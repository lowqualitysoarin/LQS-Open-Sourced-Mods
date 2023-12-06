behaviour("LQS_RaidAIHandler")

function LQS_RaidAIHandler:Awake()
	-- Base
	-- Handler Triggers
	self.startHandlerDefender = function(actor, spawnedPoint)
		print("<color=blue>Defender</color> AI Started for", actor.name)
		self.script.StartCoroutine(self:StartHandlerDefender(actor, spawnedPoint))
	end

	self.startHandlerPurpleGuy = function(actor, spawnedPoint)
		print("<color=purple>Purple Guy</color> AI Started for", actor.name)
	end
end

function LQS_RaidAIHandler:Start()
	-- Vars
	self.airsoftRaidBase = nil
	self.airsoftRaidAIBase = nil

	-- Override state data
	-- Format: {"TargetState", Actor, {Parameters}}
	self.overrideStateDataDefender = {}
	self.overrideStateDataPurpleMerc = {}

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())
end

function LQS_RaidAIHandler:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0.02))

		-- Get the raid AI base
		local raidAIBase = _G.LQSSoarinsAirsoftRaidAIBase
		if (raidAIBase) then
			self.airsoftRaidAIBase = raidAIBase.self
			self.airsoftRaidBase = self.airsoftRaidAIBase.airsoftRaidBase
		end
	end
end

function LQS_RaidAIHandler:OverrideHandlerState(state, actorFilter, parameters, teamFilter)
	-- Overrides the state of the given actor or the actors in a team
	if (teamFilter == Team.Blue) then
		-- Eagles
		local nextTableCount = #self.overrideStateDataDefender+1
		self.overrideStateDataDefender[nextTableCount] = {state, actorFilter, parameters}
	else
		-- Purple Mercs
		self.overrideStateDataPurpleMerc = {state, actorFilter, parameters}
	end
end

