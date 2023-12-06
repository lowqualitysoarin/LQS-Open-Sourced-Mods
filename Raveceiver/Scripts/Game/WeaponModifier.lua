behaviour("WeaponModifier")

function WeaponModifier:Awake()
	-- Base
	self.selectedWeapon = nil

	-- Conditions
	self.safeOn = false
	self.isHolstered = false
	self.isUnloaded = false

	-- Raveceiver Weapons
	self.rcScript = nil

	-- Essentials
	self.playerWeapon = nil

	self.quickDrawDischargeChance = 90
	self.slowDrawDischargeChance = 1
	self.timeHeldHolster = 0

	self.weaponMaxAmmo = 0

	self.alreadyGotWeapon = false
	self.alreadyGotWeaponData = false

	self.alreadyShot = false

	self.alreadyHolstered = false
	self.tempDisableHolster = false
	self.pressedHolsterButton = false
	self.tempDisableFeatures = false
end

function WeaponModifier:Start()
	-- Scripts
	if (self.targets.playerModifier) then
		self.playerModifier = self.targets.playerModifier.GetComponent(ScriptedBehaviour).self
	end
	
	-- Listeners
	GameEvents.onActorDied.AddListener(self, "OnPlayerDied")
end

function WeaponModifier:OnPlayerDied(actor)
	-- Do shit when the player dies
	if (actor.isPlayer) then
		self:ResetGameBools()
	end
end

function WeaponModifier:ResetGameBools()
	-- Literally resets some game bools, like safe, unload, etc...
	-- Holstering
	self.isHolstered = false
	self.alreadyShot = false
	self.alreadyHolstered = false
	self.tempDisableHolster = false
	self.pressedHolsterButton = false

	-- Unloading
	self.isUnloaded = false

	-- Safe
	self.safeOn = false

	-- Data
	self.alreadyGotWeapon = false
	self.alreadyGotWeaponData = false

	-- Others
	self.suicide = false
	self.tempDisableFeatures = false
end

function WeaponModifier:Update()
	-- Weapon Checker
	self:WeaponChecker()

	-- Weapon Conditions
	if (not self.tempDisableFeatures) then
		self:WeaponConditions()
	end

	-- Raveceiver Weapon Conditions
	-- This only does a little checks from the weapon for the game.
	if (self.rcScript) then
		self:RC_WeaponConditions()
	end
end

function WeaponModifier:RC_WeaponConditions()
	-- Slow down player when mind control happens.
	if (self.rcScript.mindControl) then
		if (self.playerModifier) then
			self.playerModifier.isOnMindControl = true
		end
	else
		if (self.playerModifier) then
			self.playerModifier.isOnMindControl = false
		end
	end
end

function WeaponModifier:WeaponChecker()
	-- Some checks for the weapon
	-- To prevent nil errors.

	local player = Player.actor

	if (player) then
		-- Gets the player's weapon
		if (not self.alreadyGotWeapon or self.playerWeapon == nil) then
			local activeWeapon = player.activeWeapon
			self.playerWeapon = activeWeapon

			self.alreadyGotWeapon = true
		end
	end
end

function WeaponModifier:WeaponConditions()
	-- Handles the weapon conditions
	-- Like weapon safety or something.

	-- Check if the weapon is a Raveceiver Weapon
	-- If so, then return.
	if (self:IsRaveceiverWeapon()) then 
		self.tempDisableFeatures = true
		return 
	end

	-- Holster System
	-- Tick Pressed Holster Button
	if (Input.GetKeyDown(KeyCode.BackQuote)) then
		self.pressedHolsterButton = true
	end

	-- Main
	if (Input.GetKey(KeyCode.BackQuote) and self.playerWeapon) then
		-- Timer
		self.timeHeldHolster = self.timeHeldHolster + 1 * Time.deltaTime

		if (not self.tempDisableHolster and self.timeHeldHolster > 0.1) then
			-- Switch
			self.isHolstered = not self.isHolstered

			-- Tick bools
			self.alreadyShot = false
			self.alreadyHolstered = false
	
			-- Main
			if (self.isHolstered) then
				self:HolsterSystem(true, true)
			else
				self:HolsterSystem(false, true)
			end

			-- Temp Disable
			self.tempDisableHolster = true
		end
	elseif (Input.GetKeyUp(KeyCode.BackQuote) and self.pressedHolsterButton and self.playerWeapon and self.timeHeldHolster < 0.1) then
		-- Switch
		self.isHolstered = not self.isHolstered

		-- Tick bools
		self.alreadyShot = false
		self.alreadyHolstered = false

		-- Main
		if (self.isHolstered) then
			self:HolsterSystem(true, false)
		else
			self:HolsterSystem(false, false)
		end
	end

	if (Input.GetKeyUp(KeyCode.BackQuote)) then
		self.tempDisableHolster = false
		self.pressedHolsterButton = false
		self.timeHeldHolster = 0
	end

	-- Safety System
	if (Input.GetKeyDown(KeyCode.LeftBracket) and not self.isHolstered) then
		-- Switch
		self.safeOn = not self.safeOn

		-- Main
		if (self.safeOn) then
			self:SafetySystem(true)
		else
			self:SafetySystem(false)
		end
	end

	if (self.playerWeapon) then
		-- Animation Handling
		local animator = self.playerWeapon.animator

		if (self.safeOn) then
			animator.CrossFade("Tuck", 1.5)
		end
	end

	-- Unloading System
	if (Input.GetKeyDown(KeyCode.U) and not self.isUnloaded and self.playerWeapon and not self.playerWeapon.isReloading) then
		self.isUnloaded = not self.isUnloaded

		-- Get the weapon ammo data
		if (not self.alreadyGotWeaponData) then
			self.weaponMaxAmmo = self.playerWeapon.maxAmmo
			self.alreadyGotWeaponData = true
		end
		
		self:UnloadWeapon(self.playerWeapon, true, self.playerWeapon.animator)
	end

	if (Input.GetKeyBindButtonDown(KeyBinds.Reload) and self.isUnloaded and self.playerWeapon and not self.playerWeapon.isReloading) then
		self.isUnloaded = not self.isUnloaded
		self:UnloadWeapon(self.playerWeapon, false, self.playerWeapon.animator)
	end
