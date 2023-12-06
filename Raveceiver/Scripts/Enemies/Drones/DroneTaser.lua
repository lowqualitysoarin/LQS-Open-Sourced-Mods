behaviour("DroneTaser")

function DroneTaser:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.droneScript = self.targets.droneScript.GetComponent(ScriptedBehaviour).self

	-- Important parts
	self.tasePoint = self.targets.tasePoint.transform
	self.taser = self.targets.taser

	-- Vital bools
	self.taserActive = true

	-- Configuration
	self.attackRange = self.data.GetFloat("attackRange")

	self.damageRadius = self.data.GetFloat("damageRadius")
	self.damage = self.data.GetFloat("damage")
	self.balanceDamage = self.data.GetFloat("balanceDamage")

	-- Taser Essentials
	self.taseSound = self.targets.taseSound.GetComponent(AudioSource)

	self.isAttacking = false
	self.canAttack = true

	-- Finalize
	-- Put taser volume to 0
	self.taseSound.volume = 0
end

function DroneTaser:Update()
	-- Vital Check
	self:CheckVitals()

	-- Base
	if (self.droneScript ~= nil) then
		-- Checks if the drone's state is attack
		if (self.droneScript.currentState == self.droneScript.droneStates[2] and self.droneScript:IsFunctional()) then
			if (self.taserActive and self.canAttack) then
				self:Tase()
			else
				self:StopFeatures()
			end
		else
			self:StopFeatures()
		end
	end

	-- Taser particles
	self:Particles()
end

function DroneTaser:StopFeatures()
	-- Fade out sound
	self.taseSound.volume = Mathf.Lerp(self.taseSound.volume, 0, Time.deltaTime * 8.5)

	-- Tick attacking to false
	self.isAttacking = false
end

function DroneTaser:Particles()
	-- Play particles (If it has some)
	local particleSystem = self.tasePoint.gameObject.GetComponentInChildren(ParticleSystem)

	if (particleSystem ~= nil) then
		if (self.isAttacking) then
			particleSystem.Play(true)
		else
			particleSystem.Stop(true)
		end
	end
end

function DroneTaser:Tase()
	-- Start Tasing
	-- Get the distance between the player
	local distToPlayer = (Player.actor.transform.position - self.tasePoint.position).magnitude

	-- If the player is in the attack range then turn on the taser
	if (distToPlayer < self.attackRange) then
		-- Get the alive actors in radius
		local taseSphere = ActorManager.AliveActorsInRange(self.tasePoint.position, self.damageRadius)

		-- Fade in taser sound
	    self.taseSound.volume = Mathf.Lerp(self.taseSound.volume, 1, Time.deltaTime * 8.5)

		-- Tick attacking to true
		self.isAttacking = true

		-- If there are actors found then do a loop
		if (#taseSphere > 0) then
			-- If the actor is player then tase it
			for _,actor in pairs(taseSphere) do
				-- Tasing
				if (actor.isPlayer and not actor.isDead) then
					actor.Damage(nil, self.damage, self.balanceDamage, false, false)
				end
			end
		end
	end
end

function DroneTaser:CheckVitals()
	-- Same thing on what I did for the sentries weapons

	-- Taser
	if (self.taser ~= nil) then
		self.taserActive = true
	else
		self.taserActive = false
	end
end
