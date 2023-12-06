-- low_quality_soarin © 2023-2024
-- The purple mercenary's AI, if the player wants to defend this time (Its gonna be awful)
behaviour("LQS_AirsoftPurpleMercAI")

function LQS_AirsoftPurpleMercAI:Awake()
	-- Vars
	-- AI Main
	self.airsoftRaidAIBase = nil

	self.actor = nil
	self.enemyInRange = {}

	self.aiIndex = nil
	self.actorController = nil
	self.actorSquad = nil

	self.targetDestination = Vector3.zero
	self.targetObjective = nil

	self.aiStateIndex = 1
	self.pathIndex = 1

	-- Action Vars
	self.forgetTimer = 0
	self.forgetTime = 10

	self.quickStepTimer = 0
	self.quickStepTime = 0.4
	self.quickStepRange = 8

	self.instinctRange = 10
	self.instinctFleeChance = 50

	self.destinationThreshold = 2.5
	self.objectivesDestroyed = 0

	self.newWanderPointTimer = 0
	self.newWanderPointTime = 60

	-- Action Bools
	self.alreadySetAttackObjective = false

	self.isAlreadySabotaging = false
	self.alreadyCalledInstinctChance = false

	self.canEngage = true
	self.alreadyCalledGoTo = false

	-- State Functions
	-- These are functions that modifies the actor's behavior
	-- Attack Objective
	self.attackObjectiveResetVars = function()
		self.alreadySetAttackObjective = false
	end

	self.attackObjective = function()
		self:AttackObjective()
	end

	-- Sabotaging
	self.sabotagingResetVars = function()
		self.isAlreadySabotaging = false
		self.alreadyCalledInstinctChance = false
	end

	self.sabotaging = function()
		self:Sabotaging()
	end

	-- Engage
	self.engageResetVars = function()
		self.quickStepTimer = 0
	end

	self.engage = function()
		self:Engage()
	end

	-- Hunt
	self.huntResetVars = function()
		self.quickStepTimer = 0
	end

	self.hunt = function()
		self:Hunt()
	end

	-- Go To
	self.goToResetVars = function()
		self.alreadyCalledGoTo = false
		self.destinationThreshold = 2.5
	end

	self.goTo = function()
		self:GoTo()
	end

	-- State Machine
	-- Since there is no IEnumerator in ravenscript
	-- Format: {"AIStateName", {AIStateFunction, AIStateFunctionVarResetter}}
	self.aiStates = {
		{"AttackObjective", {self.attackObjective, self.attackObjectiveResetVars}},
		{"Sabotaging", {self.sabotaging, self.sabotagingResetVars}},
		{"Engage", {self.engage, self.engageResetVars}},
		{"Hunt", {self.hunt, self.huntResetVars}},
		{"GoTo", {self.goTo, self.goToResetVars}}
	}

	self.currentState = self.aiStates[self.aiStateIndex][1]

	-- Handler Vars
	self.alreadyRanHandler = false
	self.prevState = nil
end

function LQS_AirsoftPurpleMercAI:StartAI(raidAIBase, aiIndex, actor)
	-- Sets up and starts the AI handler for this actor
	-- Set up the important vars
	self.airsoftRaidAIBase = raidAIBase.self
	self.actor = actor

	self.aiIndex = aiIndex
	self.actorController = self.actor.aiController
	self.actorSquad = self.actor.squad

	-- Finalize
	self.actorController.canJoinPlayerSquad = false
	self.actorController.skillLevel = SkillLevel.Elite
	self.actorController.OverrideDefaultMovement()

	-- Set weapon difficulty
	self.airsoftRaidAIBase:SetWeaponLoadoutDifficulty(self.actor, Difficulty.Easy, self.airsoftRaidAIBase.airsoftRaidBase.eagleDefenders, Effectiveness.Yes, false)

	-- Run the handler coroutine
	if (not self.alreadyRanHandler) then
		self.airsoftRaidAIBase:StartAIHandler(self.actor)
		self.alreadyRanHandler = true
	end
end

function LQS_AirsoftPurpleMercAI:GoTo()
	-- Set the goTo destination
	if (not self.alreadyCalledGoTo) then
		self:SetDestination(self.targetDestination)
		self.alreadyCalledGoTo = true
	end

	-- Gets the actor to the given goToPos, it doesn't do all of that stupid searching shit because this is the purple guy
	local distance = Vector3.Distance(self.targetDestination, self.actor.transform.position)
	if (distance < self.destinationThreshold) then
		self:ChangeState(self.goToResetVars, 1)
	end

	-- Vision system
	local canSeeAEnemy, enemyInSight = self:CanSeeEnemy()
	if (canSeeAEnemy) then
		self:ChangeState(self.goToResetVars, 2)
	end
end

