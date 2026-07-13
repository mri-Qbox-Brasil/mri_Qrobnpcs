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
