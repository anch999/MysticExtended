local mainframe = CreateFrame("FRAME", "MysticExtendedListFrame", MysticEnchantingFrame,"UIPanelDialogTemplate")
    mainframe:SetSize(305,508);
    mainframe:SetPoint("RIGHT", MysticEnchantingFrame, "RIGHT", 295, 0);
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
            MysticExtended_ShowButton:SetText("Show");
            MysticEnchantingFrame.MysticExtendedText:Show();
        end
    end)

MysticEnchantingFrame.MysticExtendedText = MysticEnchantingFrame:CreateFontString();
MysticEnchantingFrame.MysticExtendedText:SetFont("Fonts\\FRIZQT__.TTF", 12)
MysticEnchantingFrame.MysticExtendedText:SetFontObject(GameFontNormal)
MysticEnchantingFrame.MysticExtendedText:SetText("Mystic Extended");
MysticEnchantingFrame.MysticExtendedText:SetPoint("TOPRIGHT", -70, -11);
MysticEnchantingFrame.MysticExtendedText:SetShadowOffset(1,-1);

local realmName = GetRealmName();

local function setCurrentSelectedList()
    local thisID = this:GetID();
    MysticExtendedDB["currentSelectedList"] = thisID;
    UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,thisID);
    local update = MysticExtended_ScrollFrameUpdate();
        if update then
            MysticExtended_ScrollFrameUpdate();
        end
end

function MysticExtended:MenuInitialize()
        local info;
        for k,v in ipairs(MysticExtendedDB["EnchantSaveLists"]) do
                    info = {
                        text = v.Name;
                        func = function() setCurrentSelectedList() end;
                    };
                    UIDropDownMenu_AddButton(info);
        end
end

function MysticExtended_ListEnable()
    UIDropDownMenu_Initialize(MysticExtended_ListDropDown, MysticExtended.MenuInitialize);
	UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,MysticExtendedDB["currentSelectedList"]);
    local update = MysticExtended_ScrollFrameUpdate();
        if update then
            MysticExtended_ScrollFrameUpdate();
        end
end

StaticPopupDialogs["MYSTICEXTENDED_ADDLIST"] = {
    text = "Add New List?",
    button1 = "Confirm",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function (self, data, data2)
        local text = self.editBox:GetText()
        MysticExtendedDB["EnchantSaveLists"][text] = {["Name"] = text, [realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false}; }
        UIDropDownMenu_Initialize(MysticExtended_ListDropDown, MysticExtended.MenuInitialize);
        UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,#MysticExtendedDB["EnchantSaveLists"]);
        MysticExtendedDB["currentSelectedList"] = #MysticExtendedDB["EnchantSaveLists"];
        local update = MysticExtended_ScrollFrameUpdate();
        if update then
            MysticExtended_ScrollFrameUpdate();
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    enterClicksFirstButton = true,
}

StaticPopupDialogs["MYSTICEXTENDED_EDITLISTNAME"] = {
    text = "Edit Current List Name?",
    button1 = "Confirm",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function (self, data, data2)
        local text = self.editBox:GetText()
        if text ~= "" then
            MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]].Name = text;
            UIDropDownMenu_Initialize(MysticExtended_ListDropDown, MysticExtended.MenuInitialize);
            local update = MysticExtended_ScrollFrameUpdate();
            if update then
                MysticExtended_ScrollFrameUpdate();
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    enterClicksFirstButton = true,
}

StaticPopupDialogs["MYSTICEXTENDED_DELETELIST"] = {
    text = "Delete List?",
    button1 = "Confirm",
    button2 = "Cancel",
    OnAccept = function (self, data, data2)
        tremove(MysticExtendedDB["EnchantSaveLists"], MysticExtendedDB["currentSelectedList"]);
        UIDropDownMenu_Initialize(MysticExtended_ListDropDown, MysticExtended.MenuInitialize);
        UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,1);
        MysticExtendedDB["currentSelectedList"] = 1;
        local update = MysticExtended_ScrollFrameUpdate();
        if update then
            MysticExtended_ScrollFrameUpdate();
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    enterClicksFirstButton = true,
}

local function exportString()
    MysticExtended_OptionsMenu:Close();
    local data = {};
    for i,v in ipairs(MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]]) do
        tinsert(data,{v[1]});
    end
    data["Name"] = MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]]["Name"];
    Internal_CopyToClipboard("MEXT:"..MysticExtended:Serialize(data));
end

function MysticExtended:ListFrameMenuRegister(self)
	MysticExtended_OptionsMenu:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                MysticExtended_OptionsMenu:AddLine(
                    'text', "Send Current List",
                    'func', function() StaticPopup_Show("MYSTICEXTENDED_SEND_ENCHANTLIST",MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]].Name) end,
                    'notCheckable', true
                )
                MysticExtended_OptionsMenu:AddLine(
                    'text', "Export List",
                    'func', exportString,
                    'tooltip', "Exports a string to clipboard",
                    'notCheckable', true
                )
                MysticExtended_OptionsMenu:AddLine(
                    'text', "Import List",
                    'func', function() StaticPopup_Show("MYSTICEXTENDED_IMPORT_ENCHANTLIST") end,
                    'notCheckable', true
                )
                MysticExtended_OptionsMenu:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'func', function() MysticExtended_OptionsMenu:Close() end,
					'notCheckable', true
				)
            end
		end,
		'dontHook', true
	)
