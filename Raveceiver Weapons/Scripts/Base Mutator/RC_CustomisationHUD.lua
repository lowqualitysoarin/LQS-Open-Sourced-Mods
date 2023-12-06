behaviour("RC_CustomisationHUD")

function RC_CustomisationHUD:Awake()
	-- Awake Vars
	self.isUsed = false
end

function RC_CustomisationHUD:Start()
	-- Base
	self.rcBase = self.targets.rcBase.GetComponent(ScriptedBehaviour).self

	-- Vars
	self.weaponName = self.targets.weaponName.GetComponent(Text)
	self.controlsText = self.targets.controlsText.GetComponent(Text)
	self.ambientMusic = self.targets.ambientMusic.GetComponent(AudioSource)

	self.uiBG = self.targets.uiBG

	-- Finalize
	self:StartSetup()
end

function RC_CustomisationHUD:StartSetup()
	-- The first setup
	-- Controls Text Setup
	self.controlsText.text = 
	"Close customisation: push [<color=orange>" .. 
	string.upper(self.rcBase.customisationKey) .. 
	"</color>] \nUnlock Weapon: push [<color=orange>" .. 
	string.upper(self.rcBase.freeManipulateKey) .. 
	"</color>] \nHide/Unhide dropdowns: push [<color=orange>H</color>] \n \nOrbit: hold [<color=orange>RMB</color>] \nZoom: scroll [<color=orange>MMB</color>]"

	-- Mute ambient music
	self.ambientMusic.volume = 0

	-- Disable the uiBG
	self.uiBG.SetActive(false)

	-- Tick isUsed to true
	self.isUsed = true
end

function RC_CustomisationHUD:OnEnable()
	self:ToggleHUD(true)
end

function RC_CustomisationHUD:OnDisable()
	self:ToggleHUD()
end

function RC_CustomisationHUD:ToggleHUD(active)
	-- Toggles the HUD
	if (not self.isUsed) then return end

	-- Convert nil to false
	if (active == nil) then
		active = false
	end

	-- Main
	-- Background UI
	self.uiBG.SetActive(active)

	-- Ambient music
	self.script.StartCoroutine(self:MusicFade(active))

	-- Name setup
	-- Only when active.
	local infoData = nil

	if (active) then
		if (self.rcBase.rcScript) then
			infoData = self.rcBase.rcScript.infoContainer
		end

		if (infoData and infoData.HasString("weaponName")) then
			self.weaponName.text = string.upper(infoData.GetString("weaponName"))
		else
			self.weaponName.text = string.upper("None Provided")
		end
	end
end

function RC_CustomisationHUD:MusicFade(active)
	-- A coroutine that toggles the music
	return function()
		if (active) then
			-- Fade in music
			self.ambientMusic.Play()
			self.ambientMusic.volume = 0

			coroutine.yield(WaitForSeconds(0))

			while (self.ambientMusic.volume < 1) do
				self.ambientMusic.volume = Mathf.Lerp(self.ambientMusic.volume, 0.1, 1.5 * Time.unscaledDeltaTime)
				coroutine.yield(WaitForSeconds(0))
			end
		else
			-- Stop the music
			self.ambientMusic.Stop()
		end
	end
end