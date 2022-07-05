local MysticExtended_options_swap = "Last Active Spec";
local quickSwapNum = "";
local lastSpecPos

function MysticExtendedOptions_Toggle()
    if InterfaceOptionsFrame:IsVisible() then
		InterfaceOptionsFrame:Hide();
	else
		InterfaceOptionsFrame_OpenToCategory("MysticExtended");
	end
end

local function MysticExtendedOptions_Menu_OnClick()
    local thisID = this:GetID();
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_Menu, thisID);
	MysticExtendedOptions_NameEdit:SetText(MysticExtendedDB["Specs"][thisID][1])
	
	if MysticExtendedDB["Specs"][thisID][2] == "LastSpec" then
		UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap1, lastSpecPos);
	else
		UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap1, MysticExtendedDB["Specs"][thisID][2]);
	end
	
	if MysticExtendedDB["Specs"][thisID][3] == "LastSpec" then
		UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap1, lastSpecPos);
	else
		UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap2, MysticExtendedDB["Specs"][thisID][3]);
	end
	
	SpMenuSpecNum = thisID;
	MysticExtended_QuickswapNum1 = MysticExtendedDB["Specs"][thisID][2];
	MysticExtended_QuickswapNum2 = MysticExtendedDB["Specs"][thisID][3];
end

local function MysticExtendedOptions_Menu_Initialize()
    local info;
	for k,v in pairs(MysticExtendedDB["Specs"]) do
				info = {
					text = MysticExtendedDB["Specs"][k][1];
					func = MysticExtendedOptions_Menu_OnClick;
				};
					UIDropDownMenu_AddButton(info);
	end
end

local function MysticExtendedOptions_NameEditCheckToggle()
	if MysticExtendedOptions_NameEditCheck:GetChecked() then
		MysticExtendedDB["EditAscenSpec"] = MysticExtendedOptions_NameEditCheck:GetChecked()
	else
		MysticExtendedDB["EditAscenSpec"] = MysticExtendedOptions_NameEditCheck:GetChecked()
	end
end

local function MysticExtendedOptions_PresetNameEditCheckToggle()
	if MysticExtendedOptions_PresetNameEditCheck:GetChecked() then
		MysticExtendedDB["EditAscenPreset"] = MysticExtendedOptions_PresetNameEditCheck:GetChecked()
	else
		MysticExtendedDB["EditAscenPreset"] = MysticExtendedOptions_PresetNameEditCheck:GetChecked()
	end
end

local function MysticExtendedOptions_PresetNameEdit_OnClick()
	local thisID = this:GetID();
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_PresetMenu, thisID);
	MysticExtendedOptions_PresetNameEdit:SetText(MysticExtendedDB["EnchantPresets"][thisID]);
	MysticExtendedOptions_PresetSet = thisID;
end

local function MysticExtendedOptions_PresetMenu_Initialize()
	--Loads the enchant preset list into the enchant preset dropdown menu
	local info;
	for k,v in pairs(MysticExtendedDB["EnchantPresets"]) do
		info = {
					text = MysticExtendedDB["EnchantPresets"][k];
					func = MysticExtendedOptions_PresetNameEdit_OnClick;
				};
					UIDropDownMenu_AddButton(info);
	end
end

local function MysticExtendedOptions_QuickSwapLastSpec_OnClick(num)
	local thisID = this:GetID();
	if quickSwapNum == "1" then
		UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap1, thisID);
		MysticExtended_QuickswapNum1 = "LastSpec";
		MysticExtendedDB["Specs"][SpMenuSpecNum][2] = "LastSpec";
	elseif quickSwapNum == "2" then
		UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap2, thisID);
		MysticExtended_QuickswapNum2 = "LastSpec";
		MysticExtendedDB["Specs"][SpMenuSpecNum][3] = "LastSpec";
	end
end

local function MysticExtendedOptions_QuickSwap1_OnClick()
	local thisID = this:GetID();
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap1, thisID);
	MysticExtended_QuickswapNum1 = thisID;
	MysticExtendedDB["Specs"][SpMenuSpecNum][2] = MysticExtended_QuickswapNum1;
	
end

local function MysticExtendedOptions_QuickSwap1_Initialize()
	--Loads the spec list into the quickswap1 dropdown menu
	local info;
	for k,v in pairs(MysticExtendedDB["Specs"]) do
		info = {
					text = MysticExtendedDB["Specs"][k][1];
					func = MysticExtendedOptions_QuickSwap1_OnClick;
				};
					UIDropDownMenu_AddButton(info);
					lastSpecPos = k + 1
	end
	--Adds Lastspec as the last entry on the quickswap1 dropdown menu 
	info = {
		text = MysticExtended_options_swap;
		func = MysticExtendedOptions_QuickSwapLastSpec_OnClick;
	};
		UIDropDownMenu_AddButton(info);
		quickSwapNum = "1"
