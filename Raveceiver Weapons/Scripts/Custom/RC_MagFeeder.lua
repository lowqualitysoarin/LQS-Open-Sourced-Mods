-- low_quality_soarin © 2023-2024
-- A animator for the mag feeder spring and head to add more detail or if the mag is just transparent.
behaviour("RC_MagFeeder")

function RC_MagFeeder:Start()
	-- Base
	self.ammoCarrier = self.targets.ammoCarrier.GetComponent(ScriptedBehaviour).self
	self.thisAnimator = self.gameObject.GetComponent(Animator)

	-- Vars
	self.ammoBaked = false
end

function RC_MagFeeder:Update()
	-- This one uses traditional animation, surely doing procedural one is a hassel.
	-- It will need a integer named "currentAmmo" in the animator for it to work properly.
	
	-- Determine ammo holder
	if (not self.ammoBaked) then
		if (self.ammoCarrier and self.thisAnimator and self.thisAnimator.GetInteger("currentAmmo")) then
			if (self.ammoCarrier.ammo) then
				-- Base Magazine
				-- This one is real time.
				self.thisAnimator.SetInteger("currentAmmo", self.ammoCarrier.ammo)
			elseif (self.ammoCarrier.storedAmmoCount) then
				-- Stored Magazine
				self.thisAnimator.SetInteger("currentAmmo", self.ammoCarrier.storedAmmoCount)
	
				-- Turn bool to true
				-- This only executes once since this is only for dropped magazines.
				self.ammoBaked = true
			end
		end
	end
end
