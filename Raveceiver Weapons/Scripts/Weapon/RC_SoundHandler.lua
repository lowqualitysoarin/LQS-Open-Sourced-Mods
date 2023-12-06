-- low_quality_soarin © 2023-2024
behaviour("RC_SoundHandler")

function RC_SoundHandler:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.audSrc = self.targets.audSrc.GetComponent(AudioSource)
end

function RC_SoundHandler:PlaySound(type, volume)
	-- Plays a specified sound.
	local chosenBank = nil
	local soundVol = 1

	-- Setup volume
	-- If nil then volume is 1 (100)
	if (volume) then
		soundVol = volume
	end

	-- Get the soundbank (It should have a accurate name)
	if (self.data.HasObject(type)) then
		chosenBank = self.data.GetGameObject(type).GetComponent(SoundBank).clips
	end

	-- Play the sound if the sound bank is found
	-- And if the audio source isn't nil
	if (chosenBank and self.audSrc) then
		self.audSrc.volume = soundVol
		self.audSrc.PlayOneShot(chosenBank[math.random(#chosenBank)])
	end
end
