MysticExtended = LibStub("AceAddon-3.0"):NewAddon("MysticExtended", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0", "AceComm-3.0")
local ME = LibStub("AceAddon-3.0"):GetAddon("MysticExtended")
local icon = LibStub('LibDBIcon-1.0');
local addonName = ...
MYSTICEXTENDED_MINIMAP = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(addonName, {
    type = 'data source',
    text = "MysticExtended",
    icon = 'Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1',
  })

local minimap = MYSTICEXTENDED_MINIMAP
local dewdrop = AceLibrary("Dewdrop-2.0");
local realmName = GetRealmName();
--Set Savedvariables defaults
local bagnonGuildbank = false;
local mysticMastro = false;
local auctionator = false;
MYSTICEXTENDED_ITEMSET = false;
local reFound = false;

--Set Savedvariables defaults
local DefaultSettings = {
    { TableName = "ReRollItems", 18863, 18853, 6992720 },
    { TableName = "ListFrameLastState", false },
    { TableName = "currentSelectedList", 1 },
    { TableName = "RollByQuality", true },
    { TableName = "ButtonEnable", true , CheckBox = "MysticExtendedOptions_FloatSetting" },
    { TableName = "QualityList",
        { true, true, true, true }, --Roll Quality
        { true, true, true, true }, --Unknown Quality
        { true, true, true, true }, --Extract Frame Quality
    },
    { TableName = "REFORGE_RETRY_DELAY", 5 },
    { TableName = "ShowInCity", false },
    { TableName = "MinGold", 20000 },
    { TableName = "minExtractNum", 0, Text = "MysticExtendedOptions_minExtracteditbox"},
    { TableName = "UnknownAutoExtract", false },
    { TableName = "ChatMSG", true, CheckBox = "MysticExtendedOptions_ChatMSG" },
    { TableName = "UnlockEnchantWindow", false, CheckBox = "MysticExtendedOptions_UnlockEnchantWindow" },
    { TableName = "ShowUnknown", false, CheckBox = "MysticExtendedExtract_ShowUnknown" },
    { TableName = "AllowShareEnchantListInCombat", true, CheckBox = "MysticExtendedOptions_EnableShareCombat" },
    { TableName = "AllowShareEnchantList", false, CheckBox = "MysticExtendedOptions_EnableShare" },
    { TableName = "ExtractWarn", true, CheckBox = "MysticExtendedOptions_ExtractWarning" },
    { TableName = "DefaultToExtract", false, CheckBox = "MysticExtendedOptions_DefaultToExtract" },
    { TableName = "lastXpLevel", 0 },
    { TableName = "nextLevel", 0 },
    { TableName = "KnownEnchantNumbers",
        Uncommon = { Total = 0, Known = 0, Unknown = 0 },
        Rare = { Total = 0, Known = 0, Unknown = 0 },
        Epic = { Total = 0, Known = 0, Unknown = 0 },
        Legendary = { Total = 0, Known = 0, Unknown = 0 },
        Total = {Total = 0, Known = 0}
    },
}

--[[ TableName = Name of the saved setting
CheckBox = Global name of the checkbox if it has one and first numbered table entry is the boolean
Text = Global name of where the text and first numbered table entry is the default text ]]
local function setupSettings(db)
    for _,v in ipairs(DefaultSettings) do
        if db[v.TableName] == nil then
            if #v > 1 then
                db[v.TableName] = {}
                for _, n in ipairs(v) do
                    tinsert(db[v.TableName], n)
                end
            else
                db[v.TableName] = v[1]
            end
        end

        if v.CheckBox then
            _G[v.CheckBox]:SetChecked(db[v.TableName])
        end
        if v.Text then
            _G[v.Text]:SetText(db[v.TableName])
        end
    end
end

ME.QualityList = {
    [1] = {"Uncommon",2},
    [2] = {"Rare",3},
    [3] = {"Epic",4},
    [4] = {"Legendary",5}
}

local citysList = {
    ["Stormwind City"] = true,
    ["Ironforge"] = true,
    ["Darnassus"] = true,
    ["Exodar"] = true,
    ["Orgrimmar"] = true,
    ["Silvermoon City"] = true,
    ["Thunder Bluff"] = true,
    ["Undercity"] = true,
    ["Shattrath City"] = true,
    ["Booty Bay"] = true,
    ["Everlook"] = true,
    ["Ratchet"] = true,
    ["Gadgetzan"] = true,
    ["Dalaran"] = true,
}

--Returns listTableNum, enchTableNum, enableDisenchantboolean, enableRollboolean, ignoreListboolean
function ME:SearchLists(enchantID, type)
    local compair = {
        ["Extract"] = { { "enableRoll", true }, { "enableDisenchant", true }, { "ignoreList", false } },
        ["ExtractOnly"] = { { "enableRollExt", true }, { "enableDisenchant", true }, { "ignoreList", false } },
        ["ExtractAny"] = { { "enableDisenchant", true }, { "ignoreList", false } },
        ["Keep"] = { { "enableRoll", true }, { "ignoreList", false } },
        ["Ignore"] = { { "enableRoll", true }, { "enableDisenchant", false }, { "ignoreList", true } }
    }
    --checks to see if we should keep or roll over this enchant
    local function getStates(table)
        for _, s in ipairs(compair[type]) do
            if not s[2] == table[realmName][s[1]] then
                return false
            end
        end
        return true
    end

    for _, v in ipairs(ME.EnchantSaveLists) do
        for _, b in ipairs(v) do
            if b[1] == enchantID and getStates(v) then
                return true
            end
        end
    end
end

--returns if the item needs to be reforged or not
local function rollCheck(bagID, slotID, extractoff)
    if ME.RollExtracts then return true end
    local enchantID = GetREInSlot(bagID, slotID)
    if not enchantID then return true end
    local extractCount = GetItemCount(98463)
        if (ME.db.UnknownAutoExtract and extractCount and (extractCount > ME.db.minExtractNum) and not IsReforgeEnchantmentKnown(enchantID) and ME:DoRarity(enchantID,2)) or
            ME:SearchLists(enchantID, "Extract") or
            (extractCount and (extractCount > 0) and ME:SearchLists(enchantID, "ExtractOnly")) then
            --extract if we have extracts keep if not
            if not extractoff and extractCount and (extractCount > 0) then
                ME:ExtractEnchant(bagID,slotID,enchantID)
                --updates scroll frame after removing an item from a list
                MysticExtended_ScrollFrameUpdate()
            end
            if ME.db.Debug then print("Extract") end
            return false
        elseif ME:SearchLists(enchantID, "Keep") then
            --keep enchants on these lists
            if ME.db.Debug then print("Keep") end
            return false
        elseif ME:SearchLists(enchantID, "Ignore") then
            --reforge items on these lists
            if ME.db.Debug then print("Ignore") end
            return true
        elseif mysticMastro and ME.db.mysticMastro and MysticMaestroData[realmName].RE_AH_STATISTICS[enchantID] and
            MysticMaestroData[realmName].RE_AH_STATISTICS[enchantID].current and
            ME.db.MinGold >= MysticMaestroData[realmName].RE_AH_STATISTICS[enchantID].current.Min then
            if ME.db.Debug then print("Gold") end
            return true
        elseif auctionator and ME.db.auctionator and AUCTIONATOR_MYSTIC_ENCHANT_PRICE_DATABASE[realmName][enchantID] and
        AUCTIONATOR_MYSTIC_ENCHANT_PRICE_DATABASE[realmName][enchantID].Current and
        ME.db.MinGold >= AUCTIONATOR_MYSTIC_ENCHANT_PRICE_DATABASE[realmName][enchantID].Current then
        if ME.db.Debug then print("Gold") end
        return true
        elseif not ME:DoRarity(enchantID,1) then
            --reforge the raritys that arnt selected
            if ME.db.Debug then print("Rarity") end
            return true
        end
end

--returns true if we want to keep this enchant
function ME:DoRarity(enchantID, iNumber)
    --get the enchantID of the slot that being rolled
    if enchantID then
        local quality = MYSTIC_ENCHANTS[enchantID].quality
        if (iNumber == 1 and ME.db.RollByQuality and ME.db.QualityList[iNumber][quality - 1]) or
            (iNumber == 2 and ME.db.UnknownAutoExtract and ME.db.QualityList[iNumber][quality - 1]) or
            (iNumber == 3 and ME.db.ShowUnknown and ME.db.QualityList[iNumber][quality - 1]) then
            return true
        end
    end
end

--timer to try to roll an enchant every 3 seconds if no altar up
function ME:Repeat()
    ME:RollEnchant();
end

--stops rolling and re registers ascensions ui 
function ME:StopAutoRoll()
    ME:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
    ME:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    MysticEnchantingFrame:RegisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
    ME:CancelTimer(ME.rollTimer);
    MysticExtended_ListFrameReforgeButton:SetText("Start Reforge");
    MysticExtendedFrame_Menu.Text:SetText("|cffffffffStart\nReforge");
    MysticExtendedCountDownText:SetText("");
    MysticExtendedCountDownFrame:Hide();
    MysticExtendedFrame_Menu_Icon_Breathing:Hide();
    ME.AutoRolling = false;
    reFound = false;
end

--works out how many rolls on the current item type it will take to get the next altar level
local function GetRequiredRollsForLevel(level)
    if level == 0 then
        return 1
    end

    if level >= 250 and not C_Realm:IsRealmMask(Enum.RealmMask.Area52) then
        return 557250 + (level - 250) * 4097
    end

    return floor(354 * level + 7.5 * level * level)
end


--removes item from a list if you know it allready or just disenchanted it
local function removeFound(enchantID)
    local function findEnchantID(table)
        for i, v in ipairs(table) do
            if v[1] == enchantID then
                return true, i
            end
        end
    end

    local notOnList = true
    for _,v in pairs(ME.EnchantSaveLists) do
        if v[realmName].enableDisenchant or v[realmName].enableRollExt then
            local remove, ID = findEnchantID(v)
                if remove then
                    tremove(v,ID)
                    if ME.db.ChatMSG then
                        local itemLink = ME:CreateItemLink(enchantID)
                        DEFAULT_CHAT_FRAME:AddMessage(itemLink .. " Has been added to your collection and removed from |cFF00FFFF".. v.Name .. " |cfffffffflist")
                        notOnList = false
                    end
                end
        end
    end
    MysticExtended_ScrollFrameUpdate()
    return notOnList
end

--[[
Event Handlers
]]
function MysticExtended_OnEvent(event, arg1, arg2, arg3)
    --starts the next roll after last cast
    if arg1 == "player" and arg2 == "Enchanting" then
        --stops all rolling when enchanting is interrupted
        if event == "UNIT_SPELLCAST_INTERRUPTED" then
            ME:StopAutoRoll();
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            --stops the 3second timer
            ME:CancelTimer(ME.rollTimer);
            --starts short timer to start next roll item
            ME:ScheduleTimer(ME.RollEnchant, tonumber(ME.db.REFORGE_RETRY_DELAY / 10));
        end
        ME:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        ME:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    end

    --ascension events
    if event == "COMMENTATOR_SKIRMISH_QUEUE_REQUEST" then
        if arg1 == "ASCENSION_REFORGE_ENCHANTMENT_LEARNED" then
            local RE = GetREData(arg2)
            local notOnList = removeFound(RE.enchantID)
            if ME.db.ChatMSG and notOnList then
                local itemLink = ME:CreateItemLink(RE.enchantID)
                DEFAULT_CHAT_FRAME:AddMessage(itemLink .. " Has been added to your collection")
            end
            MysticExtendedExtractCountText:SetText(string.format("Mystic Extracts: |cffFFFFFF%i|r", GetItemCount(98463)))
            ME:CalculateKnowEnchants()
        elseif ME.AutoRolling and arg1 == "ASCENSION_REFORGE_PROGRESS_UPDATE" then
            --Shows how many more enchants to level up your atlar
            local xpGained = arg2 - ME.db.lastXpLevel
            ME.db.nextLevel = math.floor((GetRequiredRollsForLevel(arg3) - arg2) / xpGained) + 1
            MysticExtendedNextLevelText:SetText("Next Altar Level in "..(ME.db.nextLevel).." Enchants")
            ME.db.lastXpLevel = arg2
        end
    end

    -- used to auto hide/show floating button in citys
    if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        --auto show/hide in city's
        if ME.db.ShowInCity and ME.db.ButtonEnable and (citysList[GetMinimapZoneText()] or citysList[GetRealZoneText()]) then
            MysticExtendedFrame:Show();
            MysticExtendedFrame_Menu:Show();
        elseif ME.db.ShowInCity and ME.db.ButtonEnable then
            MysticExtendedFrame:Hide();
            MysticExtendedFrame_Menu:Hide();
        end
    end
end

--checks bag slot to see if it has an item on the reroll items list
local function getItemID(bagID, slotID, item)
    if not item and bagID and slotID then
        item = GetContainerItemID(bagID, slotID);
    end
    for i , v in pairs(ME.db.ReRollItems) do
        if v == item then
            return true;
        end
    end
end

function ME:ExtractEnchant(bagID,slotID,enchantID)
    --checks to see if you have any mystic extracts
    if GetItemCount(98463) and (GetItemCount(98463) > 0) then
        --checks to see if you know the enchant if not extract and remove from list
        if IsReforgeEnchantmentKnown(enchantID) then
            removeFound(enchantID)
            DEFAULT_CHAT_FRAME:AddMessage("You already know this enchant removed from list")
        else
            RequestSlotReforgeExtraction(bagID, slotID)
            return true
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("You don't have enough Mystic Extract's to Extract this enchant")
    end
end

--finds the next bag slot with an item to roll on
local function FindNextItem()
    for bagID = 0, 4 do
        for slotID = 1, GetContainerNumSlots(bagID) do
            if getItemID(bagID,slotID) then
                 if rollCheck(bagID, slotID) then
                    return bagID, slotID, true
                 end
            end
        end
    end
end
--[[
roll the enchant or skip this item
]]
function ME:RollEnchant()
    --find item to roll on
    reFound = false
    local bagID, slotID, reforge
    if MYSTICEXTENDED_ITEMSET and MYSTICEXTENDED_BAGID and MYSTICEXTENDED_SLOTID then
        reforge = rollCheck(MYSTICEXTENDED_BAGID, MYSTICEXTENDED_SLOTID, true)
        bagID, slotID = MYSTICEXTENDED_BAGID, MYSTICEXTENDED_SLOTID
        if not reforge then
            reFound = true
        end
    else
        bagID, slotID, reforge = FindNextItem();
    end


    --show run count down
    MysticExtendedNextLevelText:SetText("Next Altar Level in "..(ME.db.nextLevel).." Enchants")
    MysticExtendedNextLevelText:Show()
    MysticExtendedCountDownFrame:Show()
    MysticExtendedCountDownText:SetText("You Have " .. GetItemCount(98462) .. " Runes Left")
    -- check if rolling hasnt been stoped or we have enough runes
    if ME.AutoRolling and GetItemCount(98462) > 0 and GetUnitSpeed("player") == 0 and reforge and not reFound then
        ME:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", MysticExtended_OnEvent)
        ME:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", MysticExtended_OnEvent)
        --starts 3sec repeat timer for when there is no atlar
        ME.rollTimer = ME:ScheduleTimer("Repeat", 3)
        --check if we are just rolling for extracts
        RequestSlotReforgeEnchantment(bagID, slotID)
        return
    end
        --stop if where out of items or runes
        if GetItemCount(98462) <= 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFOut Runes")
        elseif reFound then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFEnchant Found: " .. ME:CreateItemLink(GetREInSlot(bagID,slotID)));
        elseif GetUnitSpeed("player") == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFOut of Items to Reforge")
        end
        ME:StopAutoRoll();
end

--start rolling make all text changes 
local function startAutoRoll()
    if ME.AutoRolling then
        ME:StopAutoRoll();
    else
        if not MysticEnchantingFrame:IsVisible() then
            MysticEnchantingFrame:UnregisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
        end
        if IsMounted() then Dismount() end
        ME.AutoRolling = true;
        MysticExtendedFrame_Menu_Icon_Breathing:Show();
        MysticExtended_ListFrameReforgeButton:SetText("Auto Reforging");
        MysticExtendedFrame_Menu.Text:SetText("|cffffffffAuto\nForging");
        ME:RollEnchant();

    end
end

local function QualityEnable(enable)
    ME.db[enable] = not ME.db[enable]
end

local function QualitySet(listNum,quality)
    ME.db.QualityList[listNum][quality] = not ME.db.QualityList[listNum][quality]
end

local function EnableClick(list,cat,cat2)
    if ME.EnchantSaveLists[list][realmName][cat] then
        ME.EnchantSaveLists[list][realmName][cat] = false;
    else
        ME.EnchantSaveLists[list][realmName][cat] = true;
        if cat2 then
            ME.EnchantSaveLists[list][realmName][cat2] = false;
        end
    end
end

function ME:ButtonEnable(button)
    if button == "Main" then
        if ME.db.ButtonEnable then
            MysticExtendedFrame:Hide();
            MysticExtendedFrame_Menu:Hide();
            ME.db.ButtonEnable = false
        else
            MysticExtendedFrame:Show();
            MysticExtendedFrame_Menu:Show();
            ME.db.ButtonEnable = true
        end
    else
        if ME.db.ShowInCity then
            ME:UnregisterEvent("ZONE_CHANGED");
            ME:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
            ME.db.ShowInCity = false
            if ME.db.ButtonEnable then
                MysticExtendedFrame:Show();
                MysticExtendedFrame_Menu:Show();
            else
                MysticExtendedFrame:Hide();
                MysticExtendedFrame_Menu:Hide();
            end
        else
            ME.db.ShowInCity = true
            if ME.db.ButtonEnable and (citysList[GetMinimapZoneText()] or citysList[GetRealZoneText()]) then
                ME:RegisterEvent("ZONE_CHANGED", MysticExtended_OnEvent);
                ME:RegisterEvent("ZONE_CHANGED_NEW_AREA", MysticExtended_OnEvent);
                MysticExtendedFrame:Show();
                MysticExtendedFrame_Menu:Show();
            elseif ME.db.ButtonEnable then
                ME:RegisterEvent("ZONE_CHANGED", MysticExtended_OnEvent);
                ME:RegisterEvent("ZONE_CHANGED_NEW_AREA", MysticExtended_OnEvent);
                MysticExtendedFrame:Hide();
                MysticExtendedFrame_Menu:Hide();
            end
        end
    end
end

local function realmCheck(table)
    if table[realmName] then return end
    table[realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false};    
end

local function rollMenuLevel1(value)
    dewdrop:AddLine(
        'text', "Select Lists to Roll",
        'hasArrow', true,
        'value', ME.EnchantSaveLists,
        'notCheckable', true
    )
    dewdrop:AddLine(
        'text', "Auto Extract Unknown",
        'hasArrow', true,
        'value', "extractUnknown",
        'notCheckable', true
    )
    if mysticMastro or auctionator then
        dewdrop:AddLine(
            'text', "Reforge Based On Auction Price",
            'hasArrow', true,
            'value', "auction",
            'notCheckable', true
        )
    end
    dewdrop:AddLine(
        'text', "Roll Quality",
        'hasArrow', true,
        'value', "RollQuality",
        'notCheckable', true
    )
    dewdrop:AddLine(
        'text', "Roll For Extracts",
        'value', "RollExtracts",
        'hasArrow', true,
        'notCheckable', true
    )
    dewdrop:AddLine(
        'text', "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'closeWhenClicked', true,
        'notCheckable', true
    )
end

local function rollMenuLevel2(value)
    if value == "extractUnknown" then
        dewdrop:AddLine(
                'text', "Enable",
                'func', QualityEnable,
                'arg1', "UnknownAutoExtract",
                'checked', ME.db.UnknownAutoExtract
            )
        for k,v in ipairs(ME.QualityList) do
            local qualityColor = select(4,GetItemQualityColor(v[2]))
            dewdrop:AddLine(
                'text', qualityColor..v[1],
                'arg1', 2,
                'arg2', k,
                'func', QualitySet,
                'checked', ME.db.QualityList[2][k]
            )
        end
    elseif value == "auction" then
        if auctionator then
            dewdrop:AddLine(
                'text', "Use Auctionator Price Database",
                'func', function()
                    ME.db.auctionator = not ME.db.auctionator
                    if ME.db.auctionator then
                        ME.db.mysticMastro = false
                    end
                end,
                'checked', ME.db.auctionator
            )
        end
        if mysticMastro then
            dewdrop:AddLine(
                    'text', "Use MysticMastro Price Database",
                    'func', function()
                        ME.db.mysticMastro = not ME.db.mysticMastro
                        if ME.db.mysticMastro then
                            ME.db.auctionator = false
                        end
                    end,
                    'checked', ME.db.mysticMastro
                )
        end
    elseif value == "RollQuality" then
        dewdrop:AddLine(
                'text', "Enable",
                'func', QualityEnable,
                'arg1', "RollByQuality",
                'checked', ME.db.RollByQuality
            )
        for k,v in ipairs(ME.QualityList) do
            local qualityColor = select(4,GetItemQualityColor(v[2]))
            dewdrop:AddLine(
                'text', qualityColor..v[1],
                'arg1', 1,
                'arg2', k,
                'func', QualitySet,
                'checked', ME.db.QualityList[1][k]
            )
        end
    elseif value == ME.EnchantSaveLists then
        for i,v in ipairs(value) do
            realmCheck(v);
            dewdrop:AddLine(
                'text', v.Name,
                'hasArrow', true,
                'value', {v,i},
                'notCheckable', true
            )
        end
    elseif value == "RollExtracts" then
        dewdrop:AddLine(
                'text', "Enable",
                'checked', ME.RollExtracts,
                'func', function() ME.RollExtracts = not ME.RollExtracts end
            )
        dewdrop:AddLine(
            'text', "This option is for when you want to roll all your runes",
            'notCheckable', true
        )
        dewdrop:AddLine(
            'text', "to genarate mystic extracts enabling this will roll with",
            'notCheckable', true
        )
        dewdrop:AddLine(
            'text', "out stoping on any enchants till you run out of runes.",
            'notCheckable', true
        )
        dewdrop:AddLine(
            'text', "Either put an item in the enchanting frame or have the",
            'notCheckable', true
        )
        dewdrop:AddLine(
            'text', "item be the first item in your inventory.",
            'notCheckable', true
        )
    end
    dewdrop:AddLine(
        'text', "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'closeWhenClicked', true,
        'notCheckable', true
    )
end

local function rollMenuLevel3(value)
    dewdrop:AddLine(
        'text', "Enable List",
        'arg1', value[2],
        'arg2', "enableRoll",
        'arg3', "enableRollExt",
        'func', EnableClick,
        'checked', value[1][realmName]["enableRoll"]
    )
    dewdrop:AddLine(
        'text', "Enable Only When You Have Extracts",
        'arg1', value[2],
        'arg2', "enableRollExt",
        'arg3', "enableRoll",
        'func', EnableClick,
        'checked', value[1][realmName]["enableRollExt"]
    )
    dewdrop:AddLine(
        'text', "Disenchant to Collection and remove from list",
        'arg1', value[2],
        'arg2', "enableDisenchant",
        'arg3', "ignoreList",
        'func', EnableClick,
        'checked', value[1][realmName]["enableDisenchant"]
    )
    dewdrop:AddLine(
        'text', "ReRoll items on this list when found",
        'arg1', value[2],
        'arg2', "ignoreList",
        'arg3', "enableDisenchant",
        'func', EnableClick,
        'checked', value[1][realmName]["ignoreList"]
    )
    dewdrop:AddLine(
        'text', "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'closeWhenClicked', true,
        'notCheckable', true
    )
end

function ME:RollMenuRegister(self)
	dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                rollMenuLevel1(value)
            elseif level == 2 then
                rollMenuLevel2(value)
            elseif level == 3 then
                rollMenuLevel3(value)
            end
		end,
		'dontHook', true
	)
