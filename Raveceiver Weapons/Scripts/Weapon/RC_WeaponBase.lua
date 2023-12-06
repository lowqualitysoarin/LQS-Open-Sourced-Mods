-- low_quality_soarin © 2023-2024
behaviour("RC_WeaponBase")

function RC_WeaponBase:Awake()
	-- Identifier
	-- Doing this to be identified on the raveceiver gamemode.
	self.aRaveceiverWeapon = true

	-- Check Bools
	self.alreadyUsed = false
	self.weaponReady = false
end

function RC_WeaponBase:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.thisWeapon = self.targets.weapon.GetComponent(Weapon)
	
	if (self.thisWeapon and self.thisWeapon.animator) then
		self.thisAnimator = self.thisWeapon.animator
		self.thisAnimator.SetLayerWeight(1, 0)
	end

	-- Important Scripts
	self.poseHandler = self.targets.poseHandler.GetComponent(ScriptedBehaviour).self
	self.weaponPartsManager = self.targets.weaponPartsManager.GetComponent(ScriptedBehaviour).self
	self.ammoCarrier = self.targets.ammoCarrier.GetComponent(RC_AmmoCarrier)

	-- Optional Scripts
	if (self.targets.soundHandler) then
		self.soundHandler = self.targets.soundHandler.GetComponent(ScriptedBehaviour).self
	end

	-- Heads Up Container
	-- Stores some details needed that the player should know when operating the firearm.
	if (self.targets.infoContainer) then
		self.infoContainer = self.targets.infoContainer.GetComponent(DataContainer)
	end

	-- Customisation
	-- This is for the customisation system.
	if (self.targets.customisationContainer) then
		self.customisationContainer = self.targets.customisationContainer.GetComponent(ScriptedBehaviour).self
	end

	-- Configuration Bools
	self.targetMagID = self.data.GetString("targetMagID")

	self.restrictSlideOnSafe = self.data.GetBool("restrictSlideOnSafe")
	self.restrictHammerOnSafe = self.data.GetBool("restrictHammerOnSafe")
	self.canJam = self.data.GetBool("canJam")

	self.decockerSafety = self.data.GetBool("decockerSafety")
	self.alwaysDecockWhenSafety = self.data.GetBool("alwaysDecockWhenSafety")
	self.doubleAction = self.data.GetBool("doubleAction")
	self.manualSafety = self.data.GetBool("manualSafety")
	self.slideLockSafety = self.data.GetBool("slideLockSafety")
	self.alwaysLockSlideSafety = self.data.GetBool("alwaysLockSlideSafety")
	self.firemodeSelector = self.data.GetBool("firemodeSelector")

	self.malfunctionChance = self.data.GetFloat("malfunctionChance")
	self.jamChance = self.data.GetFloat("jamChance")
	self.accidentalFireChance = self.data.GetFloat("accidentalFireChance")
	self.failureToFeedChance = self.data.GetFloat("failureToFeedChance")

	self.selfDamageAmount = self.data.GetFloat("selfDamageAmount")

	-- Optional
	-- Bools
	if (self.data.HasBool("spinnableCylinder")) then
		self.spinnableCylinder = self.data.GetBool("spinnableCylinder")
	end
	if (self.data.HasBool("cannotShootWhileMagOut")) then
		self.cannotShootWhileMagOut = self.data.GetBool("cannotShootWhileMagOut")
	end
	if (self.data.HasBool("canBeHalfCocked")) then
		self.canBeHalfCocked = self.data.GetBool("canBeHalfCocked")
	end
	if (self.data.HasBool("spinEjectRestrict")) then
		self.spinEjectRestrict = self.data.GetBool("spinEjectRestrict")
	end
	if (self.data.HasBool("dontRestrictHammerOut")) then
		self.dontRestrictHammerOut = self.data.GetBool("dontRestrictHammerOut")
	end
	if (self.data.HasBool("dontRestrictTriggerOut")) then
		self.dontRestrictTriggerOut = self.data.GetBool("dontRestrictTriggerOut")
	end
	if (self.data.HasBool("dontRestrictCarrierReady")) then
		self.dontRestrictCarrierReady = self.data.GetBool("dontRestrictCarrierReady")
	end
	if (self.data.HasBool("isFannable")) then
		self.isFannable = self.data.GetBool("isFannable")
	end
	if (self.data.HasBool("canCockHammerSafe")) then
		self.canCockHammerSafe = self.data.GetBool("canCockHammerSafe")
	end
	if (self.data.HasBool("canSafeSlidBack")) then
		self.canSafeSlidBack = self.data.GetBool("canSafeSlidBack")
	end
	if (self.data.HasBool("moveSafeHammerReady")) then
		self.moveSafeHammerReady = self.data.GetBool("moveSafeHammerReady")
	end
	if (self.data.HasBool("twoHanded")) then
		self.twoHanded = self.data.GetBool("twoHanded")
	end
	if (self.data.HasBool("disableSelfDamageSprinting")) then
		self.disableSelfDamageSprinting = self.data.GetBool("disableSelfDamageSprinting")
	end
	if (self.data.HasBool("onlyEjectWhenRackedDoublefeed")) then
		self.onlyEjectWhenRackedDoublefeed = self.data.GetBool("onlyEjectWhenRackedDoublefeed")
	end
	if (self.data.HasBool("disableSlideTap")) then
		self.disableSlideTap = self.data.GetBool("disableSlideTap")
	end
	if (self.data.HasBool("notCockable")) then
		self.notCockable = self.data.GetBool("notCockable")
	end
	if (self.data.HasBool("noSelfLoading")) then
		self.noSelfLoading = self.data.GetBool("noSelfLoading")
	end
	if (self.data.HasBool("forceDisableAimDeadzone")) then
		self.forceDisableAimDeadzone = self.data.GetBool("forceDisableAimDeadzone")
	end
	if (self.data.HasBool("notRackable")) then
		self.notRackable = self.data.GetBool("notRackable")
	end
	if (self.data.HasBool("disableDoubleFeed")) then
		self.disableDoubleFeed = self.data.GetBool("disableDoubleFeed")
	end
	if (self.data.HasBool("disableStovepipe")) then
		self.disableStovepipe = self.data.GetBool("disableStovepipe")
	end
	if (self.data.HasBool("disableOutOfBattery")) then
		self.disableOutOfBattery = self.data.GetBool("disableOutOfBattery")
	end
	if (self.data.HasBool("disableFailureToFeed")) then
		self.disableFailureToFeed = self.data.GetBool("disableFailureToFeed")
	end
	if (self.data.HasBool("disableWronglySeatedMag")) then
		self.disableWronglySeatedMag = self.data.GetBool("disableWronglySeatedMag")
	end
	if (self.data.HasBool("dontLockWhenEmpty")) then
		self.dontLockWhenEmpty = self.data.GetBool("dontLockWhenEmpty")
	end
	if (self.data.HasBool("isAuto")) then
		self.fm1 = -1
	end
	if (self.data.HasBool("onlyReleaseWhenManuallyLocked")) then
		self.onlyReleaseWhenManuallyLocked = self.data.GetBool("onlyReleaseWhenManuallyLocked")
	end
	if (self.data.HasBool("disableSlideLock")) then
		self.disableSlideLock = self.data.GetBool("disableSlideLock")
	end
	if (self.data.HasBool("noEjectForce")) then
		self.noEjectForce = self.data.GetBool("noEjectForce")
	end

	-- Floats
	if (self.data.HasFloat("slideEventThresholds")) then
		self.slideEventThresholds = self.data.GetFloat("slideEventThresholds")
	end
	if (self.data.HasFloat("hammerReadyThreshold")) then
		self.hammerReadyThreshold = self.data.GetFloat("hammerReadyThreshold")
	end
	if (self.data.HasFloat("hammerMiddleThreshold")) then
		self.hammerMiddleThreshold = self.data.GetFloat("hammerMiddleThreshold")
	end
	if (self.data.HasFloat("hammerRestThreshold")) then
		self.hammerRestThreshold = self.data.GetFloat("hammerRestThreshold")
	end

	-- Gameplay Bools
	self.accidentalDischarges = true
	self.randomisedConditions = true
	self.allowBlinking = true
	self.allowAimShake = true

	-- Keybinds
	self.holsterKey = "`"
	self.toggleAimKey = "q"

	self.carrierOutKey = "e"
	self.carrierInInsertBulletKey = "x"
	self.removeBulletRackCloseKey = "r"

	self.slideLockTapKey = "t"
	self.pullHammerKey = "f"

	self.safetyFiremodeEjectKey = "b"
	self.altFiremodeKey = "c"

	self.cylinderSpinLeftKey = "j"
	self.cylinderSpinRightKey = "k"

	-- Raveceiver Base
	self.rcBase = nil

	-- Weapon Vars
	-- Weapon Chamber
	self.oneInTheChamber = false
	self.usedRound = false
	self.hasRacked = false
	self.canRack = true
	self.canFire = true
	self.timeHeldTrigger = 0
	self.currentBullet = nil

	-- Hammer
	self.canCockHammer = true
	self.tempDisableTriggerHammer = false
	self.tempDisableFiring = false
	self.halfCocked = false

	-- Reloading And Systems
	self.alreadyLoaded = false
	self.canReleaseSlide = false
	self.canToggleSlideLock = true
	self.canReload = true
	self.receiveRoundSuccess = false
	self.alreadyCheckedChamber = false

	-- Firemode
	if (not self.fm1) then
		self.fm1 = 1
	end

	-- Get all firemode ints
	self.currentFiremodeIndex = 1

	if (self.firemodeSelector) then
		if (self.data.HasString("firemodeIterations")) then
			self.firemodeInts = {}

			for int in string.gmatch(self.data.GetString("firemodeIterations"), '([^;]+)') do
				local number = tonumber(int)
				self.firemodeInts[#self.firemodeInts+1] = number
			end
		end
	end
	
	self.timesFired = 0
	self.canSwitchModes = true

	-- Safety
	self.alreadyTriggeredSafety = false
	self.alreadyDisabledSafety = false
	self.manualSafetyOn = false
	self.safetyDecocking = false
	self.canToggleSafety = true

	-- Holster System
	self.isHolstered = false
	self.pressedHolsterButton = false
	self.tempDisableHolster = false
	self.alreadyHolstered = false
	self.forceHolster = false
	self.timeHeldHolster = 0

	-- Accidental Discharges, Malfunctions, Jams
	self.alreadyShot = false
	self.isJammed = false

	self.stovepipe = false
	self.outofbattery = false
	self.doublefeed = false
	self.failToEject = false
	self.failToFeed = false
	self.wronglyseatedmag = false

	self.doublefeedCleared = false

	-- Raveceiver Events
	self.mindControl = false

	-- Event Tracker Bools
	-- Slide
	self.slidBack = false
	self.slideRacked = false
	self.hasLoaded = true
	self.lockedByLoad = false
	self.alreadyCalledSlideRest = true
	self.alreadyCalledSlideBack = false
	self.alreadyCalledSlideJolt = false

	if (not self.slideEventThresholds) then
		self.slideEventThresholds = 0.01
	end

	-- Ammo Carrier
	self.ammoCarrierOut = false
	self.canRotateCarrier = true

	-- Hammer
	self.isHoldingHammer = false
	self.isTriggeringHammer = false
	self.hammerReady = false
	self.alreadyDisengagedHammer = false
	self.isDecockingHammer = false
	self.decockingHammer = false
	self.alreadyCalledHammerRest = false
	self.alreadyCalledHammerReady = true
	self.alreadyCalledHammerMiddle = false

	if (not self.hammerReadyThreshold) then
		self.hammerReadyThreshold = 5
	end
	if (not self.hammerMiddleThreshold) then
		self.hammerMiddleThreshold = 15
	end
	if (not self.hammerRestThreshold) then
		self.hammerRestThreshold = 5
	end

	-- Sound Input Bools
	self.alreadyPlayedSlideBack = false
	self.alreadyPlayedJolt = false
	self.hasJolted = false
	self.alreadyPlayedSlideLockOn = false
	self.alreadyPlayedSlideLockOff = true
	self.alreadyPlayedSafetyOn = false
	self.alreadyPlayedSafetyOff = false
	self.alreadyTriggeredEjectStart = false
	self.alreadyTriggeredEjectStop = false

	-- Weapon Input Bools
	self.isAiming = false
	self.isUsingToggleAim = false
	self.isSprinting = false

    self.isRacking = false
    self.isJolting = false
	self.slideLocked = false
	self.manuallySlideLocked = false

	self.isHoldingEject = false
	self.hasEjected = false

    self.safetyOn = false
	self.isHoldingRelease = false

    self.isHoldingTrigger = false
    self.hasFired = false
	self.isFiring = false

    self.isReloading = false
	self.insertedMag = true
	self.isHoldingCloseKey = false

	-- Gameplay
	-- Aim Sway
	self.curSwayFreq = 0

	self.aimSwayMax = self.data.GetFloat("aimSwayMax")
	self.aimSwayMultiplier = self.data.GetFloat("aimSwayMultiplier")
	self.swayShootAdd = self.data.GetFloat("swayShootAdd")
	self.swayDecreaseMultiplier = self.data.GetFloat("swayDecreaseMultiplier")

	self.canResupply = true

	-- Mag Swap System
	self.currentMagIndex = 1
	self.magazineInHand = true
	self.isSwappingMags = false

	-- Effects/Misc
	self.jamRoundCasing = nil
	self.jamRoundLive = nil

	if (self.data.HasObject("dynamicCasing")) then
		self.dynamicCasing = self.data.GetGameObject("dynamicCasing")
	end
	if (self.data.HasObject("dynamicRound")) then
		self.dynamicRound = self.data.GetGameObject("dynamicRound")
	end
	if (self.data.HasObject("magazineObj")) then
		self.magazineObj = self.data.GetGameObject("magazineObj")
	end

	if (self.data.HasObject("ejectionPos")) then
		self.ejectionPos = self.data.GetGameObject("ejectionPos").transform
	end
	if (self.data.HasObject("doublefeedEjectionPos")) then
		self.doublefeedEjectionPos = self.data.GetGameObject("doublefeedEjectionPos").transform
	end
	if (self.data.HasObject("stovepipeEjectionPos")) then
		self.stovepipeEjectionPos = self.data.GetGameObject("stovepipeEjectionPos").transform
	end

	-- Finishing Touches

	-- Prespawn bullet objects
	-- It will not work if the the weapon has a cylinder.
	-- Since the ammo carrier script has it's own instantiate system.
	self:InstantiateRound(false, false, false, true)
	self:PrespawnMag()

	if (self.weaponPartsManager.hasCylinder) then
		if (self.ammoCarrier and self.dynamicRound and self.dynamicCasing) then
			self.ammoCarrier:InstantiateRound(Vector3.zero, false, self.dynamicRound, self.dynamicCasing, true)
		end
	end

	-- Start Setup
	-- If the base mutator exists. If no it will use the settings above.
	-- New approach it will do the rest. of the setup
	self.script.StartCoroutine(self:StartSetup())

	-- Used bool
	-- To prevent nil errors when disabled on the first place.
	self.alreadyUsed = true

	-- Put isHolstered to false when used.
	if (self.alreadyUsed) then
		self.isHolstered = false
	end

	-- I forgot what does this do lmao
	-- But I'm keeping it for case sensitive.
	self.count = 1
end

function RC_WeaponBase:OnDisable()
	if (self.alreadyUsed) then
		-- Bools
		self.isHolstered = true

		-- Fixes
		self:OnDisableFixes()

		-- Systems
		self:ToggleSystemAllowBools(false)

		-- Visual
		self.poseHandler:SetToHolsterPos()
	end
end

function RC_WeaponBase:OnDisableFixes()
	-- Firing
	if (self.hasFired) then
		-- Disbale fire bools
		self.hasFired = false
		self.isFiring = false

		-- Semi-Auto weps fixes
		if (self.weaponPartsManager.hasSlide) then
			if (self.oneInTheChamber) then
				self.poseHandler:InstantPoseHammer(true)
			end
		end
	end

	-- Mag fixes
	if (self.weaponPartsManager.hasMag) then
		-- Reload Fixes
		if (self.ammoCarrierOut and self.isReloading) then
			self.poseHandler:InstantUnload(false)
		end

		-- Swapping Fixes
		if (self.isSwappingMags) then
			self.isSwappingMags = false
		end
	end

	-- Animation Fixes
	self.poseHandler.stopGunPoses = false

	-- Other Fixes
	self.canResupply = true
	self.pressedHolsterButton = false
	self.tempDisableFeatures = false
end

function RC_WeaponBase:OnEnable()
	if (self.alreadyUsed) then
		-- If the weapon failed to start then restart
		if (not self.weaponReady) then
			self.script.StartCoroutine(self:StartSetup())
		end

		-- Bools
		self.isHolstered = false
		self.forceHolster = false

		-- Animation Fixes
		if (self.thisAnimator) then
			self.thisAnimator.SetLayerWeight(1, 0)
		end

		-- Sytems
		self:ToggleSystemAllowBools(true)
	end
end

function RC_WeaponBase:PrespawnMag()
	-- Prespawns the magazine object
	if (self.magazineObj) then
		local magObj = GameObject.Instantiate(self.magazineObj)
		GameObject.Destroy(magObj, 0.15)
	end
end

function RC_WeaponBase:StartSetup()
	return function()
		coroutine.yield(WaitForSeconds(0.05))
		-- Apply Settings
		-- Find the base mutator
		local baseOBJ = GameObject.Find("[LQS]RaveceiverWeaponsBase(Clone)")

		-- If it exists then get the scripted behaviour and start applying
		-- the settings.
		if (baseOBJ) then
			local behaviour = baseOBJ.gameObject.GetComponent(ScriptedBehaviour)
	
			-- Have to double check
			if (behaviour) then
				local rcSets = behaviour.self
	
				-- Cache the RCBase script
				self.rcBase = rcSets
	
				-- Apply Gameplay Settings
				self.accidentalDischarges = rcSets.enableAccidentalDischarges
				self.randomisedConditions = rcSets.randomisedConditions
				self.allowBlinking = rcSets.allowBlinking
				self.allowAimShake = rcSets.allowAimShake

				if (self.canJam) then
					self.canJam = rcSets.enableJamming
				end
	
				-- Apply Keybinds
				self.holsterKey = rcSets.holsterKey
				self.toggleAimKey = rcSets.toggleAimKey
	
				self.carrierOutKey = rcSets.carrierOutKey
				self.carrierInInsertBulletKey = rcSets.carrierInInsertBulletKey
				self.removeBulletRackCloseKey = rcSets.removeBulletRackCloseKey
	
				self.slideLockTapKey = rcSets.slideLockTapKey
				self.pullHammerKey = rcSets.pullHammerKey
	
				self.safetyFiremodeEjectKey = rcSets.safetyFiremodeEjectKey
				self.altFiremodeKey = rcSets.altFiremodeKey
	
				self.cylinderSpinLeftKey = rcSets.cylinderSpinLeftKey
				self.cylinderSpinRightKey = rcSets.cylinderSpinRightKey
			end
		end

		coroutine.yield(WaitForSeconds(0.05))

		-- Condition Randomizer
    	-- Randomizes conditions everytime when spawning with the weapon
    	-- Only if enabled.
    	if (self.randomisedConditions) then
    	  	self.script.StartCoroutine(self:RandomizeConditions())
    	end

		coroutine.yield(WaitForSeconds(0.05))

		-- Final Weapon Setup
		self.script.StartCoroutine(self:FinalWeaponSetup())
	end
end

function RC_WeaponBase:RandomizeConditions()
	return function()
		-- Randomize Main Gun States
		if (self.weaponPartsManager) then
			if (self.weaponPartsManager.hasSlide) then
				-- Slide
				if (self.weaponPartsManager.hasSlideStop or self.slideLockSafety) then
					self.slideLocked = self:RandomBool()

					-- Manually locked bool
					if (self.onlyReleaseWhenManuallyLocked and self.slideLocked) then
						self.manuallySlideLocked = self:RandomBool()
					end
				end
				
				-- Chamber
				if (not self.slideLocked) then
					self.oneInTheChamber = self:RandomBool()
					
					if (self.weaponPartsManager.hasHammer) then
						if (not self.notCockable) then
							self.poseHandler:InstantPoseHammer(self:RandomBool())
						else
							self.poseHandler:InstantPoseHammer(true)
						end
					else
						self.slideRacked = true
					end
				else
					if (self.weaponPartsManager.hasHammer) then
						self.poseHandler:InstantPoseHammer(true)
					else
						self.slideRacked = self:RandomBool()
					end
				end
			elseif (self.weaponPartsManager.hasHammer) then
				if (not self.notCockable) then
					self.poseHandler:InstantPoseHammer(self:RandomBool())
				else
					self.poseHandler:InstantPoseHammer(true)
				end
			end

			-- Ammo Carrier
			self.ammoCarrierOut = self:RandomBool()

			-- Safety
			if (not self.decockerSafety and self.manualSafety or self.decockerSafety and self.manualSafety) then
				self.safetyOn = self:GetSafetyState()
			end

			-- Firemode
			if (self.firemodeSelector and self.firemodeInts) then
				self.currentFiremodeIndex = math.random(#self.firemodeInts)
				self.fm1 = self.firemodeInts[self.currentFiremodeIndex]
			end
		end

		-- Randomize Ammo and Spare Ammo Count
		-- If the ammo carrier/magazine script exists.
		if (self.ammoCarrier) then
			self.ammoCarrier:RandomizeAmmo(self.weaponPartsManager.hasMag)
		end
	end
end

function RC_WeaponBase:GetSafetyState()
	-- Gets the safety state to prevent the gun being locked for some reason. Especially the ones
	-- that can only toggle the safety if the hammer is cocked.
	if (not self.restrictSlideOnSafe and not self.slideLockSafety) then
		if (not self.moveSafeHammerReady) then
			return self:RandomBool()
		elseif (self.moveSafeHammerReady and self.hammerReady) then
			return self:RandomBool()
		else
			return false
		end
	elseif (self.restrictSlideOnSafe and not self.slideLockSafety and not self.slideLocked) then
		if (not self.moveSafeHammerReady) then
			return self:RandomBool()
		elseif (self.moveSafeHammerReady and self.hammerReady) then
			return self:RandomBool()
		else
			return false
		end
	elseif (self.slideLockSafety and self.slideLocked) then
		return true
	end
end

function RC_WeaponBase:RandomBool()
	-- Random boolean for randomizing states.
	if (Random.Range(0, 100) < 50) then
		return true
	end

	return false
end

function RC_WeaponBase:FinalWeaponSetup()
	return function()
		-- Get Secondary Round Objects
		if (self.poseHandler.secBulletTransform) then
			local secBullet = self.poseHandler.secBulletTransform.gameObject.GetComponent(DataContainer)

			if (secBullet) then
				-- Casing
				if (secBullet.HasObject("casing")) then
					self.jamRoundCasing = secBullet.GetGameObject("casing")
				end

				-- Live Round
				if (secBullet.HasObject("live")) then
					self.jamRoundLive = secBullet.GetGameObject("live")
				end
			end
		end

		-- Only works if the weapon has a mag
		if (self.weaponPartsManager.hasMag and self.ammoCarrier) then
			-- Setup mags, if not randomized
			if (not self.randomisedConditions) then
				self.ammoCarrier:SetupMags(2)
			end

			-- Pass the magObj
			self.ammoCarrier.magObj = self.magazineObj
		end

		-- Chambered Round
		if (self.poseHandler.bulletTransform) then
			local round = self.poseHandler.bulletTransform.gameObject
	
			if (self.oneInTheChamber) then
				round.SetActive(true)
			else
				round.SetActive(false)
			end
		end

		-- Check if ammo carrier out
		if (self.ammoCarrierOut) then
			self.poseHandler:InstantUnload(self.weaponPartsManager.hasCylinder)
			self.insertedMag = false
		end

		-- Holster
		self.poseHandler:SetToHolsterPos()

		-- Tick weaponReady to true
		-- This is different from weaponUsed.
		self.weaponReady = true
	end
end

function RC_WeaponBase:IsUIClosed()
	local output = true

	if (SpawnUi.isOpen) then
		output = false
	end

	return output
end

function RC_WeaponBase:Update()
	if (Time.timeScale > 0) then
	    -- Weapon Systems
		self:WeaponSystems()

		-- Weapon Input
		self:WeaponInputs()

		-- Gameplay Systems
		self:GameplaySystems()
	end
end

function RC_WeaponBase:GameplaySystems()
	-- Vars
	local gunTransform = self.poseHandler.gunTransform
	local player = Player.actor

	-- Aim Sway
	if (self.allowAimShake and not self:IsCustomising()) then
		if (gunTransform) then
			-- Calculate Sway Freq
			if (self.isAiming) then
				self.curSwayFreq = self.curSwayFreq + self.aimSwayMultiplier * Time.deltaTime
			else
				self.curSwayFreq = self.curSwayFreq - self.swayDecreaseMultiplier * Time.deltaTime
			end
	
			-- Clamp Sway Freq And Apply Shake
			self.curSwayFreq = Mathf.Clamp(self.curSwayFreq, 0, self.aimSwayMax)
			gunTransform.rotation = gunTransform.rotation * Quaternion.Euler(self:Shake(self.curSwayFreq, 5.0))
		end
	end

	-- Ammo Resupply
	if (self.ammoCarrier and player) then
		if (not player.isDead and self:IsResupplying() and self.canResupply) then
			self.canResupply = false
			self.ammoCarrier:ResupplyAmmo(true, 1, true)

			self.script.StartCoroutine(self:ResetResupply())
		end
	end
end

function RC_WeaponBase:IsCustomising()
	local output = false

	if (self.rcBase) then
		if (self.rcBase.customisationActive) then
			output = true
		end
	end

	return output
end

function RC_WeaponBase:IsResupplying()
	local output = false

	if (Player.actor.isResupplyingAmmo) then
		output = true
	end

	return output
end

function RC_WeaponBase:ResetResupply()
	return function()
		coroutine.yield(WaitForSeconds(3))
		self.canResupply = true
	end
end

function RC_WeaponBase:Shake(intensity, speed)
	-- Gun Shaker
	-- Very Similar to the suicide system's shaker.
	local x = Mathf.PerlinNoise(Time.time * speed, 0.0) * 2.0 - 1.0
    local y = Mathf.PerlinNoise(0.0, Time.time * speed) * 2.0 - 1.0
    local z = Mathf.PerlinNoise(Time.time * speed, Time.time * speed) * 2.0 - 1.0

    local shake = Vector3(x, y, z) * intensity

    return shake
end

function RC_WeaponBase:WeaponSystems()
	-- Firing
	if (self:IsUIClosed() and not self.mindControl) then
		if (not self:CannotShootWhileMagOut()) then
			if (self.hasLoaded) then
				-- New Firing System
				-- To make it more compresible, because the old one is a mess.
				if (self.doubleAction) then
					if (self.isHoldingTrigger and not self:CanEngage() and self:CanTriggerHammer() and not self.isHolstered) then
						self.isTriggeringHammer = true
					elseif (not self.isHoldingTrigger or self:CanEngage() and not self.isHolstered) then
						self.isTriggeringHammer = false
					end
				end
	
				if (not self.isHoldingTrigger) then
					self.tempDisableFiring = false
					self.tempDisableTriggerHammer = false

					self.timesFired = 0
					self.isFiring = false
				end
	
				if (not self.tempDisableFiring and self:CanTriggerHammer()) then
					if (self.isHoldingTrigger and self:CanShoot() and self:CanEngage() and not self.isHolstered) then
						self:FireWeapon(false, false)
	
						if (self.timesFired >= self.fm1 and self.fm1 > -1) then
							if (not self.isFannable) then
								self.tempDisableFiring = true
								self.tempDisableTriggerHammer = true
							end
						end
					elseif (self.isHoldingTrigger and not self:CanShoot() and self:CanEngage() and self:CanDryFire() and not self.isHolstered) then
						self:DryFire()
	
						if (self.timesFired >= self.fm1 and self.fm1 > -1) then
							if (not self.isFannable) then
								self.tempDisableFiring = true
								self.tempDisableTriggerHammer = true
							end
						end
					end
				end
			end
		end
	end

	-- Mag Events
	self:AmmoCarrierEventTracker()

	-- Slide Events
	if (self.weaponPartsManager.hasSlide) then
		self:SlideEventTracker()
	end

	-- Hammer Events
	if (self.weaponPartsManager.hasHammer) then
		self:HammerEventTracker()
	end

	-- Safety
	if (self.safetyOn) then
		if (not self.alreadyTriggeredSafety) then
			-- Trigger Safety
			self:TriggerSafetyType()

			-- Play Sound
			if (not self.alreadyPlayedSafetyOn and self.weaponReady) then
				if (self.soundHandler) then
					self.soundHandler:PlaySound("safety")
				end

				self.alreadyPlayedSafetyOn = true
			end
		end

		self.alreadyPlayedSafetyOff = false
		self.alreadyDisabledSafety = false
	else
		if (not self.alreadyDisabledSafety) then
			-- Trigger Safety
			self:DisableSafetyType()

			-- Play Sound
			if (not self.alreadyPlayedSafetyOff and self.weaponReady) then
				if (self.soundHandler) then
					self.soundHandler:PlaySound("safety")
				end

				self.alreadyPlayedSafetyOff = true
			end
		end

		self.alreadyPlayedSafetyOn = false
		self.alreadyTriggeredSafety = false
	end

	-- Reloading
	if (self:CanUseCarrier()) then
		if (self:CanLoadBullet() and self:IsUIClosed()) then
			if (Input.GetKeyDown(self.carrierInInsertBulletKey)) then
				-- Insert Bullet
				self.ammoCarrier:IncreaseAmmo(self.soundHandler)
			end
		end

		if (self:CanUnloadBullet() and self:IsUIClosed()) then
			if (Input.GetKeyDown(self.removeBulletRackCloseKey)) then
				-- Unload Bullet
				self.ammoCarrier:DecreaseAmmo(true, self.soundHandler)
			end
		end
	end

	-- Holster System
	if (not self.mindControl and not self.tempDisableFeatures and self:IsUIClosed()) then
		if (Input.GetKeyDown(self.holsterKey)) then
			self.pressedHolsterButton = true
		end
	
		if (Input.GetKey(self.holsterKey)) then
			self.timeHeldHolster = self.timeHeldHolster + 1 * Time.deltaTime
	
			if (not self.tempDisableHolster and self.timeHeldHolster > 0.1) then
				self.isHolstered = not self.isHolstered
	
				self.alreadyShot = false
				self.alreadyHolstered = false
	
				if (self.isHolstered) then
					self:HolsterSystem(true, true)
				else
					self:HolsterSystem(false, true)
				end
	
				self.tempDisableHolster = true
			end
		elseif (Input.GetKeyUp(self.holsterKey) and self.pressedHolsterButton and self.timeHeldHolster < 0.1) then
			self.isHolstered = not self.isHolstered
	
			self.alreadyShot = false
			self.alreadyHolstered = false
	
			if (self.isHolstered) then
				self:HolsterSystem(true, false)
			else
				self:HolsterSystem(false, false)
			end
		end
	
		if (Input.GetKeyUp(self.holsterKey)) then
			self.tempDisableHolster = false
			self.pressedHolsterButton = false
			self.timeHeldHolster = 0
		end
	end

	-- Only works if the weapon has a cylinder
	if (self.weaponPartsManager.hasCylinder) then
		-- Ejector System
		if (self.isHoldingEject and not self.tempDisableFeatures and not self.mindControl) then
			if (not self.alreadyTriggeredEjectStart and self.weaponReady) then
				-- Eject Bullets
				if (self.ammoCarrier) then
					self.ammoCarrier:DecreaseAmmoCylinder(false, true, self.dynamicCasing, self.dynamicRound)
				end

				-- Play Sound
				if (self.soundHandler) then
					self.soundHandler:PlaySound("ejectstart")
				end

				-- Tick Bool
				self.alreadyTriggeredEjectStart = true
				self.alreadyTriggeredEjectStop = false
			end
		elseif (not self.isHoldingEject and self.hasEjected) then
			if (not self.alreadyTriggeredEjectStop and self.weaponReady) then
				-- Play Sound
				if (self.soundHandler) then
					self.soundHandler:PlaySound("ejectstop")
				end

				-- Tick bool
				self.alreadyTriggeredEjectStop = true
				self.alreadyTriggeredEjectStart = false
			end
		end

		-- Cylinder Spin
		if (self.ammoCarrier) then
			if (self:CanSpin() and self:IsUIClosed()) then
				if (self.spinnableCylinder) then
					if (Input.GetKeyDown(self.cylinderSpinLeftKey)) then
						self.ammoCarrier:StartRotate(true, true)
					elseif (Input.GetKeyDown(self.cylinderSpinRightKey)) then
						self.ammoCarrier:StartRotate(true, false)
					end
				end
			end
		end

		-- Chamber Check
    	if (self.weaponPartsManager.hasCylinder) then
    		self:ChamberCheck()
	    end
 	end

	-- Only works if the weapon has a mag
	if (self.weaponPartsManager.hasMag) then
		-- Magazine swap system
		if (self.ammoCarrier and self:CanSwapMags() and self:IsUIClosed()) then
			if (Input.GetKeyDown(KeyCode.Alpha7)) then
				self:SwapMagazines(1)
			elseif (Input.GetKeyDown(KeyCode.Alpha8)) then
				self:SwapMagazines(2)
			elseif (Input.GetKeyDown(KeyCode.Alpha9)) then
				self:SwapMagazines(3)
			elseif (Input.GetKeyDown(KeyCode.Alpha0)) then
				self:SwapMagazines(4)
			end
		end
	end
end

function RC_WeaponBase:CanUseCarrier()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.mindControl) then
			if (self.ammoCarrierOut) then
				if (self.weaponPartsManager.hasCylinder) then
					if (not self.isHolstered) then
						output = true
					end
				else
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanSwapMags()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.isSwappingMags) then
			if (not self.isReloading) then
				if (self.ammoCarrierOut) then
					if (not self.mindControl) then
						output = true
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:SwapMagazines(newIndex)
	-- Magazine swap system
	-- Checks
	if (self:CanCancelSwap(newIndex)) then 
		-- If the player has a magazine in hand and pressed the same index then holster the mag
		if (self.currentMagIndex == newIndex and self.magazineInHand) then
			-- Save data
			self.ammoCarrier:MagManager(self.currentMagIndex, "save")

			-- Holster mag
			self.poseHandler:HolsterMag()
			self.magazineInHand = false
		end

		-- Break function
		return 
	end

	-- Start Swapping
	self.poseHandler:StartSwapMags(newIndex)
