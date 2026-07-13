local Renewed = exports['Renewed-Lib']

return {
    useSleeplessInteract = false,                           -- Use sleepless_interact instead of ox/qb target (https://github.com/Sleepless-Development/sleepless_interact)
    targetDistance = 20.0,                                  -- Max distance ped reacts to you aiming at them, and stays held up
    reactionTime = 1000,                                    -- Time (ms) the ped takes to notice you before reacting
    robLength = 5,                                          -- Length to rob local (seconds)
    chancePedFlees = {                                      -- Chance ped runs away rather than surrendering
        min = 5,
        max = 25
    },
    chancePedFights = {                                     -- Chance ped beats your ass before or after being robbed
        min = 5,
        max = 15
    },
    chancePedIsArmedWhileFighting = {                       -- Chance ped has a melee weapon to fight player
        min = 80,
        max = 90
    },
    pedWeapons = {                                          -- Weapons ped might have
        'WEAPON_KNIFE',
        'WEAPON_BAT'
    },
    copsChance = {                                          -- Chance police are called
        min = 80,
        max = 90
    },
    allowedWeapons = {                                      -- Weapons allowed to rob peds
        'WEAPON_KNIFE',
        'WEAPON_PISTOL'
    },
    blockedPedTypes = {                                     -- Ped types that can not be robbed (https://docs.fivem.net/natives/?_0xFF059E1E4C01E63C)
        6,                                                  -- Cop
        20,                                                 -- Medic
        21,                                                 -- Fireman
        26,                                                 -- Mission
        27,                                                 -- Swat
        29                                                  -- Army
    },

    isBlacklisted = function(groups)
        for x = 1, #groups do
            if Renewed:hasGroup(groups[x]) then
                return true
            end
        end

        return false
    end,

    onPlayerLoad = function(cb)
        AddEventHandler('QBCore:Client:OnPlayerLoaded', cb)
        AddEventHandler('esx:playerLoaded', cb)
        AddEventHandler('ox:playerLoaded', cb)
    end,

    onPlayerUnload = function(cb)
        AddEventHandler('QBCore:Client:OnPlayerUnload', cb)
        AddEventHandler('esx:onPlayerLogout', cb)
        AddEventHandler('ox:playerLogout', cb)
    end,

    dispatch = function(coords)
        local PoliceJobs = { 'police' }

        -- Add your own dispatch event / exports
        -- exports['ps-dispatch']:CustomAlert({
        --     coords = coords,
        --     job = PoliceJobs,
        --     message = 'Citizen Robbery',
        --     dispatchCode = '10-??',
        --     firstStreet = coords,
        --     description = 'Citizen Robbery',
        --     radius = 0,
        --     sprite = 58,
        --     color = 1,
        --     scale = 1.0,
        --     length = 3,
        -- })
    end
}
