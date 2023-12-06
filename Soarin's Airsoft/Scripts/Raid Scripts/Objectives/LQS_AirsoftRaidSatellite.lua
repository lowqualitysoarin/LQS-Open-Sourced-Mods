-- low_quality_soarin © 2023-2024
behaviour("LQS_AirsoftRaidSatellite")

function LQS_AirsoftRaidSatellite:Start()
	-- Base
	self.raidObjective = self.targets.raidObjective.GetComponent(ScriptedBehaviour).self

	self.satelliteNeck = self.targets.satelliteNeck.transform
	self.satelliteAnimator = self.raidObjective.gameObject.GetComponent(Animator)

	-- Listeners
	self.onSabotaged = function(arguments)
		self:OnSabotaged(arguments[1])
	end

	-- Vars
	self.stopUpdate = false

	self.rotDelayActive = false
	self.targetYRot = Quaternion.identity

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())
end

function LQS_AirsoftRaidSatellite:OnSabotaged()
	-- Stuff to do when the satellite was sabotaged
	self.satelliteAnimator.enabled = false
	self.stopUpdate = true
end

function LQS_AirsoftRaidSatellite:FinalizeSetup()
	return function()
		-- Add listener on the onSabotaged event
		self.raidObjective:ManageListeners(false, "onSabotaged", "[LQS:SA]SatelliteObjective", self.onSabotaged)

		-- Doing this to have a quite optimized update
		while (not self.stopUpdate) do
			-- Randomise neck y rot
			-- Kinda function the same as how the IASBY satellite neck's rotate, but more better lol
			self.script.StartCoroutine(self:GetNewZRot())
			self.satelliteNeck.localRotation = Quaternion.Lerp(self.satelliteNeck.localRotation, self.targetYRot, Time.deltaTime * 1)

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end
	end
end

function LQS_AirsoftRaidSatellite:GetNewZRot()
	return function()
		-- This basicall rotates the neck
		if (self.rotDelayActive) then return end
		self.rotDelayActive = true

		-- A 15 second delay before getting a new Z rot for the neck
		local timer = 15
		while (timer > 0) do
			timer = timer - 1 * Time.deltaTime
			coroutine.yield(WaitForSeconds(0))
		end

		-- Get a random float for the random Z rot, and apply rot
		local randomZRot = Random.Range(-360, 360)
		self.targetYRot = Quaternion.Euler(Vector3(0, 0, randomZRot))

		-- Reset rotDelayActive
		self.rotDelayActive = false
	end
end