end

local function MysticExtendedOptions_QuickSwap2_OnClick()
	local thisID = this:GetID();
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap2, thisID);
	MysticExtended_QuickswapNum2 = thisID;
	MysticExtendedDB["Specs"][SpMenuSpecNum][3] = MysticExtended_QuickswapNum2;
end

function MysticExtendedOptions_QuickSwap2_Initialize()
	--Loads the spec list into the quickswap2 dropdown menu
	local info;
	for k,v in pairs(MysticExtendedDB["Specs"]) do
		info = {
			text = MysticExtendedDB["Specs"][k][1];
			func = MysticExtendedOptions_QuickSwap2_OnClick;
		};
			UIDropDownMenu_AddButton(info);
			lastSpecPos = k + 1
	end
	--Adds Lastspec as the last entry on the quickswap2 dropdown menu 
	info = {
		text = MysticExtended_options_swap;
		func = MysticExtendedOptions_QuickSwapLastSpec_OnClick;
	};
		UIDropDownMenu_AddButton(info);
		quickSwapNum = "2"

end

local function MysticExtended_DropDownInitialize()
	--Setup for Dropdown menus in the settings
	UIDropDownMenu_Initialize(MysticExtendedOptions_Menu, MysticExtendedOptions_Menu_Initialize);
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_Menu);
	UIDropDownMenu_SetWidth(MysticExtendedOptions_Menu, 150);

	UIDropDownMenu_Initialize(MysticExtendedOptions_QuickSwap1, MysticExtendedOptions_QuickSwap1_Initialize);
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap1);
	UIDropDownMenu_SetWidth(MysticExtendedOptions_QuickSwap1, 150);

	UIDropDownMenu_Initialize(MysticExtendedOptions_QuickSwap2, MysticExtendedOptions_QuickSwap2_Initialize);
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap2);
	UIDropDownMenu_SetWidth(MysticExtendedOptions_QuickSwap2, 150);

	UIDropDownMenu_Initialize(MysticExtendedOptions_PresetMenu, MysticExtendedOptions_PresetMenu_Initialize);
	UIDropDownMenu_SetSelectedID(MysticExtendedOptions_PresetMenu);
	UIDropDownMenu_SetWidth(MysticExtendedOptions_PresetMenu, 150);
end

local function MysticExtendedOptions_UpatePresetDB_OnClick()
		--Updates the name of the Enchant Preset selected
		MysticExtendedDB["EnchantPresets"][MysticExtendedOptions_PresetSet] = MysticExtendedOptions_PresetNameEdit:GetText();
		UIDropDownMenu_SetText(MysticExtendedOptions_PresetMenu, MysticExtendedDB["EnchantPresets"][MysticExtendedOptions_PresetSet]);
		--Overwrites   the ascension Enchant Preset names if checkbox is selected
		if MysticExtendedDB["EditAscenPreset"] then
			if AscensionUI_CDB["EnchantManager"]["presets"][MysticExtendedOptions_PresetSet].name then
				AscensionUI_CDB["EnchantManager"]["presets"][MysticExtendedOptions_PresetSet].name = MysticExtendedOptions_PresetNameEdit:GetText();
			else
				AscensionUI_CDB["EnchantManager"]["presets"][MysticExtendedOptions_PresetSet] = {"name"}
				AscensionUI_CDB["EnchantManager"]["presets"][MysticExtendedOptions_PresetSet].name = MysticExtendedOptions_PresetNameEdit:GetText();
			end
				--If there is no icon selected it will update it to the default otherwise the updated names wont show
				if AscensionUI_CDB["EnchantManager"]["presets"][MysticExtendedOptions_PresetSet].icon == nil then
					AscensionUI_CDB["EnchantManager"]["presets"][MysticExtendedOptions_PresetSet].icon = "Interface\\Icons\\inv_misc_book_16";
				end
		end
end

