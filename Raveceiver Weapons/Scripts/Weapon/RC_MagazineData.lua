-- low_quality_soarin © 2023-2024
behaviour("RC_MagazineData")

function RC_MagazineData:Awake()
	-- Identifiers
	self.isPickable = true
	self.isMag = true

	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Vars
	self.bullets = {}
	self.magID = self.data.GetString("magID")
	self.storedAmmoCount = 0

	-- Get bullets
	local bulletsContainer = self.data.GetGameObject("bulletContainer")
	local cont = bulletsContainer.GetComponentsInChildren(Transform)
	
	for _,obj in pairs(cont) do
		if (obj.gameObject ~= bulletsContainer.gameObject) then
			self.bullets[#self.bullets+1] = obj.gameObject
		end
	end
end

function RC_MagazineData:Start()
	-- Lifetime
	GameObject.Destroy(self.gameObject, 35)
end

function RC_MagazineData:ApplyBulletAmount()
	-- Hide all bullets
	if (#self.bullets > 0) then
		for _,bullet in pairs(self.bullets) do
			bullet.SetActive(false)
		end
	end

	-- Enable bullets depending on amount
	for i = 1, self.storedAmmoCount do
		self.bullets[i].SetActive(true)
	end
end
