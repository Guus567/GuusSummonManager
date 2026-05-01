GuusSummonManager = GuusSummonManager or {}
GuusSummonManager_Config = GuusSummonManager_Config or {}

-- Configuration
local config = {
    Debug = false,
    WindowWidth = 450,
    WindowHeight = 570,
    ButtonHeight = 30,
    ButtonWidth = 100,
    InputWidth = 200,
}

-- Declare variables for later initialization
local LDB, DBIcon, GSMLDB

local function ShowGSMWindow()
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] ShowGSMWindow called")
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] gui exists: " .. tostring(gui ~= nil))
        
        if gui then
            DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] gui:IsShown(): " .. tostring(gui:IsShown()))
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] GuusSummonManager.CreateGUI exists: " .. tostring(GuusSummonManager.CreateGUI ~= nil))
    end
    
    if gui and gui:IsShown() then
        gui:Hide()
        if config.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Window hidden")
        end
    else
        if gui then
            if config.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Showing existing GUI")
            end
            gui:Show()
        else
            if config.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] GUI doesn't exist, trying to create")
            end
            if GuusSummonManager.CreateGUI then
                if config.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Calling CreateGUI")
                end
                GuusSummonManager.CreateGUI()
            else
                if config.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] CreateGUI function not available, will retry")
                end
                -- Retry in next frame
                local retryFrame = CreateFrame("Frame")
                retryFrame:SetScript("OnUpdate", function()
                    if GuusSummonManager.CreateGUI then
                        GuusSummonManager.CreateGUI()
                    end
                    retryFrame:SetScript("OnUpdate", nil)
                end)
            end
        end
    end
end

-- Simple initialization with timer (more reliable for vanilla WoW)
local function InitializeMinimapIcon()
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] InitializeMinimapIcon called")
    end
    
    if not LibStub then
        if config.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] LibStub not available, retrying...")
        end
        return false
    end
    
    -- Load libraries
    local success = pcall(function()
        LDB = LibStub("LibDataBroker-1.1", true)
        DBIcon = LibStub("LibDBIcon-1.0", true)
    end)
    
    if not success then
        if config.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Library loading failed, retrying...")
        end
        return false
    end
    
    -- Create LDB object
    if LDB then
        local success2 = pcall(function()
            GSMLDB = LDB:NewDataObject("GuusSummonManager", {
                type = "launcher",
                text = "GSM",
                icon = "Interface\\GROUPFRAME\\UI-Group-LeaderIcon",
                OnClick = function(self, button)
                    if button == "RightButton" then
                        if config.Debug then
                            DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Right-click detected")
                        end
                    else
                        -- Toggle window or open via slash command
                        if gui and gui:IsShown() then
                            gui:Hide()
                        else
                            if SlashCmdList and SlashCmdList["GuusSummonManager"] then
                                SlashCmdList["GuusSummonManager"]("")
                            end
                        end
                    end
                end,
                OnTooltipShow = function(tooltip)
                    if tooltip and tooltip.AddLine then
                        tooltip:AddLine("Guus Summon Manager")
                        tooltip:AddLine("Click to open/close the window.")
                    end
                end
            })
        end)
        
        if success2 and GSMLDB then
            if config.Debug then
                DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] LDB object created successfully")
            end
            
            -- Register with DBIcon
            if DBIcon then
                local iconSuccess = pcall(function()
                    if GuusSummonManager_Config.minimap == nil then
                        GuusSummonManager_Config.minimap = { 
                            hide = false,
                            minimapPos = 220,
                            radius = 80 
                        }
                    end
                    
                    DBIcon:Register("GuusSummonManager", GSMLDB, GuusSummonManager_Config.minimap)
                    DBIcon:Show("GuusSummonManager")
                end)
                
                if not iconSuccess and config.Debug then
                    DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] DBIcon registration failed")
                end
            end
            
            return true
        end
    end
    
    return false
end

-- Try initialization with retries
local initAttempts = 0
local function TryInitialization()
    initAttempts = initAttempts + 1
    
    if InitializeMinimapIcon() then
        if config.Debug then
            DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Minimap icon initialized successfully")
        end
        return
    end
    
    if initAttempts < 5 then
        -- Retry in 2 seconds using a frame-based delay
        local retryFrame = CreateFrame("Frame")
        local elapsed = 0
        retryFrame:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= 2 then
                TryInitialization()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- Initialize configuration after saved variables are loaded
local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("VARIABLES_LOADED")
configFrame:SetScript("OnEvent", function()
    -- Ensure the config table exists
    if not GuusSummonManager_Config then
        GuusSummonManager_Config = {}
    end
    
    -- Ensure minimap config exists with proper default
    if not GuusSummonManager_Config.minimap then
        GuusSummonManager_Config.minimap = { 
            hide = false,
            minimapPos = 220,
            radius = 80 
        }
    end
    
    -- Initialize character list if needed
    if not GuusSummonManager_Config.characterList then
        GuusSummonManager_Config.characterList = {}
    end
    
    -- Load saved configuration
    if GuusSummonManager_Config.Debug ~= nil then
        config.Debug = GuusSummonManager_Config.Debug
    end
    if GuusSummonManager_Config.warlockName ~= nil then
        config.warlockName = GuusSummonManager_Config.warlockName
    else
        config.warlockName = ""
    end
    if GuusSummonManager_Config.level60Name ~= nil then
        config.level60Name = GuusSummonManager_Config.level60Name
    else
        config.level60Name = ""
    end
    
    -- Now initialize minimap icon
    TryInitialization()
    
    -- Unregister this event
    configFrame:UnregisterEvent("VARIABLES_LOADED")
end)

-- Namespace for GuusSummonManager GUI
local gui = nil
GuusSummonManager.removeFrame = nil
GuusSummonManager.useFrame = nil
GuusSummonManager.teleportFrame = nil
local characterListButtons = {}
local level60ListButtons = {}
local warlockListButtons = {}
local warlockNameEdit = nil
local addL60Edit = nil
local addWarlockEdit = nil
local addCharEdit = nil
local useActionBtn = nil
local charListLabel = nil
local warlockListLabel = nil
local RefreshCharacterList
local RefreshLevel60List
local RefreshWarlockList

