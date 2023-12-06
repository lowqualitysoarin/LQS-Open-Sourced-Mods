behaviour("DroneGun")

function DroneGun:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.droneScript = self.targets.droneScript.GetComponent(ScriptedBehaviour).self

	-- Important Parts
	self.firePoint = self.targets.firePoint.transform
	self.gun = self.targets.gun

	-- Vital Bools
	self.gunActive = true

	-- Configuration
	self.projectile = self.data.GetGameObject("projectile")

	self.bulletsPerClick = self.data.GetInt("bulletsPerClick")

	self.fireTime = self.data.GetFloat("fireTime")
	self.cooldown = self.data.GetFloat("cooldown")
	self.reloadTime = self.data.GetFloat("reloadTime")

	-- Gun Essentials
	self.fireAudio = self.targets.fireAudio.GetComponent(AudioSource)

	self.cooldownTimer = 0
	self.fireTimer = 0
	self.reloadTimer = 0
	self.timesFired = 0

	self.isAttacking = false
	self.canFire = true
	self.reloadStart = false
	self.canAttack = true
end

function DroneGun:Update()
	-- Check Vitals
	self:VitalCheck()

	-- Timers
	self:Timers()

	-- Base
	if (self.droneScript ~= nil) then
		-- Checks if the drone's state is in attack
		if (self.droneScript.currentState == self.droneScript.droneStates[2] and self.droneScript:IsFunctional()) then
			if (self.gunActive and self.canAttack) then
				self:Attack()
			else
				self:ResetFeatures()
			end
		else
			self:ResetFeatures()
		end
	end
end

function DroneGun:ResetFeatures()
	-- Attack timer
	self.fireTimer = 0

	-- Shooting bool
	self.isAttacking = false
end

function DroneGun:Timers()
	-- Cooldown Timer
	if (not self.canFire) then
		self.cooldownTimer = self.cooldownTimer + 1 * Time.deltaTime
		if (self.cooldownTimer >= self.cooldown) then
			self.cooldownTimer = 0
			self.canFire = true
		end
	end

	-- Reload Timer
	if (self.reloadStart) then
		self.reloadTimer = self.reloadTimer + 1 * Time.deltaTime
		if (self.reloadTimer >= self.reloadTime) then
			self.timesFired = 0
			self.reloadTimer = 0
			self.reloadStart = false
		end
	end
end

function DroneGun:Attack()
	-- Attack the player
	-- Get the target
	local target = nil

	if (Player.actor.isFallenOver) then
		target = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).position
	else
		target = Player.actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest).position
	end

	-- Fire timer
	self.fireTimer = self.fireTimer + 1 * Time.deltaTime
	if (self.fireTimer >= self.fireTime) then
		-- If it reaches the fire time then start firing
		-- It works the same thing as the sentry.
		if (self.timesFired < self.bulletsPerClick) then
			if (self.canFire and self:DroneCamActive()) then
				-- Shoot
				self:Shoot(target)
				self.timesFired = self.timesFired + 1

				-- Attacking bool
				self.isAttacking = true

				-- Disable canFire for cooldown
				self.canFire = false
			end
		else
			-- Start Reloading
			self.reloadStart = true
		end
	else
		-- Attacking bool
		self.isAttacking = false
	end
end

function DroneGun:DroneCamActive()
	-- Checks if the drone's camera lens is active
	local output = false

	if (self.droneScript.cameraLensActive) then
		output = true
	end

	return output
end

function DroneGun:Shoot(target)
	-- Shoot at the target
	-- Get the target's direction
	local dirToTarget = (target - self.firePoint.position)

	-- Play particle effect (if it has some)
	if (self.firePoint.childCount > 0) then
		local particleSystem = self.firePoint.gameObject.GetComponentInChildren(ParticleSystem)

		if (particleSystem ~= nil) then
			particleSystem.Play(true)
		end
	end

	-- Play sound
	self.fireAudio.Play()

	-- Instantiate projectile
	local projectile = GameObject.Instantiate(self.projectile, self.firePoint.position, Quaternion.LookRotation(dirToTarget))
end

function DroneGun:VitalCheck()
	-- Vital check for the gun drone

	-- Gun
	if (self.gun ~= nil) then
		self.gunActive = true
	else
		self.gunActive = false
	end
end