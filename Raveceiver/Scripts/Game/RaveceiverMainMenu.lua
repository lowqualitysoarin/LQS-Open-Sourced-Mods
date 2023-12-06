behaviour("RaveceiverMainMenu")

function RaveceiverMainMenu:Awake()
	-- Base (Awake)
	self.data = self.gameObject.GetComponent(DataContainer)
	self.mainScript = self.targets.mainScript.GetComponent(ScriptedBehaviour).self

	-- Impotant Prefabs
	self.gamePrefabs = self.data.GetGameObjectArray("gamePrefab")

	-- Main Targets
	self.startScreen = self.targets.startScreen
	self.gameOptions = self.targets.gameOptions
	self.weaponMenu = self.targets.weaponMenu

	self.blackScreen = self.targets.blackScreen.GetComponent(Image)

	self.mainMenuScene = self.targets.mainMenuScene
	self.emptyObject = self.targets.emptyObject

	self.menuMusic = self.targets.menuMusic.GetComponent(AudioSource)

	-- UI Elements
	self.startButton = self.targets.startButton.GetComponent(Button)
	self.startGameButton = self.targets.startGameButton.GetComponent(Button)
	self.weaponSelectionButton = self.targets.weaponSelectionButton.GetComponent(Button)

	self.noChances = self.targets.noChances.GetComponent(Toggle)
	self.shotInTheDark = self.targets.shotInTheDark.GetComponent(Toggle)
	self.randomWeapons = self.targets.randomWeapons.GetComponent(Toggle)
	self.randomConditions = self.targets.randomConditions.GetComponent(Toggle)

	self.tilesInput = self.targets.tilesInput.GetComponent(InputField)
	self.ammoInput = self.targets.ammoInput.GetComponent(InputField)
	self.spareAmmoInput = self.targets.spareAmmoInput.GetComponent(InputField)

	-- Listeners
	-- Buttons
	self.startButton.onClick.AddListener(self, "OnStartButtonClick")
	self.startGameButton.onClick.AddListener(self, "GameStart")
	self.weaponSelectionButton.onClick.AddListener(self, "OpenWeaponMenu")

	-- Input Fields
	self.tilesInput.onEndEdit.AddListener(self, "TileInputValueChanged")
	self.ammoInput.onEndEdit.AddListener(self, "AmmoInputChanged")
	self.spareAmmoInput.onEndEdit.AddListener(self, "SpareAmmoInputChanged")

	-- Toggles
	self.noChances.onValueChanged.AddListener(self, "NoChancesEnabled")
	self.shotInTheDark.onValueChanged.AddListener(self, "ShotInTheDarkEnabled")
	self.randomWeapons.onValueChanged.AddListener(self, "RandomWeaponsEnabled")
	self.randomConditions.onValueChanged.AddListener(self, "RandomConditionsEnabled")

	-- Essentials
	-- Weapon Selection
	self.selectedWeapon = nil

	-- Bools
	self.alreadyCalled = false
	self.alreadyDisabledLoadout = false
	self.alreadySetWeapon = false
end

function RaveceiverMainMenu:Start()
	-- Turn off black screen
	self.blackScreen.CrossFadeAlpha(0, 1, false)

	-- Disable Loadout
	self.script.StartCoroutine(self:DisableLoadout())

	-- Disable game menu
	self.gameOptions.SetActive(false)

	-- Get the player's secondary weapon on it's loadout and apply it as a
	-- current selected weapon.
	self.script.StartCoroutine(self:GetPlayerSecondary())
end

function RaveceiverMainMenu:GetPlayerSecondary()
	return function()
		coroutine.yield(WaitForSeconds(0.1))
		if (not self.alreadSetWeapon) then
			local playerSecondary = Player.selectedLoadout.secondary

			if (playerSecondary) then
				self:OnWeaponSelected(playerSecondary)
			end
		end
	end
end

function RaveceiverMainMenu:Update()
	-- Fade In Menu Music
	self.menuMusic.volume = Mathf.Lerp(self.menuMusic.volume, 100, Time.deltaTime * 9)
end

function RaveceiverMainMenu:OnWeaponSelected(weaponEntry)
	-- Applies the selected weapon
	self.selectedWeapon = weaponEntry

	-- Set the weaponSprite and name of the weapon to the current selection.
	local uiImage = self.weaponSelectionButton.transform.GetChild(0).gameObject.GetComponent(Image)
	local weaponName = self.weaponSelectionButton.gameObject.GetComponentInChildren(TextMeshProUGUI)

	uiImage.sprite = self.selectedWeapon.uiSprite
	weaponName.text = self.selectedWeapon.name

	-- Set the weapon's max ammo and spare ammo to the conditions field
	self.ammoInput.text = tostring(self.selectedWeapon.prefabWeapon.maxAmmo)
	self.spareAmmoInput.text = tostring(self.selectedWeapon.prefabWeapon.maxSpareAmmo)

	if (self.mainScript) then
		-- Pass the selected weapon
		self.mainScript.chosenWeapon = self.selectedWeapon

		-- Pass the ammo and spare ammo as starting ammo and starting spare ammo on
		-- the main script
		self.mainScript.startingAmmo = tonumber(self.ammoInput.text)
		self.mainScript.startingSpareAmmo = tonumber(self.spareAmmoInput.text)
	end
