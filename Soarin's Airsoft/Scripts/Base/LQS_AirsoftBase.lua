-- low_quality_soarin © 2023-2024
behaviour("LQS_AirsoftBase")

function LQS_AirsoftBase:Awake()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Projectiles
	self.airsoftProjAutoRifle = self.data.GetGameObject("airsoftProjAutoRifle")
	self.airsoftProjSemiAutoRifle = self.data.GetGameObject("airsoftProjSemiAutoRifle")
	self.airsoftProjHandgun = self.data.GetGameObject("airsoftProjHandgun")
	self.airsoftProjShotgun = self.data.GetGameObject("airsoftProjShotgun")
	self.airsoftProjSniper = self.data.GetGameObject("airsoftProjSniper")
	self.airsoftProjGrenadeLauncher = self.data.GetGameObject("airsoftProjGrenadeLauncher")
	self.airsoftProjRocketLauncher = self.data.GetGameObject("airsoftProjRocketLauncher")

	-- Sounds
	self.semiAutoRifleSounds = self.targets.semiAutoRifleSounds.GetComponent(DataContainer).GetAudioClipArray("firingSound")
	self.handgunSounds = self.targets.handgunSounds.GetComponent(DataContainer).GetAudioClipArray("firingSound")
	self.shotgunSounds = self.targets.shotgunSounds.GetComponent(DataContainer).GetAudioClipArray("firingSound")
	self.sniperSounds = self.targets.sniperSounds.GetComponent(DataContainer).GetAudioClipArray("firingSound")

	-- Weapon Role Array
	-- Format: {WeaponRole, Projectile, FiringSounds, AmmoMultiplier, SpareAmmoMultiplier, EffectiveRange}
	self.airsoftWeaponRoles = {
		{WeaponRole.AutoRifle, self.airsoftProjAutoRifle, self.semiAutoRifleSounds, 3, 3, 80},
		{WeaponRole.SemiAutoRifle, self.airsoftProjSemiAutoRifle, self.semiAutoRifleSounds, 2, 3, 90},
		{WeaponRole.Handgun, self.airsoftProjHandgun, self.handgunSounds, 2, 2, 60},
		{WeaponRole.Shotgun, self.airsoftProjShotgun, self.shotgunSounds, 2, 2, 50},
		{WeaponRole.Sniper, self.airsoftProjSniper, self.sniperSounds, 2, 2, 100},
		{WeaponRole.GrenadeLauncher, self.airsoftProjGrenadeLauncher, nil, 0, 0, 150},
		{WeaponRole.RocketLauncher, self.airsoftProjRocketLauncher, nil, 0, 0, 150},
	}

	-- Factions System
	-- Doesn't add a new faction or whatever, it just treats one team as a different faction
	local factionSkins = self.targets.factionSkins.GetComponent(DataContainer)
	local factionFlags = self.targets.factionFlags.GetComponent(DataContainer)

	-- Format: {FactionID, TeamColor(Color), TeamColor(Hex), TeamName, TeamSkins, FlagMaterial}
	self.factionsData = {
		{"Spectator", Color(255, 255, 255), "#ffffff", "Spectator", nil, nil},
		{"ArmyEagles", Color(0, 53, 255), "#0035ff", "<color=blue>Eagles</color>", factionSkins.GetActorSkin("saEagles"), factionFlags.GetMaterial("saEagles")},
		{"ArmyRavens", Color(255, 0, 0), "#ff0000", "<color=red>Ravens</color>", factionSkins.GetActorSkin("saRavens"), factionFlags.GetMaterial("saRavens")},
		{"SecFalcons", Color(0, 145, 24), "#009118", "<color=green>Falcons</color>", factionSkins.GetActorSkin("saFalcons"), factionFlags.GetMaterial("saFalcons")},
		{"InsMagpies", Color(255, 203, 0), "#ffcb00", "<color=yellow>Magpies</color>", factionSkins.GetActorSkin("saMagpies"), factionFlags.GetMaterial("saMagpies")},
		{"PMCPurpleMercs", Color(163, 39, 240), "#a327f0", "<color=purple>Purple Mercenaries</color>", factionSkins.GetActorSkin("saPurpleMercs"), factionFlags.GetMaterial("saPurpleMercs")}
	}

	self.eagleFaction = self.factionsData[2][1]
	self.ravenFaction = self.factionsData[3][1]

	-- Gamemodes
	-- This is gonna be painful
	-- Format: {GamemodeID, GamemodeObject, {EagleFaction, RavenFaction}, GamemodeName}
	local airsoftGamemodesContainer = self.targets.airsoftGamemodes.GetComponent(DataContainer)
	self.airsoftGamemodes = {
		{"Standard", nil, {"ArmyEagles", "ArmyRavens"}, "Standard"},
		{"GunGame", airsoftGamemodesContainer.GetGameObject("airsoftGunGame"), {"SecFalcons", "InsMagpies"}, "<color=orange>Gun Game</color>"},
		{"Raid", airsoftGamemodesContainer.GetGameObject("airsoftRaid"), {"ArmyEagles", "PMCPurpleMercs"}, "<color=purple>Raid</color>"},
		{"CTF", airsoftGamemodesContainer.GetGameObject("airsoftCTF"), {"SecFalcons", "InsMagpies"}, "<color=blue>Capture The Flag</color>"}
	}

	self.chosenGamemode = self.airsoftGamemodes[1]

	-- Listeners
	-- A array of listeners of this base
	-- Format: {EventID, Listener Array}
	self.airsoftBaseMethods = {
		{"onActorHit", {}},
	    {"onActorRecover", {}},
		{"onMatchEnd", {}}
	}

	-- Map restarter
	-- Some gamemodes needed this
	local mapRestarter = GameObject.Instantiate(self.targets.mapRestarter)
	self.mapRestartSignal = mapRestarter.GetComponent(TriggerScriptedSignal)