local function MysticExtendedOptions_UpateDB_OnClick()
		--Updates the name of the Spec selected
		if MysticExtended_EnableMenu() then
		MysticExtendedDB["Specs"][SpMenuSpecNum][1] = MysticExtendedOptions_NameEdit:GetText();
		UIDropDownMenu_SetText(MysticExtendedOptions_Menu, MysticExtendedDB["Specs"][SpMenuSpecNum][1]);
		--Overwrites the ascension Spec names if checkbox is selected
			if MysticExtendedDB["EditAscenSpec"] then
				AscensionUI_CDB["CA2"]["SpecNamesCustom"][SpMenuSpecNum] = MysticExtendedOptions_NameEdit:GetText();
					--If there is no icon selected it will update it to the default otherwise the updated names wont show
					if AscensionUI_CDB["CA2"]["SpecIconsCustom"][SpMenuSpecNum] == nil then
						AscensionUI_CDB["CA2"]["SpecIconsCustom"][SpMenuSpecNum] = "Interface\\Icons\\inv_misc_book_16";
					end
			end
		end
end

function MysticExtendedOptions_OpenOptions()
	if MysticExtended_EnableMenu() then
			local menuID = MysticExtended_SpecId();
			UIDropDownMenu_SetSelectedID(MysticExtendedOptions_Menu, menuID);
			UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap1, MysticExtendedDB["Specs"][menuID][2]);
			UIDropDownMenu_SetSelectedID(MysticExtendedOptions_QuickSwap2, MysticExtendedDB["Specs"][menuID][3]);
			MysticExtendedOptions_NameEdit:SetText(MysticExtendedDB["Specs"][menuID][1]);
			MysticExtendedOptions_NameEdit:SetCursorPosition(0)
		if MysticExtendedDB["Specs"][menuID][2] == "LastSpec" then
			UIDropDownMenu_SetText(MysticExtendedOptions_QuickSwap1, MysticExtended_options_swap);
		else
			UIDropDownMenu_SetText(MysticExtendedOptions_QuickSwap1, MysticExtendedDB["Specs"][MysticExtendedDB["Specs"][menuID][2]][1]);
		end
		if MysticExtendedDB["Specs"][menuID][3] == "LastSpec" then
			UIDropDownMenu_SetText(MysticExtendedOptions_QuickSwap2, MysticExtended_options_swap);
		else
			UIDropDownMenu_SetText(MysticExtendedOptions_QuickSwap2, MysticExtendedDB["Specs"][MysticExtendedDB["Specs"][menuID][3]][1]);
		end
			UIDropDownMenu_SetText(MysticExtendedOptions_Menu, MysticExtendedDB["Specs"][menuID][1]);
			SpMenuSpecNum = menuID;
			MysticExtended_QuickswapNum1 = MysticExtendedDB["Specs"][menuID][2];
			MysticExtended_QuickswapNum2 = MysticExtendedDB["Specs"][menuID][3];
	end
		local presetID = MysticExtended_PresetId();
		UIDropDownMenu_SetSelectedID(MysticExtendedOptions_PresetMenu, presetID);
		UIDropDownMenu_SetText(MysticExtendedOptions_PresetMenu, MysticExtendedDB["EnchantPresets"][presetID]);
		if MysticExtendedDB["EnchantPresets"][presetID] ~= nil then
		MysticExtendedOptions_PresetNameEdit:SetText(MysticExtendedDB["EnchantPresets"][presetID]);
		MysticExtendedOptions_PresetNameEdit:SetCursorPosition(0)
		end
		MysticExtendedOptions_PresetSet = presetID;
		MysticExtendedOptions_NameEditCheck:SetChecked(MysticExtendedDB["EditAscenSpec"])
		MysticExtendedOptions_PresetNameEditCheck:SetChecked(MysticExtendedDB["EditAscenPreset"])	
end

