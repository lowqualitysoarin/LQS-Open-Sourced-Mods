-- low_quality_soarin © 2023-2024
behaviour("RaveceiverWeaponBase")

-- Save load system
local attachmentSaveDatas = {{"dummy023123121", {0}}}

function RaveceiverWeaponBase:Start()
	-- Scripts
	self.rcInventory = nil
	self.rcControlsHelper = nil

	-- Gameplay
	self.randomisedConditions = self.script.mutator.GetConfigurationBool("randomisedConditions")
	self.enableJamming = self.script.mutator.GetConfigurationBool("enableJamming")
	self.enableAccidentalDischarges = self.script.mutator.GetConfigurationBool("enableAccidentalDischarges")
	self.allowBlinking = self.script.mutator.GetConfigurationBool("allowBlinking")
	self.allowAimShake = self.script.mutator.GetConfigurationBool("allowAimShake")
	self.enablePauseInfo = self.script.mutator.GetConfigurationBool("enablePauseInfo")

	-- Keybinds
	self.holsterKey = string.lower(self.script.mutator.GetConfigurationString("holsterKey"))
	self.toggleAimKey = string.lower(self.script.mutator.GetConfigurationString("toggleAimKey"))
	self.pickupKey = string.lower(self.script.mutator.GetConfigurationString("pickupKey"))
	self.holsterLightKey = string.lower(self.script.mutator.GetConfigurationString("holsterLightKey"))

	self.carrierOutKey = string.lower(self.script.mutator.GetConfigurationString("carrierOutKey"))
	self.carrierInInsertBulletKey = string.lower(self.script.mutator.GetConfigurationString("carrierInInsertBulletKey"))
	self.removeBulletRackCloseKey = string.lower(self.script.mutator.GetConfigurationString("removeBulletRackCloseKey"))

	self.slideLockTapKey = string.lower(self.script.mutator.GetConfigurationString("slideLockTapKey"))
	self.pullHammerKey = string.lower(self.script.mutator.GetConfigurationString("pullHammerKey"))

	self.safetyFiremodeEjectKey = string.lower(self.script.mutator.GetConfigurationString("safetyFiremodeEjectKey"))
	self.altFiremodeKey = string.lower(self.script.mutator.GetConfigurationString("altFiremodeKey"))

	self.cylinderSpinLeftKey = string.lower(self.script.mutator.GetConfigurationString("cylinderSpinLeftKey"))
	self.cylinderSpinRightKey = string.lower(self.script.mutator.GetConfigurationString("cylinderSpinRightKey"))

	-- Others
	-- Mag Drop
	self.botsDropMags = self.script.mutator.GetConfigurationBool("botsDropMags")
	self.dropMagChance = self.script.mutator.GetConfigurationRange("dropMagChance")

	-- Aiming Deadzone
	self.lockGunToCenter = self.script.mutator.GetConfigurationBool("lockGunToCenter")

	-- Customisation
	self.customisationSystem = self.script.mutator.GetConfigurationBool("customisationSystem")
	self.customisationKey = string.lower(self.script.mutator.GetConfigurationString("customisationKey"))
	self.freeManipulateKey = string.lower(self.script.mutator.GetConfigurationString("freeManipulateKey"))

	-- Monitors/Events
	self.script.AddValueMonitor("MonitorActiveWeapon", "OnActiveWeaponChange")
	GameEvents.onActorDied.AddListener(self, "OnActorDied")
	GameEvents.onActorSpawn.AddListener(self, "OnActorSpawn")

	-- Assets
	self.rcFlashlight = self.targets.rcFlashlight

	self.canvas = self.targets.canvas
	self.pauseHUD = self.targets.pauseHUD

	self.blank = self.targets.blank.GetComponent(Image)
	self.gameHUD = self.targets.gameHUD

	self.customT = self.targets.customT.transform
	self.customisationHUD = self.targets.customisationHUD
	self.attachmentPoints = self.targets.attachmentPoints

	-- Heads Up Info
	self.gunName = self.targets.gunName.GetComponent(Text)
	self.description = self.targets.description.GetComponent(Text)
	self.currentDropdownIndicator = self.targets.currentDropdownIndicator.GetComponent(Text)

	-- Vars
	self.weaponT = nil
	self.rcScript = nil

	self.aimLookEuler = Vector3.zero
	self.alreadyCalledResetLook = false

	self.customisationActive = false
	self.alreadyCalledCustomReset = false
	self.canSaveData = true
	self.cRotX = 0
	self.cRotY = 0
	self.currentDropdownIndex = 1

	-- Finishing Touches
	self.script.StartCoroutine(self:Finalize())

	self.pauseHUD.SetActive(false)
	self.blank.CrossFadeAlpha(0, 0, true)
