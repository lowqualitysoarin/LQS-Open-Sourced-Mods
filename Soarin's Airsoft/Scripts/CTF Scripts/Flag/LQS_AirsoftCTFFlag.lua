behaviour("LQS_AirsoftCTFFlag")

function LQS_AirsoftCTFFlag:Awake()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Flag renderers
	self.staticFlag = self.targets.staticFlag.GetComponent(Renderer)
	self.simulatedFlag = self.targets.simulatedFlag.GetComponent(Renderer)

	-- Flag ID
	-- Works similar as raid objective id
	local generatedID1, generatedID2, generatedID3 = math.random(1, 100), math.random(1, 100), math.random(1, 100)
	self.flagID = tostring(generatedID1 .. generatedID2 .. generatedID3)

	-- Awake vars
	self.assignedPoint = nil

	self.ownerTeam = nil
	self.ownerTeamID = nil

	self.holder = nil

	self.wasTaken = false
	self.wasCaptured = false
	self.isHeld = false

	-- Flag States
	-- For some conditions, kinda similar to FSM
	self.airsoftFlagStates = {
		"Untouched",
		"Held",
		"Dropped"
	}

	self.currentFlagState = self.airsoftFlagStates[1]

	-- Listeners
	-- Self-explanatory
	self.airsoftCTFFlagMethods = {
		{"onTaken", {}},
		{"onDropped", {}},
		{"onReturned", {}},
		{"onCaptured", {}}
	}
end

function LQS_AirsoftCTFFlag:Start()
	-- Vars
	self.airsoftBase = nil
	self.airsoftHUDBase = nil
	self.airsoftCTFBase = nil

	-- Finalize setup
	self.script.StartCoroutine(self:FinalizeSetup())
end

function LQS_AirsoftCTFFlag:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0.01))

		-- Get the CTF base
		local airsoftCTFBase = _G.LQSSoarinsAirsoftCTFBase
		if (airsoftCTFBase) then
			self.airsoftCTFBase = airsoftCTFBase.self
		end

		-- Get the base script
		local airsoftBase = _G.LQSSoarinsAirsoftBase
		if (airsoftBase) then
			-- Assign the base scripts
			self.airsoftBase = airsoftBase.self
			self.airsoftHUDBase = self.airsoftBase.airsoftHUDBase
		end

		-- Apply team flag
		self:ApplyTeamFlag(self.ownerTeam)
	end
end

function LQS_AirsoftCTFFlag:ApplyTeamFlag(team)
	-- Changes the team flag material to the given faction's flag material
	local factionFlagMaterial = self.airsoftBase:GetFactionData(team)[6]

	self.staticFlag.materials = {factionFlagMaterial}
	self.simulatedFlag.materials = {factionFlagMaterial}
end

function LQS_AirsoftCTFFlag:TakeCheck()
	-- Checks if the flag can be taken by the nearby actor
	if (self.isHeld) then return end

	-- Loop through all the nearbyActors, also to correct some misunderstanding
	local nearbyActors = ActorManager.AliveActorsInRange(self.transform.position, 2.5)
	for _,nearbyActor in pairs(nearbyActors) do
		-- Checks main
		if (self:CanBeReturned(nearbyActor)) then
			-- Return Flag
			self:ReturnFlag()
			break
		elseif (self:CanBeTaken(nearbyActor)) then
			-- Take Flag
			self.script.StartCoroutine(self:TrackHolder(nearbyActor))
			break
		elseif (self.currentFlagState == "Untouched") then
			-- Capture Flag
			local flagCaptureOut, capturedFlag = self.airsoftCTFBase:CanCaptureFlag(nearbyActor)
			if (flagCaptureOut) then
				self:CaptureFlag(capturedFlag, nearbyActor)
				break
			end
		end
	end
end

function LQS_AirsoftCTFFlag:CaptureFlag(capturedFlag, capturerActor)
	-- Captures the captured flag and adds points to the owner of this flag
	-- Trigger onCaptured listener
	self:TriggerListener("onCaptured", {capturedFlag, self, capturerActor})

	-- Return captured flag
	capturedFlag:ReturnFlag(true)
end

function LQS_AirsoftCTFFlag:ReturnFlag(wasCaptured)
	-- Returns this flag back to the base
	-- Tick wasCaptured bool soo the drop event won't get called
	self.wasCaptured = wasCaptured

	-- Set state
	self.currentFlagState = self.airsoftFlagStates[1]

	-- Unparent
	self.transform.parent = nil

	self.transform.localPosition = Vector3.zero
	self.transform.localRotation = Quaternion.identity

	-- Revert vals
	self.holder = nil

	self.wasTaken = false
	self.isHeld = false

	-- Trigger onReturn listener
	self:TriggerListener("onReturned", {self, wasCaptured})

	-- Reset pos and wasCaptured bool
	self.transform.position = self.assignedPoint.transform.position
	self.script.StartCoroutine(self:TickOffCaptured())
