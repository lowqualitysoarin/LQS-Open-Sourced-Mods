-- low_quality_soarin © 2023-2024
behaviour("LQS_RaidAIBase")

function LQS_RaidAIBase:Awake()
    -- Listeners
    -- Already explained
    self.airsoftRaidAIBaseMethods = {
        {"onCreateAIHandler", {}},
        {"onRemoveAIHandler", {}},
        {"onSpotEnemy", {}},
        {"onLoseEnemy", {}}
    }

    -- Handler List
    -- This is a array of actors which the script will handle.
    -- Format: {Actor, {AIRole, AIBehavior}}
    self.actorHandlerArray = {}
end

function LQS_RaidAIBase:Start()
    -- AI Role
    -- The role of the ai for the actor, there are two types. "AIDefender" and "AIPurpleMerc"
    -- Format: {"AIRole", AIBehaviour}
    self.AIRoles = {
        {"AIDefender", self.targets.aiDefender},
        {"AIPurpleMerc", self.targets.aiPurpleMerc}
    }

    -- Vars
    self.aiContainer = self.targets.aiContainer.transform
    self.airsoftRaidBase = nil

    -- Finalize
    self.script.StartCoroutine(self:FinalizeSetup())

	-- Make a instance
    _G.LQSSoarinsAirsoftRaidAIBase = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_RaidAIBase:FinalizeSetup()
    return function()
        coroutine.yield(WaitForSeconds(0.01))

        -- Get the airsoft raid base script
        local airsoftRaidBase = _G.LQSSoarinsAirsoftRaidBase
        if (airsoftRaidBase) then
            self.airsoftRaidBase = airsoftRaidBase.self
        end
    end
end

function LQS_RaidAIBase:GoToDestination(actor, targetDesintation, destinationThreshold, setSearchWhenReached)
    -- Overrides the handler state of the given actor
    local actorHandler, aiIndex = self:GetActorHandler(actor)
    if (actorHandler[1]) then
        actorHandler[2][2]:GoToDestination(targetDesintation, destinationThreshold, setSearchWhenReached)
    end
end

function LQS_RaidAIBase:OverrideState(actor, state)
	-- Overrides the current state of the given actor
	local actorHandler, aiIndex = self:GetActorHandler(actor)
	if (actorHandler[1]) then
		local aiBehavior = actorHandler[2][2]

		local stateResetFunc = aiBehavior.aiStates[aiBehavior.aiStateIndex][2][2]
		local targetStateIndex = self:GetStateIndex(state, aiBehavior.aiStates)

		print("State to Reset:", aiBehavior.aiStates[aiBehavior.aiStateIndex][1], "Target State:", aiBehavior.aiStates[targetStateIndex][1], targetStateIndex)
		aiBehavior:ChangeState(stateResetFunc, targetStateIndex)
	end
end

function LQS_RaidAIBase:StartAI(actor, aiRole, spawnedPoint)
    -- This simply starts handling the AI of the actor
    -- Add the actor in the handler array
    self:ManageHandlerArray(false, actor, aiRole)

    -- Get the ai role behavior
    local aiBehaviorData, aiIndex = self:GetActorHandler(actor)
    if (aiBehaviorData[1]) then
        if (aiBehaviorData[2][1] == "AIDefender") then
            -- Defender AI
            aiBehaviorData[2][2]:StartAI(_G.LQSSoarinsAirsoftRaidAIBase, aiIndex, actor, spawnedPoint, self.airsoftRaidBase.purpleGuy)
        elseif (aiBehaviorData[2][1] == "AIPurpleMerc") then
            -- Purple Merc AI
            aiBehaviorData[2][2]:StartAI(_G.LQSSoarinsAirsoftRaidAIBase, aiIndex, actor, spawnedPoint)
        end
    end
end

function LQS_RaidAIBase:StartAIHandler(actor)
    -- Different than StartAI method, this one calls a coroutine to start controlling the given aiScript
    local aiBehaviorData, aiBehaviorIndex = self:GetActorHandler(actor)
    if (aiBehaviorData[1]) then
        self.script.StartCoroutine(self:AIHandler(aiBehaviorData[2][2], aiBehaviorData))
    end
