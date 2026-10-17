<<<<<<< fork
local config = require 'configs.client'
local shared = require 'configs.shared'
local globalState = GlobalState

targetLocal = nil
isRobbing = false

-- Ped Gets Up & Runs Away --
local function pedGetUp(entity)
    targetLocal = nil
    isRobbing = false

    removeInteraction(entity)

    if IsPedDeadOrDying(entity, true) then
        return
    end

    FreezeEntityPosition(entity, false)
    lib.requestAnimDict('random@shop_robbery')
    TaskPlayAnim(entity, 'random@shop_robbery', 'kneel_getup_p', 2.0, 2.0, 2500, 9, 0, false, false, false)
    Wait(2500)

    if not cache.ped then
        return
    end

    local fightChance = math.random(config.chancePedFights.min, config.chancePedFights.max)
    local randomChance = math.random(100)
    if randomChance <= fightChance then
        attackingPed(entity)
    else
        pedFlees(entity)
    end
end

-- Handle Robbing Local --
local function robLocal(entity)
    if lib.progressCircle({
        label = 'Vasculhando bolsos...',
        duration = (config.robLength * 1000),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true },
        anim = { dict = 'random@shop_robbery', clip = 'robbery_action_b' },
    }) then
        local netID = NetworkGetNetworkIdFromEntity(entity)
        local robbed = lib.callback.await('xt-robnpcs:server:robNPC', false, netID)
        if robbed then
            pedGetUp(entity)
        end
    end
end

-- Adds Interaction to Ped --
local function addInteraction(entity)
    if config.useInteract then
        local netId = NetworkGetNetworkIdFromEntity(entity)

        exports.interact:AddEntityInteraction({
            netId = netId,
            id = 'robLocal',
            distance = 4.0,
            interactDst = 2.0,
            ignoreLos = false,
            options = {
                {
                    label = 'Roubar',
                    action = function(_, coords, args)
                        robLocal(entity)
                    end,
                },
            }
        })
    else
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    type = "client",
                    icon = 'fas fa-gun',
                    label = 'Roubar',
                    action = function(entity)
                        if GetEntityHealth(entity) <= 101 then return end
                        robLocal(entity)
                    end,
                }
            },
            distance = 2.0,
        })
    end
end

-- Local Plays Anim / Add Target --
local function handlePedInteraction(pedEntity)
    isRobbing = true
    targetLocal = pedEntity

    Wait(2000) -- Just a little "buffer" so they dont react instantly

    local coords = GetEntityCoords(targetLocal)
    notifyPolice(coords)

    TaskStandStill(targetLocal, 2000)

    -- Chance ped does not surrender
    if fightOrFlee(targetLocal) then
        isRobbing = false
        targetLocal = nil
        Entity(pedEntity).state:set('robbed', true, false)
        return
    end

    TaskHandsUp(targetLocal, 2000)
    SetPedKeepTask(targetLocal, true)
    FreezeEntityPosition(targetLocal, true)
    Wait(2000)

    forceSurrenderAnimation(targetLocal)
    addInteraction(targetLocal)
end

local function aimAtPedsLoop(newWeapon)
    local sleep = 10
    while cache.weapon ~= nil do
        if globalState?.copCount >= shared.requiredCops then
            local dist

            -- Ped gets up and runs away if you're too far away
            if targetLocal ~= nil then
                dist = getDistance(targetLocal)
                if dist > config.targetDistance then
                    pedGetUp(targetLocal)
                end
            end

            local entity

            if IsPlayerTargettingAnything(cache.playerId) then
                _, entity = GetPlayerTargetEntity(cache.playerId)
                sleep = 10
            elseif IsPlayerFreeAiming(cache.playerId) then
                _, entity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
                sleep = 10
            else
                sleep = 500
            end

            if entity ~= nil then
                local entityState = Entity(entity)?.state?.robbed
                local missionEntity = (GetEntityPopulationType(entity) == 7)
                dist = getDistance(entity)

                if dist <= config.targetDistance and not entityState and not missionEntity and not isRobbing and IsPedHuman(entity) and not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, true) and not IsPedInAnyVehicle(entity) then
                    handlePedInteraction(entity)
                end
            end
        else
            sleep = 500
        end
        Wait(sleep)
    end
end

