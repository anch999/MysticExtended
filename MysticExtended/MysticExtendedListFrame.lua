local ME = LibStub("AceAddon-3.0"):GetAddon("MysticExtended")
local dewdrop = AceLibrary("Dewdrop-2.0");
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
            ME.db.ListFrameLastState = false;
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

MysticEnchantingFrame.CollectionsList.PrevButton:SetPoint("RIGHT", MysticEnchantingFrame.CollectionsList, "BOTTOM", 6, 50)
MysticEnchantingFrame.MysticExtendedKnownCount = CreateFrame("Button", nil, MysticEnchantingFrame)
MysticEnchantingFrame.MysticExtendedKnownCount:SetPoint("BOTTOM", 135, 48)
MysticEnchantingFrame.MysticExtendedKnownCount:SetSize(190,20)
MysticEnchantingFrame.MysticExtendedKnownCount.Lable = MysticEnchantingFrame.MysticExtendedKnownCount:CreateFontString(nil , "BORDER", "GameFontNormal")
MysticEnchantingFrame.MysticExtendedKnownCount.Lable:SetJustifyH("LEFT")
MysticEnchantingFrame.MysticExtendedKnownCount.Lable:SetPoint("LEFT", 0, 0);
MysticEnchantingFrame.MysticExtendedKnownCount:SetScript("OnShow", function()
    ME:CalculateKnowEnchants()
    MysticEnchantingFrame.MysticExtendedKnownCount.Lable:SetText("Known Enchants: |cffffffff".. ME.db.KnownEnchantNumbers.Total.Known.."/"..ME.db.KnownEnchantNumbers.Total.Total)
end)
MysticEnchantingFrame.MysticExtendedKnownCount:SetScript("OnEnter", function(self) ME:EnchantCountTooltip(self) end)
MysticEnchantingFrame.MysticExtendedKnownCount:SetScript("OnLeave", function() GameTooltip:Hide() end)


local realmName = GetRealmName();
local showtable = {};

local function setCurrentSelectedList()
    local thisID = this:GetID();
    ME.db.currentSelectedList = thisID;
    UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,thisID);
    MysticExtended_ScrollFrameUpdate();
end

function ME:MenuInitialize()
        local info;
        for k,v in ipairs(ME.EnchantSaveLists) do
                    info = {
                        text = v.Name;
                        func = function() setCurrentSelectedList() end;
                    };
                    UIDropDownMenu_AddButton(info);
        end
end

function MysticExtended_ListEnable()
    UIDropDownMenu_Initialize(MysticExtended_ListDropDown, ME.MenuInitialize);
	UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,ME.db.currentSelectedList);
    MysticExtended_ScrollFrameUpdate();
end

StaticPopupDialogs["MYSTICEXTENDED_ADDLIST"] = {
    text = "Add New List?",
    button1 = "Confirm",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function (self, data, data2)
        local text = self.editBox:GetText()
        ME.EnchantSaveLists[#ME.EnchantSaveLists + 1] = {["Name"] = text, [realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false}; }
        UIDropDownMenu_Initialize(MysticExtended_ListDropDown, ME.MenuInitialize);
        UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,#ME.EnchantSaveLists);
        ME.db.currentSelectedList = #ME.EnchantSaveLists;
    MysticExtended_ScrollFrameUpdate();
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
    OnShow = function(self)
		self.editBox:SetText(ME.EnchantSaveLists[ME.db.currentSelectedList].Name)
		self:SetFrameStrata("TOOLTIP");
	end,
    OnAccept = function (self, data, data2)
        local text = self.editBox:GetText()
        if text ~= "" then
            ME.EnchantSaveLists[ME.db.currentSelectedList].Name = text;
            UIDropDownMenu_Initialize(MysticExtended_ListDropDown, ME.MenuInitialize);
            UIDropDownMenu_SetText(MysticExtended_ListDropDown, text)
            MysticExtended_ScrollFrameUpdate();
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
        tremove(ME.EnchantSaveLists, ME.db.currentSelectedList);
        UIDropDownMenu_Initialize(MysticExtended_ListDropDown, ME.MenuInitialize);
        UIDropDownMenu_SetSelectedID(MysticExtended_ListDropDown,1);
        ME.db.currentSelectedList = 1;
        MysticExtended_ScrollFrameUpdate();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    enterClicksFirstButton = true,
}

local function exportString()
    dewdrop:Close();
    local data = {};
    for i,v in ipairs(ME.EnchantSaveLists[ME.db.currentSelectedList]) do
        tinsert(data,{v[1]});
    end
    data["Name"] = ME.EnchantSaveLists[ME.db.currentSelectedList]["Name"];
    Internal_CopyToClipboard("MEXT:"..ME:Serialize(data));
end

function ME:ListFrameMenuRegister(self)
	dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                dewdrop:AddLine(
                    'text', "Send Current List",
                    'func', function() StaticPopup_Show("MYSTICEXTENDED_SEND_ENCHANTLIST",ME.EnchantSaveLists[ME.db.currentSelectedList].Name) end,
                    'notCheckable', true
                )
                dewdrop:AddLine(
                    'text', "Export List",
                    'func', exportString,
                    'tooltip', "Exports a string to clipboard",
                    'notCheckable', true
                )
                dewdrop:AddLine(
                    'text', "Import List",
                    'func', function() StaticPopup_Show("MYSTICEXTENDED_IMPORT_ENCHANTLIST") end,
                    'notCheckable', true
                )
                dewdrop:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'func', function() dewdrop:Close() end,
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
    UIDropDownMenu_SetWidth(MysticExtended_ListDropDown, 155)
    listDropdown.EnchantNumber = listDropdown:CreateFontString("MysticExtendedEnchantCount", "OVERLAY", "GameFontNormal");
    listDropdown.EnchantNumber:SetPoint("TOPLEFT", 26, -8);
    listDropdown.EnchantNumber:SetFont("Fonts\\FRIZQT__.TTF", 11)
    listDropdown:SetScript("OnUpdate", function()
            listDropdown.EnchantNumber:SetText("|cff00ff00"..#showtable);
        end)

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
    for i, enchant in ipairs(ME.EnchantSaveLists[ME.db.currentSelectedList]) do
        if enchant[1] == id then
            return i
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
    showtable = {Name = ME.EnchantSaveLists[ME.db.currentSelectedList].Name, MenuID = ME.EnchantSaveLists[ME.db.currentSelectedList].MenuID};
    for _,v in ipairs(ME.EnchantSaveLists[ME.db.currentSelectedList]) do
        if MYSTIC_ENCHANTS[v[1]] then
            tinsert(showtable,v)
        end
    end

    local maxValue = #showtable
	FauxScrollFrame_Update(scrollFrame.scrollBar, maxValue, MAX_ROWS, ROW_HEIGHT);
	local offset = FauxScrollFrame_GetOffset(scrollFrame.scrollBar);
	for i = 1, MAX_ROWS do
		local value = i + offset
        scrollFrame.rows[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
		if value <= maxValue and showtable[value] and MYSTIC_ENCHANTS[showtable[value][1]] then
			local row = scrollFrame.rows[i]
            local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[showtable[value][1]].quality))
            row:SetText(qualityColor..GetSpellInfo(MYSTIC_ENCHANTS[showtable[value][1]].spellID))
            row.enchantID = showtable[value][1]
            row.link = ME:CreateItemLink(showtable[value][1])
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
    MysticExtended_ScrollFrameUpdate();
end)

