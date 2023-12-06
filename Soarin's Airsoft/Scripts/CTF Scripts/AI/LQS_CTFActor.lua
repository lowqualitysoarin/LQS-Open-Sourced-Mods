behaviour("LQS_CTFActor")

function LQS_CTFActor:Awake()
	-- Base
	self.thisActor = nil
	self.actorController = nil

	-- State functions
	-- Attack
	self.attackEnter = function()
		self.targetDest = self.rivalFlag.transform.position
	end

	self.attack = function()
		self:Attack()
	end

	-- Defend
	self.defendVarResetter = function()
		self.newDefendPointTimer = 0
		self.defendTimer = 0
	end

	self.defend = function()
		self:Defend()
	end

	-- Return Flag
	self.returnFlagEnter = function()
		self.targetDest = self.allyFlag.transform.position
	end

	self.returnFlag = function()
		self:ReturnFlag()
	end

	-- Capture Flag
	self.captureFlagVarResetter = function()
		self.alreadyCalledCaptureFlag = false
	end

	self.captureFlag = function()
		self:CaptureFlag()
	end

	-- Protect Capturer
	self.protectCapturerEnter = function()
		self.targetDest = self.rivalFlag.transform.position
	end

	self.protectCapturer = function()
		self:ProtectCapturer()
	end

	-- State Vars
	self.attackTimer = 0
	self.returnFlagTimer = 0
	self.newDefendPointTimer = 0
	self.defendTimer = 0
	self.protectCapturerTimer = 0

	self.alreadyCalledCaptureFlag = false

	-- State Machine
	-- A shitty but simple state machine, less actions than the raid one
	self.aiStates = {
		{"Attack", {self.attack, self.attackEnter}},
		{"Defend", {self.defend, nil, self.defendVarResetter}},
		{"ReturnFlag", {self.returnFlag}},
		{"CaptureFlag", {self.captureFlag, nil, self.captureFlagResetter}},
		{"ProtectCapturer", {self.protectCapturer}}
	}

	self.aiStateIndex = 1
	self.currentState = self.aiStates[self.aiStateIndex][1]

	-- Base Vars
	self.lastDestPos = Vector3.zero
	self.targetDest = Vector3.zero

	self.airsoftBase = nil
	self.airsoftCTFAIBase = nil
	self.airsoftCTFBase = nil

	self.rivalFlag = nil
	self.allyFlag = nil

	self.alreadyRanHandler = false
end

function LQS_CTFActor:StartAI(airsoftBase, ctfBase, ctfAIBase, initialState, actor)
	-- Starts this ai entry
	-- Assign dependency
	self.airsoftBase = airsoftBase
	self.airsoftCTFBase = ctfBase
	self.airsoftCTFAIBase = ctfAIBase
	
	self.thisActor = actor
	self.actorController = self.thisActor.aiController

	-- Modify properties
	self.teamBase = self.airsoftCTFBase:GetTeamBase(self.thisActor.team)
	self.rivalFlag = self.airsoftCTFBase:GetFlag(self.thisActor.team, true)
	self.allyFlag = self.airsoftCTFBase:GetFlag(self.thisActor.team)

	self.actorController.canJoinPlayerSquad = false
	self.actorController.OverrideDefaultMovement()

	-- Finalize
	self:ChangeState(initialState)

	-- Fire up the AI
	if (not self.alreadyRanHandler) then
		self.airsoftCTFAIBase:StartAIHandler(self.thisActor)
		self.alreadyRanHandler = true
	end
end

function LQS_CTFActor:ChangeState(newStateIndex)
	-- Changes the state (duh)
	-- Reset previous state vars
	if (self.aiStates[self.aiStateIndex] and self.aiStates[self.aiStateIndex][2][3]) then
		self.aiStates[self.aiStateIndex][2][3]()
	end

	-- Enter new state
	if (self.aiStates[newStateIndex] and self.aiStates[newStateIndex][2][2]) then
		self.aiStates[newStateIndex][2][2]()
	end

	-- Change to the new state
	self.aiStateIndex = newStateIndex
	self.currentState = self.aiStates[self.aiStateIndex][1]
end

function LQS_CTFActor:Attack()
	self.attackTimer = self.attackTimer + 1 * Time.deltaTime
	if (self.attackTimer >= 1.5) then
		self.targetDest = self.rivalFlag.transform.position
		self.attackTimer = 0
	end
end

function LQS_CTFActor:Defend()
	self.newDefendPointTimer = self.newDefendPointTimer + 1 * Time.deltaTime
	if (self.newDefendPointTimer >= 5) then
		self.targetDest = self.teamBase.spawnPosition
		self.newDefendPointTimer = 0
	end

	self.defendTimer = self.defendTimer + 1 * Time.deltaTime
	if (self.defendTimer >= 30) then
		self:ChangeState(1)
	end
end

function LQS_CTFActor:ReturnFlag()
	self.returnFlagTimer = self.returnFlagTimer + 1 * Time.deltaTime
	if (self.returnFlagTimer >= 1.5) then
		self.targetDest = self.allyFlag.transform.position
		self.returnFlagTimer = 0
	end
end

function LQS_CTFActor:CaptureFlag()
	if (not self.alreadyCalledCaptureFlag) then
		self.targetDest = self.teamBase.transform.position
		self.alreadyCalledCaptureFlag = true
	end
end

function LQS_CTFActor:ProtectCapturer()
	local dist_to_flag = Vector3.Distance(self.rivalFlag.transform.position, self.thisActor.transform.position)

	self.protectCapturerTimer = self.protectCapturerTimer + 1 * Time.deltaTime
	if (self.protectCapturerTimer >= 1.5) then
		self.targetDest = self.thisActor.transform.position
		if (dist_to_flag > 3.5) then
			self.targetDest = self.rivalFlag.transform.position
		end
		self.protectCapturerTimer = 0
	end
end
