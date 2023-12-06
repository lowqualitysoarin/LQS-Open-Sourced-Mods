behaviour("DroneBase")

function DroneBase:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.rb = self.gameObject.GetComponent(Rigidbody)

	-- Important Parts
	self.sightPoint = self.targets.sightPoint.transform

	self.lightClear = self.targets.lightClear
	self.lightAlert = self.targets.lightAlerted
	self.lightEngage = self.targets.lightEngage

	self.motor = self.targets.motor
	self.battery = self.targets.battery
	
	self.rotor1 = self.targets.rotor1
	self.rotor2 = self.targets.rotor2

	self.camera = self.targets.camera
	self.cameraLens = self.targets.cameraLens

	-- Drone Parts
	self.rotorTop = self.targets.rotorTop.transform
	self.rotorBottom = self.targets.rotorBottom.transform

	-- Vital Bools
	self.motorActive = true
	self.batteryActive = true
	self.rotorsActive = true
	self.cameraActive = true
	self.cameraLensActive = true

	-- Config
	self.hasGun = self.data.GetBool("hasGun")

	self.speed = self.data.GetFloat("speed")

	self.visionRange = self.data.GetFloat("visionRange")
	self.alertedVisionRange = self.data.GetFloat("alertedVisionRange")

	self.alertTime = self.data.GetFloat("alertTime")
	self.chaseTime = self.data.GetFloat("chaseTime")

	self.hoverHeight = self.data.GetFloat("hoverHeight")

	-- Drone Weapons
	if (not self.hasGun) then -- Taser
		self.weaponScript = self.targets.weaponScript.GetComponent(ScriptedBehaviour).self
	elseif (self.hasGun) then -- Gun
		self.weaponScript = self.targets.weaponScript.GetComponent(ScriptedBehaviour).self
	end

	-- Drone States
	self.droneStates = {
		"Idle",
		"Engage",
		"Alerted",
		"Dead"
	}

	self.currentState = self.droneStates[1]

	-- Drone Essentials
	self.targetPoint = GameObject.Instantiate(self.targets.targetPosOrig, self.transform.position, Quaternion.identity).transform
	self.targetPos = Vector3.zero
	self.hoverPos = self.transform.position
	self.newPos = Vector3.zero

	self.soundClear = self.targets.soundClear.GetComponent(AudioSource)
	self.soundAlert = self.targets.soundAlert.GetComponent(AudioSource)
	self.hoverSound = self.targets.hoverSound.GetComponent(AudioSource)

	self.alertTimer = 0
	self.chaseTimer = 0
	self.hoverSinTimer = 0
	self.secondaryTimer = 0

	self.isAttacking = false
	self.targetSpotted = false
	self.canMove = true
	self.allowedToHover = true
	self.allowToBalanceRot = true
end

function DroneBase:Update()
	-- Check Vitals
	self:VitalCheck()

	-- Drone Activities
	if (self:IsFunctional()) then
		-- States
		if (self.currentState == self.droneStates[1]) then
			self:Idle()
		elseif (self.currentState == self.droneStates[2]) then
			if (self.hasGun) then
				self:Engage()
			else
				self:EngageRush()
			end
		elseif (self.currentState == self.droneStates[3]) then
			self:Alerted()
		end

		-- Target Look At
		if (not self.allowBalanceRot and self:CanLockOn()) then
			self:LookAtTarget(self.targetPoint)
		end

		-- Rotor Animation
		self:Rotors()

		-- Handles the isAttacking state
		if (self.weaponScript ~= nil) then
			self.isAttacking = self.weaponScript.isAttacking
		end

		-- Light States Handler
		self:LightStates()
	else
		-- Switch to dead state because its dead.
		self.currentState = self.droneStates[4]

		-- Dead State
	    if (self.currentState == self.droneStates[4]) then
		    self:Dead()
	    end
	end
end

function DroneBase:IsFunctional()
	-- Checks if all drone's vital parts are active
	local output = false

	if (self.motorActive) then
		if (self.rotorsActive) then
			if (self.cameraActive) then
				if (self.batteryActive) then
					output = true
				end
			end
		end
	end

	return output
end

function DroneBase:LightStates()
	-- Change Light State
	if (self.cameraActive and self.cameraLensActive) then
		if (self.currentState == self.droneStates[1]) then -- Clear State
			self.lightClear.SetActive(true)
			self.lightAlert.SetActive(false)
			self.lightEngage.SetActive(false)
		elseif (self.currentState == self.droneStates[3] or self.currentState == self.droneStates[2]) then -- Alert/Engage State
			if (not self.isAttacking) then -- Attack State
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

