behaviour("MobileBase")

function MobileBase:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Parent Transform
	self.baseTransform = self.targets.baseTransform.transform

	-- Mobile Parts
	self.motor = self.targets.motor

	self.tireL = self.targets.tireL
	self.tireR = self.targets.tireR
	self.tireSteering = self.targets.tireSteer

	-- Mobile Parts
	self.steeringYaw = self.targets.steerYaw.transform
	self.tiresTransform = self.data.GetGameObjectArray("tire")

	-- Configurations
	self.speed = self.data.GetFloat("speed")
	self.turnSpeed = self.data.GetFloat("turnSpeed")

	self.newPointTime = self.data.GetFloat("newPointTime")
	self.slowDownMultiplier = self.data.GetFloat("slowDownMultiplier")
	self.turnSlowMultiplier = self.data.GetFloat("turnSlowMultiplier")
	self.buildUpMultiplier = self.data.GetFloat("buildUpMultiplier")

	-- Vital Bools
	self.motorActive = true
	self.tireLActive = true
	self.tireRActive = true
	self.tireSteeringActive = true

	-- Mobile Essentials
	self.targetDestination = nil
	self.previousPos = Vector3.zero

	self.motorSound = self.targets.motorSound.GetComponent(AudioSource)
	
	self.destinationSet = false
	self.canMove = true
	self.newPointStart = false
	self.alreadyGotMidpoint = false

	self.newPointTimer = 0
	self.currentSpeed = 0
	self.currentTurnSpeed = 0
	self.currentSpeedDrag = 0
	self.midPoint = 0

	-- Finishing Touches
	self.currentSpeed = self.speed
	self.currentTurnSpeed = self.turnSpeed
end

function MobileBase:Update()
	-- Vital Check
	self:CheckVitals()

	-- Main
	if (self.motorActive) then
		-- Navigation System
		-- This is gonna be hella painful
		self:Navigation()

		-- Speed Drag
		self:SpeedDrag()

	    -- Slow Down Multiplier
	    self:SlowMultiplier()
	end

	-- Timers
	self:Timers()
end

function MobileBase:SpeedDrag()
	-- Kinda like a speed fade in and fade out thing
	-- Checks first if the destination was set.
	if (self.destinationSet) then
		-- Calculate the distance between the destination and current position
		local distanceToPoint = (self.targetDestination - self.baseTransform.position).magnitude

		if (not self.alreadyGotMidpoint) then
		    self.midPoint = 0
			self.midPoint = (distanceToPoint / 2)
			self.alreadyGotMidpoint = true
		end

		-- Start calculating for the speed drag
		if (self.canMove) then
			if (distanceToPoint > self.midPoint) then
				self.currentSpeedDrag = self.currentSpeedDrag + self.buildUpMultiplier * Time.deltaTime
				self.currentSpeedDrag = Mathf.Clamp(self.currentSpeedDrag, 0, self.speed)
			elseif (distanceToPoint < self.midPoint) then
				self.currentSpeedDrag = self.currentSpeedDrag - self.buildUpMultiplier * Time.deltaTime
				self.currentSpeedDrag = Mathf.Clamp(self.currentSpeedDrag, 0, self.speed)
			end
		else
			self.currentSpeedDrag = self.currentSpeedDrag - self.buildUpMultiplier * Time.deltaTime
			self.currentSpeedDrag = Mathf.Clamp(self.currentSpeedDrag, 0, self.speed)
		end
	end
end

function MobileBase:SlowMultiplier()
	-- Adds up a slow down multiplier to the mobile
	-- if one of the tires are shot.
	local multiplier1 = 0
	local multiplierTurn1 = 0

	local multiplier2 = 0
	local multiplierTurn2 = 0

	local multiplier3 = 0
	local multiplierTurn3 = 0

	-- Start multiplying
	if (not self.tireLActive) then
		multiplier1 = self.slowDownMultiplier
		multiplierTurn1 = self.turnSlowMultiplier
	end

	if (not self.tireRActive) then
		multiplier2 = self.slowDownMultiplier
		multiplierTurn2 = self.turnSlowMultiplier
	end

	if (not self.tireSteeringActive) then
		multiplier3 = self.slowDownMultiplier
		multiplierTurn3 = self.turnSlowMultiplier
	end

	-- Speed Output
	self.currentSpeed = self.currentSpeedDrag - multiplier1 - multiplier2 - multiplier3
	self.currentTurnSpeed = self.turnSpeed - multiplierTurn1 - multiplierTurn2 - multiplierTurn3

	-- Finalize (Speed Clamping)
	self.currentSpeed = Mathf.Clamp(self.currentSpeed, 0, self.speed)
	self.currentTurnSpeed = Mathf.Clamp(self.currentTurnSpeed, 0, self.turnSpeed)
end

function MobileBase:Timers()
	-- New Destination Delay
	if (self.newPointStart) then
		self.newPointTimer = self.newPointTimer + 1 * Time.deltaTime
		if (self.newPointTimer >= self.newPointTime) then
			self.destinationSet = false
			self.newPointTimer = 0
			self.newPointStart = false
		end
	end
end