-- Function to execute transporter commands
local function ExecuteTransporterCommand(command, param)
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Executing command: " .. command .. " " .. (param or ""))
    end
    
    if command == "spawn" and param and param ~= "" then
        -- Try both mdps and rdps roles - one should work
        local spawnCmd1 = ".z addlegacy \"" .. param .. "\" mdps"
        local spawnCmd2 = ".z addlegacy \"" .. param .. "\" rdps"
        SendChatMessage(spawnCmd1, "SAY")
        SendChatMessage(spawnCmd2, "SAY")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Spawning: " .. param .. " (trying both mdps and rdps roles)")
    elseif command == "uninvite" and param and param ~= "" then
        -- Execute the /uninvite command directly on the invited character (no suffix)
        SlashCmdList["UNINVITE"](param)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Uninviting: " .. param)
    elseif command == "remove-warlock" and param and param ~= "" then
        -- Remove warlock (legacy character with -lite suffix)
        local truncatedName = string.sub(param, 1, 7)
        local targetName = truncatedName .. "-lite"
        
        -- First set target
        if SlashCmdList["TARGET"] then
            SlashCmdList["TARGET"](targetName)
        end
        
        -- Wait multiple frames for target to be set, then send remove
        if GuusSummonManager.removeFrame then
            GuusSummonManager.removeFrame:SetScript("OnUpdate", nil)
        end
        
        GuusSummonManager.removeFrame = CreateFrame("Frame")
        GuusSummonManager.removeFrame.frameCount = 0
        GuusSummonManager.removeFrame.executed = false
        
        GuusSummonManager.removeFrame:SetScript("OnUpdate", function()
            if GuusSummonManager.removeFrame and not GuusSummonManager.removeFrame.executed then
                GuusSummonManager.removeFrame.frameCount = GuusSummonManager.removeFrame.frameCount + 1
                -- Wait 10 frames to ensure target is set
                if GuusSummonManager.removeFrame.frameCount >= 10 then
                    SendChatMessage(".z remove", "SAY")
                    GuusSummonManager.removeFrame.executed = true
                    GuusSummonManager.removeFrame:SetScript("OnUpdate", nil)
                end
            end
        end)
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Removing: " .. param)
    elseif command == "use" then
        if GuusSummonManager_Config.characterList and table.getn(GuusSummonManager_Config.characterList) > 0 then
            -- Use frame-based delay to ensure reliable execution
            if GuusSummonManager.useFrame then
                GuusSummonManager.useFrame:SetScript("OnUpdate", nil)
            end
            
            GuusSummonManager.useFrame = CreateFrame("Frame")
            GuusSummonManager.useFrame.frameCount = 0
            GuusSummonManager.useFrame.executed = false
            
            GuusSummonManager.useFrame:SetScript("OnUpdate", function()
                if GuusSummonManager.useFrame and not GuusSummonManager.useFrame.executed then
                    GuusSummonManager.useFrame.frameCount = GuusSummonManager.useFrame.frameCount + 1
                    -- Wait 10 frames to clear target
                    if GuusSummonManager.useFrame.frameCount == 10 then
                        -- Clear target first
                        ClearTarget()
                    -- Wait additional 10 frames (total 20) before sending command
                    elseif GuusSummonManager.useFrame.frameCount >= 20 then
                        -- Build list of truncated warlock names to exclude
                        local truncatedWarlockNames = {}
                        if GuusSummonManager_Config and GuusSummonManager_Config.warlockList then
                            for i, warlockName in ipairs(GuusSummonManager_Config.warlockList) do
                                if warlockName and warlockName ~= "" then
                                    truncatedWarlockNames[string.sub(warlockName, 1, 7) .. "-lite"] = true
                                end
                            end
                        end
                        
                        local charCount = 0
                        if GuusSummonManager_Config and GuusSummonManager_Config.characterList and type(GuusSummonManager_Config.characterList) == "table" then
                            for i, charEntry in ipairs(GuusSummonManager_Config.characterList) do
                                local charName
                                if type(charEntry) == "string" then
                                    charName = charEntry
                                elseif type(charEntry) == "table" then
                                    charName = charEntry.name
                                end
                                
                                if charName then
                                    local truncatedCharName = string.sub(charName, 1, 7) .. "-lite"
                                    if not truncatedWarlockNames[truncatedCharName] then
                                        SendChatMessage(".z use", "SAY")
                                        charCount = charCount + 1
                                    end
                                end
                            end
                        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Use portal sent to " .. charCount .. " characters")
                        GuusSummonManager.useFrame.executed = true
                        GuusSummonManager.useFrame:SetScript("OnUpdate", nil)
                    end
                end
            end)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r No characters in list!")
        end
    elseif command == "invite" and param and param ~= "" then
        -- Execute the /inv command directly
        SlashCmdList["INVITE"](param)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Inviting: " .. param)
    end
end

-- Function to add character to saved list
local function AddCharacterToList(characterName)
    -- Trim whitespace from the name
    characterName = string.gsub(characterName, "^%s+", "")
    characterName = string.gsub(characterName, "%s+$", "")
    
    if not characterName or characterName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Character name cannot be empty!")
        return false
    end
    
    if not GuusSummonManager_Config.characterList then
        GuusSummonManager_Config.characterList = {}
    end
    
    -- Get current player's level
    local playerLevel = UnitLevel("player")
    if not playerLevel or playerLevel == 0 then
        playerLevel = 1
    end
    
    -- Check if already exists
    for i, charEntry in ipairs(GuusSummonManager_Config.characterList) do
        local existingName
        if type(charEntry) == "string" then
            existingName = charEntry
        elseif type(charEntry) == "table" then
            existingName = charEntry.name
        end
        
        if existingName == characterName then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r " .. characterName .. " already in list!")
            return false
        end
    end
    
    -- Store character with level info
    table.insert(GuusSummonManager_Config.characterList, {
        name = characterName,
        level = playerLevel
    })
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Added " .. characterName .. " (Level " .. playerLevel .. ") to character list")
    
    if RefreshCharacterList then
        RefreshCharacterList()
    end
    
    return true
end

-- Function to remove character from saved list
local function RemoveCharacterFromList(characterName)
    if not GuusSummonManager_Config.characterList then
        return false
    end
    
    for i, charEntry in ipairs(GuusSummonManager_Config.characterList) do
        local entryName
        if type(charEntry) == "string" then
            entryName = charEntry
        elseif type(charEntry) == "table" then
            entryName = charEntry.name
        end
        
        if entryName == characterName then
            table.remove(GuusSummonManager_Config.characterList, i)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Removed " .. characterName .. " from character list")
            
            if RefreshCharacterList then
                RefreshCharacterList()
            end
            return true
        end
    end
    
    return false