function DroneBase:Rotors()
	-- Procedurally animated rotors
	if (self.rotorsActive) then
		self.rotorTop.Rotate(Vector3(0, 0, 1500 * Time.deltaTime), Space.Self)
		self.rotorBottom.Rotate(Vector3(0, 0, 1500 * Time.deltaTime), Space.Self)
	end
end

function DroneBase:CanLockOn()
	local output = false

	if (
		self.currentState == self.droneStates[2]
		or self.currentState == self.droneStates[3]
	) then
		output = true
	end

	return output
end

function DroneBase:LookAtTarget(targetPoint)
	-- Same thing on how I made the sentry to aim.
	-- But basic..

	-- Setup target point
	if (self.cameraActive and self.cameraLensActive) then
		targetPoint.position = Vector3.MoveTowards(targetPoint.position, self.targetPos, Time.deltaTime * 9)
	end

	-- Drone Look At
	self.transform.LookAt(targetPoint.position)
end

function DroneBase:FixedUpdate()
	-- Drone Activities (Fixed Update)
	if (self:IsFunctional()) then
		-- Hover
		if (not self:IsTimeStopped() and self:CanHover()) then
			self:Hover()
		end
	end
end

function DroneBase:Dead()
	-- Death state
	-- Its dead bruh...

	-- Disable hovering
	self.allowedToHover = false
	self.allowBalanceRot = false

	-- Fade out motor sound
	self.hoverSound.volume = Mathf.Lerp(self.hoverSound.volume, 0, Time.deltaTime * 4.5)

	-- Disable attacking
	self.weaponScript.canAttack = false
end

function DroneBase:Alerted()
	-- Alerted State
	-- Get the distance between the targetPos
	local distToTarget = (self.targetPoint.position - self.transform.position).magnitude

	-- Alert Timer
	self.alertTimer = self.alertTimer + 1 * Time.deltaTime
	if (self.alertTimer >= self.alertTime) then
		-- When the time is up swich beck to idle state
		self.currentState = self.droneStates[1]

		-- Play Sound
		self.soundClear.Play()

		-- Reset timer
		self.alertTimer = 0
	end

	-- Rush at the target's last position
	if (not self:IsTimeStopped()) then
		if (distToTarget > 5) then
			self.rb.AddForce(self.transform.forward * 20, ForceMode.Acceleration)
		end
	end

	-- Vision System
	if (self.cameraActive and self.cameraLensActive) then
		if (self:TargetInRange(self.visionRange)) then
			if (self:Vision()) then
				-- Change State
				self.currentState = self.droneStates[2]

				-- Reset alert timer
				self.alertTimer = 0
			end
		end
	end
end

function DroneBase:Engage()
	-- The Attack State (Gun)
	-- Tick allowed to balance rotation to false.
	self.allowToBalanceRot = false

	-- Get the target
	local target = nil

	if (Player.actor.isFallenOver) then
		target = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).position
	else
		target = Player.actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest).position
	end

	-- Give the target
	self.targetPos = target

	-- Vision System
	if (self.cameraActive and self.cameraLensActive) then
		if (not self:Vision() or not self:TargetInRange(self.alertedVisionRange)) then
			-- Change State
			self.currentState = self.droneStates[3]
		end
	end
end

function DroneBase:EngageRush()
	-- The Attack State (Taser)
	-- Tick allowed to balance rotation to false.
	self.allowToBalanceRot = false

	-- Get the distance between the targetPos
	local distToTarget = (self.targetPoint.position - self.transform.position).magnitude

	-- Get the target
	local target = nil

	if (Player.actor.isFallenOver) then
		target = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).position
	else
		target = Player.actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest).position
	end

	-- Give the target
	self.targetPos = target

	-- Rush at the target
	if (not self:IsTimeStopped()) then
	    if (distToTarget > 0.5) then
			self.rb.AddForce(self.transform.forward * 20, ForceMode.Acceleration)
		end
	end

	-- Vision System
	if (self.cameraActive and self.cameraLensActive) then
		if (not self:Vision() or not self:TargetInRange(self.alertedVisionRange)) then
			-- Change State
			self.currentState = self.droneStates[3]
		end
	end
end

