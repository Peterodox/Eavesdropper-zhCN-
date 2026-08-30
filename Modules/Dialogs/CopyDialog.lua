-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

local L = ED.Localization;

---@type EavesdropperConstants
local Constants = ED.Constants;

---@class EavesdropperCopyDialog
local CopyDialog = {};

---Attempts to duplicate sourceName into a new profile named after the trimmed edit box text.
---@param sourceName string?
---@param newName string
---@return boolean success
local function TryCopy(sourceName, newName)
	if not sourceName then return false; end
	if not ED.Database:IsValidNewProfileName(newName) then return false; end
	return ED.Database:CloneProfile(sourceName, string.trim(newName));
end

StaticPopupDialogs["EAVESDROPPER_COPY_PROFILE"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = Constants.MAX_PROFILE_NAME_LENGTH,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(self, data)
		TryCopy(data and data.sourceName, self.EditBox:GetText());
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
		StaticPopup_Hide("EAVESDROPPER_COPY_PROFILE");
	end,
	EditBoxOnEnterPressed = function(self, data)
		if TryCopy(data and data.sourceName, self:GetText()) then
			StaticPopup_Hide("EAVESDROPPER_COPY_PROFILE");
		end
	end,
};

---Prompts for the name of a new profile copied from an existing one, replacing any other open profile name prompt.
---@param profileName string The profile being copied from.
function CopyDialog.Show(profileName)
	ED.Utils.HideProfileNamePopups();

	StaticPopupDialogs["EAVESDROPPER_COPY_PROFILE"].text = L.POPUP_COPY_PROFILE:format(profileName);
	StaticPopup_Show("EAVESDROPPER_COPY_PROFILE", nil, nil, { sourceName = profileName });
end

ED.CopyDialog = CopyDialog;
