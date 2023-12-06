-- low_quality_soarin © 2023-2024
-- A script that gives a advanced railing-like placement for attachments
behaviour("RC_Railing")

local currentIndex = 2
local saveDatas = {{"dummy8887271", 0}}

function RC_Railing:Awake()
    -- Awake Vars
    -- Base
    self.data = self.gameObject.GetComponent(DataContainer)
    self.slider = self.targets.slider.GetComponent(Slider)

    -- Vars
    self.sliderOBJ = self.slider.gameObject
    self.attachmentT = self.targets.attachmentT.transform

    self.pointA = self.targets.pointA.transform
    self.pointB = self.targets.pointB.transform

    self.railingName = self.data.GetString("railingName")
    self.railingID = nil

    self.defaultMoveValue = self.data.GetFloat("defaultMoveValue")
    self.moveValue = self.defaultMoveValue

    -- Toggle Func
    self.toggleSliderFunc = function()
        if (self.sliderOBJ.activeSelf) then
            self.sliderOBJ.SetActive(false)
        else
            self.sliderOBJ.SetActive(true)
        end
    end
end

function RC_Railing:OnEnable()
	-- Finalize
	self.script.StartCoroutine(self:SetupAttachment())
end

function RC_Railing:SetupAttachment()
    -- Sets up some essential stuff for the attachment
    return function()
		coroutine.yield(WaitForSeconds(0.05))

		-- Get the onDropdownToggle script
		self.onDropdownToggle = self.targets.onDropdownToggle.GetComponent(ScriptedBehaviour).self
		self.slider.onValueChanged.AddListener(self, "OnValueChanged")

		coroutine.yield(WaitForSeconds(0.05))
        -- Check the savedata for existing ones, if so then stop this whole function
        -- and load the existing one to prevent duplicates. Also tick isReady.
        for index, data in pairs(saveDatas) do
            if (data[1] and data[1] == self.railingName) then
                self:LoadSaveSystem(index, true)
				self.isReady = true
                return
            end
        end

        -- If this attachment is new then setup the main stuff
		-- Give the current index.
		self.railingID = currentIndex

        -- Make a new save then add it to the saveDatas table
        local premadeData = {self.railingName, self.moveValue}
        saveDatas[#saveDatas + 1] = premadeData

        -- Add a listener to the slider, and apply the value to the slider then disable it
        self.slider.onValueChanged.AddListener(self, "OnValueChanged")
        self.slider.SetValueWithoutNotify(self.moveValue)

        -- Add OnDropdownToggle listener
        self.onDropdownToggle:AddOnDropdownToggleListener(self.railingName, self.toggleSliderFunc)
        self.sliderOBJ.SetActive(false)

        -- Add one to the current Index for the next attachment
        currentIndex = currentIndex + 1

		-- Set isReady to true
		self.isReady = true
    end
end

function RC_Railing:LoadSaveSystem(targetIndex, loadData)
    -- Load or saves something in the saveDatas table
    if (loadData) then
        -- Load
        -- No work if there is no targetIndex assigned.
        if (not targetIndex) then
            return
        end

        -- Load Data
        -- That's all lmao.
        self.slider.SetValueWithoutNotify(saveDatas[targetIndex][2])
    else
        -- Save
        -- If the railingID isn't properly assigned then it won't work.
        if (not self.railingID or self.railingID == 0) then
            return
        end

        -- Save Data
        saveDatas[self.railingID][2] = self.moveValue
    end
end

function RC_Railing:OnValueChanged()
    -- If the slider's value has changed then save it
    self:LoadSaveSystem()
end

function RC_Railing:Update()
    if (self.isReady) then
		-- Lerp the attachmentT between two points controlled by the slider's moveValue
		self.moveValue = self.slider.value
		self.attachmentT.position = Vector3.Lerp(self.pointA.position, self.pointB.position, self.moveValue / 1)
	end
end
