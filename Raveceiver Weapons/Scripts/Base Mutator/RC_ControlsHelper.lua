-- low_quality_soarin © 2023-2024
behaviour("RC_ControlsHelper")

function RC_ControlsHelper:Awake()
	-- Used bool
	self.hasUsed = false
end

function RC_ControlsHelper:Start()
    -- Base
    self.rcBase = self.targets.rcBase.GetComponent(ScriptedBehaviour).self

    self.helpCopy = self.targets.helpClonable
    self.contentContainer = self.targets.contentContainer.transform

    self.helpClose = self.targets.helpClose
    self.helpOpen = self.targets.helpOpen

    -- Vars
    self.otherHelp = {}

    self.hammerHelp = {}
    self.hammerHalfCockHelp = {}

    self.cylinderReloadHelp = {}
    self.cylinderReloadHelpIndexed = {}
    self.cylinderHelp = {}
    self.cylinderToggleHelp = {}

    self.magHelp = {}
    self.magReloadHelp = {}

    self.slideHelp = {}
    self.slideLockHelp = {}
    self.slideLockSafetyHelp = {}

    self.safetyHelp = {}
    self.decockerHelp = {}

	self.firemodeHelp = {}
	self.firemodeHelp2 = {}

    self.helpActive = false
    self.alreadyGeneratedHelp = false
	self.hasGeneratedHelp = false

    -- Prespawn Help
    self.script.StartCoroutine(self:SpawnKeyStrings(self.rcBase))

    -- Finishing Touches
    self.helpOpen.SetActive(false)
	self.rcBase.rcControlsHelper = self.gameObject.GetComponent(ScriptedBehaviour).self
end

function RC_ControlsHelper:OnDisable()
	if (self.hasUsed) then
		self:ResetHelp()
		self:ToggleHelp(true)

		self.helpActive = false
		self.alreadyGeneratedHelp = false
	end
end

