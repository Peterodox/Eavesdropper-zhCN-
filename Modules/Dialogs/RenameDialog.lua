-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

---@class EavesdropperRenameDialog
local RenameDialog = {};

local MaxProfileNameLength = 32;

---Attempts to rename the profile from oldName to the trimmed text in the edit box.
---@param oldName string?
---@param newName string
---@return boolean success
local function tryRename(oldName, newName)
	if not oldName then return false; end
	if not ED.Database:IsValidNewProfileName(newName) then return false; end
	return ED.Database:RenameProfile(oldName, string.trim(newName));
end

StaticPopupDialogs["EAVESDROPPER_RENAME_PROFILE"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = MaxProfileNameLength,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(self, data)
		tryRename(data and data.oldName, self.EditBox:GetText());
	end,
	OnShow = function(self, data)
		local button1 = _G[self:GetName() .. "Button1"];
		if button1 then
			button1:Disable();
		end
		local currentName = data and data.oldName or "";
		self.EditBox:SetText(currentName);
		self.EditBox:HighlightText();
		self.EditBox:SetFocus();
	end,
	EditBoxOnTextChanged = function(self)
		local popup = self:GetParent();
		local button1 = _G[popup:GetName() .. "Button1"];
		if not button1 then return; end

		-- The old name is itself an existing profile, so the duplicate check also rejects an unchanged name.
		button1:SetEnabled(ED.Database:IsValidNewProfileName(self:GetText()));
	end,
	EditBoxOnEscapePressed = function(self)
		StaticPopup_Hide("EAVESDROPPER_RENAME_PROFILE");
	end,
	EditBoxOnEnterPressed = function(self, data)
		if tryRename(data and data.oldName, self:GetText()) then
			StaticPopup_Hide("EAVESDROPPER_RENAME_PROFILE");
		end
	end,
};

ED.RenameDialog = RenameDialog;
