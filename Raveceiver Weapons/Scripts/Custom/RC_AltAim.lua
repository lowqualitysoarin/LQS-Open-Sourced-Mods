-- low_quality_soarin © 2023-2024
-- A script that gives a alternative aim system for weapons.
-- The first element of the table should be the default aim stance, unless if you only want the first stance appear once.
behaviour("RC_AltAim")

function RC_AltAim:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Scripts
	if (self.targets.gunPoses) then
		self.gunPoses = self.targets.gunPoses.GetComponent(ScriptedBehaviour).self
	end

	-- Vars
	self.altAimStances = self.data.GetGameObjectArray("aimStance")
	self.currentIndex = 1
end

function RC_AltAim:Update()
	-- Checks
	if (not self.gunPoses) then return end
	if (#self.altAimStances <= 0) then return end

	-- Change the aim stances with a press of a button
	if (Input.GetKeyDown(KeyCode.Y) and not GameManager.isPaused and not SpawnUi.isOpen) then
		-- Change the index
		if (self.currentIndex < #self.altAimStances) then
			self.currentIndex = self.currentIndex + 1
		else
			self.currentIndex = 1
		end

		-- Change the stance by index
		self.gunPoses.aimPose = self.altAimStances[self.currentIndex].transform
	end
end