end

local listDropdown = CreateFrame("Button", "MysticExtended_ListDropDown", MysticExtendedListFrame, "UIDropDownMenuTemplate");
    listDropdown:SetPoint("TOPLEFT", 4, -40);
    listDropdown:SetScript("OnClick", MysticExtended_ListOnClick);
    UIDropDownMenu_SetWidth(MysticExtended_ListDropDown,155)

local editlistnamebtn = CreateFrame("Button", "MysticExtended_EditListBtn", MysticExtendedListFrame, "OptionsButtonTemplate");
    editlistnamebtn:SetPoint("TOPLEFT", 195, -41);
    editlistnamebtn:SetText("E")
    editlistnamebtn:SetSize(27, 27);
    editlistnamebtn:SetScript("OnClick", function() StaticPopup_Show("MYSTICEXTENDED_EDITLISTNAME") end);
    editlistnamebtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText("Edit List Name")
		GameTooltip:Show()
	end)
	editlistnamebtn:SetScript("OnLeave", function() GameTooltip:Hide() end)


local addlistbtn = CreateFrame("Button", "MysticExtended_AddListBtn", MysticExtendedListFrame, "OptionsButtonTemplate");
    addlistbtn:SetPoint("TOPLEFT", 225, -41);
    addlistbtn:SetText("+")
    addlistbtn:SetSize(27, 27);
    addlistbtn:SetScript("OnClick", function() StaticPopup_Show("MYSTICEXTENDED_ADDLIST") end);
    addlistbtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText("Create New List")
		GameTooltip:Show()
	end)
	addlistbtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local removelistbtn = CreateFrame("Button", "MysticExtended_RemoveListBtn", MysticExtendedListFrame, "OptionsButtonTemplate");
    removelistbtn:SetPoint("TOPLEFT", 255, -41);
    removelistbtn:SetText("-")
    removelistbtn:SetSize(27, 27);
    removelistbtn:SetScript("OnClick", function() StaticPopup_Show("MYSTICEXTENDED_DELETELIST") end);
    removelistbtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText("Remove List")
		GameTooltip:Show()
	end)
	removelistbtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

------------------ScrollFrameTooltips---------------------------
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
--Check to see if the enchant is allreay on the list
local function GetSavedEnchant(id)
    for n in ipairs(MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]]) do
        if MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][n][1] == id then
            return n
        end
    end
end

local ROW_HEIGHT = 16;   -- How tall is each row?
local MAX_ROWS = 23;      -- How many rows can be shown at once?

local scrollFrame = CreateFrame("Frame", "MysticExtended_ScrollFrame", MysticExtendedListFrame);
    scrollFrame:EnableMouse(true);
    scrollFrame:SetSize(265, ROW_HEIGHT * MAX_ROWS + 16);
    scrollFrame:SetPoint("LEFT",20,-8);
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });

function MysticExtended_ScrollFrameUpdate()
    local maxValue = #MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]]
	FauxScrollFrame_Update(scrollFrame.scrollBar, maxValue, MAX_ROWS, ROW_HEIGHT);
	local offset = FauxScrollFrame_GetOffset(scrollFrame.scrollBar);
	for i = 1, MAX_ROWS do
		local value = i + offset
        if not MYSTIC_ENCHANTS[MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][value][1]] then
            tremove(MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]],value);
            return true
        end
        scrollFrame.rows[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
		if value <= maxValue and MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][value] ~= nil then
			local row = scrollFrame.rows[i]
            local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][value][1]].quality))
            row:SetText(qualityColor..GetSpellInfo(MYSTIC_ENCHANTS[MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][value][1]].spellID))
            row.enchantID = MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][value][1]
            row.link = MysticExtended:CreateItemLink(MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][value][1])
			row:Show()
		else
			scrollFrame.rows[i]:Hide()
		end
	end
end

local scrollSlider = CreateFrame("ScrollFrame","MysticExtendedListFrameScroll",MysticExtended_ScrollFrame,"FauxScrollFrameTemplate");
scrollSlider:SetPoint("TOPLEFT", 0, -8)
scrollSlider:SetPoint("BOTTOMRIGHT", -30, 8)
scrollSlider:SetScript("OnVerticalScroll", function(self, offset)
    self.offset = math.floor(offset / ROW_HEIGHT + 0.5)
    local update = MysticExtended_ScrollFrameUpdate();
        if update then
            MysticExtended_ScrollFrameUpdate();
        end
end)

