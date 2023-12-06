-- low_quality_soarin © 2023-2024
-- A script that checks whether the targetDropdown is open or not. Good for attachment points that has configurations.
behaviour("RC_OnDropdownToggle")

function RC_OnDropdownToggle:Awake()
	-- Vars
	self.targetDropdown = self.targets.targetDropdown.transform
	self.listeners = {}

	self.lastCount = self.targetDropdown.childCount
	self.maxCount = self.lastCount
end

function RC_OnDropdownToggle:Update()
	-- Monitor if the dropdown is open
	if (self.targetDropdown.childCount ~= self.lastCount) then		
		if (self.targetDropdown.childCount == self.maxCount) then
			self:OnDropdownToggle()
		elseif (self.targetDropdown.childCount > self.maxCount) then
			self.maxCount = self.lastCount
		end
		self.lastCount = self.targetDropdown.childCount
	end
end

-- Inspired by RadioactiveJellyfish's way on how he did listeners on my weapon pickup mod.
function RC_OnDropdownToggle:AddOnDropdownToggleListener(owner, func)
	-- Adds the function to the listener
	self.listeners[owner] = func
end

function RC_OnDropdownToggle:RemoveOnDropdownToggleListener(owner)
	-- Removes the function from the listener
	self.listeners[owner] = nil
end

function RC_OnDropdownToggle:OnDropdownToggle()
	-- Trigger the listeners
	for owner,func in pairs(self.listeners) do
		func()
	end
end
