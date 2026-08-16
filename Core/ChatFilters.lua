-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

---@class EavesdropperChatFilters
local ChatFilters = {};

---@param groupName string
---@return ColorMixin
local function GetGroupColor(groupName)
	local option = ED.Constants.FILTER_OPTIONS[groupName];
	local chatType = type(option) == "table" and option[1] or option;
	chatType = ED.Constants.ENTRY_CHAT_REMAP[chatType] or chatType;

	local chatInfo = ChatTypeInfo[chatType] or { r = 1, g = 1, b = 1 };
	return CreateColor(chatInfo.r, chatInfo.g, chatInfo.b);
end

---@param event string
---@return string
local function NormalizeEvent(event)
	local remapped = ED.Constants.ENTRY_CHAT_REMAP[event];
	if remapped then
		return remapped;
	end

	if event:sub(1, 9) == "CHAT_MSG_" then
		return event:sub(10):upper();
	end

	return event:upper();
end

---@param chatType string
---@return string
local function ResolveEvent(chatType)
	local remapped = ED.Constants.ENTRY_CHAT_REMAP[chatType] or chatType;
	return remapped:upper();
end

---Resolve the proper DB setting for the chosen frame's filters.
---Only Mentions gets a distinct key back; Main, Dedicated, and Group all resolve to Filters.
---@param frame table
---@return string
local function ResolveFilterKey(frame)
	if frame == ED.MentionsFrame then
		return "MentionsFilters";
	end
	return "Filters";
end

---Generates the chat filter menu for UI
---@param frame table
---@param menu table
---@param useFrameState boolean?
function ChatFilters:GenerateFilterListMenu(frame, menu, useFrameState)
	local settingKey = ResolveFilterKey(frame);

	for i = 1, #ED.Constants.FILTER_ORDER do
		local groupName = ED.Constants.FILTER_ORDER[i];

		local labelText = ED.Constants.FILTER_LABELS[groupName] or groupName;
		local groupColor = GetGroupColor(groupName);
		local groupLabel = ED.Utils.WrapTextInColor(labelText, groupColor);

		menu:CreateCheckbox(
			groupLabel,
			function()
				if useFrameState then
					local filters = frame.filters;
					if not filters then return false; end
					return filters[groupName] or false;
				end
				local current = ED.Database:GetSetting(settingKey);
				if not current then return false; end
				return current[groupName] or false;
			end,
			function()
				if useFrameState then
					frame.filters = frame.filters or {};
					local value = frame.filters[groupName];
					if value == nil then
						value = ED.Constants.DEFAULT_FILTERS[groupName] or false;
					end
					frame.filters[groupName] = not value;
				else
					local current = ED.Database:GetSetting(settingKey) or {};
					local value = current[groupName];
					if value == nil then
						value = ED.Constants.DEFAULT_FILTERS[groupName] or false;
					end

					local newFilters = ED.Utils.ShallowCopy(current);
					newFilters[groupName] = not value;

					ED.Database:SetSetting(settingKey, newFilters);
				end
				ChatFilters:UpdateFilters(frame);
			end
		);

		if ED.Constants.DIVIDE_AFTER[groupName] then
			menu:CreateDivider();
		end
	end
end

---Updates active chat events on a given frame based on current filter settings.
---Tracks changes via a dirty flag and only refreshes the chat frame if needed.
---@param frame table?
function ChatFilters:UpdateFilters(frame)
	if not frame then return; end
	local filters = frame.filters or ED.Database:GetSetting(ResolveFilterKey(frame));
	if not filters then return; end

	frame.active_events = frame.active_events or {};
	local dirty = false;

	for groupName, enabled in pairs(filters) do
		local chatTypes = ED.Constants.FILTER_OPTIONS[groupName];
		if chatTypes then
			for _, chatType in ipairs(chatTypes) do
				local event = ResolveEvent(chatType);
				local currentlyActive = frame.active_events[event] == true;
				if enabled ~= currentlyActive then
					frame.active_events[event] = enabled and true or nil;
					dirty = true;
				end
			end
		end
	end

	if dirty then
		frame:RefreshChat();
	end
end

---Checks whether a specific event is currently active on the given frame.
---@param event string
---@param frame table
---@return boolean
function ChatFilters:HasEvent(event, frame)
	event = NormalizeEvent(event);

	frame.active_events = frame.active_events or {};
	return frame.active_events[event] == true;
end

---Initialises active events and per-frame filter state from the DB.
---Per-frame filters start from main frame as base (and don't save for now); the main and
---Mentions frames always read live from their own key instead.
---@param frame table?
function ChatFilters:Init(frame)
	if not frame then return; end
	frame.active_events = frame.active_events or {};

	local settingKey = ResolveFilterKey(frame);
	local filters = ED.Database:GetSetting(settingKey);
	if not filters then return; end

	if frame ~= ED.Frame and frame ~= ED.MentionsFrame then
		frame.filters = ED.Utils.ShallowCopy(filters);
	end

	for groupName, enabled in pairs(filters) do
		local chatTypes = ED.Constants.FILTER_OPTIONS[groupName];
		if chatTypes then
			for _, chatType in ipairs(chatTypes) do
				local event = ResolveEvent(chatType);
				frame.active_events[event] = enabled and true or nil;
			end
		end
	end
end

ED.ChatFilters = ChatFilters;
