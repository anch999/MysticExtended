-- **********************************************************************
-- EnchantListShare:
--	<local>SpamProtect(name)
-- 	MysticExtended:OnEnable()
--	MysticExtended_GetEnchantList(wlstrg,sendername)
--	MysticExtended:OnCommReceived(prefix, message, distribution, sender)
-- **********************************************************************
local playerName = UnitName("player");
local realmName = GetRealmName();
local SpamFilter = {}
local SpamFilterTime = 10
MysticExtended_OptionsMenu = AceLibrary("Dewdrop-2.0");

-- Colours stored for code readability
local GREY = "|cff999999";
local RED = "|cffff0000";
local WHITE = "|cffFFFFFF";
local GREEN = "|cff1eff00";
local PURPLE = "|cff9F3FFF";
local BLUE = "|cff0070dd";
local ORANGE = "|cffFF8400";

--[[
<local> SpamProtect(name)
Check Spamfilter table
]]
local function SpamProtect(name)
	if not name then return true end
	if SpamFilter[string.lower(name)] then
		if GetTime() - SpamFilter[string.lower(name)] > SpamFilterTime then
			SpamFilter[string.lower(name)] = nil
			return true
		else
			return false
		end
	else
		return true
	end
end

--[[
MysticExtended_GetEnchantList(wlstrg,sendername)
Get the EnchantList, Deserialize it and save it in the savedvariables table
]]
function MysticExtended_GetEnchantList(wlstrg,sendername)
	local success, wltab = MysticExtended:Deserialize(wlstrg);
	if success then
		tinsert(MysticExtendedDB["EnchantSaveLists"], {Name = wltab["Name"], [realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false}});
		for i,v in ipairs(wltab) do
			tinsert(MysticExtendedDB["EnchantSaveLists"][#MysticExtendedDB["EnchantSaveLists"]], v)
		end
		MysticExtended:MenuInitialize();
	end
end

--[[
StaticPopupDialogs["MYSTICEXTENDED_GET_ENCHANTLIST"]
This is shown, if someone send you a Enchantlist
]]
StaticPopupDialogs["MYSTICEXTENDED_GET_ENCHANTLIST"] = {
	text = "%s sends you an Enchantlist. Accept?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function()
		this:SetFrameStrata("TOOLTIP");
	end,
	OnAccept = function(self,data)
		MysticExtended:SendCommMessage("MysticExtendedEnchantList", "AcceptEnchantList", "WHISPER", data)
	end,
	OnCancel = function (self,data)
		MysticExtended:SendCommMessage("MysticExtendedEnchantList", "CancelEnchantlist", "WHISPER", data)
	end,
	timeout = 15,
	whileDead = 1,
	hideOnEscape = 1
}

--[[
MysticExtended:OnCommReceived(prefix, message, distribution, sender)
Incomming messages from AceComm
]]
function MysticExtended:OnCommReceived(prefix, message, distribution, sender)
	if prefix ~= "MysticExtendedEnchantList" then return end
	if message == "SpamProtect" then
		--local _,_,timeleft = string.find( 10-(GetTime() - SpamFilter[string.lower(sender)]), "(%d+)%.")
		--DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticExtended"..": "..RED.."You must wait "..WHITE..timeleft..RED.." seconds before you can send a new EnchantList too "..WHITE..sender..RED..".");
	elseif message == "FinishSend" then
		SpamFilter[string.lower(sender)] = GetTime()
	elseif message == "AcceptEnchantList" then
		local wsltable = {};
			for i,v in ipairs(MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]]) do
				tinsert(wsltable,{v[1]});
			end
			wsltable["Name"] = MysticExtendedDB["EnchantSaveLists"][MysticExtendedDB["currentSelectedList"]]["Name"];
		local sendData = MysticExtended:Serialize(wsltable);
		MysticExtended:SendCommMessage("MysticExtendedEnchantList", sendData, "WHISPER", sender);
	elseif message == "EnchantListRequest" then
		if MysticExtendedDB["AllowShareEnchantList"] then
			if MysticExtendedDB["AllowShareEnchantListInCombat"] then
				if UnitAffectingCombat("player") then
					MysticExtended:SendCommMessage("MysticExtendedEnchantList", "CancelEnchantList", "WHISPER", sender)
					DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticExtended"..": "..WHITE..sender..RED.." tried to send you a EnchantList. Rejected because you are in combat.");
				else
					local dialog = StaticPopup_Show("MYSTICEXTENDED_GET_ENCHANTLIST", sender);
					if ( dialog ) then
						dialog.data = sender;
					end
				end
			else
				local dialog = StaticPopup_Show("MYSTICEXTENDED_GET_ENCHANTLIST", sender);
				if ( dialog ) then
					dialog.data = sender;
				end
			end
		else
			MysticExtended:SendCommMessage("MysticExtendedEnchantList", "CancelEnchantList", "WHISPER", sender);
		end

	elseif message == "CancelEnchantList" then
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticExtended"..": "..WHITE..sender..RED.." rejects your EnchantList.");
	else
		SpamFilter[string.lower(sender)] = GetTime()
		MysticExtended_GetEnchantList(message,sender)
		MysticExtended:SendCommMessage("MysticExtendedEnchantList", "FinishSend", "WHISPER", sender)
	end
end

--[[
StaticPopupDialogs["MYSTICEXTENDED_SEND_ENCHANTLIST"]
This is shown, if you want too share a EnchantList
]]
StaticPopupDialogs["MYSTICEXTENDED_SEND_ENCHANTLIST"] = {
	text = "Send Enchant List (%s)",
	button1 = "Send",
	button2 = "Cancel",
	OnShow = function(self)
		MysticExtended_OptionsMenu:Close();
		self:SetFrameStrata("TOOLTIP");
	end,
	OnAccept = function()
		local name = _G[this:GetParent():GetName().."EditBox"]:GetText()
		if name == "" then return end
		if string.lower(name) == string.lower(playerName) then
			DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticExtended"..": "..RED.."You can't send EnchantLists to yourself.");
		else
			if SpamProtect(string.lower(name)) then
				MysticExtended:SendCommMessage("MysticExtendedEnchantList", "EnchantListRequest", "WHISPER", name);
			else
				local _,_,timeleft = string.find( 10-(GetTime() - SpamFilter[string.lower(name)]), "(%d+)%.")
				DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticExtended"..": "..RED.."You must wait "..WHITE..timeleft..RED.." seconds before you can send a new EnchantList to "..WHITE..name..RED..".");
			end
		end
	end,
	hasEditBox = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

--[[
StaticPopupDialogs["MYSTICEXTENDED_IMPORT_ENCHANTLIST"]
This is shown, if you want too import an EnchantList
]]
StaticPopupDialogs["MYSTICEXTENDED_IMPORT_ENCHANTLIST"] = {
	text = "Paste List String To Import",
	button1 = "Import",
	button2 = "Cancel",
	OnShow = function(self)
		MysticExtended_OptionsMenu:Close();
		self:SetFrameStrata("TOOLTIP");
	end,
	OnAccept = function()
		local data = string.sub(_G[this:GetParent():GetName().."EditBox"]:GetText(), 5)
		local success, wltab = MysticExtended:Deserialize(data);
	if success then
		tinsert(MysticExtendedDB["EnchantSaveLists"], {Name = wltab["Name"], [realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false}});
		for i,v in ipairs(wltab) do
			tinsert(MysticExtendedDB["EnchantSaveLists"][#MysticExtendedDB["EnchantSaveLists"]], v)
		end
		MysticExtended:MenuInitialize();
	end
	end,
	hasEditBox = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}