-- Handlers --
lib.onCache('weapon', function(newWeapon)
    if not newWeapon or not isAllowedWeapon(newWeapon) or isBlacklistedJob(config.blacklistedJobs) then return end

    aimAtPedsLoop(newWeapon)
end)

AddEventHandler('xt-robnpcs:client:onUnload', function()
    if not targetLocal then return end
    pedGetUp(targetLocal)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not targetLocal then return end
    pedGetUp(targetLocal)
end)
||||||| base
local config = require 'configs.client'
local shared = require 'configs.shared'
local globalState = GlobalState

targetLocal = nil
isRobbing = false

-- Ped Gets Up & Runs Away --
local function pedGetUp(entity)
    targetLocal = nil
    isRobbing = false

    removeInteraction(entity)

    if IsPedDeadOrDying(entity, true) then
        return
    end

    FreezeEntityPosition(entity, false)
    lib.requestAnimDict('random@shop_robbery')
    TaskPlayAnim(entity, 'random@shop_robbery', 'kneel_getup_p', 2.0, 2.0, 2500, 9, 0, false, false, false)
    Wait(2500)

    if not cache.ped then
        return
    end

    local fightChance = math.random(config.chancePedFights.min, config.chancePedFights.max)
    local randomChance = math.random(100)
    if randomChance <= fightChance then
        attackingPed(entity)
    else
        pedFlees(entity)
    end
end

-- Handle Robbing Local --
local function robLocal(entity)
    if lib.progressCircle({
        label = 'Running Pockets...',
        duration = (config.robLength * 1000),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true },
        anim = { dict = 'random@shop_robbery', clip = 'robbery_action_b' },
    }) then
        local netID = NetworkGetNetworkIdFromEntity(entity)
        local robbed = lib.callback.await('xt-robnpcs:server:robNPC', false, netID)
        if robbed then
            pedGetUp(entity)
        end
    end
end

-- Adds Interaction to Ped --
local function addInteraction(entity)
    if config.useInteract then
        local netId = NetworkGetNetworkIdFromEntity(entity)

        exports.interact:AddEntityInteraction({
            netId = netId,
            id = 'robLocal',
            distance = 4.0,
            interactDst = 2.0,
            ignoreLos = false,
            options = {
                {
                    label = 'Rob Citizen',
                    action = function(_, coords, args)
                        robLocal(entity)
                    end,
                },
            }
        })
    else
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    type = "client",
                    icon = 'fas fa-gun',
                    label = 'Rob Citizen',
                    action = function(entity)
                        robLocal(entity)
                    end,
                }
            },
            distance = 2.0,
        })
    end
end

-- Local Plays Anim / Add Target --
local function handlePedInteraction(pedEntity)
    isRobbing = true
    targetLocal = pedEntity

    Wait(2000) -- Just a little "buffer" so they dont react instantly

    local coords = GetEntityCoords(targetLocal)
    notifyPolice(coords)

    TaskStandStill(targetLocal, 2000)

    -- Chance ped does not surrender
    if fightOrFlee(targetLocal) then
        isRobbing = false
        targetLocal = nil
        Entity(pedEntity).state:set('robbed', true, false)
        return
    end

    TaskHandsUp(targetLocal, 2000)
    SetPedKeepTask(targetLocal, true)
    FreezeEntityPosition(targetLocal, true)
    Wait(2000)

    forceSurrenderAnimation(targetLocal)
    addInteraction(targetLocal)
end

local function aimAtPedsLoop(newWeapon)
    local sleep = 10
    while cache.weapon ~= nil do
        if globalState?.copCount >= shared.requiredCops then
            local dist

            -- Ped gets up and runs away if you're too far away
            if targetLocal ~= nil then
                dist = getDistance(targetLocal)
                if dist > config.targetDistance then
                    pedGetUp(targetLocal)
                end
            end

            local entity

            if IsPlayerTargettingAnything(cache.playerId) then
                _, entity = GetPlayerTargetEntity(cache.playerId)
                sleep = 10
            elseif IsPlayerFreeAiming(cache.playerId) then
                _, entity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
                sleep = 10
            else
                sleep = 500
            end

            if entity ~= nil then
                local entityState = Entity(entity)?.state?.robbed
                local missionEntity = (GetEntityPopulationType(entity) == 7)
                dist = getDistance(entity)

                if dist <= config.targetDistance and not entityState and not missionEntity and not isRobbing and IsPedHuman(entity) and not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, true) and not IsPedInAnyVehicle(entity) then
                    handlePedInteraction(entity)
                end
            end
        else
            sleep = 500
        end
        Wait(sleep)
    end
