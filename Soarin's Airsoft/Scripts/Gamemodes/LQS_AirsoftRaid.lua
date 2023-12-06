-- low_quality_soarin © 2023-2024
-- Gamemode Briefing: Raid

-- 1 (Purple Mercs) v 5 (Eagle Army)

-- Eagles must protect all their satellites and their supply point until the times up.
-- A purple merc must destroy the things mentioned above before the time runs out.


-- Spawns of satellites and supply points will be randomised, just like the way I did in IASBY
-- There will be a different POI which is the eagle's spawn and the purple merc spawn

-- A satellite acts as a signal for the eagle army, when they spot the purple merc they will set a location ping where they saw purple merc
-- and the receivers of the ping will rush to the point, some will just stay defending their objectives.

-- When a satellite is destroyed their ping signal will only be received by some actors
-- or maybe not receive anything at all.

-- A supply point acts like a shortened spawn point for the eagle army, so they don't have to walk for miles just to spawn
-- When a supply point is destroyed they will be forced to spawn to a another supply point


-- When all of the eagle's objectives we're destroyed, they will have to stand their ground while the purple merc hunts them
-- A extraction point will appear after a few seconds have passed, if all of the eagle defenders we're hit and the objectives we're destroyed then the purple merc wins.

-- If all of the eagle defenders successfully defended some of their objectives, successfully extracted during the hunting phase
-- Or got a hit of the purple merc, the eagle army wins

behaviour("LQS_AirsoftRaid")

function LQS_AirsoftRaid:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Prefabs
	self.satellitePrefab = self.data.GetGameObject("satellitePrefab")
	self.supplyPrefab = self.data.GetGameObject("supplyPrefab")

	-- POI Points
	-- This two first vars are just only capture points
	self.eagleSpawnMain = nil
	self.purpleSpawnMain = nil

	-- These are the main POI points
	-- The capture point assigned on them is on their objective script
	self.allObjectives = {}
	self.satellitePoints = {}
	self.supplyPoints = {}

	-- Announcer Lines
	-- To add in the game feel
	self.purpleMercAnnouncerLines = self.targets.purpleMercAnnouncerLines.GetComponent(DataContainer)
	self.eagleArmyAnnouncerLines = nil

	-- Listeners
	-- Airsoft Base
	self.onActorHit = function(arguments)
		self:OnActorHit(arguments[1], arguments[2])
	end

	self.onActorRecover = function(arguments)
		self:OnActorRecover(arguments[1])
	end

	self.onDeployButtonPressed = function()
		self:OnDeploy()
	end

	-- Objectives
	self.onObjectiveDestroyed = function(arguments)
		self:OnObjectiveDestroyed(arguments[1])
	end

	-- AI Handlers
	self.onSpotEnemy = function(arguments)
		self:OnSpotEnemy(arguments[1], arguments[2])
	end

	self.onLoseEnemy = function(arguments)
		self:OnLoseEnemy(arguments[1], arguments[2])
	end

	self.onRemoveAIHandler = function(arguments)
		self:OnLoseEnemy(arguments[1], arguments[2])
	end

	-- Easter Egg Names
	-- Rare names only exclusive for this mode, and only for the purple mercs
	self.easterEggNames = {
		"William Afton",
		"Subject 106",
		"V1",
		"V2",
		"Akira Nishikiyama",
		"Kazuma Kiryu",
		"Goro Majima",
		"Delinquent",
		"Perrell Laquarius Brown",
		"Purple Guy",
		"Sudliam Nafton"
	}

	-- Vars
	self.activeActors = {}
	self.spottersList = {}

	self.eagleDefenders = {}
	self.purpleGuy = nil

	self.activeSatelliteCount = 0
	self.objectivesDestroyedCount = 0

	self.extractRange = 0

	self.airsoftBase = nil
	self.airsoftHUDBase = nil
	self.airsoftRaidAIBase = nil
	self.airsoftRaidHUDBase = nil

	self.alreadyDeployed = false
	self.purpleGuySpotted = false

	self.huntingPhase = false

	-- Events
    GameEvents.onMatchEnd.AddListener(self, "OnMatchEnd")

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())

	-- Share Instance
	_G.LQSSoarinsAirsoftRaidBase = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_AirsoftRaid:OnMatchEnd()
	-- Stop the game from ending
	CurrentEvent.Consume()
