-- low_quality_soarin © 2023-2024
-- Aims to achieve the "Unrecord" styled bodycam movement.
behaviour("LQS_BodyCam")

function LQS_BodyCam:Start()
	-- Base
	self.lookEuler = Vector3.zero
	self.camEuler = Vector3.zero
	
	-- Events and Monitors
	GameEvents.onActorSpawn.AddListener(self, "onPlayerSpawn")
	self.script.AddValueMonitor("MonitorActiveWeapon", "OnActiveWeaponChange")

	-- Configurables
	self.bodyCamX = self.script.mutator.GetConfigurationFloat("bodyCamX")
	self.bodyCamY = self.script.mutator.GetConfigurationFloat("bodyCamY")
	self.bodyCamHeight = self.script.mutator.GetConfigurationFloat("bodyCamHeight")

	self.lockCamToCenter = self.script.mutator.GetConfigurationBool("lockCamToCenter")
	self.enableBodyCamOverlay = self.script.mutator.GetConfigurationBool("enableBodyCamOverlay")
	self.zoomWithAnyGun = self.script.mutator.GetConfigurationBool("zoomWithAnyGun")

	self.toggleBodyCamKey = string.lower(self.script.mutator.GetConfigurationString("toggleBodyCamKey"))
	self:CheckKeyCode()

	self.walkBobIntensity = self.script.mutator.GetConfigurationFloat("walkBobIntensity")
	self.runBobIntensity = self.script.mutator.GetConfigurationFloat("runBobIntensity")

	self.weaponRollClamp = self.script.mutator.GetConfigurationFloat("weaponRollClamp")
	self.cameraRollClamp = self.script.mutator.GetConfigurationFloat("cameraRollClamp")

	self.aimingDeadzoneClamp = self.script.mutator.GetConfigurationFloat("aimingDeadzoneClamp")
	self.walkTiltAmount = self.script.mutator.GetConfigurationFloat("walkTiltAmount")

	self.disableTilting = self.script.mutator.GetConfigurationBool("disableTilting")
	self.disableGunTuck = self.script.mutator.GetConfigurationBool("disableGunTuck")

	self.borderFieldOfView = self.script.mutator.GetConfigurationRange("borderFieldOfView")

	-- Vars
	self.bodyCam = self.targets.mainCam.transform
	self.fpBodyCam = self.targets.fpBodyCam.transform
	self.fpRoot = nil

	self.bodyCamOverlay = self.targets.bodyCamOverlay.transform
	self.overlayBorder = self.targets.overlayBorder.GetComponent(Camera)
	self.fpBodyCamera = self.fpBodyCam.gameObject.GetComponent(Camera)

	self.rfFPCam = nil
	self.rfWeaponFPCamera = nil
	
	self.bodyCamWeaponParent = self.targets.bodyCamWeaponParent.transform
	self.bodyCamPivot = self.targets.bodyCamPivot.transform

	self.useBodyCam = true
	self.alreadyAppliedWeaponParent = false
	self.alreadyTriggeredResetCam = true
	self.playerAlreadySpawned = false
	self.zoomFPCam = false
	self.isInPhotomode = false

	self.weaponZSway = 0
	self.camZSway = 0
	self.tuckAmount = 0

	self.canStep = true
	self.bobTilt = Vector3.zero

	-- Finalize
	-- Apply bodycam height.
	self.bodyCam.localPosition = Vector3(self.bodyCamX, self.bodyCamHeight, self.bodyCamY)
	self.bodyCamOverlay.localPosition = self.bodyCam.localPosition

	self.overlayInitialPos = self.bodyCamOverlay.localPosition
	self.overlayInitialRot = self.bodyCamOverlay.localRotation
	
	-- Bodycam Overlay
	-- Enable/Disable Overlay
	self.bodyCamOverlay.gameObject.SetActive(self.enableBodyCamOverlay)

	-- Apply Border FOV
	self.overlayBorder.fieldOfView = self.borderFieldOfView

	-- Sets up parents
	self.script.StartCoroutine(self:SetupParents())
end

function LQS_BodyCam:SetupParents()
	return function()
		coroutine.yield(WaitForSeconds(0))
		-- Set fp root and cam
		local playerCamera = PlayerCamera.fpCamera

		self.fpRoot = playerCamera.transform.parent

		self.rfFPCam = playerCamera
		self.rfWeaponFPCam = self.rfFPCam.transform.GetChild(0)

		-- Set field of view
		self.defCamFOV = self.rfFPCam.fieldOfView
	    self.fpDefCamFOV = self.rfWeaponFPCam.gameObject.GetComponent(Camera).fieldOfView

		-- Set parent of the fp camera
		playerCamera.transform.parent = self.bodyCam
	end
