-- low_quality_soarin © 2023-2024
behaviour("RC_Flashlight")

function RC_Flashlight:Awake()
	-- Nil fixes
	self.used = false
end

function RC_Flashlight:Start()
	-- Raveceiver Base
	if (self.targets.rcBase) then
		self.rcBase = self.targets.rcBase.GetComponent(ScriptedBehaviour).self
	end

	-- Keybinds
	self.holsterLightKey = "l"

	-- Apply Binds
	if (self.rcBase) then
		self.holsterLightKey = self.rcBase.holsterLightKey
	end

	-- Scripts
	self.poseHandler = self.targets.poseHandler.GetComponent(ScriptedBehaviour).self
	self.soundHandler = self.targets.soundHandler.GetComponent(ScriptedBehaviour).self

	-- Vars
	self.flashParent = self.targets.flashParent.transform
	self.flashAimPose = self.targets.flashAimPose.transform
	self.light = self.targets.light

	self.forceHolster = true
	self.isTwoHanded = false
	self.aim = false
	self.mouthHold = false

	-- Finishing
	self.light.SetActive(false)

	self.used = true
end

function RC_Flashlight:OnDisable()
	if (self.used) then
		self:HolsterBools()
	end
end

function RC_Flashlight:Update()
	-- Flashlight Self Input
	self:FlashSelfInput()

	-- Flashlight Weapon Input
	self:FlashWepInput()
end

function RC_Flashlight:FlashSelfInput()
	-- Flashlight holster system
	if (Input.GetKeyDown(self.holsterLightKey) and self:CanToggleFlash()) then
		self.forceHolster = not self.forceHolster

		if (not self.forceHolster) then
			self.light.SetActive(true)
			self.soundHandler:PlaySound("flashon")
		else
			self.light.SetActive(false)
			self.soundHandler:PlaySound("flashoff")
		end
	elseif (not self:CanToggleFlash()) then
		self:HolsterBools()
	end
end

function RC_Flashlight:HolsterBools()
	-- Resets the poseHandler controller bools
	-- And holsters the flashlight when called.
	self.light.SetActive(false)
	self.forceHolster = true

	self.twoHanded = false
	self.aim = false
	self.mouthHold = false
end

function RC_Flashlight:CanToggleFlash()
	local output = false

	if (not self.rcBase.customisationActive) then
		if (self.rcBase.rcScript) then
			if (not self.rcBase.mindControl) then
				output = true
			end
		end
	end

	return output
end

function RC_Flashlight:FlashWepInput()
	-- Control flashlight by weapon input
	-- For the poseHandler script.

	if (not self.rcBase) then return end
	if (not self.rcBase.rcScript) then return end

	local rcScript = self.rcBase.rcScript

	if (self.aim) then
		self:GetAimPos(rcScript)
	end

	self.isTwoHanded = rcScript.twoHanded
	self.aim = self:CanAim(rcScript)
	self.mouthHold = self:CanMouthHold(rcScript)
end

function RC_Flashlight:GetAimPos(rcScript)
	local poseHandler = rcScript.poseHandler

	if (poseHandler) then
		local gunTransform = poseHandler.gunTransform

		self.flashAimPose.localPosition = Vector3(
			gunTransform.localPosition.x + 0.12,
			gunTransform.localPosition.y - 0.045,
			gunTransform.localPosition.z + 0.25
		)
	end
end

function RC_Flashlight:CanMouthHold(rcScript)
	local output = false

	if (
		rcScript.ammoCarrierOut and 
		rcScript.magazineInHand or 
		rcScript.isReloading or 
		rcScript.isJolting or 
		rcScript.isRacking or 
		rcScript.mindControl or
		rcScript.twoHanded
	) then
		if (not self.forceHolster) then
			output = true
		end
	end

	return output
end

function RC_Flashlight:CanAim(rcScript)
	local output = false

	if (rcScript.isAiming) then
		if (not rcScript.ammoCarrierOut or not rcScript.magazineInHand) then
			if (not rcScript.isReloading) then
				if (not rcScript.isJolting) then
					if (not rcScript.isRacking) then
						if (not rcScript.isSprinting) then
							if (not rcScript.mindControl) then
								if (not self.forceHolster) then
									output = true
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