function MobileBase:Navigation()
	-- The Navigation System
	-- Get a viable destination.
	if (not self.destinationSet) then
	    self.targetDestination = self:GetRandomPoint()
		self.alreadyGotMidpoint = false
	end

	-- If the destination is set then move towards it
	if (self.destinationSet and self:IsUpright()) then
		-- Get the distance between the mobile and the destination
		local distanceToPoint = (self.targetDestination - self.baseTransform.position).magnitude

		-- Get the mobile velocity for motion
		local velocity = ((self.baseTransform.position - self.previousPos).magnitude) / Time.deltaTime
		self.previousPos = self.baseTransform.position

		-- Move towards destination
		self.baseTransform.position = Vector3.MoveTowards(self.baseTransform.position, self.targetDestination, Time.deltaTime * self.currentSpeed)

		-- Only works if the mobile can move
		if (self.canMove) then
			-- Steering
			-- Soo it won't look a little stale lmao.
		    -- Also another time check because the reason is just below this code.
		    if (distanceToPoint > 0.5) then
			    if (Time.deltaTime > 0) then
				    self:Steering(self.targetDestination)
			    end
		    end
			
			-- Only works when the mobile is not close to the destination
			if (distanceToPoint > 1) then
				-- Look towards destination (lmao)
				local posToLookAt = (self.targetDestination - self.baseTransform.position)
				posToLookAt.y = 0
	
				local finalRot = Quaternion.LookRotation(posToLookAt, self.baseTransform.up)
				self.baseTransform.rotation = Quaternion.Slerp(self.baseTransform.rotation, finalRot, Time.deltaTime * self.currentTurnSpeed)
			end
		end

		-- Doing a time check because these fuck up when paused.
		if (Time.deltaTime > 0) then
			-- Wheel motion
			-- Handles the wheel motion
			self:WheelMotion(velocity)

			-- Motor Sound Manager
		    -- Handles the motor sounds.
			self:MotorSound()
		end

		-- If the destination is reached then get a new destination
		if (distanceToPoint < 1) then
			self.newPointStart = true
		end
	end
end

function MobileBase:MotorSound()
	-- Handles the volume of the audio source depending on
	-- the mobile's velocity.
	self.motorSound.volume = self.currentSpeed * 50 / 100
end

function MobileBase:Steering(targetPoint)
	-- Basically a procedurally animated steering thing
	-- I can't think enough to put something in here because it is just self-explanatory.

	-- Only rotate to the Y axis
	local lookAt = (targetPoint - self.steeringYaw.position)
	lookAt.y = 0

	-- Rotate
	local finalRot = Quaternion.LookRotation(lookAt, self.steeringYaw.up)
	self.steeringYaw.rotation = Quaternion.Lerp(self.steeringYaw.rotation, finalRot, Time.deltaTime * self.currentTurnSpeed * 1.85)
end

function MobileBase:IsUpright()
	-- Checks if the mobile is upright
	local output = true

	if (Vector3.Dot(self.baseTransform.up, Vector3.down) > 0) then
		output = false
	else
		output = true
	end

	return output
end

function MobileBase:WheelMotion(currentVel)
	-- Motions of the wheel.. Simple as that!
	-- Start rotating
	if (#self.tiresTransform > 0) then
		for _,tire in pairs(self.tiresTransform) do
			tire.transform.Rotate(Vector3(0, 0, -currentVel * 5), Space.Self)
		end
	end
end

function MobileBase:GetRandomPoint()
	-- Gets a random point for the Navigation System

	-- It basically launches 8 raycasts around the object, if the first stage of the raycasts didn't hit anything
	-- then it will proceed to the second stage. This time it launches downwards if it hits something that means it is a
	-- viable destination. If there are multiple passed points it will just choose a random one.
	local chosenPoint = nil
	local passedPoints = {}

	local numberOfRays = 8
	local sideRange = 2.85
	local downRange = 0.55
	local angle = 180

	-- Raycast initiation
	for i = 1, numberOfRays do
		-- Initiate the first stage of the raycasts
		local rot = self.transform.rotation
		local rotMod = Quaternion.AngleAxis((i / numberOfRays - 1) * angle * 2 - angle, self.transform.up)
		local dir = rot * rotMod * Vector3.forward

		local firstRay = Ray(self.transform.position, dir)
		local raySides = Physics.Spherecast(firstRay, 1, sideRange, RaycastTarget.ProjectileHit)

		-- Debugging
		-- Debug.DrawLine(self.transform.position, self.transform.position + dir * sideRange, Color.red)

		-- Initiate the second stage of the raycasts
		if (raySides == nil) then
			local secPos = self.transform.position + dir * sideRange
			local secondRay = Ray(secPos, Vector3.down)

			local rayDown = Physics.Raycast(secondRay, downRange, RaycastTarget.ProjectileHit)

			-- Debugging
			-- Debug.DrawLine(secPos, secPos + Vector3.down * downRange, Color.yellow)

			-- If it hits anything then add to the passed list of raycast
			if (rayDown ~= nil) then
				passedPoints[#passedPoints+1] = rayDown.point
			end
		end
	end

	-- Finalize (Choosing a random point just incase if there are multiple passed points)
	if (#passedPoints > 0) then
		local chosenInt = math.random(#passedPoints)
		chosenPoint = passedPoints[chosenInt]
	end

	-- Return the chosen destination
	if (chosenPoint) then
		self.destinationSet = true
		return chosenPoint
	end
end

function MobileBase:CheckVitals()
	-- Same thing on what I did for the base of the sentry script,

	-- but this one is for the mobile system. This only checks the tires
	-- and motor.

	-- Motor
	if (self.motor ~= nil) then
		self.motorActive = true
	else
		self.motorActive = false
	end

	-- Left Tire
	if (self.tireL ~= nil) then
		self.tireLActive = true
	else
		self.tireLActive = false
	end

	-- Right Tire
	if (self.tireR ~= nil) then
		self.tireRActive = true
	else
		self.tireRActive = false
	end

	-- Steering Tire
	if (self.tireSteering ~= nil) then
		self.tireSteeringActive = true
	else
		self.tireSteeringActive = false
	end
end
