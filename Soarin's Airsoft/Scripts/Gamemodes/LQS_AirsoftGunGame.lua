behaviour("LQS_AirsoftGunGame")

function LQS_AirsoftGunGame:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Weapon Entries
	self.goldenFlintlock = self.data.GetWeaponEntry("goldenFlintlock")
	self.goldenWrench = self.data.GetWeaponEntry("goldenWrench")

	-- Listener functions
	self.onActorHit = function(arguments)
		self:OnActorHit(arguments[1], arguments[2])
	end

	self.onActorRecover = function(arguments)
		self:OnActorRecover(arguments[1])
	end

	-- Vars
	self.airsoftBase = nil
	self.weaponList = {}

	self.scoreLimit = 5
	self.alreadyCalledWinner = false

	-- Events
	GameEvents.onActorSpawn.AddListener(self, "OnActorSpawn")
	GameEvents.onMatchEnd.AddListener(self, "OnMatchEnd")

	-- Finalize
	self.script.StartCoroutine(self:FinalizeSetup())

	-- Share singleton
	_G.LQSSoarinsAirsoftGunGame = self.gameObject.GetComponent(ScriptedBehaviour)
end

function LQS_AirsoftGunGame:OnMatchEnd()
	-- This will only stop ending the match lmao
	CurrentEvent.Consume()
end

function LQS_AirsoftGunGame:OnActorSpawn(actor)
	self:ApplyWeapon(actor)
end

function LQS_AirsoftGunGame:OnActorHit(actor, sourceActor)
	self:ApplyWeapon(sourceActor)
end

function LQS_AirsoftGunGame:OnActorRecover(actor)
	self:ApplyWeapon(actor)
end

function LQS_AirsoftGunGame:ApplyWeapon(actor)
	-- Applies a weapon for this actor
	local airsoftActorData = self.airsoftBase.airsoftHUDBase.leaderboardBase
	
	-- Equip new weapon
	local actorLbData = airsoftActorData:GetActorLeaderboardData(actor)
	if (actorLbData) then
		-- Get the actor's kill score
		-- This will be always clamped from 1 to 32
		local killScore = actorLbData[2][1]+1
		killScore = Mathf.Clamp(killScore, 1, self.scoreLimit+1)

		-- killScore check
		self:ScoreCheck(actor, actorLbData[2][1])

		-- Give the new weapon
		-- Give the next weapon, if the next weapon is a nil its probably the golden wrench
		local nextWeapon = self.weaponList[killScore]
		if (not nextWeapon) then
			nextWeapon = self.goldenWrench
		end

		self.airsoftBase:GetNewLoadout(actor, {nextWeapon, nil, nil, nil, nil})
	end
end

function LQS_AirsoftGunGame:ScoreCheck(actor, killScore)
	-- Basically checks the score of the given actor if they already won or stuff
	-- Also used to announce that they've reached the golden gun or the golden wrench
	if (not actor or not killScore) then return end

	-- The checks
	if (killScore >= self.scoreLimit-2 and killScore < self.scoreLimit+1) then
		-- Score alerts
		if (not actor.isPlayer and killScore >= self.scoreLimit-1) then
			-- Will not be announced if the actor has reached the score is the player
			-- By default the alert is gonna be the golden flintlock one, but the other one is the golden wrench
			local scoreAlertText = actor.name .. " has obtained the <color=#ffd700>golden flintlock</color>, they are getting close on hitting the score limit!"
			if (killScore == self.scoreLimit) then
				scoreAlertText = actor.name .. " has obtained the <color=#ffd700>golden wrench</color>, Don't let them get a hit!"
			end

			-- Announce actor
		    self.airsoftBase.airsoftHUDBase:TriggerIndicatorText(scoreAlertText, 3)
		elseif (actor.isPlayer) then
			-- Some heads up for the player
			if (killScore == self.scoreLimit-2) then
				-- Give a heads up that the golden gun is next
				local goldenGunAlertText = "<color=#ffd700>Golden flintlock</color> is next"
				self.airsoftBase.airsoftHUDBase:TriggerIndicatorText(goldenGunAlertText, 3)
			end
		end
    elseif (killScore >= self.scoreLimit+1) then
	    -- If the killScore hits the scoreLimit
		if (not self.alreadyCalledWinner) then
			self.airsoftBase:EndMatch(actor)
		    self.alreadyCalledWinner = true
		end
	end
end

function LQS_AirsoftGunGame:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0))

		-- Get the airsoft base script
		local airsoftBase = _G.LQSSoarinsAirsoftBase
		if (airsoftBase) then
			self.airsoftBase = airsoftBase.self
		end

		-- Add onActorHit and onActorRecover listener
		if (self.airsoftBase) then
			self.airsoftBase:ManageListeners(false, "onActorHit", "[LQS:SA]GunGame", self.onActorHit)
			self.airsoftBase:ManageListeners(false, "onActorRecover", "[LQS:SA]GunGame", self.onActorRecover)
		end

	    -- Bake weapon list
	    -- Basically generates a list of weapons that are going to be used in the match
		self:GenerateWeaponList()
	end
end

function LQS_AirsoftGunGame:GenerateWeaponList()
	-- Generate weapon list 
	-- Loop 30 times (by default) to choose weapons the final two would be the final weapons
	-- golden flintlock (the first final weapon) and golden wrench (the second final weapon)
	for i = 1, self.scoreLimit-1 do
		-- The chosen weapon output, it will be always primary
		local chosenWeapon = WeaponManager.GetAiWeaponPrimary(self.airsoftBase:GetRandomPickStrategy(), Team.Blue or Team.Red)

		-- Secondary rng
		-- If the rifleOrWeapon variable is 2 then replace the chosen weapon with a secondary
		local rifleOrWeapon = math.random(1, 2)
		if (rifleOrWeapon == 2) then
			chosenWeapon = WeaponManager.GetAiWeaponSecondary(self.airsoftBase:GetRandomPickStrategy(), Team.Blue or Team.Red)
		end

		-- Output
		self.weaponList[i] = chosenWeapon
	end

	-- Apply golden gun and golden wrench as final weapons
	self.weaponList[#self.weaponList+1] = self.goldenFlintlock
	self.weaponList[#self.weaponList+1] = self.goldenWrench
end