end

function RaveceiverWeaponBase:Finalize()
	return function()
		coroutine.yield(WaitForSeconds(0.05))
		-- HUD
		self.gameHUD.SetActive(false)
		self.customisationHUD.SetActive(false)

		-- Apply global variables
		_G.rcBaseSaveLoad = self.gameObject.GetComponent(ScriptedBehaviour).self
	end
end

function RaveceiverWeaponBase:OnActorSpawn(actor)
	-- Save Load Attachment
	if (actor.isPlayer) then
		self.script.StartCoroutine(self:CheckWeaponDelay(actor.activeWeapon))
	end
end

function RaveceiverWeaponBase:CheckWeaponDelay(weapon)
	-- Have to put this in a coroutine because it passes a nil later in the weapon
	-- Check despite its not a nil in spawn
	return function()
		coroutine.yield(WaitForSeconds(0.05))
		self:RCWeaponCheck(weapon)
	end
end

function RaveceiverWeaponBase:OnActorDied(actor, killer)
	-- RC Resetter
	if (actor.isPlayer) then
		self:ResetMain()
	end

	-- Mag Drop System
	if (self.rcScript and self.botsDropMags) then
		if (actor and killer) then
			if (not actor.isPlayer and killer.isPlayer) then
				local luck = Random.Range(0, 100)
	
				if (luck < self.dropMagChance) then
					self:DropMag(self.rcScript, actor)
				end
			end
		end
	end
end

function RaveceiverWeaponBase:ResetMain()
	-- Resets the weapon vars and stuff
	-- Reset rcScript
	self.rcScript = nil

	-- Reset HUD elements and stuff
	self:ResetElements()
	self:CleanCustomisationCanvas()
end

function RaveceiverWeaponBase:DropMag(rcScript, actor)
	-- Checks
	-- Gmod like ahhh checking.
	if (not rcScript) then return end
	if (not rcScript.weaponPartsManager.hasMag) then return end
	if (rcScript.weaponPartsManager.isRevolverLike) then return end
	if (not rcScript.magazineObj) then return end
	if (not rcScript.ammoCarrier) then return end

	-- Spawn Mag
	-- Get Pos
	local spawnPos = actor.transform.position

	if (actor.isFallenOver) then
		spawnPos = actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest)
	else
		spawnPos = actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest)
	end

	-- Instantiate Mag
	local mag = GameObject.Instantiate(rcScript.magazineObj, spawnPos, Quaternion.identity).GetComponent(ScriptedBehaviour).self

	-- Setup Bullet Amount
	mag.storedAmmoCount = math.random(rcScript.ammoCarrier.maxAmmo)
	mag:ApplyBulletAmount()
end

function RaveceiverWeaponBase:MonitorActiveWeapon()
	return Player.actor.activeWeapon
end

function RaveceiverWeaponBase:OnActiveWeaponChange(weapon)
	-- Raveceiver Weapon Check
	self.script.StartCoroutine(self:CheckWeaponDelay(weapon))
end

function RaveceiverWeaponBase:RCWeaponCheck(weapon)
	-- Check if its a raveceiver weapon.
	-- Similar technique on how I check if its a raveceiver weapon. On my raveceiver game.
	if (not weapon) then return end
	
	-- Reset rcScript and disable flashlight
	self.rcFlashlight.SetActive(false)

	self.weaponT = nil
	self.rcScript = nil
	self.canSaveData = true

	self.currentDropdownIndex = 1

	-- Start looking for raveceiverBase script
	local foundScripts = weapon.gameObject.GetComponentsInChildren(ScriptedBehaviour)

	for _,script in pairs(foundScripts) do
		local curScript = script.self

		if (curScript.aRaveceiverWeapon) then
			-- Turn on flashlight
			self.rcFlashlight.SetActive(true)

			-- Cache the script and the weapon transform if its a raveceiver weapon
			self.rcScript = curScript
			self.weaponT = weapon.transform
			break
		end
	end

	-- This block below will only work if the weapon has a weapon base script
	if (not self.rcScript) then return end
	if (not self.rcScript.thisWeapon) then return end

	-- Load or Save attachment data
	-- Checks if the weapon existed in the saveData.
	if (self:WeaponExistedOnSaveData(self.rcScript.thisWeapon.weaponEntry.name)) then
		-- If so then load
		self.script.StartCoroutine(self:LoadSaveCustomisation(false, true))
	else
		-- Else create a new save
		self.script.StartCoroutine(self:LoadSaveCustomisation(true, false))
	end
