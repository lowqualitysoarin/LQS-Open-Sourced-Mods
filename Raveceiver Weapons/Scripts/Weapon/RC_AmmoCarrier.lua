-- low_quality_soarin © 2023-2024
behaviour("RC_AmmoCarrier")

function RC_AmmoCarrier:Awake()
	-- Awake Vars
	-- Mag OBJ
	self.magObj = nil
	self.magObjOrig = self.transform.GetChild(0).gameObject
end

function RC_AmmoCarrier:Start()
	-- Base
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Get the weapon script
	-- Spare Ammo system will not work if there is none
	if (self.targets.thisWeapon.GetComponent(Weapon)) then
		self.weaponScript = self.targets.thisWeapon.GetComponent(Weapon)
	end

	-- Configuration

	-- Bullets
	-- Gets the bullet objects, this is needed for the ammo count.
	self.bullets = {}

	if (self.data.HasObject("bulletContainer")) then
		-- Bullet Container Technique
		-- The easiest way, if the weapon holds alot of bullets in the mag
		local parentCont = self.data.GetGameObject("bulletContainer")
		local getChildObjs = parentCont.GetComponentsInChildren(Transform)

		for _,obj in pairs(getChildObjs) do
			if (obj.gameObject ~= parentCont) then
				self.bullets[#self.bullets+1] = obj.gameObject
			end
		end
	else
		-- Specific Type
		-- Something useful for revolvers or anything, but tedious to setup
		self.bullets = self.data.GetGameObjectArray("bullet")
	end

	-- Optional Bools
	if (self.data.HasBool("isCylinder")) then
		self.isCylinder = self.data.GetBool("isCylinder")
	end
	if (self.data.HasBool("useReloadIndex")) then
		self.useReloadIndex = self.data.GetBool("useReloadIndex")
	end
	if (self.data.HasBool("loadingGateRight")) then
		self.loadingGateRight = self.data.GetBool("loadingGateRight")
	end
	if (self.data.HasBool("clockwise")) then
		self.clockwise = self.data.GetBool("clockwise")
	end
	if (self.data.HasBool("restrictSpin")) then
		self.restrictSpin = self.data.GetBool("restrictSpin")
	end

	if (self.data.HasFloat("rotationDegree")) then
		self.rotationDegree = self.data.GetFloat("rotationDegree")
	end
	if (self.data.HasFloat("reloadStartRot")) then
		self.reloadStartRot = self.data.GetFloat("reloadStartRot")
	end
	if (self.data.HasFloat("reloadRotDegree")) then
		self.reloadRotDegree = self.data.GetFloat("reloadRotDegree")
	end

	-- Vars
	self.magData = {}

	self.finalAngle = self.transform.localEulerAngles.y
	self.isOnReloadMode = false
	self.canLoadRound = true

	self.revolverBulletData = {}
	self.alreadyGotBulletData = false

	self.currentBulletIndex = 1

	self.currentBullet = nil
	self.currentReloadBullet = nil

	-- Setup Ammo
	self.maxAmmo = #self.bullets
	self.ammo = self.maxAmmo

	-- Only works if the weapon has a cylinder
	if (self.isCylinder) then
		-- Setup Bullet Data
		self:SetupBulletData()
	end

	-- Setup Spare Ammo
	-- If weaponScript isn't nil.
	if (self.weaponScript) then
		self.maxSpareAmmo = self.weaponScript.maxSpareAmmo
		self.spareAmmo = self.maxSpareAmmo
	end

	-- Ammo Monitor
	self.lastAmmo = 0
end

function RC_AmmoCarrier:Update()
	-- Spare Ammo System
	self:SpareAmmoSystem()

	-- Only works if the weapon has a cylinder.
	if (self.isCylinder) then
		-- Cylinder Rotation
		self:RotateCylinder()

		if (self.alreadyGotBulletData) then
			-- Chamber Check
			self:RoundManager()
		end
	end
end

function RC_AmmoCarrier:SetupBulletData()
	if (#self.bullets > 0) then
		-- Normal Rotation Degree
		local lastAngle = self.transform.localEulerAngles.y

		-- Reload Rotation Degree
		-- For guns like the Colt Single Action army.
		local lastReloadAngle = nil

		if (self.useReloadIndex) then
			if (self.reloadStartRot) then
			    lastReloadAngle = self.reloadStartRot
			end
		end

		-- Setup
		for _,bullet in pairs(self.bullets) do
			self.revolverBulletData[#self.revolverBulletData+1] = {
				bullet,
				true,
				false,
				lastAngle,
				lastReloadAngle
			}

			if (self.clockwise) then
				lastAngle = lastAngle + self.rotationDegree

				if (lastReloadAngle and self.reloadRotDegree) then
					lastReloadAngle = lastReloadAngle + self.reloadRotDegree
				end
			else
				lastAngle = lastAngle - self.rotationDegree

				if (lastReloadAngle and self.reloadRotDegree) then
					lastReloadAngle = lastReloadAngle - self.reloadRotDegree
				end
			end
		end

		self.alreadyGotBulletData = true
	end
end

function RC_AmmoCarrier:RoundManager()
	-- Gets the active round
	if (#self.revolverBulletData > 0) then
		self.currentBullet = self.revolverBulletData[self.currentBulletIndex]
	end

	-- Get the active reload round
	-- Something near the loading gate or something idk.
	if (self.useReloadIndex) then
		local targetIndex = nil
		local chosenIndex = nil

		-- Get the bulletIndex
		-- If loadingGate is on the right then it will add else subtract.
		if (self.loadingGateRight) then
			targetIndex = self.currentBulletIndex - 1
		else
			targetIndex = self.currentBulletIndex + 1
		end

		-- Check if the targetIndex overflows
		-- To prevent nil errors.
		if (targetIndex <= 0) then
			targetIndex = self.maxAmmo
		elseif (targetIndex > self.maxAmmo) then
			targetIndex = 1
		end

		-- Finalize
		chosenIndex = targetIndex
		self.currentReloadBullet = self.revolverBulletData[chosenIndex]
	end

	-- Manages the rounds
	for _,round in pairs(self.revolverBulletData) do
		local bullet = round[1]
		local isLive = round[2]
		local isGone = round[3]

		local bulletData = bullet.gameObject.GetComponent(DataContainer)

		if (bulletData) then
			if (bulletData.HasObject("casing") and bulletData.HasObject("live")) then
				if (not isLive) then
					bulletData.GetGameObject("casing").SetActive(true)
					bulletData.GetGameObject("live").SetActive(false)
				else
					bulletData.GetGameObject("casing").SetActive(false)
					bulletData.GetGameObject("live").SetActive(true)
				end
			end
		end

		if (isGone) then
			bullet.gameObject.SetActive(false)
		else
			bullet.gameObject.SetActive(true)
		end
	end
end

function RC_AmmoCarrier:SpareAmmoSystem()
	-- Checks
	-- Return if some of these are nil.
	if (not self.maxSpareAmmo and not self.spareAmmo and not self.weaponScript) then return end

	-- Setup spare ammo on the main weapon spare ammo
	-- Doing this because Steel haven't exposed overridable binds.
	self.weaponScript.spareAmmo = self.spareAmmo

	-- Force ammo to zero
	-- Because it will shoot even there is no ammo in it if it do have rf ammo in it.
	-- Because this base uses this as it's ammo counter.
	self.weaponScript.maxAmmo = 0
	self.weaponScript.ammo = 0
end

function RC_AmmoCarrier:RandomizeAmmo(isMagazine)
	if (not isMagazine) then
		local amountToDecrease = math.random(self.maxAmmo)

		for i = 1, amountToDecrease do
			if (not self.isCylinder) then
				self:DecreaseAmmo()
			else
				self:DecreaseAmmoCylinder(true, false)
			end
		end
	else
		-- Randomize the number of mags
		local numberOfMags = math.random(1, 4)

		-- Call Setup Mags
		self:SetupMags(numberOfMags, true)
	end
end

function RC_AmmoCarrier:SetupMags(numberOfMags, randomized)
	-- Sets up the mag slots
	-- Make mag presets.
	for i = 1, numberOfMags do
		local ammoCount = self.maxAmmo

		-- Randomize amount if allowed
		if (randomized) then
			ammoCount = math.random(self.maxAmmo)
		end

		self.magData[#self.magData+1] = ammoCount
	end

	-- Load the first mag preset
	self:MagManager(1, "load")
end

function RC_AmmoCarrier:MagManager(index, type, newAmount)
	if (type == "load") then
		-- Load Magazine Data
		-- Check if the index is nil
		if (not self.magData[index]) then return false end
		
		-- Strip all ammo for save and load system
		for i = 1, self.maxAmmo do
			self:DecreaseAmmo()
		end
	
		-- Load the ammo count and assign current mag
		for i = 1, self.magData[index] do
			self:IncreaseAmmo(nil, true)
		end

		-- Bool Output
		return true
	elseif (type == "save") then
		-- Save Magazine Data
		-- Check if the index is nil
		if (not self.magData[index]) then return false end

		-- Save
		self.magData[index] = self.ammo

		-- Bool Output
		return true
	elseif (type == "drop") then
		-- Drop Magazine
		if (self.magObj) then
			-- Spawn Mag
			local mag = GameObject.Instantiate(self.magObj, self.transform.position, self.transform.rotation).GetComponent(ScriptedBehaviour).self

			-- Setup Mag Data
			mag.storedAmmoCount = self.ammo
			mag:ApplyBulletAmount()

			-- Remove data and hide mag
			table.remove(self.magData, index)

			if (self.magObjOrig) then
				self.magObjOrig.SetActive(false)
			end

			-- Bool Output
			return true
		end

		-- Bool Output
		return false
	elseif (type == "add") then
		-- Add Magazine
		-- Checks
		if (#self.magData >= 4) then return false end

		-- Add Mag
		self.magData[#self.magData+1] = newAmount

		-- Bool Output
		return true
	end
end

function RC_AmmoCarrier:DecreaseAmmoCylinder(pickRandom, eject, casing, live)
	if (#self.revolverBulletData > 0) then
		if (pickRandom) then
			local chosenRound = self.revolverBulletData[math.random(#self.revolverBulletData)]
			local isGone = chosenRound[3]

			if (not isGone) then
				chosenRound[2] = false
				chosenRound[3] = true
	
				self.ammo = self.ammo - 1
				self.ammo = Mathf.Clamp(self.ammo, 0, 9999)
			end
		elseif (eject) then
			if (not self.useReloadIndex) then
				-- Normal
				for _,data in pairs(self.revolverBulletData) do
					local isGone = data[3]
					local isLive = data[2]
	
					local allowEject = false
					local luck = Random.Range(0, 100)
	
					if (luck < 37.84 and not isLive) then
						allowEject = true
					elseif (isLive) then
						allowEject = true
					end
	
					if (allowEject) then
						if (not isGone) then
							-- Instantiate
							self:InstantiateRound(data[1].transform, data[2], live, casing)
	
							-- Drop
							data[2] = false
							data[3] = true
			
							self.ammo = self.ammo - 1
							self.ammo = Mathf.Clamp(self.ammo, 0, 9999)
						end
					end
				end
			else
				-- One By One
				-- Uses the reloadIndex.
				if (self.currentReloadBullet) then
					-- Get the current reload bullet object
					local reloadBulletOBJ = self.currentReloadBullet[1].gameObject

					-- Same thing what I did above but only ejects at the part where the
					-- Index is. But ignores whether the round is live or not.
					for _,data in pairs(self.revolverBulletData) do
						if (data[1].gameObject == reloadBulletOBJ) then
							local isGone = data[3]
							local isLive = data[2]
							
							if (not isGone) then
								self:InstantiateRound(data[1].transform, data[2], live, casing)

								data[2] = false
								data[3] = true
				
								self.ammo = self.ammo - 1
								self.ammo = Mathf.Clamp(self.ammo, 0, 9999)
								break
							end
						end
					end
				end
			end
		end
	end
end

function RC_AmmoCarrier:InstantiateRound(targetT, isLive, live, casing, prespawn)
	local chosenRound = nil

	if (not prespawn) then
		if (casing and live) then
			if (isLive) then
				chosenRound = live
			else
				chosenRound = casing
			end
		end
	
		if (chosenRound and targetT) then
			local round = GameObject.Instantiate(chosenRound, targetT.position, targetT.rotation)
	
			local roundRB = round.GetComponent(Rigidbody)
			roundRB.AddForce(round.transform.up * 1.25, ForceMode.Impulse)
		end
	else
		local stored = {}
		local chosenLive = false

		for i = 1, 2 do
			if (not chosenLive) then
				if (live) then
					chosenRound = live
				end

				chosenLive = true
			else
				if (casing) then
					chosenRound = casing
				end
			end

			if (chosenRound) then
				local round = GameObject.Instantiate(chosenRound)
				stored[#stored+1] = round
			end
		end

		self.script.StartCoroutine(self:DeleteStored(stored))
	end
end

function RC_AmmoCarrier:DeleteStored(stored)
	return function()
		coroutine.yield(WaitForSeconds(0.15))
		if (#stored > 0) then
			for _,obj in pairs(stored) do
				if (obj) then
					GameObject.Destroy(obj)
				end
			end
		end
	end
end

function RC_AmmoCarrier:DecreaseAmmo(takeAmmo, soundHandler)
	local chosenRound = self.bullets[#self.bullets - self.lastAmmo]
	
	if (chosenRound) then
		chosenRound.SetActive(false)
	end

	if (takeAmmo) then
		if (self.spareAmmo) then
			self.spareAmmo = self.spareAmmo + 1
			self.spareAmmo = Mathf.Clamp(self.spareAmmo, 0, 9999)

			if (soundHandler) then
				soundHandler:PlaySound("bulleteject")
			end
		end
	end

	self.lastAmmo = self.lastAmmo + 1
	self.ammo = self.ammo - 1

	self.lastAmmo = Mathf.Clamp(self.lastAmmo, 0, self.maxAmmo)
	self.ammo = Mathf.Clamp(self.ammo, 0, self.maxAmmo)
end

function RC_AmmoCarrier:IncreaseAmmo(soundHandler, dontStripSpareAmmo)
	if (not self.isCylinder) then
		self.lastAmmo = self.lastAmmo - 1
		local chosenRound = self.bullets[#self.bullets - self.lastAmmo]
		
		if (chosenRound) then
			chosenRound.SetActive(true)
		end
	
		if (self.spareAmmo and not dontStripSpareAmmo) then
			self.spareAmmo = self.spareAmmo - 1
			self.spareAmmo = Mathf.Clamp(self.spareAmmo, 0, 9999)

			if (soundHandler) then
				soundHandler:PlaySound("bulletinsert")
			end
		end

		self.ammo = self.ammo + 1
	
		self.lastAmmo = Mathf.Clamp(self.lastAmmo, 0, self.maxAmmo)
		self.ammo = Mathf.Clamp(self.ammo, 0, self.maxAmmo)
	else
		if (not self.useReloadIndex) then
			-- Normal Reload
			-- Chooses the first empty chamber.
			if (#self.revolverBulletData > 0) then
				for _,round in pairs(self.revolverBulletData) do
					local isGone = round[3]
		
					if (isGone) then
						round[2] = true
						round[3] = false

						if (self.spareAmmo and not dontStripSpareAmmo) then
							self.spareAmmo = self.spareAmmo - 1
							self.spareAmmo = Mathf.Clamp(self.spareAmmo, 0, 9999)

							if (soundHandler) then
								soundHandler:PlaySound("bulletinsert")
							end
						end
	
						self.ammo = self.ammo + 1
						self.ammo = Mathf.Clamp(self.ammo, 0, self.maxAmmo)
						break
					end
				end
			end
		else
			-- One By One
			-- Only loads on the selected chamber.
			if (self.currentReloadBullet) then
				-- Similar thing what I did for the eject
				local reloadBulletOBJ = self.currentReloadBullet[1].gameObject

				for _,round in pairs(self.revolverBulletData) do
					if (round[1].gameObject == reloadBulletOBJ) then
						local isGone = round[3]
		
						if (isGone) then
							round[2] = true
							round[3] = false

							if (self.spareAmmo and not dontStripSpareAmmo) then
								self.spareAmmo = self.spareAmmo - 1
								self.spareAmmo = Mathf.Clamp(self.spareAmmo, 0, 9999)

								if (soundHandler) then
									soundHandler:PlaySound("bulletinsert")
								end
							end
		
							self.ammo = self.ammo + 1
							self.ammo = Mathf.Clamp(self.ammo, 0, self.maxAmmo)
							break
						end
					end
				end
			end
		end
	end
end

function RC_AmmoCarrier:ResupplyAmmo(specificAmount, amount, useMaxAmmo)
	if (not specificAmount) then
		self.spareAmmo = self.spareAmmo + 1
	else
		if (not useMaxAmmo) then
			self.spareAmmo = self.spareAmmo + amount
		else
			self.spareAmmo = self.spareAmmo + self.maxAmmo
		end
	end
end

function RC_AmmoCarrier:StartRotate(isForced, spinLeft)
	if (not isForced) then
		self.script.StartCoroutine(self:Rotate(true))
	else
		if (self.clockwise) then
			self.script.StartCoroutine(self:Rotate(not spinLeft))
		else
			self.script.StartCoroutine(self:Rotate(spinLeft))
		end
	end
end

function RC_AmmoCarrier:ReloadToNormal(reload)
	-- A transition system without changing the bullet's index.
	if (self.useReloadIndex) then
		if (not reload) then
			self.finalAngle = self.currentBullet[4]
			self.isOnReloadMode = false
		else
			if (self.currentReloadBullet[5]) then
				self.finalAngle = self.currentReloadBullet[5]
			end

			self.isOnReloadMode = true
		end
	end
end

function RC_AmmoCarrier:Rotate(spinLeft)
	-- Rotates the carrier
	return function()
		if (self.restrictSpin) then
			if (not spinLeft and self.clockwise) then return end
			if (spinLeft and not self.clockwise) then return end
		end

		if (self.isCylinder) then
			if (spinLeft) then
				if (self.currentBulletIndex < self.maxAmmo) then
					self.currentBulletIndex = self.currentBulletIndex + 1
				else
					self.currentBulletIndex = 1
				end
			elseif (not spinLeft) then
				if (self.currentBulletIndex > 1) then
					self.currentBulletIndex = self.currentBulletIndex - 1
				else
					self.currentBulletIndex = self.maxAmmo
				end
			end
		end

		coroutine.yield(WaitForSeconds(0.05))

		if (not self.isOnReloadMode) then
			self.finalAngle = self.currentBullet[4]
		else
			if (self.useReloadIndex) then
				if (self.currentReloadBullet[5]) then
					self.finalAngle = self.currentReloadBullet[5]
				end
			end
		end
	end
end

function RC_AmmoCarrier:RotateCylinder()
	-- Literally just a rotation lerp lol
	local targetRot = Quaternion.Euler(self.transform.localEulerAngles.x, self.finalAngle, self.transform.localEulerAngles.z)
	self.transform.localRotation = Quaternion.Lerp(self.transform.localRotation, targetRot, 25 * Time.deltaTime)
end