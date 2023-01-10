local ME = LibStub("AceAddon-3.0"):GetAddon("MysticExtended")
function ME:OptionsToggle()
    if InterfaceOptionsFrame:IsVisible() then
		InterfaceOptionsFrame:Hide();
	else
		MysticExtended_OptionsMenu:Close();
		Collections:Hide();
		InterfaceOptionsFrame_OpenToCategory("MysticExtended");
		MoneyInputFrame_SetCopper(MysticExtended_MoneyFrame,MysticExtendedDB.MinGold)
	end
end

local function MysticExtendedOptions_Menu_OnClick()
    local thisID = this:GetID();
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_Menu, thisID);
end

local function MysticExtendedOptions_Menu_Initialize()
    local info;
	for k,v in pairs(ME.db.ReRollItems) do
				info = {
					text = GetItemInfo(ME.db.ReRollItems[k]);
					func = MysticExtendedOptions_Menu_OnClick;
				};
					UIDropDownMenu_AddButton(info);
	end
end

function MysticExtended_DropDownInitialize()
	--Setup for Dropdown menus in the settings
	UIDropDownMenu_Initialize(MysticExtendedOptions_Menu, MysticExtendedOptions_Menu_Initialize);
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_Menu,1);
	UIDropDownMenu_SetWidth(MysticExtendedOptions_Menu, 150);
end

local function AddIdButton()
	local function checkID(text)
		for i,v in pairs(ME.db.ReRollItems) do
			if v == text then
				return true;
			end
		end
	end
	local text = tonumber(MysticExtendedOptions_AddIDeditbox:GetText());
	if not checkID(text) and GetItemInfo(text) then
		tinsert(ME.db.ReRollItems,text)
	end
end

local function DeleteIdButton()
	local id = UIDropDownMenu_GetSelectedID(MysticExtendedOptions_Menu);
	table.remove(ME.db.ReRollItems,id)
	MysticExtendedOptions_Menu_Initialize();
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_Menu,1);
	UIDropDownMenu_SetText(MysticExtendedOptions_Menu,GetItemInfo(ME.db.ReRollItems[1]));
end

--Creates the options frame and all its assets
InterfaceOptionsFrame:SetWidth(850)
local mainframe = {};
		mainframe = CreateFrame("FRAME", "MysticExtendedOptionsFrame", InterfaceOptionsFrame, nil);
    	local fstring = mainframe:CreateFontString(mainframe, "OVERLAY", "GameFontNormal");
		fstring:SetText("MysticExtended Settings");
		fstring:SetPoint("TOPLEFT", 15, -15)
		mainframe.name = "MysticExtended";
		InterfaceOptions_AddCategory(mainframe);

