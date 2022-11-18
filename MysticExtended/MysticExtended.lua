MysticExtended = LibStub("AceAddon-3.0"):NewAddon("MysticExtended", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0", "AceComm-3.0")

MysticExtended_DewdropMenu = AceLibrary("Dewdrop-2.0");
local realmName = GetRealmName();
--Set Savedvariables defaults
local RollExtracts = false;
local DefaultMysticExtendedDB  = {
["EnchantSaveLists"] = {[1] = {["Name"] = "Enchant List 1", [realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false}}},
["ReRollItems"] = {18863, 18853,992720},
["ListFrameLastState"] = false,
["currentSelectedList"] = 1,
["RollByQuality"] = true,
["ButtonEnable"] = true,
["QualityList"] = {
    [1] = {"Uncommon",true,2},
    [2] = {"Rare",true,3},
    [3] = {"Epic",true,4},
    [4] = {"Legendary",true,5}
},
["REFORGE_RETRY_DELAY"] = 5,
};

local function MysticExtended_DoSaveList(bagID, slotID)
    local enchantID = GetREInSlot(bagID, slotID)
        for i , v in ipairs(MysticExtendedDB["EnchantSaveLists"]) do
            if v[realmName]["enableRoll"] then
                for a , b in ipairs(v) do
                    if b[1] == enchantID then
                        return i,a,v[realmName]["enableDisenchant"],v[realmName]["enableRoll"],v[realmName]["ignoreList"]
                    end
                end
            end
        end
end

local function checkRaritys(quality)
    for i , v in pairs(MysticExtendedDB["QualityList"]) do
        if v[3] == quality and v[2] then
            return true;
        end
    end
end

local function MysticExtended_DoRarity(bagID, slotID)
    local enchantID = GetREInSlot(bagID, slotID)
        if MysticExtendedDB.RollByQuality then
            for i , v in pairs(MYSTIC_ENCHANTS) do
                if v.enchantID == enchantID and checkRaritys(v.quality) then
                    return true;
                end
            end
        end
end

local AutoOn = false;

function MysticExtended:Repeat()
    MysticExtended_RollEnchant();
end

local function MysticExtended_StopAutoRoll()
    MysticExtended:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
    MysticExtended:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    MysticEnchantingFrame:RegisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
    MysticExtended:CancelTimer(MysticExtended.rollTimer);
    MysticExtended_ListFrameReforgeButton:SetText("Start Reforge");
    MysticExtendedFrame_Menu.Text:SetText("|cffffffffStart\nReforge");
    MysticExtendedCountDownText:SetText("");
    MysticExtendedCountDownFrame:Hide();
    MysticExtendedFrame_Menu_Icon_Breathing:Hide();
    AutoOn = false;
end

local function EventHandler(event, unitID, spell)
    if unitID == "player" and spell == "Enchanting" then
        if event == "UNIT_SPELLCAST_INTERRUPTED" then
            MysticExtended_StopAutoRoll();
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            MysticExtended:CancelTimer(MysticExtended.rollTimer);
            MysticExtended:ScheduleTimer(MysticExtended_RollEnchant, tonumber(MysticExtendedDB["REFORGE_RETRY_DELAY"] / 10));
        end
        MysticExtended:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        MysticExtended:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    end
end

local function MysticExtended_GetItemID(bagID, slotID)
    if bagID and slotID then
        local item = GetContainerItemID(bagID, slotID);
            for i , v in pairs(MysticExtendedDB["ReRollItems"]) do
                if v == item then
                    return true;
                end
            end
    end
end

local function MysticExtended_RemoveFound(bagID, slotID)
    local listName,enchNum = MysticExtended_DoSaveList(bagID,slotID)
    table.remove(MysticExtendedDB["EnchantSaveLists"][listName],enchNum)
end

local function DisenchantItem(bagID,slotID)
    if GetItemCount(98463) and (GetItemCount(98463) > 0) then
        if IsReforgeEnchantmentKnown(GetREInSlot(bagID,slotID)) then
            DEFAULT_CHAT_FRAME:AddMessage("You already know this enchant removed from list");
            MysticExtended_RemoveFound(bagID,slotID);
        else
            MysticExtended_RemoveFound(bagID,slotID);
            RequestSlotReforgeExtraction(bagID, slotID);
            local itemLink = MysticExtended:CreateItemLink(GetREInSlot(bagID,slotID));
            DEFAULT_CHAT_FRAME:AddMessage(itemLink.." Has been added to your collection and removed from the list");
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("You don't have enough Mystic Extract to disenchant that item")
    end
end

local function MysticExtended_FindNextItem()
    local bagID, slotID = 0, 0;
    for b = bagID, 4 do
        for s = slotID + 1, GetContainerNumSlots(b) do
            if MysticExtended_GetItemID(b,s) then
                local listName,enchNum,enableDisenchant,enableRoll,ignoreList = MysticExtended_DoSaveList(b,s)
                    if RollExtracts then
                        return b, s;
                    elseif enableRoll and ignoreList ~= true then
                        if enableDisenchant then
                            DisenchantItem(b,s);
                            MysticExtended_ScrollFrameUpdate();
                        end
                    elseif  enableRoll and ignoreList then
                        return b, s;
                    elseif MysticExtended_DoRarity(b,s) then
                    else
                        return b, s;
                    end
            end
        slotID = s;
        end
    slotID = 0;
    end
end

function MysticExtended_RollEnchant()
    local bagID, slotID = MysticExtended_FindNextItem();
        MysticExtendedCountDownFrame:Show();
        MysticExtendedCountDownText:SetText("You Have "..GetItemCount(98462).." Runes Left");
    if AutoOn and GetItemCount(98462) > 0 and MysticExtended_GetItemID(bagID, slotID) and GetUnitSpeed("player") == 0 then
        MysticExtended:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", EventHandler);
        MysticExtended:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", EventHandler);
        MysticExtended.rollTimer = MysticExtended:ScheduleTimer("Repeat", 3);
        local listName,enchNum,enableDisenchant,enableRoll,ignoreList = MysticExtended_DoSaveList(bagID,slotID)
        if RollExtracts then
            RequestSlotReforgeEnchantment(bagID, slotID);
        elseif enableRoll and ignoreList ~= true then
        elseif enableRoll and ignoreList then
            RequestSlotReforgeEnchantment(bagID, slotID);
        elseif MysticExtended_DoRarity(bagID,slotID) then else
            RequestSlotReforgeEnchantment(bagID, slotID);
        end
    else
        if GetItemCount(98462) <= 0 then
            DEFAULT_CHAT_FRAME:AddMessage("Out Runes")
        elseif GetUnitSpeed("player") == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("Out of Items to Reforge")
        end
        MysticExtended_StopAutoRoll();
    end
end

local function MysticExtended_StartAutoRoll()
    if AutoOn then
        MysticExtended_StopAutoRoll();
    else
        if not MysticEnchantingFrame:IsVisible() then
            MysticEnchantingFrame:UnregisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
        end
        if IsMounted() then Dismount() end
        AutoOn = true;
        MysticExtendedFrame_Menu_Icon_Breathing:Show();
        MysticExtended_ListFrameReforgeButton:SetText("Auto Reforging");
        MysticExtendedFrame_Menu.Text:SetText("|cffffffffAuto\nForging");
        MysticExtended_RollEnchant();

    end
end

local function QualityEnable()
    if MysticExtendedDB["RollByQuality"] then
        MysticExtendedDB["RollByQuality"] = false;
    else
        MysticExtendedDB["RollByQuality"] = true;
    end
end

local function QualitySet(tablenum,state)
    if state then
        MysticExtendedDB["QualityList"][tablenum][2] = false;
    else
        MysticExtendedDB["QualityList"][tablenum][2] = true;
    end
end

local function EnableClick(list,cat,cat2)
    if MysticExtendedDB["EnchantSaveLists"][list][realmName][cat] then
        MysticExtendedDB["EnchantSaveLists"][list][realmName][cat] = false;
    else
        MysticExtendedDB["EnchantSaveLists"][list][realmName][cat] = true;
        if cat2 then
            MysticExtendedDB["EnchantSaveLists"][list][realmName][cat2] = false;
        end
    end
end

function MysticExtended:ButtonEnable()
    if MysticExtendedDB["ButtonEnable"] then
        MysticExtendedFrame:Hide();
        MysticExtendedFrame_Menu:Hide();
        MysticExtendedDB["ButtonEnable"] = false
    else
        MysticExtendedFrame:Show();
        MysticExtendedFrame_Menu:Show();
        MysticExtendedDB["ButtonEnable"] = true
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

function MysticExtended:RollMenuRegister(self)
	MysticExtended_DewdropMenu:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Select Lists to Roll",
                    'hasArrow', true,
                    'value', MysticExtendedDB["EnchantSaveLists"],
                    'notCheckable', true
                )
                MysticExtended_DewdropMenu:AddLine(
                    'text', "Roll Quality",
                    'hasArrow', true,
                    'value', MysticExtendedDB["QualityList"],
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
				if value == MysticExtendedDB["QualityList"] then
                    MysticExtended_DewdropMenu:AddLine(
                            'text', "Enable",
                            'func', QualityEnable,
                            'checked', MysticExtendedDB["RollByQuality"]
                        )
                    for k,v in ipairs(value) do
                        local _, _, _, qualityColor = GetItemQualityColor(v[3])
                        MysticExtended_DewdropMenu:AddLine(
                            'text', qualityColor..v[1],
                            'arg1', k,
                            'arg2', v[2],
                            'func', QualitySet,
                            'checked', v[2]
                        )
                    end
                elseif value == MysticExtendedDB["EnchantSaveLists"] then
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
                    'func', EnableClick,
                    'checked', value[1][realmName]["enableRoll"]
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

function MysticExtended_OnClick(self,arg1)
    if MysticExtended_DewdropMenu:IsOpen() then
        MysticExtended_DewdropMenu:Close();
    else
        if (arg1=="LeftButton") then
            MysticExtended_StartAutoRoll();
        elseif (arg1=="RightButton") then
            if IsAltKeyDown() then
                MysticEnchantingFrame:Display();
            else
            MysticExtended:RollMenuRegister(self);
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
    reforgebutton:SetScript("OnClick", function(self, btnclick, down) MysticExtended_OnClick(self,btnclick) end);
    reforgebutton:SetScript("OnEnter", function()
        reforgebutton.Highlight:Show();
        if IsShiftKeyDown() then
            MysticExtended_Secure:Show();
        else
            if not IsAltKeyDown() then GameTooltip:SetOwner(this, "ANCHOR_RIGHT") end
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
        GameTooltip:Hide();
    end);
    secureBttn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Left Click To Start Reforging");
        GameTooltip:AddLine("Shift Left Click To Drop An Atlar");
        GameTooltip:AddLine("Right Click To Show Roll Settings");
        GameTooltip:AddLine("Alt Right To Open Enchanting Frame");
        GameTooltip:Show();
	end);

