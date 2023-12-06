-- low_quality_soarin © 2023-2024
-- Gamemode Briefing: Capture The Flag

-- 10 (Falcons) v 10 (Magpies)

-- Some actors in the team must defend their flag while the others engage the opposing flag
-- When a team reaches 5 captures then that team wins


-- Flags will be always set at the furthest point in the map, only recommended on small or medium maps
-- The flag points will be treated as a spawnpoint for the teams aswell


-- If a actor reaches a flag then they will become the holder of the flag, they have to take it back on their base
-- And make sure that their flag is still there in order to capture the taken flag

-- If a actor who is holding the flag then they will drop the flag, it can be taken by the same team of the actor who was holding the flag before
-- Or be instantly sent back to base if approached by a actor if it has the same owner team as the flag

behaviour("LQS_AirsoftCTF")

function LQS_AirsoftCTF:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Flags
	self.flagCTF = self.data.GetGameObject("flagCTF")

	-- Team bases and flags
	-- Team A: Eagles, Team B: Ravens
	self.teamABase = nil
	self.teamBBase = nil

	self.teamAFlag = nil
	self.teamBFlag = nil

	-- Listeners
	-- Airsoft Base
	self.onActorHit = function(arguments)
		self:OnActorHit(arguments[1], arguments[2])
	end

	self.onActorRecover = function(arguments)
		self:OnActorRecover(arguments[1])
	end

	-- HUD Base
	self.onDeployButtonPressed = function(arguments)
		self:OnDeploy()
	end

	-- CTF Flags
	self.onFlagTaken = function(arguments)
		-- Parameters: (TakenFlag: Flag, TakerActor: Actor)
		self:OnFlagTaken(arguments[1], arguments[2])
	end

	self.onFlagDropped = function(arguments)
		-- Parameters: (DroppedFlag: Flag)
		self:OnFlagDropped(arguments[1])
	end

	self.onFlagCaptured = function(arguments)
		-- Parameters: (CapturedFlag: Flag, CapturerFlag: Flag, CapturerActor: Actor)
		self:OnFlagCaptured(arguments[1], arguments[2], arguments[3])
	end

	self.onFlagReturned = function(arguments)
		-- Parameters: (ReturnedFlag: Flag, WasCaptured: Bool)
		self:OnFlagReturned(arguments[1], arguments[2])
	end

	-- Vars
	self.allActors = {}
	self.teamAActors = {}
	self.teamBActors = {}

	self.teamAFlagHolder = nil
	self.teamBFlagHolder = nil

	self.airsoftBase = nil
	self.airsoftHUDBase = nil
	self.airsoftCTFAIBase = nil

	self.alreadyDeployed = false

	-- Events
	GameEvents.onMatchEnd.AddListener(self, "OnMatchEnd")

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())

	-- Share instance
	_G.LQSSoarinsAirsoftCTFBase = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_AirsoftCTF:OnMatchEnd()
	-- Stop the game from ending
	CurrentEvent.Consume()
end

function LQS_AirsoftCTF:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0))

		-- Get CTF AI base
		local airsoftCTFAIBase = _G.LQSSoarinsAirsoftCTFAIBase
		if (airsoftCTFAIBase) then
			self.airsoftCTFAIBase = airsoftCTFAIBase.self
		end

		-- Get base script
		local airsoftBase = _G.LQSSoarinsAirsoftBase
		if (airsoftBase) then
			-- Apply base scripts
			self.airsoftBase = airsoftBase.self
			self.airsoftHUDBase = self.airsoftBase.airsoftHUDBase

			-- Add Listeners
			self.airsoftBase:ManageListeners(false, "onActorHit", "[LQS:SA]CTF", self.onActorHit)
			self.airsoftBase:ManageListeners(false, "onActorRecover", "[LQS:SA]CTF", self.onActorRecover)
			self.airsoftHUDBase:ManageListeners(false, "onDeployButtonPressed", "[LQS:SA]CTF", self.onDeployButtonPressed)

			-- Some properties changes
			self.airsoftBase.disableHitActorManager = true

			self.airsoftHUDBase:ToggleRFDeployButton(false)
			self.airsoftHUDBase:ToggleAirsoftDeployButton(true)

			self.airsoftHUDBase.airsoftDeployLabel.text = "Start CTF"
		end

		-- Setup points
		self:SetupBases()
		self:SetupTeams()
	end
end

function LQS_AirsoftCTF:OnActorRecover(actor)
	-- Set AI handler
	if (not actor.isPlayer) then
		self.airsoftCTFAIBase:CreateAIHandler(actor)
	end
end

function LQS_AirsoftCTF:OnActorHit(actor, sourceActor)
	-- Drop the flag if the actor has it
	local isHoldingFlag, flagHeld = self:IsHoldingFlag(actor)
	if (isHoldingFlag) then
		flagHeld:TakeDropFlag(true)
	end

	-- Remove AI handler
	if (not actor.isPlayer) then
		self.airsoftCTFAIBase:RemoveAIHandler(actor)
	end

	-- Return to base
	local availablePoints = {self:GetTeamBase(actor.team)}
	self.airsoftBase:ManageHitActor(actor, false, availablePoints)