end

function RaveceiverMainMenu:DisableLoadout()
	return function()
		coroutine.yield(WaitForSeconds(0.1))
		if (not self.alreadyDisabledLoadout) then
			SpawnUi.SetLoadoutVisible(false)
			SpawnUi.SetMinimapVisible(false)
			SpawnUi.SetLoadoutOverride(self.emptyObject)
			SpawnUi.SetMinimapOverride(self.emptyObject)
			SpawnUi.playerCanSelectSpawnPoint = false
			GameObject.Destroy(GameObject.Find("Background Panel"))
			Screen.UnlockCursor()
			self.alreadyDisabledLoadout = true
		end
		coroutine.yield(WaitForSeconds(0.05))
	end
end

-- Input Fields
function RaveceiverMainMenu:TileInputValueChanged(received)
	-- Find the number in the input field
	local findNumberInTilesInput = string.match(received, "%d+")

	-- Finalize
	self.tileAmount = tonumber(findNumberInTilesInput)

	if (self.mainScript) then
		self.mainScript.maxInstantiates = self.tileAmount
	end
end

function RaveceiverMainMenu:AmmoInputChanged(received)
	-- Find the number in the input field
	local foundNumber = tonumber(string.match(received, "%d+"))

	-- Check if the found ammo amount exceeds to the weapon's maxAmmo amount
	if (foundNumber and self.selectedWeapon and self.mainScript) then
		-- Get the selected weapon's maxAmmo value
		local weaponMaxAmmo = self.selectedWeapon.prefabWeapon.maxAmmo

		-- If it exceeds apply the weapon's maxAmmo instead
		if (foundNumber > weaponMaxAmmo) then
			self.mainScript.startingAmmo = weaponMaxAmmo
			self.ammoInput.text = weaponMaxAmmo
		else
			self.mainScript.startingAmmo = foundNumber
		end
	end
end

function RaveceiverMainMenu:SpareAmmoInputChanged(received)
	-- Find the number in the input field
	local foundNumber = tonumber(string.match(received, "%d+"))

	-- Check if the found spare ammo amount exceeds to the weapon's maxSpareAmmo amount
	if (foundNumber and self.selectedWeapon and self.mainScript) then
		-- Get the selected weapon's maxSpareAmmo value
		local weaponMaxSpareAmmo = self.selectedWeapon.prefabWeapon.maxSpareAmmo

		-- Finalize
		self.mainScript.startingSpareAmmo = foundNumber
	end
end

-- Buttons
function RaveceiverMainMenu:GameStart()
	-- Start the game when clicked
	self.script.StartCoroutine(self:StartGame())
end

function RaveceiverMainMenu:StartGame()
	return function()
		self.gameOptions.SetActive(false)
		coroutine.yield(WaitForSeconds(0.1))
		self.blackScreen.CrossFadeAlpha(1, 1, false)
		coroutine.yield(WaitForSeconds(5))
		if (not self.alreadyCalled) then
			Screen.LockCursor()
			SpawnUi.Close()

			self.menuMusic.Stop()

			self.mainScript:GenerateLevel(self.mainScript.levels)
			self.alreadyCalled = true
		end
		coroutine.yield(WaitForSeconds(0.15))
		self.blackScreen.CrossFadeAlpha(0, 0, true)
		self.mainMenuScene.SetActive(false)
		PlayerCamera.CancelOverrideCamera()
	end
end

function RaveceiverMainMenu:OnStartButtonClick()
	-- When clicked, it will proceed to the Game Options page
	self.script.StartCoroutine(self:OpenMenu())
end

function RaveceiverMainMenu:OpenMenu()
	return function()
		coroutine.yield(WaitForSeconds(0.05))
		-- Close Start Menu
		self.startScreen.SetActive(false)

		-- Open Game Menu
		self.gameOptions.SetActive(true)
		coroutine.yield(WaitForSeconds(1))
	end
end

function RaveceiverMainMenu:OpenWeaponMenu()
	-- Opens the weapon menu for selection 
	self.weaponMenu.SetActive(true)
	self.gameOptions.SetActive(false)
end

-- Toggles
function RaveceiverMainMenu:NoChancesEnabled()
	self.mainScript.noChances = self.noChances.isOn
end

function RaveceiverMainMenu:ShotInTheDarkEnabled()
	self.mainScript.shotInTheDark = self.shotInTheDark.isOn
end

function RaveceiverMainMenu:RandomWeaponsEnabled()
	self.mainScript.randomWeapons = self.randomWeapons.isOn

	-- Disable the weapon selection button if on
	if (self.randomWeapons.isOn) then
		self.weaponSelectionButton.interactable = false
	else
		self.weaponSelectionButton.interactable = true
	end
end

function RaveceiverMainMenu:RandomConditionsEnabled()
	self.mainScript.randomConditions = self.randomConditions.isOn

	-- Disable weapon ammo input fields if on
	if (self.randomConditions.isOn) then
		self.ammoInput.interactable = false
		self.spareAmmoInput.interactable = false
	else
		self.ammoInput.interactable = true
		self.spareAmmoInput.interactable = true
	end
end