end

function LQS_BodyCam:CheckKeyCode()
	-- Basically converts it to a keycode when its a unique one
	local uniqueBinds = {
		{"leftalt", KeyCode.LeftAlt},
		{"rightalt", KeyCode.RightAlt},
		{"capslock", KeyCode.CapsLock},
		{"tab", KeyCode.Tab},
		{"rightshift", KeyCode.RightShift},
		{"leftshift", KeyCode.LeftShift},
		{"pageup", KeyCode.PageUp},
		{"pagedown", KeyCode.PageDown},
		{"delete", KeyCode.Delete},
		{"backspace", KeyCode.Backspace},
		{"space", KeyCode.Space},
		{"clear", KeyCode.Clear},
		{"uparrow", KeyCode.UpArrow},
		{"downarrow", KeyCode.DownArrow},
		{"rightarrow", KeyCode.RightArrow},
		{"leftarrow", KeyCode.LeftArrow},
		{"insert", KeyCode.Insert},
		{"home", KeyCode.Home},
		{"end", KeyCode.End},
		{"f1", KeyCode.F1},
		{"f2", KeyCode.F2},
		{"f3", KeyCode.F3},
		{"f4", KeyCode.F4},
		{"f5", KeyCode.F5},
		{"f6", KeyCode.F6},
		{"f7", KeyCode.F7},
		{"f8", KeyCode.F8},
		{"f9", KeyCode.F9},
		{"f10", KeyCode.F10},
		{"f11", KeyCode.F11},
		{"f12", KeyCode.F12},
		{"f13", KeyCode.F13},
		{"f14", KeyCode.F14},
		{"f15", KeyCode.F15},
		{"mouse0", KeyCode.Mouse0},
		{"mouse1", KeyCode.Mouse1},
		{"mouse2", KeyCode.Mouse2},
		{"mouse3", KeyCode.Mouse3},
		{"mouse4", KeyCode.Mouse4},
		{"mouse5", KeyCode.Mouse5},
		{"mouse6", KeyCode.Mouse6},
		{"none", KeyCode.None}
	}

	for index,bind in pairs(uniqueBinds) do
		-- If the binds are the same then bind it to it
		if (self.toggleBodyCamKey == bind[1]) then
			self.toggleBodyCamKey = bind[2]
			break
		end
	end
end

function LQS_BodyCam:MonitorActiveWeapon()
	return Player.actor.activeWeapon
end

function LQS_BodyCam:OnActiveWeaponChange(weapon)
	if (not weapon) then return end

	-- Fix FOV
	self.rfFPCam.fieldOfView = self.defCamFOV
	self.fpBodyCamera.fieldOfView = self.fpDefCamFOV

	-- Parent the weapon
	self.script.StartCoroutine(self:ParentWeapon(weapon))
end

function LQS_BodyCam:ParentWeapon(weapon)
	-- Parent the weapon to the new weapon parent
	return function()
		if (weapon.transform.parent == self.bodyCamWeaponParent) then return end
		if (Player.actor.activeSeat and Player.actor.activeSeat.activeWeapon) then return end

		coroutine.yield(WaitForSeconds(0.05))

		weapon.transform.parent = self.bodyCamWeaponParent

		weapon.transform.localPosition = Vector3.zero
		weapon.transform.localRotation = Quaternion.identity
	end
end

function LQS_BodyCam:OnPlayerSpawn(actor)
	if (actor.isPlayer) then
		-- Apply new weapon parent
		if (not self.alreadyAppliedWeaponParent) then
			local curWeapon = actor.activeWeapon
			if (curWeapon) then
				self.bodyCamWeaponParent.parent = curWeapon.transform.parent

				self.bodyCamWeaponParent.localPosition = Vector3.zero
				self.bodyCamWeaponParent.localRotation = Quaternion.identity

				self.alreadyAppliedWeaponParent = true
			end
		end

		-- Reset Body Cam
		self:ResetBodyCam(true)

		-- Check player already spawned
		self.playerAlreadySpawned = true
	end
end

