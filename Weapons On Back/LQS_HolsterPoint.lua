-- low_quality_soarin © 2024-2025
behaviour("LQS_HolsterPoint")

function LQS_HolsterPoint:Awake()
	-- Identifier
	self.isHolsterPoint = true

	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	self.holster = self.data.GetGameObject("holster").transform
	self.holsterSlot = self.data.GetString("holsterSlot")
end
