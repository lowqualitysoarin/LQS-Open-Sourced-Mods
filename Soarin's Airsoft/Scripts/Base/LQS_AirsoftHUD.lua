-- low_quality_soarin © 2023-2024
behaviour("LQS_AirsoftHUD")

function LQS_AirsoftHUD:Awake()
	-- Listeners
	-- But for the HUD
	self.airsoftHUDMethods = {
		{"onDeployButtonPressed", {}}
	}
end

function LQS_AirsoftHUD:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- HUD
	-- Indicators
	self.hitVignette = self.targets.hitVignette.GetComponent(Image)
	self.indicatorText = self.targets.indicatorText.GetComponent(Text)
	self.returnText = self.targets.returnText.GetComponent(Text)

	self.wayPointMarker = self.targets.wayPointMarker.GetComponent(Image)
	self.wayPointDistanceText = self.targets.wayPointDistanceText.GetComponent(Text)

	self.hitText = self.targets.hitText.GetComponent(Text)

	-- Elements
	self.progressBar = self.targets.progressBar.GetComponent(Image)
	self.progressBarText = self.targets.progressBarText.GetComponent(Text)

	-- Overlays
	-- Win overlay
	self.winOverlay = self.targets.winOverlay.GetComponent(Animator)
	self.winOverlayPlayerText = self.targets.winOverlayPlayerText.GetComponent(Text)

	-- Perma hit overlay
	self.permaHitOverlay = self.targets.permaHitOverlay.GetComponent(Animator)
	self.permaHitLabel = self.targets.permaHitLabel.GetComponent(Text)
	self.permaHitAudio = self.targets.permaHitAudio.GetComponent(AudioSource)

	-- Game Loadout
	self.airsoftDeployButton = self.targets.airsoftDeployButton.GetComponent(Button)
	self.airsoftDeployLabel = self.targets.airsoftDeployLabel.GetComponent(Text)

	-- Subtitles
	-- Format: {"Dialog", {AudioClip, AudioSource, VolumeScale}, LineDuration}
	self.subtitlesText = self.targets.subtitlesText.GetComponent(Text)
	self.subtitlesAudioSource = self.targets.subtitlesAudioSource.GetComponent(AudioSource)

	-- Events
	self.airsoftDeployButton.onClick.AddListener(self, "OnPressDeployButton")

	-- Finalize
	-- Disable some elements
	self.hitVignette.CrossFadeAlpha(0, 0, true)
	self.indicatorText.CrossFadeAlpha(0, 0, true)
	self.returnText.CrossFadeAlpha(0, 0, true)

	self.wayPointMarker.CrossFadeAlpha(0, 0, true)
	self.wayPointDistanceText.CrossFadeAlpha(0, 0, true)

	self.hitText.CrossFadeAlpha(0, 0, true)

	self.progressBar.CrossFadeAlpha(0, 0, true)
	self.progressBarText.CrossFadeAlpha(0, 0, true)

	self.airsoftDeployButton.gameObject.SetActive(false)
	self.permaHitOverlay.gameObject.SetActive(false)

	self.subtitlesText.CrossFadeAlpha(0, 0, true)

	-- Vars
	self.rfItemPanels = {}

	self.rfDeployButton = nil
	self.rfIngameUI = nil

	self.targetTeamColor = nil

	self.currentSubtitleAudioSource = nil

	self.waypointHandlerActive = false
	self.stopWaypointHandler = false

	self.hasSubtitleSequencePlaying = false
	self.stopSubtitleSequence = false

	-- Share singleton
	_G.LQSSoarinsAirsoftHUDBase = self.gameObject.GetComponent(ScriptedBehaviour)

	-- Finish setup
	self.script.StartCoroutine(self:FinalizeSetup())
end