function RC_ControlsHelper:SpawnKeyStrings(rcBase)
    return function()
		coroutine.yield(WaitForSeconds(0.05))
        -- Gets the key strings for the weapon helper
        -- Holstering
        local otherHelp = {
			"Aim weapon: hold rcRMBAimKey", 
			"Toggle aim weapon: push rcAimKey",
            "Draw/Holster flashlight: push rcFlashlight", 
			"Pickup magazine/bullet: push rcPickupKey",
			"Draw/Holster weapon: push rcHolsterKey",
            "Slow draw/holster weapon: hold rcHolsterKey",
			"Open customisation: push rcCustomisationKey"
		}

        -- Prespawn Other Help
        for _, item in pairs(otherHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.otherHelp[#self.otherHelp+1] = curHelp
        end

        -- Hammer
        local hammerHelp = {
			"Pull hammer: hold rcPullHammerKey",
            "Release hammer: hold rcPullHammerKey + rcFireKey then release rcPullHammerKey"
		}
        local hammerHalfCockHelp = {
			"Half cock hammer: tap rcPullHammerKey"
		}

        -- Prespawn Hammer Help
        for _, item in pairs(hammerHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.hammerHelp[#self.hammerHelp+1] = curHelp
        end
        for _, item in pairs(hammerHalfCockHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.hammerHalfCockHelp[#self.hammerHalfCockHelp+1] = curHelp
        end

		-- Double Check Hammer Help
		for _,newItem in pairs(self.hammerHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end
		for _,newItem in pairs(self.hammerHalfCockHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end

		-- Hide Hammer Help
		self:ToggleContents(self.hammerHelp, true)
		self:ToggleContents(self.hammerHalfCockHelp, true)

        -- Cylinder
        local cylinderReloadHelp = {
			"Extract casings: hold rcSafetyKey", 
			"Insert bullet: push rcCarrierInKey"
		}
        local cylinderReloadHelpIndexed = {
			"Push extractor rod: hold rcSafetyKey", 
			"Insert bullet: push rcCarrierInKey"
		}
        local cylinderHelp = {
			"Spin cylinder: push rcCylinderSpinL - Left or rcCylinderSpinR - Right"
		}
        local cylinderToggleHelp = {
			"Open cylinder: push rcCarrierOutKey", 
			"Close cylinder: push rcRackKey"
		}

        -- Prespawn Cylinder Help
        for _, item in pairs(cylinderToggleHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.cylinderToggleHelp[#self.cylinderToggleHelp+1] = curHelp
        end
        for _, item in pairs(cylinderReloadHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.cylinderReloadHelp[#self.cylinderReloadHelp+1] = curHelp
        end
        for _, item in pairs(cylinderReloadHelpIndexed) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.cylinderReloadHelpIndexed[#self.cylinderReloadHelpIndexed+1] = curHelp
        end
        for _, item in pairs(cylinderHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.cylinderHelp[#self.cylinderHelp+1] = curHelp
        end

		-- Double Check Cylinder Help
		for _,newItem in pairs(self.cylinderToggleHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end
		for _,newItem in pairs(self.cylinderReloadHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end
		for _,newItem in pairs(self.cylinderReloadHelpIndexed) do
			newItem.text = self:AssignKey(newItem.text)
		end
		for _,newItem in pairs(self.cylinderHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end

		-- Hide Cylinder Help
		self:ToggleContents(self.cylinderToggleHelp, true)
		self:ToggleContents(self.cylinderReloadHelp, true)
		self:ToggleContents(self.cylinderReloadHelpIndexed, true)
		self:ToggleContents(self.cylinderHelp, true)

        -- Magazine
        local magHelp = {
			"Eject magazine: push rcCarrierOutKey", 
			"Insert magazine: push rcCarrierInKey",
			"Tap the magazine: push rcCarrierInKey",
			"Drop magazine: push rcCarrierOutKey"
		}
        local magReloadHelp = {
			"Insert round into magazine: push rcCarrierInKey",
            "Remove round from magazine: push rcRackKey"
		}

        -- Prespawn Magazine Help
        for _, item in pairs(magHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.magHelp[#self.magHelp+1] = curHelp
        end
        for _, item in pairs(magReloadHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.magReloadHelp[#self.magReloadHelp+1] = curHelp
        end

		-- Hide Mag Help
		self:ToggleContents(self.magHelp, true)
		self:ToggleContents(self.magReloadHelp, true)

        -- Slide
        local slideHelp = {
			"Pull back slide: hold rcRackKey",
            "Inspect chamber: hold rcSlideLockKey + rcRackKey", 
			"Slide tap: push rcSlideLockKey"
		}
        local slideLockHelp = {
			"Lock slide: hold rcRackKey + hold rcSlideLockKey then release rcRackKey",
            "Release slide lock: push rcSlideLockKey"
		}
        local slideLockSafetyHelp = {
			"Lock slide: hold rcRackKey and push rcSafetyKey",
            "Release slide lock: push rcSafetyKey"
		}

        -- Prespawn Slide Help
        for _, item in pairs(slideHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.slideHelp[#self.slideHelp+1] = curHelp
        end
        for _, item in pairs(slideLockHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.slideLockHelp[#self.slideLockHelp+1] = curHelp
        end
        for _, item in pairs(slideLockSafetyHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.slideLockSafetyHelp[#self.slideLockSafetyHelp+1] = curHelp
        end

		-- Double Check Slide Help
		for _,newItem in pairs(self.slideHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end
		for _,newItem in pairs(self.slideLockHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end
		for _,newItem in pairs(self.slideLockSafetyHelp) do
			newItem.text = self:AssignKey(newItem.text)
		end

		-- Hide Slide Help
		self:ToggleContents(self.slideHelp, true)
		self:ToggleContents(self.slideLockHelp, true)
		self:ToggleContents(self.slideLockSafetyHelp, true)

        -- Safety
        local safetyHelp = {
			"Toggle safety: push rcSafetyKey"
		}
        local decockerHelp = {
			"Use decocker: hold rcSafetyKey"
		}

        -- Prespawn Safety Help
        for _, item in pairs(safetyHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.safetyHelp[#self.safetyHelp+1] = curHelp
        end
        for _, item in pairs(decockerHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.decockerHelp[#self.decockerHelp+1] = curHelp
        end

		-- Hide Safety Help
		self:ToggleContents(self.safetyHelp, true)
		self:ToggleContents(self.decockerHelp, true)

		-- Firemode
		local firemodeHelp = {
			"Toggle firemode: push rcSafetyKey"
		}
		local firemodeHelp2 = {
			"Toggle firemode: push rcAltFiremodeKey"
		}

		-- Prespawn Firemode Help
		for _, item in pairs(firemodeHelp) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.firemodeHelp[#self.firemodeHelp+1] = curHelp
        end
        for _, item in pairs(firemodeHelp2) do
            local curHelp = GameObject.Instantiate(self.helpCopy, self.contentContainer).GetComponent(Text)
            curHelp.text = self:AssignKey(item)

			self.firemodeHelp2[#self.firemodeHelp2+1] = curHelp
        end

		-- Hide Firemode Help
		self:ToggleContents(self.firemodeHelp, true)
		self:ToggleContents(self.firemodeHelp2, true)

		-- Final Bool
		self.hasGeneratedHelp = true
    end
end

function RC_ControlsHelper:ToggleContents(contents, hide)
	for _,content in pairs(contents) do
		if (not hide) then
			content.gameObject.SetActive(true)
		else
			content.gameObject.SetActive(false)
		end
	end
end

function RC_ControlsHelper:AssignKey(helpText)
	-- Get the available keys
	local rcBase = self.rcBase
	local keys = {
		{"rcRMBAimKey", KeyBinds.Aim},
		{"rcAimKey", rcBase.toggleAimKey},
		{"rcFlashlight", rcBase.holsterLightKey},
		{"rcHolsterKey", rcBase.holsterKey},
		{"rcPullHammerKey", rcBase.pullHammerKey},
		{"rcSafetyKey", rcBase.safetyFiremodeEjectKey},
		{"rcCarrierInKey", rcBase.carrierInInsertBulletKey},
		{"rcCylinderSpinL", rcBase.cylinderSpinLeftKey},
		{"rcCylinderSpinR", rcBase.cylinderSpinRightKey},
		{"rcRackKey", rcBase.removeBulletRackCloseKey},
		{"rcCarrierOutKey", rcBase.carrierOutKey},
		{"rcSlideLockKey", rcBase.slideLockTapKey},
		{"rcFireKey", KeyBinds.Fire},
		{"rcAltFiremodeKey", rcBase.altFiremodeKey},
		{"rcPickupKey", rcBase.pickupKey},
		{"rcCustomisationKey", rcBase.customisationKey}
	}

	-- Finalize sentence
	local final = helpText

	-- Replace replaceable words
	for _,key in pairs(keys) do
		for word in helpText:gmatch("%w+") do
			if (word == key[1]) then
				-- Do a little tweaking
				local targetKeybind = string.upper(tostring(key[2]))
				
				if (targetKeybind == "FIRE") then
					targetKeybind = "LMB"
				elseif (targetKeybind == "AIM") then
					targetKeybind = "RMB"
				elseif (targetKeybind == "`") then
					targetKeybind = "BackQuote"
				end
				
				-- Final Keybind
				local finalKeybind = "[ <color=orange>" .. targetKeybind .. "</color> ]"
				
				-- Replace replaceable pattern
				final = string.gsub(helpText, key[1], finalKeybind)
			end
		end
	end

	return final
end

function RC_ControlsHelper:Update()
	-- Main
    if (self:IsARaveceiverWeapon()) then
		-- Generate help
        if (not self.alreadyGeneratedHelp) then
			-- If the key strings fail to generate then try to generate it again
			if (not self.hasGeneratedHelp) then
				self.script.StartCoroutine(self:SpawnKeyStrings(self.rcBase))
			end

			-- Generate
            self.script.StartCoroutine(self:GenerateHelp(self.rcBase.rcScript))
            self.alreadyGeneratedHelp = true
        end

		-- Help Toggle
		if (Input.GetKeyDown(KeyCode.H) or Input.GetKeyDown(KeyCode.Slash)) then
			self.helpActive = not self.helpActive

			if (self.helpActive) then
				self:ToggleHelp()
			else
				self:ToggleHelp(true)
			end
		end

		-- Used Bool
		self.hasUsed = true
    end
end

function RC_ControlsHelper:ToggleHelp(hide)
	if (not hide) then
		self.helpOpen.SetActive(true)
		self.helpClose.SetActive(false)
	else
		self.helpOpen.SetActive(false)
		self.helpClose.SetActive(true)
	end
end

function RC_ControlsHelper:ResetHelp()
    -- Resets the help panel.
	self:ToggleContents(self.hammerHelp, true)
	self:ToggleContents(self.hammerHalfCockHelp, true)
	self:ToggleContents(self.cylinderToggleHelp, true)
	self:ToggleContents(self.cylinderReloadHelp, true)
	self:ToggleContents(self.cylinderReloadHelpIndexed, true)
	self:ToggleContents(self.cylinderHelp, true)
	self:ToggleContents(self.magHelp, true)
	self:ToggleContents(self.magReloadHelp, true)
	self:ToggleContents(self.slideHelp, true)
	self:ToggleContents(self.slideLockHelp, true)
	self:ToggleContents(self.slideLockSafetyHelp, true)
	self:ToggleContents(self.safetyHelp, true)
	self:ToggleContents(self.decockerHelp, true)
	self:ToggleContents(self.firemodeHelp, true)
	self:ToggleContents(self.firemodeHelp2, true)
end

function RC_ControlsHelper:GenerateHelp(weapon)
    return function()
		-- Reset Help
		coroutine.yield(WaitForSeconds(0.05))
		-- Generate the available binds for the weapon
		if (weapon.aRaveceiverWeapon) then
			-- Check if the weapon has a slide
			if (weapon.weaponPartsManager.hasSlide) then
				self:ToggleContents(self.slideHelp)
	
				-- Check if the weapon has a slide stop or a slide lock safety
				if (weapon.weaponPartsManager.hasSlideStop) then
					self:ToggleContents(self.slideLockHelp)
				elseif (weapon.slideLockSafety) then
					self:ToggleContents(self.slideLockSafetyHelp)
				end
			end
	
			-- Check if the weapon has a safety
			if (weapon.manualSafety) then
				self:ToggleContents(self.safetyHelp)
			elseif (weapon.decockerSafety) then
				self:ToggleContents(self.decockerHelp)
			end
	
			-- Check if the weapon has a hammer
			if (weapon.weaponPartsManager.hasHammer) then
				self:ToggleContents(self.hammerHelp)
	
				-- Check if the hammer can be half-cocked
				if (weapon.canBeHalfCocked) then
					self:ToggleContents(self.hammerHalfCockHelp)
				end
			end
	
			-- Check if the weapon has a magazine or a cylinder
			if (weapon.weaponPartsManager.hasMag) then
				self:ToggleContents(self.magHelp)
				self:ToggleContents(self.magReloadHelp)
			elseif (weapon.ammoCarrier.isCylinder) then
				self:ToggleContents(self.cylinderToggleHelp)
				
				-- Check if the cylinder's reload is indexed
				if (weapon.ammoCarrier.useReloadIndex) then
					self:ToggleContents(self.cylinderReloadHelpIndexed)
				else
					self:ToggleContents(self.cylinderReloadHelp)
				end

				-- Check if the cylinder is spinnable
				if (weapon.spinnableCylinder) then
					self:ToggleContents(self.cylinderHelp)
				end
			end

			-- Check if the weapon has a firemode system
			if (weapon.firemodeSelector and not weapon.manualSafety and not weapon.decockerSafety) then
				self:ToggleContents(self.firemodeHelp)
			elseif (weapon.firemodeSelector and weapon.manualSafety or weapon.firemodeSelector and weapon.decockerSafety) then
				self:ToggleContents(self.firemodeHelp2)
			end
		end
	end
end

function RC_ControlsHelper:IsARaveceiverWeapon()
    if (self.rcBase and self.rcBase.rcScript) then
        return true
    end
    return false
end