function LQS_RaidAIHandler:StartHandlerDefender(actor, spawnedPoint)
	return function()
		-- The Main AI Handler for the defenders, it will automatically stop if the given actor isn't in the actorHandlerArray anymore
		-- Start (Handler)
		local aiBehaviour, aiIndex = self.airsoftRaidAIBase:GetActorHandler(actor)
		local enemyPurpleGuy = self.airsoftRaidBase.purpleGuy
		local aiStateIndex = 1

		-- AI controller and Squad
		local actorController = actor.aiController
		local actorSquad = actor.squad

		-- Vars
		local targetDestination, previousPoint = Vector3.zero, spawnedPoint
		local lastEnemyPos = Vector3.zero
		local goToPos = Vector3.zero

		local newDestTimer = 0
		local newDestTime = 5

		local guardTimer = 0
		local guardTime = 35
		local guardNewDestTimer = 0
		local guardNewDestTime = 5
		local guardRange = 10
		local guardChance = 35
		
		local searchTimer = 0
		local searchTime = 30
		local searchNewDestTimer = 0
		local searchNewDestTime = 5
		local searchRange = 15

		local quickStepTimer = 0
		local quickStepTime = 0.6
		local quickStepRange = 8

		local loseTimer = 0
		local loseTime = 20
		local catchUpChance = 75

		local alreadyCalledNewDest = false
		local alreadyDecidedChase = false
		local alreadyCalledNewSearchDest = false
		local alreadyCalledNewGuardDest = false
		local alreadyCalledGoTo = false

	    -- States functions
	    -- Functions that gets called once the coroutine hits the while .. do loop, it depends on the state of the ai

		-- Wander
		local wanderResetVars = function()
			newDestTimer = 0
			alreadyCalledNewDest = false
		end

	    local wander = function()
			-- Get the distance between the actor and the destination
			local distance = Vector3.Distance(targetDestination, actor.transform.position)

			-- The vision system, when it spots the purple guy it will automatically set the state to (engage)
			if (ActorManager.ActorsCanSeeEachOther(actor, enemyPurpleGuy)) then
				wanderResetVars()
				aiStateIndex = 3
			end

			-- If the actor has reached it's destination then get a new destination
			if (distance < 2.5 and alreadyCalledNewDest) then
				-- Stay put at this destination
				self:SetDestination(actorController, actor.transform.position)
				alreadyCalledNewDest = false
			end

			-- New destination timer, or guard timer
			-- It hurts to use a timer like this again...
	    	if (not alreadyCalledNewDest) then
				newDestTimer = newDestTimer + 1 * Time.deltaTime
				if (newDestTimer >= newDestTime) then
					-- Decide if the actor should guard or keep wandering
					if (self:LuckSystem(guardChance)) then
						-- Guard
						wanderResetVars()
						aiStateIndex = 2
					else
						-- Keep wandering
						targetDestination, previousPoint = self:GetNewDestination(previousPoint)
					    self:SetDestination(actorController, targetDestination)
					end

					-- Reset vars
					newDestTimer = 0
					alreadyCalledNewDest = true
				end
			end
	    end
    
	    -- Guard
		local guardResetVars = function()
			guardTimer = 0
			guardNewDestTimer = 0
			alreadyCalledNewGuardDest = false
		end

		local guard = function()
			-- The vision system, guards needs eyes
			-- If the actor spots the purple guy then engage, what the fuck else??
			if (ActorManager.ActorsCanSeeEachOther(actor, enemyPurpleGuy)) then
				guardResetVars()
				aiStateIndex = 3
			end

			-- Keep guarding or there will be a hole in the paycheck
			local distance = Vector3.Distance(targetDestination, actor.transform.position)

			-- New point when guard point is reached
			if (distance < 2.5 and alreadyCalledNewGuardDest) then
				self:SetDestination(actorController, actor.transform.position)
				alreadyCalledNewGuardDest = false
			end

			-- Set new guard point
			if (not alreadyCalledNewGuardDest) then
				guardNewDestTimer = guardNewDestTimer + 1 * Time.deltaTime
				if (guardNewDestTimer >= guardNewDestTime) then
					-- Get new destination
					targetDestination = self:GetRandomPointInRange(actor.transform.position, guardRange)
					self:SetDestination(actorController, targetDestination)

					-- Reset vars
					guardNewDestTimer = 0
					alreadyCalledNewGuardDest = true
				end
			end

			-- The guard timer, if the times up then return to the wander state
			guardTimer = guardTimer + 1 * Time.deltaTime
			if (guardTimer >= guardTime) then
				guardResetVars()
				aiStateIndex = 1
			end
		end
    
	    -- Engage
		local engageResetVars = function(ignoreOthers)
			loseTimer = 0
			alreadyDecidedChase = false

			if (not ignoreOthers) then
				quickStepTimer = 0
			end
		end

		local engage = function()
			-- The vision system, already know what does this do
			if (not ActorManager.ActorsCanSeeEachOther(actor, enemyPurpleGuy)) then
				-- If the actor loses it's sight to on the purple guy then get it's last position or just stay put
				if (not alreadyDecidedChase) then
					targetDestination = actor.transform.position
					if (self:LuckSystem(catchUpChance)) then
						-- If the luck system is true then catch up
						targetDestination = lastEnemyPos
					end
					
					-- Set the destintion, then tick the alreadyDecidedChase bool to true soo it won't get executed again
					self:SetDestination(actorController, targetDestination)
					alreadyDecidedChase = true
				end
				
				-- Start lose timer
				-- If the timer hits loseTime then start the searching phase
				loseTimer = loseTimer + 1 * Time.deltaTime
				if (loseTimer >= loseTime) then
					-- Reset vars and switch state
					engageResetVars()
					aiStateIndex = 4
				end
			else
				-- Keep track of the purple guy's position
				lastEnemyPos = enemyPurpleGuy.transform.position
				local distToEnemy = Vector3.Distance(lastEnemyPos, actor.transform.position)

				-- Attack the purple guy for what he did back in 87
				-- Set attack target
				actorSquad.attackTarget = enemyPurpleGuy

				-- Quick step like Goro Majima, when nearby the enemy
				if (distToEnemy < 35) then
					quickStepTimer = quickStepTimer + 1 * Time.deltaTime
					if (quickStepTimer >= quickStepTime) then
						targetDestination = self:GetRandomPointInRange(actor.transform.position, quickStepRange)
						self:SetDestination(actorController, targetDestination)
						quickStepTimer = 0
					end
				end

				-- Reset vars
				engageResetVars(true)
			end
		end
    
	    -- Search
		local searchResetVars = function()
			searchTimer = 0
			alreadyCalledNewSearchDest = false
		end

		local search = function()
			-- The vision system
			-- When it spots the purple guy again then set it to engage state
			if (ActorManager.ActorsCanSeeEachOther(actor, enemyPurpleGuy)) then
				searchResetVars()
				aiStateIndex = 3
			end

			-- Get the distance between the actor and the destination
			local distance = Vector3.Distance(targetDestination, actor.transform.position)

			-- Search for the purple guy
			-- If the actor reaches it's destination then get a new search point
			if (distance < 2.5 and alreadyCalledNewSearchDest) then
				self:SetDestination(actorController, actor.transform.position)
				alreadyCalledNewSearchDest = false
			end

			-- Search around the area where the purple guy was last found
			if (not alreadyCalledNewSearchDest) then
				searchNewDestTimer = searchNewDestTimer + 1 * Time.deltaTime
				if (searchNewDestTimer >= searchNewDestTime) then
					targetDestination = self:GetRandomPointInRange(lastEnemyPos, searchRange)
					self:SetDestination(actorController, targetDestination)

					alreadyCalledNewSearchDest = true
					searchNewDestTimer = 0
				end
			end
			
			-- Search timer
			-- If the timer reaches the max time, then it will return to the wandering state
			searchTimer = searchTimer + 1 * Time.deltaTime
			if (searchTimer >= searchTime) then
				-- Reset vars and switch to wander state
				searchResetVars()
				aiStateIndex = 1
			end
		end

		-- Go to
		local goToResetVars = function()
			alreadyCalledGoTo = false
		end

		local goTo = function(parameters)
			-- The vision system
			if (ActorManager.ActorsCanSeeEachOther(actor, enemyPurpleGuy)) then
				goToResetVars()
				aiStateIndex = 3
			end

			-- Set the goTo destination
			if (not alreadyCalledGoTo) then
				goToPos = parameters[1]
				targetDestination = goToPos
				self:SetDestination(actorController, targetDestination)
				alreadyCalledGoTo = true
			end

			-- Gets the actor to the given goToPos and returns back to the wander state when it gets there
			local distance = Vector3.Distance(targetDestination, actor.transform.position)
			if (distance < 2.5) then
				goToResetVars()
				aiStateIndex = 1
			end
		end

	    -- State machine
	    -- Since there is no IEnumerator in ravenscript
		-- Format: {"AIStateName", {AIStateFunction, AIStateFunctionVarResetter}}
	    local aiStates = {
	    	{"Wander", {wander, wanderResetVars}},
	    	{"Guard", {guard, guardResetVars}},
	    	{"Engage", {engage, engageResetVars}},
	    	{"Search", {search, searchResetVars}},
			{"GoTo", {goTo, nil}}
	    }

		local currentState = aiStates[aiStateIndex][1]
		local stateParameters = {}

		-- Override State
		-- This overrides the actor's current state with to a given state
		local overrideCurrentState = function()
			local overrideStateData, overrideStateIndex = self:GetOverrideStateData(actor)
			if (overrideStateData) then
				if (overrideStateData[2] == actor) then
					-- Reset the vars of the current state before switching 
					local prevStateData = aiStates[aiStateIndex]
					if (prevStateData[2][2]) then
						prevStateData[2][2]()
					end

					-- Get the given override state and apply that state
					stateParameters = overrideStateData[3]
					aiStateIndex = self:GetStateIndex(overrideStateData[1], aiStates)

					-- Clear the overrideStateData
					self.overrideStateDataDefender[overrideStateIndex] = nil
				end
			end
		end

		-- Finalize (Handler)
		actorController.canJoinPlayerSquad = false
		actorController.OverrideDefaultMovement()
		targetDestination, previousPoint = self:GetNewDestination(previousPoint)

		-- Update (Handler)
		-- This is gonna fucking suck
		while (self.airsoftRaidAIBase.actorHandlerArray[aiIndex]) do
			-- Handle the given state
			-- The functions can only change the current state
			local currentStateData = aiStates[aiStateIndex]

			currentState = currentStateData[1]
			currentStateData[2][1](stateParameters)

			print(currentState)

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		print("Stopped AI handler on", actor)
		actorController.ReleaseDefaultMovementOverride()
	end
