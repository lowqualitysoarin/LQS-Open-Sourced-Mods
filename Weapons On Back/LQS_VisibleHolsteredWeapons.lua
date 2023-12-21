-- low_quality_soarin © 2024-2025
behaviour("LQS_VisibleHolsteredWeapons")

_G.LQSWeaponHolstersBase = nil

function LQS_VisibleHolsteredWeapons:Awake()
    -- Instance
    _G.LQSWeaponHolstersBase = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_VisibleHolsteredWeapons:Start()
	-- Base
    self.data = self.gameObject.GetComponent(DataContainer)

    -- Vars
    self.onRunList = {} -- A list of actors in the running list
    self.isInPhotoMode = false

    -- Config
    self.visualizeHeavyWeapons = self.script.mutator.GetConfigurationBool("visualizeHeavyWeapons")
    self.visualizeSecondaryWeapons = self.script.mutator.GetConfigurationBool("visualizeSecondaryWeapons")
    self.visualizePrimaryWeapons = self.script.mutator.GetConfigurationBool("visualizePrimaryWeapons")

    self.targetTeam = "Both"

    local chosenTeam = self.script.mutator.GetConfigurationDropdown("canBeShowedOn")
    if (chosenTeam == 1) then
        self.targetTeam = Team.Blue
    elseif (chosenTeam == 2) then
        self.targetTeam = Team.Red
    elseif (chosenTeam == 3) then
        self.targetTeam = "PlayerOnly"
    end

    self.blacklistedWeapons = {}

    for word in string.gmatch(string.upper(self.script.mutator.GetConfigurationString("weaponBlacklist")), '([^,]+)') do
        self.blacklistedWeapons[word] = true
    end

    -- Presets
    self.presets = self.data.GetGameObjectArray("preset")
    self.actorHolsterData = {} -- Format: {
                                --    Actor, 
                                --    {PrimaryHolster, (Ragdoll)PrimaryHolster}, 
                                --    {SecondaryHolster, (Ragdoll)SecondaryHolster}, 
                                --    {HeavyHolster, (Ragdoll)HeavyHolster},
                                --    }
    -- Events
    GameEvents.onActorSpawn.AddListener(self, "ActorSpawn")
end

function LQS_VisibleHolsteredWeapons:ActorSpawn(actor)
    -- Check if the weapon holsters can be showed on this actor
    if (not self:CanBeShowed(actor)) then return end

    -- Update and setup (if possible) holsters
    self:SetupHolsters(actor)
    self:UpdateHolsters(actor)

    -- Call update coroutine for the actor
    -- For updating holsters, if the actor is not dead
    self.script.StartCoroutine(self:CoroutineUpdate(actor))
end

function LQS_VisibleHolsteredWeapons:CanBeShowed(actor)
    if (not actor) then return false end
    
    if (
        (self.targetTeam == "Both") or
        (actor.isPlayer and self.targetTeam == "PlayerOnly") or
        (actor.team == self.targetTeam)
    ) then
        return true
    end 
    return false
end

function LQS_VisibleHolsteredWeapons:OnActorWeaponChange(actor)
    self:UpdateHolsters(actor)
end

function LQS_VisibleHolsteredWeapons:Update()
    -- Photomode and pause check
    if (Input.GetKeyDown(KeyCode.F8)) then
        self.isInPhotoMode = not self.isInPhotoMode
    end

    if (Input.GetKeyDown(KeyCode.Escape) and self.isInPhotoMode) then
        self.isInPhotoMode = false
    end
end

