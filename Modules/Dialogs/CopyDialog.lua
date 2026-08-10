-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

---@class EavesdropperCopyDialog
local CopyDialog = {};

local MaxProfileNameLength = 32;

---Attempts to duplicate sourceName into a new profile named after the trimmed edit box text.
---@param sourceName string?
---@param newName string
---@return boolean success
local function tryCopy(sourceName, newName)
	if not sourceName then return false; end
	if not ED.Database:IsValidNewProfileName(newName) then return false; end
	return ED.Database:CloneProfile(sourceName, string.trim(newName));
end

StaticPopupDialogs["EAVESDROPPER_COPY_PROFILE"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = MaxProfileNameLength,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnAccept = function(self, data)
		tryCopy(data and data.sourceName, self.EditBox:GetText());
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
		if tryCopy(data and data.sourceName, self:GetText()) then
			StaticPopup_Hide("EAVESDROPPER_COPY_PROFILE");
		end
	end,
};

ED.CopyDialog = CopyDialog;
