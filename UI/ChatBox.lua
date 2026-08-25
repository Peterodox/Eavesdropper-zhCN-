-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

---@type EavesdropperConstants
local Constants = ED.Constants;

---@type EavesdropperEnums
local Enums = ED.Enums;

---@class EavesdropperChatBox
local ChatBox = {};

---@type table
local SharedMedia = LibStub("LibSharedMedia-3.0");

---Apply all font-related options from the database
---@param frame table?
function ChatBox:ApplyFontOptions(frame)
	local owner = frame or ED.Frame;
	local chatBox = owner and owner.ChatBox;
	if not chatBox then
		return;
	end

	local outline = ED.Database:GetSetting("FontOutline");
	local face = ED.Database:GetSetting("FontFace");
	local profileKey = owner:GetProfileFontSizeKey();
	local size = profileKey and ED.Database:GetSetting(profileKey) or owner.FontSize;
	local shadow = ED.Database:GetSetting("FontShadow");

	local flags = "";
	if outline == Enums.CHAT_BOX.FONT_OUTLINE.OUTLINE then
		flags = "OUTLINE";
	elseif outline == Enums.CHAT_BOX.FONT_OUTLINE.THICKOUTLINE then
		flags = "THICKOUTLINE";
	end

	local font = SharedMedia:Fetch("font", face);
	if font then
		chatBox:SetFont(font, size, flags);
	end

	if shadow then
		chatBox:SetShadowColor(0, 0, 0, 0.8);
		chatBox:SetShadowOffset(1, -1);
	else
		chatBox:SetShadowColor(0, 0, 0, 0);
	end
end

---Adjust font size by delta (+1 / -1)
---@param frame table
---@param delta number
function ChatBox:AdjustFontSize(frame, delta)
	local profileKey = frame:GetProfileFontSizeKey();
	local size = profileKey and ED.Database:GetSetting(profileKey) or frame.FontSize;
	if not size then
		return;
	end

	size = Clamp(size + delta, Constants.CHAT_BOX.MIN_FONT_SIZE, Constants.CHAT_BOX.MAX_FONT_SIZE);

	if profileKey then
		ED.Database:SetSetting(profileKey, size);
	else
		frame.FontSize = size;
		frame:SaveInstanceState();
	end

	self:ApplyFontOptions(frame);
end

ED.ChatBox = ChatBox;
