-- low_quality_soarin © 2023-2024
-- This will always use progress bars, when its completed the sabotage is complete
behaviour("LQS_AirsoftRaidObjective")

function LQS_AirsoftRaidObjective:Awake()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Trigger System
	-- This is needed for the sabotage system
	self.usableDependency = self.targets.usableDependency

	if (self.targets.activationSignal) then
		self.activationSignal = self.targets.activationSignal.GetComponent(TriggerScriptedSignal)
	end

	self.sabotageTime = self.data.GetFloat("sabotageTime")
	self.sabotageProgress = 0

	self.hasTriggeredUsable = false
	self.triggererInRange = false

	-- Objective ID
	-- Randomly generated for the waypoint marker
	local generatedID1, generatedID2, generatedID3 = math.random(1, 100), math.random(1, 100), math.random(1, 100)
	self.objectiveID = tostring(generatedID1 .. generatedID2 .. generatedID3)

	-- Awake vars
	self.assignedPoint = nil
	self.objectiveType = nil
	self.isSabotaged = false

	-- Listeners
	-- Similar format as AirsoftBase listeners
	self.airsoftRaidObjectiveMethods = {
		{"onSabotaged", {}},
		{"onSabotage", {}},
		{"onSabotageCancelled", {}}
	}
end

function LQS_AirsoftRaidObjective:Start()
	-- Vars
	self.airsoftBase = nil
	self.airsoftHUDBase = nil
	self.airsoftRaidBase = nil

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())

	-- Make instance variable
	self.objectiveInstance = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_AirsoftRaidObjective:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0.01))

		-- Get the airsoft raid script
		local airsoftRaidBase = _G.LQSSoarinsAirsoftRaidBase
        if (airsoftRaidBase) then
            self.airsoftRaidBase = airsoftRaidBase.self
        end

		-- Get the airsoftBase script and assign some stuff, as usual
		local airsoftBase = _G.LQSSoarinsAirsoftBase
		if (airsoftBase) then
			self.airsoftBase = airsoftBase.self
			self.airsoftHUDBase = self.airsoftBase.airsoftHUDBase
		end
	end
end

function LQS_AirsoftRaidObjective:SabotageCheck()
	-- This is called by a trigger, this basically do a alive actors in range check to get the triggerer
	-- and check if the triggerer is a player or a bot. If its a bot then ignore the usable dependency and start sabotaging.
	-- If the triggerer is a player then include the usable dependency in order to start sabotaging
	if (not self.isSabotaged) then
		-- Set triggerer in range to true
		self.triggererInRange = true

		-- Get the possible triggerer of this objective
		local nearbyActor = ActorManager.AliveActorsInRange(self.transform.position, 5)[1]
		if (nearbyActor) then
			-- Trigger the sabotage tracker
			self.script.StartCoroutine(self:SabotageTracker(nearbyActor))
		end
	end
end

function LQS_AirsoftRaidObjective:SabotageTracker(actor)
	return function()
		-- Trigger check
		-- It will be set to true if the attacker is a bot
		local triggerCheckDone = not actor.isPlayer
		if (actor.isPlayer) then
			-- Enable the usable dependency
			self:ToggleUsableDependency(true)
		end

		-- Wait for the player/actor to trigger the usableDependency, it will continue if the player has triggered it
		while (not self.hasTriggeredUsable) do
			coroutine.yield(WaitForSeconds(0))
		end

		-- If the player/actor has triggered the usable then tick trigger check done to true
		if (actor.isPlayer) then
			self:ToggleUsableDependency(false)
		end
		triggerCheckDone = true

		-- This middle part is the sabotage start part
		-- Call onSabotage event, this and onSabotaged is different. Only gets called if objective is getting sabotaged
		self:TriggerListener("onSabotage", {self.objectiveInstance})

		-- When everything is set then start sabotaging
		-- If the triggererInRange is set false then it will cancel the progress
		local sabotageDone = false
		local alreadyToggledProgressBar = false
		while (not sabotageDone) do
			-- Sabotage progress handler
			while (triggerCheckDone and self.sabotageProgress < self.sabotageTime) do
				-- If triggerer isn't on range anymore, then cancel sabotage
				if (not self.triggererInRange) then 
					self.airsoftBase:ToggleWeapons(actor.weaponSlots, false) 
					return 
				end

				-- Lock the actor's weapons
				self.airsoftBase:ToggleWeapons(actor.weaponSlots, true) 

				-- Enable hud elements if player
				self.sabotageProgress = self.sabotageProgress + 1 * Time.deltaTime
				if (actor.isPlayer) then
					-- Toggle progress bar
					if (not alreadyToggledProgressBar) then
						self.airsoftHUDBase:ToggleProgressBar(true)
						alreadyToggledProgressBar = true
					end

					-- Update progress bar
					self.airsoftHUDBase:UpdateProgressBar(self.sabotageProgress, self.sabotageTime)
				end

				-- Update
				coroutine.yield(WaitForSeconds(0))
			end

			-- Call sabotage done to finish the loop
			sabotageDone = true
		end

		-- Sabotage Complete
		self:SabotageCompleted(actor)
		self.airsoftBase:ToggleWeapons(actor.weaponSlots, false) 
	end
end

function LQS_AirsoftRaidObjective:SabotageCompleted(actor)
	-- Stuff to call and do if the sabotage is successful
	-- Tick isSabotaged and hasTriggeredUsable bool and stop HUD progressbar element
	self.isSabotaged = true
	self.hasTriggeredUsable = false

	if (actor.isPlayer) then
		self.airsoftHUDBase:ToggleProgressBar(false)
	end

	-- Call onSabotaged event
	self:TriggerListener("onSabotaged", {self.objectiveInstance})

	-- Trigger object activation trigger, for the effects
	if (self.activationSignal) then
		self.activationSignal.Send("ActivateObject", SignalContext())
	end
end

function LQS_AirsoftRaidObjective:SabotageCancel()
	-- This simply just stops the sabotage progress
	self.triggererInRange = false
	self.hasTriggeredUsable = false
	self.airsoftHUDBase:ToggleProgressBar(false)
end

function LQS_AirsoftRaidObjective:ToggleUsableDependency(active)
	self.usableDependency.SetActive(active)
end

function LQS_AirsoftRaidObjective:TriggeredSabotageUse()
	-- This a dependency needed if the triggerer is a player
	self.hasTriggeredUsable = true
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftRaidObjective:TriggerListener(type, arguments)
	if (not type) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftRaidObjectiveMethods[targetMethodIndex]) then
		for _,func in pairs(self.airsoftRaidObjectiveMethods[targetMethodIndex][2]) do
			func(arguments)
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftRaidObjective:ManageListeners(remove, type, owner, func)
	if (not type or not owner or not func) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftRaidObjectiveMethods[targetMethodIndex]) then
		if (not remove) then
			self.airsoftRaidObjectiveMethods[targetMethodIndex][2][owner] = func
		else
			self.airsoftRaidObjectiveMethods[targetMethodIndex][2][owner] = nil
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftRaidObjective:GetTargetMethod(type)
	local targetMethodIndex = nil
	for index,method in pairs(self.airsoftRaidObjectiveMethods) do
		if (method[1] == type) then
			targetMethodIndex = index
		end
	end
	return targetMethodIndex
end
