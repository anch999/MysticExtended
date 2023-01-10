MysticExtended = LibStub("AceAddon-3.0"):NewAddon("MysticExtended", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0", "AceComm-3.0")
local ME = LibStub("AceAddon-3.0"):GetAddon("MysticExtended")
local icon = LibStub('LibDBIcon-1.0');
local addonName, addonTable = ...
MYSTICEXTENDED_MINIMAP = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(addonName, {
    type = 'data source',
    text = "MysticExtended",
    icon = 'Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1',
  })

local minimap = MYSTICEXTENDED_MINIMAP
MysticExtended_DewdropMenu = AceLibrary("Dewdrop-2.0");
MysticExtended_MiniMapMenu = AceLibrary("Dewdrop-2.0");
local realmName = GetRealmName();
--Set Savedvariables defaults
local RollExtracts = false;
local bagnonGuildbank = false;
local mysticMastro = false;
MYSTICEXTENDED_ITEMSET = false;

local DefaultMysticExtendedDB  = {
["EnchantSaveLists"] = {[1] = {["Name"] = "Enchant List 1", [realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false}}},
["ReRollItems"] = {18863, 18853,6992720},
["ListFrameLastState"] = false,
["currentSelectedList"] = 1,
["RollByQuality"] = true,
["ButtonEnable"] = true,
["QualityList"] = {
    {true,true,true,true},  --Roll Quality
    {true,true,true,true},  --Unknown Quality
    {true,true,true,true},  --Extract Frame Quality
},
["REFORGE_RETRY_DELAY"] = 5,
["ShowInCity"] = false,
["MinGold"] = 20000
};

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

    for _, v in ipairs(ME.db.EnchantSaveLists) do
        for a, b in ipairs(v) do
            if b[1] == enchantID and getStates(v) then
                return true
            end
        end
    end
end

--returns if the item needs to be reforged or not
function ME:RollCheck(bagID, slotID, extractoff)
    if RollExtracts then return true end
    local enchantID = GetREInSlot(bagID, slotID)
    if not enchantID then return true end
    local extractCount = GetItemCount(98463)
        if (ME.db.UnknownAutoExtract and extractCount and (extractCount > 0) and not IsReforgeEnchantmentKnown(enchantID) and ME:DoRarity(enchantID,2)) or
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

local AutoOn = false;
local reFound = false;
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
    AutoOn = false;
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
            ME:RemoveFound(RE.enchantID)
            MysticExtendedExtractCountText:SetText(string.format("Mystic Extracts: |cffFFFFFF%i|r", GetItemCount(98463)))
        elseif arg1 == "ASCENSION_REFORGE_PROGRESS_UPDATE" then
            --Shows how many more enchants to level up your atlar
            local xpGained = arg2 - ME.db.lastXpLevel[realmName]
            local nextLevel = (GetRequiredRollsForLevel(arg3) - arg2) / xpGained
            ME.db.lastItemXpLevel[realmName] = math.floor(nextLevel) + 1
            MysticExtendedNextLevelText:SetText("Next Altar Level in "..(math.floor(nextLevel) + 1).." Enchants")
            ME.db.lastXpLevel[realmName] = arg2
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
function ME:GetItemID(bagID, slotID, item)
    if not item and bagID and slotID then
        item = GetContainerItemID(bagID, slotID);
    end
    for i , v in pairs(ME.db.ReRollItems) do
        if v == item then
            return true;
        end
    end
end

--removes item from a list if you know it allready or just disenchanted it
function ME:RemoveFound(enchantID)
    local function findEnchantID(table)
        for i, v in ipairs(table) do
            if v[1] == enchantID then
                return true, i
            end
        end
    end

    for _,v in pairs(ME.db.EnchantSaveLists) do
        if v[realmName].enableDisenchant or v[realmName].enableRollExt then
            local remove, ID = findEnchantID(v)
                if remove then
                    tremove(v,ID)
                    if ME.db.ChatMSG then
                        local itemLink = ME:CreateItemLink(enchantID)
                        DEFAULT_CHAT_FRAME:AddMessage(itemLink .. " Has been added to your collection and removed from |cFF00FFFF".. v.Name .. " |cfffffffflist")
                    end
                end
        end
    end


        MysticExtended_ScrollFrameUpdate()
end

function ME:ExtractEnchant(bagID,slotID,enchantID)
    --checks to see if you have any mystic extracts
    if GetItemCount(98463) and (GetItemCount(98463) > 0) then
        --checks to see if you know the enchant if not extract and remove from list
        if IsReforgeEnchantmentKnown(enchantID) then
            ME:RemoveFound(enchantID)
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
            if ME:GetItemID(bagID,slotID) then
                 if ME:RollCheck(bagID, slotID) then
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
        reforge = ME:RollCheck(MYSTICEXTENDED_BAGID, MYSTICEXTENDED_SLOTID, true)
        bagID, slotID = MYSTICEXTENDED_BAGID, MYSTICEXTENDED_SLOTID
        if not reforge then
            reFound = true
        end
    else
        bagID, slotID, reforge = FindNextItem();
    end


    --show run count down
    MysticExtendedNextLevelText:SetText("Next Altar Level in "..(ME.db.lastItemXpLevel[realmName]).." Enchants")
    MysticExtendedNextLevelText:Show()
    MysticExtendedCountDownFrame:Show()
    MysticExtendedCountDownText:SetText("You Have " .. GetItemCount(98462) .. " Runes Left")
    -- check if rolling hasnt been stoped or we have enough runes
    if AutoOn and GetItemCount(98462) > 0 and GetUnitSpeed("player") == 0 and reforge and not reFound then
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
local function MysticExtended_StartAutoRoll()
    if AutoOn then
        ME:StopAutoRoll();
    else
        if not MysticEnchantingFrame:IsVisible() then
            MysticEnchantingFrame:UnregisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
        end
        if IsMounted() then Dismount() end
        AutoOn = true;
        MysticExtendedFrame_Menu_Icon_Breathing:Show();
        MysticExtended_ListFrameReforgeButton:SetText("Auto Reforging");
        MysticExtendedFrame_Menu.Text:SetText("|cffffffffAuto\nForging");
        ME:RollEnchant();

    end
end

local function QualityEnable(enable)
    if ME.db[enable] then
        ME.db[enable] = false;
    else
        ME.db[enable] = true;
    end
end

local function QualitySet(listNum,quality)
    if ME.db.QualityList[listNum][quality] then
        ME.db.QualityList[listNum][quality] = false;
    else
        ME.db.QualityList[listNum][quality] = true;
    end
end

local function EnableClick(list,cat,cat2)
    if ME.db.EnchantSaveLists[list][realmName][cat] then
        ME.db.EnchantSaveLists[list][realmName][cat] = false;
    else
        ME.db.EnchantSaveLists[list][realmName][cat] = true;
        if cat2 then
            ME.db.EnchantSaveLists[list][realmName][cat2] = false;
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

local function RollExtractsEnable()
    if RollExtracts then
        RollExtracts = false;
    else
        RollExtracts = true;
    end
end

local function realmCheck(table)
    if table[realmName] then return end
    table[realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false};    
end

function ME:RollMenuRegister(self)
	MysticExtended_DewdropMenu:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Select Lists to Roll",
                    'hasArrow', true,
                    'value', ME.db.EnchantSaveLists,
                    'notCheckable', true
                )
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Auto Extract Unknown",
                    'hasArrow', true,
                    'value', "extractUnknown",
                    'notCheckable', true
                )
                if mysticMastro then
                    MysticExtended_DewdropMenu:AddLine(
                        'text', "Reforge Based On Auction Price",
                        'hasArrow', true,
                        'value', "mysticMastro",
                        'notCheckable', true
                    )
                end
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Roll Quality",
                    'hasArrow', true,
                    'value', "RollQuality",
                    'notCheckable', true
                )
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Roll For Extracts",
                    'value', "RollExtracts",
                    'hasArrow', true,
                    'notCheckable', true
                )
                MysticExtended_DewdropMenu:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'func', function() MysticExtended_DewdropMenu:Close() end,
					'notCheckable', true
				)
            elseif level == 2 then
                if value == "extractUnknown" then
                    MysticExtended_DewdropMenu:AddLine(
                            'text', "Enable",
                            'func', QualityEnable,
                            'arg1', "UnknownAutoExtract",
                            'checked', ME.db.UnknownAutoExtract
                        )
                    for k,v in ipairs(ME.QualityList) do
                        local qualityColor = select(4,GetItemQualityColor(v[2]))
                        MysticExtended_DewdropMenu:AddLine(
                            'text', qualityColor..v[1],
                            'arg1', 2,
                            'arg2', k,
                            'func', QualitySet,
                            'checked', ME.db.QualityList[2][k]
                        )
                    end
                elseif value == "mysticMastro" then
                    MysticExtended_DewdropMenu:AddLine(
                            'text', "Enable",
                            'func', QualityEnable,
                            'arg1', "mysticMastro",
                            'checked', ME.db.mysticMastro
                        )
                elseif value == "RollQuality" then
                    MysticExtended_DewdropMenu:AddLine(
                            'text', "Enable",
                            'func', QualityEnable,
                            'arg1', "RollByQuality",
                            'checked', ME.db.RollByQuality
                        )
                    for k,v in ipairs(ME.QualityList) do
                        local qualityColor = select(4,GetItemQualityColor(v[2]))
                        MysticExtended_DewdropMenu:AddLine(
                            'text', qualityColor..v[1],
                            'arg1', 1,
                            'arg2', k,
                            'func', QualitySet,
                            'checked', ME.db.QualityList[1][k]
                        )
                    end
                elseif value == ME.db.EnchantSaveLists then
                    for i,v in ipairs(value) do
                        realmCheck(v);
                        MysticExtended_DewdropMenu:AddLine(
                            'text', v.Name,
                            'hasArrow', true,
                            'value', {v,i},
                            'notCheckable', true
                        )
                    end
                elseif value == "RollExtracts" then
                    MysticExtended_DewdropMenu:AddLine(
                            'text', "Enable",
                            'checked', RollExtracts,
                            'func', RollExtractsEnable
                        )
                    MysticExtended_DewdropMenu:AddLine(
                        'text', "When this option is enabled it will ignore all",
                        'notCheckable', true
                    )
                    MysticExtended_DewdropMenu:AddLine(
                        'text', "other rolling options and just roll on the",
                        'notCheckable', true
                    )
                    MysticExtended_DewdropMenu:AddLine(
                        'text', "first item it finds till you run out of runes",
                        'notCheckable', true
                    )
                end
                MysticExtended_DewdropMenu:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'func', function() MysticExtended_DewdropMenu:Close() end,
					'notCheckable', true
				)
            elseif level == 3 then
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Enable List",
                    'arg1', value[2],
                    'arg2', "enableRoll",
                    'arg3', "enableRollExt",
                    'func', EnableClick,
                    'checked', value[1][realmName]["enableRoll"]
                )
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Enable Only When You Have Extracts",
                    'arg1', value[2],
                    'arg2', "enableRollExt",
                    'arg3', "enableRoll",
                    'func', EnableClick,
                    'checked', value[1][realmName]["enableRollExt"]
                )
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Disenchant to Collection and remove from list",
                    'arg1', value[2],
                    'arg2', "enableDisenchant",
                    'arg3', "ignoreList",
                    'func', EnableClick,
                    'checked', value[1][realmName]["enableDisenchant"]
                )
                MysticExtended_DewdropMenu:AddLine(
                    'text', "ReRoll items on this list when found",
                    'arg1', value[2],
                    'arg2', "ignoreList",
                    'arg3', "enableDisenchant",
                    'func', EnableClick,
                    'checked', value[1][realmName]["ignoreList"]
                )
                MysticExtended_DewdropMenu:AddLine(
				    'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
				    'func', function() MysticExtended_DewdropMenu:Close() end,
				    'notCheckable', true
				)
            end
		end,
		'dontHook', true
	)
