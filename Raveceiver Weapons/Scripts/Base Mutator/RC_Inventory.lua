-- low_quality_soarin © 2023-2024
behaviour("RC_Inventory")

function RC_Inventory:Start()
	-- Base
	self.rcBase = self.targets.rcBase.GetComponent(ScriptedBehaviour).self
	self.data = self.gameObject.GetComponent(DataContainer)

	-- UI
	self.slotIcons = self.data.GetGameObjectArray("slot")
	self.main = self.targets.main

	-- Vars
	self.tickTimer = 0

	-- Finishing Touches
	self.rcBase.rcInventory = self.gameObject.GetComponent(ScriptedBehaviour).self
end

function RC_Inventory:Update()
	-- Check if the weapon has access to slots
	-- Only works for weapons with magazines.
	if (self:CanShowSlots(self.rcBase.rcScript)) then
		-- Set UI to active
		self.main.SetActive(true)

        -- Ticked update
    	-- Doing this for optimisation. 
		self.tickTimer = self.tickTimer + 1 * Time.deltaTime
		if (self.tickTimer >= 0.05) then
			-- Monitor Inventory
			self:MonitorInventory(self.rcBase.rcScript)
	
			self.tickTimer = 0
		end
	else
		-- Hide UI
		self.main.SetActive(false)
		self.tickTimer = 0.05
	end
end

function RC_Inventory:CanShowSlots(rcScript)
	if (rcScript.ammoCarrier and not rcScript.ammoCarrier.isCylinder) then
		if (rcScript.weaponPartsManager.hasMag) then
			if (self.rcBase.rcControlsHelper and not self.rcBase.rcControlsHelper.helpActive) then
				return true
			end 
		end
	end
	return false
end

function RC_Inventory:MonitorInventory(rcScript)
	-- Monitor Inventory System
	-- Checks
	if (not rcScript) then return end

	-- Start Monitoring
	for index,slot in pairs(self.slotIcons) do
		-- Get the icons
		local slotEmpty = slot.transform.GetChild(0).gameObject
		local slotMag = slot.transform.GetChild(1).gameObject

		-- Do check before applying
		if (slotEmpty and slotMag and self:HasAmmoCarrier(rcScript)) then
			-- If it passes is should show a mag, else a empty text.
			if (self:LoopChecks(index, rcScript)) then
				slotEmpty.SetActive(false)
				slotMag.SetActive(true)
			else
				slotEmpty.SetActive(true)
				slotMag.SetActive(false)
			end
		end
	end
end

function RC_Inventory:LoopChecks(index, rcScript)
	if (index ~= rcScript.currentMagIndex or not rcScript.magazineInHand) then
		if (rcScript.ammoCarrier.magData[index]) then
			return true
		end
	end
	return false
end

function RC_Inventory:HasAmmoCarrier(rcScript)
	if (rcScript.ammoCarrier) then
		if (not rcScript.ammoCarrier.isCylinder) then
			return true
		end
	end
	return false
end
