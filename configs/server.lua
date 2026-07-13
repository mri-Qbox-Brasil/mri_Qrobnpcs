local Renewed = exports['Renewed-Lib']

return {
    payOut = {              -- Payout min/max
        min = 10,
        max = 20
    },
    payOutChance = {        -- Chance player receives cash
        min = 70,
        max = 80
    },
    chanceItemsFound = {    -- Chance player finds items
        min = 80,
        max = 90
    },
    lootableItems = {       -- Items player can loot
        { item = 'rolex', min = 1, max = 2 },
        { item = 'phone', min = 1, max = 2 }
    },
    robCooldown = 20,       -- Cooldown (seconds) between robberies, per player. This is the payout rate limit
    pedCooldown = 300,      -- How long (seconds) a robbed ped stays unrobbable, for everyone
    robDistance = 5.0,      -- Max distance (m) the player may be from the ped when the payout is claimed

    hasGroup = function(src, groups)
        for x = 1, #groups do
            if Renewed:hasGroup(src, groups[x]) then
                return true
            end
        end

        return false
    end,

    addCash = function(src, amount)
        -- Renewed:addMoney(src, amount, 'cash', 'NPC Robbery')  -- qb/qbx/esx
        -- return true

        return exports.ox_inventory:AddItem(src, 'money', amount)
    end,

    addItem = function(src, item, amount)
        -- local player = Renewed:getPlayer(src)
        -- player.Functions.AddItem(item, amount)  -- qb/qbx
        -- return true

        return exports.ox_inventory:AddItem(src, item, amount)
    end
}