end

function LQS_AirsoftBase:Start()
	-- Configuration
	self.quickTravelKey = self:CheckKeyCode(string.lower(self.script.mutator.GetConfigurationString("quickTravelKey")))
	self.respawnTime = self.script.mutator.GetConfigurationInt("respawnTime")

	-- Vars
	self.disabledActors = {}
	self.blacklistedActors = {}

	self.actorOccluder = self.targets.actorOccluder

	self.airsoftHUDBase = nil
	self.alreadyTriggeredIndicatorText = false
	self.matchFinished = false

	self.disableHitActorManager = false
	self.playerAlreadySpawned = false

	-- Events
	GameEvents.onActorSpawn.AddListener(self, "OnActorSpawn")
	GameEvents.onCapturePointCaptured.AddListener(self, "OnPointCaptured")
	GameEvents.onCapturePointNeutralized.AddListener(self, "OnPointNeutralized")

	-- Setup Gamemode
	-- Always call before doing a final setup
	self:SetupGamemode(self.script.mutator.GetConfigurationDropdown("gamemode"))

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())

	-- Make a singleton
	_G.LQSSoarinsAirsoftBase = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_AirsoftBase:EndMatch(actor, useTeam)
	-- Ends the match, shows the winner, and restarts the map after a couple of seconds
	-- Play the win overlay
	self.airsoftHUDBase:TriggerWinOverlay(actor, useTeam)

	-- Call onMatchEnd event and tick matchFinish bool
	self:TriggerListener("onMatchEnd", {actor})
	self.matchFinish = true

	-- Restart map
	self.script.StartCoroutine(self:RestartMap())
end

function LQS_AirsoftBase:RestartMap(skip)
	return function()
		-- Literally just restarts the map, can be called without calling EndMatch() first
		-- The timer (literally)
		local time = 20
		local alreadyToggledCountdownTimer = false
		while (time > 0 and not skip) do
			-- Subtract time
			time = time - 1 * Time.deltaTime

			-- If the timer reaches 5 seconds start notifying that the map will restart in 5 seconds
			if (time > 0 and time < 6) then
				if (not alreadyToggledCountdownTimer) then
					self.airsoftHUDBase:ToggleCountdownTimer(true)
					alreadyToggledCountdownTimer = true
				end
				self.airsoftHUDBase:UpdateCountdownTimer("The map is restarting in... \n <color=yellow>", "</color>", time)
			end

			-- Udpate
			coroutine.yield(WaitForSeconds(0))
		end

		-- Restart the map
		self.airsoftHUDBase:ToggleCountdownTimer(false)
		self.mapRestartSignal.Send("RestartMap", SignalContext())
	end
end

function LQS_AirsoftBase:SetupGamemode(int)
	-- Sets up the gamemode
	-- Get the chosen gamemode
	self.chosenGamemode = self.airsoftGamemodes[int+1]
	
	-- Activate gamemode
	if (self.chosenGamemode[2]) then
		self.chosenGamemode[2].SetActive(true)
	end

	-- Apply teams
	self.eagleFaction = self.chosenGamemode[3][1]
	self.ravenFaction = self.chosenGamemode[3][2]
end

function LQS_AirsoftBase:CheckKeyCode(givenBind)
	-- From my bodycam mod
	-- Basically converts it to a keycode when its a unique one
	local uniqueBinds = {
		{"leftalt", KeyCode.LeftAlt},
		{"rightalt", KeyCode.RightAlt},
		{"leftbracket", KeyCode.LeftBracket},
		{"rightbracket", KeyCode.RightBracket},
		{"capslock", KeyCode.CapsLock},
		{"tab", KeyCode.Tab},
		{"rightshift", KeyCode.RightShift},
		{"leftshift", KeyCode.LeftShift},
		{"pageup", KeyCode.PageUp},
		{"pagedown", KeyCode.PageDown},
		{"delete", KeyCode.Delete},
		{"backspace", KeyCode.Backspace},
		{"space", KeyCode.Space},
		{"clear", KeyCode.Clear},
		{"uparrow", KeyCode.UpArrow},
		{"downarrow", KeyCode.DownArrow},
		{"rightarrow", KeyCode.RightArrow},
		{"leftarrow", KeyCode.LeftArrow},
		{"insert", KeyCode.Insert},
		{"home", KeyCode.Home},
		{"end", KeyCode.End},
		{"f1", KeyCode.F1},
		{"f2", KeyCode.F2},
		{"f3", KeyCode.F3},
		{"f4", KeyCode.F4},
		{"f5", KeyCode.F5},
		{"f6", KeyCode.F6},
		{"f7", KeyCode.F7},
		{"f8", KeyCode.F8},
		{"f9", KeyCode.F9},
		{"f10", KeyCode.F10},
		{"f11", KeyCode.F11},
		{"f12", KeyCode.F12},
		{"f13", KeyCode.F13},
		{"f14", KeyCode.F14},
		{"f15", KeyCode.F15},
		{"mouse0", KeyCode.Mouse0},
		{"mouse1", KeyCode.Mouse1},
		{"mouse2", KeyCode.Mouse2},
		{"mouse3", KeyCode.Mouse3},
		{"mouse4", KeyCode.Mouse4},
		{"mouse5", KeyCode.Mouse5},
		{"mouse6", KeyCode.Mouse6},
		{"none", KeyCode.None}
	}

	for index,bind in pairs(uniqueBinds) do
		-- If the binds are the same then bind it to it
		if (givenBind == bind[1]) then
			return bind[2]
		end
	end
	return givenBind
end