end

function LQS_RaidAIBase:AIHandler(aiScript, aiBehaviorData)
	return function()
		-- The coroutine that runs the given states
		-- It will automatically stop if the actor is not in the actor handler array anymore
		coroutine.yield(WaitForSeconds(1))

		-- Start Handling
		self:TriggerListener("onCreateAIHandler", {aiScript.actor, aiBehaviorData})

        -- Some vars only for this coroutine
        local alreadyTriggeredOnSpotEvent = false
        local alreadyTriggeredOnLoseEvent = true

		-- Update (Handler)
		-- This is gonna fucking suck
		local prevState = nil
		while (self.actorHandlerArray[aiScript.aiIndex]) do
		    -- Vision System
		    -- Triggers some events related to vision
		    aiScript.canSeeAEnemy = self:IsInSight(aiScript.actorController)
			if (aiScript.canSeeAEnemy) then
				-- Triggers the onSpotEnemy event
				if (not alreadyTriggeredOnSpotEvent) then
					self:TriggerListener("onSpotEnemy", {aiScript.actor, aiBehaviorData})
					alreadyTriggeredOnSpotEvent = true
				end
				alreadyTriggeredOnLoseEvent = false
			else
				-- Trigger the onLoseEnemy event
				if (not alreadyTriggeredOnLoseEvent) then
					self:TriggerListener("onLoseEnemy", {aiScript.actor, aiBehaviorData})
					alreadyTriggeredOnLoseEvent = true
				end
				alreadyTriggeredOnSpotEvent = false
			end

			-- Handle the given state
			-- The functions can only change the current state
			local currentStateData = aiScript.aiStates[aiScript.aiStateIndex]

			aiScript.currentState = currentStateData[1]
			currentStateData[2][1]()

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Stop handling actor
		aiScript.actorController.ReleaseDefaultMovementOverride()
		self:TriggerListener("onRemoveAIHandler", {aiScript.actor, aiBehaviorData})
		GameObject.Destroy(aiScript.gameObject)
	end
end

