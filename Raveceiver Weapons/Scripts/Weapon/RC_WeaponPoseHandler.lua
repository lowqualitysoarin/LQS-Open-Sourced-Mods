-- low_quality_soarin © 2023-2024
behaviour("RC_WeaponPoseHandler")

function RC_WeaponPoseHandler:Awake()
    -- Important Scripts
    self.weaponBase = self.targets.weaponBase.GetComponent(ScriptedBehaviour).self
end

function RC_WeaponPoseHandler:Start()
    -- Base
    self.data = self.gameObject.GetComponent(DataContainer)

    -- Base Transforms
    if (self.targets.gunTransform) then
        self.gunTransform = self.targets.gunTransform.transform
    end
    if (self.targets.magTransform) then
        self.magTransform = self.targets.magTransform.transform
    end

    if (self.targets.slideTransform) then
        self.slideTransform = self.targets.slideTransform.transform
    end
    if (self.targets.bulletTransform) then
        self.bulletTransform = self.targets.bulletTransform.transform
    end
    if (self.targets.secondaryBulletTransform) then
        self.secBulletTransform = self.targets.secondaryBulletTransform.transform
    end
    if (self.targets.safetyTransform) then
        self.safetyTransform = self.targets.safetyTransform.transform
    end
    if (self.targets.hammerTransform) then
        self.hammerTransform = self.targets.hammerTransform.transform
    end

    if (self.targets.firemodeTransform) then
        self.firemodeTransform = self.targets.firemodeTransform.transform
    end
    if (self.targets.ejectorTransform) then
        self.ejectorTransform = self.targets.ejectorTransform.transform
    end

    if (self.targets.lockTransform) then
        self.lockTransform = self.targets.lockTransform.transform
    end
    if (self.targets.releaseTransform) then
        self.releaseTransform = self.targets.releaseTransform.transform
    end
    if (self.targets.triggerTransform) then
        self.triggerTransform = self.targets.triggerTransform.transform
    end

    if (self.targets.outsideParent) then
        self.outsideParent = self.targets.outsideParent.transform
    end
    if (self.targets.insideParent) then
        self.insideParent = self.targets.insideParent.transform
    end

    -- Poses (Procedurally Animated Poses)
    if (self.targets.gunPoses) then
        self.gunPoses = self.targets.gunPoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.magPoses) then
        self.magPoses = self.targets.magPoses.GetComponent(ScriptedBehaviour).self
    end

    if (self.targets.slidePoses) then
        self.slidePoses = self.targets.slidePoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.bulletPoses) then
        self.bulletPoses = self.targets.bulletPoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.secondaryBulletPoses) then
        self.secBulletPoses = self.targets.secondaryBulletPoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.safetyPoses) then
        self.safetyPoses = self.targets.safetyPoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.hammerPoses) then
        self.hammerPoses = self.targets.hammerPoses.GetComponent(ScriptedBehaviour).self
    end

    if (self.targets.firemodePoses) then
        self.firemodePoses = self.targets.firemodePoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.ejectorPoses) then
        self.ejectorPoses = self.targets.ejectorPoses.GetComponent(ScriptedBehaviour).self
    end

    if (self.targets.lockPoses) then
        self.lockPoses = self.targets.lockPoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.releasePoses) then
        self.releasePoses = self.targets.releasePoses.GetComponent(ScriptedBehaviour).self
    end
    if (self.targets.triggerPoses) then
        self.triggerPoses = self.targets.triggerPoses.GetComponent(ScriptedBehaviour).self
    end

    -- Vars
    self.reloadTime = 0.65
    self.revolverReloadTime = 0.2

    self.stopGunPoses = false

    if (self.data.HasFloat("firingSpeed")) then
        self.firingSpeed = self.data.GetFloat("firingSpeed")
    else
        self.firingSpeed = 35
    end

    -- Pose Handlers
    -- Gun
    if (self.gunTransform) then
        self.targetGunPose = self.gunTransform
    end

    -- Magazine
    if (self.magTransform) then
        self.targetMagPose = self.magTransform
    end

    -- Moving Parts
    if (self.slideTransform) then
        self.targetSlidePose = self.slideTransform
    end
    if (self.safetyTransform) then
        self.targetSafetyPose = self.safetyTransform
    end

    if (self.triggerTransform) then
        self.targetTriggerPose = self.triggerTransform
    end
    if (self.bulletTransform) then
        self.targetBulletPose = self.bulletTransform
    end
    if (self.secBulletTransform) then
        self.targetSecBulletPose = self.secBulletTransform
    end
    if (self.hammerTransform) then
        self.targetHammerPose = self.hammerTransform
    end

    if (self.firemodeTransform) then
        self.targetFiremodePose = self.firemodeTransform
    end
    if (self.ejectorTransform) then
        self.targetEjectorPose = self.ejectorTransform
    end

    if (self.lockTransform) then
        self.targetLockPose = self.lockTransform
    end
    if (self.releaseTransform) then
        self.targetReleasePose = self.releaseTransform
    end
