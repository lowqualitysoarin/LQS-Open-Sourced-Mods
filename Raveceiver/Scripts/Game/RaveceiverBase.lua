behaviour("RaveceiverBase")

function RaveceiverBase:Awake()
    -- Weapon Essentials (Awake)
    self.startingAmmo = 0
    self.startingSpareAmmo = 0
end

function RaveceiverBase:Start()
    -- Base
    self.data = self.gameObject.GetComponent(DataContainer)
    self.hudScript = self.targets.hudScript.GetComponent(ScriptedBehaviour).self

    -- Listeners
    GameEvents.onActorDied.AddListener(self, "OnPlayerDied")
    GameEvents.onActorSpawn.AddListener(self, "OnPlayerSpawn")

    -- Configuration
    self.levels = self.data.GetGameObjectArray("level")
    self.deadEndsL = self.data.GetGameObjectArray("deadEndsL")
    self.deadEndsR = self.data.GetGameObjectArray("deadEndsR")

    self.space = self.data.GetFloat("space")

    self.cassetteSpawnChance = self.data.GetFloat("cassetteSpawnChance")

	self.sentrySpawnChance = self.data.GetFloat("sentrySpawnChance")
	self.mobileSentrySpawnChance = self.data.GetFloat("mobileSentrySpawnChance")
	self.droneSpawnChance = self.data.GetFloat("droneSpawnChance")
	self.gunDroneSpawnChance = self.data.GetFloat("gunDroneSpawnChance")

    -- Items
    self.cassetteTape = self.targets.cassetteTape

	-- Enemies
	self.sentry = self.targets.sentry
	self.mobileSentry = self.targets.mobileSentry
	self.drone = self.targets.drone
	self.gunDrone = self.targets.gunDrone

    -- Important Arrays
    self.spawns = {}
    self.cassetteSpawns = {}

    self.playerSpawns = {}
    self.droneSpawns = {}
    self.gunDroneSpawns = {}
    self.sentrySpawns = {}
    self.mobileSentrySpawns = {}

    -- Dead End System
    self.lastA = nil
    self.lastB = nil

	-- Optimisation
	self.spawnedEnemies = {}
    self.spawnedItems = {}

    -- Essentials
    self.spawnedLevels = {}
    self.currentZ = self.space
    self.maxInstantiates = 20

    self.newLevelTimer = 0
    self.optiTimer = 1

    self.ACompleted = false
    self.BCompleted = false
    self.gameReady = false
    self.gameAwakened = false
    self.triggeredNewLevel = false
    self.isGenerating = false
    self.alreadyDied = false

    self.copyA = true

    -- Game Rules
    self.noChances = false
    self.shotInTheDark = false

    -- Weapon Essentials
    self.randomConditions = false
    self.randomWeapons = false
end

function RaveceiverBase:PlayGame()
    -- Starts the game 
    self:GenerateLevel(self.levels)
end

function RaveceiverBase:OnPlayerDied(actor)
    -- If the player died then generate a new level
    if (actor.isPlayer) then
        self.script.StartCoroutine(self:StartNewLevel())
    end
end