function CloneTable(t)				-- return a copy of the table t
	local new = {};					-- create a new table
	local i, v = next(t, nil);		-- i is an index of t, v = t[i]
	while i do
		if type(v)=="table" then 
			v=CloneTable(v);
		end 
		new[i] = v;
		i, v = next(t, i);			-- get next index
	end
	return new;
end

function MysticExtended:OnInitialize()
    if ( MysticExtendedDB == nil ) then
        MysticExtendedDB = CloneTable(DefaultMysticExtendedDB);
    end
    realmName = GetRealmName();
    for _,v in ipairs(MysticExtendedDB["EnchantSaveLists"]) do
        if v[realmName] == nil then
            v[realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false};
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
    if MysticExtendedDB["Version"] == nil or MysticExtendedDB["Version"] < 110 then
        MysticExtendedDB["Version"] = 110;
        local data = {};
        for _,v in pairs(MysticExtendedDB["EnchantSaveLists"]) do
            tinsert(data, v);
        end
        MysticExtendedDB["EnchantSaveLists"] = {};
        for _,v in ipairs(data) do
            tinsert(MysticExtendedDB["EnchantSaveLists"], v);
        end
        MysticExtendedDB["currentSelectedList"] = 1;
    end
    MysticExtended:RegisterComm("MysticExtendedEnchantList")
