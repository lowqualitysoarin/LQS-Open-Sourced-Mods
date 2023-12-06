-- low_quality_soarin © 2023-2024
-- Eagle Custom AI for the Raid gamemode, its originally made for a coroutine but that shit is soo ineffective and buggy
behaviour("LQS_AirsoftEagleDefenderAI")

function LQS_AirsoftEagleDefenderAI:Awake()
	-- Vars
	-- AI Main
	self.airsoftRaidAIBase = nil

	self.actor = nil
	self.enemyPurpleGuy = nil

	self.aiIndex = nil
	self.actorController = nil

	self.targetDestination, self.previousPoint = Vector3.zero, nil
	self.prevTargetDest = Vector3.zero
	self.lastEnemyPos = Vector3.zero

	self.aiStateIndex = 1

	-- Action Vars
	self.newDestTimer = 0
	self.newDestTime = 5

	self.guardTimer = 0
	self.guardTime = 25
	self.newGuardDestTimer = 0
	self.newGuardDestTime = 5
	self.guardRange = 10
	self.guardChance = 25

	self.searchTimer = 0
	self.searchTime = 20
	self.searchNewDestTimer = 0
	self.searchNewDestTime = 5
	self.searchRange = 15

	self.quickStepTimer = 0
	self.quickStepTime = 0.6
	self.quickStepRange = 8

	self.loseTimer = 0
	self.loseTime = 10
	self.catchUpChance = 75

	self.destinationThreshold = 2.5

	-- Action Bools
	self.alreadyCalledNewDest = false

	self.alreadyDecidedChase = false
	self.quickStepTimerRunning = false

	self.alreadyCalledNewSearchDest = false
	self.alreadyCalledNewGuardDest = false

	self.alreadyCalledGoTo = false
	self.setSearchWhenReached = false

	self.canSeeAEnemy = false
	self.alreadyTriggeredOnSpotEvent = false
	self.alreadyTriggeredOnLoseEvent = true

	-- State Functions
	-- These are functions that modifies the actor's behavior
	-- Wander
	self.wanderResetVars = function()
		self.newDestTimer = 0
		self.alreadyCalledNewDest = false
	end

	self.wander = function()
		self:Wander()
	end

	-- Guard
	self.guardResetVars = function()
		self.guardTimer = 0
		self.newGuardDestTimer = 0
		self.alreadyCalledNewGuardDest = false
	end

	self.guard = function()
		self:Guard()
	end

	-- Engage
	self.engageResetVars = function()
		self.quickStepTimer = 0
	end

	self.engage = function()
		self:Engage()
	end

	-- Alerted
	self.alertedResetVars = function()
		self.loseTimer = 0
		self.alreadyDecidedChase = false
	end

	self.alerted = function()
		self:Alerted()
	end

	-- Search
	self.searchResetVars = function()
		self.searchTimer = 0
		self.searchNewDestTimer = 0
		self.alreadyCalledNewSearchDest = false
	end

	self.search = function()
		self:Search()
	end

	-- Extract
	self.extractResetVars = function()
		self.prevTargetDest = Vector3.zero
	end

	self.extract = function()
		self:Extract()
	end

	-- Idle
	self.idle = function()
		self:Idle()
	end

	-- Go To
	self.goToResetVars = function()
		self.alreadyCalledGoTo = false
		self.setSearchWhenReached = false
		self.destinationThreshold = 2.5
	end

	self.goTo = function()
		self:GoTo()
	end

	-- State Machine
	-- Since there is no IEnumerator in ravenscript
	-- Format: {"AIStateName", {AIStateFunction, AIStateFunctionVarResetter}}
	self.aiStates = {
		{"Wander", {self.wander, self.wanderResetVars}},
		{"Guard", {self.guard, self.guardResetVars}},
		{"Engage", {self.engage, self.engageResetVars}},
		{"Alerted", {self.alerted, self.alertedResetVars}},
		{"Search", {self.search, self.searchResetVars}},
		{"Extract", {self.extract, self.extractResetVars}},
		{"Idle", {self.idle, nil}},
		{"GoTo", {self.goTo, self.goToResetVars}}
	}

	self.currentState = self.aiStates[self.aiStateIndex][1]

	-- Handler Vars
	self.alreadyRanHandler = false
end

function LQS_AirsoftEagleDefenderAI:StartAI(raidAIBase, aiIndex, actor, previousPoint, enemy)
	-- Sets up and starts the AI handler for this actor
	-- Set up the important vars
	self.airsoftRaidAIBase = raidAIBase.self

	self.actor = actor
	self.enemyPurpleGuy = enemy
	self.aiIndex = aiIndex

	self.actorController = self.actor.aiController
	self.actorController.skillLevel = SkillLevel.Veteran
	self.actorSquad = self.actor.squad

	self.previousPoint = previousPoint

	-- Finalize
	self.actorController.canJoinPlayerSquad = false
	self.actorController.OverrideDefaultMovement()
	self.targetDestination, self.previousPoint = self:GetNewDestination(self.previousPoint)

	-- Set weapon difficulty
	self.airsoftRaidAIBase:SetWeaponLoadoutDifficulty(self.actor, Difficulty.Challenging, {self.enemyPurpleGuy}, Effectiveness.Preferred, true)

	-- Run the handler coroutine
	if (not self.alreadyRanHandler) then
		self.airsoftRaidAIBase:StartAIHandler(self.actor)
		self.alreadyRanHandler = true
	end
