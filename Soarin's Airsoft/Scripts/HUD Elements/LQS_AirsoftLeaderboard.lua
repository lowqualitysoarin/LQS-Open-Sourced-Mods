behaviour("LQS_AirsoftLeaderboard")

local totalPlayerKills = 0

function LQS_AirsoftLeaderboard:Start()
	-- Base
	-- Leaderboard main
	self.leaderboardBase = self.targets.leaderboardBase
	self.leaderboardContent = self.targets.leaderboardContent
	self.leaderboardContentHolder = self.targets.leaderboardContentHolder.transform

	-- Leaderboard player
	self.leaderboardPlayerName = self.targets.leaderboardPlayerName.GetComponent(Text)
	self.leaderboardPlayerGameInfo = self.targets.leaderboardPlayerGameInfo.GetComponent(Text)
	self.leaderboardPlayerTotalKills = self.targets.leaderboardPlayerTotalKills.GetComponent(Text)
	self.leaderboardPlayerTeam = self.targets.leaderboardPlayerTeam.GetComponent(Text)
	self.leaderboardGamemodeTitle = self.targets.leaderboardGamemodeTitle.GetComponent(Text)

	-- Leaderboard Data
	-- Format: {Actor, {Kills, Deaths, Captures}, FactionData, BaseImage, ActorNameHolder, ActorKillsHolder, ActorDeathsHolder, ActorCapturesHolder}
	self.leaderboardData = {}

	-- Vars
	self.airsoftBase = nil 
	self.airsoftHUDBase = nil

	self.leaderboardOpen = false
	self.alreadySetupPlayerInfo = false
	self.alreadyActivatedLeaderboard = false
	self.alreadyDeactivatedLeaderboard = true

	-- Finalize
	-- Close leaderboard
	self.leaderboardBase.SetActive(false)

	-- Run coroutine
	self.script.StartCoroutine(self:FinalizeSetup())

	-- Share singleton
	_G.LQSSoarinsAirsoftLeaderboard = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_AirsoftLeaderboard:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0))

		-- Deactivate ravenfield's scoreboard (yes the main scoreboard)
		local rfLeaderboard = GameObject.Find("Scoreboard Canvas")
		if (rfLeaderboard) then
			rfLeaderboard.SetActive(false)
		end

		-- Basically a more optimized Update() (I guess)
		local run = true
		while (run) do
			-- Open/Close leaderboard
			if (Input.GetKeyBindButton(KeyBinds.Scoreboard)) then
				if (not self.alreadyActivatedLeaderboard) then
					-- Activate
					self.leaderboardOpen = true
					Screen.UnlockCursor()

					-- Tick bools
					self.alreadyActivatedLeaderboard = true
					self.alreadyDeactivatedLeaderboard = false
				end
			else
				if (not self.alreadyDeactivatedLeaderboard) then
					-- Deactivate
					self.leaderboardOpen = false
					Screen.LockCursor()

					-- Tick bools
					self.alreadyActivatedLeaderboard = false
					self.alreadyDeactivatedLeaderboard = true
				end
			end
			self.leaderboardBase.SetActive(self.leaderboardOpen)

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end
	end
end

