MysticExtended_ExtractMenu = AceLibrary("Dewdrop-2.0");
local mainframe = CreateFrame("FRAME", "MysticExtendedExtractFrame", UIParent,"UIPanelDialogTemplate")
    mainframe:SetSize(460,508);
    mainframe:SetPoint("CENTER",0,0);
    mainframe:EnableMouse(true);
    mainframe:SetMovable(true);
    mainframe:RegisterForDrag("LeftButton");
    mainframe:SetScript("OnDragStart", function(self) mainframe:StartMoving() end);
    mainframe:SetScript("OnDragStop", function(self) mainframe:StopMovingOrSizing() end);
    mainframe:SetScript("OnShow", function()
        MysticExtended:SearchBags()
        MysticExtended:RegisterEvent("BAG_UPDATE", MysticExtended.SearchBags);
        if not MysticEnchantingFrame:IsVisible() then
            MysticEnchantingFrame:UnregisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
        end
        MysticExtended:RegisterEvent("CURRENCY_DISPLAY_UPDATE", MysticExtended_OnEvent);
        MysticExtended:RegisterEvent("KNOWN_CURRENCY_TYPES_UPDATE", MysticExtended_OnEvent);
        MysticExtendedExtractCountText:SetText(string.format("Mystic Extracts: |cffFFFFFF%i|r", GetItemCount(98463)));

    end);
    mainframe:SetScript("OnHide", function()
        MysticExtended:UnregisterEvent("BAG_UPDATE");
        MysticEnchantingFrame:RegisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
        MysticExtended:UnregisterEvent("CURRENCY_DISPLAY_UPDATE");
        MysticExtended:UnregisterEvent("KNOWN_CURRENCY_TYPES_UPDATE");

    end);
    mainframe.TitleText = mainframe:CreateFontString();
    mainframe.TitleText:SetFont("Fonts\\FRIZQT__.TTF", 12);
    mainframe.TitleText:SetFontObject(GameFontNormal);
    mainframe.TitleText:SetText("Mystic Extended");
    mainframe.TitleText:SetPoint("TOP", 0, -9);
    mainframe.TitleText:SetShadowOffset(1,-1);
    mainframe:Hide();

local extractbutton = CreateFrame("Button", "MysticExtendedExtractCount", MysticExtendedExtractFrame);
    extractbutton:SetSize(20,20);
    extractbutton:SetPoint("TOPLEFT", MysticExtendedExtractFrame, "TOPLEFT", 153, -40);
    extractbutton.icon = extractbutton:CreateTexture("MysticExtendedFrame_ExtractCount_Icon","ARTWORK");
    extractbutton.icon:SetSize(20,20);
    extractbutton.icon:SetPoint("TOPLEFT", "MysticExtendedExtractCount","TOPLEFT",1,-1);
    extractbutton.icon:SetTexture("Interface\\Icons\\Inv_Custom_MysticExtract");
	extractbutton.Lable = extractbutton:CreateFontString("MysticExtendedExtractCountText" , "BORDER", "GameFontNormal");
	extractbutton.Lable:SetJustifyH("LEFT");
	extractbutton.Lable:SetPoint("RIGHT", -30, 0);
    extractbutton.Lable:SetText(string.format("Mystic Extracts: |cffFFFFFF%i|r", GetItemCount(98463)))
    extractbutton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -13, -50)
        GameTooltip:SetHyperlink(select(2,GetItemInfo(98463)));
        GameTooltip:Show()
    end)
    extractbutton:SetScript("OnLeave", function () GameTooltip:Hide() end)
    extractbutton:Show();

local inventoryItems = {};

--finds the next bag slot with an item to roll on
function MysticExtended:SearchBags()
    inventoryItems = {};
    for b = 0, 4 do
        for s = 1, GetContainerNumSlots(b) do
            if MysticExtendedDB["ShowUnknown"] and GetContainerItemInfo(b,s) and select(4,GetContainerItemInfo(b,s)) > 2 then
                if not IsReforgeEnchantmentKnown(GetREInSlot(b,s)) and MysticExtended:DoRarity(b, s, 4) then
                    tinsert(inventoryItems,{b,s});
                end
            elseif GetContainerItemInfo(b,s) and select(4,GetContainerItemInfo(b,s)) > 2 and MysticExtended:DoSaveList(b,s,nil,"Extract") then
                tinsert(inventoryItems,{b,s});
            end
        end
    end
    MysticExtended_InventroyScrollFrameUpdate()
