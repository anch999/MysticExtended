local ME = LibStub("AceAddon-3.0"):GetAddon("MysticExtended")
local dewdrop = AceLibrary("Dewdrop-2.0");
local mainframe = CreateFrame("FRAME", "MysticExtendedExtractFrame", UIParent,"UIPanelDialogTemplate")
    mainframe:SetSize(460,508);
    mainframe:SetPoint("CENTER",0,0);
    mainframe:EnableMouse(true);
    mainframe:SetMovable(true);
    mainframe:RegisterForDrag("LeftButton");
    mainframe:SetScript("OnDragStart", function(self) mainframe:StartMoving() end);
    mainframe:SetScript("OnDragStop", function(self) mainframe:StopMovingOrSizing() end);
    mainframe:SetScript("OnShow", function()
        ME:SearchBags()
        ME:RegisterEvent("BAG_UPDATE", ME.SearchBags);
        if not MysticEnchantingFrame:IsVisible() then
            MysticEnchantingFrame:UnregisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST");
        end
        ME:CalculateKnowEnchants()
    end);
    mainframe:SetScript("OnHide", function()
        ME:UnregisterEvent("BAG_UPDATE")
        if not ME.AutoRolling then
            MysticEnchantingFrame:RegisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST")
        end
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

local inventoryItems
local bagThrottle = false
--finds the next bag slot with an item with an enchant on it
function ME:SearchBags()
    if not bagThrottle then
        inventoryItems = {}
        for bagID = 0, 4 do
            for slotID = 1, GetContainerNumSlots(bagID) do
                local enchantID = GetREInSlot(bagID,slotID)
                if enchantID then
                    local quality,_,_,link = select(4,GetContainerItemInfo(bagID,slotID))
                    if ME.db.ShowUnknown and quality and quality > 2 then
                        if not IsReforgeEnchantmentKnown(enchantID) and ME:DoRarity(enchantID, 3) then
                            tinsert(inventoryItems,{bagID,slotID,link,enchantID});
                        end
                    elseif quality and quality > 2 and ME:SearchLists(enchantID, "ExtractAny") then
                        tinsert(inventoryItems,{bagID,slotID,link,enchantID});
                    end
                end
            end
        end
        bagThrottle = true
        ME.bagThrottle = ME:ScheduleTimer(function() bagThrottle = false end, .1);
        MysticExtended_InventroyScrollFrameUpdate()
        MysticExtendedExtractCountText:SetText(string.format("Mystic Extracts: |cffFFFFFF%i|r", GetItemCount(98463)));
    end
end

--Shows a menu with options and sharing options
local extractMenu = CreateFrame("Button", "MysticExtended_ExtractInterface_QualityMenu", MysticExtendedExtractFrame, "OptionsButtonTemplate");
    extractMenu:SetSize(133, 30);
    extractMenu:SetPoint("BOTTOMRIGHT", MysticExtendedExtractFrame, "BOTTOMRIGHT", -20, 20);
    extractMenu:SetText("Quality");
    extractMenu:RegisterForClicks("LeftButtonDown");
    extractMenu:SetScript("OnClick", function(self)
        if dewdrop:IsOpen() then
            dewdrop:Close();
        else
            ME:ExtractMenuRegister(self);
            dewdrop:Open(this);
        end
    end);

local unknown = CreateFrame("CheckButton", "MysticExtendedExtract_ShowUnknown", MysticExtendedExtractFrame, "UICheckButtonTemplate");
	unknown:SetPoint("BOTTOMLEFT", MysticExtendedExtractFrame, "BOTTOMLEFT", 20, 20);
	unknown.Lable = unknown:CreateFontString(nil , "BORDER", "GameFontNormal");
	unknown.Lable:SetJustifyH("LEFT");
	unknown.Lable:SetPoint("LEFT", 30, 0);
	unknown.Lable:SetText("Show All Unknown\nEnchants Of Selected Quality");
	unknown:SetScript("OnClick", function()
		if ME.db.ShowUnknown then
			ME.db.ShowUnknown = false
		else
			ME.db.ShowUnknown = true
		end
        ME:SearchBags();
	end);

local function QualitySet(listNum,quality)
    if ME.db.QualityList[listNum][quality] then
        ME.db.QualityList[listNum][quality] = false;
    else
        ME.db.QualityList[listNum][quality] = true;
    end
    ME:SearchBags();
end

function ME:ExtractMenuRegister(self)
    dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                for k, v in ipairs(ME.QualityList) do
                    local qualityColor = select(4, GetItemQualityColor(v[2]))
                    dewdrop:AddLine(
                        'text', qualityColor .. v[1],
                        'arg1', 3,
                        'arg2', k,
                        'func', QualitySet,
                        'checked', ME.db.QualityList[3][k]
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
            local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[inventoryItems[value][4]].quality))
            row.Text:SetText(inventoryItems[value][3])
            row.Text1:SetText(qualityColor..GetSpellInfo(MYSTIC_ENCHANTS[inventoryItems[value][4]].spellID))
            row.link = inventoryItems[value][3]
            row.link2 = ME:CreateItemLink(inventoryItems[value][4]);
			row.bag = inventoryItems[value][1]
            row.slot = inventoryItems[value][2]
            row.tNumber = value
            row.enchantID = inventoryItems[value][4]
            row:Show()
		else
			scrollFrame.rows[i]:Hide()
		end
	end
end