function LQS_AirsoftLeaderboard:UpdateLeaderboard(actor, updateData)
	-- Adds or updates the contents in the leaderboard
	local actorLbData = self:GetActorLeaderboardData(actor)
	if (not actorLbData) then
		-- Add actor to leaderboard
		-- Instantiate content
		local newLbContent = GameObject.Instantiate(self.leaderboardContent, self.leaderboardContentHolder)
		
		-- Reset localPosition and localRotation (Just incase)
		newLbContent.transform.localPosition = Vector3.zero
		newLbContent.transform.localRotation = Quaternion.identity

		-- Extract contents
		local actorToPut = actor

		local baseImage = newLbContent.gameObject.GetComponent(Image)
		local actorNameHolder = newLbContent.transform.GetChild(0).gameObject.GetComponent(Text)

		local actorKillsHolder = newLbContent.transform.GetChild(1).gameObject.GetComponent(Text)
		local actorDeathsHolder = newLbContent.transform.GetChild(2).gameObject.GetComponent(Text)
		local actorCapturesHolder = newLbContent.transform.GetChild(3).gameObject.GetComponent(Text)

		-- Setup contents
		-- Get faction data
		local factionData = self.airsoftBase:GetFactionData(actor.team)

		-- Apply color and texts
		baseImage.color = self.airsoftHUDBase:ColorClamp01(factionData[2])
		actorNameHolder.text = actorToPut.name

		actorKillsHolder.text = "0"
		actorDeathsHolder.text = "0"
		actorCapturesHolder.text = "0"

		-- Add to presentActors array
		local newLbData = {actorToPut, {0, 0, 0}, factionData, baseImage, actorNameHolder, actorKillsHolder, actorDeathsHolder, actorCapturesHolder}
		self.leaderboardData[#self.leaderboardData+1] = newLbData

		-- Update player info (player only)
		self:UpdatePlayerInfo(newLbData)

		-- If the player's faction is spectator then remove it's content in the leaderboard
		if (factionData[1] == "Spectator") then
			GameObject.Destroy(newLbContent)
		end
	else
		-- Update
		if (not updateData) then return end

		-- Update the target data
		-- Format "UpdateType;;Sub/Add"
		local unwrappedData = self:UnwrapData(updateData)
		if (#unwrappedData == 0) then return end

		local updateType = unwrappedData[1]
		local updateAction = unwrappedData[2]

		-- Update the actor's usual info
		-- Get the integer to update
		local intToUpdate = actorLbData[2][1]
		local sourceTableIndex = 1
		local textToUpdate = actorLbData[6]
		if (updateType == "UpdateDeaths") then
			intToUpdate = actorLbData[2][2]
			sourceTableIndex = 2
			textToUpdate = actorLbData[7]
		elseif (updateType == "UpdateCaptures") then
			intToUpdate = actorLbData[2][3]
			sourceTableIndex = 3
			textToUpdate = actorLbData[8]
		end

		-- Perform action
		if (updateAction == "Sub") then
			intToUpdate = intToUpdate - 1
		elseif (updateAction == "Add") then
			intToUpdate = intToUpdate + 1
		end
		actorLbData[2][sourceTableIndex] = intToUpdate

		-- Update some stuff
		self:UpdatePlayerInfo(actorLbData, updateType, updateAction)
		if (textToUpdate) then
			textToUpdate.text = tostring(intToUpdate)
		end

		-- Update leaderboard arrangement (this is gonna suck)
		self:UpdateLeaderboardArrangement()
	end
end

function LQS_AirsoftLeaderboard:RemoveLeaderboardContent(actor)
	-- Removes the leaderboard content of the given actor, but the other info will be kept and still be updated and its permanent
	local actorLbData = self:GetActorLeaderboardData(actor)
	if (actorLbData[4]) then
		GameObject.Destroy(actorLbData[4].gameObject)
	end
end

function LQS_AirsoftLeaderboard:UpdateLeaderboardArrangement()
	-- Basically arranges the leader board from highest to lowest
	-- Create array which only holds the content gameobject and the number of kills
	local instances = {}
	for _,lbData in pairs(self.leaderboardData) do
		if (lbData[4]) then
			instances[#instances+1] = {lbData[2][1], lbData[4].transform}
		end
	end

	-- Arrange I'll be using table.sort() for this one lmao
	table.sort(instances, function(a, b) return a[1] > b[1] end)

	-- Update leaderboard arrangement
	local arrangementIndex = 0
	for _,scoreData in pairs(instances) do
		scoreData[2].SetSiblingIndex(arrangementIndex)
		arrangementIndex = arrangementIndex + 1
	end
end

function LQS_AirsoftLeaderboard:UpdatePlayerInfo(lbData, updateType, updateAction)
	-- Updates the player's info
	if (not lbData) then return end
	if (not lbData[1].isPlayer) then return end

	if (not self.alreadySetupPlayerInfo) then
		-- Setup the player info
		self.leaderboardPlayerName.text = lbData[1].name
		self.leaderboardPlayerTeam.text = lbData[3][4]

		self.leaderboardPlayerGameInfo.text = "Kills: 0\nDeaths: 0\nCaptures: 0"
		self.leaderboardPlayerTotalKills.text = "Total Kills: " .. tostring(totalPlayerKills)

		self.alreadySetupPlayerInfo = true
	else
		-- Update the player info
		-- Kind of similar the one above, but different thing to assign
		self.leaderboardPlayerGameInfo.text = "Kills: " .. tostring(lbData[2][1]) .. "\nDeaths: " .. tostring(lbData[2][2]) .. "\nCaptures: " .. tostring(lbData[2][3])

		-- Update total kills
		-- Resets if the player quits the application
		if (updateType == "UpdateKills" and updateAction == "Add") then
			totalPlayerKills = totalPlayerKills + 1
			self.leaderboardPlayerTotalKills.text = "Total Kills: " .. tostring(totalPlayerKills)
		end
	end
end

function LQS_AirsoftLeaderboard:UnwrapData(data)
    -- My own unwrapping method
	-- Copied from my ravenm version of weapon pickup
    local dataFinal = {}
    for word in string.gmatch(data, "([^;;]+)") do
        dataFinal[#dataFinal+1] = word
    end
    return dataFinal
end

function LQS_AirsoftLeaderboard:GetActorLeaderboardData(actor)
	-- Checks if the given actor is already present in the leaderboard
	for _,lbData in pairs(self.leaderboardData) do
		if (lbData[1] == actor) then
			return lbData
		end
	end
	return nil
end
