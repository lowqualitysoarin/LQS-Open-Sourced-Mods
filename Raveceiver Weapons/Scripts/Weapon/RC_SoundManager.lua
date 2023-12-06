-- low_quality_soarin © 2023-2024
-- Works the same as the pose manager. But for sounds
behaviour("RC_SoundManager")

function RC_SoundManager:Awake()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.container = self.targets.container

	local type = self.data.GetString("type")

	-- Get Sounds
	if (self.container) then
		if (type == "slideBack") then
			self.slideBackSounds = self.container.GetComponent(SoundBank)
		elseif (type == "magIn") then
			self.magInSounds = self.container.GetComponent(SoundBank)
		elseif (type == "magOut") then
			self.magOutSounds = self.container.GetComponent(SoundBank)
		elseif (type == "safety") then
			self.safetySounds = self.container.GetComponent(SoundBank)
		elseif (type == "bullets") then
			self.bulletSounds = self.container.GetComponent(SoundBank)
		elseif (type == "firemode") then
			self.firemodeSounds = self.container.GetComponent(SoundBank)
		end
	end
end