end

function MysticExtended:OnEnable()
    MysticExtended_ListEnable();
    MysticExtended_DropDownInitialize();
    if MysticExtendedDB["AllowShareEnchantListInCombat"] then
        MysticExtendedOptions_EnableShareCombat:SetChecked(true);
    else
        MysticExtendedOptions_EnableShareCombat:SetChecked(false);
    end
    if MysticExtendedDB["AllowShareEnchantList"] then
        MysticExtendedOptions_EnableShare:SetChecked(true);
    else
        MysticExtendedOptions_EnableShare:SetChecked(false);
    end
    if MysticExtendedDB["REFORGE_RETRY_DELAY"] == nil then
        MysticExtendedDB["REFORGE_RETRY_DELAY"] = 5;
    end
    if MysticExtendedDB["ButtonEnable"] then
        MysticExtendedFrame:Show();
        MysticExtendedFrame_Menu:Show();
        MysticExtendedOptions_FloatSetting:SetChecked(true);
    else
        MysticExtendedOptions_FloatSetting:SetChecked(false);
    end
    if MYSTIC_ENCHANTS then
        for k,v in pairs(MYSTIC_ENCHANTS) do
            if v.enchantID ~= 0 then
               v.spellName = GetSpellInfo(v.spellID)
            end
         end
    end
    MysticExtended_DelaySlider:SetValue(MysticExtendedDB["REFORGE_RETRY_DELAY"]);
end