end

function RC_WeaponBase:CanCancelSwap(newIndex)
	-- Another fucking check
	local output = false

	if (
		self.currentMagIndex == newIndex and self.magazineInHand or
		not self.ammoCarrier.magData[newIndex]
	) then
		output = true
	end

	return output
end

function RC_WeaponBase:OnMagazineSwap(newIndex)
	-- Base swap system
	-- Save the current magazine data
	if (self.magazineInHand) then
		self.ammoCarrier:MagManager(self.currentMagIndex, "save")
	end

	-- Load the new magazine and set the new index
	if (self.ammoCarrier:MagManager(newIndex, "load")) then
		self.currentMagIndex = newIndex

		-- Enable mag
		self.magazineInHand = true
		self.ammoCarrier.magObjOrig.SetActive(true)
	end
end

function RC_WeaponBase:CanSpin()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.mindControl) then
			if (self.spinEjectRestrict) then
				if (not self.isHoldingEject) then
					if (self.ammoCarrier.useReloadIndex) then
						if (self.ammoCarrier.isOnReloadMode) then
							output = true
						end
					else
						if (self.ammoCarrierOut) then
							output = true
						end
					end
				end
			else
				if (self.ammoCarrierOut) then
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CannotShootWhileMagOut()
	-- For some guns like the Hi-Point C9
	local output = false

	if (self.cannotShootWhileMagOut) then
		if (self.ammoCarrierOut) then
			output = true
		end
	end

	return output
