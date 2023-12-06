-- low_quality_soarin © 2023-2024
behaviour("LQS_Dashing")

function LQS_Dashing:Start()
	-- Important Scripts
	self.slidingScript = _G.LQSArcadeMovementsInstance.slidingSystem
	self.vaultingScript = _G.LQSArcadeMovementsInstance.vaultingSystem
	self.arcadeMovementsBase = _G.LQSArcadeMovementsInstance

	-- Base
	self.dashKey = nil

	-- Vars
	self.dashInt = 3
	self.currentDashInt = self.dashInt

	self.dashSpeed = 4.5
	self.dashRegenTime = 1.25
	self.dashCooldown = 0.15

	self.canDash = true
	self.isRegeneratingStamina = false

	self.dashSpeedMultiplier = 0
end

function LQS_Dashing:Update()
	if (self.disable) then return end

	-- Stamina Clamp
	self.currentDashInt = Mathf.Clamp(self.currentDashInt, 0, self.dashInt)

	-- Movement Core Support
	if (self.arcadeMovementsBase.movementCore) then
		self.arcadeMovementsBase:AddModifier(Player.actor, "LQSDashing", self.dashSpeedMultiplier)
	end

	-- Dashing System Base
	if (self:CanDash()) then
		-- If the key is pressed then dash in 10 seconds flat
		if (Input.GetKeyDown(self.dashKey)) then
			self.script.StartCoroutine(self:Dash())

			-- Cooldown
			self.canDash = false
			self.script.StartCoroutine(self:DashCooldown())
		end
	end

	-- Stamina Regen
	if (self.currentDashInt < self.dashInt and not self.isRegeneratingStamina) then
		self.script.StartCoroutine(self:DashRegen())
	end
end

function LQS_Dashing:DashRegen()
	return function()
		self.isRegeneratingStamina = true

		local time = 0
		while (time < self.dashRegenTime) do
			time = time + 1 * Time.deltaTime
			coroutine.yield(WaitForSeconds(0))
		end

		self.currentDashInt = self.currentDashInt + 1
		self.isRegeneratingStamina = false
	end
end

function LQS_Dashing:DashCooldown()
	-- Self-explanatory
	return function()
		coroutine.yield(WaitForSeconds(self.dashCooldown))
		self.canDash = true
	end
end

function LQS_Dashing:Dash()
	return function()
	    -- Get the needed vars
		local player = Player.actor
	    local playerRB = player.gameObject.GetComponentInParent(Rigidbody)

		local time = 0
		local defPlayerSpeed = player.speedMultiplier
		local appliedDashSpeed = false
    
	    -- Start dashing
		while (time < 0.065) do
			-- Increase speed
			if (not appliedDashSpeed) then
				if (not self.arcadeMovementsBase.movementCore) then
					player.speedMultiplier = player.speedMultiplier + self.dashSpeed
				else
					self.dashSpeedMultiplier = self.dashSpeed
				end

				appliedDashSpeed = true
			end
			time = time + 1 * Time.deltaTime

			-- Disable rigidbody gravity
			-- Only on air
			if (not Player.actorIsGrounded) then
				playerRB.useGravity = false
			end

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end

		-- Revert values
		if (not self.arcadeMovementsBase.movementCore) then
			player.speedMultiplier = defPlayerSpeed
		else
			self.dashSpeedMultiplier = defPlayerSpeed
		end
		playerRB.useGravity = true

		-- Decrease stamina and some clamping
		self.currentDashInt = self.currentDashInt - 1
	end
end

function LQS_Dashing:CanDash()
	-- Checks if the player can dash
	if (Player.actor) then
		if (not Player.actor.isDead) then
			if (not Player.actor.isFallenOver) then
				if (not Player.actor.activeVehicle) then
					if (Player.actor.velocity.magnitude > 0) then
						if (not self.vaultingScript.isVaulting) then
							if (not self.slidingScript.isSliding) then
								if (not GameManager.isPaused) then
									if (self.canDash) then
										if (self.currentDashInt > 0) then
											return true
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end