end

function LQS_AirsoftEagleDefenderAI:GoTo()
	-- Set the goTo destination
	if (not self.alreadyCalledGoTo) then
		self:SetDestination(self.targetDestination)
		self.alreadyCalledGoTo = true
	end

	-- Gets the actor to the given goToPos and returns back to the wander or search state when it gets there
	local distance = Vector3.Distance(self.targetDestination, self.actor.transform.position)
	if (distance < self.destinationThreshold) then
		local targetState = 1
		if (self.setSearchWhenReached) then
			targetState = 5
		end
		self:ChangeState(self.goToResetVars, 1)
	end

	-- The vision system
	if (self.canSeeAEnemy) then
		self:ChangeState(self.goToResetVars, 3)
	end
end

function LQS_AirsoftEagleDefenderAI:Idle()
	-- This basically just makes the actor stay in place, nothing at all
	self.targetDestination = self.actor.transform.position
	if (self.targetDestination ~= self.prevTargetDest) then
		self:SetDestination(self.targetDestination)
		self.prevTargetDest = self.targetDestination
	end
end

function LQS_AirsoftEagleDefenderAI:Extract()
	-- Run back to the main spawn, because that is treated as a extraction point
	-- Get extraction point pos
	local destination = self.airsoftRaidAIBase.airsoftRaidBase.eagleSpawnMain.transform.position

	-- Track distance
	local distToTargetExtract = Vector3.Distance(self.airsoftRaidAIBase.airsoftRaidBase.eagleSpawnMain.transform.position, self.actor.transform.position)
	if (distToTargetExtract < 4) then
		if (self.canSeeAEnemy) then
			-- Quickstep if the purple guy is in sight
			local distToEnemy = Vector3.Distance(self.enemyPurpleGuy.transform.position, self.actor.transform.position)
			if (distToEnemy < 35) then
				self.quickStepTimer = self.quickStepTimer + 1 * Time.deltaTime
				if (self.quickStepTimer >= self.quickStepTime) then
					destination = self.airsoftRaidAIBase:GetRandomPointInRange(self.actor.transform.position, self.quickStepRange)
					self.quickStepTimer = 0
				end
			end
		else
			-- Stay put
		    destination = self.actor.transform.position
		end
	end

	-- Go to given destination
	self.targetDestination = destination
	if (self.targetDestination ~= self.prevTargetDest) then
		self:SetDestination(self.targetDestination)
		self.prevTargetDest = self.targetDestination
	end
end

function LQS_AirsoftEagleDefenderAI:Search()
	-- Get the distance between the actor and the destination
	local distance = Vector3.Distance(self.targetDestination, self.actor.transform.position)

	-- Search for the purple guy
	-- If the actor reaches it's destination then get a new search point
	if (distance < 2.5 and self.alreadyCalledNewSearchDest) then
		self:SetDestination(self.actor.transform.position)
		self.alreadyCalledNewSearchDest = false
	end

	-- Search around the area where the purple guy was last found
	if (not self.alreadyCalledNewSearchDest) then
		self.searchNewDestTimer = self.searchNewDestTimer + 1 * Time.deltaTime
		if (self.searchNewDestTimer >= self.searchNewDestTime) then
			-- Get a new search destination
	        self.targetDestination = self.airsoftRaidAIBase:GetRandomPointInRange(self.lastEnemyPos, self.searchRange)
	        self:SetDestination(self.targetDestination)

			self.searchNewDestTimer = 0
	        self.alreadyCalledNewSearchDest = true
		end
	end
	
	-- Search timer
	-- If the timer reaches the max time, then it will return to the wandering state
	self.searchTimer = self.searchTimer + 1  * Time.deltaTime
	if (self.searchTimer >= self.searchTime) then
		self:ChangeState(self.searchResetVars, 1)
	end

	-- The vision system
	-- When it spots the purple guy again then set it to engage state
	if (self.canSeeAEnemy) then
		self:ChangeState(self.searchResetVars, 3)
	end
end

function LQS_AirsoftEagleDefenderAI:Alerted()
	-- If the actor loses it's sight to on the purple guy then get it's last position or just stay put
	if (not self.alreadyDecidedChase) then
		self.targetDestination = self.actor.transform.position
		if (self.airsoftRaidAIBase:LuckSystem(self.catchUpChance)) then
			-- If the luck system is true then catch up
			self.targetDestination = self.lastEnemyPos
		end
		
		-- Set the destintion, then tick the alreadyDecidedChase bool to true soo it won't get executed again
		self:SetDestination(self.targetDestination)
		self.alreadyDecidedChase = true
	end
	
	-- Start lose timer
	-- If the timer hits loseTime then start the searching phase
	self.loseTimer = self.loseTimer + 1 * Time.deltaTime
	if (self.loseTimer >= self.loseTime) then
		self:ChangeState(self.alertedResetVars, 5)
	end

	-- The vision system, already know what does this do
	if (self.canSeeAEnemy) then
		self:ChangeState(self.alertedResetVars, 3)
	end
