behaviour("HUDBase")

function HUDBase:Start()
	-- Base
	self.mainScript = self.targets.mainScript.GetComponent(ScriptedBehaviour).self
	self.canvas = self.targets.canvas

	-- HUD Elements
	self.blackFade = self.targets.blackFade.GetComponent(Image)

	-- Essentials
	self.triggeredFade = false

	-- Finalize
	-- Set blackFade alpha to zero
	self.blackFade.CrossFadeAlpha(0, 0, true)

	-- Disable Default HUD
	self.script.StartCoroutine(self:DisableDefaultHUD())
end

function HUDBase:DisableDefaultHUD()
	-- Literally disables the Ravenfield HUD Elements
	-- I'm doing it on a coroutine because errors spew out when launch immediately.
	return function()
		coroutine.yield(WaitForSeconds(0.15))
		-- Disable Base Game HUD
		if (GameManager.buildNumber < 27) then
			-- EA 26 and below
		    GameObject.Find("Ingame UI Container(Clone)").Find("Ingame UI/Panel").gameObject.GetComponent(Image).color = Color(0,0,0,0)
		    GameObject.Find("Current Ammo Text").gameObject.SetActive(false)
	        GameObject.Find("Spare Ammo Text").gameObject.SetActive(false)
	        GameObject.Find("Vehicle Health Background").gameObject.SetActive(false)
	        GameObject.Find("Resupply Health").gameObject.SetActive(false)
	        GameObject.Find("Resupply Ammo").gameObject.SetActive(false)
	        GameObject.Find("Squad Text").gameObject.GetComponent(Text).color = Color(0,0,0,0)
	        GameObject.Find("Sight Text").gameObject.SetActive(false)
	        GameObject.Find("Weapon Image").gameObject.SetActive(false)
	        GameObject.Find("Health Text").gameObject.transform.parent.gameObject.SetActive(false)
		else
			-- EA 27
			-- Got this snippet of code from RadioactiveJellyfish's hud mutator
			PlayerHud.HideUIElement(UIElement.PlayerHealth)
			PlayerHud.HideUIElement(UIElement.VehicleInfo)
			PlayerHud.HideUIElement(UIElement.VehicleRepairInfo)
			PlayerHud.HideUIElement(UIElement.SquadOrderLabel)
			PlayerHud.HideUIElement(UIElement.SquadMemberInfo)
			PlayerHud.HideUIElement(UIElement.WeaponInfo)
		end

		-- Disable Gamemode HUD
		PlayerHud.hudGameModeEnabled = false
	end
end

function HUDBase:Update()
	-- Main

	-- Features
	-- I want to be a little organized lmao
	if (self.mainScript) then
		self:HUDFeatures()
	end
end

function HUDBase:HUDFeatures()
	-- HUD Features
	-- This handles the HUD features.

	-- Player
	local player = Player.actor

	if (player) then
	    -- If the player is dead then trigger the blackFade
		if (player.isDead and self.mainScript.gameAwakened and not self.triggeredFade) then
			self:BlackScreenFade(false)
			self.triggeredFade = true
		else
			self.triggeredFade = false
		end
	end
end

function HUDBase:BlackScreenFade(fadeOut)
	-- Handles the fade
	if (fadeOut) then
		self.blackFade.CrossFadeAlpha(0, 1, false)
	else
		self.blackFade.CrossFadeAlpha(1, 1, false)
	end
end
