behaviour("PlayerModifier")

function PlayerModifier:Start()
	-- Base
	-- Player Speed
	self.playerWalkSpeed = 0.65
	self.playerRunSpeed = 0.85
	self.suicideSpeed = 0.15

	-- Events
	GameEvents.onActorDied.AddListener(self, "OnPlayerDied")

	-- Vars
	self.isOnMindControl = false
end

function PlayerModifier:OnPlayerDied(actor)
	if (actor.isPlayer) then
		self.isOnMindControl = false
	end
end

function PlayerModifier:Update()
	-- Get the player
	local player = Player.actor

	-- Standard Modifiers
	self:StandardModif(player)
end

function PlayerModifier:StandardModif(player)
	-- Standard Modifiers for the player
	if (player and not player.isDead) then
		-- Player speed
		if (player.isSprinting and player.velocity.magnitude > 0 and not self.isOnMindControl) then
			player.speedMultiplier = self.playerRunSpeed
		elseif (not self.isOnMindControl) then
			player.speedMultiplier = self.playerWalkSpeed
		else
			player.speedMultiplier = self.suicideSpeed
		end
	end
end