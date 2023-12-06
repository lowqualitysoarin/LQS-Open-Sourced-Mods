-- low_quality_soarin © 2023-2024
behaviour("LQS_Sliding")

function LQS_Sliding:Start()
	-- Important Scripts
	self.vaultingScript = _G.LQSArcadeMovementsInstance.vaultingSystem
	self.arcadeMovementsBase = _G.LQSArcadeMovementsInstance

	-- Base
	self.slideStartSpeed = 6.45
	self.sprintTime = 0.55

	self.declerationAmountLand = 7.85
	self.declerationAmountAir = 5.95

	-- Vars
	self.isSliding = false
	self.alreadySlided = false

	self.sprintTimer = 0
	self.defaultSpeed = nil

	self.slideSpeedMultiplier = 0
end

function LQS_Sliding:Update()
	if (self.disable) then return end
	local player = Player.actor

	-- Movement Core Support
	if (self.arcadeMovementsBase.movementCore) then
		self.arcadeMovementsBase:AddModifier(player, "LQSSliding", self.slideSpeedMultiplier)
	end

	-- Main Sliding System
	-- Slide timer handler
	self:SlideTimerHandler(player)

	-- If the player crouches and sprinted long enough then slide
	if (self:CanSlide() and player.isCrouching) then
		if (self.sprintTimer > self.sprintTime) then
			self.isSliding = true
		end
	end

	-- If the is sliding then initiate slide movement
	if (self.isSliding) then
		self:Slide()
	end
end

function LQS_Sliding:SlideTimerHandler(player)
	-- Check if the player is sprinting if so then initiate sprint timer
	-- Main
	self.sprintTimer = Mathf.Clamp(self.sprintTimer, 0, Mathf.Infinity)
	if (self:VelCheck() and player.isSprinting) then
		-- If the player is sprinting
		self.sprintTimer = self.sprintTimer + 1 * Time.deltaTime
	elseif (self:CanDecreaseSprintTime()) then
		-- If not
		self.sprintTimer = self.sprintTimer - 6.65 * Time.deltaTime
	end

	-- Reset if the player is vaulting
	if (self.vaultingScript.isVaulting) then
		self.sprintTimer = 0
	end 
end

function LQS_Sliding:CanDecreaseSprintTime()
	if (self.sprintTimer > 0) then
		if (Player.actor) then
			if (Player.actorIsGrounded) then
				return true
			end
		end
	end
	return false
end

function LQS_Sliding:Slide()
	-- Slide movement
	-- Get player
	local player = Player.actor

	-- Get default vars
	if (not self.defaultSpeed and not self.arcadeMovementsBase.movementCore) then
		self.defaultSpeed = player.speedMultiplier
	end

	-- Give the slide start speed
	if (not self.alreadySlided) then
		if (not self.arcadeMovementsBase.movementCore) then
			player.speedMultiplier = player.speedMultiplier + self.slideStartSpeed
		else
			self.slideSpeedMultiplier = self.slideStartSpeed
		end
		self.alreadySlided = true
	end

	-- Slide stop check
	if (not player.isCrouching or not self:VelCheck()) then
		self:StopSliding()
	end

	-- Knockdown system
	local knockdownSphere = Physics.OverlapSphere(player.transform.position + Vector3.up * 0.5, 0.55, RaycastTarget.ProjectileHit)

	if (#knockdownSphere > 0) then
		for _,obj in pairs(knockdownSphere) do
			-- Get the actor script if possible
			local actor = obj.gameObject.GetComponentInParent(Actor)

			if (actor and not actor.isPlayer) then
				actor.KnockOver(player.transform.forward * 5.25)
			end
		end
	end

	-- Start declaring slide
	local declarationAmount = self.declerationAmountLand
	if (not Player.actorIsGrounded) then
		declarationAmount = self.declerationAmountAir
	end
	
	if (not self.arcadeMovementsBase.movementCore) then
		player.speedMultiplier = player.speedMultiplier - declarationAmount * Time.deltaTime

	    -- Clamping
	    player.speedMultiplier = Mathf.Clamp(player.speedMultiplier, self.defaultSpeed, Mathf.Infinity)
	else
		self.slideSpeedMultiplier = self.slideSpeedMultiplier - declarationAmount * Time.deltaTime

		-- Clamping
		self.slideSpeedMultiplier = Mathf.Clamp(player.speedMultiplier, 0, Mathf.Infinity)
	end

	-- If the speed multiplier reaches default then stop sliding
	if (player.speedMultiplier == self.defaultSpeed or self.arcadeMovementsBase.movementCore and self.slideSpeedMultiplier <= 0) then
		self:StopSliding()
	end
end

function LQS_Sliding:StopSliding()
	-- Stops the sliding stuff
	local player = Player.actor

	-- Reset values
	if (not self.arcadeMovementsBase.movementCore) then
		player.speedMultiplier = self.defaultSpeed
	end

	self.isSliding = false
	self.alreadySlided = false
end

function LQS_Sliding:VelCheck()
	if (Player.actor.velocity.magnitude > 0) then
		if (not GameManager.isPaused) then
			return true
		end
	end
	return false
end

function LQS_Sliding:CanSlide()
	-- Checks if the player can slide
	if (Player.actor) then
		if (not Player.actor.isDead) then
			if (not Player.actor.isProne) then
				if (Player.actorIsGrounded) then
					if (not GameManager.isPaused) then
						if (not self.isSliding) then
							return true
						end
					end
				end
			end
		end
	end
	return false
end