function RaveceiverBase:OnPlayerSpawn(actor)
    -- This basically handles the weapon stuff, etc..
    if (actor.isPlayer) then
        -- No chances
        -- Puts a listener on the player that checks if the player has taken damage.
        if (self.noChances) then
            actor.onTakeDamage.AddListener(self, "PlayerTakenDamage")
        end

        -- Apply weapon selection
        -- Specified Weapon
        if (self.chosenWeapon and not self.randomWeapons) then
            -- Remove weapons
            for i = 0, 4 do
                actor.RemoveWeapon(i)
            end

            -- Apply weapon
            actor.EquipNewWeaponEntry(self.chosenWeapon, 0, true)
        else
            -- Get all available weapons
            local availableWeapons = self:GetWeaponsRC()

            -- Remove all weapons
            for i = 0, 4 do
                actor.RemoveWeapon(i)
            end

            -- Chose a random weapon and apply
            local chosenWeapon = availableWeapons[math.random(#availableWeapons)]
            actor.EquipNewWeaponEntry(chosenWeapon, 0, true)
        end

        -- Load Conditions
        if (self.randomConditions) then
            -- Makes random conditions. Only works when enabled.
            -- Get the current weapon's max ammo and max spare ammo
            local maxAmmo = actor.activeWeapon.maxAmmo
            local maxSpareAmmo = actor.activeWeapon.maxSpareAmmo

            -- Randomised ammo and spare ammo count
            actor.activeWeapon.ammo = math.random(maxAmmo)
            actor.activeWeapon.spareAmmo = math.random(maxSpareAmmo)
        else
            -- If random conditions if off
            actor.activeWeapon.ammo = self.startingAmmo
            actor.activeWeapon.spareAmmo = self.startingSpareAmmo
        end

        -- Resets Vars
        self:ResetGameVars()
    end
end

function RaveceiverBase:ResetGameVars()
    -- Literally resets some bools, floats, and stuff
    self.alreadyDied = false
end

function RaveceiverBase:PlayerTakenDamage()
    -- If the player has taken damage then die
    local player = Player.actor

    if (self.noChances and player and not player.isDead) then
        self.script.StartCoroutine(self:KillPlayer(player))
    end
end

function RaveceiverBase:KillPlayer(player)
    return function()
        coroutine.yield(WaitForSeconds(0.85))
        if (not self.alreadyDied) then
            player.Kill()
            self.alreadyDied = true
        end
    end
end

function RaveceiverBase:GetWeaponsRC()
    -- Get all available weapons
    local weaponsFound = WeaponManager.allWeapons

    -- Another table that excludes equipments
    local availablesTable = {}

    -- Exclude any melees, throwables, equipment, etc...
    for index,wep in pairs(weaponsFound) do
        -- Check if the weapon's slot is gear or large gear
        -- If the weapon entry isn't then add it to the availables table.
        if (wep.slot ~= WeaponSlot.Gear) then
            if (wep.slot ~= WeaponSlot.LargeGear) then
                availablesTable[#availablesTable+1] = wep
            end
        end
    end

    return availablesTable
end

function RaveceiverBase:GenerateLevel(rLevels)
    -- Instantiate the levels
    -- Select a level
    local chosenLevel = rLevels[math.random(#rLevels)]

    -- Copy level
    local mainLevel = GameObject.Instantiate(chosenLevel, self.transform.position, Quaternion.identity)
    self.spawnedLevels[#self.spawnedLevels+1] = mainLevel

    -- Sideways Instantiate
    self:SidewaysInstantiate(self.levels)
end

function RaveceiverBase:SidewaysInstantiate(rLevels)
    -- Start generating levels sideways
    local chosenLevel = nil

    -- Looping
    for i = 1, self.maxInstantiates do
        -- Choose a level
        chosenLevel = rLevels[math.random(#rLevels)]

        -- Instantiate level
        -- Copy Point
        local copyPoint = Vector3(self.transform.position.x, self.transform.position.y,
        self.transform.position.z + self.currentZ)
        
        if (self.copyA) then
            -- Make a clone
            local spawnedLvl = GameObject.Instantiate(chosenLevel, copyPoint, Quaternion.identity)

            -- Point A Copy Completed
            self.ACompleted = true
            self.copyA = false

            -- Store last A (If it is)
            if (i >= self.maxInstantiates - 1) then
                self.lastA = spawnedLvl
            elseif (i < self.maxInstantiates - 1) then
                self.spawnedLevels[#self.spawnedLevels+1] = spawnedLvl
            end
        else
            -- Make a clone
            local spawnedLvl = GameObject.Instantiate(chosenLevel, -copyPoint, Quaternion.identity)

            -- Point B Copy Completed
            self.BCompleted = true
            self.copyA = true

            -- Store last B
            if (i >= self.maxInstantiates - 1) then
                self.lastB = spawnedLvl
            elseif (i < self.maxInstantiates - 1) then
                self.spawnedLevels[#self.spawnedLevels+1] = spawnedLvl
            end
        end

        -- Checks if Side A and B is are down instantiating before proceeding to
        -- the next instantiate point.
        if (self.ACompleted and self.BCompleted) then
            -- Build up the z axis for the next instantiate
            self.currentZ = self.currentZ + self.space

            -- Reset bools
            self.ACompleted = false
            self.BCompleted = false
        end
    end

    -- Dead End Check
    self:DeadEndSystem(self.lastA, self.lastB)
end

function RaveceiverBase:DeadEndSystem(lastA, lastB)
    -- Replaces the two last levels with dead ends on
    -- their respective sides

    -- Last A (Left)
    -- Get pos
    local lastAPos = lastA.transform.position

    -- Get a random dead end then replace the old level with it
    local chosenEndL = self.deadEndsL[math.random(#self.deadEndsL)]
    local spawnedEndL = GameObject.Instantiate(chosenEndL, lastAPos, Quaternion.identity)

    -- Last B (Right)
    -- Get pos
    local lastBPos = lastB.transform.position

    -- Get a random dead end then replace the old level with it
    local chosenEndR = self.deadEndsR[math.random(#self.deadEndsR)]
    local spawnedEndR = GameObject.Instantiate(chosenEndR, lastBPos, Quaternion.identity)

    -- Remove the old levels and add them to spawnedLevels
    GameObject.Destroy(lastA)
    GameObject.Destroy(lastB)

    self.spawnedLevels[#self.spawnedLevels+1] = spawnedEndL
    self.spawnedLevels[#self.spawnedLevels+1] = spawnedEndR

    -- Spawning Entities
    self.script.StartCoroutine(self:GetSpawns())
end

function RaveceiverBase:GetSpawns()
    return function()
        coroutine.yield(WaitForSeconds(0.1))

        -- Get all scripts
        local scripts = GameObject.FindObjectsOfType(ScriptedBehaviour)

        -- Look for the spawn script by looping
        for _, script in pairs(scripts) do
            if (script.self.isSpawnPoint) then
                -- Entity Spawn
                self.spawns[#self.spawns + 1] = script.self
            elseif (script.self.isCassetteSpawn) then
                -- Cassette Spawn
                self.cassetteSpawns[#self.cassetteSpawns+1] = script.transform.position
            end
        end

        -- Assign the spawn scrips to their respective arrays
        if (#self.spawns > 0) then
            for _, spawnPoint in pairs(self.spawns) do
                -- Is a player spawn
                if (spawnPoint.isPlayerSpawn) then
                    self.playerSpawns[#self.playerSpawns + 1] = spawnPoint.transform.position
                end

                -- Is a drone spawn
                if (spawnPoint.isDroneSpawn) then
                    self.droneSpawns[#self.droneSpawns + 1] = spawnPoint.transform.position
                end

                -- Is a gun drone spawn
                if (spawnPoint.isGunDroneSpawn) then
                    self.gunDroneSpawns[#self.gunDroneSpawns + 1] = spawnPoint.transform.position
                end

                -- Is a sentry spawn
                if (spawnPoint.isSentrySpawn) then
                    self.sentrySpawns[#self.sentrySpawns + 1] = spawnPoint.transform.position
                end

                -- Is a mobile sentry spawn
                if (spawnPoint.isMobileSentrySpawn) then
                    self.mobileSentrySpawns[#self.mobileSentrySpawns + 1] = spawnPoint.transform.position
                end
            end
        end

        -- Spawn player to random spawnpoint
        self:SpawnPlayer()
    end
end

function RaveceiverBase:SpawnPlayer()
    -- Spawns the player to a random position
    if (#self.playerSpawns > 0) then
        -- Choose a random spawnpoint
        local chosenPoint = self.playerSpawns[math.random(#self.playerSpawns)]

        -- Spawn player
        if (Player.actor.isDead) then
            Player.actor.SpawnAt(chosenPoint)
        end
    end

    -- Spawn enemies
    self:SpawnItemsAndEnemies()
end

function RaveceiverBase:SpawnItemsAndEnemies()
	-- Spawns Items and Enemies
	-- This is gonna lag alot lmaooooo
	local playerPos = Player.actor.transform.position

    -- Items
    -- Cassette Tapes
    if (#self.cassetteSpawns > 0) then
        for _,spawn in pairs(self.cassetteSpawns) do
            -- Luck system
			local luck = Random.Range(1, 100)

			-- Distance to player
			-- To prevent being close to the player.
			local distanceToPlayer = (spawn - playerPos).magnitude

            -- Spawn cassette on point if it passes luck
            if (luck < self.cassetteSpawnChance and distanceToPlayer > 15) then
                local spawnedCassette = GameObject.Instantiate(self.cassetteTape, Vector3(spawn.x, spawn.y + 0.15, spawn.z), Quaternion.identity)
                self.spawnedItems[#self.spawnedItems+1] = spawnedCassette
            end 
        end
    end

    -- Enemies
	-- Spawn Sentries
	if (#self.sentrySpawns > 0) then
		for _,spawn in pairs(self.sentrySpawns) do
			-- Luck system
			local luck = Random.Range(1, 100)

			-- Distance to player
			-- To prevent being spawnkilled.
			local distanceToPlayer = (spawn - playerPos).magnitude

			-- Spawn sentry on paint if it passes the luck
			if (luck < self.sentrySpawnChance and distanceToPlayer > 20) then
				local spawnedSentry = GameObject.Instantiate(self.sentry, spawn, Quaternion.Euler(0, Random.Range(0, 360), 0))
				self.spawnedEnemies[#self.spawnedEnemies+1] = {
                    spawnedSentry, 
                    spawnedSentry.GetComponentsInChildren(TurretVitalPart)
                }
			end
		end
	end

	-- Spawn Mobile Sentries
	if (#self.mobileSentrySpawns > 0) then
		for _,spawn in pairs(self.mobileSentrySpawns) do
			-- Luck system
			local luck = Random.Range(1, 100)

			-- Distance to player
			-- To prevent being spawnkilled.
			local distanceToPlayer = (spawn - playerPos).magnitude

			-- Spawn sentry on paint if it passes the luck
			if (luck < self.mobileSentrySpawnChance and distanceToPlayer > 20) then
				local spawnedMobileSentry = GameObject.Instantiate(self.mobileSentry, spawn, Quaternion.Euler(0, Random.Range(0, 360), 0))
				self.spawnedEnemies[#self.spawnedEnemies+1] = {
                    spawnedMobileSentry, 
                    spawnedMobileSentry.GetComponentsInChildren(TurretVitalPart)
                }
			end
		end
	end

	-- Spawn Drones
	if (#self.droneSpawns > 0) then
		for _,spawn in pairs(self.droneSpawns) do
			-- Luck system
			local luck = Random.Range(1, 100)

			-- Distance to player
			-- To prevent being spawnkilled.
			local distanceToPlayer = (spawn - playerPos).magnitude

			-- Spawn drone on paint if it passes the luck
			if (luck < self.droneSpawnChance and distanceToPlayer > 20) then
				local spawnedDrone = GameObject.Instantiate(self.drone, spawn, Quaternion.Euler(0, Random.Range(0, 360), 0))
				self.spawnedEnemies[#self.spawnedEnemies+1] = {
                    spawnedDrone, 
                    spawnedDrone.GetComponentsInChildren(DroneVitalPart)
                }
			end
		end
	end

	-- Spawn Gun Drones
	if (#self.gunDroneSpawns > 0) then
		for _,spawn in pairs(self.gunDroneSpawns) do
			-- Luck system
			local luck = Random.Range(1, 100)

			-- Distance to player
			-- To prevent being spawnkilled.
			local distanceToPlayer = (spawn - playerPos).magnitude

			-- Spawn drone on paint if it passes the luck
			if (luck < self.gunDroneSpawnChance and distanceToPlayer > 20) then
				local spawnedGunDrone = GameObject.Instantiate(self.gunDrone, spawn, Quaternion.Euler(0, Random.Range(0, 360), 0))
				self.spawnedEnemies[#self.spawnedEnemies+1] = {
                    spawnedGunDrone, 
                    spawnedGunDrone.GetComponentsInChildren(DroneVitalPart)
                }
			end
		end
	end

    -- Set gameReady and gameAwakened to true
    self.gameReady = true
    self.gameAwakened = true

    -- Start game and set isGenerating to false
    self:StartGame()
    self.isGenerating = false
end

function RaveceiverBase:StartGame()
    -- This calls stuff like the HUD fade in etc...
    if (self.hudScript) then
        self.hudScript:BlackScreenFade(true)
    end
end

function RaveceiverBase:Update()
    -- Only works if the game is started/awakened
    if (self.gameAwakened) then
        -- GameEvents
        self:GameEventsRaveceiver()
    end

    -- Only works if the game is ready to play
	if (self.gameReady) then
        -- Optimisation
        -- Doing this with a timer now because it gives a massive lag instead of perf boost.
        self.optiTimer = self.optiTimer + 1 * Time.deltaTime
        
        if (self.optiTimer >= 1) then
            if (#self.spawnedEnemies > 0 and #self.spawnedItems > 0 and #self.spawnedLevels > 0) then
                self:Optimisation()
            end

            self.optiTimer = 0
        end
    end
end

function RaveceiverBase:GameEventsRaveceiver()
    -- Just like the EventsSytem but only for this mod.
    -- Essentials
    local player = Player.actor

    -- Main
    if (player) then
        
    end
end

function RaveceiverBase:StartNewLevel()
    -- Literally starts a new level (Generates a new one)
    return function()
        coroutine.yield(WaitForSeconds(5))
        self:RemoveLevels()
    end
end

function RaveceiverBase:Optimisation()
    -- Get the player pos
    -- This is used for culling enemies.
    local playerPos = Player.actor.transform.position

    -- Do a loop for the optimisation

    -- This loop does a loop to all spawned enemies. It gets their current pos
    -- and prefab. If they are far away from the player they will be culled.
    -- Its kind of awful but atleast it gives a decent 60-50 frames.
    for _,enemyData in pairs(self.spawnedEnemies) do
        -- Get the enemy prefab and position
        local prefab = enemyData[1]
        local vitals = enemyData[2]

        if (prefab and vitals) then
            -- Get the prefab position
            local pos = prefab.transform.position

            -- Get the distance between this enemy and the player
            local distToPlayer = (pos - playerPos).magnitude

            -- Disable if far away from the player and enable if close
            if (distToPlayer > 25) then
                -- Tick isCulled to the vital parts soo the enemy won't die
                -- when culled.
                for _,vital in pairs(vitals) do
                    vital.isCulled = true
                end

                -- Disable prefab
                prefab.SetActive(false)
            else
                -- Enable prefab
                prefab.SetActive(true)

                -- Tick isCulled to the vital parts soo the enemy won't die
                -- when culled.
                for _,vital in pairs(vitals) do
                    vital.isCulled = false
                end
            end
        end
    end

    -- Same thing but for items
    for _,item in pairs(self.spawnedItems) do
        if (item) then
            local itemPos = item.transform.position
            local distanceToPlayer = (itemPos - playerPos).magnitude

            if (distanceToPlayer > 25) then
                item.SetActive(false)
            else
                item.SetActive(true)
            end
        end
    end

    -- Levels optimisation
    -- This will look awful but boosts fps and can handle large amount of tiles
    -- I guess.
    for _,level in pairs(self.spawnedLevels) do
        if (level) then
            local levelPos = level.transform.position
            local distanceToPlayer = (levelPos - playerPos).magnitude

            if (distanceToPlayer > 45) then
                level.SetActive(false)
            else
                level.SetActive(true)
            end
        end
    end
end

function RaveceiverBase:RemoveLevels()
    -- Basically removes all levels. Needed if the player dies and needs to generate a new level.
    local spawnedLevels = self.spawnedLevels

    -- Entities
    local spawnedItems = self.spawnedItems
    local spawnedEnemies = self.spawnedEnemies

    -- First Stage (Remove all Entities)
    -- Enemies
    if (#spawnedEnemies > 0) then
        for _,data in pairs(spawnedEnemies) do
            local prefab = data[1]

            if (prefab) then
                GameObject.Destroy(prefab.transform.root.gameObject)
            end
        end
    end

    -- Clear spawnedEnemies table
    self.spawnedEnemies = {}

    -- Items
    if (#spawnedItems > 0) then
        for _,prefab in pairs(spawnedItems) do
            if (prefab) then
                GameObject.Destroy(prefab.transform.root.gameObject)
            end
        end
    end

    -- Clear spawnedItems table
    self.spawnedItems = {}

    -- Second Stage (Remove all levels)
    if (#spawnedLevels > 0) then
        for _,level in pairs(spawnedLevels) do
            if (level) then
                GameObject.Destroy(level.transform.root.gameObject)
            end
        end
    end

    -- Clear level datas
    self.spawnedLevels = {}
    self.lastA = nil
    self.lastB = nil

    self.ACompleted = false
    self.BCompleted = false
    self.copyA = true

    -- Finalize
    self:ClearSpawnData()
end

function RaveceiverBase:ClearSpawnData()
    -- Clears all the spawn data
    self.spawns = {}
    self.cassetteSpawns = {}

    self.playerSpawns = {}
    self.droneSpawns = {}
    self.gunDroneSpawns = {}
    self.sentrySpawns = {}
    self.mobileSentrySpawns = {}

    -- Reset space data
    self.currentZ = self.space

    -- Set gameReady to false because its all reseted
    self.gameReady = false

    -- Reset Optimisation timer
    self.optiTimer = 1

    -- Generate a new level
    self.script.StartCoroutine(self:NewLevelDelay())
end

function RaveceiverBase:NewLevelDelay()
    return function()
        coroutine.yield(WaitForSeconds(0.65))
        self:GenerateLevel(self.levels)
    end
end