end

function RaveceiverWeaponBase:WeaponExistedOnSaveData(weapon)
	-- A function that checks if the given weapon in in the saveData table
	for _,data in pairs(attachmentSaveDatas) do
		if (data[1] and data[1] == weapon) then
			return true
		end
	end
	return false
end

function RaveceiverWeaponBase:Update()
	local actor = Player.actor

	-- Functions
	-- If the player has a raveceiver weapon on hand.
	if (self.rcScript) then
		-- Weapon Info
		if (GameManager.isPaused and not SpawnUi.isOpen and self.enablePauseInfo) then
			self:WeaponInfo()
		else
			self:WeaponInfo(true)
		end

		-- Pickup Function
		if (actor and not actor.isDead) then
			self:PickupSystem(actor)
		end

		-- Customisation
		self:WeaponCustomisation()

		-- Aim Deadzone
		self:AimDeadzone()

		-- Unhide Game HUD
		if (not self.customisationActive) then
			self.gameHUD.SetActive(true)
		else
			self.gameHUD.SetActive(false)
		end
	else
		self:ResetElements()
	end
end

function RaveceiverWeaponBase:ResetElements()
	-- Literally resets the game elements
	-- Reset Info Data
	self:WeaponInfo(true)

	-- Reset Aim Deadzone
	self:AimDeadzone(true)

	-- Reset Customisation
	self:WeaponCustomisation(true)

	-- Hide Game HUD
	self.gameHUD.SetActive(false)
end

function RaveceiverWeaponBase:WeaponCustomisation(reset)
	-- The weapon customisation system, lol idk.
	if (not reset) then
		if (not self.customisationSystem) then return end
		if (not self.rcScript) then return end
		if (Time.timeScale <= 0) then return end
	
		-- Toggle Customisation Menu
		if (Input.GetKeyDown(self.customisationKey)) then
			self.customisationActive = not self.customisationActive
			self:ToggleCustomisation(self.customisationActive)
		end

		-- Free Manipulate
		if (Input.GetKeyDown(self.freeManipulateKey)) then
			self.rcScript.tempDisableFeatures = not self.rcScript.tempDisableFeatures
		end

		-- Dropdown Hider
	    if (Input.GetKeyDown(KeyCode.H) and self.rcScript.customisationContainer) then
	    	self.rcScript.customisationContainer:ToggleDropdowns(not self.rcScript.customisationContainer.active)
	    end

		if (self.customisationActive) then
			-- Control
			self:CustomisationControl()

			-- Customisation Manager
			self:CustomisationManager()
		end

		-- Reset Bool
		self.alreadyCalledCustomReset = false
	else
		if (not self.alreadyCalledCustomReset) then
			self:ToggleCustomisation()
			self.alreadyCalledCustomReset = true
		end
	end
end