function DroneBase:Idle()
	-- The Idle State
	-- Tick allowed to balance rotation to true because it doesn't seen any enemies.
	self.allowToBalanceRot = true

	-- Give the target
	-- This basically puts the target pos prefab to the front of the drone.
	self.targetPos = self.transform.forward

	-- Look Rotation
	self.transform.Rotate(0, 18.5 * Time.deltaTime, 0)

	-- Vision System
	if (self.cameraActive and self.cameraLensActive) then
		if (self:TargetInRange(self.visionRange)) then
			if (self:Vision()) then
				-- Change State
				self.currentState = self.droneStates[2]

				-- Play Sound
				self.soundAlert.Play()
			end
		end
	end
end

function DroneBase:CanHover()
	-- Determines if the drone is allowed to hover.
	local output = false

	if (self.allowedToHover) then
		if (self.motorActive) then
			if (self.rotorsActive) then
				if (self.cameraActive) then
					output = true
				end
			end
		end
	end

	return output
end

function DroneBase:Hover()
	-- Keeps the drone floating
	-- I don't know how to do this lmao.

	-- Hovering Calculations
	local yVel = self.rb.velocity.y + Physics.gravity.y

	-- Hover Effect
	self.hoverSinTimer = self.hoverSinTimer + 1 * Time.deltaTime
	if (self.hoverSinTimer >= 1) then
		yVel = yVel - 5.5 * Time.deltaTime

		self.secondaryTimer = self.secondaryTimer + 1 * Time.deltaTime
		if (self.secondaryTimer >= 3.5) then
			self.hoverSinTimer = 0
			self.secondaryTimer = 0
		end
	else
		yVel = yVel + 5.5 * Time.deltaTime

		self.secondaryTimer = self.secondaryTimer + 1 * Time.deltaTime
		if (self.secondaryTimer >= 3.5) then
			self.hoverSinTimer = 0
			self.secondaryTimer = 0
		end
	end

	-- Add Force
	self.rb.AddForce(Vector3(0, -yVel, 0), ForceMode.Acceleration)

	-- Balance rotation
	-- This is very bad...
	local normalRot = Quaternion.Euler(0, self.transform.eulerAngles.y, 0)
	self.transform.rotation = Quaternion.Lerp(self.transform.rotation, normalRot, Time.deltaTime * 20)
end

function DroneBase:TargetInRange(givenRange)
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

function DroneBase:Vision()
	-- A hacky way to make a vision cone alike thing because RS is way damn limited.
	local spotted = false

	local target = nil

	if (Player.actor.isFallenOver) then
		target = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest)
	else
		target = Player.actor.GetHumanoidTransformAnimated(HumanBodyBones.Chest)
	end
	
	local visionCast = Physics.Linecast(self.sightPoint.position, target.position, RaycastTarget.ProjectileHit)

	-- Debugging
	-- Debug.DrawLine(self.sightPoint.position, target.position, Color.yellow)

	if (visionCast ~= nil) then
		local actorScript = visionCast.collider.gameObject.GetComponentInParent(Actor)

		if (actorScript ~= nil and actorScript.isPlayer) then
			-- Direction to the target
			local dirToTarget = Vector3.Normalize(Vector3(visionCast.point.x, self.sightPoint.position.y - 1, visionCast.point.z) - self.sightPoint.position)

			-- Dot products both up and down
			local dotProductForward = Vector3.Dot(self.sightPoint.forward, dirToTarget)
			local dotProductDown = Vector3.Dot(-self.sightPoint.up, dirToTarget)

			-- Debugging
			-- Debug.DrawRay(Vector3(visionCast.point.x, self.sightPoint.position.y - 1, visionCast.point.z), Vector3.up, Color.green)
	
			if (dotProductForward > 0.707 or dotProductDown > 0.707 and self.currentState == self.droneStates[1] or self.currentState == self.droneStates[3]) then
				spotted = true
			elseif (dotProductForward > 0.707 or dotProductDown ~= 0 and self.currentState ~= self.droneStates[1] or self.currentState ~= self.droneStates[3]) then
				spotted = true
			end
		end
	end

	return spotted
end

function DroneBase:IsTimeStopped()
	local output = false

	if (Time.deltaTime == 0) then
		output = true
	end

	return output
end

function DroneBase:VitalCheck()
	-- Same thing on how I did it with the sentries. But for drones

	-- Motor
	if (self.motor ~= nil) then
		self.motorActive = true
	else
		self.motorActive = false
	end

	-- Battery
	if (self.battery ~= nil) then
		self.batteryActive = true
	else
		self.batteryActive = false
	end

	-- Rotors
	if (self.rotor1 ~= nil and self.rotor2 ~= nil) then
		self.rotorsActive = true
	else
		self.rotorsActive = false
	end

	-- Camera Armor
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
end