function LQS_AirsoftPurpleMercAI:Hunt()
	-- This can only get called by the base script, which totally makes the purple guy go beast mode
	-- Get the nearest enemy
	local nearestEnemy = self.airsoftRaidAIBase:GetNearestActor(self.actor.transform.position, self.airsoftRaidAIBase.airsoftRaidBase.eagleDefenders)
	if (nearestEnemy) then
		-- Attack the given nearest enemy (Yeah its cheaty)
		if (ActorManager.ActorsCanSeeEachOther(self.actor, nearestEnemy)) then
			-- If this actor can see the enemy actor
			-- Set attack target
			self.actorSquad.attackTarget = nearestEnemy

			-- Quickstepping (already explained)
		    local distToEnemy = Vector3.Distance(nearestEnemy.transform.position, self.actor.transform.position)
			if (distToEnemy < 35) then
				self.quickStepTimer = self.quickStepTimer + 1 * Time.deltaTime
				if (self.quickStepTimer >= self.quickStepTime) then
					self.targetDestination = self.airsoftRaidAIBase:GetRandomPointInRange(self.actor.transform.position, self.quickStepRange)
			        self.quickStepTimer = 0
				end
			end
		else
			-- If the actor can't see the enemy actor (obviously attack it)
			-- Go to the nearest enemy's current position
		    self.targetDestination = nearestEnemy.transform.position
		end
	else
		-- Wander for a bit
		-- It will stop when it detects a active enemy
		self.newWanderPointTimer = self.newWanderPointTimer + 1 * Time.deltaTime
		if (self.newWanderPointTimer >= self.newWanderPointTime) then
			local allObjectives = self.airsoftRaidAIBase.airsoftRaidBase.allObjectives
			self.targetDestination = allObjectives[math.random(#allObjectives)].assignedPoint.transform.position
			self.newWanderPointTimer = 0
		end
	end

	-- Set destination
	local distToDestination = Vector3.Distance(self.targetDestination, self.actor.transform.position)
	if (distToDestination > 2.5) then
		self:SetDestination(self.targetDestination)
	end
end

function LQS_AirsoftPurpleMercAI:Engage()
	-- Get the current attack target of this actor
	local currentTarget = self.actorController.currentAttackTarget
	if (currentTarget) then
		-- Some trackers only for this function
		local distToEnemy = Vector3.Distance(currentTarget.transform.position, self.actor.transform.position)

		-- Quickstep like Kazuma Kiryu
		if (distToEnemy < 35) then
			self.quickStepTimer = self.quickStepTimer + 1 * Time.deltaTime
			if (self.quickStepTimer >= self.quickStepTime) then
				self.targetDestination = self.airsoftRaidAIBase:GetRandomPointInRange(self.actor.transform.position, self.quickStepRange)
			    self.quickStepTimer = 0
			end
		end
	end

	-- Vision system
	local canSeeAEnemy, enemyInSight = self:CanSeeEnemy()
	if (not canSeeAEnemy) then
		-- If the actor loses sight of the enemy then just attack another objective
		self.forgetTimer = self.forgetTimer + 1 * Time.deltaTime
		if (self.forgetTimer >= self.forgetTime) then
			self:ChangeState(self.engageResetVars, 1)
		end
	else
		-- Reset if the actor regain sight of it
		self.forgetTimer = 0

		-- Something chitty, just to make this ai quite harder (again)
		self.actorSquad.attackTarget = enemyInSight
	end

	-- Set destination
	local distToDestination = Vector3.Distance(self.targetDestination, self.actor.transform.position)
	if (distToDestination > 1) then
		self:SetDestination(self.targetDestination)
	end
end

function LQS_AirsoftPurpleMercAI:Sabotaging()
	-- Wait for the sabotage progress to be done
	if (not self.isAlreadySabotaging) then
		-- Stay put, the actor will move on its own if it feels to have danger up ahead
		self.targetDestination = self.actor.transform.position
		self:SetDestination(self.targetDestination)

		-- Start sabotaging
		self.targetObjective:TriggeredSabotageUse()

		-- Soo it won't be called again
		self.isAlreadySabotaging = true
	end

	-- When the target objective is destroyed then walk away
	if (self.targetObjective and self.targetObjective.isSabotaged) then
		self:ChangeState(self.sabotagingResetVars, 1)
	end

	-- Some chitty stuff, just to make the ai harder
	local nearestEnemy = self.airsoftRaidAIBase:GetNearestActor(self.actor.transform.position, self.airsoftRaidAIBase.airsoftRaidBase.eagleDefenders)
	if (nearestEnemy) then
		-- Instinct system
	    -- Basically a rng whether if the actor should abandon the current objective and just choose a new one
		local distToEnemy = Vector3.Distance(nearestEnemy.transform.position, self.actor.transform.position)
		if (distToEnemy < self.instinctRange and not self.alreadyCalledInstinctChance) then
			if (self.airsoftRaidAIBase:LuckSystem(self.instinctFleeChance)) then
				self.targetObjective = nil
				self:ChangeState(self.sabotagingResetVars, 1)
			end
			self.alreadyCalledInstinctChance = true
		end
	end

	-- If the actor walks away the targetObjective's range then return to it (idk)
	local distToObjective = Vector3.Distance(self.targetObjective.assignedPoint.transform.position, self.actor.transform.position)
	if (distToObjective > 5) then
		self:ChangeState(self.sabotagingResetVars, 1)
	end

	-- Vision system
	-- Cancel the sabotaging if it sees a enemy
	local canSeeAEnemy, enemyInSight = self:CanSeeEnemy()
	if (canSeeAEnemy) then
		-- Cancel sabotage and change state
		self.targetObjective:SabotageCancel()
		self:ChangeState(self.sabotagingResetVars, 3)
	end
end

function LQS_AirsoftPurpleMercAI:AttackObjective()
	-- Attack a objective
	if (not self.alreadySetAttackObjective) then
		-- Get a objective to attack
		self.targetObjective = self:GetActiveObjective(self.targetObjective)

		-- Gonna have to do a nil check here
		if (self.targetObjective) then
			-- Assign the destination of the target destination
			self.targetDestination = self.targetObjective.assignedPoint.transform.position
		    self:SetDestination(self.targetDestination)

		    self.alreadySetAttackObjective = true
		end
	else
		-- When a target objective is set then wait for the actor reach it
		local distanceToObjective = Vector3.Distance(self.targetDestination, self.actor.transform.position)
		if (distanceToObjective < 3) then
			-- When reached set the state to sabotaging state
			self:ChangeState(self.attackObjectiveResetVars, 2)
		end
	end

	-- Vision system
	local canSeeAEnemy, enemyInSight = self:CanSeeEnemy()
	if (canSeeAEnemy) then
		self:ChangeState(self.attackObjectiveResetVars, 3)
	end
end

function LQS_AirsoftPurpleMercAI:CanSeeEnemy()
	-- A cheatier version of the vision system, this basically gives them a eye behind this actor's back
	for _,actor in pairs(self.airsoftRaidAIBase.airsoftRaidBase.eagleDefenders) do
		if (ActorManager.ActorsCanSeeEachOther(self.actor, actor)) then
			if (not self.airsoftRaidAIBase.airsoftRaidBase.airsoftBase:IsDisabledActor(actor)) then
				return true, actor
			end
		end
	end
	return false, nil
end

function LQS_AirsoftPurpleMercAI:GetActiveObjective(excludedObjective)
	-- Gets a active objective for this actor to sabotage
	local activeObjectives = {}
	local activeObjectivesUnprotected = {}

	local chosenObjective = nil

	-- First check
	-- This check basically checks the distance between this actor and the target objective, which possibly be the previous one
	-- If the actor is somewhat close to this objective then just continue to attack this objective than wasting time to get a new one
	if (self.targetObjective and not self.targetObjective.isSabotaged) then
		local distToPrevObj = Vector3.Distance(self.targetObjective.assignedPoint.transform.position, self.actor.transform.position)
		if (distToPrevObj < 100) then
			return self.targetObjective
		end
	end

	-- Main check
	-- Get all active objectives in the activeObjectives and activeObjectivesUnprotected array
	local allObjectives = self.airsoftRaidAIBase.airsoftRaidBase.allObjectives
	for _,objective in pairs(allObjectives) do
		-- Check if active
		if (not objective.isSabotaged) then
			-- Check if objective is not the same as the excluded objective
			if (not excludedObjective or excludedObjective and objective.assignedPoint ~= excludedObjective.assignedPoint) then
			    -- Check if unprotected
			    if (self.airsoftRaidAIBase.airsoftRaidBase.airsoftBase:IsUnprotected(objective.assignedPoint, Team.Blue)) then
			    	activeObjectivesUnprotected[#activeObjectivesUnprotected+1] = objective
			    end
			end

			-- Add to activeObjectives array
			activeObjectives[#activeObjectives+1] = objective
		end
	end

	-- Finalize
	-- If there is no available objectives then fuck it, choose a random active object
	chosenObjective = activeObjectives[math.random(#activeObjectives)]
	if (#activeObjectivesUnprotected > 0) then
		chosenObjective = activeObjectivesUnprotected[math.random(#activeObjectivesUnprotected)]
	end

	return chosenObjective
end

function LQS_AirsoftPurpleMercAI:GoToDestination(destination, destinationThreshold)
	-- Makes this actor go to the given destination
	self.targetDestination = destination
	self.destinationThreshold = destinationThreshold
	self:ChangeState(nil, 5)
end

function LQS_AirsoftPurpleMercAI:SetDestination(destination)
	-- Sets the destination of the given actor
	self.actorController.Goto(destination)
end

function LQS_AirsoftPurpleMercAI:ChangeState(funcResetVar, newState)
	-- Changes the handler state of this actor
	-- Reset vars used by the previous state
	if (funcResetVar) then
		funcResetVar()
	end

	-- Change the state
	self.aiStateIndex = newState
end