end

-- Handlers --
lib.onCache('weapon', function(newWeapon)
    if not newWeapon or not isAllowedWeapon(newWeapon) or isBlacklistedJob(config.blacklistedJobs) then return end

    aimAtPedsLoop(newWeapon)
end)

AddEventHandler('xt-robnpcs:client:onUnload', function()
    if not targetLocal then return end
    pedGetUp(targetLocal)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not targetLocal then return end
    pedGetUp(targetLocal)
end)
=======
local config = require 'configs.client'
local shared = require 'configs.shared'
local utils = require 'client.utils'

local robbing = false
local claiming = false
local heldUp = nil
local aimToken = 0

local robPed

local function stillHeldUp(entity)
    return function()
        return heldUp == entity
    end
end

local function endHoldup(entity)
    if heldUp ~= entity then return end

    heldUp = nil
    utils.removeInteraction(entity)

    CreateThread(function()
        utils.getUp(entity)

        if utils.rollReaction() == 'fight' then
            utils.fight(entity)
        else
            utils.flee(entity)
        end

        robbing = false
    end)
end

function robPed(entity)
    if claiming or heldUp ~= entity then return end
    claiming = true

    if utils.robAnimation(config.robLength) then
        lib.callback.await('xt-robnpcs:server:robNPC', false, NetworkGetNetworkIdFromEntity(entity))
    end

    claiming = false

    -- Released whether the server paid out, rejected the claim, or the animation was
    -- interrupted. A failed rob must never leave the ped frozen.
    endHoldup(entity)
end

local function beginHoldup(entity)
    robbing = true
    heldUp = entity

    utils.notifyPolice(GetEntityCoords(entity))

    Wait(config.reactionTime)

    if heldUp ~= entity then return end

    local reaction = utils.rollReaction()

    if reaction ~= 'surrender' then
        Entity(entity).state:set('robbed', true, false)
        heldUp = nil

        if reaction == 'fight' then
            utils.fight(entity)
        else
            utils.flee(entity)
            lib.notify({ title = locale('ran_away'), type = 'error' })
        end

        Wait(2000)
        robbing = false

        return
    end

    local isHeldUp = stillHeldUp(entity)

    if not utils.surrender(entity, isHeldUp) then
        return endHoldup(entity)
    end

    utils.keepSurrendered(entity, isHeldUp)
    utils.addInteraction(entity, robPed)
end

local function startAimLoop(weapon)
    aimToken += 1

    if not utils.isAllowedWeapon(weapon) then
        if heldUp then endHoldup(heldUp) end
        return
    end

    if config.isBlacklisted(shared.blacklistedJobs) then return end

    local token = aimToken

    CreateThread(function()
        while token == aimToken do
            local sleep = 500

            if heldUp then
                sleep = 250

                if not DoesEntityExist(heldUp) or utils.getDistance(heldUp) > config.targetDistance then
                    endHoldup(heldUp)
                end
            elseif not robbing and not cache.vehicle and (GlobalState.copCount or 0) >= shared.requiredCops and utils.isAiming() then
                sleep = 10

                local hit, entity = utils.raycast(config.targetDistance)

                -- The raycast yields a few frames. If the weapon changed while it resolved,
                -- this loop is already stale and heldUp is still nil, so committing now would
                -- freeze a ped that no live loop is left to release.
                if token ~= aimToken then break end

                if hit and utils.isRobbable(entity) and utils.getDistance(entity) <= config.targetDistance then
                    beginHoldup(entity)
                end
            end

            Wait(sleep)
        end
    end)
end

local function cleanup()
    aimToken += 1
    robbing = false
    claiming = false

    if not heldUp then return end

    utils.release(heldUp)
    heldUp = nil
end

lib.onCache('weapon', startAimLoop)

-- lib.onCache only fires on a change, so a weapon already in hand when the resource
-- starts (or when the player spawns) would never arm the loop.
CreateThread(function()
    startAimLoop(cache.weapon)
end)

config.onPlayerLoad(function()
    startAimLoop(cache.weapon)
end)

config.onPlayerUnload(cleanup)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    cleanup()
end)
>>>>>>> upstream
