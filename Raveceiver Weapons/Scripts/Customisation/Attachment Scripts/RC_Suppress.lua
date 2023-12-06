-- low_quality_soarin © 2023-2024
-- A script that suppresses the weapon when this is enabled.
behaviour("RC_Suppress")

function RC_Suppress:Awake()
	-- Awake vars
	self.isUsed = false
	self.hasEnabled = false
end

function RC_Suppress:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	self.thisWeapon = self.targets.thisWeapon.GetComponent(Weapon)
	self.thisAudioSource = self.thisWeapon.gameObject.GetComponent(AudioSource)

	self.muzzle = self.targets.muzzle

	self.supSound = self.data.GetAudioClip("supSound")

	-- Vars
	if (self.thisAudioSource) then
		self.defaultSound = self.thisAudioSource.clip
	end

	-- Finalize
	self:ToggleSuppressor(true)
	self.isUsed = true
end

function RC_Suppress:OnEnable()
	-- Suppress the gun
	if (self.isUsed) then
		self:ToggleSuppressor(true)
	end
end

function RC_Suppress:OnDisable()
	-- Unsuppress the gun
	if (self.isUsed and self.hasEnabled) then
		self:ToggleSuppressor()
	end
end

function RC_Suppress:ToggleSuppressor(active)
	-- Toggles the suppressor
	-- Convert nil to false bool
	if (active == nil) then
		active = false
	end

	-- Main
	self.hasEnabled = active

	self.thisWeapon.isLoud = active
	self.muzzle.SetActive(not active)

	if (active) then
		self.thisAudioSource.clip = self.supSound
	else
		if (self.defaultSound) then
			self.thisAudioSource.clip = self.defaultSound
		end
	end
end