end

function MysticExtended_OnClick(self, arg1)
    if MysticExtended_DewdropMenu:IsOpen() then
        MysticExtended_DewdropMenu:Close();
    else
        if (arg1 == "LeftButton") then
            MysticExtended_StartAutoRoll();
        elseif (arg1 == "RightButton") then
            if IsAltKeyDown() then
                MysticEnchantingFrame:Display();
            else
                ME:RollMenuRegister(self);
                MysticExtended_DewdropMenu:Open(this);
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
    --[[ mainframe:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = "true",
        insets = {left = "11", right = "12", top = "12", bottom = "11"},
        edgeSize = 32,
        titleSize = 32,
    }); ]]
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

local function CloneTable(t) -- return a copy of the table t
    local new = {}; -- create a new table
    local i, v = next(t, nil); -- i is an index of t, v = t[i]
    while i do
        if type(v) == "table" then
            v = CloneTable(v);
        end
        new[i] = v;
        i, v = next(t, i); -- get next index
    end
    return new;
end
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
    if (MysticExtendedDB == nil) then
        MysticExtendedDB = CloneTable(DefaultMysticExtendedDB);
    end
    ME.db = MysticExtendedDB
    realmName = GetRealmName();
    for _, v in ipairs(ME.db.EnchantSaveLists) do
        if v[realmName] == nil then
            v[realmName] = { ["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false };
        end
        --clean up for old settings
        if type(v.enableDisenchant) == "boolean" then
            v.enableDisenchant = nil;
        end
        if type(v.enableRoll) == "boolean" then
            v.enableRoll = nil;
        end
        if type(v.ignoreList) == "boolean" then
            v.enableRoll = nil;
        end
    end

    --Enable the use of /al or /atlasloot to open the loot browser
    SLASH_MYSTICEXTENDED1 = "/mysticextended";
    SLASH_MYSTICEXTENDED2 = "/me";
    SlashCmdList["MYSTICEXTENDED"] = function(msg)
        MysticExtended_SlashCommand(msg);
    end

    if ME.db.Version == nil or ME.db.Version < 110 then
        ME.db.Version = 110;
        local data = {};
        for _, v in pairs(ME.db.EnchantSaveLists) do
            tinsert(data, v);
        end
        ME.db.EnchantSaveLists = {};
        for _, v in ipairs(data) do
            tinsert(ME.db.EnchantSaveLists, v);
        end
        ME.db.currentSelectedList = 1;
    end

    if ME.db.Version == nil or ME.db.Version < 130 then
        ME.db.Version = 130
        local data = {[1] = {},[2] = {}, [3] = {}}
        for _,v in ipairs(ME.db.QualityList) do
           tinsert(data[1],v[2])
           tinsert(data[2],true)
           tinsert(data[3],v[4])
        end
        ME.db.QualityList = {}
        for i, v in ipairs(data) do
            ME.db.QualityList[i] = v
        end

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
                if enchantID and ME:GetItemID(bagID, slotID) and
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
                if ME:GetItemID(nil, nil, id) then
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
    MysticExtended_ListEnable();
    MysticExtended_DropDownInitialize();
    if ME.db.AllowShareEnchantListInCombat then
        MysticExtendedOptions_EnableShareCombat:SetChecked(true);
    else
        MysticExtendedOptions_EnableShareCombat:SetChecked(false);
    end

    if ME.db.AllowShareEnchantList then
        MysticExtendedOptions_EnableShare:SetChecked(true);
    else
        MysticExtendedOptions_EnableShare:SetChecked(false);
    end

    if not ME.db.UnknownAutoExtract then
        ME.db.UnknownAutoExtract = false
    end

    if ME.db.REFORGE_RETRY_DELAY == nil then
        ME.db.REFORGE_RETRY_DELAY = 5;
    end

    if ME.db.ButtonEnable then
        MysticExtendedOptions_FloatSetting:SetChecked(true);
    else
        MysticExtendedOptions_FloatSetting:SetChecked(false);
    end

    if ME.db.AutoMysticScrollBloodforge then
        --MysticExtendedOptions_AutoMysticScrollBloodforge:SetChecked(true);
        ME:RegisterEvent("GOSSIP_SHOW", MysticExtended.BloodyJarOpen);
    else
        --MysticExtendedOptions_AutoMysticScrollBloodforge:SetChecked(false);
    end

    if ME.db.ChatMSG == nil or ME.db.ChatMSG then
        MysticExtendedOptions_ChatMSG:SetChecked(true);
        ME.db.ChatMSG = true;
    else
        MysticExtendedOptions_ChatMSG:SetChecked(false);
    end

    if ME.db.ShowUnknown then
        MysticExtendedExtract_ShowUnknown:SetChecked(true);
        ME.db.ShowUnknown = true;
    else
        MysticExtendedExtract_ShowUnknown:SetChecked(false);
    end

    if ME.db.ExtractWarn == nil or ME.db.ExtractWarn then
        MysticExtendedOptions_ExtractWarning:SetChecked(true);
        ME.db.ExtractWarn = true;
    else
        MysticExtendedOptions_ExtractWarning:SetChecked(false);
    end

    if not ME.db.lastXpLevel then ME.db.lastXpLevel = {} end
    if not ME.db.lastXpLevel[realmName] then ME.db.lastXpLevel[realmName] = 0 end
    if not ME.db.lastItemXpLevel then ME.db.lastItemXpLevel = {} end
    if not ME.db.lastItemXpLevel[realmName] then ME.db.lastItemXpLevel[realmName] = 0 end

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

    if not ME.db.MinGold then
        ME.db.MinGold = 20000
    end

    if select(4,GetAddOnInfo('Bagnon_GuildBank')) then bagnonGuildbank = true end
    if select(4,GetAddOnInfo('MysticMaestro')) then
        mysticMastro = true
        MysticExtended_MoneyFrame:Show()
    end
    MoneyInputFrame_SetCopper(MysticExtended_MoneyFrame,MysticExtendedDB.MinGold)
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
        if MysticExtended_MiniMapMenu:IsOpen() then
            MysticExtended_MiniMapMenu:Close();
        else
            ME:MiniMapMenuRegister(self);
            MysticExtended_MiniMapMenu:Open(this);
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
    MysticExtended_MiniMapMenu:Close();
end

function ME:MiniMapMenuRegister(self)
	MysticExtended_MiniMapMenu:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                MysticExtended_MiniMapMenu:AddLine(
                    'text', "Show/Hide Floating Button",
                    'func', toggleFloatingbutton,
                    'notCheckable', true
                )
                MysticExtended_MiniMapMenu:AddLine(
                    'text', "Options",
                    'func', ME.OptionsToggle,
                    'notCheckable', true
                )
                MysticExtended_MiniMapMenu:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'func', function() MysticExtended_MiniMapMenu:Close() end,
					'notCheckable', true
				)
            end
		end,
		'dontHook', true
	)
end