end

--Shows a menu with options and sharing options
local extractMenu = CreateFrame("Button", "MysticExtended_ExtractInterface_QualityMenu", MysticExtendedExtractFrame, "OptionsButtonTemplate");
    extractMenu:SetSize(133, 30);
    extractMenu:SetPoint("BOTTOMRIGHT", MysticExtendedExtractFrame, "BOTTOMRIGHT", -20, 20);
    extractMenu:SetText("Quality");
    extractMenu:RegisterForClicks("LeftButtonDown");
    extractMenu:SetScript("OnClick", function(self)
        if MysticExtended_ExtractMenu:IsOpen() then
            MysticExtended_ExtractMenu:Close();
        else
            MysticExtended:ExtractMenuRegister(self);
            MysticExtended_OptionsMenu:Open(this);
        end
    end);

local unknown = CreateFrame("CheckButton", "MysticExtendedExtract_ShowUnknown", MysticExtendedExtractFrame, "UICheckButtonTemplate");
	unknown:SetPoint("BOTTOMLEFT", MysticExtendedExtractFrame, "BOTTOMLEFT", 20, 20);
	unknown.Lable = unknown:CreateFontString(nil , "BORDER", "GameFontNormal");
	unknown.Lable:SetJustifyH("LEFT");
	unknown.Lable:SetPoint("LEFT", 30, 0);
	unknown.Lable:SetText("Show All Unknown\nEnchants Of Selected Quality");
	unknown:SetScript("OnClick", function()
		if MysticExtendedDB["ShowUnknown"] then
			MysticExtendedDB["ShowUnknown"] = false
		else
			MysticExtendedDB["ShowUnknown"] = true
		end
        MysticExtended:SearchBags();
	end);

local function QualitySet(tablenum, state)
    if state then
        MysticExtendedDB["QualityList"][tablenum][4] = false;
    else
        MysticExtendedDB["QualityList"][tablenum][4] = true;
    end
    MysticExtended:SearchBags();
end

function MysticExtended:ExtractMenuRegister(self)
    MysticExtended_ExtractMenu:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                for k, v in ipairs(MysticExtendedDB["QualityList"]) do
                    local qualityColor = select(4, GetItemQualityColor(v[3]))
                    MysticExtended_ExtractMenu:AddLine(
                        'text', qualityColor .. v[1],
                        'arg1', k,
                        'arg2', v[4],
                        'func', QualitySet,
                        'checked', v[4]
                    )
                end
                MysticExtended_ExtractMenu:AddLine(
                    'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
                    'func', function() MysticExtended_ExtractMenu:Close() end,
                    'notCheckable', true
                )
            end
        end,
        'dontHook', true
    )
end

------------------ScrollFrameTooltips---------------------------
local function ItemTemplate_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -13, -50)
    if self.link2 and IsControlKeyDown() then
        GameTooltip:SetHyperlink(self.link2);
    elseif self.link then
        GameTooltip:SetHyperlink(self.link)
    else
        return
    end
    GameTooltip:Show()
end

local function ItemTemplate_OnLeave()
    GameTooltip:Hide()
end

--ScrollFrame

local ROW_HEIGHT = 16;   -- How tall is each row?
local MAX_ROWS = 23;      -- How many rows can be shown at once?

local scrollFrame = CreateFrame("Frame", "MysticExtended_DE_ScrollFrame", MysticExtendedExtractFrame);
    scrollFrame:EnableMouse(true);
    scrollFrame:SetSize(420, ROW_HEIGHT * MAX_ROWS + 16);
    scrollFrame:SetPoint("LEFT",20,-8);
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });

