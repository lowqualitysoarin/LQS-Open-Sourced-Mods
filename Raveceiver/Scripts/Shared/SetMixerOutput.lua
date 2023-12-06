behaviour("SetMixerOutput")

function SetMixerOutput:Start()
	-- This sets all the audio source's output in the prefab to "Ingame"
	-- Because idk why I can hear all of them despite I'm far away.

	-- Get all AudioSources
	local foundAudioSources = self.gameObject.GetComponentsInChildren(AudioSource)

	-- If there is some AudioSources in the gameobject then,
	-- set the output to "Ingame"
	if (#foundAudioSources > 0) then
		for _,as in pairs(foundAudioSources) do
			as.SetOutputAudioMixer(AudioMixer.Ingame)
		end
	end
end