function LQS_BodyCam:FixedUpdate()
	-- Base Lerp
	if (self:CanLerp() and self:CamActiveBool()) then
		if (self.useBodyCam) then
			if (self.rfFPCam and not self.zoomFPCam) then
				self.rfFPCam.fieldOfView = self.defCamFOV
			end

			self:BodyCamLerp()
			self:CamLerp()

			self.alreadyTriggeredResetCam = false
		end
	elseif (not self.alreadyTriggeredResetCam) then
		self:ResetBodyCam()
	end
end

function LQS_BodyCam:ResetBodyCam(spawnReset)
	-- Literally resets the body cam back to normal cam
	-- Reset Weapon Transform.
	self.bodyCamWeaponParent.localRotation = Quaternion.identity
	self.bodyCamWeaponParent.localPosition = Vector3.zero

	-- Reset Main Body Cam
	self.bodyCam.localRotation = Quaternion.identity
	self.fpBodyCamera.fieldOfView = self.fpDefCamFOV

	-- Reset Main Vars
	self.lookEuler = Vector3.zero
	self.camEuler = Vector3.zero
	self.bobTilt = Vector3.zero

	self.canStep = true

	self.weaponZSway = 0
	self.camZSway = 0
	self.tuckAmount = 0

	-- End
	if (not spawnReset) then
		self.alreadyTriggeredResetCam = true
	end
end

function LQS_BodyCam:LateUpdate()
	-- Important Bodycam Stuff
	self:BodyCamHandler()

	-- Only if it can lerp
	if (self:CanLerp()) then
		-- Bodycam Toggle
		if (Input.GetKeyDown(self.toggleBodyCamKey)) then
			self.useBodyCam = not self.useBodyCam
		end

		-- Pivot Handler and Overlay Handler
		self:BodyCamPivotHandler()
		self:OverlayHandler()
	end
end

function LQS_BodyCam:OverlayHandler()
	-- Handles the overlay
	-- Rotate the overlay.
	local overlayYRot = Vector3(self.camEuler.x, self.camEuler.y, self.camZSway)
	self.bodyCamOverlay.localRotation = Quaternion.Lerp(self.bodyCamOverlay.localRotation, Quaternion.Euler(overlayYRot), Time.unscaledDeltaTime * 2.15)
end

function LQS_BodyCam:BodyCamHandler()
	-- Handles the main bodycam whether it should appear or nah.
	if (self:CamActiveBool()) then
		self:CameraControl()
		
		if (self.enableBodyCamOverlay) then
			self.bodyCamOverlay.gameObject.SetActive(true)
		end
	else
		self:CameraControl(true)

		if (self.enableBodyCamOverlay) then
			self.bodyCamOverlay.gameObject.SetActive(false)
		end
	end
end

function LQS_BodyCam:CameraControl(disable)
	if (disable) then
		-- Disable
		self.fpBodyCam.gameObject.SetActive(false)
		if (self.rfWeaponFPCam) then
			self.rfWeaponFPCam.gameObject.SetActive(true)
		end
	else
		-- Enable
		self.fpBodyCam.gameObject.SetActive(true)
		if (self.rfWeaponFPCam) then
			self.rfWeaponFPCam.gameObject.SetActive(false)
		end
	end
end

function LQS_BodyCam:CamActiveBool()
	-- A bool to control the camera activation
	if (self.useBodyCam) then
		if (Player.actor) then
			if (not Player.actor.isDead) then
				if (not Player.isSpectator) then
					if (not Player.actor.isFallenOver) then
						return true
					end
				end
			end
		end
	end
	return false
end

function LQS_BodyCam:BodyCamPivotHandler()
	-- Handler of the cam pivot
	-- Mimics the player's fpview position and rotation
	if (not Player.actor) then return end
	if (not self.fpRoot) then return end

	self.bodyCamPivot.position = self.fpRoot.position
	self.bodyCamPivot.rotation = self.fpRoot.rotation
end

function LQS_BodyCam:CanLerp()
	-- Some bool that runs the lerp when it passes
	if (not GameManager.isPaused) then
		if (Time.timeScale > 0) then
			return true
		end
	end
	return false
end

function LQS_BodyCam:MovementCheck()
	-- Checks the player's movements
	local vel = Player.actor.velocity.magnitude

	local state1 = "Idle"
	local state2 = "Idle"

	if (vel > 1) then
        -- Walking Forward/Backwards
        if (Input.GetKeyBindAxis(KeyBinds.Vertical) > 0) then
        	state1 = "WalkingForwards"
        elseif (Input.GetKeyBindAxis(KeyBinds.Vertical) < 0) then
        	state1 = "WalkingBackwards"
        end
        
        -- Sideways Walking
        if (Input.GetKeyBindAxis(KeyBinds.Horizontal) > 0) then
        	state2 = "WalkingRight"
        elseif (Input.GetKeyBindAxis(KeyBinds.Horizontal) < 0) then
        	state2 = "WalkingLeft"
        end
	end

	-- Output
	return state1, state2
