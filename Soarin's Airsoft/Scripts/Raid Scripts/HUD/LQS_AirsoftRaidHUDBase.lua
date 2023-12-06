behaviour("LQS_AirsoftRaidHUDBase")

function LQS_AirsoftRaidHUDBase:Start()
	-- HUD
	-- Timer
	self.timerText = self.targets.timerText.GetComponent(Text)

	-- Objective Marker
	self.supplyPointMarker = self.targets.supplyPointMarker
	self.satellitePointMarker = self.targets.satellitePointMarker

	-- Marker Array
	-- Format: {MarkerID, MarkerPos, MarkerImage, MarkerText}
	self.markerArray = {}

	-- Vars
	self.waypointContainer = self.targets.waypointContainer.transform

	self.airsoftRaidBase = nil

	self.isObjectiveWaypointsOpen = false
	self.stopUpdateCoroutine = false

	-- Share singleton
	_G.LQSSoarinsAirsoftRaidHUDBase = self.gameObject.GetComponent(ScriptedBehaviour)

	-- Finalize
	-- Disable some elements
	self.timerText.CrossFadeAlpha(0, 0, true)
	self.waypointContainer.gameObject.SetActive(false)

	-- Finalize Setup
	self.script.StartCoroutine(self:FinalizeSetup())
end

function LQS_AirsoftRaidHUDBase:FinalizeSetup()
	return function()
		coroutine.yield(WaitForSeconds(0.01))

		-- Get the airsoft raid base script
		local airsoftRaidBase = _G.LQSSoarinsAirsoftRaidBase
		if (airsoftRaidBase) then
			self.airsoftRaidBase = airsoftRaidBase.self
		end

		-- Start update coroutine
		self.script.StartCoroutine(self:CoroutineUpdate())
	end
end

function LQS_AirsoftRaidHUDBase:CoroutineUpdate()
	return function()
		-- Doing it in a coroutine to be more optimized
		while (not self.stopUpdateCoroutine) do
			-- Objectives marker toggle
			if (Input.GetKeyDown(KeyCode.RightBracket)) then
				self.isObjectiveWaypointsOpen = not self.isObjectiveWaypointsOpen
				self.waypointContainer.gameObject.SetActive(self.isObjectiveWaypointsOpen)
			end

			-- Objectives marker handler
			if (self.isObjectiveWaypointsOpen) then
				self:WaypointHandler()
			end

			-- Update
			coroutine.yield(WaitForSeconds(0))
		end
	end
end

function LQS_AirsoftRaidHUDBase:WaypointHandler()
	-- Updates the positions of the waypoints in the markerArray
	for _,markerData in pairs(self.markerArray) do
		-- The way this works is really similar to the respawn marker in the hud base, so no need for crazy explanation
		if (markerData) then
			-- Handle waypoint marker img
		    local minX = markerData[3].GetPixelAdjustedRect().width / 2
		    local maxX = Screen.width - minX
    
		    local minY = markerData[3].GetPixelAdjustedRect().height / 2
		    local maxY = Screen.height - minY
    
		    local markerPos = PlayerCamera.activeCamera.WorldToScreenPoint(markerData[2])
    
		    local playerFpCam = PlayerCamera.fpCamera.transform
		    if (Vector3.Dot((markerData[2] - playerFpCam.position), playerFpCam.forward) < 0) then
		    	if (markerPos.x < Screen.width / 2) then
		    		markerPos.x = maxX
		    	else
		    		markerPos.x = minX
		    	end
		    end
    
		    markerPos.x = Mathf.Clamp(markerPos.x, minX, maxX)
		    markerPos.y = Mathf.Clamp(markerPos.y, minY, maxY)
    
		    markerData[3].transform.position = markerPos
    
		    -- Handle waypoint marker distance
		    local distanceText = tostring(math.floor(Vector3.Distance(markerData[2], playerFpCam.position))) .. "m"
		    markerData[4].text = distanceText
		end
	end
end

function LQS_AirsoftRaidHUDBase:StopUpdateCoroutine()
	-- Stops the update coroutine
	self.stopUpdateCoroutine = true
	self.isObjectiveWaypointsOpen = false
end

function LQS_AirsoftRaidHUDBase:ToggleTimer(active)
	-- Toggles the timer
	local targetAlpha = 0
	if (active) then
		targetAlpha = 1
	end
	self.timerText.CrossFadeAlpha(targetAlpha, 1.5, false)
end

function LQS_AirsoftRaidHUDBase:UpdateTimer(currentTime)
	-- Displays the current time
	currentTime = currentTime + 1

	local minutes = Mathf.FloorToInt(currentTime / 60)
	local seconds = Mathf.FloorToInt(currentTime % 60)

	self.timerText.text = "{ " .. string.format("%02d:%02d", minutes, seconds) .. " }"
end

function LQS_AirsoftRaidHUDBase:WaypointManager(remove, id, pos, type)
	-- A manager for the objectives way point system
	if (not remove) then
		-- Add
		-- Get the type of the marker
		local markerType = nil
		if (type == "SatelliteMarker") then
			markerType = self.satellitePointMarker
		elseif (type == "SupplyPointMarker") then
			markerType = self.supplyPointMarker
		end

		-- Instantiate marker to the container
		if (not markerType) then return end
		local newMarker = GameObject.Instantiate(markerType, self.waypointContainer)

		-- Setup data handler
		local markerData = {
			id, 
			pos, 
			newMarker.GetComponent(Image), 
			newMarker.transform.GetChild(0).gameObject.GetComponent(Text)
		}

		-- Add to markerArray
		self.markerArray[#self.markerArray+1] = markerData
	else
		-- Remove
		for index,markerData in pairs(self.markerArray) do
			if (markerData[1] == id) then
				-- Destroy image object
				GameObject.Destroy(markerData[3].gameObject)

				-- Remove from array
				self.markerArray[index] = nil
			end
		end
	end
end
