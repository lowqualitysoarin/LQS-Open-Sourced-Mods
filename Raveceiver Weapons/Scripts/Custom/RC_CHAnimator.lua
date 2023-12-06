-- low_quality_soarin © 2023-2024
-- A custom script that only animates the charging handle or bolt when racked manually and ignores firing.
behaviour("RC_CHAnimator")

function RC_CHAnimator:Awake()
    -- Important Scripts
    self.weaponBase = self.targets.weaponBase.GetComponent(ScriptedBehaviour).self
end

function RC_CHAnimator:Start()
	-- Scripts
	if (self.gameObject.GetComponent(DataContainer)) then
		self.data = self.gameObject.GetComponent(DataContainer)
	end

	self.poseHandler = self.targets.poseHandler.GetComponent(ScriptedBehaviour).self

	-- Base
	if (self.targets.chTransform) then
		self.chTransform = self.targets.chTransform.transform
	end
	
	if (self.targets.chPoses) then
		self.chPoses = self.targets.chPoses.GetComponent(DataContainer)
	end

	-- Vars
	if (self.chPoses and self.chTransform) then
		self.targetChPose = self.chTransform
	end

	if (self.data) then
		if (self.data.HasBool("hasLockedState")) then
			self.hasLockedState = self.data.GetBool("hasLockedState")
		end
		if (self.data.HasBool("onlyLockWhenManuallyLocked")) then
			self.onlyLockWhenManuallyLocked = self.data.GetBool("onlyLockWhenManuallyLocked")
		end
	end
end

function RC_CHAnimator:Update()
	-- Animator
	if (self.targetChPose and self.poseHandler and self.chTransform and self.chPoses) then
		self.poseHandler:ProceduralAnimator(self.chTransform, self.targetChPose, 35, true, true)
	end

	-- Pose Handler
	self:CHPoseHandler()
end

function RC_CHAnimator:CHPoseHandler()
	if (self.chTransform and self.chPoses) then
		if (self.weaponBase.isRacking and not self.weaponBase.hasFired) then
            if (self.chPoses.HasObject("pose_racked")) then
				self.targetChPose = self.chPoses.GetGameObject("pose_racked").transform
			end
        elseif (self.weaponBase.isJolting and not self.weaponBase.hasFired) then
            if (self.chPoses.HasObject("pose_jolting")) then
                self.targetChPose = self.chPoses.GetGameObject("pose_jolting").transform
            end
		elseif (self:CanLock()) then
			if (self.chPoses.HasObject("pose_locked")) then
				self.targetChPose = self.chPoses.GetGameObject("pose_locked").transform
			end
        elseif (not self.weaponBase.hasFired) then
            if (self.chPoses.HasObject("pose_normal")) then
                self.targetChPose = self.chPoses.GetGameObject("pose_normal").transform
            end
        end
	end
end

function RC_CHAnimator:CanLock()
	if (self.hasLockedState) then
		if (not self.weaponBase.hasFired) then
			if (not self.onlyLockWhenManuallyLocked) then
				if (self.weaponBase.slideLocked) then
					return true
				end
			else
				if (self.weaponBase.manuallySlideLocked) then
					return true
				end
			end
		end
	end
	return false
end