end

function LQS_BodyCam:CamLerp()
	-- Camera Lerp
	-- Because it causes jitters on Update()
	if (not Player.actor) then return end

	local tiltMouseX = Input.GetAxisRaw("Mouse X")
	local curWeapon = Player.actor.activeWeapon

	-- BodyCam Bob
	self:BodyCamBob(curWeapon)

	-- Calculation or something
	if (not SpawnUi.isOpen) then
		if (not self.disableTilting) then
			self.camZSway = self.lookEuler.z + self:ClampT(-tiltMouseX, -self.cameraRollClamp, self.cameraRollClamp) * 8.5
			self.camZSway = Mathf.Lerp(self.camZSway, 0, 4.85 * Time.unscaledDeltaTime)
		end
	
		self.camEuler = Vector3(self.lookEuler.x, self.lookEuler.y, self.camZSway) + self.bobTilt
	end

	-- Lerp Camera
	if (self.lockCamToCenter) then
		self.bodyCam.localRotation = Quaternion.Lerp(self.bodyCam.localRotation, Quaternion.identity, Time.unscaledDeltaTime * 2.15)
	end

	self.bodyCam.localRotation = Quaternion.Lerp(self.bodyCam.localRotation, Quaternion.Euler(self.camEuler), Time.unscaledDeltaTime * 2.15)
end

function LQS_BodyCam:BodyCamLerp()
	-- The main lerp function
	if (not Player.actor) then return end

	-- Get the player's weapon
	local curWeapon = Player.actor.activeWeapon
	local playerT = Player.actor.transform

	-- Calculate look rot
	local input = Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"))

	-- Tilt
	local tiltMouseX = Input.GetAxisRaw("Mouse X")

	-- Clamp and make the look rot
	if (not SpawnUi.isOpen) then
		self.lookEuler = self.lookEuler + Vector3(-input.y, input.x, 0)

		self.weaponZSway = self.lookEuler.z + self:ClampT(-tiltMouseX, -self.weaponRollClamp, self.weaponRollClamp) * 1.25
		self.weaponZSway = Mathf.Lerp(self.weaponZSway, 0, 4.85 * Time.unscaledDeltaTime)
	
		local wepBobTilt = Vector3(self.bobTilt.x, self.bobTilt.y, self:ClampT(self.bobTilt.z, -1.65, 1.65))
		self.lookEuler = Vector3(self:ClampT(self.lookEuler.x, -self.aimingDeadzoneClamp, self.aimingDeadzoneClamp), self:ClampT(self.lookEuler.y, -self.aimingDeadzoneClamp, self.aimingDeadzoneClamp), self.weaponZSway) + wepBobTilt
	end
	
	-- Lerp Weapon
	self.bodyCamWeaponParent.localRotation = Quaternion.Lerp(self.bodyCamWeaponParent.localRotation, Quaternion.Euler(self.lookEuler), 45.85 * Time.unscaledDeltaTime)

	-- Gun Tuck
	if (not self.disableGunTuck) then
		local ray = Ray(self.bodyCam.position, self.bodyCam.forward)
		local tuckRay = Physics.Spherecast(ray, 0.01, 1.15, RaycastTarget.ActorWalkable)
	
		self.tuckAmount = Mathf.Lerp(self.tuckAmount, 0, Time.unscaledDeltaTime * 7.25)
	
		if (tuckRay) then
			self.tuckAmount = Mathf.Lerp(self.tuckAmount, 1 - (tuckRay.point - self.bodyCam.position).magnitude / 1.15, Time.unscaledDeltaTime * 7.25)
		end
	
		self.bodyCamWeaponParent.localRotation = Quaternion.Euler(self.lookEuler + Vector3.Lerp(Vector3.zero, Vector3(-90, 0, 0), self.tuckAmount))
		self.bodyCamWeaponParent.localPosition = Vector3.Lerp(Vector3.zero, Vector3(0, -1, 0), self.tuckAmount)
	end

	-- Aiming FOV
	-- Only if the weapon is using a 3d aim scope object
	self.zoomFPCam = false
	if (curWeapon and curWeapon.scopeAimObject or self.zoomWithAnyGun) then
		local targetAimFOV = self.defCamFOV
		local targetFPAimFOV = self.fpDefCamFOV
	
		if (curWeapon.isAiming) then
			targetAimFOV = curWeapon.aimFov
			targetFPAimFOV = curWeapon.aimFov
		end
	
		self.fpBodyCamera.fieldOfView = Mathf.Lerp(self.fpBodyCamera.fieldOfView, targetFPAimFOV, 15.25 * Time.unscaledDeltaTime)
		self.zoomFPCam = true
	end
