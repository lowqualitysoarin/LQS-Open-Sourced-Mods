behaviour("CassettePlayer")

function CassettePlayer:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Scripts
	if (self.targets.weaponModifier) then
		self.weaponModifier = self.targets.weaponModifier.GetComponent(ScriptedBehaviour).self
	end

	-- Events
	GameEvents.onActorSpawn.AddListener(self, "OnPlayerSpawn")

	-- Config
	self.threatEchoChance = self.data.GetFloat("threatEchoChance")
	self.threatEchoes = self.data.GetGameObject("threatEchoes").GetComponent(SoundBank)

	-- Vars
	self.stopTapeQueue = false
	self.isPlayingThreatEcho = false
	self.alreadyTriggeredShoot = false
	self.playerDead = true

	-- Essentials
	if (self.targets.cassetteAudioSource) then
		self.audioSource = self.targets.cassetteAudioSource.GetComponent(AudioSource)
	end
	
	self.tapeQueue = {}
end

function CassettePlayer:OnPlayerSpawn(actor)
	if (actor.isPlayer) then
		-- Resets Stuff
		if (self.audioSource) then
			self.audioSource.Stop()
		end
	
		self.alreadyTriggeredShoot = false
		self.stopTapeQueue = false
		self.isPlayingThreatEcho = false
	
		self.tapeQueue = {}
	end
end

function CassettePlayer:Update()
	-- Player for checks
	local player = Player.actor

	-- Main
	if (player) then
		-- Gets the player's status
		self.playerDead = Player.actor.isDead

		-- Pickup Base
		if (Input.GetKeyDown(KeyCode.F) and not self.isPlayingThreatEcho) then
			-- Pickup main
			local cassetteSphere = Physics.OverlapSphere(player.transform.position, 2.5, RaycastTarget.ProjectileHit)

			if (#cassetteSphere > 0) then
				for _,obj in pairs(cassetteSphere) do
					-- Checks if its a cassette player
				    if (self:CassetteCheck(obj)) then
					    self:AddTape(obj)
				    end
				end
			end
		end
	end

	-- Tape Player
	if (#self.tapeQueue > 0) then
		if (not self.audioSource.isPlaying and not self.stopTapeQueue) then
			self:PlayTapeQueue(self.tapeQueue)
		end
	end

	-- Only works if a threat echo is playing
	if (self.isPlayingThreatEcho) then
		if (not self.audioSource.isPlaying) then
			if (not self.alreadyTriggeredShoot) then
				self.script.StartCoroutine(self:ShootSelf())
				self.alreadyTriggeredShoot = true
			end
		end
	end
end

function CassettePlayer:PlayTapeQueue(tapeQueue)
	-- Plays the tape queues
	local currentTape = tapeQueue[1]

	-- Add to the audio source then play
	self.audioSource.clip = currentTape
	self.audioSource.Play()

	-- Remove from the queue
	table.remove(self.tapeQueue, 1)
end

function CassettePlayer:AddTape(tape)
	-- Adds the tape to the queue
	-- Luck system, if the luck is below the threat echo chance then it will be a threat echo.
	local luck = Random.Range(1, 100)

	-- Checks if the luck is below or not
	if (luck < 100) then
		-- Threat Echo
		local chosenInt = math.random(#self.threatEchoes.clips)
		self.tapeQueue[#self.tapeQueue+1] = self.threatEchoes.clips[chosenInt]

		-- Start Compelling Suicide
		self.script.StartCoroutine(self:StartMindControl())
	else
		-- Mind Tape
	end

	-- Destroy the tape
	GameObject.Destroy(tape.transform.root.gameObject)
end

function CassettePlayer:CassetteCheck(object)
	-- This is a bool that checks if the object is a cassette tape
	local output = false

	-- Try to get the scripted behaviour
	if (object.gameObject.GetComponentInParent(ScriptedBehaviour)) then
		-- Gets the scripted behaviour
		local script = object.gameObject.GetComponentInParent(ScriptedBehaviour).self

		-- If it is a cassette tape then get it
		if (script.isCassetteTape and not script.alreadyPickedUp) then
			output = true
		end
	end

	return output
end

function CassettePlayer:TriggerCompellingSuicide(start, shoot, stop)
	-- Will not work if the weaponModifier is nil
	if (not self.playerDead) then
		if (self.weaponModifier) then
			-- Start Phase
			if (start) then
				self.isPlayingThreatEcho = true
				self.stopTapeQueue = true
	
				self.weaponModifier:Suicide(true, false, false)
			end
	
			-- Suicide Phase
			if (shoot) then
				self.weaponModifier:Suicide(false, true, false)
			end
	
			-- Stops the phase
			if (stop) then
				self.weaponModifier:Suicide(false, false, true)
			end
		end
	end
end

function CassettePlayer:ShootSelf()
	return function()
		for i = 1, 5 do
			if (not self.playerDead) then
				self:TriggerCompellingSuicide(false, true, false)

				-- Delay
				coroutine.yield(WaitForSeconds(2.95))
	
				-- Check if its the final iteration
				if (i >= 5) then
					-- Set bools to false
					self.isPlayingThreatEcho = false
					self.alreadyTriggeredShoot = false
					self.stopTapeQueue = false
	
					-- Stop the suicide phase
					self:TriggerCompellingSuicide(false, false, true)
				end
			end
		end
	end
end

function CassettePlayer:StartMindControl()
	return function()
		coroutine.yield(WaitForSeconds(9.25))
		self:TriggerCompellingSuicide(true, false, false)
	end
end
