behaviour("CassetteSpawn")

function CassetteSpawn:Awake()
	-- Single Use
	self.alreadyUsed = false
end

function CassetteSpawn:Start()
	-- Validation
	self.isCassetteSpawn = true
end