scrollSlider:SetScript("OnShow", function()
    MysticExtended_ScrollFrameUpdate();
end)

scrollFrame.scrollBar = scrollSlider

local rows = setmetatable({}, { __index = function(t, i)
	local row = CreateFrame("Button", "$parentRow"..i, scrollFrame)
	row:SetSize(150, ROW_HEIGHT)
	row:SetNormalFontObject(GameFontHighlightLeft)
    row:RegisterForClicks("LeftButtonDown","RightButtonDown")
    row:SetScript("OnClick", function(self,button)
        local item = tonumber(row.enchantID)
        local itemNum = GetSavedEnchant(item)
        if button == "RightButton" then
            if ME.EnchantSaveLists[ME.db.currentSelectedList][itemNum] then
                tremove(ME.EnchantSaveLists[ME.db.currentSelectedList],itemNum)
            end
            MysticExtended_ScrollFrameUpdate()    
        elseif button == "LeftButton" then
            if IsShiftKeyDown() then
                ChatEdit_InsertLink(ME:CreateItemLink(row.enchantID))
            else
                Internal_CopyToClipboard(GetSpellInfo(MYSTIC_ENCHANTS[row.enchantID].spellID))
            end
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

function ME:CreateItemLink(id)
    local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[id].quality))
    local link = qualityColor.."|Hspell:"..MYSTIC_ENCHANTS[id].spellID.."|h["..GetSpellInfo(MYSTIC_ENCHANTS[id].spellID).."]|h|r"
    return link
end

local function enchantButtonClick(self)
    local id = self.Enchant
    if not GetSavedEnchant(id) then
        tinsert(ME.EnchantSaveLists[ME.db.currentSelectedList],{id})
        MysticExtended_ScrollFrameUpdate();
    end
end

for i = 1, 15 do
    local button = _G["CollectionItemFrame"..i].Button
    local buttonFake = _G["CollectionItemFrame"..i].Button_fake
    button:HookScript("OnClick", function(self)
        if IsAltKeyDown() then
            enchantButtonClick(self)
        end
    end)
    buttonFake:HookScript("OnClick", function(self)
        if IsAltKeyDown() then
            enchantButtonClick(self)
        elseif IsShiftKeyDown() then
            local id = self.Enchant
            ChatEdit_InsertLink(ME:CreateItemLink(id))
        end
    end)
end

------------------------------------------------------------------
--Reforge button in list interface
local reforgebuttonlist = CreateFrame("Button", "MysticExtended_ListFrameReforgeButton", MysticEnchantingFrame, "OptionsButtonTemplate");
    reforgebuttonlist:SetSize(100,26);
    reforgebuttonlist:SetPoint("TOP", MysticEnchantingFrame, "TOP", 230, -33);
    reforgebuttonlist:SetText("Start Reforge");
    reforgebuttonlist:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    reforgebuttonlist:SetScript("OnClick", function(self, btnclick) MysticExtended_OnClick(self,btnclick) end);

--Shows a menu with options and sharing options
local sharebuttonlist = CreateFrame("Button", "MysticExtended_ListFrameMenuButton", MysticExtendedListFrame, "OptionsButtonTemplate");
    sharebuttonlist:SetSize(133,30);
    sharebuttonlist:SetPoint("BOTTOMRIGHT", MysticExtendedListFrame, "BOTTOMRIGHT", -20, 20);
    sharebuttonlist:SetText("Export/Share");
    sharebuttonlist:RegisterForClicks("LeftButtonDown");
    sharebuttonlist:SetScript("OnClick", function(self)
        if dewdrop:IsOpen() then
            dewdrop:Close();
        else
            ME:ListFrameMenuRegister(self);
            dewdrop:Open(this);
        end
    end);

local optionsbuttonlist = CreateFrame("Button", "MysticExtended_ListFrameOptionsButton", MysticExtendedListFrame, "OptionsButtonTemplate");
    optionsbuttonlist:SetSize(133,30);
    optionsbuttonlist:SetPoint("BOTTOMLEFT", MysticExtendedListFrame, "BOTTOMLEFT", 20, 20);
    optionsbuttonlist:SetText("Options");
    optionsbuttonlist:RegisterForClicks("LeftButtonDown");
    optionsbuttonlist:SetScript("OnClick", function() ME:OptionsToggle() end);

--Show/Hide button in main list view
local showFrameBttn = CreateFrame("Button", "MysticExtended_ShowButton", MysticEnchantingFrame, "OptionsButtonTemplate");
    showFrameBttn:SetSize(80,26);
    showFrameBttn:SetPoint("TOP", MysticEnchantingFrame, "TOP", 320, -33);
    showFrameBttn:SetScript("OnClick", function()
        if MysticExtendedListFrame:IsVisible() then
            MysticExtendedListFrame:Hide();
            ME.db.ListFrameLastState = false;
            showFrameBttn:SetText("Show");
        else
            showFrameBttn:SetText("Hide");
            MysticExtendedListFrame:Show();
            ME.db.ListFrameLastState = true;
        end
    end)

--Moves Ascensions xp/search/sortmenu
local meFrame = MysticEnchantingFrame
    meFrame.ProgressBar:SetPoint("TOP", meFrame.TitleText,"BOTTOM", -200, -14)
    meFrame.SearchBox:SetPoint("TOPRIGHT", meFrame, -330, -33)
    meFrame.EnchantTypeList:SetPoint("TOPRIGHT", meFrame, -200, -32)

--Show list view when Mystic Enchanting frame opens
meFrame:HookScript("OnShow",
        function()
            if ME.db.UnlockEnchantWindow then AT_MYSTIC_ENCHANT_ALTAR = true end
            if ME.db.ListFrameLastState then
                MysticExtendedListFrame:Show();
                showFrameBttn:SetText("Hide");
            else
                MysticExtendedListFrame:Hide();
                showFrameBttn:SetText("Show");
            end
        end)
--Hide it when it closes
meFrame:HookScript("OnHide",
        function()
        MysticExtendedListFrame:Hide();
        MYSTICEXTENDED_ITEMSET = false
        MYSTICEXTENDED_BAGID, MYSTICEXTENDED_SLOTID = nil,nil
        end)

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self)
    if MysticExtendedListFrame:IsVisible() and IsAltKeyDown() then
        local bagID, slotID = self:GetParent():GetID(), self:GetID();
        local enchant = GetREInSlot(bagID, slotID)
            if enchant and not GetSavedEnchant(enchant) then
                tinsert(ME.EnchantSaveLists[ME.db.currentSelectedList],{enchant})
                MysticExtended_ScrollFrameUpdate();
            end
    end
end)

hooksecurefunc("ContainerFrameItemButton_OnClick", function(self, button)
    if meFrame:IsVisible() then
        local bagID, slotID = self:GetParent():GetID(), self:GetID();
        MYSTICEXTENDED_BAGID = bagID
        MYSTICEXTENDED_SLOTID = slotID
        MYSTICEXTENDED_ITEMSET = false
        ME:StopAutoRoll()
    end
end)

MysticEnchantingFrameEnchantFrameSlotButton:HookScript("OnClick", function()
    if MYSTICEXTENDED_ITEMSET then
        MYSTICEXTENDED_ITEMSET = false
        MYSTICEXTENDED_BAGID = nil
        MYSTICEXTENDED_SLOTID = nil
        ME:StopAutoRoll()
    else
        MYSTICEXTENDED_ITEMSET = true
    end
end)

for i = 1, 19 do
    local slot = MysticEnchantingFramePaperDoll["Slot" .. i]
    slot:HookScript("OnClick", function()
        MYSTICEXTENDED_BAGID = 255
        MYSTICEXTENDED_SLOTID = slot.SlotID
        MYSTICEXTENDED_ITEMSET = true
    end)
end