end

function RC_WeaponPoseHandler:SetToHolsterPos()
    if (self.gunPoses and self.gunTransform) then
        if (self.gunPoses.holsteredPose) then
            self.gunTransform.position = self.gunPoses.holsteredPose.position
            self.gunTransform.rotation = self.gunPoses.holsteredPose.rotation
        end
    end

    if (self.weaponBase.ammoCarrierOut) then
        if (self.magPoses and self.magTransform) then
            if (self.magPoses.holsteredPose and self.weaponBase.weaponPartsManager.hasMag) then
                self.magTransform.position = self.magPoses.holsteredPose.position
                self.magTransform.rotation = self.magPoses.holsteredPose.rotation
            end
        end
    end
end

function RC_WeaponPoseHandler:HolsterGun()
    if (self.gunPoses) then
        if (self.gunPoses.holsteredPose) then
            self.targetGunPose = self.gunPoses.holsteredPose
        end
    end
end

function RC_WeaponPoseHandler:Update()
    -- Weapon Base
    self:WeaponPoseHandler()
end

function RC_WeaponPoseHandler:WeaponPoseHandler()
    -- Handles the weapon poses
    -- Set Pose (Gun)
    self:SetGunPose(self.stopGunPoses)

    -- Set Pose (Other Moving Parts)
    self:SetPartsPose()

    -- Set Poses
    self:PoseHandlerTransform()
	self:MagPoseHandlerTransform()
    self:HammerPoseHandlerTransform()
    self:PartPoseHandlerTransform()
end

function RC_WeaponPoseHandler:ProceduralAnimator(baseTransform, endKey, speed, isLocal, isLinear)
    -- Universal animator for all parts
    -- Vars
    local startPosTransform = nil
    local startRotTransform = nil

    local endPosTransform = nil
    local endRotTransform = nil

    local prevPos = nil

    -- Pass local pos and rot else normal pos and rot
    if (isLocal) then
        startPosTransform = baseTransform.localPosition
        startRotTransform = baseTransform.localRotation

        endPosTransform = endKey.localPosition
        endRotTransform = endKey.localRotation

        prevPos = baseTransform.localPosition
    else
        startPosTransform = baseTransform.position
        startRotTransform = baseTransform.rotation

        endPosTransform = endKey.position
        endRotTransform = endKey.rotation

        prevPos = baseTransform.position
    end

    -- Lerping Base
    if (isLinear) then
        -- Normal Lerp
        if (isLocal) then
            baseTransform.localPosition = Vector3.Lerp(startPosTransform, endPosTransform, speed * Time.deltaTime)
            baseTransform.localRotation = Quaternion.Lerp(startRotTransform, endRotTransform, speed * Time.deltaTime)
        else
            baseTransform.position = Vector3.Lerp(startPosTransform, endPosTransform, speed * Time.deltaTime)
            baseTransform.rotation = Quaternion.Lerp(startRotTransform, endRotTransform, speed * Time.deltaTime)
        end
    else
        -- Spring Lerp
        local springScript = baseTransform.gameObject.GetComponent(RC_SpringBase)

        if (springScript) then
            springScript:Spring(endPosTransform, endRotTransform, isLocal, self.weaponBase.mindControl)
        end
    end
end

function RC_WeaponPoseHandler:HammerPoseHandlerTransform()
    if (self.weaponBase.weaponReady) then
        if (self.weaponBase.weaponPartsManager.hasHammer) then
            local flickSpeed = self.weaponBase.weaponPartsManager.hammerCockSpeed
            local returnSpeed = self.weaponBase.weaponPartsManager.hammerReturnSpeed
    
            if (self.hammerPoses and self.hammerTransform) then
                if (not self.weaponBase.hasFired) then
                    if (self:CanFlickHammer()) then
                        self:ProceduralAnimator(self.hammerTransform, self.targetHammerPose, flickSpeed, true, true)
                    elseif (self:CanReturnHammer()) then
                        self:ProceduralAnimator(self.hammerTransform, self.targetHammerPose, returnSpeed, true, true)
                    end
                elseif (self.weaponBase.hasFired) then
                    self:ProceduralAnimator(self.hammerTransform, self.targetHammerPose, 100, true, true)
                end
            end
        end
    end
end

function RC_WeaponPoseHandler:CanReturnHammer()
    local output = false

    if (not self.weaponBase.isHoldingHammer) then
        if (not self.weaponBase.isTriggeringHammer) then
            if (not self.weaponBase.hammerReady or self.weaponBase.isDecockingHammer) then
                output = true
            end
        end
    end

    return output
