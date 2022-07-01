local MysticExtended, SPM = ...
local addonName = "MysticExtended";
_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local addon = _G[addonName];

MysticExtended_Dewdrop = AceLibrary("Dewdrop-2.0");

--Set Savedvariables defaults
local DefaultMysticExtendedDB  = {
["EnchantSaveList"] = {}
};

local function MysticExtended_RollEnchant()

end

local function MysticExtended_OnClick(arg1)
    if MysticExtended_Dewdrop:IsOpen() then
        MysticExtended_Dewdrop:Close();
    else
        if (arg1=="LeftButton") then
            MysticExtended_RollEnchant();
        elseif (arg1=="RightButton") then
            MysticExtended_DewdropRegister();
            MysticExtended_Dewdrop:Open(this);
        end
    end
end

--Creates the main interface
local function MysticExtended_CreateFrame()
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
    reforgebutton:SetText("Reforge");
    reforgebutton:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    reforgebutton:SetScript("OnClick", function(self, btnclick, down) MysticExtended_OnClick(btnclick) end);
end

--[[ InterfaceOptionsFrame:HookScript("OnShow", function()
    if InterfaceOptionsFrame and MysticExtendedOptionsFrame:IsVisible() then
			MysticExtendedOptions_OpenOptions();
    end
end) ]]

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
        MysticExtended_CreateFrame();
      --  MysticExtendedOptions_CreateFrame();
       -- MysticExtendedOptions_OpenOptions();
end

function MysticExtendedFrame_OnClickHIDE()
    if SPM.FrameClosed then
        MysticExtendedFrame:Show();
        SPM.FrameClosed = false
    else
        MysticExtendedFrame:Hide();
        SPM.FrameClosed = true
    end
end