end

function LQS_RaidAIHandler:GetOverrideStateData(actor)
	-- Gets the override state data and the index, only for defenders
	for overrideStateIndex,overrideStateData in pairs(self.overrideStateDataDefender) do
		if (overrideStateData[2] == actor) then
			return overrideStateData, overrideStateIndex
		end
	end
	return nil, nil
end

function LQS_RaidAIHandler:GetStateIndex(targetState, aiStates)
	-- Gets the state index from the give aiStates array
	for stateIndex,stateData in pairs(aiStates) do
		if (stateData[1] == targetState) then
			return stateIndex
		end
	end
	return nil
end

function LQS_RaidAIHandler:GetRandomPointInRange(originPos, range)
	-- This just gets a new point within range
	-- Get random x and z, (can be scuffed)
	local randomZ = Random.Range(-range, range)
	local randomX = Random.Range(-range, range)

	local chosenPos = Vector3(
		originPos.x + randomX,
		originPos.y,
		originPos.z + randomZ
	)

	-- Snap Pos
	local ray = Ray(chosenPos + Vector3.up, Vector3.down)
	local raycastSnap = Physics.RaycastAll(ray, 2, RaycastTarget.Default)

	for _,hit in pairs(raycastSnap) do
		if (hit) then
			-- Have to check if the point is in the water level
			if (not Water.IsInWater(hit.point)) then
				return hit.point
			end
		end
	end
	return originPos
end

function LQS_RaidAIHandler:SetDestination(actorController, destination)
	-- Sets the destination of the given actor
	if (not actorController or not destination) then return end
	actorController.Goto(destination)
end

function LQS_RaidAIHandler:GetNewDestination(previousPoint)
	-- This gets a new destination for the actor
	-- Cache some available points before choosing a final one, it will exclude the previous capture point
	local availablePoints = {}
	for _,cp in pairs(ActorManager.capturePoints) do
		if (cp ~= previousPoint) then
			availablePoints[#availablePoints+1] = cp
		end
	end

	local chosenPoint = availablePoints[math.random(#availablePoints)]
	return chosenPoint.spawnPosition, chosenPoint
end

function LQS_RaidAIHandler:LuckSystem(chance)
	-- A global luck system, returns true if its lucky
	local luck = Random.Range(0, 100)
	if (luck < chance) then
		return true
	end
	return false
end
