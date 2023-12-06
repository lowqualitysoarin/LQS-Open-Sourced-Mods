-- low_quality_soarin © 2023-2024
behaviour("RC_PoseManager")

function RC_PoseManager:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Check Bools
	self.dataType = self.data.GetString("type")

	-- Get Poses
	if (self.dataType == "gun") then
		self:GetGunPoses()
	elseif (self.dataType == "magazine") then
		self:GetMagPoses()
	elseif (self.dataType == "ejector") then
		self:GetEjectorPoses()
	elseif (self.dataType == "slide") then
		self:GetSlidePoses()
	elseif (self.dataType == "safety") then
		self:GetSafetyPoses()
	elseif (self.dataType == "hammer") then
		self:GetHammerPoses()
	elseif (self.dataType == "firemode") then
		self:GetFiremodePoses()
	elseif (self.dataType == "slidelock") then
		self:GetSlideLockPoses()
	elseif (self.dataType == "magrelease") then
		self:GetMagReleasePoses()
	elseif (self.dataType == "trigger") then
		self:GetTriggerPoses()
	elseif (self.dataType == "chamberedround") then
		self:GetChamberedRoundPoses()
	elseif (self.dataType == "jamround") then
		self:GetSecondaryRoundPoses()
	elseif (self.dataType == "flashlight") then
		self:GetFlashlightPoses()
	end
end

-- These functions below only gets the poses
function RC_PoseManager:GetGunPoses()
	if (self.data.HasObject("pose_holstered") and self.data.GetGameObject("pose_holstered")) then
		self.holsteredPose = self.data.GetGameObject("pose_holstered").transform
	end

	if (self.data.HasObject("pose_idle") and self.data.GetGameObject("pose_holstered")) then
		self.idlePose = self.data.GetGameObject("pose_idle").transform
	end
	if (self.data.HasObject("pose_idlesafety") and self.data.GetGameObject("pose_idlesafety")) then
		self.idleSafetyPose = self.data.GetGameObject("pose_idlesafety").transform
	end

	if (self.data.HasObject("pose_aim") and self.data.GetGameObject("pose_aim")) then
		self.aimPose = self.data.GetGameObject("pose_aim").transform
	end
	if (self.data.HasObject("pose_sprint") and self.data.GetGameObject("pose_sprint")) then
		self.sprintPose = self.data.GetGameObject("pose_sprint").transform
	end

	if (self.data.HasObject("pose_reload") and self.data.GetGameObject("pose_reload")) then
		self.reloadPose = self.data.GetGameObject("pose_reload").transform
	end
	if (self.data.HasObject("pose_rack") and self.data.GetGameObject("pose_rack")) then
		self.rackPose = self.data.GetGameObject("pose_rack").transform
	end
	if (self.data.HasObject("pose_presscheck") and self.data.GetGameObject("pose_presscheck")) then
		self.joltPose = self.data.GetGameObject("pose_presscheck").transform
	end

	if (self.data.HasObject("pose_stovepipe") and self.data.GetGameObject("pose_stovepipe")) then
		self.stovepipePose = self.data.GetGameObject("pose_stovepipe").transform
	end
	if (self.data.HasObject("pose_doublefeed") and self.data.GetGameObject("pose_doublefeed")) then
		self.doublefeedPose = self.data.GetGameObject("pose_doublefeed").transform
	end
	if (self.data.HasObject("pose_outofbattery") and self.data.GetGameObject("pose_outofbattery")) then
		self.outofbatteryPose = self.data.GetGameObject("pose_outofbattery").transform
	end

	if (self.data.HasObject("pose_suicide") and self.data.GetGameObject("pose_suicide")) then
		self.suicidePose = self.data.GetGameObject("pose_suicide").transform
	end

	if (self.data.HasObject("pose_opencylinder") and self.data.GetGameObject("pose_opencylinder")) then
		self.openCylinderPose = self.data.GetGameObject("pose_opencylinder").transform
	end
	if (self.data.HasObject("pose_closecylinder") and self.data.GetGameObject("pose_closecylinder")) then
		self.closeCylinderPose = self.data.GetGameObject("pose_closecylinder").transform
	end
	if (self.data.HasObject("pose_eject") and self.data.GetGameObject("pose_eject")) then
		self.ejectPose = self.data.GetGameObject("pose_eject").transform
	end