function LQS_VisibleHolsteredWeapons:UpdateHolsters(actor)
    if (not actor) then return end
    if (not self:HasHolster(actor)) then return end

    -- Available to use
    local availableWeapons = {}

    for _,weapon in pairs(actor.weaponSlots) do
        if (weapon ~= actor.activeWeapon) then
            availableWeapons[#availableWeapons+1] = weapon
        end
    end

    -- Update the holsters
    -- Get all bones
    local actorHolsterData = self:GetActorData(actor)
    self:HandleHolster(actorHolsterData, availableWeapons)
end

function LQS_VisibleHolsteredWeapons:ChangeHolstersRenderMode(actorHolsterData, active, isRagdollTarget)
    -- Changes the holster's renderer mode (player only)
    self:SweepChangeRenderModeHolsters(actorHolsterData[2], active, isRagdollTarget)
    self:SweepChangeRenderModeHolsters(actorHolsterData[3], active, isRagdollTarget)
    self:SweepChangeRenderModeHolsters(actorHolsterData[4], active, isRagdollTarget)
end

function LQS_VisibleHolsteredWeapons:SweepChangeRenderModeHolsters(holstersTable, active, isRagdollTarget)
    local targetRenderer = holstersTable[2]
    if (isRagdollTarget) then
        targetRenderer = holstersTable[1]
    end

    if (targetRenderer and targetRenderer.holster.childCount > 0) then
        targetRenderer.gameObject.SetActive(active)
    end
end

function LQS_VisibleHolsteredWeapons:HandleHolster(actorHolsterData, usableWeapons)
    if (not #actorHolsterData == 0) then return end

    -- Idk what to call this
    -- It basically updates the holster slot
    local primaryOccupied = false 
    local secondaryOccupied = false
    local heavyOccupied = false

    -- The updating part
    for _,weapon in pairs(usableWeapons) do
        -- Do a loop for a check
        if (self:CanBeShown(weapon)) then
            for i = 1,3 do
                -- Since there is no match case...
                if (i == 1 and self.visualizePrimaryWeapons and not primaryOccupied) then
                    -- Destroy the old weapon impostor (sus)
                    self:DestroyWeaponRenderer(actorHolsterData[2])

                    -- Primary check
                    if (weapon.weaponEntry.slot == WeaponSlot.Primary) then
                        -- Apply renderer
                        self:ApplyWeaponRenderer(actorHolsterData[2], weapon)
                        primaryOccupied = true
                    end
                elseif (i == 2 and self.visualizeSecondaryWeapons and not secondaryOccupied) then
                    -- Same thing
                    self:DestroyWeaponRenderer(actorHolsterData[3])

                    -- Secondary check
                    if (weapon.weaponEntry.slot == WeaponSlot.Secondary) then
                        -- Apply renderer
                        self:ApplyWeaponRenderer(actorHolsterData[3], weapon)
                        secondaryOccupied = true
                    end
                elseif (i == 3 and self.visualizeHeavyWeapons and not heavyOccupied) then
                    -- Ambatukam
                    self:DestroyWeaponRenderer(actorHolsterData[4])

                    -- Heavy check
                    if (weapon.weaponEntry.slot == WeaponSlot.LargeGear) then
                        -- Apply renderer
                        self:ApplyWeaponRenderer(actorHolsterData[4], weapon)
                        heavyOccupied = true
                    end
                end
            end
        end
    end
end

function LQS_VisibleHolsteredWeapons:CanBeShown(weapon)
    if (not weapon) then return false end
    
    if (not self.blacklistedWeapons[weapon.weaponEntry.name]) then
        return true
    end
    return false
end

function LQS_VisibleHolsteredWeapons:DestroyWeaponRenderer(holsterPoints)
    -- Self explanatory
    for _,holsterPoint in pairs(holsterPoints) do
        if (holsterPoint.holster and holsterPoint.holster.childCount > 0) then
            GameObject.Destroy(holsterPoint.holster.GetChild(0).gameObject)
        end
    end
end

function LQS_VisibleHolsteredWeapons:ApplyWeaponRenderer(holsterPoints, weapon)
    for _,holsterPoint in pairs(holsterPoints) do
        -- Apply new renderer (if the weapon has a tp model assigned)
        local weaponImposter = weapon.weaponEntry.InstantiateImposter(Vector3.zero, Quaternion.identity)

        if (weaponImposter) then
            weaponImposter.transform.parent = holsterPoint.holster

            weaponImposter.transform.localPosition = Vector3.zero
            weaponImposter.transform.localRotation = Quaternion.identity
        end
    end
end

function LQS_VisibleHolsteredWeapons:HasHolster(actor)
    for _,assigned in pairs(self.actorHolsterData) do
        if (actor == assigned[1]) then
            return true
        end
    end
    return false
end

function LQS_VisibleHolsteredWeapons:GetActorData(actor)
    for _,assigned in pairs(self.actorHolsterData) do
        if (actor == assigned[1]) then
            return assigned
        end
    end
    return nil
end

function LQS_VisibleHolsteredWeapons:SetupHolsters(actor)
    -- Sets up some holster slots on the given actor
    -- Check if the actor is already in the actorHolsterData list, if so then cancel the process
    if (self:HasHolster(actor)) then return end

    -- Gonna have to do one for ragdoll and animated one
    local chest = actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest)
    local spine = actor.GetHumanoidTransformAnimated(HumanBodyBones.Spine)

    local chest_R = actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest)
    local spine_R = actor.GetHumanoidTransformRagdoll(HumanBodyBones.Spine)

    -- Activate the soldier ragdoll (because it causes an error when trying to get the self of the script)
    local ragParent = actor.GetHumanoidTransformRagdoll(HumanBodyBones.Hips).parent.parent
    ragParent.gameObject.SetActive(true)

    -- Choose a preset
    local choosePresetIndex = self.presets[math.random(#self.presets)]
    local chosenPreset = choosePresetIndex.GetComponent(DataContainer)

    -- Instantiate holsters and assign to actorHolsterData
    self.actorHolsterData[#self.actorHolsterData+1] = {
        actor,
        {
            self:InstantiateHolster(chest, chosenPreset.GetGameObject("primaryHolster")), 
            self:InstantiateHolster(chest_R, chosenPreset.GetGameObject("primaryHolster"))
        },
        {
            self:InstantiateHolster(spine, chosenPreset.GetGameObject("secondaryHolster")),
            self:InstantiateHolster(spine_R, chosenPreset.GetGameObject("secondaryHolster"))
        },
        {
            self:InstantiateHolster(chest, chosenPreset.GetGameObject("heavyHolster")), 
            self:InstantiateHolster(chest_R, chosenPreset.GetGameObject("heavyHolster"))
        }
    }

    -- Deactivate ragdoll
    ragParent.gameObject.SetActive(false)
end

function LQS_VisibleHolsteredWeapons:InstantiateHolster(targetBone, toInstantiate)
    local newHolster = GameObject.Instantiate(toInstantiate, targetBone)

    newHolster.transform.localPosition = Vector3.zero
    newHolster.transform.localRotation = Quaternion.identity

    return newHolster.GetComponent(ScriptedBehaviour).self
end

function LQS_VisibleHolsteredWeapons:CoroutineUpdate(actor)
    return function()
        if (self.onRunList[actor]) then return end

        -- Setup variables
        self.onRunList[actor] = true
        print("started coroutine for", actor.name)

        local actorHolsterData = self:GetActorData(actor)
        local skinnedMeshAnimated = actor.GetSkinnedMeshRendererAnimated()

        local lastWeapon = actor.activeWeapon
        local lastIsRendererEnabled = skinnedMeshAnimated.enabled

        while (actor) do
            -- OnWeaponChange listener
            if (actor.activeWeapon ~= lastWeapon and not actor.isDead) then
                self:OnActorWeaponChange(actor)
                lastWeapon = actor.activeWeapon
            end

            -- Change holster render mode
            if (skinnedMeshAnimated.enabled ~= lastIsRendererEnabled) then
                self:ChangeHolstersRenderMode(actorHolsterData, skinnedMeshAnimated.enabled, true)
                lastIsRendererEnabled = skinnedMeshAnimated.enabled
            end

            if (actor.isPlayer and skinnedMeshAnimated.enabled) then
                -- Player only
                self:ChangeHolstersRenderMode(actorHolsterData, self.isInPhotoMode or actor.isFallenOver, true)
            end 

            coroutine.yield(nil)
        end

        -- Stop coroutine
        self:ChangeHolstersRenderMode(actorHolsterData, false, true)
        self.onRunList[actor] = nil
    end
end