end

function RC_WeaponPoseHandler:CanFlickHammer()
    local output = false

    if (self.weaponBase.isHoldingHammer or self.weaponBase.isTriggeringHammer or self.weaponBase.hammerReady) then
        if (not self.weaponBase.isDecockingHammer) then
            output = true
        end
    end

    return output
end

function RC_WeaponPoseHandler:MagPoseHandlerTransform()
    -- Mag Animator
	if (self.magTransform and self.targetMagPose) then
        if (self.weaponBase.weaponPartsManager.hasMag) then
            if (not self.weaponBase.insertedMag) then
                self:ProceduralAnimator(self.magTransform, self.targetMagPose, 15, true, false)
            elseif (self.weaponBase.insertedMag) then
                self:ProceduralAnimator(self.magTransform, self.targetMagPose, 15, true, true)
            end
        elseif (self.weaponBase.weaponPartsManager.hasCylinder) then
            self:ProceduralAnimator(self.magTransform, self.targetMagPose, 18, true, true)
        end
    end
end

function RC_WeaponPoseHandler:SetPartsPose()
    -- Slide
    local targetSlideSpeed = 35

    if (self.weaponBase.isFiring) then
        targetSlideSpeed = self.firingSpeed
    elseif (self:IsDoingManualSlideActs()) then
        targetSlideSpeed = 25
    end

    if (self.slideTransform and self.targetSlidePose) then
        self:ProceduralAnimator(self.slideTransform, self.targetSlidePose, targetSlideSpeed, true, true)
    end

    -- Chambered Round
    if (self.bulletTransform and self.targetBulletPose) then
        self:ProceduralAnimator(self.bulletTransform, self.targetBulletPose, 35, true, true)
    end

    -- Secondary Round
    if (self.secBulletTransform and self.targetSecBulletPose) then
        self:ProceduralAnimator(self.secBulletTransform, self.targetSecBulletPose, 1000, true, true)
    end

    -- Safety
    if (self.safetyTransform and self.targetSafetyPose) then
        self:ProceduralAnimator(self.safetyTransform, self.targetSafetyPose, 25, true, true)
    end
    
    -- Slide Lock/Release
    if (self.lockTransform and self.targetLockPose) then
        self:ProceduralAnimator(self.lockTransform, self.targetLockPose, 45, true, true)
    end

    -- Trigger
    if (self.triggerTransform and self.targetTriggerPose) then
        self:ProceduralAnimator(self.triggerTransform, self.targetTriggerPose, 25, true, true)
    end

    -- Mag/Cylinder Release
    if (self.releaseTransform and self.targetReleasePose) then
        self:ProceduralAnimator(self.releaseTransform, self.targetReleasePose, 35, true, true)
    end

    -- Firemode
    if (self.firemodeTransform and self.targetFiremodePose) then
        self:ProceduralAnimator(self.firemodeTransform, self.targetFiremodePose, 45, true, true)
    end

    -- Ejector
    if (self.ejectorTransform and self.targetEjectorPose) then
        self:ProceduralAnimator(self.ejectorTransform, self.targetEjectorPose, 55, true, true)
    end
end

function RC_WeaponPoseHandler:IsDoingManualSlideActs()
    local output = false

    if (self.weaponBase.isRacking or self.weaponBase.isJolting) then
        output = true
    end

    return output
end

function RC_WeaponPoseHandler:SetGunPose(disable)
    if (self.weaponBase.weaponReady and not disable) then
        if (self.gunTransform and self.targetGunPose) then
            if (not self.weaponBase.mindControl) then
                if (self.weaponBase.isAiming or self.weaponBase.safetyOn or self.weaponBase.isReloading and self:HasNoCylinder() or self.weaponBase.isJammed) then
                    self:ProceduralAnimator(self.gunTransform, self.targetGunPose, 7.5, true, false)
                else
                    self:ProceduralAnimator(self.gunTransform, self.targetGunPose, 7.5, false, false)
                end
            else
                -- Shaking Effect
                if (Time.timeScale > 0) then
                    self.gunTransform.position = self.gunTransform.position + self:Shake(0.00025)
                    self.gunTransform.rotation = self.gunTransform.rotation * Quaternion.Euler(self:Shake(0.25))
                end
    
                -- Lerp To Position
                self:ProceduralAnimator(self.gunTransform, self.targetGunPose, 0.25, false, false)
            end
        end
    end
end

function RC_WeaponPoseHandler:HasNoCylinder()
    local output = true

    if (self.weaponBase.weaponPartsManager.hasCylinder) then
        output = false
    end

    return output
end

