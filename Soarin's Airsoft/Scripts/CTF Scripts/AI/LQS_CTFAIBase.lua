behaviour("LQS_CTFAIBase")

function LQS_CTFAIBase:Awake()
	-- Listeners
	self.airsoftCTFAIBaseMethods = {
		{"onCreateAIHandler", {}},
		{"onRemoveAIHandler", {}}
	}

	-- Handler array
	self.actorHandlerArray = {}
end

function LQS_CTFAIBase:Start()
	-- Base
	self.aiContainer = self.targets.aiContainer
	self.ctfAI = self.targets.ctfAI

	-- Vars
	self.airsoftBase = nil
	self.airsoftCTFBase = nil

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())

	-- Share instance
	_G.LQSSoarinsAirsoftCTFAIBase = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_CTFAIBase:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0.01))

		-- Get CTF base
		local airsoftCTFBase = _G.LQSSoarinsAirsoftCTFBase
		if (airsoftCTFBase) then
			self.airsoftCTFBase = airsoftCTFBase.self
		end

		-- Get base script
		local airsoftBase = _G.LQSSoarinsAirsoftBase
		if (airsoftBase) then
			self.airsoftBase = airsoftBase.self
		end
	end
end

function LQS_CTFAIBase:StartAIHandler(actor)
	-- Starts a coroutine for the actor's handler
	local handlerData, handlerIndex = self:GetAIHandler(actor)
	if (handlerData) then
		self.script.StartCoroutine(self:AIHandlerCoroutine(handlerData[2], handlerIndex))
	end
end

function LQS_CTFAIBase:AIHandlerCoroutine(handler, handlerIndex)
	return function()
		-- The coroutine for the AI handler state machine
		-- Trigger onCreate listener
		self:TriggerListener("onCreateAIHandler", {handler.thisActor, handler})

		-- Coroutine main
		while (self.actorHandlerArray[handlerIndex]) do
			-- Call state action
			local actionFunction = handler.aiStates[handler.aiStateIndex][2][1]
			actionFunction()

			-- Move the actor
			if (handler.targetDest ~= handler.lastDestPos) then
				handler.actorController.Goto(handler.targetDest)
				handler.lastDestPos = handler.targetDest
			end

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Trigger onRemove listener and destroy handler object
		handler.actorController.ReleaseDefaultMovementOverride()
		self:TriggerListener("onRemoveAIHandler", {handler.thisActor, handler})
		GameObject.Destroy(handler.gameObject)
	end
end

function LQS_CTFAIBase:GetAIHandler(actor)
	-- Gets the handler data and index of the given actor
	for handlerIndex,handlerData in pairs(self.actorHandlerArray) do
		if (handlerData[1] == actor) then
			return handlerData, handlerIndex
		end
	end
	return nil
end

