local config = require 'configs.server'
local shared = require 'configs.shared'

local robbedPeds = {}
local cooldowns = {}

GlobalState.copCount = 0

local function isPlayerPed(entity)
    local players = GetPlayers()

    for x = 1, #players do
        if GetPlayerPed(players[x]) == entity then
            return true
        end
    end

    return false
end

---@return boolean, number? entity
local function validateTarget(src, netId)
    if type(netId) ~= 'number' or netId <= 0 then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity == 0 or not DoesEntityExist(entity) then return false end
    if GetEntityType(entity) ~= 1 or isPlayerPed(entity) then return false end

    local ped = GetPlayerPed(src)

    if GetEntityHealth(ped) <= 0 then return false end
    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > config.robDistance then return false end

    return true, entity
end

lib.callback.register('xt-robnpcs:server:robNPC', function(source, netId)
    local valid, entity = validateTarget(source, netId)
    if not valid then return false end

    local now = os.time()

    -- The per-player cooldown is the payout rate limit: it is what stops a client that spams
    -- this callback in a single tick from being paid more than once. Its read and its write
    -- must not straddle a yield, or every spammed call passes the read before any reaches the
    -- write. Everything between them here is synchronous, and config.hasGroup -- the customer
    -- swap point, and the only call that could yield -- is checked AFTER the reservation and
    -- rolls it back on failure, so the guarantee holds even if a framework getter yields.
    if (cooldowns[source] or 0) > now then
        lib.notify(source, { title = locale('slow_down'), description = locale('slow_down_description'), type = 'error' })
        return false
    end

    if (robbedPeds[netId] or 0) > now then return false end
    if shared.requiredCops > 0 and GlobalState.copCount < shared.requiredCops then return false end

    cooldowns[source] = now + config.robCooldown
    robbedPeds[netId] = now + config.pedCooldown

    if config.hasGroup(source, shared.blacklistedJobs) then
        cooldowns[source] = nil
        robbedPeds[netId] = nil
        return false
    end

    Entity(entity).state:set('robbed', true, true)

    if math.random(100) <= math.random(config.payOutChance.min, config.payOutChance.max) then
        config.addCash(source, math.random(config.payOut.min, config.payOut.max))
    else
        lib.notify(source, { title = locale('no_cash'), description = locale('no_cash_description'), type = 'error' })
    end

    if math.random(100) <= math.random(config.chanceItemsFound.min, config.chanceItemsFound.max) then
        local loot = config.lootableItems[math.random(#config.lootableItems)]

        if not config.addItem(source, loot.item, math.random(loot.min, loot.max)) then
            lib.notify(source, { title = locale('pockets_full'), description = locale('pockets_full_description'), type = 'error' })
        end
    end

    return true
end)

local function updateCopCount()
    local players = GetPlayers()
    local count = 0

    for x = 1, #players do
        if config.hasGroup(tonumber(players[x]), config.policeJobs) then
            count += 1
        end
    end

    if GlobalState.copCount ~= count then
        GlobalState.copCount = count
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    print(('^5xT Development ^0| ^5%s^0'):format(GetResourceMetadata(resource, 'description', 0)))
    print('^5Support: ^0https://dsc.gg/xtdev')

    -- Cooldowns are never cleared on drop, or reconnecting would wipe them. They expire
    -- instead. Net ids are recycled, so a ped that is gone must be forgotten too, or its
    -- id blocks whichever live ped inherits it.
    SetInterval(function()
        local now = os.time()

        for src, expiry in pairs(cooldowns) do
            if expiry <= now then
                cooldowns[src] = nil
            end
        end

        for netId, expiry in pairs(robbedPeds) do
            local entity = NetworkGetEntityFromNetworkId(netId)

            if expiry <= now or entity == 0 or not DoesEntityExist(entity) then
                robbedPeds[netId] = nil
            end
        end
    end, 60000)

    if shared.requiredCops <= 0 then return end

    updateCopCount()
    SetInterval(updateCopCount, config.copCountInterval * 1000)
end)
