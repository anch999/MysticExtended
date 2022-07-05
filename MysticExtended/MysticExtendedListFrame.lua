local mainframe = CreateFrame("FRAME", "MysticExtendedListFrame", MysticEnchantingFrame,"UIPanelDialogTemplate")
    mainframe:SetSize(400,508);
    mainframe:SetPoint("RIGHT", MysticEnchantingFrame, "RIGHT", 390, 0);
    mainframe.TitleText = mainframe:CreateFontString();
    mainframe.TitleText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    mainframe.TitleText:SetFontObject(GameFontNormal)
    mainframe.TitleText:SetText("Mystic Extended");
    mainframe.TitleText:SetPoint("TOP", 0, -9);
    mainframe.TitleText:SetShadowOffset(1,-1);
    mainframe:Hide();
    mainframe:SetScript("OnHide",
    function()
        if MysticEnchantingFrame:IsVisible() then
            MysticExtendedDB.ListFrameLastState = false;
            MysticExtended_ShowButton:SetText("Show MysticExtended");
        end
    end)

local function ItemTemplate_OnEnter(self)
    if self.link == nil then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -13, -50)
    GameTooltip:SetHyperlink(self.link)
    GameTooltip:Show()
end

local function ItemTemplate_OnLeave()
    GameTooltip:Hide()
end
---------------------ScrollFrame----------------------------------

local function GetSavedEnchant(id)
    for n in pairs(MysticExtendedDB["EnchantSaveList"]) do
        if MysticExtendedDB["EnchantSaveList"][n][1] == id then
            return n
        end
    end
end

local ROW_HEIGHT = 16;   -- How tall is each row?
local MAX_ROWS = 20;      -- How many rows can be shown at once?

local scrollFrame = CreateFrame("Frame", "MysticExtended_ScrollFrame", MysticExtendedListFrame);
    scrollFrame:EnableMouse(true);
    scrollFrame:SetSize(200, ROW_HEIGHT * MAX_ROWS + 16);
    scrollFrame:SetPoint("LEFT",20,0);
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });

 function scrollFrame:Update()
	local maxValue = #MysticExtendedDB["EnchantSaveList"]

	FauxScrollFrame_Update(self.scrollBar, maxValue, MAX_ROWS, ROW_HEIGHT);
	local offset = FauxScrollFrame_GetOffset(self.scrollBar);
	for i = 1, MAX_ROWS do
		local value = i + offset
		if value <= maxValue then
			local row = self.rows[i]
            local _, _, _, qualityColor = GetItemQualityColor(MYSTIC_ENCHANTS[MysticExtendedDB["EnchantSaveList"][value][1]].quality)
            row:SetText(qualityColor..MYSTIC_ENCHANTS[MysticExtendedDB["EnchantSaveList"][value][1]].spellName)
            row.enchantID = MysticExtendedDB["EnchantSaveList"][value][1]
            row.link = MysticExtendedDB["EnchantSaveList"][value][2]
			row:Show()
		else
			self.rows[i]:Hide()
		end
	end
end

local scrollSlider = CreateFrame("ScrollFrame","MysticExtendedListFrameScroll",MysticExtended_ScrollFrame,"FauxScrollFrameTemplate");
scrollSlider:SetPoint("TOPLEFT", 0, -8)
scrollSlider:SetPoint("BOTTOMRIGHT", -30, 8)
scrollSlider:SetScript("OnVerticalScroll", function(self, offset)
    self.offset = math.floor(offset / ROW_HEIGHT + 0.5)
        scrollFrame:Update()
end)

scrollSlider:SetScript("OnShow", function()
    scrollFrame:Update()
end)

scrollFrame.scrollBar = scrollSlider

local rows = setmetatable({}, { __index = function(t, i)
	local row = CreateFrame("Button", "$parentRow"..i, scrollFrame)
	row:SetSize(150, ROW_HEIGHT)
	row:SetNormalFontObject(GameFontHighlightLeft)
    row:SetScript("OnClick", function()
        local item = tonumber(row.enchantID)
        local itemNum = GetSavedEnchant(item)
        if MysticExtendedDB["EnchantSaveList"][itemNum] then
            table.remove(MysticExtendedDB["EnchantSaveList"],itemNum)
        end
        scrollFrame:Update()
    end)
    row:SetScript("OnEnter", function(self)
        ItemTemplate_OnEnter(self)
    end)
    row:SetScript("OnLeave", ItemTemplate_OnLeave)
	if i == 1 then
		row:SetPoint("TOPLEFT", scrollFrame, 8, -8)
	else
		row:SetPoint("TOPLEFT", scrollFrame.rows[i-1], "BOTTOMLEFT")
	end

	rawset(t, i, row)
	return row
end })

scrollFrame.rows = rows

hooksecurefunc("ChatEdit_InsertLink", function(link)
	if MysticExtendedListFrame:IsVisible() then
		local id = tonumber(link:match("spell:(%d+)"))
        id = MYSTIC_ENCHANT_SPELLS[id]
            if not GetSavedEnchant(id) then
                table.insert(MysticExtendedDB["EnchantSaveList"],{id,link})
                scrollFrame:Update()
            end
    return true
	end
end)

------------------------------------------------------------------
--Reforge button in list interface
local reforgebuttonlist = CreateFrame("Button", "MysticExtended_ListFrameReforgeButton", MysticExtendedListFrame, "OptionsButtonTemplate");
    reforgebuttonlist:SetSize(170,30);
    reforgebuttonlist:SetPoint("BOTTOMLEFT", MysticExtendedListFrame, "BOTTOMLEFT", 20, 20);
    reforgebuttonlist:SetText("Start Reforge");
    reforgebuttonlist:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    reforgebuttonlist:SetScript("OnClick", function(self, btnclick, down) MysticExtended_OnClick(btnclick) end);
--Show/Hide button in main list view
local showFrameBttn = CreateFrame("Button", "MysticExtended_ShowButton", MysticEnchantingFrame, "OptionsButtonTemplate");
    showFrameBttn:SetSize(165,26);
    showFrameBttn:SetPoint("TOP", MysticEnchantingFrame, "TOP", 265, -33);
    showFrameBttn:SetScript("OnClick", function()
        if MysticExtendedListFrame:IsVisible() then
            MysticExtendedListFrame:Hide();
            MysticExtendedDB.ListFrameLastState = false;
            showFrameBttn:SetText("Show MysticExtended");
        else
            showFrameBttn:SetText("Hide MysticExtended");
            MysticExtendedListFrame:Show();
            MysticExtendedDB.ListFrameLastState = true;
        end
    end)

--Moves Ascensions xp/search/sortmenu
local meFrame = MysticEnchantingFrame
    meFrame.ProgressBar:SetPoint("TOP", meFrame.TitleText,"BOTTOM", -200, -14)
    meFrame.SearchBox:SetPoint("TOPRIGHT", meFrame, -330, -33)
    meFrame.EnchantTypeList:SetPoint("TOPRIGHT", meFrame, -200, -32)

--Show list view when Mystic Enchanting frame opens
MysticEnchantingFrame:HookScript("OnShow",
        function()
            if MysticExtendedDB.ListFrameLastState then
                MysticExtendedListFrame:Show();
                showFrameBttn:SetText("Hide MysticExtended");
            else
                MysticExtendedListFrame:Hide();
                showFrameBttn:SetText("Show MysticExtended");
            end
        end)
--Hide it when it closes
MysticEnchantingFrame:HookScript("OnHide",
        function()
        MysticExtendedListFrame:Hide();
        end)
