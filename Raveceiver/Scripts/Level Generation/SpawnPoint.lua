behaviour("SpawnPoint")

function SpawnPoint:Awake()
	-- Single Use
	self.alreadyUsed = false
end

function SpawnPoint:Start()
	-- Validation
	self.isSpawnPoint = true

	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Spawn Bools
	self.isPlayerSpawn = self.data.GetBool("isPlayerSpawn")
	self.isDroneSpawn = self.data.GetBool("isDroneSpawn")
	self.isGunDroneSpawn = self.data.GetBool("isGunDroneSpawn")
	self.isSentrySpawn = self.data.GetBool("isSentrySpawn")
	self.isMobileSentrySpawn = self.data.GetBool("isMobileSentrySpawn")
end
