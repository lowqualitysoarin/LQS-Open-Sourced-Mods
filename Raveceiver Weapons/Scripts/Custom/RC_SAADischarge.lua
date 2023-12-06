-- low_quality_soarin © 2023-2024

-- A custom script.
-- To test moddablity.
behaviour("RC_SAADischarge")

function RC_SAADischarge:Start()
    -- Base
    self.rcScript = self.targets.rcScript.GetComponent(ScriptedBehaviour).self

    -- Vars
    self.alreadyShot = false

    self.hasFall = false
    self.fallVel = 0
end

function RC_SAADischarge:Update()
    -- A accidental discharge feature for the Colt Single Action Army
    -- If the player falls high and the hammer is sitting right next to a live primer.
    -- It will fire.
    local player = Player.actor

    if (player and not player.isDead) then
        -- Ray Calculations idk
        local playerHeight = Vector3(player.transform.position.x, player.transform.position.y + 1,
            player.transform.position.z)

        local downRay = Ray(playerHeight, Vector3.down)
        local groundCheck = Physics.Spherecast(downRay, 0.5, 1, RaycastTarget.ProjectileHit)

        -- Monitor Fall Speed
        if (not groundCheck) then
			-- Toggle Bool
			self.hasFall = true
			self.alreadyShot = false

			-- Get the fall height
            self.fallVel = -player.velocity.y
        else
            -- Discharge
            -- If the player falls
            if (self.hasFall) then
                if (self.fallVel > 8) then
                    if (self.rcScript and not self.alreadyShot) then
                        if (self:CanShootSelf()) then
							self.rcScript:ShootSelf(false, true)
						end
						
                        self.alreadyShot = true
                    end
                end
            end

            self.hasFall = false
        end
    end
end

function RC_SAADischarge:CanShootSelf()
    if (not self.rcScript.hammerReady and not self.rcScript.halfCocked) then
        if (self.rcScript.accidentalDischarges) then
            return true
        end
    end

    return false
end