end

function RC_WeaponBase:ChamberCheck()
	-- Checks which current roll of the cylinder is on top.
	if (self.ammoCarrier) then
		if (self.ammoCarrier.currentBullet) then
			self.currentBullet = self.ammoCarrier.currentBullet
			
			local isLive = self.currentBullet[2]
			local isGone = self.currentBullet[3]

			if (isLive and not isGone) then
				self.oneInTheChamber = true
			else
				self.oneInTheChamber = false
			end
		end
	end
end

function RC_WeaponBase:CanUnloadBullet()
	local output = false

	if (not self:IsMagEmpty()) then
		if (not self.weaponPartsManager.hasCylinder) then
			if (self.magazineInHand) then
				if (self.isHolstered) then
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanLoadBullet()
	local output = false

	if (not self.weaponPartsManager.hasCylinder) then
		if (self.ammoCarrier.ammo < self.ammoCarrier.maxAmmo and self.ammoCarrier.spareAmmo > 0) then
			if (self.magazineInHand) then
				if (self.isHolstered) then
					output = true
				end
			end
		end
	else
		if (self.ammoCarrier.ammo < self.ammoCarrier.maxAmmo and self.ammoCarrier.spareAmmo > 0) then
			if (not self.isHoldingEject) then
				if (self.ammoCarrier.useReloadIndex) then
					if (self.ammoCarrier.isOnReloadMode) then
						output = true
					end
				else
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanTriggerHammer()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.tempDisableTriggerHammer) then
			if (not self.isHoldingHammer) then
				if (not self.isDecockingHammer) then
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanDryFire()
	local output = false

	if (not self.isHoldingHammer) then
		if (not self.safetyDecocking) then
			if (not self.isJolting) then
				if (not self.isRacking) then
					if (not self.isJammed) then
						if (not self.halfCocked) then
							output = true
						end
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanEngage(forced)
	local output = false

	if (self.weaponPartsManager.hasHammer) then
		if (self.hammerReady or forced) then
			output = true
		end
	elseif (self.weaponPartsManager.hasSlide) then
		if (self.slideRacked or forced) then
			output = true
		end
	end

	return output
