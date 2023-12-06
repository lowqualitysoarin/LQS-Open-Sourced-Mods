-- low_quality_soarin © 2023-2024
behaviour("RC_Pickup")

function RC_Pickup:Awake()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.isPickable = self.data.GetBool("isPickable")
end

function RC_Pickup:Start()
	GameObject.Destroy(self.gameObject, 35)
end