end

function MysticExtended_OnClick(self, arg1)
    if dewdrop:IsOpen() then
        dewdrop:Close();
    else
        if (arg1 == "LeftButton") then
            startAutoRoll();
        elseif (arg1 == "RightButton") then
            if IsAltKeyDown() then
                MysticEnchantingFrame:Display();
            else
                ME:RollMenuRegister(self);
                dewdrop:Open(this);
            end
        end
    end
end

--Creates the main floating button
local mainframe = CreateFrame("FRAME", "MysticExtendedFrame", UIParent, nil);
    mainframe:SetPoint("CENTER",0,0);
    mainframe:SetSize(70,70);
    mainframe:EnableMouse(true);
    mainframe:SetMovable(true);
    mainframe:RegisterForDrag("LeftButton");
    mainframe:SetScript("OnDragStart", function(self) mainframe:StartMoving() end);
    mainframe:SetScript("OnDragStop", function(self) mainframe:StopMovingOrSizing() end);
    mainframe:Hide();

local countDownFrame = CreateFrame("FRAME", "MysticExtendedCountDownFrame", UIParrnt, nil);
    countDownFrame:SetPoint("CENTER",0,200);
    countDownFrame:SetSize(400,50);
    countDownFrame:Hide();
    countDownFrame.cText = countDownFrame:CreateFontString("MysticExtendedCountDownText","OVERLAY","GameFontNormal");
    countDownFrame.cText:Show();
    countDownFrame.cText:SetPoint("CENTER",0,0);
    countDownFrame.nextlvlText = countDownFrame:CreateFontString("MysticExtendedNextLevelText","OVERLAY","GameFontNormal");
    countDownFrame.nextlvlText:Show();
    countDownFrame.nextlvlText:SetPoint("CENTER",0,-20);
    countDownFrame.rollingText = countDownFrame:CreateFontString("MysticExtendedRollingText","OVERLAY","GameFontNormal");
    countDownFrame.rollingText:Show();
    countDownFrame.rollingText:SetPoint("CENTER",0,20);
    countDownFrame.rollingText:SetText("Auto Reforging In Progress");