end

function RC_WeaponBase:CanShoot(accidentalDischarge)
	local output = false

	if (self.canFire or accidentalDischarge) then
		if (self.oneInTheChamber) then
			if (not self.manualSafetyOn and not self.safetyDecocking) then
				if (not self.isRacking) then
					if (not self.isJolting) then
						if (not self.isHoldingHammer) then
							if (not self.isJammed) then
								if (not self.halfCocked) then
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

function RC_WeaponBase:HammerEventTracker()
	-- Hammer Event Tracker
	local hammerTransform = self.poseHandler.hammerTransform
	local hammerPoses = self.poseHandler.hammerPoses

	if (hammerPoses and hammerTransform) then
		-- Event System Base
		if (self:CanReadyHammer(hammerTransform, hammerPoses.hammerReadyPose)) then
			-- Toggle Bool
			self.hammerReady = true
			self.alreadyCalledHammerRest = false
			self.alreadyCalledHammerMiddle = false

			-- Actions
			if (not self.alreadyCalledHammerReady) then
				self:HammerReadyActions()
				self.alreadyCalledHammerReady = true
			end
		elseif (self:CanTriggerMiddleEvent(hammerTransform, hammerPoses.hammerRestPose, hammerPoses.hammerReadyPose)) then
			-- Actions
			if (not self.alreadyCalledHammerMiddle) then
				if (not self.decockingHammer) then
					self:HammerMiddleActions()
				end

				self.alreadyCalledHammerMiddle = true
			end
		elseif (self:CanNotReadyHammer(hammerTransform, hammerPoses.hammerRestPose)) then
			-- Toggle Bool
			self.hammerReady = false
			self.alreadyCalledHammerReady = false
			self.alreadyCalledHammerMiddle = false

			-- Actions
			if (not self.alreadyCalledHammerRest) then
				self:HammerRestActions()
				self.alreadyCalledHammerRest = true
			end
		end
	end
end

function RC_WeaponBase:HammerMiddleActions()
	-- Hammer Middle Actions
	-- Only works with weapons with a cylinder
	if (self.weaponPartsManager.hasCylinder) then
		-- Rotate cylinder if it has one
		-- Ignores if the cylinder is using reloadIndex
		if (self.ammoCarrier and not self.ammoCarrier.useReloadIndex) then
			if (self.canRotateCarrier) then
				self.canRotateCarrier = false
				self.ammoCarrier:StartRotate()
	
				self.script.StartCoroutine(self:RotationCooldown())
			end
		end

		-- If the hammer can be half cocked then enable the half cock
		-- bool. This will stop the return or rest animation. And ready the
		-- reload transition on the ammo carrier.
		if (self.canBeHalfCocked) then
			-- Toggle Bool
			self.halfCocked = true

			-- Play Sound
			if (self.soundHandler) then
				self.soundHandler:PlaySound("hammerhalfcock")
			end

			-- Transition
			if (self.ammoCarrier) then
				if (not self.ammoCarrier.isOnReloadMode) then
					self.ammoCarrier:ReloadToNormal(true)
				end
			end
		end
	end
end

function RC_WeaponBase:RotationCooldown()
	return function()
		coroutine.yield(WaitForSeconds(0.15))
		self.canRotateCarrier = true
	end
end

function RC_WeaponBase:HammerRestActions()
	-- Hammer Rest Actions
	-- Toggle Bool
	self.canRotateCarrier = true

	-- Play Sound
	if (self.weaponReady) then
		if (self.soundHandler) then
			self.soundHandler:PlaySound("hammerrest")
		end
	end

	if (self.weaponPartsManager.hasCylinder) then
		-- Disable Half Cock Bool
		self.halfCocked = false

		if (self.ammoCarrier) then
			if (self.ammoCarrier.isOnReloadMode) then
				self.ammoCarrier:ReloadToNormal(false)
			end
		end
	end
end

function RC_WeaponBase:HammerReadyActions()
	-- Hammer Ready Actions
	-- Play Sound
	if (self.weaponReady) then
		if (self.soundHandler) then
			self.soundHandler:PlaySound("hammerready")
		end
	end

	if (self.weaponPartsManager.hasCylinder) then
		-- Rotate cylinder if it has one
		-- Ignores if the cylinder is using reloadIndex
		if (self.ammoCarrier and self.ammoCarrier.useReloadIndex) then
			if (self.canRotateCarrier) then
				self.canRotateCarrier = false
				self.ammoCarrier:StartRotate()
	
				self.script.StartCoroutine(self:RotationCooldown())
			end
		end

		-- Disable Half Cock Bool
		self.halfCocked = false

		if (self.ammoCarrier) then
			if (self.ammoCarrier.isOnReloadMode) then
				self.ammoCarrier:ReloadToNormal(false)
			end
		end
	end
end

function RC_WeaponBase:CanTriggerMiddleEvent(baseT, pointT, endT)
	local output = false

	if (self.weaponReady) then
		if (self:MatchCheck(baseT, pointT, self.hammerMiddleThreshold, true, true, endT)) then
			output = true
		end
	end

	return output
end

function RC_WeaponBase:CanReadyHammer(baseT, targetT)
	local output = false

	if (self:MatchCheck(baseT, targetT, self.hammerReadyThreshold, true)) then
		output = true
	end

	return output
end

function RC_WeaponBase:CanNotReadyHammer(baseT, targetT)
	local output = false

	if (self:MatchCheck(baseT, targetT, self.hammerRestThreshold, true)) then
		if (not self.isRacking) then
			if (not self.isJolting) then
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:AmmoCarrierEventTracker()
	-- Magazine/Cylinder tarcker. Just like how slide events works
	local carrierTransform = self.poseHandler.magTransform
	local carrierPoses = self.poseHandler.magPoses

	if (carrierTransform and carrierPoses) then
		if (self.weaponPartsManager.hasMag) then
			-- This uses distance
			local distanceToRest = (carrierTransform.localPosition - carrierPoses.insertedPose.localPosition).magnitude

			if (distanceToRest <= 0.015) then
				self.ammoCarrierOut = false
			else
				self.ammoCarrierOut = true
			end
		elseif (self.weaponPartsManager.hasCylinder) then
			-- This uses angles
			local angleToRest = Quaternion.Angle(carrierTransform.localRotation, carrierPoses.closePose.localRotation)

			if (angleToRest <= 1) then
				self.ammoCarrierOut = false
			else
				self.ammoCarrierOut = true
			end
		end
	end
end