end

function RC_PoseManager:GetMagPoses()
	if (self.data.HasObject("pose_inserted") and self.data.GetGameObject("pose_inserted")) then
		self.insertedPose = self.data.GetGameObject("pose_inserted").transform
	end
	if (self.data.HasObject("pose_inserting") and self.data.GetGameObject("pose_inserting")) then
		self.insertingPose = self.data.GetGameObject("pose_inserting").transform
	end
	if (self.data.HasObject("pose_ejected") and self.data.GetGameObject("pose_ejected")) then
		self.ejectedPose = self.data.GetGameObject("pose_ejected").transform
	end
	if (self.data.HasObject("pose_holsteredmag") and self.data.GetGameObject("pose_holsteredmag")) then
		self.holsteredPose = self.data.GetGameObject("pose_holsteredmag").transform
	end

	if (self.data.HasObject("pose_close") and self.data.GetGameObject("pose_close")) then
		self.closePose = self.data.GetGameObject("pose_close").transform
	end
	if (self.data.HasObject("pose_open") and self.data.GetGameObject("pose_open")) then
		self.openPose = self.data.GetGameObject("pose_open").transform
	end
end

function RC_PoseManager:GetEjectorPoses()
	if (self.data.HasObject("pose_rest") and self.data.GetGameObject("pose_rest")) then
		self.restEjectorPose = self.data.GetGameObject("pose_rest").transform
	end
	if (self.data.HasObject("pose_eject") and self.data.GetGameObject("pose_eject")) then
		self.ejectEjectorPose = self.data.GetGameObject("pose_eject").transform
	end
end

function RC_PoseManager:GetSlidePoses()
	if (self.data.HasObject("pose_normal") and self.data.GetGameObject("pose_normal")) then
		self.normalSlidePose = self.data.GetGameObject("pose_normal").transform
	end
	if (self.data.HasObject("pose_jolted") and self.data.GetGameObject("pose_jolted")) then
		self.joltedSlidePose = self.data.GetGameObject("pose_jolted").transform
	end
	if (self.data.HasObject("pose_racked") and self.data.GetGameObject("pose_racked")) then
		self.rackedSlidePose = self.data.GetGameObject("pose_racked").transform
	end
	if (self.data.HasObject("pose_locked") and self.data.GetGameObject("pose_locked")) then
		self.lockedSlidePose = self.data.GetGameObject("pose_locked").transform
	end
	if (self.data.HasObject("pose_stovepipe") and self.data.GetGameObject("pose_stovepipe")) then
		self.stovepipeSlidePose = self.data.GetGameObject("pose_stovepipe").transform
	end
	if (self.data.HasObject("pose_outofbattery") and self.data.GetGameObject("pose_outofbattery")) then
		self.outofbatterySlidePose = self.data.GetGameObject("pose_outofbattery").transform
	end
	if (self.data.HasObject("pose_doublefeed") and self.data.GetGameObject("pose_doublefeed")) then
		self.doublefeedSlidePose = self.data.GetGameObject("pose_doublefeed").transform
	end
end

function RC_PoseManager:GetSafetyPoses()
	if (self.data.HasObject("pose_safetyoff") and self.data.GetGameObject("pose_safetyoff")) then
		self.safetyOffPose = self.data.GetGameObject("pose_safetyoff").transform
	end
	if (self.data.HasObject("pose_safetyon") and self.data.GetGameObject("pose_safetyon")) then
		self.safetyOnPose = self.data.GetGameObject("pose_safetyon").transform
	end
end

function RC_PoseManager:GetSlideLockPoses()
	if (self.data.HasObject("pose_lockoff") and self.data.GetGameObject("pose_lockoff")) then
		self.unlockedPose = self.data.GetGameObject("pose_lockoff").transform
	end
	if (self.data.HasObject("pose_lockon") and self.data.GetGameObject("pose_lockon")) then
		self.lockedPose = self.data.GetGameObject("pose_lockon").transform
	end