local menuDrop = CreateFrame("Button", "MysticExtendedOptions_Menu", MysticExtendedOptionsFrame, "UIDropDownMenuTemplate");
	menuDrop:SetPoint("TOPLEFT", 0, -60);
	menuDrop.Lable = menuDrop:CreateFontString(nil , "BORDER", "GameFontNormal")
	menuDrop.Lable:SetJustifyH("LEFT")
	menuDrop.Lable:SetPoint("TOPLEFT", menuDrop, "TOPLEFT", 20, 20)
	menuDrop.Lable:SetText("List of item's to roll on")
	menuDrop:SetScript("OnClick", MysticExtendedOptions_Menu_OnClick);

	local addTextBox = CreateFrame("EditBox", "MysticExtendedOptions_AddIDeditbox", MysticExtendedOptionsFrame, "InputBoxTemplate");
	addTextBox:SetPoint("TOPLEFT", 23, -90);
	addTextBox:SetSize(162,30);
	addTextBox:SetText("Shift Click to add items");
	addTextBox:SetAutoFocus(false);

	local addBtn = CreateFrame("Button", "MysticExtendedOptions_AddID", MysticExtendedOptionsFrame, "OptionsButtonTemplate");
	addBtn:SetPoint("TOPLEFT", 190, -95);
	addBtn:SetSize(110,20);
	addBtn:SetText("Add item")
	addBtn:SetScript("OnClick", function() AddIdButton() end);

	local removeBtn = CreateFrame("Button", "MysticExtendedOptions_RemoveID", MysticExtendedOptionsFrame, "OptionsButtonTemplate");
	removeBtn:SetPoint("TOPLEFT", 190, -60);
	removeBtn:SetSize(110,20);
	removeBtn:SetText("Delete item")
	removeBtn:SetScript("OnClick", function() DeleteIdButton() end);

	local delaySlider = CreateFrame("Slider", "MysticExtended_DelaySlider", MysticExtendedOptionsFrame, "OptionsSliderTemplate")
	delaySlider:SetPoint("TOPLEFT", 20, -135);
	delaySlider:SetSize(160,20);
	delaySlider:SetOrientation("HORIZONTAL");
	delaySlider:SetMinMaxValues(1, 10);
	delaySlider:SetValueStep(1);
	delaySlider.Lable = delaySlider:CreateFontString(nil , "BORDER", "GameFontNormal");
	delaySlider.Lable:SetJustifyH("LEFT");
	delaySlider.Lable:SetPoint("BOTTOM", delaySlider, "BOTTOM", 0, -10);
	delaySlider.Lable:SetText("ReRoll Delay");
	delaySlider.tooltipText = "Change Delay if you keep getting Ability not ready yet" --Creates a tooltip on mouseover.
	getglobal(delaySlider:GetName() .. 'Low'):SetText('.1'); --Sets the left-side slider text (default is "Low").
	getglobal(delaySlider:GetName() .. 'High'):SetText('.10'); --Sets the right-side slider text (default is "High").
	delaySlider:SetScript("OnValueChanged", function()
		ME.db["REFORGE_RETRY_DELAY"] = delaySlider:GetValue();
		getglobal(delaySlider:GetName() .. 'Text'):SetText(tonumber("."..delaySlider:GetValue()));
	end);

	local hideFloat = CreateFrame("CheckButton", "MysticExtendedOptions_FloatSetting", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	hideFloat:SetPoint("TOPLEFT", 15, -170);
	hideFloat.Lable = hideFloat:CreateFontString(nil , "BORDER", "GameFontNormal");
	hideFloat.Lable:SetJustifyH("LEFT");
	hideFloat.Lable:SetPoint("LEFT", 30, 0);
	hideFloat.Lable:SetText("Show/Hide Floating Button");
	hideFloat:SetScript("OnClick", function() ME:ButtonEnable("Main") end);

	local hideFloatCity = CreateFrame("CheckButton", "MysticExtendedOptions_FloatCitySetting", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	hideFloatCity:SetPoint("TOPLEFT", 15, -205);
	hideFloatCity.Lable = hideFloatCity:CreateFontString(nil , "BORDER", "GameFontNormal");
	hideFloatCity.Lable:SetJustifyH("LEFT");
	hideFloatCity.Lable:SetPoint("LEFT", 30, 0);
	hideFloatCity.Lable:SetText("Show Floating Button Only In Citys");
	hideFloatCity:SetScript("OnClick", function() ME:ButtonEnable("City") end);

	local enableShare = CreateFrame("CheckButton", "MysticExtendedOptions_EnableShare", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	enableShare:SetPoint("TOPLEFT", 15, -240);
	enableShare.Lable = enableShare:CreateFontString(nil , "BORDER", "GameFontNormal");
	enableShare.Lable:SetJustifyH("LEFT");
	enableShare.Lable:SetPoint("LEFT", 30, 0);
	enableShare.Lable:SetText("Enable Enchant List Shareing");
	enableShare:SetScript("OnClick", function() 
		if ME.db["AllowShareEnchantList"] then
			ME.db["AllowShareEnchantList"] = false
		else
			ME.db["AllowShareEnchantList"] = true
		end
	end);

	local enableInCombat = CreateFrame("CheckButton", "MysticExtendedOptions_EnableShareCombat", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	enableInCombat:SetPoint("TOPLEFT", 15, -275);
	enableInCombat.Lable = enableInCombat:CreateFontString(nil , "BORDER", "GameFontNormal");
	enableInCombat.Lable:SetJustifyH("LEFT");
	enableInCombat.Lable:SetPoint("LEFT", 30, 0);
	enableInCombat.Lable:SetText("Auto Reject Enchant List Shareing In Combat");
	enableInCombat:SetScript("OnClick", function()
		if ME.db.AllowShareEnchantListInCombat then
			ME.db.AllowShareEnchantListInCombat = false
		else
			ME.db.AllowShareEnchantListInCombat = true
		end
	end);

--[[ local trinketConvert = CreateFrame("CheckButton", "MysticExtendedOptions_AutoMysticScrollBloodforge", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	trinketConvert:SetPoint("TOPLEFT", 15, -310);
	trinketConvert.Lable = trinketConvert:CreateFontString(nil , "BORDER", "GameFontNormal");
	trinketConvert.Lable:SetJustifyH("LEFT");
	trinketConvert.Lable:SetPoint("LEFT", 30, 0);
	trinketConvert.Lable:SetText("Auto Bloodforge Untarnished Mystic Scrolls when Bloody Jar is used");
	trinketConvert:SetScript("OnClick", function()
		if ME.db["AutoMysticScrollBloodforge"] then
			ME.db["AutoMysticScrollBloodforge"] = false
			ME:UnregisterEvent("GOSSIP_SHOW");
		else
			ME.db["AutoMysticScrollBloodforge"] = true
			ME:RegisterEvent("GOSSIP_SHOW", ME.BloodyJarOpen);
		end
	end); ]]

local chatmsg = CreateFrame("CheckButton", "MysticExtendedOptions_ChatMSG", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	chatmsg:SetPoint("TOPLEFT", 15, -310);
	chatmsg.Lable = chatmsg:CreateFontString(nil , "BORDER", "GameFontNormal");
	chatmsg.Lable:SetJustifyH("LEFT");
	chatmsg.Lable:SetPoint("LEFT", 30, 0);
	chatmsg.Lable:SetText("Show Enchant Learned Messages");
	chatmsg:SetScript("OnClick", function()
		if ME.db.ChatMSG then
			ME.db.ChatMSG = false
		else
			ME.db.ChatMSG = true
		end
	end);

local extractwarn = CreateFrame("CheckButton", "MysticExtendedOptions_ExtractWarning", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	extractwarn:SetPoint("TOPLEFT", 15, -345);
	extractwarn.Lable = extractwarn:CreateFontString(nil , "BORDER", "GameFontNormal");
	extractwarn.Lable:SetJustifyH("LEFT");
	extractwarn.Lable:SetPoint("LEFT", 30, 0);
	extractwarn.Lable:SetText("Toggle Extract Warning On Extract Interface");
	extractwarn:SetScript("OnClick", function()
		if ME.db.ExtractWarn then
			ME.db.ExtractWarn = false
		else
			ME.db.ExtractWarn = true
		end
	end);

local mapicon = CreateFrame("CheckButton", "MysticExtendedOptions_MapIcon", MysticExtendedOptionsFrame, "UICheckButtonTemplate");
	mapicon:SetPoint("TOPLEFT", 15, -380)
	mapicon.Lable = mapicon:CreateFontString(nil , "BORDER", "GameFontNormal")
	mapicon.Lable:SetJustifyH("LEFT")
	mapicon.Lable:SetPoint("LEFT", 30, 0)
	mapicon.Lable:SetText("Hide Minimap Button")
	mapicon:SetScript("OnClick", function()
		ME:ToggleMinimap()
	end);

	local moneyframe = CreateFrame("Frame","MysticExtended_MoneyFrame", MysticExtendedOptionsFrame, "MoneyInputFrameTemplate")
		moneyframe:SetPoint("TOPRIGHT", -70, -60)
		moneyframe.Lable = moneyframe:CreateFontString(nil , "BORDER", "GameFontNormal")
		moneyframe.Lable:SetJustifyH("LEFT")
		moneyframe.Lable:SetPoint("TOPLEFT", -5, 20)
		moneyframe.Lable:SetText("Reforge Minium Keep Price")
		moneyframe:Hide()
		moneyframe:SetScript("OnShow", function()
		MoneyInputFrame_SetCopper(MysticExtended_MoneyFrame,MysticExtendedDB.MinGold)
		end)
		MoneyInputFrame_SetOnValueChangedFunc(moneyframe, function()
			MysticExtendedDB.MinGold = MoneyInputFrame_GetCopper(moneyframe)
		end)