function RC_WeaponBase:SlideEventTracker()
	-- Slide state tracker basically
	local slideTransform = self.poseHandler.slideTransform
	local slidePoses = self.poseHandler.slidePoses
 
	if (slideTransform and slidePoses) then
		-- Events
		if (self:MatchCheck(slideTransform, slidePoses.normalSlidePose, self.slideEventThresholds, true)) then
			-- Rested
			if (not self.alreadyCheckedChamber and self.slidBack) then
				self:CheckChamber()
			end

			if (not self.alreadyCalledSlideRest) then
				self:SlideRestActs()
				self.alreadyCalledSlideRest = true
			end

			self.hasRacked = false
			self.hasJolted = false
			self.slidBack = false

			self.alreadyCalledSlideBack = false
			self.alreadyCalledSlideJolted = false
			self.alreadyLoaded = false
	    elseif (self:MatchCheck(slideTransform, slidePoses.joltedSlidePose, self.slideEventThresholds, true)) then
			-- Jolted
			self.alreadyCalledSlideRest = false

			if (not self.isJammed) then
				if (not self.alreadyCalledSlideJolted) then
					self:SlideJoltedActions()
					self.alreadyCalledSlideJolted = true
				end
			else
				self.alreadyCalledSlideJolted = false
			end
	    elseif (self:MatchCheck(slideTransform, slidePoses.rackedSlidePose, self.slideEventThresholds, true)) then
			-- Racked
			self.slidBack = true
			self.slideRacked = true
			
			self.hasJolted = false
			self.hasLoaded = false

			self.alreadyCheckedChamber = false
			self.alreadyCalledHammerRest = false
			self.alreadyCalledSlideJolted = false
			self.alreadyCalledSlideRest = false

			if (not self.alreadyCalledSlideBack) then
				self:SlideBackActions()
				self.alreadyCalledSlideBack = true
			end
			
			self:LoadingSystem()
		elseif (slidePoses.lockedSlidePose) then
			-- Locked
			if (self:MatchCheck(slideTransform, slidePoses.lockedSlidePose, self.slideEventThresholds, true)) then
				self.slidBack = true
				self.slideRacked = true
	
				self.hasJolted = false
				self.hasLoaded = false

				self.alreadyCheckedChamber = false
				self.alreadyCalledHammerRest = false
				self.alreadyCalledSlideJolted = false
				self.alreadyCalledSlideRest = false
	
				if (not self.alreadyCalledSlideBack) then
					self:SlideBackActions()
					self.alreadyCalledSlideBack = true
				end
	
				self:LoadingSystem()
			end
		end
	end
end

function RC_WeaponBase:MatchCheck(baseT, targetT, threshold, isLocal, getMiddleValue, target2T)
	local output = false

	local basePos = Vector3.zero
	local baseRot = Quaternion.identity
	local targetPos = Vector3.zero
	local targetRot = Quaternion.identity
	local target2Pos = Vector3.zero
	local target2Rot = Quaternion.identity

	if (baseT and targetT) then
		if (isLocal) then
			basePos = baseT.localPosition
			baseRot = baseT.localRotation

			targetPos = targetT.localPosition
			targetRot = targetT.localRotation

			if (target2T) then
				target2Pos = target2T.localPosition
				target2Rot = target2T.localRotation
			end
		else
			basePos = baseT.position
			baseRot = baseT.rotation

			targetPos = targetT.position
			targetRot = targetT.rotation

			if (target2T) then
				target2Pos = target2T.position
				target2Rot = target2T.rotation
			end
		end
	end

	if (not getMiddleValue) then
		-- Turn true if the distance and angle is in the threshold
		if (Vector3.Distance(basePos, targetPos) < threshold) then
			if (Quaternion.Angle(baseRot, targetRot) < threshold) then
				output = true
			end
		end
	else
		-- Turn true if the distance and angle is in the middle point
		-- of the threshold.
		if (not target2T) then return end

		local midPos = Vector3.Lerp(targetPos, target2Pos, 0.5)
		local midRot = Quaternion.Lerp(targetRot, target2Rot, 0.5)

		if (Vector3.Distance(basePos, midPos) < threshold) then
			if (Quaternion.Angle(baseRot, midRot) < threshold) then
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:SlideJoltedActions()
	-- Jolted Slide Actions
	-- Ready Hammer
	if (self.weaponPartsManager.hasHammer) then
		self.hammerReady = true
	end
end

function RC_WeaponBase:SlideBackActions()
	-- Slide Back Actions
	-- Ready Hammer
	if (self.weaponPartsManager.hasHammer) then
		self.hammerReady = true
	end

	-- Play Force Animation
	if (self.hasRacked) then
		if (self.thisAnimator) then
			self.thisAnimator.SetLayerWeight(1, 0.055)
			self.thisAnimator.SetTrigger("backwardlight")
		end
	end
end

function RC_WeaponBase:SlideRestActs()
	-- Slide Rest Actions
	-- Visual And Sound
	if (not self.hasJolted) then
		-- Play Force Animation
		if (self.thisAnimator) then
			self.thisAnimator.SetLayerWeight(1, 0.075)
			self.thisAnimator.SetTrigger("forwardlight")
		end

		-- Play Sound
		if (self.soundHandler) then
			self.soundHandler:PlaySound("slideforward")
		end
	else
		-- Play Force Animation
		if (self.thisAnimator) then
			self.thisAnimator.SetLayerWeight(1, 0.045)
			self.thisAnimator.SetTrigger("forwardlight")
		end

		-- Play Sound
		if (self.soundHandler) then
			self.soundHandler:PlaySound("slideforward", 0.65)
		end
	end
end

function RC_WeaponBase:TriggerSafetyType()
	if (not self.isJammed or self.slideLockSafety) then
		if (self.manualSafety and self.decockerSafety) then
			-- Both safeties
			self.manualSafetyOn = true
			
			if (self:CanSafetyDecockHammer()) then
				self.poseHandler:DecockHammer()
			end
	    elseif (self.manualSafety) then
			-- Manual/Thumb Safety
			self.manualSafetyOn = true

			-- Only works for manual safeties if allowed to
			if (self.slideLockSafety) then
				if (self.isRacking and not self.hasFired) then
					self.slideLocked = true
					self.manuallySlideLocked = true
				end
			end
		elseif (self.decockerSafety) then
			-- Decocker Safety
			self.safetyDecocking = true
		end
	end

	-- Disable bool (If possible)
	if (not self.alwaysDecockWhenSafety and not self.alwaysLockSlideSafety) then
		self.alreadyTriggeredSafety = true
	end
end

function RC_WeaponBase:CanSafetyDecockHammer()
	local output = false

	if (not self.isHoldingHammer) then
		if (not self.isJolting) then
			if (not self.isRacking) then 
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:DisableSafetyType()
	if (not self.isJammed or self.slideLockSafety) then
		if (self.manualSafety and self.decockerSafety) then
			-- Both safeties
			self.manualSafetyOn = false
	    elseif (self.manualSafety) then
			-- Manual/Thumb Safety
			self.manualSafetyOn = false

			-- Disable slide lock safety
			if (self.slideLockSafety) then
				if (self.slideLocked) then
					-- Toggle Bools
					self.slideLocked = false
					self.manuallySlideLocked = false

					self.isRacking = false
					self.hasRacked = false
				end
			end
		elseif (self.decockerSafety) then
			-- Decocker Safety
			if (self:CanSafetyDecockHammer()) then
				self.poseHandler:DecockHammer()
			end

			self.safetyDecocking = false
		end
	end

	-- Disable bool
	self.alreadyDisabledSafety = true
end

function RC_WeaponBase:HolsterSystem(holstering, slowDraw)
	if (holstering) then
		self:ToggleSystemAllowBools(false)
		self.poseHandler:HolsterGun()
		self.forceHolster = true
	else
		self:ToggleSystemAllowBools(true)
		self.forceHolster = false
	end

	self.script.StartCoroutine(self:CheckSafe(slowDraw))
end

function RC_WeaponBase:CheckSafe(slowDraw)
	return function()
		coroutine.yield(WaitForSeconds(0.045))

		if (not self.alreadyShot) then
			if (not self.manualSafetyOn) then
				local luck = Random.Range(1, 100)

				if (luck < self.accidentalFireChance and not slowDraw) then
					self:ShootSelf(false)
				end
	
				self.alreadyShot = true
			end
		end

		coroutine.yield(WaitForSeconds(0.015))

		if (not self.alreadyHolstered) then
			if (self.manualSafetyOn) then
				self.thisWeapon.LockWeapon()
			else
				self.thisWeapon.UnlockWeapon()
			end

			self.alreadyHolstered = true
		end
	end
end

function RC_WeaponBase:ShootSelf(suicide, forced)
	if (self.accidentalDischarges or suicide) then
		if (not self:CannotShootWhileMagOut()) then
			if (self:CanShoot(true) and self:CanEngage(forced)) then
				self:FireWeapon(true, self.mindControl)
			elseif (not self:CanShoot(true) and self:CanEngage() and self:CanDryFire()) then
				self:DryFire()
			end
		end
	end
end

function RC_WeaponBase:ToggleSystemAllowBools(turnOn)
	if (not turnOn) then
		-- System Bools
		self.isAiming = false
		self.isUsingToggleAim = false
		self.isRacking = false
		self.isReloading = false
		self.isSprinting = false

		-- Allow Bools
		self.canFire = false
		self.canRack = false
		self.canCockHammer = false
		self.canSwitchModes = false
		self.canToggleSlideLock = false
		self.canReload = false
		self.canToggleSafety = false
	else
		-- Allow Bools
		self.canFire = true
		self.canRack = true
		self.canCockHammer = true
		self.canSwitchModes = true
		self.canToggleSlideLock = true
		self.canReload = true
		self.canToggleSafety = true
	end
end

function RC_WeaponBase:LoadingSystem()
	-- Ejection Main
	local round = self.poseHandler.bulletTransform.gameObject

	-- Eject
	if (self.oneInTheChamber) then
		if (not self.doublefeed) then
			round.SetActive(false)
			self.receiveRoundSuccess = false

			-- Effects
			if (not self.stovepipe and not self.doublefeed) then
				if (self.usedRound) then
					self:InstantiateRound(false, true, false)
				else
					self:InstantiateRound(true, true, false)
				end
			end
		elseif (self.doublefeed) then
			self.receiveRoundSuccess = false
		end
	end

	-- Load
	if (self:CanLoad()) then
		if (not self.failToFeed and not self.doublefeed) then
			self.ammoCarrier:DecreaseAmmo(false)

			self.receiveRoundSuccess = true
			self.usedRound = false
			
			round.SetActive(true)
		elseif (self.failToFeed and not self.doublefeed) then
			self.receiveRoundSuccess = false
			round.SetActive(false)
		elseif (self.doublefeed) then
			self.receiveRoundSuccess = false
			round.SetActive(true)
		end

		self.alreadyLoaded = true
	elseif (self.doublefeedCleared) then
		round.SetActive(false)
		self.alreadyLoaded = false
		self.doublefeedCleared = false
	elseif (self.stovepipe) then
		self.receiveRoundSuccess = false
		round.SetActive(false)
	end

	-- Tick oneInTheChamber to false
	-- Because it can still strangely shoot while jammed
	self.oneInTheChamber = false

	-- Tick Fail To Feed bool
	-- Because it already failed to feed
	self.failToFeed = false

	-- Jam Clear
	if (self.isJammed) then
		local stillHasJam = true

		-- Stovepipe
		if (self.stovepipe and self.slidBack and self.hasRacked) then
			-- Toggle bools
			self.stovepipe = false
			stillHasJam = false

			-- Effects
			self:InstantiateRound(false, false, true)
		end

		-- Out Of Battery
		if (self.outofbattery and self.slidBack and self.hasRacked) then
			self.outofbattery = false
			stillHasJam = false
		end

		if (not stillHasJam) then
			self.isJammed = false
		end
	end

	-- Slide Lock
	-- Locks the slide if there is a empty magazine in the gun and if its racked.
	if (not self.ammoCarrierOut and self.hasRacked and self:IsMagEmpty() and not self:SlideLockSafetyCheck() and not self.receiveRoundSuccess) then
		if (self.weaponPartsManager.hasSlideStop or self.slideLockSafety) then
			if (not self.dontLockWhenEmpty) then
				self.slideLocked = true
				self.lockedByLoad = true
			end
		end
	end