end

function LQS_AirsoftRaid:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0))

		-- Remove all vehicles in the map
	    local vehiclesInMap = ActorManager.VehiclesInRange(Player.actor.transform.position, Mathf.Infinity)
	    for _,vehicle in pairs(vehiclesInMap) do
	    	GameObject.Destroy(vehicle.gameObject)
	    end

		-- Get the base script
		local airsoftBase = _G.LQSSoarinsAirsoftBase
		if (airsoftBase) then
			-- Apply the base scripts
			self.airsoftBase = airsoftBase.self
			self.airsoftHUDBase = self.airsoftBase.airsoftHUDBase

			-- Add listeners
			self.airsoftBase:ManageListeners(false, "onActorHit", "[LQS:SA]Raid", self.onActorHit)
			self.airsoftBase:ManageListeners(false, "onActorRecover", "[LQS:SA]Raid", self.onActorRecover)
			self.airsoftHUDBase:ManageListeners(false, "onDeployButtonPressed", "[LQS:SA]Raid", self.onDeployButtonPressed)

			-- Change some properties
			self.airsoftBase.disableHitActorManager = true

			self.airsoftHUDBase:ToggleRFDeployButton(false)
			self.airsoftHUDBase:ToggleAirsoftDeployButton(true)

			self.airsoftHUDBase.airsoftDeployLabel.text = "Start Raid"
		end

		-- Get the AI base script
		local raidAIBase = _G.LQSSoarinsAirsoftRaidAIBase
		if (raidAIBase) then
			-- Apply script
			self.airsoftRaidAIBase = raidAIBase.self 

			-- Add Listeners
			self.airsoftRaidAIBase:ManageListeners(false, "onSpotEnemy", "[LQS:SA]Raid", self.onSpotEnemy)
			self.airsoftRaidAIBase:ManageListeners(false, "onLoseEnemy", "[LQS:SA]Raid", self.onLoseEnemy)
			self.airsoftRaidAIBase:ManageListeners(false, "onRemoveAIHandler", "[LQS:SA]Raid", self.onRemoveAIHandler)
		end

		-- Get Raid HUD base script
		local raidHUDBase = _G.LQSSoarinsAirsoftRaidHUDBase
		if (raidHUDBase) then
			-- Apply script
			self.airsoftRaidHUDBase = raidHUDBase.self
		end

		-- Setup main stuff
		self:SetupPOI()
		self:SetupTeams()
	end
end

function LQS_AirsoftRaid:OnSpotEnemy(actor, aiBehaviorData)
	if (aiBehaviorData[1] == "AIDefender") then
		-- Eagles Only
	    -- When the actor spots the purple guy
	    -- Add to spotters array
	    self:ManageSpotters(false, actor)
    
	    -- Warn defenders that the purple guy is spotted
	    self:WarnDefenders(self.purpleGuy.transform.position, "Purple guy spotted!")
	end
end

function LQS_AirsoftRaid:OnLoseEnemy(actor, aiBehaviorData)
	if (aiBehaviorData[1] == "AIDefender") then
		-- When the actor loses sight of the purple guy
	    -- Remove from spotters array
	    self:ManageSpotters(true, actor)
	end
end