end

function LQS_AirsoftCTFFlag:TickOffCaptured()
	return function()
		-- Turns off wasCaptured bool after a second
		coroutine.yield(WaitForSeconds(0.05))
		self.wasCaptured = false
	end
end

function LQS_AirsoftCTFFlag:TrackHolder(takerActor)
	return function()
		-- Tracks the holder/taker of this flag
		-- Take flag
		self:TakeDropFlag(false, takerActor)

		-- Tracking main
		while (not self.airsoftBase:IsDisabledActor(takerActor) and self.isHeld) do
			coroutine.yield(WaitForSeconds(0))
		end

		-- Drop the flag if the actor was hit
		if (not self.wasCaptured) then
			self:TakeDropFlag(true)
		end
	end
end

function LQS_AirsoftCTFFlag:TakeDropFlag(drop, takerActor)
	if (not drop) then
		-- Take
		-- Set state
		self.currentFlagState = self.airsoftFlagStates[2]

		-- Set some stuff
		self.wasTaken = true
		self.isHeld = true
		
		self.holder = takerActor

		-- Parent to taker
		local chestT = takerActor.GetHumanoidTransformAnimated(HumanBodyBones.Chest)
		if (chestT) then
			self.transform.parent = chestT

			self.transform.localPosition = Vector3.zero
			self.transform.localRotation = Quaternion.identity

			local takeRot = Vector3(-90, 0, 45)
			self.transform.localRotation = Quaternion.Euler(takeRot)
		end

		-- Trigger listener
		self:TriggerListener("onTaken", {self, takerActor})
	else
		-- Drop
		-- Set state
		self.currentFlagState = self.airsoftFlagStates[3]

		-- Unparent and snap to ground
		self.transform.parent = nil

		local rayDown = Ray(self.transform.position + Vector3.up * 1, Vector3.down)
		local groundSnapRay = Physics.Raycast(rayDown, Mathf.Infinity, RaycastTarget.ActorWalkable)

		if (groundSnapRay) then
			self.transform.localPosition = Vector3.zero
			self.transform.localRotation = Quaternion.identity

			self.transform.position = groundSnapRay.point
		end

		-- Revert vals
		self.isHeld = false
		self.holder = nil

		-- Trigger listener
		self:TriggerListener("onDropped", {self})
	end
end

function LQS_AirsoftCTFFlag:CanBeReturned(returnerActor)
	-- Checks if the flag can be returned
	if (returnerActor.team == self.ownerTeam) then
		if (not self.airsoftBase:IsDisabledActor(returnerActor)) then
			if (self.currentFlagState == "Dropped") then
				return true
			end
		end
	end
	return false
end

function LQS_AirsoftCTFFlag:CanBeTaken(takerActor)
	-- Checks if this flag can be taken by the given actor
	if (takerActor.team ~= self.ownerTeam) then
		if (not self.airsoftBase:IsDisabledActor(takerActor)) then
			if (self.currentFlagState == "Untouched" or self.currentFlagState == "Dropped") then
				return true
			end
		end
	end
	return false
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftCTFFlag:TriggerListener(type, arguments)
	if (not type) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftCTFFlagMethods[targetMethodIndex]) then
		for _,func in pairs(self.airsoftCTFFlagMethods[targetMethodIndex][2]) do
			func(arguments)
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftCTFFlag:ManageListeners(remove, type, owner, func)
	if (not type or not owner or not func) then return end
	local targetMethodIndex = self:GetTargetMethod(type)

	if (targetMethodIndex and self.airsoftCTFFlagMethods[targetMethodIndex]) then
		if (not remove) then
			self.airsoftCTFFlagMethods[targetMethodIndex][2][owner] = func
		else
			self.airsoftCTFFlagMethods[targetMethodIndex][2][owner] = nil
		end
	end
end

-- Copy pasted from the AirsoftBase script
function LQS_AirsoftCTFFlag:GetTargetMethod(type)
	local targetMethodIndex = nil
	for index,method in pairs(self.airsoftCTFFlagMethods) do
		if (method[1] == type) then
			targetMethodIndex = index
		end
	end
	return targetMethodIndex
end