local reforgebutton = CreateFrame("Button", "MysticExtendedFrame_Menu", MysticExtendedFrame);
    reforgebutton:SetSize(55,55);
    reforgebutton:SetPoint("TOP", MysticExtendedFrame, "TOP", 0, -10);
    reforgebutton.icon = reforgebutton:CreateTexture("MysticExtendedFrame_Menu_Icon","ARTWORK");
    reforgebutton.icon:SetSize(55,55);
    reforgebutton.icon:SetPoint("TOPLEFT", "MysticExtendedFrame_Menu","TOPLEFT",1,-1);
    reforgebutton.icon:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1");
    reforgebutton.AnimatedTex = reforgebutton:CreateTexture("MysticExtendedFrame_Menu_Icon_Breathing", "OVERLAY");
    reforgebutton.AnimatedTex:SetSize(59,59);
    reforgebutton.AnimatedTex:SetPoint("CENTER", reforgebutton.icon, 0, 0);
    reforgebutton.AnimatedTex:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected");
    reforgebutton.AnimatedTex:SetAlpha(0);
    reforgebutton.AnimatedTex:Hide();
    reforgebutton.Highlight = reforgebutton:CreateTexture("MysticExtendedFrame_Menu_Icon_Highlight", "OVERLAY");
    reforgebutton.Highlight:SetSize(59,59);
    reforgebutton.Highlight:SetPoint("CENTER", reforgebutton.icon, 0, 0);
    reforgebutton.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected");
    reforgebutton.Highlight:Hide();
    reforgebutton:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    reforgebutton:SetScript("OnClick", function(self, btnclick) MysticExtended_OnClick(self,btnclick) end);
    reforgebutton:SetScript("OnEnter", function()
        reforgebutton.Highlight:Show();
        if IsShiftKeyDown() then
            MysticExtended_Secure:Show();
        else
            if not IsAltKeyDown() and not IsShiftKeyDown() then GameTooltip:SetOwner(this, "ANCHOR_RIGHT") end
            GameTooltip:AddLine("Left Click To Start Reforging");
            GameTooltip:AddLine("Shift Left Click To Drop An Atlar");
            GameTooltip:AddLine("Right Click To Show Roll Settings");
            GameTooltip:AddLine("Alt Right To Open Enchanting Frame");
            GameTooltip:Show();
        end
	end);
	reforgebutton:SetScript("OnLeave", function()
        reforgebutton.Highlight:Hide();
        GameTooltip:Hide();
    end);
    reforgebutton:Hide();
    reforgebutton.Text = reforgebutton:CreateFontString();
    reforgebutton.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    reforgebutton.Text:SetFontObject(GameFontNormal)
    reforgebutton.Text:SetText("|cffffffffStart\nReforge");
    reforgebutton.Text:SetPoint("CENTER", 0, 0);
    reforgebutton.Text:SetShadowOffset(1,-1);
    
    reforgebutton.AnimatedTex.AG = reforgebutton.AnimatedTex:CreateAnimationGroup();
    reforgebutton.AnimatedTex.AG.Alpha0 = reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha");
    reforgebutton.AnimatedTex.AG.Alpha0:SetStartDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha0:SetDuration(2);
    reforgebutton.AnimatedTex.AG.Alpha0:SetOrder(0);
    reforgebutton.AnimatedTex.AG.Alpha0:SetEndDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha0:SetSmoothing("IN");
    reforgebutton.AnimatedTex.AG.Alpha0:SetChange(1);
    
    reforgebutton.AnimatedTex.AG.Alpha1 = reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha");
    reforgebutton.AnimatedTex.AG.Alpha1:SetStartDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha1:SetDuration(2);
    reforgebutton.AnimatedTex.AG.Alpha1:SetOrder(0);
    reforgebutton.AnimatedTex.AG.Alpha1:SetEndDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha1:SetSmoothing("IN_OUT");
    reforgebutton.AnimatedTex.AG.Alpha1:SetChange(-1);
    
    reforgebutton.AnimatedTex.AG:SetScript("OnFinished", function()
        reforgebutton.AnimatedTex.AG:Play();
    end)
    
    reforgebutton.AnimatedTex.AG:Play();

    local secureBttn = CreateFrame("Button", "MysticExtended_Secure", MysticExtendedFrame_Menu, "SecureActionButtonTemplate");
    secureBttn:SetSize(50,50);
    secureBttn:SetPoint("CENTER", "MysticExtendedFrame_Menu", "CENTER");
    secureBttn:SetAttribute("shift-type1", "item");
    secureBttn:SetAttribute("item","Mystic Enchanting Altar");
    secureBttn:RegisterForClicks("LeftButtonUp");
    secureBttn:Hide();
    secureBttn:SetFrameStrata("DIALOG");
    secureBttn:SetScript("OnKeyUp", function() MysticExtended_Secure:Hide() end);
    secureBttn:SetScript("OnLeave", function()
        MysticExtended_Secure:Hide();
    end);

