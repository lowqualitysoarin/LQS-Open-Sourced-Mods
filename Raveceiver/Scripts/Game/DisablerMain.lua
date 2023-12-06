behaviour("DisablerMain")

function DisablerMain:Start()
    -- This script disables some stuff from the base game

    -- Call coroutine
    -- Because ActorManager shits it self at the start of the match.
    self.script.StartCoroutine(self:StartDisabling())
end

function DisablerMain:StartDisabling()
    return function()
        coroutine.yield(WaitForSeconds(0.1))

        -- Disable Bots
        -- This mod is meant for singleplayer anyway.
        local actors = ActorManager.actors

        if (#actors > 0) then
            for _, actor in pairs(actors) do
                if (not actor.isPlayer) then
                    actor.Deactivate()
                end
            end
        end

        -- Disable Capture Points
        -- The mod has already a built in spawning system.
        local capturePoints = ActorManager.capturePoints

        for _, point in pairs(capturePoints) do
            point.gameObject.SetActive(false)
        end
    end
end
