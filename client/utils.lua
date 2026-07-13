local config = require 'configs.client'

local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local IsPedDeadOrDying = IsPedDeadOrDying
local TaskPlayAnim = TaskPlayAnim
local IsEntityPlayingAnim = IsEntityPlayingAnim

local ANIM_DICT = 'random@shop_robbery'
local KNEEL_LOOP = 'kneel_loop_p'
local KNEEL_GETUP = 'kneel_getup_p'
local ROB_CLIP = 'robbery_action_b'

-- World, vehicles, peds and objects. Peds-only flags let the ray pass through walls.
local RAYCAST_FLAGS = 1 | 2 | 4 | 16

-- Cops, medics, firemen, mission peds, swat, army. Ambient civilians only.
local blockedPedTypes = { [6] = true, [20] = true, [21] = true, [26] = true, [27] = true, [29] = true }

local allowedWeapons = {}
for x = 1, #config.allowedWeapons do
    allowedWeapons[joaat(config.allowedWeapons[x])] = true
end

local targetExport, useQbTarget

-- qb-target may still be 'starting' when this file loads, so resolve on first use.
local function target()
    if not targetExport then
        useQbTarget = GetResourceState('qb-target') == 'started'
        targetExport = useQbTarget and exports['qb-target'] or exports.ox_target
    end

    return targetExport, useQbTarget
end

local utils = {}

function utils.isAllowedWeapon(weapon)
    return weapon ~= nil and allowedWeapons[weapon] == true
end

function utils.getDistance(entity)
    return #(GetEntityCoords(cache.ped) - GetEntityCoords(entity))
end

function utils.isAiming()
    return IsPlayerFreeAiming(cache.playerId) or IsPlayerTargettingAnything(cache.playerId) or IsControlPressed(0, 25)
end

function utils.isRobbable(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if GetEntityType(entity) ~= 1 then return false end
    if Entity(entity).state.robbed then return false end

    -- 1-5 are the ambient/random population types. Anything else was spawned by a script.
    local popType = GetEntityPopulationType(entity)
    if popType < 1 or popType > 5 then return false end

    if blockedPedTypes[GetPedType(entity)] then return false end
    if not IsPedHuman(entity) or IsPedAPlayer(entity) then return false end
    if IsPedDeadOrDying(entity, true) or IsPedInAnyVehicle(entity, false) then return false end
    if IsPedArmed(entity, 7) then return false end

    return true
end

function utils.raycast(distance)
    local weaponObject = GetCurrentPedWeaponEntityIndex(cache.ped)
    local origin

    if weaponObject and weaponObject ~= 0 then
        local muzzle = GetEntityBoneIndexByName(weaponObject, 'gun_muzzle')
        origin = muzzle ~= -1 and GetWorldPositionOfEntityBone(weaponObject, muzzle) or GetEntityCoords(weaponObject)
    else
        origin = GetPedBoneCoords(cache.ped, 31086, 0.0, 0.0, 0.0)
    end

    local camRot = GetGameplayCamRot(2)
    local pitch, yaw = math.rad(camRot.x), math.rad(camRot.z)
    local cosPitch = math.cos(pitch)
    local direction = vec3(-math.sin(yaw) * cosPitch, math.cos(yaw) * cosPitch, math.sin(pitch))

    local hit, entity = lib.raycast.fromCoords(origin, origin + (direction * distance), RAYCAST_FLAGS, 4)

    return hit, entity
end

function utils.notifyPolice(coords)
    if math.random(100) <= math.random(config.copsChance.min, config.copsChance.max) then
        config.dispatch(coords)
    end
end

function utils.addInteraction(entity, onSelect)
    if config.useInteract then
        return exports.interact:AddEntityInteraction({
            netId = NetworkGetNetworkIdFromEntity(entity),
            id = 'robLocal',
            distance = 4.0,
            interactDst = 2.0,
            ignoreLos = false,
            options = {
                {
                    label = locale('rob_citizen'),
                    action = function()
                        onSelect(entity)
                    end,
                }
            }
        })
    end

    local export, isQb = target()

    if isQb then
        return export:AddTargetEntity(entity, {
            distance = 2.0,
            options = {
                {
                    type = 'client',
                    icon = 'fas fa-gun',
                    label = locale('rob_citizen'),
                    action = function()
                        onSelect(entity)
                    end,
                }
            }
        })
    end

    export:addLocalEntity(entity, {
        {
            name = 'rob_local',
            label = locale('rob_citizen'),
            icon = 'fas fa-gun',
            distance = 2.0,
            onSelect = function()
                onSelect(entity)
            end,
        }
    })
end

function utils.removeInteraction(entity)
    if config.useInteract then
        return exports.interact:RemoveEntityInteraction(NetworkGetNetworkIdFromEntity(entity), 'robLocal')
    end

    local export, isQb = target()

    if isQb then
        return export:RemoveTargetEntity(entity, locale('rob_citizen'))
    end

    export:removeLocalEntity(entity, 'rob_local')
end

function utils.robAnimation(length)
    return lib.progressCircle({
        label = locale('running_pockets'),
        duration = length * 1000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true },
        anim = { dict = ANIM_DICT, clip = ROB_CLIP },
    })
