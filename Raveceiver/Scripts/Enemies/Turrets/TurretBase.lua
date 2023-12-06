behaviour("TurretBase")

function TurretBase:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Important Parts
	self.sightPoint = self.targets.sightPoint.transform
	self.targetPoint = self.targets.targetPoint.transform
	self.firePoint = self.targets.firePoint.transform

	self.lightClear = self.targets.lightClear
	self.lightAlert = self.targets.lightAlert
	self.lightEngage = self.targets.lightEngage

	self.pivotMotor = self.targets.pivotMotor
	self.camera = self.targets.camera
	self.cameraLens = self.targets.cameraLens
	self.gun = self.targets.gun
	self.ammoBox = self.targets.ammoBox

	-- Turret Parts
	self.yaw = self.targets.rotatorYaw.transform
	self.pitch = self.targets.rotatorPitch.transform

	-- Configurations
	self.isMobile = self.data.GetBool("isMobile")

	self.visionRange = self.data.GetFloat("visionRange")
	self.alertedVisionRange = self.data.GetFloat("visionRangeAlerted")

	self.alertTime = self.data.GetFloat("alertTime")
	self.fireTime = self.data.GetFloat("fireTime")
	self.cooldownTime = self.data.GetFloat("cooldownTime")
	self.reloadTime = self.data.GetFloat("reloadTime")

	self.bulletsPerClick = self.data.GetInt("bulletsPerClick")

	-- Mobile Parts (Only fill up when turret is mobile)
	self.mobileScript = nil

	if (self.isMobile) then
		self.mobileScript = self.targets.mobileScript.GetComponent(ScriptedBehaviour).self
	end

	-- Vital Bools
	self.motorActive = true
	self.cameraActive = true
	self.cameraLensActive = true
	self.gunActive = true
	self.ammoBoxActive = true

	-- Turret States
	self.turretStates = {
		"Idle",
		"Engage",
		"Alerted"
	}

	self.currentState = self.turretStates[1]

	-- Turret Essentials
	self.projectile = self.data.GetGameObject("projectile")

	self.fireAudio = self.targets.fireAud.GetComponent(AudioSource)
	self.alertAudio = self.targets.alertAud.GetComponent(AudioSource)
	self.clearAudio = self.targets.clearAud.GetComponent(AudioSource)

	self.lookPoint = self.targets.lookPoint.transform
	self.targetPos = self.lookPoint.position

	self.alertTimer = 0
	self.fireTimer = 0
	self.timesFired = 0
	self.cooldownTimer = 0
	self.reloadTimer = 0
	
	self.targetSpotted = false
	self.reloadStart = false
	self.canFire = true
	self.isShooting = false

	-- Finishing Touches
	self.targetPoint.position = self.targetPos
end

function TurretBase:Update()
	-- Check Vitals
	self:VitalCheck()

	-- Timers
	self:Timers()

	-- Turret Activites
	if (self.motorActive) then
		-- States
		if (self.currentState == self.turretStates[1]) then
			self:Idle()
		elseif (self.currentState == self.turretStates[2]) then
			self:Attack()
		elseif (self.currentState == self.turretStates[3]) then
			self:Alerted()
		end

		-- Light States Handler
		self:LightStates()

		-- LookAt Setup
	    if (self.cameraActive and self.cameraLensActive and self.motorActive or self.currentState == self.turretStates[1]) then
			if (self:IsUpright()) then
				self:LookAtSetup()
			end
		end
	end

	-- Mobile Manager
	if (self.isMobile) then
		self.mobileScript.canMove = self:CanMove()
	end
end

function TurretBase:LightStates()
	-- Change Light State
	if (self.cameraActive and self.cameraLensActive) then
		if (self.currentState == self.turretStates[1]) then -- Clear State
			self.lightClear.SetActive(true)
			self.lightAlert.SetActive(false)
			self.lightEngage.SetActive(false)
		elseif (self.currentState == self.turretStates[3] or self.currentState == self.turretStates[2]) then -- Alert/Engage State
			if (not self.isShooting) then -- Attack State
				self.lightClear.SetActive(false)
				self.lightAlert.SetActive(true)
				self.lightEngage.SetActive(false)
			else
				self.lightClear.SetActive(false)
				self.lightAlert.SetActive(false)
				self.lightEngage.SetActive(true)
			end
		end
	end
end

function TurretBase:CanMove()
	-- Determines if the mobile can move. If it is mobile.
	local output = true

	if (
		not self.cameraActive or 
		not self.cameraLensActive or 
		not self.motorActive 
		or self.currentState == self.turretStates[2] 
		or self.currentState == self.turretStates[3]
	) then
		output = false
	end

	return output
end

function TurretBase:Timers()
	-- Fire Cooldown
	if (not self.canFire) then
		self.cooldownTimer = self.cooldownTimer + 1 * Time.deltaTime
		if (self.cooldownTimer >= self.cooldownTime) then
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

function TurretBase:LookAtSetup()
	-- My own version of look at. Because the others I know is broken.
	-- Target point
	self.targetPoint.position = Vector3.MoveTowards(self.targetPoint.position, self.targetPos, Time.deltaTime * 15)

	-- Turret Rotation
	local finalPos = (self.targetPoint.position - self.yaw.position)
	finalPos.y = Mathf.Clamp(finalPos.y, 0.25, 0.3)

	self.yaw.rotation = Quaternion.LookRotation(finalPos, self.transform.up)
end

