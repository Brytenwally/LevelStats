local Config = {
    MinAmount = 1,
    MaxAmount = 5,
    Stats = {
        [0] = { name = "Strength",  db = "str", spellId = 7464, color = "ff0000" }, 
        [1] = { name = "Agility",   db = "agi", spellId = 7471, color = "00ff00" }, 
        [2] = { name = "Stamina",   db = "sta", spellId = 7477, color = "ffffff" }, 
        [3] = { name = "Intellect", db = "int", spellId = 7468, color = "00ccff" }, 
        [4] = { name = "Spirit",    db = "spi", spellId = 7474, color = "ffcc00" }, 
    }
}

local function SyncStatsFromDB(player)
    if not player then return end
    local guid = player:GetGUIDLow()
    local Q = CharDBQuery(string.format("SELECT str, agi, sta, `int`, spi FROM custom_level_stats WHERE guid = %d", guid))
    
    if Q then
        for i = 0, 4 do
            local count = Q:GetUInt32(i)
            if count > 0 then
                player:RemoveAura(Config.Stats[i].spellId)
                player:AddAura(Config.Stats[i].spellId, player)
                local aura = player:GetAura(Config.Stats[i].spellId)
                if aura then
                    aura:SetStackAmount(count)
                end
            end
        end
    end
end

local function OnLevelChange(event, player, oldLevel)
    if not player then return end

    -- [[ THE FIX: PREVENT DOUBLE ROLL ]] --
    local currentLevel = player:GetLevel()
    local lastProcessedLevel = player:GetData("LastLevelBonus")

    -- Only proceed if we haven't already processed this specific level
    if (lastProcessedLevel == currentLevel) then
        return 
    end
    player:SetData("LastLevelBonus", currentLevel)

    -- Proceed with the roll
    local statID = math.random(0, 4)
    local amount = math.random(Config.MinAmount, Config.MaxAmount)
    local statData = Config.Stats[statID]
    local guid = player:GetGUIDLow()

    -- 1. Update Database
    local query = string.format("INSERT INTO custom_level_stats (guid, `%s`) VALUES (%d, %d) ON DUPLICATE KEY UPDATE `%s` = `%s` + %d", 
        statData.db, guid, amount, statData.db, statData.db, amount)
    CharDBExecute(query)

    -- 2. Delayed Sync (500ms)
    player:RegisterEvent(function(eventId, delay, calls, player)
        SyncStatsFromDB(player)
        player:SendAreaTriggerMessage("Level Up Bonus: +" .. amount .. " " .. statData.name .. "!")
        player:SendBroadcastMessage(string.format("|cff00ff00[Level Bonus]:|r Gained |cff%s+%d %s|r.", statData.color, amount, statData.name))
    end, 500, 1)
end

local function OnLogin(event, player)
    -- On login, set the current level to prevent a "bonus" if they log in mid-leveling
    player:SetData("LastLevelBonus", player:GetLevel())
    
    player:RegisterEvent(function(eventId, delay, calls, player)
        SyncStatsFromDB(player)
    end, 1200, 1)
end

local function OnCommand(event, player, code)
    -- This hook triggers specifically when someone types a dot (.) command
    if (code:lower() == "bonus") then
        local guid = player:GetGUIDLow()
        local Q = CharDBQuery(string.format("SELECT str, agi, sta, `int`, spi FROM custom_level_stats WHERE guid = %d", guid))
        
        player:SendBroadcastMessage("|cffFFFF00--- Total Level Up Bonuses ---|r")
        
        if Q then
            for i = 0, 4 do
                local statTotal = Q:GetUInt32(i)
                player:SendBroadcastMessage(string.format("|cff%s%s:|r +%d", Config.Stats[i].color, Config.Stats[i].name, statTotal))
            end
        else
            player:SendBroadcastMessage("No bonuses found.")
        end

        -- Returning false tells the core: "This command is handled, don't say 'Command doesn't exist'"
        return false
    end
end

-- Hook for .commands (Event 42)
RegisterPlayerEvent(42, OnCommand) 

-- Keep the old chat hook as a backup for !bonus or just bonus
local function OnChat(event, player, message, type, lang)
    if (message:lower() == "!bonus" or message:lower() == "bonus") then
        OnCommand(42, player, "bonus")
        return false
    end
end
RegisterPlayerEvent(18, OnChat)
RegisterPlayerEvent(3, OnLogin)       
RegisterPlayerEvent(13, OnLevelChange) 
