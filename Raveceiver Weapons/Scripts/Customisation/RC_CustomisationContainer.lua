-- low_quality_soarin © 2023-2024
-- This holds the customisation dropdowns, for the rcBase.
behaviour("RC_CustomisationContainer")

function RC_CustomisationContainer:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Vars
	-- Get the dropdowns
	self.dropdowns = {}
	self.active = false

	for _,item in pairs(self.data.GetGameObjectArray("dropdown")) do
		self.dropdowns[#self.dropdowns+1] = item.GetComponent(ScriptedBehaviour).self
	end

	-- Finalize
	self:ToggleDropdowns()
end

function RC_CustomisationContainer:ToggleDropdowns(active)
	-- Convert nil into false bool
	if (active == nil) then
		active = false
	end

	-- Toggles the dropdowns
	for _,item in pairs(self.dropdowns) do
		if (item) then
			item.gameObject.SetActive(active)
		end
	end

	-- Set state
	self.active = active
end

function RC_CustomisationContainer:TransferItems(returnItems, targetCanvas)
	for _,item in pairs(self.dropdowns) do
		if (item) then
			if (returnItems) then
				item.transform.parent = self.transform
			else
				if (targetCanvas) then
					item.transform.rotation = Quaternion.identity
					item.transform.position = Vector3.zero

					item.transform.parent = targetCanvas.transform
				end
			end
		end
	end
end
