-- low_quality_soarin © 2023-2024
behaviour("LQS_ArcadeMovementsBase")

function LQS_ArcadeMovementsBase:Awake()
	-- Instance
	_G.LQSArcadeMovementsInstance = self.gameObject.GetComponent(ScriptedBehaviour).self
end

function LQS_ArcadeMovementsBase:Start()
	-- Systems
	self.vaultingSystem = self.targets.vaultingSystem.GetComponent(ScriptedBehaviour).self
	self.dashingSystem = self.targets.dashingSystem.GetComponent(ScriptedBehaviour).self
	self.slidingSystem = self.targets.slidingSystem.GetComponent(ScriptedBehaviour).self

	-- Events/Listeners
	GameEvents.onActorSpawn.AddListener(self, "ActorSpawn")

	-- Apply Configs
	-- As always, I have to do this on a coroutine soo I can give it a little delay before
	-- applying some stuff.
	self.script.StartCoroutine(self:ApplyConfigs())
end

function LQS_ArcadeMovementsBase:ActorSpawn(actor)
	if (actor.isPlayer) then
		-- Apply some stuff if its a player
		local speedMultiplier = self.script.mutator.GetConfigurationFloat("speedMultiplier")
		if (not self.movementCore) then
			actor.speedMultiplier = speedMultiplier
		else
			self.movementCore:AddModifier(actor, "LQSSpeedMultiplier", speedMultiplier)
		end
	end
end

function LQS_ArcadeMovementsBase:ApplyConfigs()
	return function()
		coroutine.yield(WaitForSeconds(0.05))

		-- Apply Settings
		-- Dashing
		self.dashingSystem.dashKey = self:CheckKeyCode(string.lower(self.script.mutator.GetConfigurationString("dashKey")))

		self.dashingSystem.dashInt = self.script.mutator.GetConfigurationInt("dashInt")
		self.dashingSystem.currentDashInt = self.dashingSystem.dashInt

		self.dashingSystem.dashSpeed = self.script.mutator.GetConfigurationFloat("dashSpeed")
		self.dashingSystem.dashRegenTime = self.script.mutator.GetConfigurationFloat("dashRegenTime")
		self.dashingSystem.dashCooldown = self.script.mutator.GetConfigurationFloat("dashCooldown")

		-- Sliding
		self.slidingSystem.slideStartSpeed = self.script.mutator.GetConfigurationFloat("slideStartSpeed")
		self.slidingSystem.sprintTime = self.script.mutator.GetConfigurationFloat("sprintTime")

		self.slidingSystem.declerationAmountLand = self.script.mutator.GetConfigurationFloat("declerationAmountLand")
		self.slidingSystem.declerationAmountAir = self.script.mutator.GetConfigurationFloat("declerationAmountAir")

	    -- Enable/disable systems
		-- Vaulting
		if (self.script.mutator.GetConfigurationBool("vaulting")) then
			self.vaultingSystem.gameObject.SetActive(true)
		else
			self.vaultingSystem.gameObject.SetActive(false)
		end

		-- Dashing
		if (self.script.mutator.GetConfigurationBool("dashing")) then
			self.dashingSystem.gameObject.SetActive(true)
		else
			self.dashingSystem.gameObject.SetActive(false)
		end

		-- Sliding
		if (self.script.mutator.GetConfigurationBool("sliding")) then
			self.slidingSystem.gameObject.SetActive(true)
		else
			self.slidingSystem.gameObject.SetActive(false)
		end

		-- Compatibility
		-- Movement Core
		local movementCoreObj = self.gameObject.Find("MovementCore(Clone)")
		if movementCoreObj then
		   self.movementCore = movementCoreObj.GetComponent(ScriptedBehaviour).self
		end
	end
end

function LQS_ArcadeMovementsBase:CheckKeyCode(givenBind)
	-- From my bodycam mod
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
		if (givenBind == bind[1]) then
			return bind[2]
		end
	end
	return givenBind
end
