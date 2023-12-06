-- low_quality_soarin © 2023-2024
behaviour("RC_WeaponPartsManager")

function RC_WeaponPartsManager:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Config Bools
	self.isRevolverLike = self.data.GetBool("isRevolverLike")
	self.hasHammer = self.data.GetBool("hasHammer")
	self.hasCylinder = self.data.GetBool("hasCylinder")
	self.hasMag = self.data.GetBool("hasMag")
	self.hasSlide = self.data.GetBool("hasSlide")
	self.hasSlideStop = self.data.GetBool("hasSlideStop")

	-- Config Floats
	self.hammerCockSpeed = self.data.GetFloat("hammerCockSpeed")
	self.hammerReturnSpeed = self.data.GetFloat("hammerReturnSpeed")
end