function LQS_AirsoftBase:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0.01))

	    -- RF Vital Objects
	    -- _Managers game object
	    local _rfmanager = GameObject.Find("_Managers(Clone)")
	    if (_rfmanager) then
	    	-- Disable Reverb Sounds
	    	-- Need to do this because the reverb sounds are more louder than the airsoft sounds
	    	local reflectionSoundSources = _rfmanager.transform.Find("Reflection Sound Sources")
	    	if (reflectionSoundSources) then
	    		for _,reverbSound in pairs(reflectionSoundSources.gameObject.GetComponentsInChildren(AudioSource)) do
	    			reverbSound.enabled = false
	    		end
	    	end
	    end
    
	    -- Some stuff to do on all actors
		for _,actor in pairs(ActorManager.actors) do
			self.script.StartCoroutine(self:AddActorSupport(actor))
		end

		-- Setup Flags
		-- May not work on some custom maps
		for _,cp in pairs(ActorManager.capturePoints) do
			self:UpdateFactionFlag(cp, cp.owner)
		end

		-- Recolor HUD team color
		local playerFactionData = self:GetFactionData(Player.actor.team)
		self.airsoftHUDBase:ChangeHUDTeamColor(playerFactionData[2])
	end
end

function LQS_AirsoftBase:AddActorSupport(actor)
	return function()
	    -- Adds a airsoft base support for the actor
		coroutine.yield(WaitForSeconds(0.05))

		-- Check if the given actor is blacklisted
		if (self:IsActorBlacklisted(actor)) then return end

	    -- Add this actor on the custom leaderboard
	    self.airsoftHUDBase.leaderboardBase:UpdateLeaderboard(actor)
    
	    -- Add onTakeDamage listener on the actor
	    actor.onTakeDamage.AddListener(self, "OnActorHit")
    
	    -- Apply team skin
	    -- The arms skin replace is 
	    local actorFactionData = self:GetFactionData(actor.team)
	    if (actorFactionData[5]) then
	    	-- Set skin
	    	actor.SetSkin(actorFactionData[5])
    
	    	-- Apply kickfoot skin
	    	if (actor.isPlayer) then
	    		local kickfootSkin = GameObject.Find("KickFoot").transform.GetChild(1).gameObject.GetComponent(SkinnedMeshRenderer)
	    		if (kickfootSkin) then
	    			kickfootSkin.sharedMaterials = actorFactionData[5].kickLegSkin.materials
	    			kickfootSkin.sharedMesh = actorFactionData[5].kickLegSkin.mesh
	    		end
	    	end
	    end
	end
end

function LQS_AirsoftBase:UpdateFactionFlag(point, targetOwner)
	-- This is used to update the faction flag on the given flag
	-- Get the renderer of the flag (if possible, because some flags in custom maps are different)
	local flagRenderer = point.flagRenderer
	if (not flagRenderer) then
		flagRenderer = point.gameObject.GetComponentInChildren(SkinnedMeshRenderer)
	end

	-- Get the faction data of the owner and apply the new material
	if (flagRenderer) then
		local ownerFactionData = self:GetFactionData(targetOwner)
	    flagRenderer.materials = {ownerFactionData[6]}
	end
end

function LQS_AirsoftBase:TriggerListener(type, arguments)
	-- Triggers the target listeners
	if (not type) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftBaseMethods[targetMethodIndex]) then
		for _,func in pairs(self.airsoftBaseMethods[targetMethodIndex][2]) do
			func(arguments)
		end
	end
end

function LQS_AirsoftBase:ManageListeners(remove, type, owner, func)
	-- Adds a listener on one of the base's methods
	if (not type or not owner or not func) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	-- Manage listeners
	if (targetMethodIndex and self.airsoftBaseMethods[targetMethodIndex]) then
		if (not remove) then
			-- Add listener
			self.airsoftBaseMethods[targetMethodIndex][2][owner] = func
		else
			-- Remove listener
			self.airsoftBaseMethods[targetMethodIndex][2][owner] = nil
		end
	end
end

function LQS_AirsoftBase:GetTargetMethod(type)
	-- Simply gets the target method index
	local targetMethodIndex = nil
	for index,method in pairs(self.airsoftBaseMethods) do
		if (method[1] == type) then
			targetMethodIndex = index
		end
	end
	return targetMethodIndex
end

function LQS_AirsoftBase:GetFactionData(team)
	-- Gets the faction data of the given actor's team
	local targetFaction = "Spectator"
	if (team == Team.Red) then
		targetFaction = self.ravenFaction
	elseif (team == Team.Blue) then
		targetFaction = self.eagleFaction
	end

	for _,factionData in pairs(self.factionsData) do
		if (targetFaction == factionData[1]) then
			return factionData
		end
	end
	return nil
end

function LQS_AirsoftBase:OnPointCaptured(point, newOwner)
	-- Update leaderboard captures
	local capturers = ActorManager.AliveActorsInRange(point.transform.position, point.captureRange)
	for _,actor in pairs(capturers) do
		if (actor.team == newOwner) then
			self:UpdateLeaderboard(actor, "UpdateCaptures;;Add")
		end
	end

	-- Update flag
	self:UpdateFactionFlag(point, newOwner)
end

function LQS_AirsoftBase:OnPointNeutralized(point, oldOwner)
	-- Update flag
	self:UpdateNeutralizedFlag(point, oldOwner)
end

function LQS_AirsoftBase:UpdateNeutralizedFlag(point, oldOwner)
	-- Similar way on how I did on the update leaderboard capture thing but only changes the team flag
	-- Get the new owner, by default its eagles
	local newOwner = Team.Blue
	if (oldOwner == Team.Blue) then
		-- If the old owner is eagles
		newOwner = Team.Red
	elseif (oldOwner == Team.Neutral) then
		-- If there is no old occupants of this point
		-- This gets the nearest actor and choose the team of that actor as the new owner
		local capturers = ActorManager.AliveActorsInRange(point.transform.position, point.captureRange)
		for _,actor in pairs(capturers) do
			newOwner = actor.team
			break
		end
	end

	-- Update the flag
	self:UpdateFactionFlag(point, newOwner)
