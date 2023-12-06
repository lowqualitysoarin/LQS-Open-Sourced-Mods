-- low_quality_soarin © 2023-2024
-- A script that replaces the base aiming pose into a desired aiming pose
behaviour("RC_Optic")

function RC_Optic:Awake()
	-- Awake vars
	self.isUsed = false
end

function RC_Optic:Start()
	-- Base
	self.gunPoses = self.targets.gunPoses.GetComponent(ScriptedBehaviour).self

	-- Vars
	self.defaultAim = self.gunPoses.aimPose
	self.targetAimPose = self.targets.targetAimPose.transform

	-- Finalize
	self.isUsed = true
	self:ToggleOptic(true)
end

function RC_Optic:OnEnable()
	if (self.isUsed) then
		self:ToggleOptic(true)
	end
end

function RC_Optic:OnDisable()
	if (self.isUsed) then
		self:ToggleOptic()
	end
end

function RC_Optic:ToggleOptic(active)
	-- Toggles the optic
	-- Convert nil to false bool
	if (active == nil) then
		active = false
	end

	-- Main
	if (active) then
		self.gunPoses.aimPose = self.targetAimPose
	else
		if (self.defaultAim) then
			self.gunPoses.aimPose = self.defaultAim
		end
	end
end
