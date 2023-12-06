behaviour("DroneVitalPart")

function DroneVitalPart:Awake()
	self.isVitalPart = true
	self.isCulled = false
end

function DroneVitalPart:OnDisable()
	if (not self.isCulled) then
		GameObject.Destroy(self.gameObject)
	end
end