end

function LQS_AirsoftBase:UpdateLeaderboard(actor, updateType)
	self.airsoftHUDBase.leaderboardBase:UpdateLeaderboard(actor, updateType)
end

function LQS_AirsoftBase:OnActorHit(actor, sourceActor, dmgInfo)
	-- No killing, its fucking airsoft. I still see some bots kill another bot with a melee
	actor.health = actor.maxHealth
	actor.balance = actor.maxBalance

	-- Check the damageInfo
	if (not self:CanBeHit(actor, dmgInfo)) then return end

	-- The actor calls a hit if they are hit
	self:ActorHit(actor, sourceActor)
end

function LQS_AirsoftBase:CanBeHit(actor, dmgInfo)
	-- Checks if the damage info type is plausible for a hit
	if (dmgInfo.type ~= DamageSourceType.FallDamage) then
		if (dmgInfo.type ~= DamageSourceType.Exception) then
			if (dmgInfo.type ~= DamageSourceType.Scripted) then
				if (dmgInfo.type ~= DamageSourceType.Unknown) then
					if (not self:IsActorBlacklisted(actor)) then
						return true
					end
				end
			end
		end
	end
	return false
end

function LQS_AirsoftBase:ActorHit(actor, sourceActor)
	-- Stuff to do when a actor is hit
	-- Toggle actor
	self:ToggleActor(actor, true, sourceActor)
end

function LQS_AirsoftBase:ToggleActor(actor, hit, sourceActor)
	-- Just like what mentioned above this method
	if (self:CheatingChance(actor) and hit) then return end

	-- Stuff to do if the actor/sourceActor is a player
	if (actor.isPlayer) then
		self:PlayerHit(sourceActor, hit)
	elseif (sourceActor and sourceActor.isPlayer) then
		if (not self:IsDisabledActor(actor)) then
			self:OnPlayerHitActor(actor)
		end
	end

	-- Stuff to do if the actor is hit
	if (hit) then
		if (not self:IsDisabledActor(actor)) then
			-- Update leaderboard kills
	    	-- Add death count to the victim
	    	self:UpdateLeaderboard(actor, "UpdateDeaths;;Add")
    
	    	-- Update killer leaderboard info, if its a teamkill then subtract the kill count
			-- if there is no killer then this will be ignored
			if (sourceActor) then
				local killReport = "UpdateKills;;Add"
				if (sourceActor.team == actor.team) then
					killReport = "UpdateKills;;Sub"
				end
				self:UpdateLeaderboard(sourceActor, killReport)
			end

			-- Call onActorHit event
			self:TriggerListener("onActorHit", {actor, sourceActor})
	    end
		
		-- Manage actor
		if (not self.disableHitActorManager) then
			self:ManageHitActor(actor, false, ActorManager.capturePoints)
		end
	end
end

function LQS_AirsoftBase:OnPlayerHitActor(actor)
	-- This gets called if the player hit some actor, doesn't get called if the actor 
	-- that was hit was already hit
	self.airsoftHUDBase:TriggerHitIndicator(actor, true)
end

function LQS_AirsoftBase:PlayerHit(actor, hit)
	-- Basically triggers some hud elements and stuff to indicate that the player was hit
	-- Show a text that the player is hit or back in the game
	if (hit) then
		if (self.alreadyTriggeredIndicatorText) then return end

		-- Give the actor who hit the player
		self.airsoftHUDBase:TriggerHitIndicator(actor, false)

		-- If the player was hit
		-- Trigger indicator
		self.airsoftHUDBase:TriggerIndicatorText("You are <color=red>Hit</color> \n Return to the given <color=purple>respawn point</color>", 3)

		-- Tick alreadyTriggeredIndicatorText
		self.alreadyTriggeredIndicatorText = true
	else
		-- If the player is back in the game
		-- Trigger indicator
		self.airsoftHUDBase:TriggerIndicatorText("You are <color=green>back</color> in the game", 3)

		-- Tick alreadyTriggeredIndicatorText
		self.alreadyTriggeredIndicatorText = false
	end
end

function LQS_AirsoftBase:CheatingChance(actor)
	-- Simply a chance that the given actor can shrug the hit
	-- If the luck is less than 25 then the actor will not call the hit, else then call the hit
	if (not actor.isPlayer) then
		local luck = Random.Range(0, 100)
		if (luck < 25) then
			return true
		end
	end
	return false
end

