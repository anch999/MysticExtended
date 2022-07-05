local MysticExtended, MEx = ...
local addonName = "MysticExtended";
_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")
local addon = _G[addonName];

MysticExtended_Dewdrop = AceLibrary("Dewdrop-2.0");

--Set Savedvariables defaults
local DefaultMysticExtendedDB  = {
["EnchantSaveList"] = {},
["ReRollItems"] = {18863, 18853},
["ListFrameLastState"] = false
};

local function MysticExtended_DoSaveList(bagID, slotID)
    local enchantID = GetREInSlot(bagID, slotID)
        for i , v in pairs(MysticExtendedDB["EnchantSaveList"]) do
            if v == enchantID then
                return true;
            end
        end
end

local function MysticExtended_DoRarity(bagID, slotID)
    local enchantID = GetREInSlot(bagID, slotID)
        for i , v in pairs(MYSTIC_ENCHANTS) do
            if v.enchantID == enchantID and v.quality >= 3 then
                return true;
            end
        end
end

local AutoOn = false;
local REFORGE_RETRY_DELAY = 0.3; -- seconds

local function EventHandler(event, unitID, spell)
    if unitID == "player" and spell == "Enchanting" then
        if event == "UNIT_SPELLCAST_INTERRUPTED" then
            AutoOn = false;
            MysticExtendedFrame_Menu:SetText("Start Reforge");
            MysticExtended_ListFrameReforgeButton:SetText("Start Reforge");
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            addon:ScheduleTimer(MysticExtended_RollEnchant, REFORGE_RETRY_DELAY);
        end
        addon:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
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

local function MysticExtended_FindNextItem()
    local bagID, slotID = 0, 0;
    for b = bagID, 4 do
        for s = slotID + 1, GetContainerNumSlots(b) do
            if MysticExtended_GetItemID(b,s) then
                if MysticExtended_DoRarity(b,s) or MysticExtended_DoSaveList(b,s) then else
                    return b, s;
                end
            end
        slotID = s;
        end
    slotID = 0;
    end
end

local function MysticExtended_StopAutoRoll()
    addon:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
    addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    MysticExtendedFrame_Menu:SetText("Start Reforge");
    MysticExtended_ListFrameReforgeButton:SetText("Start Reforge");
    AutoOn = false;
end

function MysticExtended_RollEnchant()
local bagID, slotID = MysticExtended_FindNextItem();
    if AutoOn and GetItemCount(98462) >= 1 and MysticExtended_GetItemID(bagID, slotID) then
        addon:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", EventHandler);
        addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", EventHandler);
        if MysticExtended_DoRarity(bagID,slotID) or MysticExtended_DoSaveList(bagID,slotID) then else
            RequestSlotReforgeEnchantment(bagID, slotID);
        end
    else
        if GetItemCount(98462) <= 1 then
            print("Out Runes")
        else
            print("Out off Items to Reforge")
        end
        MysticExtended_StopAutoRoll();
    end
end

local function MysticExtended_StartAutoRoll()
    if AutoOn then
        MysticExtended_StopAutoRoll();
    else
        AutoOn = true;
        MysticExtendedFrame_Menu:SetText("Auto Reforging");
        MysticExtended_ListFrameReforgeButton:SetText("Auto Reforging");
        MysticExtended_RollEnchant();
    end
end

function MysticExtended_OnClick(arg1)
    if MysticExtended_Dewdrop:IsOpen() then
        MysticExtended_Dewdrop:Close();
    else
        if (arg1=="LeftButton") then
            MysticExtended_StartAutoRoll();
        elseif (arg1=="RightButton") then
            MysticExtended_DewdropRegister();
            MysticExtended_Dewdrop:Open(this);
        end
    end
end

--Creates the main floating button
local mainframe = CreateFrame("FRAME", "MysticExtendedFrame", UIParent, nil);
   mainframe:SetPoint("CENTER",0,0);
   mainframe:SetSize(120,50);
   mainframe:EnableMouse(true);
   mainframe:SetMovable(true);
   mainframe:SetBackdrop({
       bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
       edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
       tile = "true",
       insets = {left = "11", right = "12", top = "12", bottom = "11"},
       edgeSize = 32,
       titleSize = 32,
   });
   mainframe:RegisterForDrag("LeftButton");
   mainframe:SetScript("OnDragStart", function(self) mainframe:StartMoving() end)
   mainframe:SetScript("OnDragStop", function(self) mainframe:StopMovingOrSizing() end)

local reforgebutton = CreateFrame("Button", "MysticExtendedFrame_Menu", MysticExtendedFrame, "OptionsButtonTemplate");
   reforgebutton:SetSize(100,30);
   reforgebutton:SetPoint("TOP", MysticExtendedFrame, "TOP", 0, -10);
   reforgebutton:SetText("Start Reforge");
   reforgebutton:RegisterForClicks("LeftButtonDown", "RightButtonDown");
   reforgebutton:SetScript("OnClick", function(self, btnclick, down) MysticExtended_OnClick(btnclick) end);

local function CloneTable(t)				-- return a copy of the table t
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

function addon:OnInitialize()
    if ( MysticExtendedDB == nil ) then
        MysticExtendedDB = CloneTable(DefaultMysticExtendedDB);
    end
end