scrollSlider:SetScript("OnShow", function()
    local update = MysticExtended_ScrollFrameUpdate();
        if update then
            MysticExtended_ScrollFrameUpdate();
        end
end)

scrollFrame.scrollBar = scrollSlider

local rows = setmetatable({}, { __index = function(t, i)
	local row = CreateFrame("Button", "$parentRow"..i, scrollFrame)
	row:SetSize(150, ROW_HEIGHT)
	row:SetNormalFontObject(GameFontHighlightLeft)
    row:SetScript("OnClick", function()
        local item = tonumber(row.enchantID)
        local itemNum = GetSavedEnchant(item)
        if MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]][itemNum] then
            table.remove(MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]],itemNum)
        end
        local update = MysticExtended_ScrollFrameUpdate();
        if update then
            MysticExtended_ScrollFrameUpdate();
        end
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

function MysticExtended:CreateItemLink(id)
    local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[id].quality))
    local link = qualityColor.."|Hspell:"..MYSTIC_ENCHANTS[id].spellID.."|h["..MYSTIC_ENCHANTS[id].spellName.."]|h|r"
    return link
end

hooksecurefunc("ChatEdit_InsertLink", function(link)
	local id
    if MysticExtendedOptionsFrame:IsVisible() then
        id = tonumber(link:match("item:(%d+)"))
        MysticExtendedOptions_AddIDeditbox:SetText(id);
    else
        if MysticExtendedListFrame:IsVisible() then
            if link:match("item:") then
                id = GetREInSlot(GetMouseFocus():GetParent():GetID(), GetMouseFocus():GetID())
            else
                id = tonumber(link:match("spell:(%d+)"))
                id = MYSTIC_ENCHANT_SPELLS[id]
            end
                if not GetSavedEnchant(id) then
                    tinsert(MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]],{id})
                    local update = MysticExtended_ScrollFrameUpdate();
                    if update then
                        MysticExtended_ScrollFrameUpdate();
                    end
                end
        return true
        end
    end
end)

------------------------------------------------------------------
--Reforge button in list interface
local reforgebuttonlist = CreateFrame("Button", "MysticExtended_ListFrameReforgeButton", MysticEnchantingFrame, "OptionsButtonTemplate");
    reforgebuttonlist:SetSize(100,26);
    reforgebuttonlist:SetPoint("TOP", MysticEnchantingFrame, "TOP", 230, -33);
    reforgebuttonlist:SetText("Start Reforge");
    reforgebuttonlist:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    reforgebuttonlist:SetScript("OnClick", function(self, btnclick, down) MysticExtended_OnClick(self,btnclick) end);

--Shows a menu with options and sharing options
local sharebuttonlist = CreateFrame("Button", "MysticExtended_ListFrameMenuButton", MysticExtendedListFrame, "OptionsButtonTemplate");
    sharebuttonlist:SetSize(133,30);
    sharebuttonlist:SetPoint("BOTTOMRIGHT", MysticExtendedListFrame, "BOTTOMRIGHT", -20, 20);
    sharebuttonlist:SetText("Export/Share");
    sharebuttonlist:RegisterForClicks("LeftButtonDown");
    sharebuttonlist:SetScript("OnClick", function(self)
        if MysticExtended_OptionsMenu:IsOpen() then
            MysticExtended_OptionsMenu:Close();
        else
            MysticExtended:ListFrameMenuRegister(self);
            MysticExtended_OptionsMenu:Open(this);
        end
    end);

local optionsbuttonlist = CreateFrame("Button", "MysticExtended_ListFrameOptionsButton", MysticExtendedListFrame, "OptionsButtonTemplate");
    optionsbuttonlist:SetSize(133,30);
    optionsbuttonlist:SetPoint("BOTTOMLEFT", MysticExtendedListFrame, "BOTTOMLEFT", 20, 20);
    optionsbuttonlist:SetText("Options");
    optionsbuttonlist:RegisterForClicks("LeftButtonDown");
    optionsbuttonlist:SetScript("OnClick", function() MysticExtended:OptionsToggle() end);

--Show/Hide button in main list view
local showFrameBttn = CreateFrame("Button", "MysticExtended_ShowButton", MysticEnchantingFrame, "OptionsButtonTemplate");
    showFrameBttn:SetSize(80,26);
    showFrameBttn:SetPoint("TOP", MysticEnchantingFrame, "TOP", 320, -33);
    showFrameBttn:SetScript("OnClick", function()
        if MysticExtendedListFrame:IsVisible() then
            MysticExtendedListFrame:Hide();
            MysticExtendedDB.ListFrameLastState = false;
            showFrameBttn:SetText("Show");
        else
            showFrameBttn:SetText("Hide");
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
                showFrameBttn:SetText("Hide");
            else
                MysticExtendedListFrame:Hide();
                showFrameBttn:SetText("Show");
            end
        end)
--Hide it when it closes
MysticEnchantingFrame:HookScript("OnHide",
        function()
        MysticExtendedListFrame:Hide();
        end)