end

-- Function to set warlock name
local function SetWarlockName(warlockName)
    -- Trim whitespace from the name
    warlockName = string.gsub(warlockName, "^%s+", "")
    warlockName = string.gsub(warlockName, "%s+$", "")
    
    if not warlockName or warlockName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Warlock name cannot be empty!")
        return false
    end
    
    config.warlockName = warlockName
    GuusSummonManager_Config.warlockName = warlockName
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Warlock name set to: " .. warlockName)
    
    return true
end

-- Function to set level 60 character name
local function SetLevel60Name(level60Name)
    -- Trim whitespace from the name
    level60Name = string.gsub(level60Name, "^%s+", "")
    level60Name = string.gsub(level60Name, "%s+$", "")
    
    if not level60Name or level60Name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Level 60 character name cannot be empty!")
        return false
    end
    
    config.level60Name = level60Name
    GuusSummonManager_Config.level60Name = level60Name
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Level 60 character set to: " .. level60Name)
    
    return true
end

-- Function to add level 60 character to list
local function AddLevel60ToList(characterName)
    -- Trim whitespace from the name
    characterName = string.gsub(characterName, "^%s+", "")
    characterName = string.gsub(characterName, "%s+$", "")
    
    if not characterName or characterName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Character name cannot be empty!")
        return false
    end
    
    if not GuusSummonManager_Config.level60List then
        GuusSummonManager_Config.level60List = {}
    end
    
    -- Check if already exists
    for i, charName in ipairs(GuusSummonManager_Config.level60List) do
        if charName == characterName then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r " .. characterName .. " already in level 60 list!")
            return false
        end
    end
    
    -- Add to list
    table.insert(GuusSummonManager_Config.level60List, characterName)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Added " .. characterName .. " to level 60 list")
    
    if RefreshLevel60List then
        RefreshLevel60List()
    end
    
    return true
end

-- Function to remove level 60 character from list
local function RemoveLevel60FromList(characterName)
    if not GuusSummonManager_Config.level60List then
        return false
    end
    
    for i, charName in ipairs(GuusSummonManager_Config.level60List) do
        if charName == characterName then
            table.remove(GuusSummonManager_Config.level60List, i)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Removed " .. characterName .. " from level 60 list")
            
            if RefreshLevel60List then
                RefreshLevel60List()
            end
            return true
        end
    end
    
    return false
end

-- Function to add warlock to list
local function AddWarlockToList(warlockName)
    -- Trim whitespace from the name
    warlockName = string.gsub(warlockName, "^%s+", "")
    warlockName = string.gsub(warlockName, "%s+$", "")
    
    if not warlockName or warlockName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Warlock name cannot be empty!")
        return false
    end
    
    if not GuusSummonManager_Config.warlockList then
        GuusSummonManager_Config.warlockList = {}
    end
    
    -- Check if already exists
    for i, charName in ipairs(GuusSummonManager_Config.warlockList) do
        if charName == warlockName then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r " .. warlockName .. " already in warlock list!")
            return false
        end
    end
    
    -- Add to list
    table.insert(GuusSummonManager_Config.warlockList, warlockName)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Added " .. warlockName .. " to warlock list")
    
    if RefreshWarlockList then
        RefreshWarlockList()
    end
    return true
end

-- Function to remove warlock from list
local function RemoveWarlockFromList(warlockName)
    if not GuusSummonManager_Config.warlockList then
        return false
    end
    
    for i, charName in ipairs(GuusSummonManager_Config.warlockList) do
        if charName == warlockName then
            table.remove(GuusSummonManager_Config.warlockList, i)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Removed " .. warlockName .. " from warlock list")
            
            if RefreshWarlockList then
                RefreshWarlockList()
            end
            return true
        end
    end
    
    return false
end

-- Function to get all warlock names from list
local function GetAllWarlockNames()
    if not GuusSummonManager_Config then
        GuusSummonManager_Config = {}
    end
    if not GuusSummonManager_Config.warlockList then
        GuusSummonManager_Config.warlockList = {}
    end
    return GuusSummonManager_Config.warlockList or {}
end

-- Function to get first warlock from list
local function GetFirstWarlockName()
    if not GuusSummonManager_Config then
        GuusSummonManager_Config = {}
    end
    if not GuusSummonManager_Config.warlockList then
        GuusSummonManager_Config.warlockList = {}
    end
    if table.getn(GuusSummonManager_Config.warlockList) == 0 then
        return nil
    end
    return GuusSummonManager_Config.warlockList[1]
end

-- Function to get first level 60 character from list or fallback
local function GetFirstLevel60Character()
    -- First check if we have a manually set level 60 character
    if config.level60Name and config.level60Name ~= "" then
        return config.level60Name
    end
    
    -- Check level 60 list
    if GuusSummonManager_Config.level60List and table.getn(GuusSummonManager_Config.level60List) > 0 then
        return GuusSummonManager_Config.level60List[1]
    end
    
    -- Fall back to searching through character list for first level 60
    if not GuusSummonManager_Config.characterList or table.getn(GuusSummonManager_Config.characterList) == 0 then
        return nil
    end
    
    for i, charData in ipairs(GuusSummonManager_Config.characterList) do
        -- Handle both old format (just name string) and new format (table with level)
        local charName
        local charLevel = 0
        
        if type(charData) == "string" then
            charName = charData
        elseif type(charData) == "table" then
            charName = charData.name
            charLevel = charData.level or 0
        end
        
        if charLevel == 60 then
            return charName
        end
    end
    
    return nil
end

