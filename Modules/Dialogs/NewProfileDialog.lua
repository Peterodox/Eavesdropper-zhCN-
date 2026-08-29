-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

local L = ED.Localization;

---@type EavesdropperConstants
local Constants = ED.Constants;

---@class EavesdropperNewProfileDialog
local NewProfileDialog = {};

---Attempts to create a profile named after the trimmed text in the edit box.
---@param profileName string
---@return boolean success
local function TryCreate(profileName)
	if not ED.Database:IsValidNewProfileName(profileName) then return false; end
	return ED.Database:CreateProfile(string.trim(profileName));
end

StaticPopupDialogs["EAVESDROPPER_NEW_PROFILE"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = Constants.MAX_PROFILE_NAME_LENGTH,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(self)
		TryCreate(self.EditBox:GetText());
	end,
	OnShow = function(self)
		local button1 = _G[self:GetName() .. "Button1"];
		if button1 then
			button1:Disable();
		end
		self.EditBox:SetText("");
		self.EditBox:SetFocus();
	end,
	EditBoxOnTextChanged = function(self)
		local popup = self:GetParent();
		local button1 = _G[popup:GetName() .. "Button1"];
		if not button1 then return; end

		button1:SetEnabled(ED.Database:IsValidNewProfileName(self:GetText()));
	end,
	EditBoxOnEscapePressed = function()
		StaticPopup_Hide("EAVESDROPPER_NEW_PROFILE");
	end,
	EditBoxOnEnterPressed = function(self)
		if TryCreate(self:GetText()) then
			StaticPopup_Hide("EAVESDROPPER_NEW_PROFILE");
		end
	end,
};

---Prompts for the name of a new profile, replacing any other open profile name prompt.
function NewProfileDialog.Show()
	ED.Utils.HideProfileNamePopups();

	StaticPopupDialogs["EAVESDROPPER_NEW_PROFILE"].text = L.POPUP_NEW_PROFILE;
	StaticPopup_Show("EAVESDROPPER_NEW_PROFILE");
end

ED.NewProfileDialog = NewProfileDialog;