end

function WeaponModifier:IsRaveceiverWeapon()
	local output = false

	if (self.playerWeapon) then
		local foundScripts = self.playerWeapon.gameObject.GetComponentsInChildren(ScriptedBehaviour)

		for _,script in pairs(foundScripts) do
			local curScript = script.self

			if (curScript.aRaveceiverWeapon) then
				-- Cache the script
				self.rcScript = curScript

				-- Set output to true
				output = true
				break
			end
		end
	end

	return output
end

function WeaponModifier:UnloadWeapon(weapon, unload, animator)
	-- Basically the unload system
	if (unload) then
		-- Empty Clip
		weapon.maxAmmo = 0
		weapon.spareAmmo = weapon.spareAmmo + weapon.ammo

		weapon.ammo = 0

		-- Play Animation
		animator.SetTrigger("reload")
	else
		-- Reset Max Ammo
		weapon.maxAmmo = self.weaponMaxAmmo

		-- Reload
	    weapon.Reload()
	end
end

function WeaponModifier:SafetySystem(safe)
	-- Handles the safety system
	if (safe) then
		self.playerWeapon.LockWeapon()
	else
		self.playerWeapon.UnlockWeapon()
	end
end

function WeaponModifier:HolsterSystem(holstering, slowDraw)
	-- Handles the holstering system
	if (holstering) then
		-- Holstering
		self.playerWeapon.gameObject.SetActive(false)
	else
		-- Unholstering
		self.playerWeapon.gameObject.SetActive(true)

		-- Play Animation
		local animator = self.playerWeapon.animator

		if (animator) then
			animator.SetTrigger("unholster")
		end
	end

	-- Check if the safe is on
	self.script.StartCoroutine(self:CheckSafe(self.safeOn, self.playerWeapon, slowDraw))
end

function WeaponModifier:CheckSafe(safe, weapon, slowDraw)
	-- If the weapon has it's safe on then there will be no accidental discharges will happen.
	-- If it isn't then a discharge might happen.
	return function()
		coroutine.yield(WaitForSeconds(0.15))
		if (not self.alreadyShot) then
			if (not safe and not slowDraw) then
				-- Initiate a luck
				local luck = Random.Range(1, 100)

				-- If the luck is below the discharge chance then shoot
				if (luck < self.quickDrawDischargeChance and not slowDraw) then
					self:ShootSelf(weapon)
				elseif (luck < self.slowDrawDischargeChance and slowDraw) then
					self:ShootSelf(weapon)
				end

				-- Tick alreadyShot
				self.alreadyShot = true
			end
		end
		coroutine.yield(WaitForSeconds(0.05))
		-- Get the player for checks
		local player = Player.actor

		if (not self.alreadyHolstered and player and not player.isDead) then
			-- Lock or Unlock the weapon depending on the state
			if (safe) then
				weapon.LockWeapon()
			else
				weapon.UnlockWeapon()
			end

			-- Tick alreadyHolstered
			self.alreadyHolstered = true
		end
	end
end

function WeaponModifier:ShootSelf(weapon)
	-- This block literally makes the player shoots it self
	if (weapon.ammo > 0) then
		weapon.Shoot(true)

		local player = Player.actor
	
		if (player) then
			player.Damage(nil, 50, 0, false, false)
		end
	end
end

function WeaponModifier:Suicide(start, shoot, stop)
	-- Based self harm
	-- Check if the rcScript isn't nil

	-- This will only work if the weapon is a raveceiver weapon
	if (self.rcScript) then
		-- Starts the suicide phase
		if (start) then
			self.rcScript:TriggerMindControl("start")
		end

		-- Shoot function
		if (shoot) then
			self.rcScript:TriggerMindControl("shoot")
		end

		-- Stops the mindControl event
		if (stop) then
			self.rcScript:TriggerMindControl("stop")
		end
	end
end