end

function LQS_AirsoftCTF:IsHoldingFlag(actor)
	-- Checks if the given actor is holding a flag, if true it returns a bool and the flag
	-- that the actor is holding
	local targetHolder = self.teamAFlagHolder
	local targetFlag = self.teamAFlag
	for i = 1, 2 do
		if (actor == targetHolder) then
			return true, targetFlag
		end

		targetHolder = self.teamBFlagHolder
		targetFlag = self.teamBFlag
	end
	return false
end

function LQS_AirsoftCTF:OnDeploy()
	-- Deploys all available actors
	if (self.alreadyDeployed) then return end

	-- Deploy base
	for _,actor in pairs(self.allActors) do
		-- Get spawnpoint for this actor
		local targetSpawnPoint = nil
		if (actor.team == Team.Blue) then
			-- Falcons
			targetSpawnPoint = self.teamABase.spawnPosition
			self.teamAActors[#self.teamAActors+1] = actor
		elseif (actor.team == Team.Red) then
			-- Magpies
			targetSpawnPoint = self.teamBBase.spawnPosition
			self.teamBActors[#self.teamBActors+1] = actor 
		end

		-- Finalize
		if (targetSpawnPoint) then
			-- Spawn
			actor.SpawnAt(targetSpawnPoint, Quaternion.identity)

			-- Only can be called if the actor is not a player
			if (not actor.isPlayer) then
				-- Add squad so they don't stay there like idiots
				Squad.Create({actor})

				-- Assign AI objective
				-- Quite different than the raid gamemode
				self.airsoftCTFAIBase:CreateAIHandler(actor)
			end
		end
	end

	-- Close UI
	SpawnUi.Close()

	-- Finalize
	self.alreadyDeployed = true
end

function LQS_AirsoftCTF:OnFlagReturned(returnedFlag, wasCaptured)
	-- Do stuff when a flag was returned
	-- Similar thing below but everyone decides if they should defend or attack
	self.airsoftCTFAIBase:SetTeamDefendOrAttack(self.teamAActors, math.random(3, 4), {self.teamAFlagHolder})
	self.airsoftCTFAIBase:SetTeamDefendOrAttack(self.teamBActors, math.random(3, 4), {self.teamBFlagHolder})
end

function LQS_AirsoftCTF:OnFlagCaptured(capturedFlag, capturerFlag, capturerActor)
	-- Do stuff when a flag was captured
	-- Remove flag holder
	if (capturedFlag.ownerTeamID == "TeamA") then
		-- TeamA
		self.teamAFlagHolder = nil
	elseif (capturedFlag.ownerTeamID == "TeamB") then
		-- TeamB
		self.teamBFlagHolder = nil
	end

	-- Decided whether if some actors in that should defend or attack
	self.airsoftCTFAIBase:SetTeamDefendOrAttack(self.teamAActors, math.random(3, 4), {capturerActor, self.teamAFlagHolder})
	self.airsoftCTFAIBase:SetTeamDefendOrAttack(self.teamBActors, math.random(3, 4), {capturerActor, self.teamBFlagHolder})

	-- Tell the capturerActor to take a rest (defend)
	self.airsoftCTFAIBase:ChangeState(capturerActor, 2)
end

function LQS_AirsoftCTF:OnFlagTaken(takenFlag, takerActor)
	-- Do stuff when a flag is taken
	local targetReturnTeam = nil
	local targetProtectTeam = nil

	if (takenFlag.ownerTeamID == "TeamA") then
		-- TeamA Flag
		self.teamAFlagHolder = takerActor

		targetReturnTeam = self.teamAActors
		targetProtectTeam = self.teamBActors
	elseif (takenFlag.ownerTeamID == "TeamB") then
		-- TeamB Flag
		self.teamBFlagHolder = takerActor

		targetReturnTeam = self.teamBActors
		targetProtectTeam = self.teamAActors
	end

	-- Set actors actions
	if (targetReturnTeam and targetProtectTeam) then
		-- Set team actions and tell the taker actor to capture the flag
		self:SetTeamActions(targetReturnTeam, targetProtectTeam, 3, 5, takerActor.transform.position, {self.teamAFlagHolder, self.teamBFlagHolder})
		self.airsoftCTFAIBase:ChangeState(takerActor, 4)
	end
end

function LQS_AirsoftCTF:OnFlagDropped(droppedFlag)
	-- Do stuff when a flag is dropped
	local targetReturnTeam = nil
	local targetTakeTeam = nil

	if (droppedFlag.ownerTeamID == "TeamA") then
		-- TeamA Flag
		self.teamAFlagHolder = nil

		targetReturnTeam = self.teamAActors
		targetTakeTeam = self.teamBActors
	elseif (droppedFlag.ownerTeamID == "TeamB") then
		-- TeamB Flag
		self.teamBFlagHolder = nil

		targetReturnTeam = self.teamBActors
		targetTakeTeam = self.teamAActors
	end

	-- Set actors actions
	if (targetReturnTeam and targetTakeTeam) then
		self:SetTeamActions(targetReturnTeam, targetTakeTeam, 3, 1, droppedFlag.transform.position, {self.teamAFlagHolder, self.teamBFlagHolder})
	end
end

function LQS_AirsoftCTF:SetTeamActions(firstTeam, secondTeam, firstTeamAct, secondTeamAct, signalPos, excludedActors)
	-- Sets the state of the list of actor on teams to their target state or choose whether to defend or attack (I'm braindead)
	local targetTeam = firstTeam
	local targetAction = firstTeamAct
	for i = 1, 2 do
		-- Set action
		self.airsoftCTFAIBase:SetGroupStateIndex(targetAction, signalPos, targetTeam, excludedActors)

		-- Set next
		targetTeam = secondTeam
		targetAction = secondTeamAct
	end
end

function LQS_AirsoftCTF:SetupBases()
	-- Sets up the bases for the teams and flags
	-- Get all the capture points dotted around the map
	local capturePoints = ActorManager.capturePoints

	-- Choose a random point for the team A and get the furthest point for team B
	-- Similar on how the raid gamemode gets the furthest point
	self.teamABase = capturePoints[math.random(#capturePoints)]
	self.teamBBase = self:GetXPoint(true, self.teamABase, capturePoints, {self.teamABase})

	-- Instantiate flag objs and apply properties
	local targetBase = self.teamABase
	local targetTeam = Team.Blue
	local targetTeamID = "TeamA"
	for i = 1, 2 do
		-- Instantiate flag
		local newFlag = GameObject.Instantiate(self.flagCTF, targetBase.transform.position, targetBase.transform.rotation).GetComponent(ScriptedBehaviour).self

		-- Apply properties
		newFlag.assignedPoint = targetBase
		newFlag.ownerTeam = targetTeam
		newFlag.ownerTeamID = targetTeamID

		-- Add listener
		newFlag:ManageListeners(false, "onTaken", "[LQS:SA]CTF", self.onFlagTaken)
		newFlag:ManageListeners(false, "onDropped", "[LQS:SA]CTF", self.onFlagDropped)
		newFlag:ManageListeners(false, "onReturned", "[LQS:SA]CTF", self.onFlagReturned)
		newFlag:ManageListeners(false, "onCaptured", "[LQS:SA]CTF", self.onFlagCaptured)

		-- Set team flag
		if (i == 1) then
			self.teamAFlag = newFlag
		elseif (i == 2) then
			self.teamBFlag = newFlag
		end

		-- Set next flag
		targetBase = self.teamBBase
		targetTeam = Team.Red
		targetTeamID = "TeamB"
	end

	-- Disable default flags
	for _,flag in pairs(capturePoints) do
		flag.gameObject.SetActive(false)
	end
end

function LQS_AirsoftCTF:SetupTeams()
	-- Sets up the teams, similar way how Raid gamemode sets up teams
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
	end

	-- Finalize
	self.allActors = actorsToSpawn
end

function LQS_AirsoftCTF:RemoveActorLeaderboardContent(removedActors)
	return function()
		-- This simply just removes the leaderboard content of the given actors
		coroutine.yield(WaitForSeconds(0.1))
		for _,xActor in pairs(removedActors) do
			xActor.Deactivate()
			self.airsoftHUDBase.leaderboardBase:RemoveLeaderboardContent(xActor)
		end
	end
end

function LQS_AirsoftCTF:GetMissingActorsCount(array, count)
	-- Gets the number of missing actors in the given team
	local output = 0
	for i = 1, count do
		if (not array[i]) then
			output = output + 1
		end
	end
	return output
end

function LQS_AirsoftCTF:GetFlag(team, getOpposing)
	-- Gets the opposing or the given team's flag
	if (not getOpposing) then
		-- Get team flag
		if (team == Team.Blue) then
			return self.teamAFlag
		elseif (team == Team.Red) then
			return self.teamBFlag
		end
	else
		-- Get opposing
		if (team == Team.Blue) then
			return self.teamBFlag
		elseif (team == Team.Red) then
			return self.teamAFlag
		end
	end
	return nil
end

function LQS_AirsoftCTF:GetTeamBase(team)
	-- Gets the base of the given team
	if (team == Team.Blue) then
		return self.teamABase
	elseif (team == Team.Red) then
		return self.teamBBase
	end
	return nil
end

function LQS_AirsoftCTF:CanCaptureFlag(capturer)
	-- Checks if the given actor has a opposing flag to capture
	-- Returns the captured flag if true
	local targetHolder = self.teamAFlagHolder
	local targetFlag = self.teamAFlag
	for i = 1, 2 do
		if (capturer == targetHolder) then
			return true, targetFlag
		end

		targetHolder = self.teamBFlagHolder
		targetFlag = self.teamBFlag
	end
	return false
end

function LQS_AirsoftCTF:GetXPoint(nearest, targetPoint, points, excludedPoints)
	-- Copy pasted from the raid base script
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

function LQS_AirsoftCTF:IsExcludedPoint(point, excludedPoints)
	-- Checks if the given point is a part of the exludedPoints array
	if (not excludedPoints) then return false end

	for _,exPoint in pairs(excludedPoints) do
		if (point == exPoint) then
			return true
		end
	end
	return false
end