--Creates the options frame and all its assets
function MysticExtendedOptions_CreateFrame()
	InterfaceOptionsFrame:SetWidth(850)
	local mainframe = {};
		mainframe.panel = CreateFrame("FRAME", "MysticExtendedOptionsFrame", UIParent, nil);
    	local fstring = mainframe.panel:CreateFontString(mainframe, "OVERLAY", "GameFontNormal");
		fstring:SetText("Spec Menu Settings");
		fstring:SetPoint("TOPLEFT", 15, -15)
		mainframe.panel.name = "MysticExtended";
		InterfaceOptions_AddCategory(mainframe.panel);

	local editbox1 = CreateFrame("EditBox", "MysticExtendedOptions_NameEdit", MysticExtendedOptionsFrame, "InputBoxTemplate");
	editbox1:SetPoint("TOPLEFT", MysticExtendedOptionsFrame, "TOPLEFT", 39, -89);
	editbox1:SetSize(160,24);
    editbox1:SetAutoFocus(false);
	editbox1:SetMaxLetters(30);
	editbox1:SetScript("OnEditFocusGained", function() 
		editbox1:SetScript("OnTextChanged", function() MysticExtendedOptions_UpateDB_OnClick() end) 
	end)
	editbox1:SetScript("OnEditFocusLost", function() editbox1:SetScript("OnTextChanged", nil) end)

	local MysticExtended = CreateFrame("Button", "MysticExtendedOptions_Menu", MysticExtendedOptionsFrame, "UIDropDownMenuTemplate");
    MysticExtended:SetPoint("TOPLEFT", 15, -60);
	MysticExtended.Lable = MysticExtended:CreateFontString(nil , "BORDER", "GameFontNormal")
	MysticExtended.Lable:SetJustifyH("LEFT")
	MysticExtended.Lable:SetPoint("TOPLEFT", MysticExtended, "TOPLEFT", 20, 20)
	MysticExtended.Lable:SetText("Select Spec To Edit")
	MysticExtended:SetScript("OnClick", MysticExtendedOptions_UpateDB_OnClick);

	local quickswap1 = CreateFrame("Button", "MysticExtendedOptions_QuickSwap1", MysticExtendedOptionsFrame, "UIDropDownMenuTemplate");
    quickswap1:SetPoint("TOPLEFT", 190, -60);
	quickswap1.Lable = quickswap1:CreateFontString(nil , "BORDER", "GameFontNormal")
	quickswap1.Lable:SetJustifyH("RIGHT")
	quickswap1.Lable:SetPoint("TOPLEFT", quickswap1, "TOPLEFT", 20, 20)
	quickswap1.Lable:SetText("QuickSwap Left Click")

	local quickswap2 = CreateFrame("Button", "MysticExtendedOptions_QuickSwap2", MysticExtendedOptionsFrame, "UIDropDownMenuTemplate");
    quickswap2:SetPoint("TOPLEFT", MysticExtendedOptionsFrame, "TOPLEFT", 190, -89);
	quickswap2.Lable = quickswap2:CreateFontString(nil , "BORDER", "GameFontNormal")
	quickswap2.Lable:SetJustifyH("RIGHT")
	quickswap2.Lable:SetPoint("BOTTOMLEFT", quickswap2, "BOTTOMLEFT", 20, -20)
	quickswap2.Lable:SetText("QuickSwap Right Click")

	local editbox2 = CreateFrame("EditBox", "MysticExtendedOptions_PresetNameEdit", MysticExtendedOptionsFrame, "InputBoxTemplate");
	editbox2:SetPoint("TOPLEFT", 39, -209);
	editbox2:SetSize(160,24)
    editbox2:SetAutoFocus(false);
	editbox2:SetScript("OnEditFocusGained", function()
		editbox2:SetScript("OnTextChanged", function() MysticExtendedOptions_UpatePresetDB_OnClick() end) 
	end)
	editbox2:SetScript("OnEditFocusLost", function() editbox2:SetScript("OnTextChanged", nil) end)

	local presetmenu = CreateFrame("Button", "MysticExtendedOptions_PresetMenu", MysticExtendedOptionsFrame, "UIDropDownMenuTemplate");
    presetmenu:SetPoint("TOPLEFT", 15, -180);
	presetmenu.Lable = presetmenu:CreateFontString(nil , "BORDER", "GameFontNormal")
	presetmenu.Lable:SetJustifyH("RIGHT")
	presetmenu.Lable:SetPoint("TOPLEFT", presetmenu, "TOPLEFT", 20, 20)
	presetmenu.Lable:SetText("Select Enchant Preset To Edit")

	local updateAscenUI1 = CreateFrame("CheckButton", "MysticExtendedOptions_NameEditCheck", MysticExtendedOptionsFrame, "OptionsCheckButtonTemplate")
	updateAscenUI1:SetPoint("TOPLEFT", 5, -89);
	updateAscenUI1:SetScript("OnClick", MysticExtendedOptions_NameEditCheckToggle);
	updateAscenUI1:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText("Overwrite Ascension Spec Names")
		GameTooltip:Show()
	end)
	updateAscenUI1:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local updateAscenUI2 = CreateFrame("CheckButton", "MysticExtendedOptions_PresetNameEditCheck", MysticExtendedOptionsFrame, "OptionsCheckButtonTemplate")
	updateAscenUI2:SetPoint("TOPLEFT", 5, -209);
	updateAscenUI2:SetScript("OnClick", MysticExtendedOptions_PresetNameEditCheckToggle);
	updateAscenUI2:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText("Overwrite Ascension Preset Names")
		GameTooltip:Show()
	end)
	updateAscenUI2:SetScript("OnLeave", function() GameTooltip:Hide() end)

	MysticExtended_DropDownInitialize();
end

