-- low_quality_soarin © 2023-2024
-- Only parents the object its connected to the fp view of the player.
behaviour("RC_ParentOBJToFP")

function RC_ParentOBJToFP:Start()
	-- Base
	self.rcBase = self.targets.rcBase.GetComponent(ScriptedBehaviour).self
end

function RC_ParentOBJToFP:Update()
	if (self.rcBase.weaponT) then
		self.gameObject.transform.position = self.rcBase.weaponT.position
		self.gameObject.transform.rotation = self.rcBase.weaponT.rotation
	end
end