end

function RC_WeaponBase:SlideLockSafetyCheck()
	local output = false

	if (self.manualSafetyOn and self.slideLockSafety) then
		output = true
	end

	return output
end

function RC_WeaponBase:InstantiateRound(isLive, normalEject, stovepipe, prespawn)
	-- Basically makes a clone of a round, depending if its live or not.
	local chosenRound = nil

	-- Checks if prespawn
	-- If so then do the prespawn state.
	if (not prespawn) then
		-- Checks whether if the round should be live or just a casing. Then get the proper chosen
		-- casing model.
		if (isLive) then
			if (self.dynamicRound) then
				chosenRound = self.dynamicRound
			end
		else
			if (self.dynamicCasing) then
				chosenRound = self.dynamicCasing
			end
		end
	
		-- Start spawning
		-- Checks first if one of the ejection positions exists. Some will not work if they don't.
		if (self.ejectionPos or self.doublefeedEjectionPos or self.stovepipeEjectionPos) then
			-- Get the poses
			local ejectPos = self.ejectionPos -- Normal Ejection Pos
			local dfEjectPos = self.doublefeedEjectionPos -- Double Feed Ejection Pos
			local spEjectPos = self.stovepipeEjectionPos -- Stovepipe Ejection Pos
	
			-- Pos Var
			local chosenTransform = nil
	
			-- Get a available position. If none then it will not work.
			if (ejectPos and normalEject and not stovepipe) then
				chosenTransform = ejectPos
			elseif (dfEjectPos and not normalEject and not stovepipe) then
				chosenTransform = dfEjectPos
			elseif (spEjectPos and stovepipe) then
				chosenTransform = spEjectPos
			end
	
			-- Checks if pos and chosenRound isn't nil.
			-- If they are. It will not work..
			if (chosenTransform and chosenRound) then
				-- Instantiate round
				local round = GameObject.Instantiate(chosenRound, chosenTransform.position, chosenTransform.rotation)
	
				-- Add force
				-- It is not a normal ejection then there will be no forces applied.
				if (normalEject and not self.noEjectForce) then
					-- Gets the rigidbody first. If none, then there will be no forces applied.
					local roundRb = round.GetComponent(Rigidbody)
	
					if (roundRb) then
						-- Left force
						-- It will choose the left side for ejection.
						roundRb.AddForce(-chosenTransform.right * 2.35, ForceMode.Impulse)
	
						-- Upward force
						roundRb.AddForce(chosenTransform.forward * 1.65, ForceMode.Impulse)
					end
				end
			end
		end
	else
		-- Prespawn
		-- To prevent lag spikes everytime it instantiates a object for the first time.
		local stored = {}
		local chosenLive = false

		for i = 1, 2 do
			-- Create a primitive to instantiate
			if (not chosenLive) then
				if (self.dynamicRound) then
					chosenRound = self.dynamicRound
				end

				chosenLive = true
			else
				if (self.dynamicCasing) then
					chosenRound = self.dynamicCasing
				end
			end

			-- Start spawning if not nil
			if (chosenRound) then
				-- Instantiate then cache the object to delete later
				local round = GameObject.Instantiate(chosenRound)
				stored[#stored+1] = round
			end
		end

		-- Delete the prespawn objects
		self.script.StartCoroutine(self:DeleteStored(stored))
 	end
end

function RC_WeaponBase:DeleteStored(stored)
	-- Deletes the stored prespawn objects.
	return function()
		coroutine.yield(WaitForSeconds(0.15))
		if (#stored > 0) then
			for _,obj in pairs(stored) do
				if (obj) then
					GameObject.Destroy(obj)
				end
			end
		end
	end
end

function RC_WeaponBase:CanLoad()
	local output = false

	if (not self:IsMagEmpty()) then
		if (not self.ammoCarrierOut) then
			if (not self.stovepipe) then
				if (not self.wronglyseatedmag) then
					if (not self.isRacking) then
						if (not self.slideLocked) then
							if (not self.alreadyLoaded) then
								output = true
							end
						end
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CheckChamber()
	if (self.receiveRoundSuccess) then
		self.oneInTheChamber = true
		self.canFire = true
	else
		self.oneInTheChamber = false
	end

	self.hasLoaded = true
	self.alreadyCheckedChamber = true
end

function RC_WeaponBase:IsMagEmpty()
	local output = true

	if (self.ammoCarrier.ammo > 0) then
		output = false
	end
	
	return output
end

function RC_WeaponBase:WeaponInputs()
	-- Handles the inputs
    -- Aiming
    if (Input.GetKeyDown(self.toggleAimKey) and not self.isHolstered and not self.tempDisableFeatures and not self.mindControl and self:IsUIClosed()) then
		self.isUsingToggleAim = not self.isUsingToggleAim
        self.isAiming = not self.isAiming
    end

	if (not self.isHolstered and not self.mindControl and self:IsUIClosed()) then
		if (Input.GetKeyBindButton(KeyBinds.Aim) and not self.tempDisableFeatures) then
			self.isAiming = true
			self.isUsingToggleAim = false
		elseif (not Input.GetKeyBindButton(KeyBinds.Aim) and not self.isUsingToggleAim) then
			self.isAiming = false
		end
	end

	-- Sprinting
	local playerVel = Player.actor.velocity.magnitude

	if (Player.actor.isSprinting and playerVel ~= 0 and not self.tempDisableFeatures) then
		self.isSprinting = true
	else
		self.isSprinting = false
	end

	-- Only works if the gun has a slide and a mag
    if (self.weaponPartsManager.hasSlide and self.weaponPartsManager.hasMag) then
		-- Racking
		if (not self.notRackable) then
			if (Input.GetKey(self.removeBulletRackCloseKey) and not Input.GetKey(self.slideLockTapKey) and self:CanMoveSlide() and not self.mindControl and self:IsUIClosed()) then
				-- Actions
				self:PullSlideActions()
	
				-- Slide lock
				if (not self:IsMagEmpty() and not self.ammoCarrierOut or self.ammoCarrierOut) then
					self.slideLocked = false
					self.manuallyLocked = false
				end
			elseif (not Input.GetKey(self.slideLockTapKey)) then
				self.alreadyPlayedSlideBack = false
			end
		
			if (Input.GetKeyUp(self.removeBulletRackCloseKey) and not Input.GetKeyUp(self.slideLockTapKey)) then
				-- Actions
				self:ReleaseSlideActions()
			end
		end

		-- Only works when the weapon has a slide lock
		if (self.weaponPartsManager.hasSlideStop) then
			-- Slide Lock
			if (self.isRacking and not self.hasFired and not self.mindControl) then
				if (Input.GetKeyDown(self.slideLockTapKey) and self:CanSlideLock() and self:IsUIClosed()) then
					-- Play Sound
					if (not self.alreadyPlayedSlideLockOn) then
						if (self.soundHandler) then
							self.soundHandler:PlaySound("slidelock")
						end
	
						self.alreadyPlayedSlideLockOn = true
						self.alreadyPlayedSlideLockOff = false
					end
	
					-- Bools
					self.slideLocked = true
					self.manuallySlideLocked = true
					self.canReleaseSlide = false
				end
			else
				self.canReleaseSlide = true
			end
	
			-- Slide Release
			if (Input.GetKeyDown(self.slideLockTapKey) and self:CanReleaseSlide() and not self.mindControl and self:IsUIClosed()) then
				-- Play sound
				if (not self.alreadyPlayedSlideLockOff) then
					if (self.soundHandler) then
						self.soundHandler:PlaySound("slidelock")
					end
	
					self.alreadyPlayedSlideLockOff = true
					self.alreadyPlayedSlideLockOn = false
				end
	
				-- Bools
				self.slideLocked = false
				self.manuallySlideLocked = false
				self.hasRacked = false
			end
		end
			
		-- Slide Tap
		if (Input.GetKeyDown(self.slideLockTapKey) and self:CanSlideTap() and self:IsUIClosed()) then
			self:SlideTap()
		end
	end

	-- Only works if the gun has a safety system
	if (self.decockerSafety or self.manualSafety) then
		-- Safety (Manual/Thumb) or Both
		if (self.manualSafety or self.decockerSafety and self.manualSafety) then
			if (Input.GetKeyDown(self.safetyFiremodeEjectKey) and self:CanMoveSafe() and not self.mindControl and self:IsUIClosed()) then
				-- Toggle Bool
				self.safetyOn = not self.safetyOn
			end
		elseif (self.decockerSafety) then
			if (Input.GetKeyDown(self.safetyFiremodeEjectKey) and self:CanMoveSafe() and not self.mindControl and self:IsUIClosed()) then
				-- Toggle Bool
				self.safetyOn = true
			end

			if (Input.GetKeyUp(self.safetyFiremodeEjectKey) and self:IsUIClosed()) then
				self.safetyOn = false
			end
		end
	end

	-- Firemodes System
	if (self.firemodeSelector) then
		if (self:IsUIClosed()) then
			if (not self.decockerSafety and not self.manualSafety) then
				-- Reuse safety bind if there is no safety system
				if (Input.GetKeyDown(self.safetyFiremodeEjectKey) and self:CanSwitchFireModes() and not self.mindControl) then
					self:FiremodeChangeActs()
				end
			elseif (self.decockerSafety or self.manualSafety) then
				-- Else use a alternate keybind
				if (Input.GetKeyDown(self.altFiremodeKey) and self:CanSwitchFireModes() and not self.mindControl) then
					self:FiremodeChangeActs()
				end
			end
		end
	end

    -- Jolting
    if (self:IsUIClosed()) then
		if (Input.GetKey(self.slideLockTapKey) and self:CanMoveSlide() and not self.mindControl) then
			if (Input.GetKey(self.removeBulletRackCloseKey)) then
				self.isJolting = true
				self.hasJolted = true

				-- Play Sound
				if (not self.stovepipe and not self.doublefeed and not self.isRacking) then
					if (not self.alreadyPlayedJolt) then
						if (self.soundHandler) then
							self.soundHandler:PlaySound("slideback", 0.65)
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

    if (Input.GetKeyUp(self.slideLockTapKey) or Input.GetKeyUp(self.removeBulletRackCloseKey) and self:CanMoveSlide()) then
        self.isJolting = false
		self.alreadyPlayedJolt = false
    end

    -- Trigger
    if (Input.GetKeyBindButton(KeyBinds.Fire) and self:CanHoldTrigger() and not self:CannotShootWhileMagOut() and not self.mindControl) then
        self.isHoldingTrigger = true
    else
        self.isHoldingTrigger = false
    end

    -- Reloading
	-- Unload and Drop Mag
    if (Input.GetKeyDown(self.carrierOutKey) and self:CanReload(false) and self:CanOpenCylinder() and not self:HasDoubleFeed() and not self.mindControl and self:IsUIClosed()) then
        self.poseHandler:StartReload(true, self.weaponPartsManager.isRevolverLike)
	elseif (Input.GetKeyDown(self.carrierOutKey) and self:CanDropMag() and not self.mindControl and self:IsUIClosed()) then
		self.magazineInHand = not self.ammoCarrier:MagManager(self.currentMagIndex, "drop")
    end

	-- Hold ver for the animator
	if (Input.GetKey(self.carrierOutKey) and not self.tempDisableFeatures and not self.mindControl and self:IsUIClosed()) then
		self.isHoldingRelease = true
	else
		self.isHoldingRelease = false
	end

	-- Load
	if (self.weaponPartsManager.hasMag) then
		-- Only works if the weapon has a magazine
		if (Input.GetKeyDown(self.carrierInInsertBulletKey) and self:CanReload(true) and not self.mindControl and self:IsUIClosed()) then
			-- Mag in function
			self.poseHandler:StartReload(false, false)
		elseif (Input.GetKeyDown(self.carrierInInsertBulletKey) and self:CanMagTap() and not self.mindControl and self:IsUIClosed()) then
			-- Mag tap function
			self:MagTap()
 		end
	elseif (self.weaponPartsManager.hasCylinder) then
		-- Only works if the weapon has a cylinder
		-- Cylinder close function
		if (Input.GetKeyDown(self.removeBulletRackCloseKey) and self:CanReload(true) and self:CanCloseCylinder() and not self.mindControl and self:IsUIClosed()) then
			self.poseHandler:StartReload(false, true)
		end

		-- Hold ver for the animator
		if (Input.GetKey(self.removeBulletRackCloseKey) and not self.tempDisableFeatures and not self.mindControl and self:IsUIClosed()) then
			self.isHoldingCloseKey = true
		else
			self.isHoldingCloseKey = false
		end
	end

	-- Hammer Inputs
	if (self.weaponPartsManager.hasHammer) then
		-- Cocking
		if (not self.isDecockingHammer) then
			if (Input.GetKey(self.pullHammerKey) and self:CanCockHammer() and not self.mindControl and self:IsUIClosed()) then
				self.isHoldingHammer = true
			elseif (not self.mindControl) then
				self.isHoldingHammer = false
			end
		elseif (not self.mindControl) then
			self.isHoldingHammer = false
		end

		-- Decocking
		if (self:IsUIClosed()) then
			if (self.isHoldingTrigger) then
				self.timeHeldTrigger = self.timeHeldTrigger + 1 * Time.deltaTime
			else
				self.timeHeldTrigger = 0
			end

			if (Input.GetKey(self.pullHammerKey) and self:CanDecockHammer() and not self.mindControl) then
				if (self.timeHeldTrigger < 0.15) then
					self.isDecockingHammer = true
				end
			end
		end

		if (Input.GetKeyUp(self.pullHammerKey) and self.isDecockingHammer and self:IsUIClosed()) then
			if (not self.alreadyDisengagedHammer) then
				self:DisengageHammer()
			end
		end

		if (not self.isHoldingTrigger and self.isDecockingHammer) then
			self.isDecockingHammer = false
			self.alreadyDisengagedHammer = false
		end
	end

	-- Ejector Inputs
	-- Only works when it has a cylinder and no safety or firemodes system.
	if (self.weaponPartsManager.hasCylinder) then
		if (not self.manualSafety and not self.decockerSafety and not self.firemodeSelector) then
			if (Input.GetKey(self.safetyFiremodeEjectKey) and self:CanEject() and self:IsUIClosed()) then
				self.isHoldingEject = true
				self.hasEjected = true
			else
				self.isHoldingEject = false
			end
		end
	end
end

function RC_WeaponBase:CanSlideLock()
	local output = false

	if (not self.disableSlideLock) then
		if (self.canToggleSlideLock) then
			output = true
		end
	end

	return output
end

function RC_WeaponBase:CanReleaseSlide()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.disableSlideLock) then
			if (self.canReleaseSlide) then
				if (self.slideLocked) then
					if (self.canToggleSlideLock) then
						if (not self.onlyReleaseWhenManuallyLocked) then
							output = true
						else
							if (self.manuallySlideLocked) then
								output = true
							end
						end
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanSlideTap()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.slideLocked) then
			if (not self.disableSlideTap) then
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:CanDropMag()
	local output = false

	if (self.weaponPartsManager.hasMag) then
		if (self.ammoCarrier) then
			if (self.ammoCarrierOut) then
				if (self.magazineInHand) then
					if (not self.isReloading) then
						output = true
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanDecockHammer()
	local output = false

	if (not self.tempDisableFeatures) then
		if (self.canCockHammer) then
			if (not self.notCockable) then
				if (self.isFannable) then
					if (self.hammerReady) then
						output = true
					end
				else
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanOpenCylinder()
	local output = false

	if (self.weaponPartsManager.hasCylinder) then
		if (not self.hammerReady or self.dontRestrictCarrierReady) then
			output = true
		end
	else
		output = true
	end

	return output
