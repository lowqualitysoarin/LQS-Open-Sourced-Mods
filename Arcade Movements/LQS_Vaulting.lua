-- low_quality_soarin © 2023-2024
behaviour("LQS_Vaulting")

function LQS_Vaulting:Start()
	-- Base
    self.vaultArms = self.targets.vaultArms
    self.vaultArmsAnimator = self.vaultArms.GetComponent(Animator)

    self.playerHeight = 2.0
    self.playerRadius = 0.5

    -- Events/Listeners
    GameEvents.onActorSpawn.AddListener(self, "ActorSpawn")

    -- Vars
    self.bodycamMutatorInstance = nil

    self.isVaulting = false
    self.alreadyModChecked = false
    self.alreadySetupArms = false

    -- Finishing Touches
    self.vaultArms.SetActive(false)
end

function LQS_Vaulting:ActorSpawn(actor)
    if (actor.isPlayer) then
        -- Setup arms skin
        if (not self.alreadySetupArms) then
            local vaultArmsSkin = self.vaultArms.GetComponentInChildren(SkinnedMeshRenderer)
            ActorManager.GetTeamSkin(actor.team).armSkin.Apply(vaultArmsSkin, actor.team)
            self.alreadySetupArms = true
        end

        -- Check if some certain of mutators are active
        if (not self.alreadyModChecked) then
            -- Find bodycam mod
            local bodycamMutatorOBJ = GameObject.Find("[LQS]Bodycam(Clone)")
            if (bodycamMutatorOBJ) then
                self.bodycamMutatorInstance = bodycamMutatorOBJ.GetComponent(ScriptedBehaviour).self
            end

            -- Finish
            self.alreadyModChecked = false
        end
    end
end

function LQS_Vaulting:Update()
    if (self.disable) then return end

    -- Vault Arms Parenter
    if (self:CanParentVaultArms()) then
        if (self.bodycamMutatorInstance) then
            -- If the player is playing with the bodycam mod
            self.vaultArms.transform.parent = self.bodycamMutatorInstance.bodyCamWeaponParent
        else
            -- If not using with it
            self.vaultArms.transform.parent = PlayerCamera.fpCamera.transform
        end

        self.vaultArms.transform.localPosition = Vector3.zero
        self.vaultArms.transform.localRotation = Quaternion.identity
    end

	-- Main Vault System
    if (self:CanVault()) then
        if (Input.GetKeyBindButtonDown(KeyBinds.Jump)) then
            -- Have to check it like this because rs is way different than unity's
            local playerCam = PlayerCamera.fpCamera.transform

            local ray1 = Ray(playerCam.position, playerCam.forward)
            local rayHit1 = Physics.Raycast(ray1, 1.0, RaycastTarget.ActorWalkable)

            -- Debug.DrawRay(playerCam.position, playerCam.forward, Color.red, 5.15)

            if (rayHit1) then
                -- Initiate second ray
                local ray2 = Ray(rayHit1.point + (playerCam.forward * self.playerRadius) + (Vector3.up * 0.6 * self.playerHeight), Vector3.down)
                local rayHit2 = Physics.Raycast(ray2, self.playerHeight, RaycastTarget.ActorWalkable)

                -- Debug.DrawRay(rayHit1.point + (playerCam.forward * self.playerRadius) + (Vector3.up * 0.6 * self.playerHeight), Vector3.down, Color.green, 5.15)

                if (rayHit2) then
                    if (not self:ColliderCheck(rayHit2.point)) then
                        self.script.StartCoroutine(self:VaultMotion(rayHit2.point, 0.3, rayHit1.point))
                    end
                end
            end
        end
    end
end

function LQS_Vaulting:CanParentVaultArms()
    if (Player.actor) then
        if (not Player.actor.isDead) then
            return true
        end
    end
    return false
end