function TurretBase:Attack()
	-- Lock on target
	local target = nil

	if (Player.actor.isFallenOver) then
		target = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).position
	else
		target = Player.actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest).position
	end

	if (self.motorActive) then
		-- Give target pos
		self.targetPos = target
	end

	-- Attack
	if (self.gunActive and self.cameraActive and self.cameraLensActive) then
		-- This is basically a charge attack. Soo it gives a little time for the player to move out of the turret's sight.
		-- If the player didn't manage to take cover, then shoot.
		self.fireTimer = self.fireTimer + 1 * Time.deltaTime

		if (self.fireTimer >= self.fireTime) then
			-- Main shoot thing with reload and cooldown stuff
			if (self.timesFired < self.bulletsPerClick) then
				if (self.canFire) then
					-- Shoot
					self:Shoot(target)
					self.timesFired = self.timesFired + 1

					-- Shooting Bool
					self.isShooting = true

					-- Disable canfire for cooldown
					self.canFire = false
				end
			else
				-- Reload
				if (self.ammoBoxActive) then
					self.reloadStart = true
				end
			end
		else
			-- Shooting Bool
			self.isShooting = false
		end
	else
		-- Reset Timer
		self.fireTimer = 0

		-- Shooting Bool
		self.isShooting = false
	end

	-- Vision System
	if (self.cameraActive and self.cameraLensActive) then
		if (not self:Vision() or not self:TargetInRange(self.alertedVisionRange)) then
			-- Reset attack timer
			self.fireTimer = 0

			-- Reload while idle
			if (self.ammoBoxActive) then
				self.reloadStart = true
			end

			-- Shooting Bool
		    self.isShooting = false

			-- Change state
			self.currentState = self.turretStates[3]
		end
	end
end

function TurretBase:IsUpright()
	-- Checks if the mobile is upright
	local output = true

	if (Vector3.Dot(self.transform.up, Vector3.down) > 0) then
		output = false
	else
		output = true
	end

	return output
end

function TurretBase:Shoot(target)
	-- Literally the shooting function
	-- Get the direction of the target
	local direction = (target - self.firePoint.position)

	-- Play particle effects if it has some
	if (self.firePoint.childCount > 0) then
		local particleSystem = self.firePoint.gameObject.GetComponentInChildren(ParticleSystem)

		if (particleSystem ~= nil) then
			particleSystem.Play(true)
		end
	end

	-- Play the fire sound
	if (self.fireAudio ~= nil) then
		self.fireAudio.Play()
	end

	-- Spawns the projectile
	local projectile = GameObject.Instantiate(self.projectile, self.firePoint.position, Quaternion.LookRotation(direction))
end

function TurretBase:Alerted()
	-- Alert Timer
	-- When the timer exceeds it returns back to idle state
	self.alertTimer = self.alertTimer + 1 * Time.deltaTime

	if (self.alertTimer > self.alertTime) then
		-- Change State
		self.currentState = self.turretStates[1]

		-- Play Sound
		self.clearAudio.Play()

		-- Reset Timer
		self.alertTimer = 0
	end

	-- Vision System
	-- When the player is spotted again then return to attack state.
	if (self.cameraActive and self.cameraLensActive) then
		if (self:TargetInRange(self.alertedVisionRange)) then
			if (self:Vision()) then
				self.currentState = self.turretStates[2]
				self.alertTimer = 0
			end
		end
	end
end

function TurretBase:Idle()
	-- Idle state of the turret. Literally just looking left and right.
	-- Until it sees a viable target.

	-- Look
	if (self.motorActive) then
		-- Give target pos
		self.targetPos = self.lookPoint.position
	end

	-- Vision System
	if (self.cameraActive and self.cameraLensActive) then
		if (self:TargetInRange(self.visionRange)) then
			if (self:Vision()) then
				self.currentState = self.turretStates[2]

				-- Play Sound
				self.alertAudio.Play()
			end
		end
	end
end

function TurretBase:Vision()
	-- A hacky way to make a vision cone alike thing because RS is way damn limited.
	local spotted = false

	local target = nil

	if (Player.actor.isFallenOver) then
		target = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest)
	else
		target = Player.actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest)
	end
	
	local visionCast = Physics.Linecast(self.sightPoint.position, target.position, RaycastTarget.ProjectileHit)

	if (visionCast ~= nil) then
		local actorScript = visionCast.collider.gameObject.GetComponentInParent(Actor)

		if (actorScript ~= nil and actorScript.isPlayer) then
			local dirToTarget = Vector3.Normalize(visionCast.point - self.sightPoint.position)
			local dotProduct = Vector3.Dot(self.sightPoint.forward, dirToTarget)
	
			if (dotProduct > 0.606) then
				spotted = true
			end
		end
	end

	return spotted
end

function TurretBase:TargetInRange(givenRange)
	-- It is a bool to check if the Player is in the target range.
	local isInRange = false

	if (Player.actor) then
		local target = Player.actor.transform
		local distanceToPlayer = (target.position - self.transform.position).magnitude
	
		if (distanceToPlayer < givenRange) then
			isInRange = true
		else
			isInRange = false
		end
	end

	return isInRange
end

function TurretBase:VitalCheck()
	-- Checks The Turret's Vitals

	-- This checks the turret's vitals. When one vital is destroyed the turret may stop functioning properly.
	-- For example when the Ammo Box is destroyed then the turret can't reload.

	-- Pivot Motor
	if (self.pivotMotor ~= nil) then
		self.motorActive = true
	else
		self.motorActive = false
	end

	-- Camera
	if (self.camera ~= nil) then
		self.cameraActive = true
	else
		self.cameraActive = false
	end

	-- Camera Lens
	if (self.cameraLens ~= nil) then
		self.cameraLensActive = true
	else
		self.cameraLensActive = false
	end

	-- Gun
	if (self.gun ~= nil) then
		self.gunActive = true
	else
		self.gunActive = false
	end

	-- Ammo Box
	if (self.ammoBox ~= nil) then
		self.ammoBoxActive = true
	else
		self.ammoBoxActive = false
	end
end
