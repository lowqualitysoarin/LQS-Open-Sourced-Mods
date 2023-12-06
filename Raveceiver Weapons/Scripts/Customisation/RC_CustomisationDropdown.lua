-- low_quality_soarin © 2023-2024
-- A dropdown for the customisation system, similar approach on what I did on the PravusFramework dropdown.
-- But more open and less limited.
behaviour("RC_CustomisationDropdown")

local savedIDs = {}
local appliedDefaultIndexArray = {"dummy2312312"}

function RC_CustomisationDropdown:Awake()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Extra config
	-- Most these are optional
	if (self.data.HasInt("defaultDropdownIndex")) then
		self.defaultDropdownIndex = self.data.GetInt("defaultDropdownIndex")
	end

	-- Vars
	self.dropdown = self.targets.dropdown.GetComponent(Dropdown)
	self.targetOrigin = self.targets.targetOrigin.transform

	self.foundItems = {}
	self.dropdownName = nil
	self.attachmentPointName = nil
	self.rcBaseSaveLoad = nil
	self.currentIndex = 1
	self.dropdownID = nil

	-- Finalize
	self:SetupDropdown()
end

function RC_CustomisationDropdown:SetupDropdown()
	-- Setup the dropdown
	if (not self.dropdown) then return end

	-- Get the dropdown name
	self.dropdownName = self.data.GetString("dropdownName")

	-- Get the attachment point name (optional)
	-- Different from the dropdownName because that is just treated like a ID
	if (self.data.HasString("attachmentPointName")) then
		self.attachmentPointName = self.data.GetString("attachmentPointName")
	end

	-- Get the items from the data container
	self.foundItems = self.data.GetGameObjectArray("item")
	local itemNames = self.data.GetStringArray("itemName")

	-- Add a listener to the dropdown
	self.dropdown.onValueChanged.AddListener(self, "ChangeAttachment")

	-- Add options to the dropdown
	self.dropdown.AddOptions(itemNames)

	-- Get the rcBase to access the LoadSaveCustomisation function
	-- If the player has the Raveceiver Base mutator on.
	if (_G.rcBaseSaveLoad) then
		self.rcBaseSaveLoad = _G.rcBaseSaveLoad
	end

	-- Try to reassign the ID
	self:DropdownIDManager(nil, true)

	-- Apply dropdown index
	if (self.defaultDropdownIndex and not self:AlreadyAppliedDefaultIndex()) then
		self.dropdown.value = self.defaultDropdownIndex
	end
end

function RC_CustomisationDropdown:AlreadyAppliedDefaultIndex()
	-- Checks if this attachment point has it's default index applied
	-- from the start of the game.
	for _,id in pairs(appliedDefaultIndexArray) do
		if (id and self.dropdownName == id) then
			return true
		end
	end
	appliedDefaultIndexArray[#appliedDefaultIndexArray+1] = self.dropdownName
	return false
end

function RC_CustomisationDropdown:DropdownIDManager(assignedID, reassign)
	-- This is only for the Raveceiver Base mutator, to fix some issues on the mutator
	-- that it overwriting every dropdown index when saving
	if (not reassign) then
		-- Set ID
		self.dropdownID = assignedID

	    -- Set savedID because everytime the player dies the dropdownID gets resetted
		-- It will get reassigned when setted up again.
	    savedIDs[#savedIDs+1] = {self.dropdownName, self.dropdownID}
	else
		-- Reassign ID
		-- If this is called it will try to reassign the ID, when the player dies or re-equips the weapon
		for _,save in pairs(savedIDs) do
			-- Do some checks
			if (save and save[1] and save[2]) then
				-- If the saveID matches the dropdownName then assign the ID
				if (save[1] == self.dropdownName) then
					self.dropdownID = save[2]
					break
				end
			end 
		end
	end
end

function RC_CustomisationDropdown:ChangeAttachment(value)
	-- Load Attachment
	self:LoadAttachment(value + 1)
end

function RC_CustomisationDropdown:LoadAttachment(index, dontCallSaveLoad, setIndexValue)
	-- Loads the attachment
	-- Enable the item, and disable the rest
	for index,item in pairs(self.foundItems) do
		if (item) then
			item.SetActive(false)
		end
	end

	if (self.foundItems[index]) then
		self.foundItems[index].SetActive(true)
	end

	-- Give the current index
	self.currentIndex = index
	
	if (setIndexValue) then
		self.dropdown.SetValueWithoutNotify(index - 1)
	end

	-- Call the Raveceiver Base's LoadSaveCustomisation function
	-- If the player has the base mutator on
	if (self.rcBaseSaveLoad and not dontCallSaveLoad) then
		self.rcBaseSaveLoad.script.StartCoroutine(self.rcBaseSaveLoad:LoadSaveCustomisation(true, false, self.dropdownID))
	end
end