function LQS_AirsoftRaid:ManageSpotters(remove, actor)
	-- Manages the list who has sights of the purple guy
	if (not remove) then
		-- Add
		if (not self:AlreadyInSpotList(actor)) then
			self.spottersList[#self.spottersList+1] = actor
		end
	else
		-- Remove
		local listIndex = self:AlreadyInSpotList(actor)
		if (listIndex) then
			self.spottersList[listIndex] = nil
		end
	end

	-- Check if the spottersList count is above zero
	-- If so then keep the purpleGuySpotted bool true, it will turn false if no one have sights of the purple guy
	self.purpleGuySpotted = #self.spottersList > 0
end

function LQS_AirsoftRaid:AlreadyInSpotList(value)
	-- This checks if the given value already exists in the spotters list, returns the index if it does
	for spotterIndex,spotterActor in pairs(self.spottersList) do
		if (spotterActor == value) then
			return spotterIndex
		end
	end
	return nil
end

function LQS_AirsoftRaid:OnDeploy()
	-- Custom deploy, that's it
	self:RaidDeploy()
end

function LQS_AirsoftRaid:RaidDeploy()
	-- This simply deploys the available actors
	if (self.alreadyDeployed) then return end

	-- Deploy Base
	for _,actor in pairs(self.activeActors) do
		-- Get the proper spawnpoint for the actor and assign them in the team arrays
		local targetSpawnPoint = nil
		if (actor.team == Team.Blue) then
			-- Eagles
			targetSpawnPoint = self.eagleSpawnMain.spawnPosition
			self.eagleDefenders[#self.eagleDefenders+1] = actor
		elseif (actor.team == Team.Red) then
			-- Purple Mercenaries
			targetSpawnPoint = self.purpleSpawnMain.spawnPosition
			self.purpleGuy = actor
		end

		if (targetSpawnPoint) then
			-- Spawn
			actor.SpawnAt(targetSpawnPoint, Quaternion.identity)
		
			-- Add squad, so they can move
			if (not actor.isPlayer) then
				Squad.Create({actor})
			end
		end
	end

	-- Assign the aiBehavior
	-- Apply AI defender on the eagle team
	for i = 1, 2 do
		for _,aiActor in pairs(self.eagleDefenders) do
			if (not aiActor.isPlayer) then
				self.airsoftRaidAIBase:StartAI(aiActor, "AIDefender", self.eagleSpawnMain)
			end
		end
	end

	-- Apply AI Defender on the purple merc team
	if (not self.purpleGuy.isPlayer) then
		self.airsoftRaidAIBase:StartAI(self.purpleGuy, "AIPurpleMerc", self.purpleSpawnMain)
	end

	-- Close the loadout screen
	SpawnUi.Close()

	-- Start the raid timer and play announcer line
	self.script.StartCoroutine(self:StartRaidTimer())
	self:PlayAnnouncerLine("missionStart", Player.actor.team)

	-- Soo it can't be triggered again
	self.alreadyDeployed = true
end

function LQS_AirsoftRaid:PlayAnnouncerLine(lineType, targetTeam, randomLine)
	-- Plays a announcer line from the given team. Can be randomised
	-- Get the target announcer
	local targetAnnouncer = nil
	if (targetTeam == Team.Blue) then
		targetAnnouncer = self.eagleArmyAnnouncerLines
	elseif (targetTeam == Team.Red) then
		targetAnnouncer = self.purpleMercAnnouncerLines
	end

	-- Play line (only if the announcer exists and that line entry exists)
	if (targetAnnouncer and targetAnnouncer.HasObject(lineType)) then
		self.airsoftBase.airsoftHUDBase:StartSequenceDataContainer(targetAnnouncer.GetGameObject(lineType).GetComponent(DataContainer), randomLine)
	end
end

function LQS_AirsoftRaid:OnActorRecover(actor)
	-- Add back the actor's ai handler, defenders only
	if (actor ~= self.purpleGuy and not actor.isPlayer) then
		self.airsoftRaidAIBase:StartAI(actor, "AIDefender", nil)
	end
end

function LQS_AirsoftRaid:OnActorHit(actor, sourceActor)
	-- Call actor hit, way different than the base one
	self:RaidActorHit(actor,sourceActor)
end

function LQS_AirsoftRaid:RaidActorHit(actor, sourceActor)
	-- This variant of ActorHit is only available for this gamemode
	-- The only difference between this and the one in the base script is that this gives a chance for the 
	-- Eagles to respawn, but for the Purple merc it just ends the game
	local permaHit = false

	-- Team check
	if (actor.team == Team.Red) then
		-- If the actor that was hit is a purple merc
		-- End the match (duh)
		self.script.StartCoroutine(self:EndRaidMatch(sourceActor, false, 5))

		-- Set permaHit to true
		permaHit = true
	elseif (actor.team == Team.Blue) then
		-- If the actor that was hit is a eagle soldier
		-- If the game's phase is on the hunting phase
		if (self.huntingPhase) then
			-- Set permaHit for ealges to true
			permaHit = true
		end
	end

	-- Stop the actor's ai handler
	if (not actor.isPlayer) then
		self.airsoftRaidAIBase:ManageHandlerArray(true, actor)
	end

	-- Start tracking the actor
	local allowedPoints = self:GetAvailablePoints(actor)
	self.airsoftBase:ManageHitActor(actor, permaHit, allowedPoints)
end

function LQS_AirsoftRaid:OnObjectiveDestroyed(objective)
	-- If a objective was destroyed
	if (not objective) then return end
	objective = objective.self

	-- If the destroyed objective is a satellite then reduce the active satellite count
	if (objective.objectiveType == "Satellite") then
		self.activeSatelliteCount = self.activeSatelliteCount - 1
	end

	-- Hunting phase checker
	if (not self.huntingPhase) then
		-- Increase the count of objectives that was destroyed
		self.objectivesDestroyedCount = self.objectivesDestroyedCount + 1

		-- If the objectivesDestroyedCount reaches the count of objectives then start the hunting phase
		if (self.objectivesDestroyedCount >= #self.allObjectives) then
			self:StartHuntingPhase()
		end
	end

	-- Remove objective marker if the player is a purple guy
	if (self.purpleGuy.isPlayer) then
		self.airsoftRaidHUDBase:WaypointManager(true, objective.objectiveID)
	end

	-- Notify defenders that a objective is destroyed
	-- Some of them maybe warned if a satellite is destroyed
	self:WarnDefenders(objective.assignedPoint.spawnPosition, "A objective has been destroyed at " .. objective.assignedPoint.name)
end

function LQS_AirsoftRaid:EndRaidMatch(winnerActor, skip, duration, noAnnouncerLine)
	return function()
		-- Ends the match literally
		-- Error patch
		if (not duration) then
			duration = 5
		end

		-- Delay (skippable)
		local time = duration
		while (time > 0 and not skip) do
			time = time - 1 * Time.deltaTime
			coroutine.yield(WaitForSeconds(0))
		end

		-- End the match (duh)
	    if (not self.airsoftBase.matchFinished) then
			-- Play win announcer line (doesn't play if the winner team is eagles and it reaches the hunting phase)
			if (not noAnnouncerLine) then
				self:PlayAnnouncerLine("win", winnerActor.team, true)
			end

			-- Call the base EndMatch
	    	self.airsoftBase:EndMatch(winnerActor, true)
	    end
	end
end

function LQS_AirsoftRaid:StartRaidTimer()
	return function()
		-- This basically starts the raid timer
		-- Toggle timer
		self.airsoftRaidHUDBase:ToggleTimer(true)

		-- Timer main
		local raidTimer = 300
		local alreadyPlayed1MinWarn = false
		local alreadyPlayed15SecWarn = false
		while (raidTimer > 0) do
			-- If the game is in the hunting phase then stop this timer
			if (self.huntingPhase) then return end

			-- If the timer hits 1 min or 15 seconds then play the announcer line
			if (raidTimer < 61 and raidTimer > 59) then
				-- 1 minute
				if (not alreadyPlayed1MinWarn) then
					self:PlayAnnouncerLine("1minWarn", Player.actor.team, true)
					alreadyPlayed1MinWarn = true
				end
			elseif (raidTimer < 16 and raidTimer > 14) then
				-- 15 seconds
				if (not alreadyPlayed15SecWarn) then
					self:PlayAnnouncerLine("15secWarn", Player.actor.team, true)
					alreadyPlayed15SecWarn = true
				end
			end

			-- Decrease Time and update timer hud
			raidTimer = raidTimer - 1 * Time.deltaTime
			self.airsoftRaidHUDBase:UpdateTimer(raidTimer)

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- If the time is up then end the game
		self.script.StartCoroutine(self:EndRaidMatch(self.eagleDefenders[math.random(#self.eagleDefenders)], true))
	end
end

function LQS_AirsoftRaid:StartHuntingPhase()
	-- Set the purple guy's state to hunting state
	-- This is basically the agro state of this actor lol
	if (not self.purpleGuy.isPlayer) then
		self.airsoftRaidAIBase:OverrideState(self.purpleGuy, "Hunt")
	end

	-- Start the extraction sequence
	self.script.StartCoroutine(self:StartExtractionSequence())

	-- Enable the hunting phase bool
	self.huntingPhase = true
end

function LQS_AirsoftRaid:StartExtractionSequence()
	return function()
		-- The timers for the extraction thingy
		local timer = 60

		-- Play announcer line
		self:PlayAnnouncerLine("objectivesDestroyed", Player.actor.team, true)

		-- Arrival timer
		-- The time before the extraction heli arrives
		while (timer > 0) do
			-- Decrease timer and update timer hud
			timer = timer - 1 * Time.deltaTime
			self.airsoftRaidHUDBase:UpdateTimer(timer)

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Do stuff when the arrival timer ends
		-- Spawn the extract heli (if possible to)
		local heliPilot, landingDest, heliSpawnPos = self:SpawnExtractHeli()
		local extractHeli = heliPilot.activeVehicle

		-- Check if the did successfully spawn
		-- If so wait for the heli reaches it's landing area
		if (not heliPilot) then
			self.script.StartCoroutine(self:EndRaidMatch(self.eagleDefenders[math.random(#self.eagleDefenders)], true, 0, true))
			return
		end

		-- Play extraction announcer line
		self:PlayAnnouncerLine("extractionArrived", Player.actor.team, true)

		-- Get all survivors to the extract point
		for _,survivorActor in pairs(self.eagleDefenders) do
			if (not self.airsoftBase:IsDisabledActor(survivorActor)) then
				-- Check if player
				if (not survivorActor.isPlayer) then
					-- Is bot
					self.airsoftRaidAIBase:OverrideState(survivorActor, "Extract")
				else
					-- Is player
				end
			end
		end

		-- Set timer
		timer = 30

		-- Track extract heli
		local reachedLandingArea = false
		while (not reachedLandingArea) do
			-- Track distance
			-- Start the extraction timer when reached
			local distToDestination = Vector3.Distance(landingDest, extractHeli.transform.position)
			if (distToDestination < 70) then
				heliPilot.aiController.targetFlightAltitude = 10
				reachedLandingArea = true
			end

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Extraction timer
		while (timer > 0) do
			-- Decrease timer and update timer hud
			timer = timer - 1 * Time.deltaTime
			self.airsoftRaidHUDBase:UpdateTimer(timer)

			-- Lerp extract heli soo it won't wildly move around
			extractHeli.transform.position = Vector3.Lerp(extractHeli.transform.position, landingDest, Time.deltaTime * 0.3)

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Do stuff when the extraction timer ends
		-- Get the actors on the heli and get the hell out of here
		local actorsExtracted = {}
		local actorsInExtractRange = ActorManager.AliveActorsInRange(self.eagleSpawnMain.transform.position, self.extractRange)
		for _,extractingActor in pairs(actorsInExtractRange) do
			-- Check if the actor isn't the purple guy and not hit
			if (extractingActor ~= self.purpleGuy and not self.airsoftBase:IsDisabledActor(extractingActor)) then
				-- Bots only
				if (not extractingActor.isPlayer) then
					-- Add the actor to the heli pilot squad, because it kicks out the pilot lmfaoo
				    heliPilot.squad.AddMember(extractingActor)
				    extractingActor.teleportTo(extractHeli.transform.position, Quaternion.identity)
    
				    -- Add to blacklist (hope this works as intended)
				    self.airsoftRaidAIBase:OverrideState(extractingActor, "Idle")
				    self.airsoftBase:ActorBlacklistManager(true, extractingActor)
				end

				-- Enter vehicle and add to actors extracted array
				extractingActor.EnterVehicle(extractHeli)
				actorsExtracted[#actorsExtracted+1] = extractingActor
			end
		end

		-- Leave area
		heliPilot.squad.AssignOrder(Order.CreateMoveOrder(heliSpawnPos))

		-- End the match
		-- If there are actors who successfully extracted then the eagle army wins, if none then the purple mercs win
		local winnerActor = self.purpleGuy
		if (#actorsExtracted > 0) then
			winnerActor = self.eagleDefenders[math.random(#self.eagleDefenders)]
		end

		self.script.StartCoroutine(self:EndRaidMatch(winnerActor, true, 0, winnerActor ~= self.purpleGuy))

		-- Play win announcer line (extracted)
		self:PlayAnnouncerLine("winExtracted", Player.actor.team, true)
	end
end

function LQS_AirsoftRaid:SpawnExtractHeli()
	-- This spawns the extract heli
	-- Check if the eagle defender's point can be landed on
	local landingCheckRay = Ray(self.eagleSpawnMain.transform.position, Vector3.up)
	local landingCheckCast = Physics.Spherecast(landingCheckRay, 15, 50, RaycastTarget.ProjectileHit)

	-- If the landingCheck raycast hits something then that's a instant no
	if (landingCheckCast) then
		return nil, nil
	end

	-- If spawnpoint is landable then spawn the heli
	-- Get a heli spawnpoint, before really spawning it
	local randomActorT = self.eagleDefenders[math.random(#self.eagleDefenders)].transform

	-- Calculate spawn and land pos
	local spawnPosition = randomActorT.position + randomActorT.forward * 850 + Vector3.up * 50
	local extractHeliLandPoint = self.eagleSpawnMain.transform.position + Vector3.up * 15

	-- Calculate spawn rot
	local spawnDir = self.eagleSpawnMain.transform.position - spawnPosition
	spawnDir.y = 0

	local spawnRotation = Quaternion.LookRotation(spawnDir)

	-- Spawning main
	-- Check if the team has a attack heli assigned if it does then continue else stop and return false
	local heliPrefab = VehicleSpawner.GetPrefab(Team.Blue, VehicleSpawnType.TransportHelicopter)
	if (not self:IsHelicopter(heliPrefab)) then
		return nil, nil
	end

	-- Spawn the heli, and disarm it if it does have lethal weapons
	local extractHeli = VehicleSpawner.SpawnVehicle(Team.Blue, VehicleSpawnType.TransportHelicopter, spawnPosition, spawnRotation)
	self:DisarmVehicle(extractHeli)

	-- Add a pilot and modify its properties
	local heliPilot = ActorManager.CreateAIActor(Team.Blue)

	heliPilot.name = self.easterEggNames[math.random(#self.easterEggNames)]
	self.airsoftBase:ActorBlacklistManager(true, heliPilot)

	heliPilot.SpawnAt(extractHeli.transform.position, Quaternion.identity)
	Squad.Create({heliPilot})
	
	heliPilot.EnterVehicle(extractHeli)
	heliPilot.squad.AssignOrder(Order.CreateMoveOrder(extractHeliLandPoint))

	return heliPilot, extractHeliLandPoint, spawnPosition
end

function LQS_AirsoftRaid:DisarmVehicle(vehicle)
	-- Disarms all the weapons in the given vehicle
	if (not vehicle) then return end

	-- Loop through all the seats and disarm the weapons
	for _,vehSeat in pairs(vehicle.seats) do
		for _,vehSeatWeapon in pairs(vehSeat.weapons) do
			-- Have to do a additional nil check because some modders leave empty mounted weapon entries
			if (vehSeatWeapon) then
				-- Empty ammo
				vehSeatWeapon.maxAmmo = 0
				vehSeatWeapon.maxSpareAmmo = 0
				vehSeatWeapon.ammo = 0
				vehSeatWeapon.spareAmmo = 0

				-- Lock weapon
				vehSeatWeapon.LockWeapon()
			end
		end
	end
end

function LQS_AirsoftRaid:IsHelicopter(vehicleGO)
	-- Checks if the given vehicle is a helicopter
	if (vehicleGO) then
		local vehicleScript = vehicleGO.GetComponent(Vehicle)
	    if (vehicleScript.isHelicopter) then
	    	return true
	    end
	end
	return false
end

function LQS_AirsoftRaid:WarnDefenders(targetPosition, additionalInfo, excludedActor)
	-- This just warns some of the defenders that a objective is destroyed
	-- Calculate the success chance of warning the defenders
	local warnSuccessChance = self.activeSatelliteCount / #self.satellitePoints * 100
	warnSuccessChance = Mathf.Clamp(warnSuccessChance, 25, Mathf.Infinity)

	-- Start warning
	for _,defenderActor in pairs(self.eagleDefenders) do
		if (defenderActor ~= excludedActor) then
			local luck = Random.Range(0, #self.satellitePoints / #self.satellitePoints * 100)
			if (luck < warnSuccessChance) then
				if (not defenderActor.isPlayer) then
					-- If the actor that was warned is a bot
					self.airsoftRaidAIBase:GoToDestination(defenderActor, targetPosition, 5.5, true)
				else
					-- If the actor that was warned is a player
					self.airsoftBase.airsoftHUDBase:TriggerIndicatorText(additionalInfo)
				end
			end
		end
	end
end

function LQS_AirsoftRaid:GetAvailablePoints(actor)
	-- This gets the available points for the actor's team, Eagles have access to supply points (if they aren't sabotaged)
	-- While Purple Mercs only have their first spawn, they don't have a respawn chance anyway
	local availablePoints = {self.purpleSpawnMain}
	if (actor.team == Team.Blue) then
		-- If the actor team is Eagle then do the real checking
		-- Get some available supply points, the eagle spawn is there just incase if all supply points are not available
		availablePoints = {self.eagleSpawnMain}
		for _,supplyPointData in pairs(self.supplyPoints) do
			if (not supplyPointData.isSabotaged) then
				availablePoints[#availablePoints+1] = supplyPointData[2]
			end
		end
	end
	return availablePoints
end

function LQS_AirsoftRaid:SetupPOI()
	-- Sets up the point of interests, such as eagle and purple merc spawns, supply points, satellites, etc...
	-- Get all of the active capture points in the map
	local capturePoints = ActorManager.capturePoints

	-- Start setting up the POIs
	-- Stage 1: Choose a capture for the eagle spawn main and do a furthest point check for the purple merc spawn
	self.eagleSpawnMain = capturePoints[math.random(#capturePoints)]
    self.purpleSpawnMain = self:GetXPoint(false, self.eagleSpawnMain, capturePoints)

	-- Set the extract range for later
	self.extractRange = self.eagleSpawnMain.captureFloor

	-- Set capture point's captureFloor and captureCeiling range 0 so they won't be captured
	self.eagleSpawnMain.captureFloor = 0
	self.eagleSpawnMain.captureCeiling = 0

	self.purpleSpawnMain.captureFloor = 0
	self.purpleSpawnMain.captureCeiling = 0

	-- Stage 2: Choose spawnpoints for the objectives
	local chosenPOIPoints = {}
	local excludedPoints = {self.eagleSpawnMain, self.purpleSpawnMain}
	for i = 1, 5 do
		chosenPOIPoints[i] = self:GetXPoint(true, self.eagleSpawnMain, capturePoints, excludedPoints)
		excludedPoints[#excludedPoints+1] = chosenPOIPoints[i]
	end

	-- Stage 3: Spawn the objective prefabs and assign them to array, object prefabs to spawn will take turns per loop
	local toInstantiate = self.satellitePrefab
	local instantiateType = "Satellite"
	for _,poiPoint in pairs(chosenPOIPoints) do
		-- Instantiate the object prefab, adding random rotations to spice it up a bit
		local randomRot = Quaternion.Euler(Vector3(0, Random.Range(-360, 360), 0))
		local spawnedObjective = GameObject.Instantiate(toInstantiate, poiPoint.transform.position, randomRot).GetComponent(ScriptedBehaviour).self

		-- Assign stuff on the objective script
		spawnedObjective:ManageListeners(false, "onSabotaged", "[LQS:SA]Raid", self.onObjectiveDestroyed)

		spawnedObjective.assignedPoint = poiPoint
		spawnedObjective.objectiveType = instantiateType

		-- Choose the next prefab to instantiate
		if (toInstantiate == self.satellitePrefab) then
			-- Done cloning a satellite objective
			self.satellitePoints[#self.satellitePoints+1] = spawnedObjective
			self.airsoftRaidHUDBase:WaypointManager(false, spawnedObjective.objectiveID, spawnedObjective.assignedPoint.transform.position, "SatelliteMarker")

			toInstantiate = self.supplyPrefab
			instantiateType = "SupplyPoint"
		elseif (toInstantiate == self.supplyPrefab) then
			-- Done cloning a supply objective
			self.supplyPoints[#self.supplyPoints+1] = spawnedObjective
			self.airsoftRaidHUDBase:WaypointManager(false, spawnedObjective.objectiveID, spawnedObjective.assignedPoint.transform.position, "SupplyPointMarker")

			toInstantiate = self.satellitePrefab
			instantiateType = "Satellite"
		end

		-- Add to allObjectives array
		self.allObjectives[#self.allObjectives+1] = spawnedObjective
	end

	-- Stage 4: Finalize
	-- Disable flags
	for _,point in pairs(chosenPOIPoints) do
		point.gameObject.SetActive(false)
	end

	-- Apply vars
	self.activeSatelliteCount = #self.satellitePoints
end

function LQS_AirsoftRaid:GetXPoint(nearest, targetPoint, points, excludedPoints)
	-- Similar to that nearest point script in the airsoft base script, but also has a ability to get the furthest point
	-- And ignore given excluded points

	-- Set the targetDist for reference later on the loop
	local targetDist = 0
	if (nearest) then
		targetDist = Mathf.Infinity
	end

	-- Loop through all points and return the nearest or furthest point
	local outputPoint = nil
	for _,point in pairs(points) do
		local dist = Vector3.Distance(point.transform.position, targetPoint.transform.position)
		-- If the point was the same point that is being used as reference then ignore it
		if (not self:IsExcludedPoint(point, excludedPoints)) then
			if (dist < targetDist and nearest) then
				-- Nearest
				outputPoint = point
				targetDist = dist
			elseif (dist > targetDist and not nearest) then
				-- Furthest
				outputPoint = point
				targetDist = dist
			end
		end
	end
	return outputPoint
end

function LQS_AirsoftRaid:IsExcludedPoint(point, excludedPoints)
	-- Checks if the given point is a part of the exludedPoints array
	if (not excludedPoints) then return false end

	for _,exPoint in pairs(excludedPoints) do
		if (point == exPoint) then
			return true
		end
	end
	return false
end

function LQS_AirsoftRaid:SetupTeams()
	-- This sets up the teams
	local actorsToSpawn = {}
	local removedActors = {}

	-- Get the actors in teams
	local actorsEagles = ActorManager.GetActorsOnTeam(Team.Blue)
	local actorsRavens = ActorManager.GetActorsOnTeam(Team.Red)

	-- Setup Teams
	local targetArray = actorsEagles
	local targetTeam = Team.Blue
	local targetCount = 5
	for teamInterations = 1, 2 do
		-- Setup team counts
	    -- Spawn actors, only if the number of actors in the team is insufficient
		local missingActorsCount = self:GetMissingActorsCount(targetArray, targetCount)
		for spawnIterations = 1, missingActorsCount do
			-- Add a actor
			local newActor = ActorManager.CreateAIActor(targetTeam)
			targetArray[#targetArray+1] = newActor

			-- Modify properties
			-- This only works for newly spawned actors
			if (teamInterations == 2) then
				-- Modify actor (Purple Mercenaries)
				-- Name easter egg, doing this for fun lol
				local luck = Random.Range(0, 100)
				if (luck < 35) then
					-- If its lucky then change the name of the actor on one of the names in the easterEggNames list
					local chosenName = self.easterEggNames[math.random(#self.easterEggNames)]
					newActor.name = chosenName
				end
			end

			-- Add airsoft support on the actor
			self.airsoftBase:AddActorSupport(newActor)
		end

		-- Deactivate actors
		-- If there are too much actors in that team
		for removeIterations = 1, #targetArray do
			if (removeIterations > targetCount) then
				-- If the iteration is over the targetCount
				removedActors[#removedActors+1] = targetArray[removeIterations]
			else
				-- if the iteration is below the targetCount
				actorsToSpawn[#actorsToSpawn+1] = targetArray[removeIterations]
			end
		end

		-- Setup the next team
		targetArray = actorsRavens
		targetTeam = Team.Red
		targetCount = 1
	end

	-- Finalize	
	self.script.StartCoroutine(self:RemoveActorLeaderboardContent(removedActors))
	self.activeActors = actorsToSpawn
end

function LQS_AirsoftRaid:RemoveActorLeaderboardContent(removedActors)
	return function()
		-- This simply just removes the leaderboard content of the given actors
		coroutine.yield(WaitForSeconds(0.1))
		for _,xActor in pairs(removedActors) do
			xActor.Deactivate()
			self.airsoftHUDBase.leaderboardBase:RemoveLeaderboardContent(xActor)
		end
	end
end

function LQS_AirsoftRaid:GetMissingActorsCount(array, count)
	-- Gets the number of missing actors in the given team
	local output = 0
	for i = 1, count do
		if (not array[i]) then
			output = output + 1
		end
	end
	return output
end