end

-- Turn to face the robber, hands up, then ease down into the kneel. The blend speeds are
-- deliberately low so the ped settles into each pose rather than snapping between them.
-- Bails on every yield if the holdup ended, or the freeze would outlive the robbery.
function utils.surrender(entity, isHeldUp)
    lib.requestAnimDict(ANIM_DICT)

    ClearPedTasks(entity)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedCanRagdoll(entity, false)
    TaskTurnPedToFaceEntity(entity, cache.ped, 800)
    Wait(600)

    if not isHeldUp() or not DoesEntityExist(entity) then return false end

    TaskHandsUp(entity, -1, cache.ped, -1, true)
    SetPedKeepTask(entity, true)
    Wait(1200)

    if not isHeldUp() or not DoesEntityExist(entity) then return false end

    TaskPlayAnim(entity, ANIM_DICT, KNEEL_LOOP, 2.0, 2.0, -1, 1, 0.0, false, false, false)
    Wait(900)

    if not isHeldUp() or not DoesEntityExist(entity) then return false end

    FreezeEntityPosition(entity, true)

    return true
end

-- Ambient events can still break the loop out from under us, so re-assert it at the
-- same low blend speed. Re-blending, rather than snapping, keeps the recovery invisible.
function utils.keepSurrendered(entity, isHeldUp)
    CreateThread(function()
        while isHeldUp() do
            if not DoesEntityExist(entity) then return end

            if not IsEntityPlayingAnim(entity, ANIM_DICT, KNEEL_LOOP, 3) then
                TaskPlayAnim(entity, ANIM_DICT, KNEEL_LOOP, 2.0, 2.0, -1, 1, 0.0, false, false, false)
            end

            Wait(500)
        end
    end)
end

function utils.getUp(entity)
    if not DoesEntityExist(entity) then return end

    local kneeling = IsEntityPlayingAnim(entity, ANIM_DICT, KNEEL_LOOP, 3)

    FreezeEntityPosition(entity, false)
    SetPedCanRagdoll(entity, true)

    if IsPedDeadOrDying(entity, true) then return end

    -- Released before they ever knelt (holstered, walked off) — nothing to stand up from.
    if not kneeling then
        SetPedKeepTask(entity, false)
        ClearPedTasks(entity)
        return
    end

    lib.requestAnimDict(ANIM_DICT)
    TaskPlayAnim(entity, ANIM_DICT, KNEEL_GETUP, 2.0, 2.0, 2200, 0, 0.0, false, false, false)
    Wait(2200)

    SetPedKeepTask(entity, false)
end

-- Synchronous teardown for resource stop / logout, where a yielding thread will never resume.
function utils.release(entity)
    if not entity or not DoesEntityExist(entity) then return end

    utils.removeInteraction(entity)
    FreezeEntityPosition(entity, false)
    SetPedCanRagdoll(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, false)
    SetPedKeepTask(entity, false)
    ClearPedTasks(entity)
end

function utils.fight(entity)
    if not DoesEntityExist(entity) or IsPedDeadOrDying(entity, true) then return end

    ClearPedTasks(entity)
    SetBlockingOfNonTemporaryEvents(entity, false)
    SetPedFleeAttributes(entity, 0, 0)
    SetPedCombatAttributes(entity, 46, 1)       -- BF_CanFightArmedPedsWhenNotArmed
    SetPedCombatAttributes(entity, 17, 0)       -- BF_AlwaysFlee
    SetPedCombatAttributes(entity, 5, 1)        -- BF_AlwaysFight
    SetPedCombatAttributes(entity, 58, 1)       -- BF_DisableFleeFromCombat
    SetPedCombatRange(entity, 3)
    SetPedRelationshipGroupHash(entity, joaat('HATES_PLAYER'))

    if math.random(100) <= math.random(config.chancePedIsArmedWhileFighting.min, config.chancePedIsArmedWhileFighting.max) then
        GiveWeaponToPed(entity, joaat(config.pedWeapons[math.random(#config.pedWeapons)]), 1, false, true)
    end

    TaskCombatHatedTargetsAroundPed(entity, 50, 0)
    lib.notify({ title = locale('fight_back'), description = locale('fight_back_description'), type = 'error' })
end

function utils.flee(entity)
    if not DoesEntityExist(entity) or IsPedDeadOrDying(entity, true) then return end

    SetBlockingOfNonTemporaryEvents(entity, false)
    SetPedKeepTask(entity, false)
    TaskReactAndFleePed(entity, cache.ped)
end

---@return 'fight' | 'flee' | 'surrender'
function utils.rollReaction()
    local fight = math.random(config.chancePedFights.min, config.chancePedFights.max)
    local flee = math.random(config.chancePedFlees.min, config.chancePedFlees.max)
    local roll = math.random(100)

    if roll <= fight then return 'fight' end
    if roll <= fight + flee then return 'flee' end

    return 'surrender'
end

return utils