-- Function to refresh character list display
RefreshCharacterList = function()
    if not gui or not gui:IsVisible() then
        return
    end
    
    -- Clear existing buttons
    for i, button in ipairs(characterListButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    characterListButtons = {}
    
    if not GuusSummonManager_Config.characterList then
        GuusSummonManager_Config.characterList = {}
    end
    
    -- Create buttons for each character
    local isFirstChar = true
    local prevCharNameFrame = nil
    for i, charEntry in ipairs(GuusSummonManager_Config.characterList) do
        -- Extract character name and level from entry
        local characterName
        local characterLevel = 0
        
        if type(charEntry) == "string" then
            characterName = charEntry
        elseif type(charEntry) == "table" then
            characterName = charEntry.name
            characterLevel = charEntry.level or 0
        end
        
        if characterName then
            -- Character name label (with level info)
            local nameFrame = CreateFrame("Frame", "GSMCharName" .. i, gui)
            nameFrame:SetWidth(180)
            nameFrame:SetHeight(config.ButtonHeight)
            
            -- Anchor first character to addCharEdit (the input field), subsequent to previous nameFrame
            if isFirstChar then
                -- Position below the input field with 10px spacing (matches Level 60 list)
                nameFrame:SetPoint("TOPLEFT", addCharEdit, "BOTTOMLEFT", 0, -10)
                isFirstChar = false
            else
                nameFrame:SetPoint("TOPLEFT", prevCharNameFrame, "BOTTOMLEFT", 0, -5)
            end
            
            prevCharNameFrame = nameFrame
            
            nameFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            nameFrame:SetBackdropColor(0.2, 0.2, 0.3, 0.9)
            nameFrame:SetBackdropBorderColor(0.5, 0.5, 0.7, 0.9)
            
            local nameText = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", nameFrame, "LEFT", 8, 0)
            nameText:SetText(characterName)
            nameText:SetTextColor(0.8, 0.8, 1.0)
            
            table.insert(characterListButtons, nameFrame)
            
            -- Invite button
            local inviteBtn = CreateFrame("Button", "GSMInviteBtn" .. i, gui)
            inviteBtn:SetWidth(50)
            inviteBtn:SetHeight(config.ButtonHeight)
            inviteBtn:SetPoint("TOPLEFT", nameFrame, "TOPRIGHT", 10, 0)
            
            inviteBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            inviteBtn:SetBackdropColor(0.2, 0.5, 0.2, 0.8)
            inviteBtn:SetBackdropBorderColor(0.3, 0.8, 0.3, 0.8)
            
            inviteBtn:SetScript("OnEnter", function()
                inviteBtn:SetBackdropColor(0.3, 0.7, 0.3, 0.9)
            end)
            inviteBtn:SetScript("OnLeave", function()
                inviteBtn:SetBackdropColor(0.2, 0.5, 0.2, 0.8)
            end)
            
            local inviteText = inviteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            inviteText:SetPoint("CENTER", inviteBtn, "CENTER", 0, 0)
            inviteText:SetText("Invite")
            inviteText:SetTextColor(0.3, 1.0, 0.3)
            
            local charNameClosure = characterName
            inviteBtn:SetScript("OnClick", function()
                ExecuteTransporterCommand("invite", charNameClosure)
            end)
            
            table.insert(characterListButtons, inviteBtn)
            
            -- Uninvite button
            local uninviteBtn = CreateFrame("Button", "GSMUninviteBtn" .. i, gui)
            uninviteBtn:SetWidth(55)
            uninviteBtn:SetHeight(config.ButtonHeight)
            uninviteBtn:SetPoint("TOPLEFT", inviteBtn, "TOPRIGHT", 5, 0)
            
            uninviteBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            uninviteBtn:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
            uninviteBtn:SetBackdropBorderColor(0.7, 0.3, 0.3, 0.8)
            
            uninviteBtn:SetScript("OnEnter", function()
                uninviteBtn:SetBackdropColor(0.6, 0.3, 0.3, 0.9)
            end)
            uninviteBtn:SetScript("OnLeave", function()
                uninviteBtn:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
            end)
            
            local uninviteText = uninviteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            uninviteText:SetPoint("CENTER", uninviteBtn, "CENTER", 0, 0)
            uninviteText:SetText("Uninvite")
            uninviteText:SetTextColor(1.0, 0.5, 0.5)
            
            uninviteBtn:SetScript("OnClick", function()
                ExecuteTransporterCommand("uninvite", charNameClosure)
            end)
            
            table.insert(characterListButtons, uninviteBtn)
            
            -- Teleport button
            local teleportBtn = CreateFrame("Button", "GSMTeleportBtn" .. i, gui)
            teleportBtn:SetWidth(55)
            teleportBtn:SetHeight(config.ButtonHeight)
            teleportBtn:SetPoint("TOPLEFT", uninviteBtn, "TOPRIGHT", 5, 0)
            
            teleportBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            teleportBtn:SetBackdropColor(0.2, 0.3, 0.5, 0.8)
            teleportBtn:SetBackdropBorderColor(0.3, 0.5, 0.8, 0.8)
            
            teleportBtn:SetScript("OnEnter", function()
                teleportBtn:SetBackdropColor(0.3, 0.5, 0.7, 0.9)
            end)
            teleportBtn:SetScript("OnLeave", function()
                teleportBtn:SetBackdropColor(0.2, 0.3, 0.5, 0.8)
            end)
            
            local teleportText = teleportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            teleportText:SetPoint("CENTER", teleportBtn, "CENTER", 0, 0)
            teleportText:SetText("Teleport")
            teleportText:SetTextColor(0.5, 0.7, 1.0)
            
            teleportBtn:SetScript("OnClick", function()
                local warlockName = GetFirstWarlockName()
                local charName = charNameClosure
                
                if not warlockName or warlockName == "" then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r No warlocks in list!")
                    return
                end
                
                -- Target the character immediately
                if SlashCmdList["TARGET"] then
                    SlashCmdList["TARGET"](charName)
                end
                
                -- Use frame-based delay to send summon command reliably
                if GuusSummonManager.teleportFrame then
                    GuusSummonManager.teleportFrame:SetScript("OnUpdate", nil)
                end
                
                GuusSummonManager.teleportFrame = CreateFrame("Frame")
                GuusSummonManager.teleportFrame.frameCount = 0
                GuusSummonManager.teleportFrame.executed = false
                GuusSummonManager.teleportFrame.charName = charName
                GuusSummonManager.teleportFrame.warlockName = warlockName
                
                GuusSummonManager.teleportFrame:SetScript("OnUpdate", function()
                    if GuusSummonManager.teleportFrame and not GuusSummonManager.teleportFrame.executed then
                        GuusSummonManager.teleportFrame.frameCount = GuusSummonManager.teleportFrame.frameCount + 1
                        -- Wait 10 frames to ensure target is set
                        if GuusSummonManager.teleportFrame.frameCount >= 10 then
                            local wName = GuusSummonManager.teleportFrame.warlockName
                            local cName = GuusSummonManager.teleportFrame.charName
                            if wName and wName ~= "" then
                                -- Truncate warlock name to 7 chars and add -lite suffix
                                local truncatedWarlockName = string.sub(wName, 1, 7) .. "-lite"
                                SendChatMessage("cast Ritual of Summoning", "WHISPER", nil, truncatedWarlockName)
                                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Summoning " .. cName .. " via " .. wName)
                            end
                            GuusSummonManager.teleportFrame.executed = true
                            GuusSummonManager.teleportFrame:SetScript("OnUpdate", nil)
                        end
                    end
                end)
            end)
            
            table.insert(characterListButtons, teleportBtn)
            
            -- Remove button
            local removeBtn = CreateFrame("Button", "GSMRemoveBtn" .. i, gui)
            removeBtn:SetWidth(50)
            removeBtn:SetHeight(config.ButtonHeight)
            removeBtn:SetPoint("TOPLEFT", teleportBtn, "TOPRIGHT", 5, 0)
            
            removeBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            removeBtn:SetBackdropColor(0.5, 0.2, 0.2, 0.8)
            removeBtn:SetBackdropBorderColor(0.8, 0.3, 0.3, 0.8)
            
            removeBtn:SetScript("OnEnter", function()
                removeBtn:SetBackdropColor(0.7, 0.3, 0.3, 0.9)
            end)
            removeBtn:SetScript("OnLeave", function()
                removeBtn:SetBackdropColor(0.5, 0.2, 0.2, 0.8)
            end)
            
            local removeText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            removeText:SetPoint("CENTER", removeBtn, "CENTER", 0, 0)
            removeText:SetText("Remove")
            removeText:SetTextColor(1.0, 0.3, 0.3)
            
            removeBtn:SetScript("OnClick", function()
                RemoveCharacterFromList(charNameClosure)
            end)
            
            table.insert(characterListButtons, removeBtn)
        end
    end
end

-- Function to refresh warlock list display
RefreshWarlockList = function()
    if not gui or not gui:IsVisible() then
        return
    end
    
    -- Clear existing buttons
    for i, button in ipairs(warlockListButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    warlockListButtons = {}
    
    if not GuusSummonManager_Config.warlockList then
        GuusSummonManager_Config.warlockList = {}
    end
    
    -- Create buttons for each warlock
    local isFirstItem = true
    local prevNameFrame = nil
    local lastNameFrame = nil
    for i, warlockName in ipairs(GuusSummonManager_Config.warlockList) do
        if warlockName then
            -- Warlock name label
            local nameFrame = CreateFrame("Frame", "GSMWarlockName" .. i, gui)
            nameFrame:SetWidth(140)
            nameFrame:SetHeight(config.ButtonHeight)
            
            -- Anchor first item to addWarlockEdit, subsequent items to previous nameFrame
            if isFirstItem then
                nameFrame:SetPoint("TOPLEFT", addWarlockEdit, "BOTTOMLEFT", 0, -10)
                isFirstItem = false
            else
                nameFrame:SetPoint("TOPLEFT", prevNameFrame, "BOTTOMLEFT", 0, -5)
            end
            
            prevNameFrame = nameFrame
            lastNameFrame = nameFrame
            
            nameFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            nameFrame:SetBackdropColor(0.3, 0.2, 0.2, 0.9)
            nameFrame:SetBackdropBorderColor(0.7, 0.3, 0.3, 0.9)
            
            local nameText = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", nameFrame, "LEFT", 8, 0)
            nameText:SetText(warlockName .. " (Lv60)")
            nameText:SetTextColor(1.0, 0.5, 0.5)
            
            table.insert(warlockListButtons, nameFrame)
            
            -- Spawn button (green)
            local spawnBtn = CreateFrame("Button", "GSMSpawnWarlockBtn" .. i, gui)
            spawnBtn:SetWidth(50)
            spawnBtn:SetHeight(config.ButtonHeight)
            spawnBtn:SetPoint("TOPLEFT", nameFrame, "TOPRIGHT", 5, 0)
            
            spawnBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            spawnBtn:SetBackdropColor(0.2, 0.5, 0.2, 0.8)
            spawnBtn:SetBackdropBorderColor(0.3, 0.8, 0.3, 0.8)
            
            spawnBtn:SetScript("OnEnter", function()
                spawnBtn:SetBackdropColor(0.3, 0.7, 0.3, 0.9)
            end)
            spawnBtn:SetScript("OnLeave", function()
                spawnBtn:SetBackdropColor(0.2, 0.5, 0.2, 0.8)
            end)
            
            local spawnText = spawnBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            spawnText:SetPoint("CENTER", spawnBtn, "CENTER", 0, 0)
            spawnText:SetText("Spawn")
            spawnText:SetTextColor(0.3, 1.0, 0.3)
            
            local warlockNameClosure = warlockName
            spawnBtn:SetScript("OnClick", function()
                ExecuteTransporterCommand("spawn", warlockNameClosure)
            end)
            
            table.insert(warlockListButtons, spawnBtn)
            
            -- Uninvite button (red)
            local uninviteBtn = CreateFrame("Button", "GSMUninviteWarlockBtn" .. i, gui)
            uninviteBtn:SetWidth(55)
            uninviteBtn:SetHeight(config.ButtonHeight)
            uninviteBtn:SetPoint("TOPLEFT", spawnBtn, "TOPRIGHT", 5, 0)
            
            uninviteBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            uninviteBtn:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
            uninviteBtn:SetBackdropBorderColor(0.7, 0.3, 0.3, 0.8)
            
            uninviteBtn:SetScript("OnEnter", function()
                uninviteBtn:SetBackdropColor(0.6, 0.3, 0.3, 0.9)
            end)
            uninviteBtn:SetScript("OnLeave", function()
                uninviteBtn:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
            end)
            
            local uninviteText = uninviteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            uninviteText:SetPoint("CENTER", uninviteBtn, "CENTER", 0, 0)
            uninviteText:SetText("Uninvite")
            uninviteText:SetTextColor(1.0, 0.5, 0.5)
            
            uninviteBtn:SetScript("OnClick", function()
                ExecuteTransporterCommand("remove-warlock", warlockNameClosure)
            end)
            
            table.insert(warlockListButtons, uninviteBtn)
            
            -- Remove button (remove from list)
            local removeBtn = CreateFrame("Button", "GSMRemoveWarlockBtn" .. i, gui)
            removeBtn:SetWidth(50)
            removeBtn:SetHeight(config.ButtonHeight)
            removeBtn:SetPoint("TOPLEFT", uninviteBtn, "TOPRIGHT", 5, 0)
            
            removeBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            removeBtn:SetBackdropColor(0.5, 0.2, 0.2, 0.8)
            removeBtn:SetBackdropBorderColor(0.8, 0.3, 0.3, 0.8)
            
            removeBtn:SetScript("OnEnter", function()
                removeBtn:SetBackdropColor(0.7, 0.3, 0.3, 0.9)
            end)
            removeBtn:SetScript("OnLeave", function()
                removeBtn:SetBackdropColor(0.5, 0.2, 0.2, 0.8)
            end)
            
            local removeText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            removeText:SetPoint("CENTER", removeBtn, "CENTER", 0, 0)
            removeText:SetText("Remove")
            removeText:SetTextColor(1.0, 0.3, 0.3)
            
            removeBtn:SetScript("OnClick", function()
                RemoveWarlockFromList(warlockNameClosure)
            end)
            
            table.insert(warlockListButtons, removeBtn)
        end
    end
    
    -- Reposition warlock list label based on whether there are warlocks
    if warlockListLabel then
        if lastNameFrame then
            -- Position below the last warlock's name frame
            warlockListLabel:SetPoint("TOPLEFT", lastNameFrame, "BOTTOMLEFT", 0, -10)
        else
            -- Position below the addWarlockEdit if no warlocks
            warlockListLabel:SetPoint("TOPLEFT", addWarlockEdit, "BOTTOMLEFT", 0, -10)
        end
    end
end

-- Function to refresh level 60 character list display
RefreshLevel60List = function()
    if not gui or not gui:IsVisible() then
        return
    end
    
    -- Clear existing buttons
    for i, button in ipairs(level60ListButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    level60ListButtons = {}
    
    if not GuusSummonManager_Config.level60List then
        GuusSummonManager_Config.level60List = {}
    end
    
    -- Create buttons for each level 60 character
    local isFirstItem = true
    local prevNameFrame = nil
    local lastNameFrame = nil
    for i, characterName in ipairs(GuusSummonManager_Config.level60List) do
        if characterName then
            -- Character name label
            local nameFrame = CreateFrame("Frame", "GSMLevel60Name" .. i, gui)
            nameFrame:SetWidth(140)
            nameFrame:SetHeight(config.ButtonHeight)
            
            -- Anchor first item to addL60Edit, subsequent items to previous nameFrame
            if isFirstItem then
                nameFrame:SetPoint("TOPLEFT", addL60Edit, "BOTTOMLEFT", 0, -10)
                isFirstItem = false
            else
                nameFrame:SetPoint("TOPLEFT", prevNameFrame, "BOTTOMLEFT", 0, -5)
            end
            
            prevNameFrame = nameFrame
            lastNameFrame = nameFrame
            
            nameFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            nameFrame:SetBackdropColor(0.2, 0.3, 0.2, 0.9)
            nameFrame:SetBackdropBorderColor(0.3, 0.7, 0.3, 0.9)
            
            local nameText = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", nameFrame, "LEFT", 8, 0)
            nameText:SetText(characterName .. " (Lv60)")
            nameText:SetTextColor(0.3, 1.0, 0.3)
            
            table.insert(level60ListButtons, nameFrame)
            
            -- Spawn button (green)
            local spawnBtn = CreateFrame("Button", "GSMSpawnL60Btn" .. i, gui)
            spawnBtn:SetWidth(50)
            spawnBtn:SetHeight(config.ButtonHeight)
            spawnBtn:SetPoint("TOPLEFT", nameFrame, "TOPRIGHT", 5, 0)
            
            spawnBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            spawnBtn:SetBackdropColor(0.2, 0.5, 0.2, 0.8)
            spawnBtn:SetBackdropBorderColor(0.3, 0.8, 0.3, 0.8)
            
            spawnBtn:SetScript("OnEnter", function()
                spawnBtn:SetBackdropColor(0.3, 0.7, 0.3, 0.9)
            end)
            spawnBtn:SetScript("OnLeave", function()
                spawnBtn:SetBackdropColor(0.2, 0.5, 0.2, 0.8)
            end)
            
            local spawnText = spawnBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            spawnText:SetPoint("CENTER", spawnBtn, "CENTER", 0, 0)
            spawnText:SetText("Spawn")
            spawnText:SetTextColor(0.3, 1.0, 0.3)
            
            local charNameClosure = characterName
            spawnBtn:SetScript("OnClick", function()
                ExecuteTransporterCommand("spawn", charNameClosure)
            end)
            
            table.insert(level60ListButtons, spawnBtn)
            
            -- Uninvite button (red) - works with -lite suffix
            local uninviteBtn = CreateFrame("Button", "GSMUninviteL60Btn" .. i, gui)
            uninviteBtn:SetWidth(55)
            uninviteBtn:SetHeight(config.ButtonHeight)
            uninviteBtn:SetPoint("TOPLEFT", spawnBtn, "TOPRIGHT", 5, 0)
            
            uninviteBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            uninviteBtn:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
            uninviteBtn:SetBackdropBorderColor(0.7, 0.3, 0.3, 0.8)
            
            uninviteBtn:SetScript("OnEnter", function()
                uninviteBtn:SetBackdropColor(0.6, 0.3, 0.3, 0.9)
            end)
            uninviteBtn:SetScript("OnLeave", function()
                uninviteBtn:SetBackdropColor(0.4, 0.2, 0.2, 0.8)
            end)
            
            local uninviteText = uninviteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            uninviteText:SetPoint("CENTER", uninviteBtn, "CENTER", 0, 0)
            uninviteText:SetText("Uninvite")
            uninviteText:SetTextColor(1.0, 0.5, 0.5)
            
            uninviteBtn:SetScript("OnClick", function()
                ExecuteTransporterCommand("remove-warlock", charNameClosure)
            end)
            
            table.insert(level60ListButtons, uninviteBtn)
            
            -- Remove button (remove from list)
            local removeBtn = CreateFrame("Button", "GSMRemoveL60Btn" .. i, gui)
            removeBtn:SetWidth(50)
            removeBtn:SetHeight(config.ButtonHeight)
            removeBtn:SetPoint("TOPLEFT", uninviteBtn, "TOPRIGHT", 5, 0)
            
            removeBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            removeBtn:SetBackdropColor(0.5, 0.2, 0.2, 0.8)
            removeBtn:SetBackdropBorderColor(0.8, 0.3, 0.3, 0.8)
            
            removeBtn:SetScript("OnEnter", function()
                removeBtn:SetBackdropColor(0.7, 0.3, 0.3, 0.9)
            end)
            removeBtn:SetScript("OnLeave", function()
                removeBtn:SetBackdropColor(0.5, 0.2, 0.2, 0.8)
            end)
            
            local removeText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            removeText:SetPoint("CENTER", removeBtn, "CENTER", 0, 0)
            removeText:SetText("Remove")
            removeText:SetTextColor(1.0, 0.3, 0.3)
            
            removeBtn:SetScript("OnClick", function()
                RemoveLevel60FromList(charNameClosure)
            end)
            
            table.insert(level60ListButtons, removeBtn)
        end
    end
    
    -- Reposition Use Portal button based on whether there are level 60 characters
    if useActionBtn then
        if lastNameFrame then
            -- Position below the last level 60 character's name frame (not the remove button)
            useActionBtn:SetPoint("TOPLEFT", lastNameFrame, "BOTTOMLEFT", 0, -10)
        else
            -- Position below the addL60Edit if no characters
            useActionBtn:SetPoint("TOPLEFT", addL60Edit, "BOTTOMLEFT", 0, -10)
        end
    end
end

-- Function to create the main GUI
local function CreateGUI()
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] CreateGUI called!")
    end
    
    if gui then
        gui:Show()
        RefreshCharacterList()
        return
    end

    -- Main frame
    gui = CreateFrame("Frame", "GuusSummonManagerGUI", UIParent)
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Main frame created: " .. tostring(gui))
    end
    
    gui:SetWidth(config.WindowWidth)
    gui:SetHeight(config.WindowHeight)
    
    -- Always center the window (position persistence has corrupted data)
    gui:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Window centered")
    end
    gui:SetMovable(true)
    gui:EnableMouse(true)

    -- Frame background
    gui:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Title bar
    local title = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", gui, "TOP", 0, -15)
    title:SetText("Guus Summon Manager")
    
    -- Close button
    local closeBtn = CreateFrame("Button", "GSMCloseBtn", gui)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetPoint("TOPRIGHT", gui, "TOPRIGHT", -5, -5)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetScript("OnClick", function() gui:Hide() end)
    
    -- Make frame draggable
    gui:SetScript("OnMouseDown", function() gui:StartMoving() end)
    gui:SetScript("OnMouseUp", function()
        gui:StopMovingOrSizing()
        -- Position persistence disabled - always center instead
    end)
    
    -- ===== WARLOCK SECTION =====
    local warlockTopLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    warlockTopLabel:SetPoint("TOPLEFT", gui, "TOPLEFT", 15, -45)
    warlockTopLabel:SetText("Warlocks:")
    
    -- Add warlock input
    local addWarlockLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addWarlockLabel:SetPoint("TOPLEFT", warlockTopLabel, "BOTTOMLEFT", 0, -10)
    addWarlockLabel:SetText("Add warlock:")
    
    addWarlockEdit = CreateFrame("EditBox", "GSMAddWarlockEdit", gui, "InputBoxTemplate")
    addWarlockEdit:SetWidth(150)
    addWarlockEdit:SetHeight(24)
    addWarlockEdit:SetPoint("TOPLEFT", addWarlockLabel, "BOTTOMLEFT", 0, -5)
    addWarlockEdit:SetAutoFocus(false)
    
    -- Add warlock button
    local addWarlockBtn = CreateFrame("Button", "GSMAddWarlockBtn", gui, "UIPanelButtonTemplate")
    addWarlockBtn:SetWidth(60)
    addWarlockBtn:SetHeight(24)
    addWarlockBtn:SetPoint("TOPLEFT", addWarlockEdit, "TOPRIGHT", 5, 0)
    addWarlockBtn:SetText("Add")
    addWarlockBtn:SetScript("OnClick", function()
        local warlockName = addWarlockEdit:GetText()
        if AddWarlockToList(warlockName) then
            addWarlockEdit:SetText("")
        end
    end)
    
    -- Warlock list label (repositioned by RefreshWarlockList)
    warlockListLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    warlockListLabel:SetPoint("TOPLEFT", addWarlockEdit, "BOTTOMLEFT", 0, -10)
    warlockListLabel:SetText("")
    
    -- ===== LEVEL 60 CHARACTER LIST SECTION =====
    local level60ListLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    level60ListLabel:SetPoint("TOPLEFT", warlockListLabel, "BOTTOMLEFT", 0, -10)
    level60ListLabel:SetText("Level 60 List:")
    
    -- Add level 60 character input
    local addL60Label = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addL60Label:SetPoint("TOPLEFT", level60ListLabel, "BOTTOMLEFT", 0, -10)
    addL60Label:SetText("Add level 60:")
    
    addL60Edit = CreateFrame("EditBox", "GSMAddL60Edit", gui, "InputBoxTemplate")
    addL60Edit:SetWidth(150)
    addL60Edit:SetHeight(24)
    addL60Edit:SetPoint("TOPLEFT", addL60Label, "BOTTOMLEFT", 0, -5)
    addL60Edit:SetAutoFocus(false)
    
    -- Add level 60 button
    local addL60Btn = CreateFrame("Button", "GSMAddL60Btn", gui, "UIPanelButtonTemplate")
    addL60Btn:SetWidth(60)
    addL60Btn:SetHeight(24)
    addL60Btn:SetPoint("TOPLEFT", addL60Edit, "TOPRIGHT", 5, 0)
    addL60Btn:SetText("Add")
    addL60Btn:SetScript("OnClick", function()
        local charName = addL60Edit:GetText()
        if AddLevel60ToList(charName) then
            addL60Edit:SetText("")
        end
    end)
    
    -- Use action button
    useActionBtn = CreateFrame("Button", "GSMUseActionBtn", gui, "UIPanelButtonTemplate")
    useActionBtn:SetWidth(100)
    useActionBtn:SetHeight(24)
    useActionBtn:SetPoint("TOPLEFT", addL60Edit, "BOTTOMLEFT", 0, -10)
    useActionBtn:SetText("Use Portal")
    useActionBtn:SetScript("OnClick", function()
        ExecuteTransporterCommand("use")
    end)
    
    -- ===== CHARACTER LIST SECTION =====
    charListLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    charListLabel:SetPoint("TOPLEFT", useActionBtn, "BOTTOMLEFT", 0, -10)
    charListLabel:SetText("Characters to Invite:")
    
    -- Add character input
    local addCharLabel = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addCharLabel:SetPoint("TOPLEFT", charListLabel, "BOTTOMLEFT", 0, -10)
    addCharLabel:SetText("Add character:")
    
    addCharEdit = CreateFrame("EditBox", "GSMAddCharEdit", gui, "InputBoxTemplate")
    addCharEdit:SetWidth(150)
    addCharEdit:SetHeight(24)
    addCharEdit:SetPoint("TOPLEFT", addCharLabel, "BOTTOMLEFT", 0, -5)
    addCharEdit:SetAutoFocus(false)
    
    -- Add character button
    local addCharBtn = CreateFrame("Button", "GSMAddCharBtn", gui, "UIPanelButtonTemplate")
    addCharBtn:SetWidth(60)
    addCharBtn:SetHeight(24)
    addCharBtn:SetPoint("TOPLEFT", addCharEdit, "TOPRIGHT", 5, 0)
    addCharBtn:SetText("Add")
    addCharBtn:SetScript("OnClick", function()
        local charName = addCharEdit:GetText()
        if AddCharacterToList(charName) then
            addCharEdit:SetText("")
        end
    end)
    
    -- NOW refresh all lists in correct order after all elements are created
    RefreshWarlockList()
    RefreshLevel60List()
    RefreshCharacterList()
    
    -- Show the frame
    gui:Show()
    
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Frame width: " .. gui:GetWidth())
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Frame height: " .. gui:GetHeight())
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Frame shown: " .. tostring(gui:IsShown()))
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Frame visible: " .. tostring(gui:IsVisible()))
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Frame left: " .. tostring(gui:GetLeft()))
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Frame top: " .. tostring(gui:GetTop()))
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] CreateGUI completed successfully!")
    end
end

-- Expose CreateGUI globally for minimap icon RIGHT HERE before anything else uses it
GuusSummonManager.CreateGUI = CreateGUI

-- Slash command handler
local function SlashCommandHandler(msg)
    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] SlashCommandHandler called with msg: " .. tostring(msg))
    end
    
    local command = string.lower(msg or "")
    local args = {}
    
    -- Parse arguments
    for arg in string.gmatch(command, "%S+") do
        table.insert(args, arg)
    end
    
    command = args[1] or ""

    if config.Debug then
        DEFAULT_CHAT_FRAME:AddMessage("[GSM DEBUG] Parsed command: '" .. command .. "'")
    end

    if command == "" or command == "show" or command == "menu" then
        -- Call local CreateGUI function directly
        CreateGUI()
        if gui then
            gui:Show()
        end
        return
    end

    if command == "list" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Saved Characters:")
        if not GuusSummonManager_Config.characterList or table.getn(GuusSummonManager_Config.characterList) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  No characters saved yet.")
        else
            local level60Found = false
            for i, charEntry in ipairs(GuusSummonManager_Config.characterList) do
                local charName
                local charLevel = 0
                
                if type(charEntry) == "string" then
                    charName = charEntry
                    charLevel = 0
                elseif type(charEntry) == "table" then
                    charName = charEntry.name
                    charLevel = charEntry.level or 0
                end
                
                if charLevel == 60 then
                    level60Found = true
                end
                
                DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. charName .. " (Level " .. charLevel .. ")")
            end
            if level60Found then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00 ✓ Level 60 available for spawning|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000 Note: Add characters while logged into them to capture their actual level|r")
            end
        end
        
        -- Display Warlock List
        if not GuusSummonManager_Config.warlockList or table.getn(GuusSummonManager_Config.warlockList) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Warlocks:|r None")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Warlocks:|r")
            for i, warlockName in ipairs(GuusSummonManager_Config.warlockList) do
                DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. warlockName)
            end
        end
        
        -- Display Level 60 List
        if not GuusSummonManager_Config.level60List or table.getn(GuusSummonManager_Config.level60List) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Level 60 List:|r None")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Level 60 List:|r")
            for i, charName in ipairs(GuusSummonManager_Config.level60List) do
                DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. charName)
            end
        end
    elseif command == "setlevel" and args[2] and args[3] then
        local charName = args[2]
        local newLevel = tonumber(args[3])
        
        if not newLevel or newLevel < 1 or newLevel > 60 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Level must be between 1 and 60!")
            return
        end
        
        if not GuusSummonManager_Config.characterList then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Character not found in list!")
            return
        end
        
        local found = false
        for i, charEntry in ipairs(GuusSummonManager_Config.characterList) do
            local entryName
            if type(charEntry) == "string" then
                entryName = charEntry
            elseif type(charEntry) == "table" then
                entryName = charEntry.name
            end
            
            if entryName == charName then
                -- Convert to table format if needed
                if type(charEntry) == "string" then
                    GuusSummonManager_Config.characterList[i] = {
                        name = charName,
                        level = newLevel
                    }
                else
                    GuusSummonManager_Config.characterList[i].level = newLevel
                end
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r " .. charName .. " level set to " .. newLevel)
                found = true
                if RefreshCharacterList then
                    RefreshCharacterList()
                end
                break
            end
        end
        
        if not found then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000GuusSummonManager:|r Character '" .. charName .. "' not found in list!")
        end
    elseif command == "set60" and args[2] then
        local charName = table.concat(args, " ", 2)  -- Join remaining args in case of spaces
        SetLevel60Name(charName)
    elseif command == "debug" then
        config.Debug = not config.Debug
        if GuusSummonManager_Config then
            GuusSummonManager_Config.Debug = config.Debug
        end
        local status = config.Debug and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager:|r Debug mode " .. status)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00GuusSummonManager Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /gsm or /summon - Open main window")
        DEFAULT_CHAT_FRAME:AddMessage("  /gsm list - Show all saved characters and warlock name")
        DEFAULT_CHAT_FRAME:AddMessage("  /gsm set60 <charname> - Set level 60 character")
        DEFAULT_CHAT_FRAME:AddMessage("  /gsm setlevel <charname> <level> - Set character level (1-60)")
        DEFAULT_CHAT_FRAME:AddMessage("  /gsm debug - Toggle debug mode")
    end
end

-- Register slash commands at the very end, after all functions are defined
SLASH_GuusSummonManager1 = "/gsm"
SLASH_GuusSummonManager2 = "/summon"
SlashCmdList["GuusSummonManager"] = SlashCommandHandler

-- Add reload UI commands
SLASH_RELOADUI1 = "/rl"
SLASH_RELOADUI2 = "/reload"
SLASH_RELOADUI3 = "/reloadui"
SLASH_RELOADUI4 = "/rui"
SlashCmdList["RELOADUI"] = function()
    ReloadUI()
end