function LQS_CTFAIBase:CreateAIHandler(actor)
	-- Creates a AI handler for the actor
	-- Instantiate handler and add to handler array
	local newHandler = GameObject.Instantiate(self.ctfAI, self.aiContainer.transform).GetComponent(ScriptedBehaviour).self
	self.actorHandlerArray[#self.actorHandlerArray+1] = {actor, newHandler}

	-- Start ai
	newHandler:StartAI(self.airsoftBase, self.airsoftCTFBase, self, self:DecideInitState(actor), actor)
end

function LQS_CTFAIBase:RemoveAIHandler(actor)
	-- Removes the AI handler of the given actor
	local handlerData, handlerIndex = self:GetAIHandler(actor)
	if (self.actorHandlerArray[handlerIndex]) then
		self.actorHandlerArray[handlerIndex] = nil
	end
end

function LQS_CTFAIBase:DecideInitState(actor)
	-- Decides a initial state for the ai soo it can get up to date on what's going on in the game
	-- Get this actor's team flag and opposing flag
	local actorTeamFlag = self.airsoftCTFBase:GetFlag(actor.team)
	local opposingTeamFlag = self.airsoftCTFBase:GetFlag(actor.team, true)

	-- Checking main
	local outputIndex = 1
	if (actorTeamFlag.currentFlagState == "Untouched") then
		-- If the team flag is all good then check the state of the opposing flag
		if (opposingTeamFlag.currentFlagState == "Untouched") then
			-- If the opposing team's flag is untouched then its time to get it or just sit there to defend
			outputIndex = 1
			if (self:LuckSystem(30)) then
				outputIndex = 2
			end
		elseif (opposingTeamFlag.currentFlagState == "Held") then
			-- If the opposing team's flag is taken then protect the taker or just sit
			outputIndex = 5
			if (self:LuckSystem(65)) then
				outputIndex = 2
			end
		elseif (opposingTeamFlag.currentFlagState == "Dropped") then
			-- If the opposing team's flag was dropped then get it before it gets returned or just sit
			outputIndex = 1
			if (self:LuckSystem(80)) then
				outputIndex = 2
			end
		end
	elseif (actorTeamFlag.currentFlagState == "Dropped" or actorTeamFlag.currentFlagState == "Held") then
		-- Return the team flag if it was dropped or taken
		outputIndex = 3
	end
	return outputIndex
end

function LQS_CTFAIBase:LuckSystem(chance)
	-- Chance system literally...
	local luck = Random.Range(0, 100)
	if (luck < chance) then
		return true
	end
	return false
end

function LQS_CTFAIBase:ChangeState(actor, newStateIndex)
	-- Changes the ai state of the given actor
	local handlerData, handlerIndex = self:GetAIHandler(actor)
	if (handlerData) then
		handlerData[2]:ChangeState(newStateIndex)
	end
end

function LQS_CTFAIBase:SetTeamDefendOrAttack(targetTeam, defendIterations, excludedActors)
	-- Changes the given team's actors state to attack or defend
	-- Error patch
	if (not excludedActors) then
		excludedActors = {}
	end

	-- Decision main
	local currentIteration = 0
	local targetState = 2
	for _,actor in pairs(targetTeam) do
		if (not self:IsValueInTable(actor, excludedActors) and not actor.isPlayer) then
			-- Set state
			self:ChangeState(actor, targetState)
			
			-- Check Iteration
			if (currentIteration <= defendIterations) then
				-- Defend
				targetState = 2
			elseif (currentIteration > defendIterations) then
				-- Attack
				targetState = 1
			end
		end
	end
end

function LQS_CTFAIBase:SetGroupStateIndex(stateIndex, originPos, targetTeam, excludedActors)
	-- Sets a new state of some actors nearby the signal origin
	-- Error match
	if (not excludedActors) then
		excludedActors = {}
	end

	-- Setting main
	local arrangedArray = self:OrderDistActors(true, originPos, targetTeam)
	for i = 1, math.random(3, 5) do
		if (arrangedArray[i]) then
			if (not arrangedArray[i].isPlayer and not self:IsValueInTable(arrangedArray[i], excludedActors)) then
				self:ChangeState(arrangedArray[i], stateIndex)
			end
		end
	end
end

function LQS_CTFAIBase:IsValueInTable(value, givenTable)
	-- Checks if the value is in the given table
	if (not givenTable) then return end
	for _,tVal in pairs(givenTable) do
		if (value == tVal) then
			return true
		end
	end
	return false
end

function LQS_CTFAIBase:OrderDistActors(nearest, originPos, actorsList)
	-- Idk what to call this, basically returns a nearest/furthest or furthest/nearest list of actors in a array
	-- Init vars
	local outputArray = {}

	local targetDist = 0
	if (nearest) then
		targetDist = Mathf.Infinity
	end

	-- Dist check main
	for _,actor in pairs(actorsList) do
		local dist = Vector3.Distance(actor.transform.position, originPos)
		if (dist < targetDist and nearest) then
			-- Nearest
			outputArray[#outputArray+1] = actor
			targetDist = dist
		elseif (dist > targetDist and not nearest) then
			-- Furthest
			outputArray[#outputArray+1] = actor
			targetDist = dist
		end
	end
	return outputArray
end

-- Copy pasted from the AirsoftBase script
function LQS_CTFAIBase:TriggerListener(type, arguments)
	if (not type) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftCTFAIBaseMethods[targetMethodIndex]) then
		for _,func in pairs(self.airsoftCTFAIBaseMethods[targetMethodIndex][2]) do
			func(arguments)
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_CTFAIBase:ManageListeners(remove, type, owner, func)
	if (not type or not owner or not func) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftCTFAIBaseMethods[targetMethodIndex]) then
		if (not remove) then
			self.airsoftCTFAIBaseMethods[targetMethodIndex][2][owner] = func
		else
			self.airsoftCTFAIBaseMethods[targetMethodIndex][2][owner] = nil
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_CTFAIBase:GetTargetMethod(type)
	local targetMethodIndex = nil
	for index,method in pairs(self.airsoftCTFAIBaseMethods) do
		if (method[1] == type) then
			targetMethodIndex = index
		end
	end
	return targetMethodIndex
end
