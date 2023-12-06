-- low_quality_soarin © 2023-2024
-- A bolt action script, basically makes racking acts like toggle.
behaviour("RC_BoltAction")

function RC_BoltAction:Start()
    -- Base
    self.weaponBase = self.targets.weaponBase.GetComponent(ScriptedBehaviour).self

    self.boltBack = false
	self.canBoltBack = true

	self.alreadyPlayedJolt = false
end

function RC_BoltAction:OnDisable()
	-- This only fixes some issues, like not being able to cycle the bolt
	-- after being knocked down.
	self.canBoltBack = true
	self.alreadyPlayedJolt = false
end

function RC_BoltAction:Update()
    -- Toggle Rack
    -- Dirty way lmaooo.
    if (self.weaponBase) then
		-- Racking
        if (Input.GetKeyDown(self.weaponBase.removeBulletRackCloseKey) and
            not Input.GetKey(self.weaponBase.slideLockTapKey) and self.weaponBase:CanMoveSlide(true) and
            not self.weaponBase.mindControl and self.weaponBase:IsUIClosed() and self.canBoltBack) then
            -- Actions
			self.canBoltBack = false
            self.boltBack = not self.boltBack

			self.script.StartCoroutine(self:BoltBackCD())
        end

        if (not self.weaponBase.mindControl) then
			if (self.boltBack) then
				-- Bolt Back
				self.weaponBase:PullSlideActions()
	
				-- Slide lock
				if (not self.weaponBase:IsMagEmpty() and not self.weaponBase.ammoCarrierOut or
					self.weaponBase.ammoCarrierOut) then
					self.slideLocked = false
				end
			else
				-- Bolt Forward
				self.weaponBase.alreadyPlayedSlideBack = false
	
				-- Actions
				self.weaponBase:ReleaseSlideActions()
			end
		end

		-- Jolting
		if (self.weaponBase:IsUIClosed()) then
			if (Input.GetKey(self.weaponBase.slideLockTapKey) and self.weaponBase:CanMoveSlide(true) and not self.weaponBase.mindControl) then
				if (Input.GetKey(self.weaponBase.removeBulletRackCloseKey)) then
					self.weaponBase.isJolting = true
					self.weaponBase.hasJolted = true
	
					-- Play Sound
					if (not self.weaponBase.stovepipe and not self.weaponBase.doublefeed and not self.weaponBase.isRacking) then
						if (not self.alreadyPlayedJolt) then
							if (self.weaponBase.soundHandler) then
								self.weaponBase.soundHandler:PlaySound("slideback", 0.65)
							end
		
							self.alreadyPlayedJolt = true
						end
					end
				end
			else
				self.alreadyPlayedJolt = false
			end
		else
			self.alreadyPlayedJolt = false
		end

		if (Input.GetKeyUp(self.weaponBase.slideLockTapKey) or Input.GetKeyUp(self.weaponBase.removeBulletRackCloseKey) and self.weaponBase:CanMoveSlide(true)) then
			self.weaponBase.isJolting = false
			self.alreadyPlayedJolt = false
		end
    end
end

function RC_BoltAction:BoltBackCD()
	return function()
		coroutine.yield(WaitForSeconds(0.25))
		self.canBoltBack = true
	end
end
