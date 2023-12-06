behaviour("TurretVitalPart")

function TurretVitalPart:Awake()
	self.isVitalPart = false
	self.isCulled = false
end

function TurretVitalPart:OnDisable()
	if (not self.isCulled) then
		GameObject.Destroy(self.gameObject)
	end
end