function LQS_AirsoftBase:ManageHitActor(actor, permaHit, allowedPoints)
	-- Manages the hit actor, suck as kicking out of the squad, and returning to return points
	-- Get the squad of this actor
	local squad = actor.squad
	if (actor.isPlayer or squad.hasPlayerLeader) then
		squad = Player.squad
	end

	if (squad) then
		-- Kicks the given actor out of the squad, if they are on a squad
		local removedMembers = {}
		for _,member in pairs(squad.members) do
			if (member ~= actor) then
				removedMembers[#removedMembers+1] = member
			end
		end
		if (#removedMembers > 0) then
			squad.SplitSquad(removedMembers)
		end

		-- Kick actors out of the vehicle
		if (actor.activeVehicle) then
			-- Start kicking
			-- Kick everyone except of the main actor
			actor.ExitVehicle()
			for _,exMember in pairs(removedMembers) do
				if (exMember.activeVehicle) then
					exMember.ExitVehicle()
				end
			end
		end
	end

	-- Fill up the blanks and start tracking, the GetReturnPoint method now needs a array that contains capture points
	-- So they can be restricted on which points they are allowed to return to, very helpful for custom gamemodes.
	local targetBase, targetPoint = self:GetReturnPoint(actor, allowedPoints)
	self.script.StartCoroutine(self:TrackActor(actor, targetPoint, targetBase, permaHit))
end

function LQS_AirsoftBase:TrackActor(actor, destination, order, permaHit)
	return function()
		-- Basically tracks the actor and removes the disabled effects from it when they reached their destination
		if (not actor or not destination) then return end
		if (self:IsDisabledActor(actor)) then return end

		-- Toggle tracker, you are going to see this in the end aswell
		self:ToggleTracker(actor, true, destination, permaHit)

		-- Stop the entire coroutine if its perma hit
		if (permaHit) then return end

		-- Tracking system
		-- This is gonna lag lmfaooo
		while (Vector3.Distance(destination, actor.transform.position) > 5) do
			-- Lock all of this actor's weapons
			-- Doing it here now, because swapping weapons unlocks it
	        self:ToggleWeapons(actor.weaponSlots, true)

			if (not actor.isPlayer) then
				-- Bots only stuff
			    -- Force actor to go to the return point
				self:SetActorSquadOrder(actor.squad, order, nil)
			else
				-- Player only stuff
				-- Quick travel, literally teleports the player back to the target
				-- return point within a press of a button
				if (Input.GetKeyDown(self.quickTravelKey)) then
					self:TeleportActor(actor, destination)
				end
			end

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Ready timer
		-- A extra 10 seconds (by default), before the actor can attack again
		local readyTimer = self.respawnTime
		local alreadyToggleCountdown = false
		local alreadyTriggeredSpawnHeadsUp = false
		while (readyTimer > 0) do
			-- Timer
			readyTimer = readyTimer - 1 * Time.deltaTime

			-- Have to put this here aswell lmfaoo
			self:ToggleWeapons(actor.weaponSlots, true)

			if (actor.isPlayer) then
				-- Player only
				-- Notify the player if they are in their respawn point
				if (not alreadyTriggeredSpawnHeadsUp) then
					self.airsoftHUDBase:TriggerIndicatorText("You have reached your respawn point \nYou have " .. tostring(self.respawnTime) .. " seconds to apply your new loadout \nFind a good position to prevent being spawnkilled", 3)
					alreadyTriggeredSpawnHeadsUp = true
				end

			    -- If the timer is below below 4 seconds start notifying
			    -- that the player is returning into the game
			    if (readyTimer < 6 and readyTimer > 1) then
					-- Toggle countdown timer
			    	if (not alreadyToggleCountdown) then
						self:ToggleCountdownTimer(true)
						alreadyToggleCountdown = true
					end

					-- Update timer
					self.airsoftHUDBase:UpdateCountdownTimer("You are Respawning in... \n <color=yellow>", "</color>", readyTimer)
			    end
			else
				-- Bots only
				-- Force actor to go to stay at the return point
				self:SetActorSquadOrder(actor.squad, Order.CreateMoveOrder(actor.transform.position), nil)
			end

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- The toggle again, but disabling and turning off some stuff
		self:ToggleTracker(actor, false)
	end
end

function LQS_AirsoftBase:SetActorSquadOrder(actorSquad, order, attackTarget)
	-- Gives an order on the given squad
	if (not actorSquad or not order) then return end
	
	-- Give order and set attack target
	actorSquad.attackTarget = attackTarget
	actorSquad.AssignOrder(order)
end

function LQS_AirsoftBase:ToggleTracker(actor, onHit, destination, permaHit)
	-- Toggles the tracker, making the code above less messy jfc
	-- Add actor from disabledActors array
	self:DisabledActorManager(onHit, actor)

	-- If permaHit is true then start the permaHit tracker
	if (permaHit) then
		self.script.StartCoroutine(self:PermaHitTracker(actor))
	end

	-- Toggle HUD elements (Player only)
	if (actor.isPlayer) then
		-- Enable hit vignette
		self.airsoftHUDBase:ToggleHitVignette(onHit)

		if (onHit) then
			-- On hit
			if (not permaHit) then
				-- Lead the player to the waypoint
				self.airsoftHUDBase:TriggerWaypointMarker(actor, destination)
			end
		else
			-- On recover
			if (not permaHit) then
				-- Stop waypoint marker
				self.airsoftHUDBase:StopWaypointHandler()
			end

			-- Toggle countdown
			self:ToggleCountdownTimer(false)
		end
	end

	-- Change controller properties
	self:ToggleControllerProperties(actor, not onHit)

	-- Toggles
	if (onHit) then
		-- On hit
		-- Parent Occluder
		local occluder = GameObject.Instantiate(self.actorOccluder, actor.transform.position, Quaternion.identity)

		occluder.transform.parent = actor.transform
		occluder.transform.localPosition = Vector3.zero
		occluder.transform.localRotation = Quaternion.identity
	else
		-- On recover
		-- Unlock all of this actor's weapons
	    self:ToggleWeapons(actor.weaponSlots, false)

		-- Toggle actor and remove occluder
		self:ToggleActor(actor, false)
		GameObject.Destroy(actor.transform.Find("[LQS:AS]ActorOccluder(Clone)").gameObject)

		-- Get new loadout
		self:GetNewLoadout(actor)

		-- Call on actor recover event
		self:TriggerListener("onActorRecover", {actor})
	end
end

function LQS_AirsoftBase:PermaHitTracker(actor)
	return function()
		-- Similar to the actor tracker but this one when the actor is permanently hit
		-- It will automatically stop if the given actor is not in the disabled actor array anymore

		-- Trigger perma hit screen when the actor is player
		if (actor.isPlayer) then
			self.airsoftHUDBase:TriggerPermaHitOverlay()
		end

		-- Perma hit tracker
		while (self:IsDisabledActor(actor)) do
			-- Lock all of this actor's weapons
			self:ToggleWeapons(actor.weaponSlots, true)

			-- Set position to current position so they won't move
			if (not actor.isPlayer) then
				self:SetActorSquadOrder(actor.squad, Order.CreateMoveOrder(actor.transform.position), nil)
			end

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Disable the perma hit overlay
		if (actor.isPlayer) then
			self.airsoftHUDBase:TogglePermaHitOverlay(false)
		end
	end
end

function LQS_AirsoftBase:ToggleCountdownTimer(activate)
	-- Toggles the countdown timer, will not work if the match is finish
	if (not self.matchFinish) then
		self.airsoftHUDBase:ToggleCountdownTimer(activate)
	end
end

function LQS_AirsoftBase:GetNewLoadout(actor, customLoadout)
	-- Gets a new loadout for the given actor, if its a player then give their chosen loadout
	local newLoadout = self:CreateLoadout(actor, customLoadout)

	-- Apply new weapons
	local forceEquipWeapon = true
	for i = 1,5 do
		actor.RemoveWeapon(i-1)
		if (newLoadout[i]) then
			actor.EquipNewWeaponEntry(newLoadout[i], i-1, forceEquipWeapon)
			forceEquipWeapon = false
		end
	end

	-- Setup weapons
	self:SetupWeapons(actor)
end

function LQS_AirsoftBase:CreateLoadout(actor, customLoadout)
	-- Basically returns a loadout styled data
	-- loadoutOutput, by default it uses the player's loadout set
	local loadoutOutput = customLoadout
	if (not loadoutOutput) then
		-- If customLoadout is nil
		-- Assign the player's loadout, it will be replaced later if the actor is a bot
		local playerLoadout = Player.selectedLoadout
		loadoutOutput = {playerLoadout.primary, playerLoadout.secondary, playerLoadout.gear1, playerLoadout.gear2, playerLoadout.gear3}

	    -- First iteration primary, second secondary, third to fifth gear or large gear, sixth large gear check
	    -- This will be ignored if the actor is a player
	    if (not actor.isPlayer) then
	    	-- Get random weapons
	    	loadoutOutput[1] = WeaponManager.GetAiWeaponPrimary(self:GetRandomPickStrategy(), actor.team)
	    	loadoutOutput[2] = WeaponManager.GetAiWeaponSecondary(self:GetRandomPickStrategy(), actor.team)
	    	loadoutOutput[3] = WeaponManager.GetAiWeaponSmallGear(self:GetRandomPickStrategy(), actor.team)
	    	loadoutOutput[4] = WeaponManager.GetAiWeaponAllGear(self:GetRandomPickStrategy(), actor.team)
	    	loadoutOutput[5] = WeaponManager.GetAiWeaponSmallGear(self:GetRandomPickStrategy(), actor.team)
    
	    	-- Check if the second gear slot is a large weapon, if so then remove the weapon in third gear slot
	    	if (loadoutOutput[4] and loadoutOutput[4].slot == WeaponSlot.LargeGear) then
	    		loadoutOutput[4] = nil
	    	end
	    end
	else
		-- If customLoadout isn't a nil
		-- Pass the data from customLoadout array to the loadoutOutput, this will ignore any loadout restrictions
		-- It will always follow the loadout format in the customLoadout
		for i = 1,5 do
			loadoutOutput[i] = customLoadout[i]
		end
	end
	return loadoutOutput
end

function LQS_AirsoftBase:GetRandomPickStrategy()
	-- Returns a random pick strategy, this is used for the respawning system
	-- Some arrays for the randomisation
	local pickStrategyDist = {
		Distance.Any,
		Distance.Auto,
		Distance.Short,
		Distance.Far,
		Distance.Mid,
	}

	local pickStrategyType = {
		LoadoutType.AntiArmor,
		LoadoutType.Normal,
		LoadoutType.Repair,
		LoadoutType.ResupplyAmmo,
		LoadoutType.ResupplyHealth,
		LoadoutType.SmokeScreen,
		LoadoutType.Stealth
	}

	-- Start choosing loadout
	-- Choose pick strategy
	return LoadoutPickStrategy(pickStrategyType[math.random(#pickStrategyType)], pickStrategyDist[math.random(#pickStrategyDist)])
end

function LQS_AirsoftBase:TeleportActor(actor, pos)
	-- Self-explanatory
	if (not actor or not pos) then return end
	actor.TeleportTo(pos, actor.transform.rotation)
end

function LQS_AirsoftBase:ToggleControllerProperties(actor, revert)
	-- Just changes the properties of the bot
	if (actor.isPlayer) then return end
	local actorController = actor.aiController
	
	actorController.meleeChargeRange = -1
	actorController.canSprint = false
	if (revert) then
		actorController.meleeChargeRange = 30
		actorController.canSprint = true
	end
end

function LQS_AirsoftBase:DisabledActorManager(add, actor)
	-- Adds or remove the given actor from the "disabledActors" array 
	if (add) then
		-- Add
		self.disabledActors[#self.disabledActors+1] = actor
	else
		-- Remove
		for index,disabledActor in pairs(self.disabledActors) do
			if (disabledActor == actor) then
				self.disabledActors[index] = nil
				break
			end
		end
	end
end

function LQS_AirsoftBase:IsDisabledActor(actor)
	-- Checks if the given actor is disabled
	for _,disabledActor in pairs(self.disabledActors) do
		if (disabledActor == actor) then
			return true
		end
	end
	return false
end

function LQS_AirsoftBase:ActorBlacklistManager(add, actor)
	-- A manager for adding actors that shouldn't be modified by this base
	if (add) then
		-- Add
		self.blacklistedActors[#self.blacklistedActors+1] = actor
	else
		-- Remove
		for index,blacklistedActor in pairs(self.blacklistedActors) do
			if (blacklistedActor == actor) then
				self.blacklistedActors[index] = nil
				break
			end
		end
	end
end

function LQS_AirsoftBase:IsActorBlacklisted(actor)
	-- Checks if the given actor is blacklisted
	for _,blacklistedActor in pairs(self.blacklistedActors) do
		if (blacklistedActor == actor) then
			return true
		end
	end
	return false
end

function LQS_AirsoftBase:GetReturnPoint(actor, allowedPoints, ignoreContesting)
	-- Finds a base for the actor to return when hit
	local chosenPointPos = actor.transform.position

	-- Get available points, if there is no available point for that team
	-- it will choose a neutral point instead, if not still it will get a enemy team's flag
	-- which isn't protected
	local availablePoints = {}
	local foundAvailablePoints = false
	local oppositeTeam = self:GetOppositeTeam(actor.team)
	for i=1,3 do
		-- Check if the previous loop already found some goodies
		if (foundAvailablePoints) then break end

		-- Loop thorugh all capture points to find a viable return points
		for iteration,cp in pairs(allowedPoints) do
			-- Add some available points
			if (
				cp.owner == actor.team and self:IsUnprotected(cp, oppositeTeam) and i == 1 or 
				cp.owner == Team.Neutral and i == 2 or 
				cp.owner == oppositeTeam and self:IsUnprotected(cp, oppositeTeam) and i == 3
			) then
				availablePoints[#availablePoints+1] = cp
			end

			-- If looping through all points are done and there is some found points
			-- then break the loop
			if (not next(allowedPoints, iteration) and #availablePoints > 0) then
				foundAvailablePoints = true
				break
			end
		end
	end

	-- If there are available points found
	if (#availablePoints > 0) then
		-- Choose a nearest available point and set as a return point
		local chosenPoint = self:GetNearestPoint(actor, availablePoints)
		chosenPointPos = chosenPoint.spawnPosition
	end

	-- Return order
	return Order.CreateMoveOrder(chosenPointPos), chosenPointPos
end

function LQS_AirsoftBase:GetNearestPoint(actor, points)
	-- Simply gets the nearest point from the given actor
	local closestPoint = nil
	local minDist = Mathf.Infinity
	for _,point in pairs(points) do
		local dist = Vector3.Distance(point.spawnPosition, actor.transform.position)
		if (dist < minDist) then
			closestPoint = point
			minDist = dist
		end
	end
	return closestPoint
end

function LQS_AirsoftBase:IsUnprotected(point, targetEnemyTeam)
	-- Checks if the given capture point is unprotected/uncontested within it's capture radius
	local actors = ActorManager.AliveActorsInRange(point.spawnPosition, point.captureRange)
	for _,actor in pairs(actors) do
		if (actor.team == targetEnemyTeam) then
			return false
		end
	end
	return true
end

function LQS_AirsoftBase:GetOppositeTeam(team)
	-- Gets the opposite team
	if (team == Team.Blue) then
		return Team.Red
	elseif (team == Team.Red) then
		return Team.Blue
	end
end

function LQS_AirsoftBase:ToggleWeapons(actorSlots, lock)
	-- Lock or Unlocks the weapons of the given actor
	for _,wep in pairs(actorSlots) do
		-- Lock main weapon
		wep.LockWeapon()
		if (not lock) then
			wep.UnlockWeapon()
		end

		-- Lock alt weapons
		for _,altWep in pairs(wep.alternativeWeapons) do
			altWep.LockWeapon()
			if (not lock) then
				altWep.UnlockWeapon()
			end
		end
	end
end

function LQS_AirsoftBase:OnActorSpawn(actor)
	-- Setup the weapons of this actor
	self:SetupWeapons(actor)

	-- If the actor is a player then hide the loadout button (lmao)
	if (not self.playerAlreadySpawned) then
		self.airsoftHUDBase:ToggleRFDeployButton(false)
		self.playerAlreadySpawned = true
	end
end

function LQS_AirsoftBase:SetupWeapons(actor)
	-- Sets up the actor's weapons, basically turns them all into
	-- airsoft guns if possible.
	if (self:IsActorBlacklisted(actor)) then return end

	-- Conversion main
	local actorSlots = actor.weaponSlots
	for _,wep in pairs(actorSlots) do
		-- Setup main and secondary weapons
		self:ConvertToAirsoft(wep)
		self.script.StartCoroutine(self:SetupAltWeapons(wep))

		-- Apply faction skin, and addition to kill performance (probabaly)
		-- Can break the visuals aswell, I can't do anything about it damn itttt
		if (actor.isPlayer) then
			local factionSkin = self:GetFactionData(actor.team)
			local armSkin = self:GetArmSkin(wep)
	
			if (factionSkin[5] and armSkin) then
				armSkin.sharedMaterials = factionSkin[5].armSkin.materials
				armSkin.sharedMesh = factionSkin[5].armSkin.mesh
			end
		end
	end
end

function LQS_AirsoftBase:GetArmSkin(wep)
	-- May be inaccurate lmfao
	local skinnedMeshRenderers = wep.gameObject.GetComponentsInChildren(SkinnedMeshRenderer)
	for _,skinnedMesh in pairs(skinnedMeshRenderers) do
		if (skinnedMesh.rootBone.name:find("Arm.R")) then
			return skinnedMesh
		end
	end
	return nil
end

function LQS_AirsoftBase:SetupAltWeapons(wep)
	return function()
		-- This has a little delay on setting up the alt weapons
		coroutine.yield(WaitForSeconds(0.01))

		if (not wep) then return end
		for _,altWep in pairs(wep.alternativeWeapons) do
			self:ConvertToAirsoft(altWep)
		end
	end
end

function LQS_AirsoftBase:ConvertToAirsoft(weapon)
	-- Different from the one above
	-- Get the weapon role (can be scuffed, damn it Steel)
	local wepRole = weapon.GenerateWeaponRoleFromStats()

	-- Checking, if the weapon is a gl, or something similar then
	-- don't apply any airsoft conversion
	if (self:CanBeAirsoft(weapon, wepRole)) then
		-- Disable Particle Effects
		-- This is going to break some weapon's visuals
		self:RemoveParticles(weapon)

		-- Set the projectile prefab based on the role of the weapon
		self:ApplyProjectile(weapon, wepRole)

		-- Set the firing sound (can be scuffed)
		self:SetSound(weapon, wepRole)

		-- Change the properties of the weapon
		self:ChangeProperties(weapon, wepRole)

		-- Reduce Recoil
		self:ReduceRecoil(weapon)
	end
end

function LQS_AirsoftBase:ReduceRecoil(weapon)
	-- Reduces the recoil of the given weapon
	-- Subtract recoil
	weapon.recoilBaseKickback = weapon.recoilBaseKickback - (Random.Range(0.01, 0.06) * 2)
	weapon.recoilKickbackProneMultiplier = weapon.recoilKickbackProneMultiplier - (Random.Range(0.01, 0.06) * 2)
	weapon.recoilRandomKickback = weapon.recoilRandomKickback - (Random.Range(0.01, 0.06) * 2)

	-- Get new snap recoil
	weapon.recoilSnapMagnitude = self:GetMiddleValue(weapon.recoilSnapMagnitude) - (Random.Range(0.01, 0.06) * 2)
	weapon.recoilSnapDuration = weapon.recoilSnapDuration - (Random.Range(0.01, 0.06) * 2)

	-- Clamp recoil
	weapon.recoilSnapMagnitude = Mathf.Clamp(weapon.recoilSnapMagnitude, 0, Mathf.Infinity)
end

function LQS_AirsoftBase:GetMiddleValue(value)
	local midVal = Mathf.Lerp(0, value, 0.5)
	return midVal
end

function LQS_AirsoftBase:ChangeProperties(weapon, wepRole)
	-- Find the data for the matching weapon role, and the defaults
	local ammoMultiplierTarget = 2
	local spareAmmoMultiplierTarget = ammoMultiplierTarget
	local effectiveRangeTarget = 100

	for _,wepRoleData in pairs(self.airsoftWeaponRoles) do
		if (wepRole == wepRoleData[1]) then
			ammoMultiplierTarget = wepRoleData[4]
			spareAmmoMultiplierTarget = wepRoleData[5]
			effectiveRangeTarget = wepRoleData[6]
		end
	end

	-- Increases the capacity of the given weapon, multiplier depends on the role.
	-- And doesn't increase if the weapon only holds six rounds
	if (weapon.maxAmmo > 6) then
		-- Increase Max
		weapon.maxAmmo = weapon.maxAmmo * ammoMultiplierTarget
		weapon.maxSpareAmmo = weapon.maxSpareAmmo * spareAmmoMultiplierTarget

		-- Set Current
		weapon.ammo = weapon.maxAmmo
		weapon.spareAmmo = weapon.maxSpareAmmo
	end

	-- If the weapon is a shotgun then put the projectile spawn count to 3
	if (wepRole == WeaponRole.Shotgun) then
		weapon.projectilesPerShot = 3
	end

	-- Set effective range
	weapon.effectiveRange = effectiveRangeTarget
end

function LQS_AirsoftBase:RemoveParticles(weapon)
	-- Removes the weapon's particles in it's children
	local particles = weapon.gameObject.GetComponentsInChildren(ParticleSystem)
	for _,particle in pairs(particles) do
		particle.gameObject.SetActive(false)
	end
end

function LQS_AirsoftBase:SetSound(weapon, wepRole)
	-- Similar to the projectile one, but applies the sounds
	local audSrc = weapon.gameObject.GetComponent(AudioSource)

	-- Get the "SoundManager" script, if the weapon has it set the audio source
	local soundManagerScript = weapon.gameObject.GetComponentInChildren(SoundManager)
	if (soundManagerScript) then
		audSrc = soundManagerScript.AudioSource
	end

	-- Set pitch, different if the the audio source doesn't loop
	-- Automatically bypasses if the weapon uses Jelly's "SoundManager" script
	audSrc.pitch = Random.Range(-3, -1)
	if (not audSrc.loop and not weapon.isAuto or soundManagerScript) then
		-- If its not looped then its considered to be a semi automatic weapon
		audSrc.pitch = 1

		-- Apply sound depending on role
		local soundToApply = nil
		for _,wepRoleData in pairs(self.airsoftWeaponRoles) do
			if (wepRole == wepRoleData[1] and wepRoleData[3]) then
				soundToApply = wepRoleData[3]
				break
			end
		end

		-- Finalize
		if (soundToApply) then
			audSrc.clip = soundToApply[math.random(#soundToApply)]
		end
	end
end

function LQS_AirsoftBase:ApplyProjectile(weapon, wepRole)
	-- Apply the the proper projectile, "AutoRifle" is default
	local projToApply = nil
	for _,wepRoleData in pairs(self.airsoftWeaponRoles) do
		if (wepRole == wepRoleData[1]) then
			projToApply = wepRoleData[2]
			break
		end
	end

	-- Finalize
	if (projToApply) then
		weapon.SetProjectilePrefab(projToApply)
	end
end

function LQS_AirsoftBase:CanBeAirsoft(weapon, wepRole)
	-- Literally a check if the weapon can get a airsoft conversion
	-- Check if the wepaon prefab has the [LQS]Airsoft;;Ignore object, if it does then ignore the weapon
	if (weapon.transform.Find("[LQS]Airsoft;;Ignore")) then return false end

	-- Check if the weapon role can become a airsoft conversion
	for _,wepRoleData in pairs(self.airsoftWeaponRoles) do
		if (wepRole == wepRoleData[1]) then
			return true
		end
	end
	return false
end
