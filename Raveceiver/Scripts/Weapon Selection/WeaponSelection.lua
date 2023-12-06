behaviour("WeaponSelection")

function WeaponSelection:Awake()
	-- Base
	-- This script stores the weapon data from the weapon selection
	self.button = self.gameObject.GetComponent(Button)

	-- Listeners
	self.button.onClick.AddListener(self, "OnSelect")

	-- Weapon Entry
	self.weaponEntry = nil
end

function WeaponSelection:Start()
	-- Apply the weaponSprite to it's button
	self.script.StartCoroutine(self:ApplyUIIcon())
end

function WeaponSelection:ApplyUIIcon()
	return function()
		coroutine.yield(WaitForSeconds(0.1))
		if (self.weaponEntry) then
			local image = self.gameObject.GetComponent(Image)
			image.sprite = self.weaponEntry.uiSprite
		end
	end
end

function WeaponSelection:OnSelect()
	-- When this weapon entry is selected
	if (self.mainMenuScript and self.weaponEntry) then
		self.mainMenuScript:OnWeaponSelected(self.weaponEntry)
	end

	-- Close the menu
	if (self.weaponMenuScript) then
		self.weaponMenuScript:CloseMenu()
	end
end