end

function RC_WeaponBase:CanCloseCylinder()
	local output = false

	if (not self.isHoldingEject) then
		output = true
	end

	return output
end

function RC_WeaponBase:CanCockHammer()
	local output = false

	if (not self.tempDisableFeatures) then
		if (self.canCockHammer) then
			if (not self.notCockable) then
				if (not self.isHoldingTrigger or self.isFannable) then
					if (self.weaponPartsManager.hasCylinder) then
						if (not self.ammoCarrierOut or self.dontRestrictHammerOut) then
							output = true
						end
					else
						if (not self.manualSafetyOn or self.canCockHammerSafe) then
							output = true
						end
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanHoldTrigger()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.isRacking) then
			if (not self.isReloading) then
				if (not self.isJolting) then
					if (not self.isHolstered) then
						if (not self.manualSafetyOn and not self.safetyDecocking) then
							if (not self.isHoldingEject) then
								if (not self.isHoldingCloseKey) then
									if (not self.weaponPartsManager.hasCylinder) then
										output = true
									else
										if (not self.ammoCarrierOut or self.dontRestrictTriggerOut) then
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

	return output
end

function RC_WeaponBase:CanEject()
	local output = false

	if (not self.tempDisableFeatures) then
		if (self.ammoCarrierOut) then
			if (not self.isHolstered) then
				if (self.ammoCarrier.useReloadIndex) then
					if (self.ammoCarrier.isOnReloadMode) then
						output = true
					end
				else
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:ReleaseSlideActions()
	-- Release Slide Actions
	-- Toggle Bools
	self.isRacking = false
	self.lockedByLoad = false

	self.alreadyPlayedSlideLockOff = false
	self.alreadyPlayedSlideLockOn = false
end

function RC_WeaponBase:PullSlideActions()
	-- Slide Pull Actions
	-- Trigger Bools
	self.isRacking = true
	self.hasRacked = true
	self.manuallySlideLocked = false

	-- Play Sound
	if (not self.alreadyPlayedSlideBack) then
		if (self.soundHandler) then
			self.soundHandler:PlaySound("slideback")
		end

		self.alreadyPlayedSlideBack = true
	end
end

function RC_WeaponBase:FiremodeChangeActs()
	-- Firemode Change Events
	-- Change Firemode
	if (self.firemodeInts) then
		if (self.currentFiremodeIndex < #self.firemodeInts) then
			self.currentFiremodeIndex = self.currentFiremodeIndex + 1
		else
			self.currentFiremodeIndex = 1
		end

		self.fm1 = self.firemodeInts[self.currentFiremodeIndex]
	end

	-- Play Sound
	if (self.soundHandler) then
		self.soundHandler:PlaySound("firemode")
	end
end

function RC_WeaponBase:CanSwitchFireModes()
	local output = false

	if (not self.tempDisableFeatures) then
		if (self.canSwitchModes) then
			if (not self.isHolstered) then
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:DisengageHammer()
	-- Simply disengages the hammer.
	if (self:CanMoveHammer()) then
		if (self.hammerReady) then
			self.poseHandler:DecockHammer()
		end
	end

	self.alreadyDisengagedHammer = true
end

function RC_WeaponBase:MagTap()
	-- Mag Tap Function

	-- Malfunction Clear
	-- Wrongly seated mag
	if (self.wronglyseatedmag) then
		self.wronglyseatedmag = false
	end

	-- Play Force Animation
	if (self.thisAnimator) then
		self.thisAnimator.SetLayerWeight(1, 0.3)
		self.thisAnimator.SetTrigger("forward")
	end

	-- Play Sound
	if (self.soundHandler) then
		self.soundHandler:PlaySound("magtap")
	end
end

function RC_WeaponBase:CanMagTap()
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.isHolstered) then
			if (not self.isReloading) then
				if (not self.ammoCarrierOut) then
					output = true
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:HasDoubleFeed()
	local output = true

	if (not self.onlyEjectWhenRackedDoublefeed) then
		if (not self.doublefeed or self.slideLocked) then
			output = false
		end
	else
		if (not self.doublefeed or self.slidBack and self.isRacking) then
			output = false
		end
	end

	return output
end

function RC_WeaponBase:CanReload(isAmmoCarrierOut)
	local output = false

	if (not self.tempDisableFeatures) then
		if (not self.isReloading) then
			if (not self.isSwappingMags) then
				if (self.magazineInHand) then
					if (isAmmoCarrierOut) then
						if (self.ammoCarrierOut) then
							if (self.canReload) then
								output = true
							end
						end
					else
						if (not self.ammoCarrierOut) then
							if (self.canReload) then
								output = true
							end
						end
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:SlideTap()
	-- Jam Clear
	if (self.outofbattery) then
		-- Play Force Animation
		if (self.thisAnimator) then
			self.thisAnimator.SetLayerWeight(1, 0.15)
			self.thisAnimator.SetTrigger("forward")
		end

		-- Toggle Bool
		self.outofbattery = false
		self.isJammed = false
	end
end

function RC_WeaponBase:CanMoveSafe()
	local output = false

	if (not self.tempDisableFeatures) then
		if (self.canToggleSafety) then
			if (not self.lockedByLoad or not self.slideLockSafety) then
				if (not self.isJammed or self.slideLockSafety and self.doublefeed and self.isRacking or self.slideLockSafety and self.slideLocked) then
					if (not self.hasFired) then
						if (not self.slidBack or self.slideLockSafety or self.canSafeSlidBack) then
							if (self.moveSafeHammerReady) then
								if (self.hammerReady) then
									output = true
								end
							else
								output = true
							end
						end
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:CanMoveSlide(bypassNotRackable)
	local output = false

	if (not self.tempDisableFeatures) then
		if (self.canRack) then
			if (not self.notRackable or bypassNotRackable) then
				if (not self.hasFired) then
					if (self.restrictSlideOnSafe) then
						if (not self.manualSafetyOn or self.slideLockSafety and self.doublefeed) then
							output = true
						end
					else
						output = true
					end
				end
			end
		end
	end

	return output
end

function RC_WeaponBase:DryFire()
	-- Dry Fire
	-- Dry Fire Weapon
	if (self:CanMoveHammer()) then
		if (self.hammerReady) then
			self.poseHandler:OnFire(self.weaponPartsManager.hasHammer, true)
		end
	end

	-- Dry Fire Systems
	if (not self.slidBack and not self.manualSafetyOn) then
		-- Play Sound
		if (self.soundHandler) then
			self.soundHandler:PlaySound("dryfire")
		end

		-- Play Force Animation
		if (self.thisAnimator) then
			self.thisAnimator.SetLayerWeight(1, 0.075)
			self.thisAnimator.SetTrigger("forwardlight")
		end

		-- Engage Bool
		self.slideRacked = false
	end

	-- Controls the max times it can be fired
    -- Something for the firemode system
    if (self.fm1 > -1) then
    	self.timesFired = self.timesFired + 1
    else
	    self.timesFired = 0
    end
