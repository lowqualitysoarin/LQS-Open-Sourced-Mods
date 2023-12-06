behaviour("WeaponMenu")

function WeaponMenu:Awake()
	-- Base
	self.mainMenuScript = self.targets.mainMenuScript.GetComponent(ScriptedBehaviour).self
	self.weaponsFound = {}

	self.weaponMenu = self.targets.weaponMenu
	self.weaponSelection = self.targets.weaponSelection
	self.contents = self.targets.contents.transform

	-- Essentials
	self.alreadySearched = false
end

function WeaponMenu:Start()
	-- Start finding available weapons
	self.script.StartCoroutine(self:GenerateWeaponList())
end

function WeaponMenu:GenerateWeaponList()
	return function()
		coroutine.yield(WaitForSeconds(0.1))
		if (not self.alreadySearched) then
			-- Get all available weapons
			self.weaponsFound = WeaponManager.allWeapons

			-- Another table that excludes equipments
			local availablesTable = {}

			-- Exclude any melees, throwables, equipment, etc...
			-- You don't need those, especially you don't want to have a medkit against drones.
			for index,wep in pairs(self.weaponsFound) do
				-- Check if the weapon's slot is gear or large gear
				-- If the weapon entry isn't then add it to the availables table.
				if (wep.slot ~= WeaponSlot.Gear) then
					if (wep.slot ~= WeaponSlot.LargeGear) then
						availablesTable[#availablesTable+1] = wep
					end
				end
			end

			-- Start making instantiates of weaponEntries for the selection
			for _,wepEntry in pairs(availablesTable) do
				-- Instantiate weapon entry selection
				local entryCopy = GameObject.Instantiate(self.weaponSelection, self.contents)

				-- Assign data
				local entryScript = entryCopy.GetComponent(ScriptedBehaviour).self

				if (entryScript) then
					entryScript.weaponEntry = wepEntry
					entryScript.weaponMenuScript = self.gameObject.GetComponent(ScriptedBehaviour).self
					entryScript.mainMenuScript = self.mainMenuScript
				end
			end

			-- Tick alreadySearched when done soo it won't make another copy
			self.alreadySearched = true
		end
	end
end

function WeaponMenu:CloseMenu()
	-- Closes the menu
	self.weaponMenu.SetActive(false)
	self.mainMenuScript.gameOptions.SetActive(true)
end
