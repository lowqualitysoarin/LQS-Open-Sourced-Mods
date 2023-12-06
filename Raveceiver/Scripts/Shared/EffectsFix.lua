behaviour("EffectsFix")

function EffectsFix:Awake()
	-- This script is for fixing particle effects and sound bugs
	
	-- The bug I'm witnessing is basically when the enemy is unculled it will replay
	-- both particle effects and sound.

	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Specified Effects and Sound
	self.sfx = {}
	self.pfx = {}

	self.chosenObjects = self.data.GetGameObjectArray("effect")

	-- Assign effects to their respective arrays
	for _,go in pairs(self.chosenObjects) do
		-- If the GameObject has a particle system
		if (go.GetComponent(ParticleSystem)) then
			self.pfx[#self.pfx+1] = go.GetComponent(ParticleSystem)
		end

		-- Or if the GameObject has a audio source
		if (go.GetComponent(AudioSource)) then
			self.sfx[#self.sfx+1] = go.GetComponent(AudioSource)
		end
	end

	-- Bools
	self.alreadyTriggered = false
end

function EffectsFix:Start()
	-- Play when the effects are enabled
	if (not self.alreadyTriggered) then
		-- Play
		for _,effect in pairs(self.pfx) do
			effect.Play(true)
		end
	
		for _,sound in pairs(self.sfx) do
			sound.Play()
		end

		-- Tick bool soo it won't play again
		self.alreadyTriggered = true
	end
end