end

function LQS_AirsoftEagleDefenderAI:Engage()
	-- Keep track of the purple guy's position
	self.lastEnemyPos = self.enemyPurpleGuy.transform.position
	local distToEnemy = Vector3.Distance(self.lastEnemyPos, self.actor.transform.position)

	-- Attack the purple guy for what he did back in 87
	-- Quick step like Goro Majima, when nearby the enemy
	if (distToEnemy < 35) then
		self.quickStepTimer = self.quickStepTimer + 1 * Time.deltaTime
		if (self.quickStepTimer >= self.quickStepTime) then
	        self.targetDestination = self.airsoftRaidAIBase:GetRandomPointInRange(self.actor.transform.position, self.quickStepRange)
	        self:SetDestination(self.targetDestination)
			self.quickStepTimer = 0
		end
	end

	-- The vision system, again...
	if (not self.canSeeAEnemy) then
		self:ChangeState(self.engageResetVars, 4)
	end
end

function LQS_AirsoftEagleDefenderAI:Guard()
	-- Keep guarding or there will be a hole in the paycheck
	local distance = Vector3.Distance(self.targetDestination, self.actor.transform.position)

	-- New point when guard point is reached
	if (distance < 2.5 and self.alreadyCalledNewGuardDest) then
		self:SetDestination(self.actor.transform.position)
		self.alreadyCalledNewGuardDest = false
	end

	-- Set new guard point
	if (not self.alreadyCalledNewGuardDest) then
		self.newGuardDestTimer = self.newGuardDestTimer + 1 * Time.deltaTime
		if (self.newGuardDestTimer >= self.newGuardDestTime) then
			-- Get new destination
	        self.targetDestination = self.airsoftRaidAIBase:GetRandomPointInRange(self.actor.transform.position, self.guardRange)
	        self:SetDestination(self.targetDestination)
        
			self.newGuardDestTimer = 0
	        self.alreadyCalledNewGuardDest = true
		end
	end

	-- The vision system, guards needs eyes
	-- If the actor spots the purple guy then engage, what the fuck else??
	if (self.canSeeAEnemy) then
		self:ChangeState(self.guardResetVars, 3)
	end

	-- The guard timer, if the times up then return to the wander state
	self.guardTimer = self.guardTimer + 1 * Time.deltaTime
	if (self.guardTimer >= self.guardTime) then
		self:ChangeState(self.guardResetVars, 1)
	end
end

function LQS_AirsoftEagleDefenderAI:Wander()
	-- Get the distance between the actor and the destination
	local distance = Vector3.Distance(self.targetDestination, self.actor.transform.position)

	-- If the actor has reached it's destination then get a new destination
	if (distance < 2.5 and self.alreadyCalledNewDest) then
		-- Stay put at this destination
		self:SetDestination(self.actor.transform.position)
		self.alreadyCalledNewDest = false
	end

	-- New destination timer, or guard timer
	-- It hurts to use a timer like this again...
	if (not self.alreadyCalledNewDest) then
		self.newDestTimer = self.newDestTimer + 1 * Time.deltaTime
		if (self.newDestTimer >= self.newDestTime) then
			-- Decide if the actor should guard or keep wandering
	        if (self.airsoftRaidAIBase:LuckSystem(self.guardChance)) then
	        	-- Guard
	        	self:ChangeState(self.wanderResetVars, 2)
	        else
	        	-- Keep wandering
	        	self.targetDestination, self.previousPoint = self:GetNewDestination(self.previousPoint)
	        	self:SetDestination(self.targetDestination)
	        end
        
			self.newDestTimer = 0
	        self.alreadyCalledNewDest = true
		end
	end

	-- The vision system, when it spots the purple guy it will automatically set the state to (engage)
	if (self.canSeeAEnemy) then
		self:ChangeState(self.wanderResetVars, 3)
	end
end

function LQS_AirsoftEagleDefenderAI:GetNewDestination(previousPoint)
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

function LQS_AirsoftEagleDefenderAI:GoToDestination(destination, destinationThreshold, setSearchWhenReached)
	-- Makes this actor go to the given destination
	self.targetDestination = destination
	self.lastEnemyPos = destination
	self.setSearchWhenReached = setSearchWhenReached
	self.destinationThreshold = destinationThreshold
	self:ChangeState(nil, 8)
end

function LQS_AirsoftEagleDefenderAI:SetDestination(destination)
	-- Sets the destination of the given actor
	self.actorController.Goto(destination)
end

function LQS_AirsoftEagleDefenderAI:ChangeState(funcResetVar, newState)
	-- Changes the handler state of this actor
	-- Reset vars used by the previous state
	if (funcResetVar) then
		funcResetVar()
	end

	-- Change the state
	self.aiStateIndex = newState
end