--[[
MysticExtended_SlashCommand(msg):
msg - takes the argument for the /mysticextended command so that the appropriate action can be performed
If someone types /mysticextended, bring up the options box
]]
local function MysticExtended_SlashCommand(msg)
    if msg == "options" then
        ME:OptionsToggle();
    elseif msg == "extract" then
        ME:ExtractToggle();
    elseif msg == "bloody" then
        ME:AutoUntarnished();
    elseif msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF90EE90<MysticExtended>");
        DEFAULT_CHAT_FRAME:AddMessage("options to open options");
        DEFAULT_CHAT_FRAME:AddMessage("extract to open extract interface");
    elseif msg == "debug" then
        ME:Debug()
    else
        if MysticExtendedFrame:IsVisible() then
            MysticExtendedFrame:Hide();
            MysticExtendedFrame_Menu:Hide();
        else
            MysticExtendedFrame:Show();
            MysticExtendedFrame_Menu:Show();
        end
    end
end

function ME:ExtractToggle()
    if MysticExtendedExtractFrame:IsVisible() then
        MysticExtendedExtractFrame:Hide();
    else
        MysticExtendedExtractFrame:Show();
    end
end

function ME:OnInitialize()
    realmName = GetRealmName();
    if not MysticExtendedDB then MysticExtendedDB = {} end
    if not MysticExtendedDB.Settings then MysticExtendedDB.Settings = {} end
    if not MysticExtendedDB.Settings[realmName] then MysticExtendedDB.Settings[realmName] = {} end
    if not MysticExtendedDB.EnchantSaveLists then MysticExtendedDB.EnchantSaveLists = { [1] = {Name = "Default"} } end
    ME.db = MysticExtendedDB.Settings[realmName]
    ME.EnchantSaveLists = MysticExtendedDB.EnchantSaveLists
    setupSettings(ME.db)

    ME.RollExtracts = ME.db.DefaultToExtract

    for _, v in ipairs(ME.EnchantSaveLists) do
        if v[realmName] == nil then
            v[realmName] = { ["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false };
        end
    end

    ME.AutoRolling = false

    --Enable the use of /al or /atlasloot to open the loot browser
    SLASH_MYSTICEXTENDED1 = "/mysticextended";
    SLASH_MYSTICEXTENDED2 = "/me";
    SlashCmdList["MYSTICEXTENDED"] = function(msg)
        MysticExtended_SlashCommand(msg);
    end

    ME:RegisterComm("MysticExtendedEnchantList")
end

--adds a move to and from buttons to realm/personal/guild bank for auto moving mystic enchanted trinkets 
local function guildBankFrameOpened()
    local gFrame = GuildBankFrame
    local toPointX, toPointY = -255,-39
    local fromPointX, fromPointY = 255,-39
    if bagnonGuildbank then
        gFrame = BagnonFrameguildbank
        toPointX, toPointY = -80, 25
        fromPointX, fromPointY = 80, 25
    end
    local moveReItemsTobank = CreateFrame("Button", "MysticExtended_BankTo", gFrame, "OptionsButtonTemplate");
    moveReItemsTobank:SetSize(135, 26);
    moveReItemsTobank:SetPoint("TOP", gFrame, "TOP", toPointX, toPointY);
    moveReItemsTobank:SetText("Move To Bank");
    moveReItemsTobank:SetScript("OnClick", function()
        for bagID = 0, 4 do
            for slotID = 1, GetContainerNumSlots(bagID) do
                local enchantID = GetREInSlot(bagID, slotID)
                if enchantID and getItemID(bagID, slotID) and
                (ME:SearchLists(enchantID, "Keep") or (ME:DoRarity(enchantID,1) and not ME:SearchLists(enchantID, "Ignore"))) then
                    UseContainerItem(bagID, slotID)
                end
            end
        end
    end)
    local moveReItemsFrombank = CreateFrame("Button", "MysticExtended_BankFrom", gFrame, "OptionsButtonTemplate");
    moveReItemsFrombank:SetSize(135, 26);
    moveReItemsFrombank:SetPoint("TOP", gFrame, "TOP", fromPointX, fromPointY);
    moveReItemsFrombank:SetText("Move To Inventory");
    moveReItemsFrombank:SetScript("OnClick", function()
        for c = 1, 112 do
            if GetGuildBankItemLink(GetCurrentGuildBankTab(), c) then
                local id = tonumber(select(3,
                    strfind(GetGuildBankItemLink(GetCurrentGuildBankTab(), c), "^|%x+|Hitem:(%-?%d+).*")))
                if getItemID(nil, nil, id) then
                    AutoStoreGuildBankItem(GetCurrentGuildBankTab(), c)
                end
            end
        end
    end)
     ME:UnregisterEvent("GUILDBANKFRAME_OPENED");
end

--auto converts trinkets to there bloody version
function ME:BloodyJarOpen()
    if GossipFrameNpcNameText:GetText() == "Bloody Jar" and ME.db.AutoMysticScrollBloodforge then
        for i = 1, GetNumGossipOptions() - 1 do
            local b = _G["GossipTitleButton" .. i]
            if b and b:GetText() and b:GetText():match("Untarnished Mystic Scroll") then
                b:Click()
                _G["StaticPopup1Button1"]:Click()
                return
            end
        end
    end
end

function ME:AutoUntarnished()
    if ME.db.AutoMysticScrollBloodforge then
        ME.db.AutoMysticScrollBloodforge = false
        ME:UnregisterEvent("GOSSIP_SHOW");
        DEFAULT_CHAT_FRAME:AddMessage("Auto BloodyJar Is Now OFF");
    else
        ME.db.AutoMysticScrollBloodforge = true
        ME:RegisterEvent("GOSSIP_SHOW", MysticExtended.BloodyJarOpen);
        DEFAULT_CHAT_FRAME:AddMessage("Auto BloodyJar Is Now ON");
    end
end

function ME:Debug()
    if ME.db.Debug then
        ME.db.Debug = false
        DEFAULT_CHAT_FRAME:AddMessage("Debug Is Now OFF");
    else
        ME.db.Debug = true
        DEFAULT_CHAT_FRAME:AddMessage("Debug Is Now ON");
    end
end

--Loads when addon is loaded
function ME:OnEnable()
    MysticExtended_ListEnable()
    MysticExtended_DropDownInitialize()

    if ME.db.AutoMysticScrollBloodforge then
        --MysticExtendedOptions_AutoMysticScrollBloodforge:SetChecked(true);
        ME:RegisterEvent("GOSSIP_SHOW", MysticExtended.BloodyJarOpen);
    else
        --MysticExtendedOptions_AutoMysticScrollBloodforge:SetChecked(false);
    end

    if ME.db.ShowInCity and (citysList[GetMinimapZoneText()] or citysList[GetRealZoneText()]) then
        MysticExtendedOptions_FloatCitySetting:SetChecked(true);
        ME:RegisterEvent("ZONE_CHANGED", MysticExtended_OnEvent);
        ME:RegisterEvent("ZONE_CHANGED_NEW_AREA", MysticExtended_OnEvent);
        if ME.db.ButtonEnable then
            MysticExtendedFrame:Show();
            MysticExtendedFrame_Menu:Show();
        else
            MysticExtendedFrame:Hide();
            MysticExtendedFrame_Menu:Hide();
        end
    elseif ME.db.ShowInCity and not (citysList[GetMinimapZoneText()] or citysList[GetRealZoneText()]) and ME.db.ButtonEnable then
        MysticExtendedOptions_FloatCitySetting:SetChecked(true);
        ME:RegisterEvent("ZONE_CHANGED", MysticExtended_OnEvent);
        ME:RegisterEvent("ZONE_CHANGED_NEW_AREA", MysticExtended_OnEvent);
        MysticExtendedFrame:Hide();
        MysticExtendedFrame_Menu:Hide();
    else
        if ME.db.ButtonEnable then
            MysticExtendedFrame:Show();
            MysticExtendedFrame_Menu:Show();
        else
            MysticExtendedFrame:Hide();
            MysticExtendedFrame_Menu:Hide();
        end
        MysticExtendedOptions_FloatCitySetting:SetChecked(false);
    end
    MysticExtended_DelaySlider:SetValue(ME.db.REFORGE_RETRY_DELAY);

    ME:RegisterEvent("GUILDBANKFRAME_OPENED", guildBankFrameOpened);
    ME:RegisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST", MysticExtended_OnEvent);

    if not ME.db.minimap then
        ME.db.minimap = {hide = false}
    end

    if icon then
        icon:Register('MysticExtended', minimap, ME.db.minimap)
    end

    if ME.db.minimap and ME.db.minimap.hide then
        MysticExtendedOptions_MapIcon:SetChecked(true);
    else
        MysticExtendedOptions_MapIcon:SetChecked(false);
    end

    if select(4,GetAddOnInfo('Bagnon_GuildBank')) then bagnonGuildbank = true end
    if select(4,GetAddOnInfo('MysticMaestro')) then
        mysticMastro = true
        MysticExtended_MoneyFrame:Show()
    end
    if select(4,GetAddOnInfo('Auctionator')) then
        auctionator = true
        MysticExtended_MoneyFrame:Show()
    end

    MoneyInputFrame_SetCopper(MysticExtended_MoneyFrame,ME.db.MinGold)
end

-- All credit for this func goes to Tekkub and his picoGuild!
local function GetTipAnchor(frame)
    local x, y = frame:GetCenter()
    if not x or not y then return 'TOPLEFT', 'BOTTOMLEFT' end
    local hhalf = (x > UIParent:GetWidth() * 2 / 3) and 'RIGHT' or (x < UIParent:GetWidth() / 3) and 'LEFT' or ''
    local vhalf = (y > UIParent:GetHeight() / 2) and 'TOP' or 'BOTTOM'
    return vhalf .. hhalf, frame, (vhalf == 'TOP' and 'BOTTOM' or 'TOP') .. hhalf
end

function minimap.OnClick(self, button)
    GameTooltip:Hide()
    if button == "RightButton" then
        if dewdrop:IsOpen() then
            dewdrop:Close();
        else
            ME:MiniMapMenuRegister(self);
            dewdrop:Open(this);
        end
    elseif not MysticExtendedExtractFrame:IsVisible() and button == 'LeftButton' then
        MysticExtendedExtractFrame:Show();
    else
        MysticExtendedExtractFrame:Hide();
    end
end

function minimap.OnLeave()
    GameTooltip:Hide()
end

function minimap.OnEnter(self)
    GameTooltip:SetOwner(self, 'ANCHOR_NONE')
    GameTooltip:SetPoint(GetTipAnchor(self))
    GameTooltip:ClearLines()
    GameTooltip:AddLine('MysticExtended')
    GameTooltip:Show()
end

function ME:ToggleMinimap()
    local hide = not ME.db.minimap.hide
    ME.db.minimap.hide = hide
    if hide then
      icon:Hide('MysticExtended')
    else
      icon:Show('MysticExtended')
    end
end

local function toggleFloatingbutton()
    if MysticExtendedFrame:IsVisible() then
        MysticExtendedFrame:Hide();
        MysticExtendedFrame_Menu:Hide();
    else
        MysticExtendedFrame:Show();
        MysticExtendedFrame_Menu:Show();
    end
end

-- returns true, if player has item with given ID in inventory or bags and it's not on cooldown
local function hasItem(itemID)
    local item, found, id
    -- scan bags
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        item = GetContainerItemLink(bag, slot)
        if item then
          found, _, id = item:find('^|c%x+|Hitem:(%d+):.+')
          if found and tonumber(id) == itemID then
            return true
          end
        end
      end
    end
    return false
  end

function ME:MiniMapMenuRegister(self)
	dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                local text = "Start Reforge"
                if ME.AutoRolling then
                    text = "Reforging"
                end
                dewdrop:AddLine(
                    'text', text,
                    'func', startAutoRoll,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                local itemID = 1903513
                if hasItem(itemID) then
                    local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                    local startTime, duration = GetItemCooldown(itemID)
                    local cooldown = math.ceil(((duration - (GetTime() - startTime))/60))
                    local text = name
                    if cooldown > 0 then
                      text = name.." |cFF00FFFF("..cooldown.." ".. "mins" .. ")"
                    end
                    local secure = {
                      type1 = 'item',
                      item = name
                    }
                    dewdrop:AddLine(
                      'text', text,
                      'secure', secure,
                      'icon', icon,
                      'closeWhenClicked', true
                    )
                end
                dewdrop:AddLine(
                    'text', "Roll Options",
                    'hasArrow', true,
                    'value', "Roll Options",
                    'notCheckable', true
                )
                dewdrop:AddLine(
                    'text', "Show/Hide Floating Button",
                    'func', toggleFloatingbutton,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                dewdrop:AddLine(
                    'text', "Options",
                    'func', ME.OptionsToggle,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                dewdrop:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'closeWhenClicked', true,
					'notCheckable', true
				)
            elseif level == 2 then
                if value == "Roll Options" then
                    rollMenuLevel1(value)
                end
            elseif level == 3 then
                rollMenuLevel2(value)
            elseif level == 4 then
                rollMenuLevel3(value)
            end
		end,
		'dontHook', true
	)
end