local scrollSlider = CreateFrame("ScrollFrame","MysticExtendedDEListFrameScroll",MysticExtended_DE_ScrollFrame,"FauxScrollFrameTemplate");
scrollSlider:SetPoint("TOPLEFT", 0, -8)
scrollSlider:SetPoint("BOTTOMRIGHT", -30, 8)
scrollSlider:SetScript("OnVerticalScroll", function(self, offset)
    self.offset = math.floor(offset / ROW_HEIGHT + 0.5)
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
        if ME.db.ExtractWarn then
            StaticPopupDialogs.MYSTICEXTENDED_CONFIRM_EXTRACT.item = {row.bag,row.slot,row.enchantID};
            StaticPopup_Show("MYSTICEXTENDED_CONFIRM_EXTRACT",row.Text1:GetText())
        else
            if ME:ExtractEnchant(row.bag,row.slot,row.enchantID) then
                tremove(inventoryItems,row.tNumber)
                MysticExtended_InventroyScrollFrameUpdate()
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
        ME:ExtractEnchant(StaticPopupDialogs.MYSTICEXTENDED_CONFIRM_EXTRACT.item[1],StaticPopupDialogs.MYSTICEXTENDED_CONFIRM_EXTRACT.item[2],StaticPopupDialogs.MYSTICEXTENDED_CONFIRM_EXTRACT.item[3]);
        ME:SearchBags();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

    mainframe.knownCount = CreateFrame("Button", nil, MysticExtendedExtractFrame)
	mainframe.knownCount:SetPoint("TOP", 110, -40)
	mainframe.knownCount:SetSize(190,20)
    mainframe.knownCount.Lable = mainframe.knownCount:CreateFontString(nil , "BORDER", "GameFontNormal")
	mainframe.knownCount.Lable:SetJustifyH("LEFT")
	mainframe.knownCount.Lable:SetPoint("LEFT", 0, 0);
	mainframe.knownCount:SetScript("OnShow", function() mainframe.knownCount.Lable:SetText("Known Enchants: |cffffffff".. ME.db.KnownEnchantNumbers.Total.Known.."/"..ME.db.KnownEnchantNumbers.Total.Total) end)
    mainframe.knownCount:SetScript("OnEnter", function(self) ME:EnchantCountTooltip(self) end)
    mainframe.knownCount:SetScript("OnLeave", function() GameTooltip:Hide() end)

    function ME:EnchantCountTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(select(4, GetItemQualityColor(2)).."Commen Enchants")
        GameTooltip:AddLine("|cffffffffKnown: "..ME.db.KnownEnchantNumbers.Commen.Known.."/"..ME.db.KnownEnchantNumbers.Commen.Total)
        GameTooltip:AddLine("|cffffffffUnknown: "..ME.db.KnownEnchantNumbers.Commen.Unknown)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(select(4, GetItemQualityColor(3)).."Rare Enchants")
        GameTooltip:AddLine("|cffffffffKnown: "..ME.db.KnownEnchantNumbers.Rare.Known.."/"..ME.db.KnownEnchantNumbers.Rare.Total)
        GameTooltip:AddLine("|cffffffffUnknown: "..ME.db.KnownEnchantNumbers.Rare.Unknown)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(select(4, GetItemQualityColor(4)).."Epic Enchants")
        GameTooltip:AddLine("|cffffffffKnown: "..ME.db.KnownEnchantNumbers.Epic.Known.."/"..ME.db.KnownEnchantNumbers.Epic.Total)
        GameTooltip:AddLine("|cffffffffUnknown: "..ME.db.KnownEnchantNumbers.Epic.Unknown)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(select(4, GetItemQualityColor(5)).."Legendary Enchants")
        GameTooltip:AddLine("|cffffffffKnown: "..ME.db.KnownEnchantNumbers.Legendary.Known.."/"..ME.db.KnownEnchantNumbers.Legendary.Total)
        GameTooltip:AddLine("|cffffffffUnknown: "..ME.db.KnownEnchantNumbers.Legendary.Unknown)
        GameTooltip:Show()
    end

function ME:CalculateKnowEnchants()
    local known = {
        Commen = { Total = 0, Known = 0, Unknown = 0 },
        Rare = { Total = 0, Known = 0, Unknown = 0 },
        Epic = { Total = 0, Known = 0, Unknown = 0 },
        Legendary = { Total = 0, Known = 0, Unknown = 0 },
        Total = {Total = 0, Known = 0}
    }

    for _, v in pairs(MYSTIC_ENCHANTS) do
       if v.enchantID ~= 0 and v.flags ~= 1 then
          if v.quality == 2 then
             known.Commen.Total = known.Commen.Total + 1
          elseif v.quality == 3 then
            known.Rare.Total = known.Rare.Total + 1
          elseif v.quality == 4 then
            known.Epic.Total = known.Epic.Total + 1
          elseif v.quality == 5 then
            known.Legendary.Total = known.Legendary.Total + 1
          end

          if IsReforgeEnchantmentKnown(v.enchantID) then
             if v.quality == 2 then
                known.Commen.Known = known.Commen.Known + 1
             elseif v.quality == 3 then
                known.Rare.Known = known.Rare.Known + 1
             elseif v.quality == 4 then
                known.Epic.Known = known.Epic.Known + 1
             elseif v.quality == 5 then
                known.Legendary.Known = known.Legendary.Known + 1
             end
             known.Total.Known = known.Total.Known + 1
          end
          known.Total.Total = known.Total.Total + 1
       end
    end
    known.Commen.Unknown = known.Commen.Total - known.Commen.Known
    known.Rare.Unknown = known.Rare.Total - known.Rare.Known
    known.Epic.Unknown = known.Epic.Total - known.Epic.Known
    known.Legendary.Unknown = known.Legendary.Total - known.Legendary.Known 

    ME.db.KnownEnchantNumbers = known
    MysticExtendedExtractFrame.knownCount.Lable:SetText("Known Enchants: |cffffffff".. ME.db.KnownEnchantNumbers.Total.Known.."/"..ME.db.KnownEnchantNumbers.Total.Total)
end