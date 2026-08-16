-- Copyright The Eavesdropper Authors
-- Inspired by Sippy Cup
-- SPDX-License-Identifier: GPL-3.0-or-later

local L = ED.Localization;

---@class EavesdropperCopyTextDialog
local CopyTextDialog = {};

---Returns the editBox child of a StaticPopup dialog, handling both API styles.
---Borrowed from Total RP 3.
---@param dialog table
---@return table
local function GetDialogEditBox(dialog)
	return dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox;
end

---Applies ElvUI skin to the dialog's editBox if ElvUITheme is enabled.
---@param editBox table
local function SkinEditBox(editBox)
	local E = ElvUI and ElvUI[1];
	if not E or not ED.Database:GetGlobalSetting("ElvUITheme") then return; end
	local S = E:GetModule("Skins");
	if not S then return; end

	S:HandleEditBox(editBox);
end

---Populates and wires up the editBox for URL display and keyboard interaction.
---@param editBox table
---@param url string?
local function SetupEditBox(editBox, url)
	editBox:SetText(url or "");
	editBox:HighlightText();
	editBox:SetFocus();

	editBox:SetScript("OnEditFocusGained", function(self)
		self:HighlightText();
	end);

	editBox:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			self:GetParent():Hide();
		elseif key == "C" and IsControlKeyDown() then
			self:HighlightText();
			UIErrorsFrame:AddMessage(L.COPY_SYSTEM_MESSAGE, YELLOW_FONT_COLOR:GetRGB());
			RunNextFrame(function()
				self:GetParent():Hide();
			end);
		end
	end);
end

StaticPopupDialogs["EAVESDROPPER_COPY_TEXT_DIALOG"] = {
	button1 = CANCEL,
	hasEditBox = true,
	maxLetters = 0,
	editBoxWidth = 320,
	OnShow = function(self)
		local editBox = GetDialogEditBox(self);
		SkinEditBox(editBox);
		SetupEditBox(editBox, StaticPopupDialogs["EAVESDROPPER_COPY_TEXT_DIALOG"].url or "");
	end,
	timeout = false,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
};

---Displays a static popup dialog containing the given text in a copyable editBox.
---@param text string
---@param value string
local function ShowCopyDialog(text, value)
	StaticPopupDialogs["EAVESDROPPER_COPY_TEXT_DIALOG"].text = text;
	StaticPopupDialogs["EAVESDROPPER_COPY_TEXT_DIALOG"].url = value;
	local dialog = StaticPopup_Show("EAVESDROPPER_COPY_TEXT_DIALOG");
	if dialog then
		dialog:ClearAllPoints();
		dialog:SetPoint("CENTER", UIParent, "CENTER");
	end
end

---Displays a static popup dialog containing the given URL in a copyable editBox.
---@param url string
function CopyTextDialog.CreateExternalLinkDialog(url)
	ShowCopyDialog(ED.Globals.addon_title .. L.POPUP_LINK, url);
end

---Displays a static popup dialog containing the given character name in a copyable editBox.
---@param name string
function CopyTextDialog.ShowCopyName(name)
	ShowCopyDialog(ED.Globals.addon_title .. L.POPUP_COPY_NAME, name);
end

ED.CopyTextDialog = CopyTextDialog;