function MysticExtended_InventroyScrollFrameUpdate()
    local maxValue = #inventoryItems
	FauxScrollFrame_Update(scrollFrame.scrollBar, maxValue, MAX_ROWS, ROW_HEIGHT);
	local offset = FauxScrollFrame_GetOffset(scrollFrame.scrollBar);
	for i = 1, MAX_ROWS do
		local value = i + offset
        scrollFrame.rows[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
		if value <= maxValue then
			local row = scrollFrame.rows[i]
            local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[GetREInSlot(inventoryItems[value][1],inventoryItems[value][2])].quality))
            row.Text:SetText(select(7, GetContainerItemInfo(inventoryItems[value][1],inventoryItems[value][2])));
            row.Text1:SetText(qualityColor..GetSpellInfo(MYSTIC_ENCHANTS[GetREInSlot(inventoryItems[value][1],inventoryItems[value][2])].spellID))
            row.link = select(7, GetContainerItemInfo(inventoryItems[value][1],inventoryItems[value][2]));
            row.link2 = MysticExtended:CreateItemLink(GetREInSlot(inventoryItems[value][1],inventoryItems[value][2]));
			row.bag = inventoryItems[value][1];
            row.slot = inventoryItems[value][2];
            row:Show()
		else
			scrollFrame.rows[i]:Hide()
		end
	end
end

local scrollSlider = CreateFrame("ScrollFrame","MysticExtendedDEListFrameScroll",MysticExtended_ScrollFrame,"FauxScrollFrameTemplate");
scrollSlider:SetPoint("TOPLEFT", 0, -8)
scrollSlider:SetPoint("BOTTOMRIGHT", -30, 8)
scrollSlider:SetScript("OnVerticalScroll", function(self, offset)
    self.offset = math.floor(offset / ROW_HEIGHT + 0.5)
    MysticExtended_InventroyScrollFrameUpdate();

end)

scrollSlider:SetScript("OnShow", function()
    MysticExtended_InventroyScrollFrameUpdate();
end)

scrollFrame.scrollBar = scrollSlider

local rows = setmetatable({}, { __index = function(t, i)
	local row = CreateFrame("Button", "$parentRow"..i, scrollFrame)
	row:SetSize(405, ROW_HEIGHT)
	row:SetNormalFontObject(GameFontHighlightLeft)
    row.Text = row:CreateFontString("$parentRow"..i.."Text","OVERLAY","GameFontNormal");
    row.Text:SetSize(260, ROW_HEIGHT);
    row.Text:SetPoint("LEFT",row);
    row.Text:SetJustifyH("LEFT");
    row.Text1 = row:CreateFontString("$parentRow"..i.."Text1","OVERLAY","GameFontNormal");
    row.Text1:SetSize(140, ROW_HEIGHT);
    row.Text1:SetPoint("LEFT",row,270,0);
    row.Text1:SetJustifyH("LEFT");
    row:SetScript("OnClick", function()
        if MysticExtendedDB["ExtractWarn"] then
            StaticPopupDialogs.MYSTICEXTENDED_CONFIRM_EXTRACT.item = {row.bag,row.slot};
            StaticPopup_Show("MYSTICEXTENDED_CONFIRM_EXTRACT",row.Text1:GetText())
        else
            MysticExtended:ExtractEnchant(row.bag,row.slot);
            MysticExtended:SearchBags();
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

--[[
StaticPopupDialogs["MYSTICEXTENDED_CONFIRM_EXTRACT"]
This is shown, if you want too share a EnchantList
]]
StaticPopupDialogs["MYSTICEXTENDED_CONFIRM_EXTRACT"] = {
	text = "Extract (%s)",
	button1 = "Extract",
	button2 = "Cancel",
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP");
	end,
	OnAccept = function(self)
        MysticExtended:ExtractEnchant(StaticPopupDialogs.MYSTICEXTENDED_CONFIRM_EXTRACT.item[1],StaticPopupDialogs.MYSTICEXTENDED_CONFIRM_EXTRACT.item[2]);
        MysticExtended:SearchBags();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}