function LQS_AirsoftHUD:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0))

		-- Get some rf's loadout elements and stuff
		-- I'm doing this soo I can disable the deploy button lol
		local loadoutParent = GameObject.Find("Screen Fitter").transform.GetChild(1).GetChild(0).GetChild(0)
		if (loadoutParent) then
			-- RF deloy button
			self.rfDeployButton = loadoutParent.GetChild(1).gameObject

			-- Parent airsoft deploy button to the loadoutParent
			local deployButtonParent = self.airsoftDeployButton.transform.parent.transform
			deployButtonParent.parent = loadoutParent
			deployButtonParent.position = self.rfDeployButton.transform.position
		end

		-- Get the Airsoft Base script
	    local airsoftBase = _G.LQSSoarinsAirsoftBase
		if (airsoftBase) then
			-- Set airsoftBase script
			self.airsoftBase = airsoftBase.self

			-- Pass this script to the base
			self.airsoftBase.airsoftHUDBase = _G.LQSSoarinsAirsoftHUDBase.self
		end

		-- Get the leaderboard script
		local leaderboardBase = _G.LQSSoarinsAirsoftLeaderboard
		if (leaderboardBase) then
			-- Apply the scripts
			self.leaderboardBase = leaderboardBase.self
			self.leaderboardBase.airsoftHUDBase = _G.LQSSoarinsAirsoftHUDBase.self
			self.leaderboardBase.airsoftBase = self.airsoftBase

			-- Apply the chosen gamemode name to the gamemodeTitle
			self.leaderboardBase.leaderboardGamemodeTitle.text = self.airsoftBase.chosenGamemode[4]
		end

		-- Get rf's player hud elements, this will be used later
	    local rfIngameUI = GameObject.Find("New Ingame UI").transform
		if (rfIngameUI) then
			-- Save Ingame UI transform
			self.rfIngameUI = rfIngameUI

			-- Pack all the weapon Item Panel (goddamn it, I thought Steel is using a overlay image to do selection indicator thing)
			local itemPanelHolder = self.rfIngameUI.GetChild(0).GetChild(0).GetChild(0)
			for i = 1, 5 do
				self.rfItemPanels[#self.rfItemPanels+1] = itemPanelHolder.GetChild(i-1).gameObject.GetComponent(RawImage)
			end
		end
	end
end

function LQS_AirsoftHUD:ChangeHUDTeamColor(colorRGB)
	-- Gets rf's default HUD colors and recolors them on the given hex code, only works if the player is present in the game
	-- Get clamped color, since rf hates using complete rgb codes
	local clampedColor = self:ColorClamp01(colorRGB)

	-- Recolor player health bar
	local playerHealthBar = self.rfIngameUI.GetChild(2).GetChild(2).GetChild(0).GetChild(0).gameObject.GetComponent(RawImage)
	playerHealthBar.color = clampedColor

	-- Recolor weapon selection, this will just call a value monitor to recolor them
	self.targetTeamColor = clampedColor
	self.script.AddValueMonitor("MonitorPlayerActiveWeapon", "RecolorWeaponSelection")
end

function LQS_AirsoftHUD:MonitorPlayerActiveWeapon()
	-- A value monitor for the player's active weapon
	return Player.actor.activeWeapon
end

function LQS_AirsoftHUD:RecolorWeaponSelection(newWeapon)
	-- If the player changes their weapon then recolor the selected panel
	if (not newWeapon) then return end
	self.rfItemPanels[newWeapon.slot+1].color = self.targetTeamColor
end

function LQS_AirsoftHUD:ColorClamp01(color)
	-- Applies the color on the base image, for some reason it hates rgb code floats which are over 1
	local output = Color(color.r / 255, color.g / 255, color.b / 255, 130 / 255)
	return output
end

function LQS_AirsoftHUD:StartSequenceDataContainer(dataContainer, randomSequence)
	-- Converts a data container into a sequence and then playing it
	if (not dataContainer) then return end

	-- Convert data container to sequence
	local convertedData = self:DataContainerToSequence(dataContainer)

	-- Get the target sequence
	local sequenceArray = convertedData
	if (randomSequence) then
		sequenceArray = {convertedData[math.random(#convertedData)]}
	end

	-- Start sequence
	self:StartSubtitleSequence(sequenceArray)
end

function LQS_AirsoftHUD:DataContainerToSequence(dataContainer)
	-- Coverts the given data container into a sequence
	-- Get the datas of the data container
	local dialogArray = dataContainer.GetStringArray("dialogString")
	local dialogClipArray = dataContainer.GetAudioClipArray("dialogClip")
	local dialogAudioSourceArray = dataContainer.GetGameObjectArray("dialogAudioSource")
	local dialogVolumeScale = dataContainer.GetFloatArray("dialogVolumeScale")
	local dialogLineDuration = dataContainer.GetFloatArray("dialogLineDuration")

	-- Pack them into one sequence
	local packedSequence = {}
	for i = 1, #dialogArray do
		-- Pack sequenceData
		local sequenceData = {
			dialogArray[i],
			{dialogClipArray[i], dialogAudioSourceArray[i], dialogVolumeScale[i]},
			dialogLineDuration[i]
		}

		-- Add to packedSequence array
		packedSequence[#packedSequence+1] = sequenceData
	end
	return packedSequence
end

function LQS_AirsoftHUD:StartSubtitleSequence(sequenceArray)
	-- This starts the subtitles handler coroutine and follows the sequence array
	if (not sequenceArray) then return end
	self.script.StartCoroutine(self:SubtitlesHandler(sequenceArray))
end

function LQS_AirsoftHUD:SubtitlesHandler(sequenceArray)
	return function()
		-- The subtitle handler coroutine
		self.hasSubtitleSequencePlaying = true

		-- Fade in subtitle text
		self.subtitlesText.CrossFadeAlpha(1, 1.5, false)

		-- Sequencer main
		local sequenceTimer = 0
		for _,sequence in pairs(sequenceArray) do
			-- Apply dialog text
			self.subtitlesText.text = sequence[1]

			-- Play dialog sound (if possible)
			if (sequence[2][1]) then
				-- Get the audio source
				local targetAudSrc = self.subtitlesAudioSource
				if (sequence[2][2]) then
					targetAudSrc = sequence[2][2]
				end

				-- Get the target volumeScale
				local targetVolumeScale = 1
				if (sequence[2][3]) then
					targetVolumeScale = sequence[2][3]
				end

				-- Play dialog
				targetAudSrc.PlayOneShot(sequence[2][1], targetVolumeScale)
				self.currentSubtitleAudioSource = targetAudSrc
			end

			-- Start the dialog timer
			sequenceTimer = sequence[3]
			while (sequenceTimer > 0) do
				-- Stop the subtitle sequence if told to stop
				if (self.stopSubtitleSequence) then
					self.stopSubtitleSequence = false
					return
				end

				sequenceTimer = sequenceTimer - 1 * Time.deltaTime
				coroutine.yield(WaitForSeconds(0))
			end
		end

		-- Finish
		self.hasSubtitleSequencePlaying = false
		self.subtitlesText.CrossFadeAlpha(0, 1.5, false)
	end
end

function LQS_AirsoftHUD:StopSubtitleSequence()
	-- Stops the current subtitle sequence
	if (not self.hasSubtitleSequencePlaying) then return end
	self.stopSubtitleSequence = true

	if (self.currentSubtitleAudioSource) then
		self.currentSubtitleAudioSource.Stop()
	end

	self.subtitlesText.CrossFadeAlpha(0, 0, true)
	self.hasSubtitleSequencePlaying = false
end

function LQS_AirsoftHUD:OnPressDeployButton()
	-- Call onDeployButtonPressed event
	self:TriggerListener("onDeployButtonPressed", nil)
end

function LQS_AirsoftHUD:ToggleAirsoftDeployButton(active)
	-- This toggle's the airsoft's deploy button
	-- The button doesn't do anything, soo you'll need to use the listener in order to make it do stuff
	self.airsoftDeployButton.gameObject.SetActive(active)
end

function LQS_AirsoftHUD:ToggleRFDeployButton(active)
	-- This toggles ravenfield's deploy button (why not? and other gamemodes needs it anyways)
	-- Have to do a nil check just incase if it fails, also istg this is gonna break
	if (self.rfDeployButton) then
		self.rfDeployButton.SetActive(active)
	end
end

function LQS_AirsoftHUD:UpdateProgressBar(value, refValue)
	-- Simply updates the progress bar
	self.progressBar.fillAmount = value / refValue
end

function LQS_AirsoftHUD:ToggleProgressBar(enable)
	-- Toggles the progress bar, simple
	local targetAlpha = 0
	if (enable) then
		targetAlpha = 1
	end
	self.progressBar.CrossFadeAlpha(targetAlpha, 1.5, false)
	self.progressBarText.CrossFadeAlpha(targetAlpha, 1.5, false)
end

function LQS_AirsoftHUD:TriggerWinOverlay(actor, useTeam)
	-- Triggers the win overlay
	if (not actor) then return end
	
	-- Error patch
	local targetName = "Unknown"
	if (actor) then
		targetName = actor.name
	end

	-- Apply the winner actor's name to the winner label
	local targetTeam = self.airsoftBase:GetFactionData(actor.team)

	self.winOverlayPlayerText.text = "<color=" .. targetTeam[3] .. ">" .. targetName .. "</color>"
	if (useTeam) then
		-- If useTeam is true then use the team name
		self.winOverlayPlayerText.text = targetTeam[4]
	end

	-- Play the win overlay anim
	self.winOverlay.SetTrigger("playwinanim")
end

function LQS_AirsoftHUD:TriggerPermaHitOverlay(deathText, deathAudio)
	-- Error patch
	if (not deathText) then
		-- If there is no given death text then apply the default one
		local luck = Random.Range(0, 100)

		deathText = "It's Over"
		if (luck < 25) then
			deathText = "It's Joever"
		end
	end

	if (not deathAudio) then
		deathAudio = self.data.GetAudioClip("permaHitAudioDefault")
	end

	-- Apply the death text and audio
	self.permaHitLabel.text = string.upper(deathText)
	self.permaHitAudio.clip = deathAudio

	-- Interrupt subtitle sequence
	self:StopSubtitleSequence()

	-- Play the perma hit overlay
	self:TogglePermaHitOverlay(true)

	local luck = Random.Range(0, 100)
	if (luck < 15) then
		-- Play alt permahit screen
		self.permaHitAudio.clip = self.data.GetAudioClip("permaHitAudioSecret")
		self.permaHitOverlay.SetTrigger("playalt")
	else
		-- Play orginal
		self.permaHitOverlay.SetTrigger("play")
	end
end

function LQS_AirsoftHUD:TogglePermaHitOverlay(active)
	self.permaHitOverlay.gameObject.SetActive(active)
end

function LQS_AirsoftHUD:TriggerHitIndicator(actor, kill)
	-- Triggers the hit text
	if (not actor) then return end

	local targetText = "Hitted by "
	if (kill) then
		targetText = "Hit "
	end

	local targetTeamColor = self.airsoftBase:GetFactionData(actor.team)[3]
	local text = targetText .. "<color=" .. targetTeamColor .. ">" .. actor.name .. "</color>"

	self.script.StartCoroutine(self:StartHitText(text))
end

function LQS_AirsoftHUD:StartHitText(text)
	return function()
		-- A player for the hit text
		self.hitText.text = text
		self.hitText.CrossFadeAlpha(1, 0.2, false)

		local fadeOutTime = 3
		while (fadeOutTime > 0) do
			fadeOutTime = fadeOutTime - 1 * Time.deltaTime
			coroutine.yield(WaitForSeconds(0))
		end

		self.hitText.CrossFadeAlpha(0, 0.2, false)
	end
end

function LQS_AirsoftHUD:ToggleHitVignette(enable)
	-- Toggles the hit vignette
	local targetAlpha = 0
	if (enable) then
		targetAlpha = 1
	end
	self.hitVignette.CrossFadeAlpha(targetAlpha, 1, false)
end

function LQS_AirsoftHUD:TriggerWaypointMarker(actor, position)
	-- Triggers the waypoint marker
	if (not actor or not position) then return end
	self.script.StartCoroutine(self:WaypointMarkerHandler(actor, position))
end

function LQS_AirsoftHUD:WaypointMarkerHandler(actor, position)
	return function()
		-- Handles the waypoint marker
		-- Do a anti-overlap check
		if (self.waypointHandlerActive) then return end
		self.waypointHandlerActive = true

		-- Activate waypoint marker
		self.wayPointMarker.CrossFadeAlpha(1, 1.5, false)
		self.wayPointDistanceText.CrossFadeAlpha(1, 1.5, false)

		-- Start handling the waypoint marker
		while (not self.stopWaypointHandler) do
			-- Start handling waypoint
			-- Handle waypoint marker img
			local minX = self.wayPointMarker.GetPixelAdjustedRect().width / 2
			local maxX = Screen.width - minX

			local minY = self.wayPointMarker.GetPixelAdjustedRect().height / 2
			local maxY = Screen.height - minY

			local markerPos = PlayerCamera.activeCamera.WorldToScreenPoint(position)

			local playerFpCam = PlayerCamera.fpCamera.transform
			if (Vector3.Dot((position - playerFpCam.position), playerFpCam.forward) < 0) then
				if (markerPos.x < Screen.width / 2) then
					markerPos.x = maxX
				else
					markerPos.x = minX
				end
			end

			markerPos.x = Mathf.Clamp(markerPos.x, minX, maxX)
			markerPos.y = Mathf.Clamp(markerPos.y, minY, maxY)

			self.wayPointMarker.transform.position = markerPos

			-- Handle waypoint marker distance
			local distanceText = tostring(math.floor(Vector3.Distance(position, actor.transform.position))) .. "m"
			self.wayPointDistanceText.text = distanceText

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Reset stuff when done
		self.stopWaypointHandler = false
		self.waypointHandlerActive = false

		self.wayPointMarker.CrossFadeAlpha(0, 1.5, false)
		self.wayPointDistanceText.CrossFadeAlpha(0, 1.5, false)
	end
end

function LQS_AirsoftHUD:StopWaypointHandler()
	-- Stops the waypoint handler
	if (not self.waypointHandlerActive) then return end
	self.stopWaypointHandler = true
end

function LQS_AirsoftHUD:ToggleCountdownTimer(enable)
	-- Toggles the coundown timer
	local targetAlpha = 0
	if (enable) then
		targetAlpha = 1
	end
	self.returnText.CrossFadeAlpha(targetAlpha, 1.5, false)
end

function LQS_AirsoftHUD:UpdateCountdownTimer(countdownTextFirst, countdownTextSecond, time)
	-- Simply just updates the countdown timer
	self.returnText.text = countdownTextFirst .. tostring(math.floor(time)) .. countdownTextSecond
end

function LQS_AirsoftHUD:TriggerIndicatorText(text, duration)
	-- Trigger the indicator text
	-- Fatal errors fix
	if (not text) then
		text = "ERROR"
	end

	if (not duration) then
		duration = 5
	end

	-- Play indicator text
	self.script.StartCoroutine(self:PlayIndicatorText(text, duration))
end

function LQS_AirsoftHUD:PlayIndicatorText(text, duration)
	return function()
		-- A player for the indicator text
		self.indicatorText.text = text
		self.indicatorText.CrossFadeAlpha(1, 1.5, false)

		local fadeOutTime = duration
		while (fadeOutTime > 0) do
			fadeOutTime = fadeOutTime - 1 * Time.deltaTime
			coroutine.yield(WaitForSeconds(0))
		end

		self.indicatorText.CrossFadeAlpha(0, 1.5, false)
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftHUD:TriggerListener(type, arguments)
	if (not type) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftHUDMethods[targetMethodIndex]) then
		for _,func in pairs(self.airsoftHUDMethods[targetMethodIndex][2]) do
			func(arguments)
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftHUD:ManageListeners(remove, type, owner, func)
	if (not type or not owner or not func) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftHUDMethods[targetMethodIndex]) then
		if (not remove) then
			self.airsoftHUDMethods[targetMethodIndex][2][owner] = func
		else
			self.airsoftHUDMethods[targetMethodIndex][2][owner] = nil
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftHUD:GetTargetMethod(type)
	local targetMethodIndex = nil
	for index,method in pairs(self.airsoftHUDMethods) do
		if (method[1] == type) then
			targetMethodIndex = index
		end
	end
	return targetMethodIndex
end