end

function LQS_BodyCam:BodyCamBob(curWeapon)
	-- Bobbing for the bodycam
	-- Get vars
	local state1, state2 = self:MovementCheck()
	local player = Player.actor

	-- Sideways Tilt
	local targetTilt = 0

	if (state2 == "WalkingRight") then
		targetTilt = self.walkTiltAmount
	elseif (state2 == "WalkingLeft") then
		targetTilt = -self.walkTiltAmount
	end

	self.bobTilt = Vector3(0, 0, targetTilt)

	-- Walk/Breathing Bob
	-- Idk how to do this...
	if (self.canStep and Player.actorIsGrounded) then
		-- Handles the bob intensity
		local targetIntensity = self.walkBobIntensity
		
		if (player.isSprinting) then
			targetIntensity = self.runBobIntensity
		end
		
		-- Shake
		if (state1 ~= "Idle" or state2 ~= "Idle") then
			-- Walk Bob
			self.script.StartCoroutine(self:CamBobMain(targetIntensity))
		else
			-- Breathing
			local wepIntensity = 0.95
			local camIntensity = 0.035

			if (curWeapon and curWeapon.isAiming) then
				wepIntensity = 0.035
				camIntensity = 0.025
			end

			-- Camera
			local camBreathShake = Vector3(
				self:ClampT(self:CamBobShake(camIntensity, 1.0).x, -1.25, 1.25),
				self:ClampT(self:CamBobShake(camIntensity, 1.0).y, -1.25, 1.25),
				self:ClampT(self:CamBobShake(camIntensity, 1.0).z, -1.25, 1.25)
			)
			self.bodyCam.localRotation = self.bodyCam.localRotation * Quaternion.Euler(camBreathShake)

			-- Weapon
			local wepBreathShake = Vector3(
				self:ClampT(self:CamBobShake(wepIntensity, 0.85).x, -1.25, 1.25),
				self:ClampT(self:CamBobShake(wepIntensity, 0.85).y, -1.25, 1.25),
				self:ClampT(self:CamBobShake(wepIntensity, 0.85).z, -1.25, 1.25)
			)
			self.bodyCamWeaponParent.localRotation = self.bodyCamWeaponParent.localRotation * Quaternion.Euler(wepBreathShake)
		end
	end
end

function LQS_BodyCam:CamBobMain(intensity)
	-- Main camera bob coroutine
	return function()
		-- Vars
		local timer = 0 

		-- Set canStep to false
		self.canStep = false

		-- Start Bob
		while (timer < 0.15) do
			if (not self:CanLerp()) then self.canStep = true return end

			-- Build up timer
			timer = timer + 1 * Time.unscaledDeltaTime

			local bobShake = Vector3(
				self:ClampT(self:CamBobShake(intensity, 5.0).x, -1.25, 1.25),
				self:ClampT(self:CamBobShake(intensity, 5.0).y, -1.25, 1.25),
				self:ClampT(self:CamBobShake(intensity, 5.0).z, -1.25, 1.25)
			)
			self.bodyCam.localRotation = self.bodyCam.localRotation * Quaternion.Euler(bobShake)

			coroutine.yield(WaitForSeconds(0))
		end

		-- Set canStep to true
		self.canStep = true
	end
end

function LQS_BodyCam:CamBobShake(intensity, speed)
	-- Reusing the code block I used in raveceiver.
	local x = Mathf.PerlinNoise(Time.time * speed, 0.0) * 2.0 - 1.0
    local y = Mathf.PerlinNoise(0.0, Time.time * speed) * 2.0 - 1.0
    local z = Mathf.PerlinNoise(Time.time * speed, Time.time * speed) * 2.0 - 1.0

	local shake = Vector3(x, y, z) * intensity

    return shake
end

function LQS_BodyCam:ClampT(value, min, max)
	-- Reusing this from my Raveceiver Base
	if (value and min and max) then
		if (value >= max) then
			value = max
		end

		if (value <= min) then
			value = min
		end

		return value
	end
end