function RaveceiverWeaponBase:CustomisationManager()
	-- This controls the dropdowns in the customisation manager
	local customisationContainer = self.rcScript.customisationContainer
	if (not customisationContainer) then return end

	-- Move the items in their targetOrigin 
	for _,cDropdown in pairs(customisationContainer.dropdowns) do
		if (cDropdown) then
			if (cDropdown and cDropdown.targetOrigin) then
				cDropdown.transform.position = PlayerCamera.activeCamera.WorldToScreenPoint(cDropdown.targetOrigin.position)
			end
		end
	end

	-- Selection System
	-- Adding this because some mutators just keep locking the mouse making the player
	-- unable to select a attachment on their weapon.
	if (Input.GetKeyDown(KeyCode.RightArrow)) then
		-- Add
		self.currentDropdownIndex = self.currentDropdownIndex + 1
	elseif (Input.GetKeyDown(KeyCode.LeftArrow)) then
		-- Subtract
		self.currentDropdownIndex = self.currentDropdownIndex - 1
	end

	-- Dropdown Index Clamping
	if (self.currentDropdownIndex > #customisationContainer.dropdowns) then
		self.currentDropdownIndex = 1
	elseif (self.currentDropdownIndex < 1) then
		self.currentDropdownIndex = #customisationContainer.dropdowns
	end

	-- Dropdown Operation
	-- Get the dropdown
	local currentDropdown = customisationContainer.dropdowns[self.currentDropdownIndex]

	if (currentDropdown) then
		-- Controlling
		if (Input.GetKeyDown(KeyCode.UpArrow)) then
			-- Up
			currentDropdown.currentIndex = currentDropdown.currentIndex + 1
		elseif (Input.GetKeyDown(KeyCode.DownArrow)) then
			-- Down
			currentDropdown.currentIndex = currentDropdown.currentIndex - 1
		end

		-- Selection Clamping
		if (currentDropdown.currentIndex > #currentDropdown.foundItems) then
			currentDropdown.currentIndex = 1
		elseif (currentDropdown.currentIndex < 1) then
			currentDropdown.currentIndex = #currentDropdown.foundItems
		else
			currentDropdown:LoadAttachment(currentDropdown.currentIndex, false, true)
		end
	end

	-- Current Dropdown Indicator
	-- Gives a heads up on what dropdown is the player selected.
	if (currentDropdown.attachmentPointName) then
		self.currentDropdownIndicator.text = "Current dropdown: <color=orange>" .. currentDropdown.attachmentPointName .. "</color>"
	else
		self.currentDropdownIndicator.text = "Current dropdown: <color=orange>ERROR:NO_ATTACHMENT_POINT_NAME</color>"
	end
end

function RaveceiverWeaponBase:CleanCustomisationCanvas()
	-- This cleans the customisation canvas, so basically when the player gets killed while
	-- customising their weapon some dropdowns will be left out in the canvas triggering errors and stuff.
	-- Soo this cleans it, to prevent those.

	-- Get the transforms of the children
	local canvasMain = self.attachmentPoints
	local canvasItems = canvasMain.GetComponentsInChildren(Transform)

	-- Eradicate every gameObject present in the customisation canvas
	for _,item in pairs(canvasItems) do
		if (item and item.gameObject ~= canvasMain) then
			GameObject.Destroy(item.gameObject)
		end
	end
end

function RaveceiverWeaponBase:LoadSaveCustomisation(ignoreLoad, ignoreSave, receivedID)
	-- Loads and Saves the customisation preset
	return function() 
		-- Checks because this is crucial
		if (not self.rcScript) then return end
		if (not self.rcScript.customisationContainer) then return end

		coroutine.yield(WaitForSeconds(0))

		-- Get the current weapon's name
		local currentWeaponName = self.rcScript.thisWeapon.weaponEntry.name

		coroutine.yield(WaitForSeconds(0))
	
		-- Load
		if (not ignoreLoad) then
			for _,data in pairs(attachmentSaveDatas) do
				-- Check if the weapon script and the data's weapon script is the same
				if (data and data[1] == currentWeaponName) then
					-- If so then get the dropdowns then load the values
					local cDropdowns = self.rcScript.customisationContainer.dropdowns

					-- Loop and load all saved indexes
					for i = 1, #cDropdowns do
						-- Load
						cDropdowns[i]:LoadAttachment(data[2][i], true, true)

						-- Break the loop when it reaches the last index
						if (i == #cDropdowns) then break end
					end
				end
			end
		end
	
		-- Save
		if (not ignoreSave) then
			local existingDataFound = false
			local existingIndex = nil
		
			-- Check if there is a existing content
			for index,data in pairs(attachmentSaveDatas) do
				if (data[1] == currentWeaponName) then
					-- If so stop the loop and pass the results
					existingIndex = index
					existingDataFound = true
					break
				end
			end
		
			if (existingDataFound) then
				-- if a existing data was found then save it there
				if (attachmentSaveDatas[existingIndex] and receivedID) then
					if (attachmentSaveDatas[existingIndex][1] == currentWeaponName) then
						-- If so save to the existing one
						local cDropdowns = self.rcScript.customisationContainer.dropdowns

						-- Save the dropdown value
						for _,dropdown in pairs(cDropdowns) do
							-- Save the dropdown value
							if (dropdown.dropdownID and dropdown.dropdownID == receivedID) then
								attachmentSaveDatas[existingIndex][2][receivedID] = dropdown.currentIndex
								break
							end
						end
					end
				end
			else
				-- Else make a new save
				local premadeSaveData = {currentWeaponName, {}}
				local cDropdowns = self.rcScript.customisationContainer.dropdowns
		
				for id,dropdown in pairs(cDropdowns) do
					-- Assign the ID of the dropdown
					dropdown:DropdownIDManager(id)

					-- Save every dropdown value
					premadeSaveData[2][#premadeSaveData[2]+1] = dropdown.currentIndex
				end
		
				-- Pass the premadeSaveData to the attachmentSaveData
				attachmentSaveDatas[#attachmentSaveDatas+1] = premadeSaveData
			end
		end
	end
end

function RaveceiverWeaponBase:CustomisationControl()
	-- Controls the weapon during customisation
	-- Get the poseHandler script
	local wpPoseHandler = self.rcScript.poseHandler

	-- Control rotation
	if (Input.GetKeyBindButton(KeyBinds.Aim)) then
		self.cRotX = self.cRotX + Input.GetAxis("Mouse X") * 15
		self.cRotY = self.cRotY + Input.GetAxis("Mouse Y") * 15

		self.customT.localRotation = Quaternion.Euler(Vector3(-self.cRotY, -self.cRotX, 0))
	end

	-- Control zoom
	if (Input.mouseScrollDelta.y < 0) then
		local modVector = Vector3(
			self.customT.localPosition.x,
			self.customT.localPosition.y,
			self.customT.localPosition.z + 0.15
		)

		-- Clamping
		self.customT.localPosition = Vector3(modVector.x, modVector.y, self:ClampT(modVector.z, 0.145, 0.893))
	end

	if (Input.mouseScrollDelta.y > 0) then
		local modVector = Vector3(
			self.customT.localPosition.x,
			self.customT.localPosition.y,
			self.customT.localPosition.z - 0.15
		)

		-- Clamping
		self.customT.localPosition = Vector3(modVector.x, modVector.y, self:ClampT(modVector.z, 0.145, 0.893))
	end

	-- Output
	wpPoseHandler:ProceduralAnimator(wpPoseHandler.gunTransform, self.customT, 7.5, true, true)
end

function RaveceiverWeaponBase:ToggleCustomisation(active)
	-- Conver nil to false
	if (active == nil) then
		active = false
	end

	-- Toggles the customisation menu
	-- Weapon Bools
	if (self.rcScript) then
		self.rcScript.tempDisableFeatures = active
    	self.rcScript.poseHandler.stopGunPoses = active

		if (self.rcScript.customisationContainer) then
			self.rcScript.customisationContainer:ToggleDropdowns(active)

			if (active) then
				self.rcScript.customisationContainer:TransferItems(false, self.attachmentPoints)
			else
				self.rcScript.customisationContainer:TransferItems(true)
			end
		end
	end

	-- Customisation HUD
	self.customisationHUD.SetActive(active)

	-- Player HUD
	local player = Player.actor

	if (player and not player.isDead) then
		PlayerHud.hudGameModeEnabled = not active
		PlayerHud.hudPlayerEnabled = not active
	end

	-- Main
	if (not active) then
		-- Disable/Reset
		self.customisationActive = false
		self.cRotX = 0
		self.cRotY = 0

		self.customT.localRotation = Quaternion.Euler(Vector3(0, -90, 0))
		self.customT.localPosition = Vector3(
			self.customT.localPosition.x,
			self.customT.localPosition.y,
			0.393
		)

		-- Main
		Screen.LockCursor()
		Input.EnableNumberRowInputs()
	else
		-- Main
		Screen.UnlockCursor()
		Input.DisableNumberRowInputs()
	end
end

function RaveceiverWeaponBase:AimDeadzone(reset)
	if (self.lockGunToCenter) then return end
	if (self.customisationActive) then return end
	if (self.rcScript and self.rcScript.forceDisableAimDeadzone) then return end
	if (Time.timeScale <= 0) then return end

	-- Get the weapon and camera transform
	local playerWeaponT = nil

	if (Player.actor.activeWeapon) then
		playerWeaponT = Player.actor.activeWeapon.transform
	end

	-- Main
	if (playerWeaponT) then
		if (not reset) then
			-- Main Aim Deadzone System
			-- Kindof similar to insurgency's aiming deazone.
			local rcScript = self.rcScript
	
			-- Reset Single Trigger Bool
			self.alreadyCalledResetLook = false
	
			-- Deadzone System
			if (rcScript.isAiming) then
				-- Make the look rot
				local input = Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"))
				self.aimLookEuler = self.aimLookEuler + Vector3(-input.y, input.x, 0)
	
				-- Clamp the rotation
				-- Soo it won't go around the player. And god damn it Steel didn't
				-- exposed Quaternion.Clamp or Vector3.Clamp.
				self.aimLookEuler = Vector3(self:ClampT(self.aimLookEuler.x, -6.5, 6.5), self:ClampT(self.aimLookEuler.y, -6.5, 6.5), self.aimLookEuler.z)
			else
				self.aimLookEuler = Vector3.Lerp(self.aimLookEuler, Vector3.zero, 10 * Time.deltaTime)
			end

			-- Lerp
			playerWeaponT.localRotation = Quaternion.Euler(self.aimLookEuler)
		else
			if (not self.alreadyCalledResetLook) then
				-- Resets the deadzone
				self.aimLookEuler = Vector3.zero
				playerWeaponT.localRotation = Quaternion.Euler(self.aimLookEuler)
		
				-- Single Trigger Bool
				self.alreadyCalledResetLook = true
			end
		end
	end
end

function RaveceiverWeaponBase:ClampT(value, min, max)
	-- My own clamping system. Because Steel didn't provide one for
	-- Vector3s and Quaternions.
	if (value and min and max) then
		if (value >= max) then
			value = max
		end

		if (value <= min) then
			value = min
		end

		return value
	end
end

function RaveceiverWeaponBase:WeaponInfo(reset)
	-- Weapon Information Handler
	-- Local Vars
	local infoData = nil

	local name = nil
	local desc = nil

	-- Get the infoData
	if (self.rcScript) then
		infoData = self.rcScript.infoContainer
	end

	if (infoData and not reset) then
		-- If infoData exists then continue
		-- Get the weapon name
		if (infoData.HasString("weaponName")) then
			name = string.upper(infoData.GetString("weaponName"))
		else
			name = string.upper("None Provided")
		end

		-- Get the weapon desc
		if (infoData.HasString("description")) then
			desc = infoData.GetString("description")
		else
			desc = "Fall back invalid info. If you are seeing this, something went wrong."
		end

		-- Finalize
		self.gunName.text = name
		self.description.text = desc

		-- Enable pauseHUD
		self.pauseHUD.SetActive(true)
	elseif (not infoData or reset) then
		-- Disable pauseHUD
		self.pauseHUD.SetActive(false)
	end
end

function RaveceiverWeaponBase:PickupSystem(actor)
	-- The pickup system for picking up live rounds dropped by a raveceiver weapon
	if (Input.GetKeyDown(self.pickupKey)) then
		local pickupSphere = Physics.OverlapSphere(actor.transform.position, 1.5, RaycastTarget.ProjectileHit)

		if (#pickupSphere > 0) then
			for _,obj in pairs(pickupSphere) do
				if (self:IsPickup(obj)) then
					self:Pickup(obj)
				end
			end
		end
	end
end

function RaveceiverWeaponBase:IsPickup(object)
	-- Similar way how I check cassette tapes in raveceiver.
	local output = false

	if (object.gameObject.GetComponentInParent(ScriptedBehaviour)) then
		local script = object.gameObject.GetComponentInParent(ScriptedBehaviour).self

		if (script.isPickable) then
			output = true
		end
	end

	return output
end

function RaveceiverWeaponBase:Pickup(obj)
	-- Get the ammo carrier script, else it will not work.
	-- And I have to double check lmaooo.
	if (self.rcScript) then
		-- Get Scripts
		local ammoCarrier = self.rcScript.ammoCarrier
		local script = obj.gameObject.GetComponentInParent(ScriptedBehaviour).self

		if (ammoCarrier) then
			if (not script.isMag) then
				-- Add Bullet
				ammoCarrier:ResupplyAmmo()

				-- Destroy Object
				GameObject.Destroy(obj.transform.parent.gameObject)
			else
				-- Add Magazine
				-- Checks
				if (self.rcScript.targetMagID ~= script.magID) then return end

				-- Start Adding
				if (ammoCarrier:MagManager(1, "add", script.storedAmmoCount)) then
					-- Destroy Object
					GameObject.Destroy(obj.transform.parent.gameObject)
				end
			end
		end
	end
end

function RaveceiverWeaponBase:Blink()
	-- Blinking system
	-- Everytime the player fires.

	-- Blink
	self.blank.CrossFadeAlpha(1, 0.025, false)

	-- Stop Blinking
	self.script.StartCoroutine(self:StopBlink())
end

function RaveceiverWeaponBase:StopBlink()
	return function()
		coroutine.yield(WaitForSeconds(0.055))
		self.blank.CrossFadeAlpha(0, 0.045, false)
	end
end
