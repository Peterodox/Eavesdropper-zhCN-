-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

---@type EavesdropperConstants
local Constants = ED.Constants;

---@class EavesdropperChatHandler
local ChatHandler = {};

-- TRP3 strips a raw "'s "/", " emote prefix to reinsert it beside its own colored name.
-- The filter below captures it first, keyed by lineID, so ChatFrameFilter can restore it.
local pendingEmotePrefixes = {};

---GetEmotePrefix Returns the raw "'s "/", " prefix of an emote message, if present.
---@param message string
---@return string?
local function GetEmotePrefix(message)
	if message:sub(1, 3) == "'s " then
		return message:sub(1, 3);
	elseif message:sub(1, 2) == ", " then
		return message:sub(1, 2);
	end
end

-- Named so RemoveMessageEventFilter could match it later.
local function emotePrefixFilter(_, _, ...)
	local message = select(1, ...);
	local lineID  = select(11, ...);

	if not message or not canaccessvalue(message) or not lineID then return; end

	local prefix = GetEmotePrefix(message);
	if not prefix then return; end

	pendingEmotePrefixes[lineID] = prefix;
	C_Timer.After(5, function() pendingEmotePrefixes[lineID] = nil; end);
end

-- Registered at file load rather than in Init(), so this runs ahead of TRP3's own
-- CHAT_MSG_EMOTE filter, which TRP3 only registers on PLAYER_LOGIN.
if ChatFrameUtil and type(ChatFrameUtil.AddMessageEventFilter) == "function" then
	ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_EMOTE", emotePrefixFilter);
end

---ChatFrameFilter Core Blizzard chat message filter
---@param chatFrame table Blizzard chat frame
---@param event string Chat event
---@param ... any
---@return boolean?
function ChatHandler:ChatFrameFilter(chatFrame, event, ...) -- luacheck: no unused (chatFrame)
	local message, sender, language, _, _, _, _, _, channel, _, lineID, guid = ...;

	if not message or not canaccessvalue(message) then return; end

	-- No support for channels now (or ever?)
	if event == "CHAT_MSG_CHANNEL" and channel then
		local lower = channel:lower();
		if ED.Constants.IGNORED_CHANNELS[lower] then return; end
	end

	--[[
	Debug in case the ChatFrame arguments ever change.
	local args = {...};
	print("Event:", event);
	for i, v in ipairs(args) do
		print("Arg" .. i .. ":", v);
	end
	]]

	-- Restore a "'s "/", " prefix stripped upstream (e.g. by TRP3's emote filter).
	if event == "CHAT_MSG_EMOTE" and lineID and pendingEmotePrefixes[lineID] then
		local prefix = pendingEmotePrefixes[lineID];
		pendingEmotePrefixes[lineID] = nil;
		if not GetEmotePrefix(message) then
			message = prefix .. message;
		end
	end

	-- Store chat history
	if event == "CHAT_MSG_SYSTEM" then
		local rollSender = ED.Utils.GetRollData(message);
		if rollSender then
			ED.ChatHistory:AddEntry("ROLL", rollSender, message);
		end
	else
		ED.ChatHistory:AddEntry(event, sender, message, language, guid, channel);
	end

	return false;
end

---MainChatFilter Runs checks on chat entries
---@param chatFrame table Blizzard chat frame
---@param event string Chat event
---@param message string Chat message
---@param sender string Sender name
---@param ... any
---@return boolean?
function ChatHandler:MainChatFilter(chatFrame, event, message, sender, ...)
	return ED.MainChat:HandleChecks(chatFrame, event, message, sender, ...);
end

---Init Registers Blizzard chat events to be filtered
function ChatHandler:Init()
	if type(ChatFrameUtil.AddMessageEventFilter) ~= "function" then return; end

	for _, evt in ipairs(Constants.CHAT_EVENTS_ALL) do
		ChatFrameUtil.AddMessageEventFilter(evt, function(...)
			return self:ChatFrameFilter(...);
		end);
	end

	ED.MainChat:Toggle();
end

ED.ChatHandler = ChatHandler;