end

function RC_WeaponBase:CanMoveHammer()
	local output = false

	if (self.restrictHammerOnSafe) then
		if (not self.manualSafetyOn) then
			if (not self.isJammed) then
				output = true
			end
		end
	else
		if (not self.isJammed) then
			output = true
		end
	end

	return output
end

function RC_WeaponBase:FireWeapon(shootSelf, suicide)
	if (self.oneInTheChamber) then
		-- Shoot the weapon
		self.isFiring = true
		self.thisWeapon.Shoot(true)

		-- Blink
		if (self.allowBlinking and self.rcBase) then
			if (not shootSelf and not suicide) then
				self.rcBase:Blink()
			end
		end

		-- Add Freq To Aim Sway
		self.curSwayFreq = self.curSwayFreq + self.swayShootAdd

		-- Jam/Malfunction System
		if (self.canJam) then
			local jamOrMalfunction = math.random(0, 1)

			if (jamOrMalfunction == 0) then
				-- Jam
				local luck = Random.Range(0, 100)
	
				if (luck < self.jamChance) then
					self:GetRandomJamMalfuncType(true)
				end
			elseif (jamOrMalfunction == 1) then
				-- Malfunction
				local luck = Random.Range(0, 100)
	
				if (luck < self.malfunctionChance) then
					self:GetRandomJamMalfuncType(false)
				end
			end
		end

		-- Self Loading
		if (not self:IsMagEmpty() or self.ammoCarrierOut) then
			self.poseHandler:OnFire(self.weaponPartsManager.hasHammer, false)
			
			if (self.weaponPartsManager.hasSlide and self.weaponPartsManager.hasSlideStop or self.slideLockSafety) then
				if (not self.dontLockWhenEmpty) then
					self.slideLocked = false
					self.manuallySlideLocked = false
				end
			end
		elseif (self:IsMagEmpty() and not self.ammoCarrierOut) then
			self.poseHandler:OnFire(self.weaponPartsManager.hasHammer, false)

			if (self.weaponPartsManager.hasSlide and self.weaponPartsManager.hasSlideStop or self.slideLockSafety) then
				if (not self.dontLockWhenEmpty) then
					self.slideLocked = true
					self.lockedByLoad = true
				end
			end
		end

		-- Self Harm (Based)
		if (shootSelf and not suicide or self.isSprinting and not self.disableSelfDamageSprinting and not suicide) then
			-- Shoot self (Only for accidental discharges and poor trigger discipline)
			Player.actor.Damage(Player.actor, self.selfDamageAmount, 0, false, false)
		elseif (suicide) then
			-- Suicide (Only for mind control event (Raveceiver Game))
			Player.actor.Kill()
		end

		-- Tick Bools
		self.slideRacked = false
		
		if (self.weaponPartsManager.hasSlide) then
			self.usedRound = true
		elseif (self.weaponPartsManager.hasCylinder) then
			if (self.currentBullet) then
				self.currentBullet[2] = false
			end
		end

		-- Cooldown
		if (self.weaponPartsManager.hasSlide) then
			self.canFire = false
		end

    	-- Controls the max times it can be fired
    	-- Something for the firemode system
    	if (self.fm1 > -1) then
    		self.timesFired = self.timesFired + 1
    	else
	    	self.timesFired = 0
    	end
	end
end

function RC_WeaponBase:GetRandomJamMalfuncType(isJam)
	if (isJam) then
		local chosenJam = math.random(1, 2)

		if (chosenJam == 1) then
			if (self:CanStovePipe()) then
				-- Stovepipe
				self.stovepipe = true
				self.isJammed = true

				-- Model Swap
				self:SwapJamRoundModel(true)
			end
		elseif (chosenJam == 2) then
			if (self:CanDoubleFeed()) then
				-- Double Feed
			    self.doublefeed = true
			    self.isJammed = true

				-- Model Swap
				self:SwapJamRoundModel(false)
			end
		end
	else
		local chosenMalfunc = math.random(1, 2)
		
		if (chosenMalfunc == 1) then
			if (self:CanOutOfBattery()) then
				-- Out Of Battery
				self.outofbattery = true
				self.isJammed = true
			end
		elseif (chosenMalfunc == 2) then
			if (not self.disableFailureToFeed) then
				-- Failure To Feed
				local luck = Random.Range(1, 100)

				if (luck < self.failureToFeedChance) then
					self.failToFeed = true
				end
			end
		end
	end
end

function RC_WeaponBase:SwapJamRoundModel(casing)
	if (self.jamRoundCasing and self.jamRoundLive) then
		if (casing) then
			self.jamRoundCasing.SetActive(true)
			self.jamRoundLive.SetActive(false)
		else
			self.jamRoundCasing.SetActive(false)
			self.jamRoundLive.SetActive(true)
		end
	end
end

function RC_WeaponBase:CanStovePipe()
	-- To prevent stovepiping even the slide is locked, etc...
	local output = false

	if (not self.disableStovepipe) then
		if (not self:IsMagEmpty()) then
			if (not self.slideLocked) then
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:CanOutOfBattery()
	-- To prevent having a out of battery when slide is locked
	-- when the gun is empty
	local output = false

	if (not self.disableOutOfBattery) then
		if (not self:IsMagEmpty()) then
			if (not self.slideLocked) then
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:CanDoubleFeed()
	-- Doing this because it double feeds even there is no mag
	-- in the gun or no ammo in the mag.
	local output = false

	if (not self.disableDoubleFeed) then
		if (not self.ammoCarrierOut) then
			if (not self:IsMagEmpty()) then
				output = true
			end
		end
	end

	return output
end

function RC_WeaponBase:OnAmmoCarrierIn()
	-- Mag In/Cylinder Close Event
	-- Only works if the weapon has a mag.
	if (self.weaponPartsManager.hasMag) then
		if (self.canJam and not self.disableWronglySeatedMag) then
			-- Wrongly seated mag system
			local luck = Random.Range(1, 100)

			if (luck < self.malfunctionChance) then
				self.wronglyseatedmag = true
			end
		end
	end

	-- Play Force Animation
	if (self.thisAnimator) then
		self.thisAnimator.SetLayerWeight(1, 0.1)
		self.thisAnimator.SetTrigger("forward")
	end

	-- Play Sound
	if (self.soundHandler) then
		if (self.weaponPartsManager.hasMag) then
			self.soundHandler:PlaySound("magin")
		elseif (self.weaponPartsManager.hasCylinder) then
			self.soundHandler:PlaySound("closecylinder")
		end
	end
end

function RC_WeaponBase:OnAmmoCarrierOut()
	-- Mag Out/Cylinder Open Event
	-- Jam Clear (Double Feed)
	if (self.doublefeed) then
		-- Toggle Bools
		self.doublefeed = false
		self.isJammed = false
		self.doublefeedCleared = true

		-- Effects
		self:InstantiateRound(false, false, false)
		self:InstantiateRound(true, false, false)
	end

	-- Play Force Animation
	if (self.thisAnimator) then
		self.thisAnimator.SetLayerWeight(1, 0.055)
		self.thisAnimator.SetTrigger("backward")
	end

	-- Only works if the weapon has a mag
	if (self.weaponPartsManager.hasMag) then
		-- Spring Interpolation Controller
		self.insertedMag = false

		-- Malfunction clear
	    -- Wrongly seated mag
		if (self.wronglyseatedmag) then
			self.wronglyseatedmag = false
		end
	end
end

function RC_WeaponBase:OnUnloadStart()
	-- Unload Start Event
	-- Play Sound
	if (self.soundHandler) then
		if (self.weaponPartsManager.hasMag) then
			self.soundHandler:PlaySound("magout")
		elseif (self.weaponPartsManager.hasCylinder) then
			self.soundHandler:PlaySound("opencylinder")
		end
	end
end

function RC_WeaponBase:OnLoadStart()
	-- Load Start Event
	-- Only works when the weapon has a mag
	if (self.weaponPartsManager.hasMag) then
		-- Spring Interpolation Controller
		self.insertedMag = true
	end
end

function RC_WeaponBase:CompellingSuicide()
	-- Kills the player on its own.
	return function()
		coroutine.yield(WaitForSeconds(1.25))

		-- Unholster Weapon if it is holstered
		if (self.isHolstered) then
			self.isHolstered = false
			self:HolsterSystem(false, true)
		end

		-- Stop Aiming if the Player is aiming
		if (self.isAiming) then
			self.isUsingToggleAim = false
			self.isAiming = false
		end

		-- If the player has a mag in hand and its out then put it in
		if (self.weaponPartsManager.hasMag) then
			if (self.magazineInHand and self.ammoCarrierOut) then
				self.isReloading = true
				self.poseHandler:StartReload(false, false)
			end
		end

		coroutine.yield(WaitForSeconds(1.25))

		-- Enable mind control
		self.mindControl = true

		coroutine.yield(WaitForSeconds(1.25))

		-- Check if the revolver's cylinder is open
		-- If so then close it. (If it is a revolver)
		if (self.weaponPartsManager.hasCylinder) then
			if (self.ammoCarrierOut) then
				self.poseHandler:StartReload(false, true)
			end
		end

		coroutine.yield(WaitForSeconds(1.25))

		-- Check if a manual safety is on
		if (self.manualSafety) then
			if (self.manualSafetyOn and self:CanMoveSafe()) then
				self.safetyOn = false
			end
		end

		coroutine.yield(WaitForSeconds(2.25))
		
		-- Check if the ammo carrier is inserted and has bullets in it
		-- If so then rack the slide.
		if (self.weaponPartsManager.hasSlide) then
			if (not self.oneInTheChamber and self:CanMoveSlide(true)) then
				if (not self.ammoCarrierOut and self.ammoCarrier.ammo > 0) then
					while (not self.slidBack) do
						coroutine.yield(WaitForSeconds(1))
						self:PullSlideActions()
					end
					
					self:ReleaseSlideActions()
				end
			end
		end

		coroutine.yield(WaitForSeconds(2.25))

		-- Cock the hammer 
		-- If it has one
		if (self.weaponPartsManager.hasHammer) then
			if (self:CanCockHammer()) then
				while (not self.hammerReady) do
					coroutine.yield(WaitForSeconds(1))
					self.isHoldingHammer = true
				end
	
				self.isHoldingHammer = false
			end
		end
	end
end

function RC_WeaponBase:TriggerMindControl(type)
	if (type == "start") then
		self.script.StartCoroutine(self:CompellingSuicide())
	elseif (type == "stop") then
		self:StopMindControl()
    elseif (type == "shoot") then
		self.script.StartCoroutine(self:CompellingShoot())
	end
end

function RC_WeaponBase:CompellingShoot()
	return function()
		-- Cock the hammer 
		if (self.weaponPartsManager.hasHammer) then
			if (self:CanCockHammer()) then
				while (not self.hammerReady) do
					coroutine.yield(WaitForSeconds(1))
					self.isHoldingHammer = true
				end
	
				self.isHoldingHammer = false
			end
		end

		-- Shoot
		self:ShootSelf(true)
	end
end

function RC_WeaponBase:StopMindControl()
	-- Simply Stops the mindControl event
	self.mindControl = false
end