function LQS_Vaulting:ColliderCheck(hitPoint)
    -- Basically some checks if the target point can be climbed on

    -- Phase 1: Raycast Up
    -- Launches a raycast upwards from the player's position, to check if the target position
    -- is blocked by a object.
    local ray1 = Ray(Player.actor.transform.position, Vector3.up)
    local colCheckUp = Physics.RaycastAll(ray1, self.playerHeight + 0.5, RaycastTarget.ActorWalkable)

    if (#colCheckUp > 0) then
        return true
    end

    -- Phase 2: CheckSphere
    -- Launces a small overlap sphere to check if there are colliders left and right
    local sphereColCheck = Physics.OverlapSphere(hitPoint + Vector3.up * 1, 0.5, RaycastTarget.ActorWalkable)

    -- Debug.DrawRay(hitPoint + Vector3.up * 0.5, Vector3.up, Color.yellow, 2.25)

    if (#sphereColCheck > 0) then
        return true
    end

    -- Phase 3: Raycast Down
    -- Launches a raycast taller then the average hitpoint check, idk...
    local ray2 = Ray(hitPoint + Vector3.up * self.playerHeight * 1, Vector3.down)
    local colCheckDown = Physics.RaycastAll(ray2, self.playerHeight * 0.5, RaycastTarget.ActorWalkable)

    if (#colCheckDown > 0) then
        return true
    end
    return false
end

function LQS_Vaulting:VaultMotion(targetPos, duration, lookPoint)
    return function()
        -- Start Vars
        self.isVaulting = true
        local playerParent = Player.actor.transform.parent

        local time = 0
        local startPos = playerParent.position

        -- Make some player changes
        local playerCol = playerParent.gameObject.GetComponent(Collider)
        local playerRB = playerParent.gameObject.GetComponent(Rigidbody)

        Player.actor.balance = 1000
        Player.actor.canDeployParachute = false
        playerCol.enabled = false

        -- Play Animation
        self:PlayVaultAnim(lookPoint)

        -- Start Vaulting
        while (time < duration) do
            -- If the player dies or gets knocked out during the vault sequence then stop the vault sequence
            if (Player.actor.isDead) then break end
            if (Player.actor.isFallenOver) then break end

            -- Lerp to the target position
            playerParent.position = Vector3.Lerp(startPos, targetPos, time / duration)
            time = time + 1 * Time.deltaTime

            -- Hide Weapon
            if (Player.actor.activeWeapon) then
                Player.actor.activeWeapon.gameObject.SetActive(false)

                -- Might aswell lock the weapon
                Player.actor.activeWeapon.LockWeapon()
            end

            -- Update
            coroutine.yield(WaitForSeconds(0))
        end

        -- End Vaulting
        -- Draw Weapon and Hide Arms
        if (Player.actor.activeWeapon) then
            Player.actor.activeWeapon.gameObject.SetActive(true)
            Player.actor.activeWeapon.animator.SetTrigger("unholster")

            -- Unlock weapon
            Player.actor.activeWeapon.UnlockWeapon()
        end

        self.vaultArms.SetActive(false)

        -- Revert player changes
        Player.actor.balance = 100
        Player.actor.canDeployParachute = true
        playerCol.enabled = true

        -- Finish Vaulting
        self.isVaulting = false
    end
end

function LQS_Vaulting:PlayVaultAnim(targetPoint)
    -- Plays the vault animation depends on the look dir of the camera
    self.vaultArms.SetActive(true)

    -- Get the dot product
    local playerCam = PlayerCamera.fpCamera.transform
    local dirToPoint = Vector3.Normalize(targetPoint, playerCam.position)
    local dot = Vector3.Dot(playerCam.forward, dirToPoint)

    -- Play the vault anim
    if (dot < 0.9 and dot > 0.2) then
        -- Middle
        self.vaultArmsAnimator.SetTrigger("vaultmid")
    elseif (dot > 0.9) then
        -- High
        self.vaultArmsAnimator.SetTrigger("vaulthigh")
    elseif (dot < 0.2) then
        -- Low
        self.vaultArmsAnimator.SetTrigger("vaultlow")
    end
end

function LQS_Vaulting:CanVault()
    if (Player.actor) then
        if (not Player.actor.isDead) then
            if (not Player.actor.activeVehicle) then
                if (not Player.actor.isProne) then
                    if (not self.isVaulting) then
                        if (not GameManager.isPaused) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end