end

function RC_PoseManager:GetHammerPoses()
	if (self.data.HasObject("pose_rest") and self.data.GetGameObject("pose_rest")) then
		self.hammerRestPose = self.data.GetGameObject("pose_rest").transform
	end
	if (self.data.HasObject("pose_halfcocked") and self.data.GetGameObject("pose_halfcocked")) then
		self.hammerHalfCockedPose = self.data.GetGameObject("pose_halfcocked").transform
	end
	if (self.data.HasObject("pose_safetydecocking") and self.data.GetGameObject("pose_safetydecocking")) then
		self.safetyDecockingPose = self.data.GetGameObject("pose_safetydecocking").transform
	end
	if (self.data.HasObject("pose_cocked") and self.data.GetGameObject("pose_cocked")) then
		self.hammerReadyPose = self.data.GetGameObject("pose_cocked").transform
	end
end

function RC_PoseManager:GetFiremodePoses()
	local firemodePoses = self.data.GetGameObjectArray("fmPose")

	if (#firemodePoses > 0) then
		self.fmPoses = {}

		for _,pose in pairs(firemodePoses) do
			if (pose) then
				self.fmPoses[#self.fmPoses+1] = pose.transform
			end
		end
	end
end

function RC_PoseManager:GetMagReleasePoses()
	if (self.data.HasObject("pose_releaseoff") and self.data.GetGameObject("pose_releaseoff")) then
		self.normalReleasePose = self.data.GetGameObject("pose_releaseoff").transform
	end
	if (self.data.HasObject("pose_releaseon") and self.data.GetGameObject("pose_releaseon")) then
		self.releasedPose = self.data.GetGameObject("pose_releaseon").transform
	end
end

function RC_PoseManager:GetTriggerPoses()
	if (self.data.HasObject("pose_normal") and self.data.GetGameObject("pose_normal")) then
		self.normalTriggerPose = self.data.GetGameObject("pose_normal").transform
	end
	if (self.data.HasObject("pose_pulled") and self.data.GetGameObject("pose_pulled")) then
		self.pulledTriggerPose = self.data.GetGameObject("pose_pulled").transform
	end
end

function RC_PoseManager:GetChamberedRoundPoses()
	if (self.data.HasObject("pose_rest") and self.data.GetGameObject("pose_rest")) then
		self.restBulletPose = self.data.GetGameObject("pose_rest").transform
	end
	if (self.data.HasObject("pose_jolted") and self.data.GetGameObject("pose_jolted")) then
		self.joltedBulletPose = self.data.GetGameObject("pose_jolted").transform
	end
	if (self.data.HasObject("pose_loading") and self.data.GetGameObject("pose_loading")) then
		self.loadingBulletPose = self.data.GetGameObject("pose_loading").transform
	end
end

function RC_PoseManager:GetSecondaryRoundPoses()
	if (self.data.HasObject("pose_rest") and self.data.GetGameObject("pose_rest")) then
		self.restSecBulletPose = self.data.GetGameObject("pose_rest").transform
	end
	if (self.data.HasObject("pose_stovepipe") and self.data.GetGameObject("pose_stovepipe")) then
		self.stovepipeSecBulletPose = self.data.GetGameObject("pose_stovepipe").transform
	end
	if (self.data.HasObject("pose_doublefeed") and self.data.GetGameObject("pose_doublefeed")) then
		self.doublefeedSecBulletPose = self.data.GetGameObject("pose_doublefeed").transform
	end
end

function RC_PoseManager:GetFlashlightPoses()
	if (self.data.HasObject("pose_holstered")) then
		self.flashlightHolsteredPose = self.data.GetGameObject("pose_holstered").transform
	end
	if (self.data.HasObject("pose_idle")) then
		self.flashlightIdlePose = self.data.GetGameObject("pose_idle").transform
	end
	if (self.data.HasObject("pose_mouthhold")) then
		self.flashlightMouthHold = self.data.GetGameObject("pose_mouthhold").transform
	end
end