function LQS_RaidAIBase:ManageHandlerArray(remove, actor, aiRole)
    -- This manages the actorHandlerArray
    if (not actor) then return end
    if (not remove) then
		if (not aiRole) then return end

        -- Add
        local aiRoleBehaviour = self:GetAIRoleBehaviour(aiRole)

        local behaviorScript = GameObject.Instantiate(aiRoleBehaviour[2], self.aiContainer).GetComponent(ScriptedBehaviour).self
        self.actorHandlerArray[#self.actorHandlerArray+1] = {actor, {aiRoleBehaviour[1], behaviorScript}}
    else
        -- Remove
        local actorHandlerData, actorHandlerIndex = self:GetActorHandler(actor)
        if (actorHandlerData) then
            self.actorHandlerArray[actorHandlerIndex] = nil
        end
    end
end

function LQS_RaidAIBase:GetAIRoleBehaviour(aiRole)
    -- Gets the AI role behaviour of the given type
    for _,aiBehaviour in pairs(self.AIRoles) do
        if (aiBehaviour[1] == aiRole) then
            return aiBehaviour
        end
    end
    return nil
end

function LQS_RaidAIBase:GetActorHandler(actor)
    -- This literally gets the actor from the actorHandlerArray and the it's index
    for handlerIndex,handlerData in pairs(self.actorHandlerArray) do
        if (handlerData[1] == actor) then
            return handlerData, handlerIndex
        end
    end
    return nil
end

function LQS_RaidAIBase:SetWeaponLoadoutDifficulty(actor, targetDifficulty, targetEnemyActors, targetEffectiveness, increaseSpread)
	-- Sets the weapon's difficulty of the given actor's loadout (only for infantries)
	for _,wep in pairs(actor.weaponSlots) do
		self:SetWeaponDifficulty(actor, wep, targetDifficulty, targetEnemyActors, targetEffectiveness, increaseSpread)
		for _,altWep in pairs(wep.alternativeWeapons) do
			self:SetWeaponDifficulty(actor, altWep, targetDifficulty, targetEnemyActors, targetEffectiveness, increaseSpread)
		end
	end
end

function LQS_RaidAIBase:SetWeaponDifficulty(actor, wep, targetDifficulty, targetEnemyActors, targetEffectiveness, increaseSpread)
	-- Sets the difficulty of the given weapon
	if (not wep) then return end

	-- Set difficulty
	wep.difficultyInfantry = targetDifficulty
	wep.difficultyInfantryGroup = targetDifficulty
	for _,enemyActor in pairs(targetEnemyActors) do
		actor.EvaluateShotDifficulty(enemyActor, wep)
	end

	-- Set effectiveness
	if (targetEffectiveness) then
		wep.effectivenessInfantry = targetEffectiveness
	    wep.effectivenessInfantryGroup = targetEffectiveness
	end

	-- Increases the spread
	if (increaseSpread) then
		wep.baseSpread = wep.baseSpread + Random.Range(0.1, 0.2) * Random.Range(0.01, 0.5)
		wep.followupSpread.maxSpreadAim = wep.followupSpread.maxSpreadAim + Random.Range(0.1, 0.2) * Random.Range(0.01, 0.5)
		wep.followupSpread.maxSpreadHip = wep.followupSpread.maxSpreadHip + Random.Range(0.1, 0.2) * Random.Range(0.01, 0.5)
	end
end

function LQS_RaidAIBase:GetNearestActor(originPos, actors, excludedActor)
	-- Gets a nearest actor from actors array that isn't hit and not the excluded actor
	local targetDist = Mathf.Infinity
	local actorOutput = nil
	for _,actor in pairs(actors) do
		local dist = Vector3.Distance(actor.transform.position, originPos)
		if (not self.airsoftRaidBase.airsoftBase:IsDisabledActor(actor)) then
			if (dist < targetDist and actor ~= excludedActor) then
				actorOutput = actor
				targetDist = dist
			end
		end
	end
	return actorOutput
end

function LQS_RaidAIBase:IsInSight(actorController)
	-- The vision handler, returns true if the enemy is really seen by this actor
	if (actorController.currentAttackTarget) then
		return true
	end
	return false
end

function LQS_RaidAIBase:GetStateIndex(targetState, aiStates)
	-- Gets the state index from aiStates array
	for stateIndex,stateData in pairs(aiStates) do
		if (stateData[1] == targetState) then
			return stateIndex
		end
	end
	return nil
end

function LQS_RaidAIBase:GetRandomPointInRange(originPos, range)
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
	local raycastSnap = Physics.RaycastAll(ray, 2.5, RaycastTarget.Default)

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

function LQS_RaidAIBase:LuckSystem(chance)
	-- A global luck system, returns true if its lucky
	local luck = Random.Range(0, 100)
	if (luck < chance) then
		return true
	end
	return false
end

-- Copy pasted from the AirsoftBase script
function LQS_RaidAIBase:TriggerListener(type, arguments)
	if (not type) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftRaidAIBaseMethods[targetMethodIndex]) then
		for _,func in pairs(self.airsoftRaidAIBaseMethods[targetMethodIndex][2]) do
			func(arguments)
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_RaidAIBase:ManageListeners(remove, type, owner, func)
	if (not type or not owner or not func) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftRaidAIBaseMethods[targetMethodIndex]) then
		if (not remove) then
			self.airsoftRaidAIBaseMethods[targetMethodIndex][2][owner] = func
		else
			self.airsoftRaidAIBaseMethods[targetMethodIndex][2][owner] = nil
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_RaidAIBase:GetTargetMethod(type)
	local targetMethodIndex = nil
	for index,method in pairs(self.airsoftRaidAIBaseMethods) do
		if (method[1] == type) then
			targetMethodIndex = index
		end
	end
	return targetMethodIndex
end