function RC_WeaponPoseHandler:Shake(intensity)
    local x = Mathf.PerlinNoise(Time.time * 5.0, 0.0) * 2.0 - 1.0
    local y = Mathf.PerlinNoise(0.0, Time.time * 5.0) * 2.0 - 1.0
    local z = Mathf.PerlinNoise(Time.time * 5.0, Time.time * 5.0) * 2.0 - 1.0

    local shake = Vector3(x, y, z) * intensity

    return shake
end

function RC_WeaponPoseHandler:PartPoseHandlerTransform()
    -- Handles the weapon's part transform for poses
    -- Slide
    if (self.slidePoses and self.targetSlidePose) then
        if (self.weaponBase.isRacking and not self.weaponBase.hasFired) then
            if (self.slidePoses.rackedSlidePose) then
                self.targetSlidePose = self.slidePoses.rackedSlidePose
            end
        elseif (self.weaponBase.isJammed and not self.weaponBase.isJolting and not self.weaponBase.hasFired and not self.weaponBase.slideLocked) then
            self.targetSlidePose = self:GetJamTypeSlide()
        elseif (self.weaponBase.slideLocked) then
            if (self.slidePoses.lockedSlidePose) then
                self.targetSlidePose = self.slidePoses.lockedSlidePose
            end
        elseif (self.weaponBase.isJolting and self:CanJoltWhileJammed() and not self.weaponBase.hasFired) then
            if (self.slidePoses.joltedSlidePose) then
                self.targetSlidePose = self.slidePoses.joltedSlidePose
            end
        elseif (not self.weaponBase.hasFired and self:HasNoBadJam()) then
            if (self.slidePoses.normalSlidePose) then
                self.targetSlidePose = self.slidePoses.normalSlidePose
            end
        end
    end

    -- Chambered Round
    if (self.bulletPoses and self.targetBulletPose) then
        if (self.weaponBase.isJolting and not self.weaponBase.slideLocked and not self.weaponBase.hasFired and not self.weaponBase.doublefeed) then
            if (self.bulletPoses.joltedBulletPose) then
                self.targetBulletPose = self.bulletPoses.joltedBulletPose
            end
        elseif (self.weaponBase.isRacking and not self.weaponBase.doublefeed or self.weaponBase.slideLocked and not self.weaponBase.doublefeed or self.weaponBase.hasFired 
        and not self.weaponBase.doublefeed or self.weaponBase.outofbattery) then
            if (self.bulletPoses.loadingBulletPose) then
                self.targetBulletPose = self.bulletPoses.loadingBulletPose
            end
        else
            if (self.bulletPoses.restBulletPose) then
                self.targetBulletPose = self.bulletPoses.restBulletPose
            end
        end
    end

    -- Secondary Round
    if (self.secBulletPoses and self.targetSecBulletPose) then
        if (self.weaponBase.isJammed) then
            if (self.secBulletTransform) then
                self.secBulletTransform.gameObject.SetActive(true)
            end

            self.targetSecBulletPose = self:GetJamTypeRound()
        else
            if (self.secBulletTransform) then
                self.secBulletTransform.gameObject.SetActive(false)
            end

            if (self.secBulletPoses.restSecBulletPose) then
                self.targetSecBulletPose = self.secBulletPoses.restSecBulletPose
            end
        end
    end

    -- Safety
    if (self.safetyPoses and self.targetSafetyPose) then
        if (self.weaponBase.safetyOn) then
            if (self.safetyPoses.safetyOnPose) then
                self.targetSafetyPose = self.safetyPoses.safetyOnPose
            end
        else
            if (self.safetyPoses.safetyOffPose) then
                self.targetSafetyPose = self.safetyPoses.safetyOffPose
            end
        end
    end

    -- Slide Lock
    if (self.lockPoses and self.targetLockPose) then
        if (self.weaponBase.slideLocked) then
            if (self.lockPoses.lockedPose) then
                self.targetLockPose = self.lockPoses.lockedPose
            end
        else
            if (self.lockPoses.unlockedPose) then
                self.targetLockPose = self.lockPoses.unlockedPose
            end
        end
    end

    -- Trigger
    if (self.triggerPoses and self.targetTriggerPose) then
        if (self.weaponBase.isHoldingTrigger) then
            if (self.triggerPoses.pulledTriggerPose) then
                self.targetTriggerPose = self.triggerPoses.pulledTriggerPose
            end
        else
            if (self.triggerPoses.normalTriggerPose) then
                self.targetTriggerPose = self.triggerPoses.normalTriggerPose
            end
        end
    end

    -- Mag/Cylinder Release
    if (self.releasePoses and self.targetReleasePose) then
        if (self.weaponBase.isHoldingRelease) then
            if (self.releasePoses.releasedPose) then
                self.targetReleasePose = self.releasePoses.releasedPose
            end
        else
            if (self.releasePoses.normalReleasePose) then
                self.targetReleasePose = self.releasePoses.normalReleasePose
            end
        end
    end

    -- Hammer
    if (self.hammerPoses and self.targetHammerPose) then
        if (not self.weaponBase.decockingHammer) then
            if (not self.weaponBase.hasFired) then
                if (self.weaponBase.isHoldingHammer or self.weaponBase.isTriggeringHammer or self.weaponBase.hammerReady and not self.weaponBase.halfCocked and not self.weaponBase.safetyDecocking) then
                    if (self.hammerPoses.hammerReadyPose) then
                        self.targetHammerPose = self.hammerPoses.hammerReadyPose
                    end
                elseif (not self.weaponBase.isHoldingHammer and not self.weaponBase.hammerReady and not self.weaponBase.halfCocked and not self.weaponBase.safetyDecocking) then
                    if (self.hammerPoses.hammerRestPose) then
                        self.targetHammerPose = self.hammerPoses.hammerRestPose
                    end
                elseif (self.weaponBase.halfCocked and not self.weaponBase.safetyDecocking) then
                    if (self.hammerPoses.hammerHalfCockedPose) then
                        self.targetHammerPose = self.hammerPoses.hammerHalfCockedPose
                    end
                elseif (self.weaponBase.safetyDecocking) then
                    if (self.hammerPoses.safetyDecockingPose) then
                        self.targetHammerPose = self.hammerPoses.safetyDecockingPose
                    end
                end
            end
        end
    end

    -- Firemode
    if (self.firemodePoses and self.targetFiremodePose) then
        if (self.firemodePoses.fmPoses and #self.firemodePoses.fmPoses > 0) then
            if (self.firemodePoses.fmPoses[self.weaponBase.currentFiremodeIndex]) then
                self.targetFiremodePose = self.firemodePoses.fmPoses[self.weaponBase.currentFiremodeIndex]
            end
        end
    end

    -- Ejector
    if (self.ejectorPoses and self.targetEjectorPose) then
        if (self.weaponBase.isHoldingEject) then
            if (self.ejectorPoses.ejectEjectorPose) then
                self.targetEjectorPose = self.ejectorPoses.ejectEjectorPose
            end
        else
            if (self.ejectorPoses.restEjectorPose) then
                self.targetEjectorPose = self.ejectorPoses.restEjectorPose
            end
        end
    end
end

function RC_WeaponPoseHandler:HasNoBadJam()
    local output = false

    if (not self.weaponBase.stovepipe) then
        if (not self.weaponBase.doublefeed) then
            output = true
        end
    end

    return output
end

function RC_WeaponPoseHandler:CanJoltWhileJammed()
    local output = true

    if (self.weaponBase.stovepipe or self.weaponBase.doublefeed) then
        output = false
    end

    return output
end

function RC_WeaponPoseHandler:GetJamTypeRound()
    local output = nil

    if (self.secBulletPoses.restSecBulletPose) then
        output = self.secBulletPoses.restSecBulletPose
    end

    if (self.weaponBase.stovepipe) then
        if (self.secBulletPoses.stovepipeSecBulletPose) then
            output = self.secBulletPoses.stovepipeSecBulletPose
        end
    elseif (self.weaponBase.doublefeed) then
        if (self.secBulletPoses.doublefeedSecBulletPose) then
            output = self.secBulletPoses.doublefeedSecBulletPose
        end
    end

    return output
end

function RC_WeaponPoseHandler:GetJamTypeSlide()
    local output = nil

    if (self.slidePoses.normalSlidePose) then
        output = self.slidePoses.normalSlidePose
    end

    if (self.weaponBase.stovepipe) then
        if (self.slidePoses.stovepipeSlidePose) then
            output = self.slidePoses.stovepipeSlidePose
        end
    elseif (self.weaponBase.outofbattery) then
        if (self.slidePoses.outofbatterySlidePose) then
            output = self.slidePoses.outofbatterySlidePose
        end
    elseif (self.weaponBase.doublefeed) then
        if (self.slidePoses.doublefeedSlidePose) then
            output = self.slidePoses.doublefeedSlidePose
        end
    end

    return output
end

function RC_WeaponPoseHandler:PoseHandlerTransform()
    -- Handles the transform for the poses
    if (self.gunPoses and self.targetGunPose) then
        if (not self.weaponBase.mindControl) then
            if (self.weaponBase.isAiming and self:CanPoseGun(false, true, true, true, true, true, false, false, false, false)) then
                if (self.gunPoses.aimPose) then
                    self.targetGunPose = self.gunPoses.aimPose
                end
            elseif (self.weaponBase.isSprinting and self:CanPoseGun(false, true, true, true, true, true, true, true, true, true)) then
                if (self.gunPoses.sprintPose) then
                    self.targetGunPose = self.gunPoses.sprintPose
                end
            elseif (self.weaponBase.isJammed and self:CanPoseGun(false, true, false, true, true, true, false, true, true, true)) then
                self.targetGunPose = self:GetJamTypeGun()
            elseif (not self.weaponBase.isAiming and self:CanPoseGun(false, false, false, true, false, false, false, false, false, false)) then
                if (self.gunPoses.idlePose) then
                    self.targetGunPose = self.gunPoses.idlePose
                end
            elseif (self.weaponBase.safetyOn and self:CanPoseGun(false, true, false, true, true, false, false, false, false, false)) then
                if (self.gunPoses.idleSafetyPose) then
                    self.targetGunPose = self.gunPoses.idleSafetyPose
                end
            elseif (self.weaponBase.weaponPartsManager.hasCylinder) then
                if (self.weaponBase.ammoCarrierOut and self:CanPoseGun(false, false, true, true, true, false, false, true, false, false)) then
                    if (self.gunPoses.openCylinderPose) then
                        self.targetGunPose = self.gunPoses.openCylinderPose
                    end
                elseif (self.weaponBase.isHoldingCloseKey and self:CanPoseGun(false, false, true, true, true, false, false, true, true, true)) then
                    if (self.gunPoses.closeCylinderPose) then
                        self.targetGunPose = self.gunPoses.closeCylinderPose
                    end
                elseif (self.weaponBase.isHoldingEject and self:CanPoseGun(false, false, true, true, true, false, false, true, false, true)) then
                    if (self.gunPoses.ejectPose) then
                        self.targetGunPose = self.gunPoses.ejectPose
                    end
                end
            end
        
            if (self.weaponBase.isRacking and self:CanPoseGun(false, false, true, true, true, true, false, true, true, false)) then
                if (self.gunPoses.rackPose) then
                    self.targetGunPose = self.gunPoses.rackPose
                end
            elseif (self.weaponBase.isJolting and self:CanPoseGun(false, false, true, true, true, true, false, true, true, false)) then
                if (self.gunPoses.joltPose) then
                    self.targetGunPose = self.gunPoses.joltPose
                end
            end
        else
            if (self.gunPoses.suicidePose) then
                self.targetGunPose = self.gunPoses.suicidePose
            end
        end
    end
end

function RC_WeaponPoseHandler:GetJamTypeGun()
    local output = nil

    if (self.gunPoses.idlePose) then
        output = self.gunPoses.idlePose
    end

    if (self.weaponBase.stovepipe) then
        if (self.gunPoses.stovepipePose) then
            output = self.gunPoses.stovepipePose
        end
    elseif (self.weaponBase.outofbattery) then
        if (self.gunPoses.outofbatteryPose) then
            output = self.gunPoses.outofbatteryPose
        end
    elseif (self.weaponBase.doublefeed) then
        if (self.gunPoses.doublefeedPose) then
            output = self.gunPoses.doublefeedPose
        end
    end

    return output
end

function RC_WeaponPoseHandler:CanPoseGun(
    bypassReload, bypassHolster, bypassAiming, bypassFiring,
    bypassSafety, bypassJam, bypassSprint, bypassCylinderOpen,
    bypassCylinderClose, bypassEject
)
    local output = false

    if (not self.weaponBase.isReloading or bypassReload) then
        if (not self.weaponBase.isHolstered or bypassHolster) then
            if (not self.weaponBase.isAiming or bypassAiming) then
                if (not self.weaponBase.safetyOn or bypassSafety) then
                    if (not self.weaponBase.hasFired or bypassFiring) then
                        if (not self.weaponBase.isJammed or bypassJam) then
                            if (not self.weaponBase.isSprinting or bypassSprint) then
                                if (not self.weaponBase.weaponPartsManager.hasCylinder) then
                                    if (not self.weaponBase.forceHolster) then
                                        output = true
                                    end
                                else
                                    if (not self.weaponBase.ammoCarrierOut or bypassCylinderOpen) then
                                        if (not self.weaponBase.isHoldingCloseKey or bypassCylinderClose) then
                                            if (not self.weaponBase.isHoldingEject or bypassEject) then
                                                output = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return output
end

function RC_WeaponPoseHandler:StartReload(unload, isRevolverLike)
    -- Starts the reload function
    -- Set isReloading to true
    self.weaponBase.isReloading = true

    -- Main
    if (not isRevolverLike) then
        if (unload) then
            self.script.StartCoroutine(self:ReloadAnimation(false))
            self.script.StartCoroutine(self:CarrierReload(true, false))
        else
            self.script.StartCoroutine(self:ReloadAnimation(false))
            self.script.StartCoroutine(self:CarrierReload(false, false))
        end
    else
        if (unload) then
            self.script.StartCoroutine(self:ReloadAnimation(true, false))
            self.script.StartCoroutine(self:CarrierReload(true, true))
        else
            self.script.StartCoroutine(self:ReloadAnimation(true, true))
            self.script.StartCoroutine(self:CarrierReload(false, true))
        end
    end
end

function RC_WeaponPoseHandler:CarrierReload(unload, isCylinder)
    return function()
		if (self.weaponBase.isReloading) then
            if (unload) then	
                if (not isCylinder) then
                    if (self.magPoses and self.targetMagPose) then
                        if (self.magPoses.insertingPose) then
                            self.targetMagPose = self.magPoses.insertingPose
                        end
        
                        self.weaponBase:OnUnloadStart()
            
                        coroutine.yield(WaitForSeconds(0.25))
            
                        if (self.magTransform and self.outsideParent) then
                            self.magTransform.parent = self.outsideParent
                        end
            
                        if (self.magPoses.ejectedPose) then
                            self.targetMagPose = self.magPoses.ejectedPose
                        end
        
                        self.weaponBase:OnAmmoCarrierOut()
            
                        coroutine.yield(WaitForSeconds(0.15))
            
                        if (self.magPoses.ejectedPose) then
                            self.targetMagPose = self.magPoses.ejectedPose
                        end
                    end
                else
                    if (self.magPoses and self.targetMagPose) then
                        self.weaponBase:OnUnloadStart()

                        if (self.magPoses.openPose) then
                            self.targetMagPose = self.magPoses.openPose
                        end

                        self.weaponBase:OnAmmoCarrierOut()
                    end
                end
            else
                if (not isCylinder) then
                    if (self.magPoses and self.targetMagPose) then
                        self.weaponBase:OnLoadStart()
    
                        coroutine.yield(WaitForSeconds(0.15))
            
                        if (self.magTransform and self.gunTransform) then
                            if (self.insideParent) then
                                self.magTransform.parent = self.insideParent
                            else
                                self.magTransform.parent = self.gunTransform
                            end
                        end
            
                        if (self.magPoses.insertingPose) then
                            self.targetMagPose = self.magPoses.insertingPose
                        end
            
                        coroutine.yield(WaitForSeconds(0.25))
            
                        if (self.magPoses.insertedPose) then
                            self.targetMagPose = self.magPoses.insertedPose
                        end
        
                        self.weaponBase:OnAmmoCarrierIn()
                    end
                else
                    if (self.magPoses and self.targetMagPose) then
                        self.weaponBase:OnLoadStart()

                        if (self.magPoses.closePose) then
                            self.targetMagPose = self.magPoses.closePose
                        end

                        self.weaponBase:OnAmmoCarrierIn()
                    end
                end
            end
        end
    end
end

function RC_WeaponPoseHandler:ReloadAnimation(hasCylinder, unload)
    return function()
        if (self.gunPoses and self.targetGunPose) then
            if (not hasCylinder) then
                if (self.weaponBase.isReloading) then
                    if (self.gunPoses.reloadPose) then
                        self.targetGunPose = self.gunPoses.reloadPose
                    end
        
                    coroutine.yield(WaitForSeconds(self.reloadTime))
            
                    self.weaponBase.isReloading = false
                end
            else
                if (self.weaponBase.isReloading) then
                    if (not unload) then
                        if (self.gunPoses.openCylinderPose) then
                            self.targetGunPose = self.gunPoses.openCylinderPose
                        end
    
                        coroutine.yield(WaitForSeconds(self.revolverReloadTime))
                    
                        self.weaponBase.isReloading = false
                    else
                        if (self.gunPoses.closeCylinderPose) then
                            self.targetGunPose = self.gunPoses.closeCylinderPose
                        end

                        coroutine.yield(WaitForSeconds(self.revolverReloadTime))
                    
                        self.weaponBase.isReloading = false
                    end
                end
            end
        end
    end
end

function RC_WeaponPoseHandler:OnFire(hasHammer, isDry)
    -- This Animates the slide and gun firing
    self.weaponBase.hasFired = true
    self.script.StartCoroutine(self:FireAnimation(hasHammer, isDry))
end

function RC_WeaponPoseHandler:FireAnimation(hasHammer, isDry)
    -- Literally the firing animation
    return function()
        if (self.weaponBase.hasFired) then
            if (not hasHammer) then
                if (self.weaponBase.weaponPartsManager.hasSlide and not self.weaponBase.noSelfLoading and not isDry) then
                    while (not self.weaponBase.slidBack) do
                        if (self.slidePoses.lockedSlidePose) then
                            self.targetSlidePose = self.slidePoses.lockedSlidePose
                        elseif (self.slidePoses.rackedSlidePose) then
                            self.targetSlidePose = self.slidePoses.rackedSlidePose
                        end
    
                        coroutine.yield(WaitForSeconds(0))
                    end
                end
    
                coroutine.yield(WaitForSeconds(0))
    
                self.weaponBase.hasFired = false
            else
                if (self.hammerPoses and self.targetHammerPose) then
                    if (not self.weaponBase.slideLocked) then
                        self.targetHammerPose = self.hammerPoses.hammerRestPose
                    end
                end

                coroutine.yield(WaitForSeconds(0.04))

                if (self.weaponBase.weaponPartsManager.hasSlide and not self.weaponBase.noSelfLoading and not isDry) then
                    while (not self.weaponBase.slidBack) do
                        if (self.slidePoses.lockedSlidePose) then
                            self.targetSlidePose = self.slidePoses.lockedSlidePose
                        elseif (self.slidePoses.rackedSlidePose) then
                            self.targetSlidePose = self.slidePoses.rackedSlidePose
                        end
    
                        coroutine.yield(WaitForSeconds(0))
                    end
                end

                if (self.hammerPoses and self.targetHammerPose) then
                    if (self.weaponBase.weaponPartsManager.hasSlide and not self.weaponBase.noSelfLoading and not isDry) then
                        self.targetHammerPose = self.hammerPoses.hammerReadyPose
                    end
                end

                coroutine.yield(WaitForSeconds(0))

                self.weaponBase.hasFired = false
            end
        end
    end
end

function RC_WeaponPoseHandler:DecockHammer()
    -- Decocks the hammer
    self.script.StartCoroutine(self:DisengageHammerVisual())
end

function RC_WeaponPoseHandler:DisengageHammerVisual()
    return function()
        self.weaponBase.decockingHammer = true

        if (self.hammerPoses and self.targetHammerPose) then
            if (not self.weaponBase.slideLocked) then
                self.targetHammerPose = self.hammerPoses.hammerRestPose
            end
        end

        coroutine.yield(WaitForSeconds(0.2))

        self.weaponBase.decockingHammer = false
    end
end

function RC_WeaponPoseHandler:InstantUnload(isCylinder)
    if (self.magPoses and self.targetMagPose) then
        if (not isCylinder) then
            self.magTransform.parent = self.outsideParent
    
            self.magTransform.localPosition = self.magPoses.ejectedPose.localPosition
            self.magTransform.localRotation = self.magPoses.ejectedPose.localRotation
    
            self.targetMagPose = self.magPoses.ejectedPose
        else
            self.magTransform.localPosition = self.magPoses.openPose.localPosition
            self.magTransform.localRotation = self.magPoses.openPose.localRotation

            self.targetMagPose = self.magPoses.openPose
        end
    end
end

function RC_WeaponPoseHandler:HolsterMag(equip)
    if (self.magPoses and self.targetMagPose) then
        if (equip) then
            self.targetMagPose = self.magPoses.ejectedPose
        else
            self.targetMagPose = self.magPoses.holsteredPose
        end
    end
end

function RC_WeaponPoseHandler:InstantPoseHammer(ready)
    if (self.hammerTransform and self.hammerPoses) then
        if (not ready) then
            if (self.hammerPoses.hammerRestPose) then
                self.hammerTransform.localPosition = self.hammerPoses.hammerRestPose.localPosition
                self.hammerTransform.localRotation = self.hammerPoses.hammerRestPose.localRotation

                self.targetHammerPose = self.hammerPoses.hammerRestPose
            end
        else
            if (self.hammerPoses.hammerReadyPose) then
                self.hammerTransform.localPosition = self.hammerPoses.hammerReadyPose.localPosition
                self.hammerTransform.localRotation = self.hammerPoses.hammerReadyPose.localRotation

                self.targetHammerPose = self.hammerPoses.hammerReadyPose
            end
        end
    end
end

function RC_WeaponPoseHandler:StartSwapMags(newIndex)
    self.script.StartCoroutine(self:SwapMags(newIndex))
end

function RC_WeaponPoseHandler:SwapMags(newIndex)
    return function()
        self.weaponBase.isSwappingMags = true
        self.targetMagPose = self.magPoses.holsteredPose

        coroutine.yield(WaitForSeconds(0.3))

        self.weaponBase:OnMagazineSwap(newIndex)

        coroutine.yield(WaitForSeconds(0.05))

        self.targetMagPose = self.magPoses.ejectedPose
        
        coroutine.yield(WaitForSeconds(0.1))

        self.weaponBase.isSwappingMags = false
    end
end
