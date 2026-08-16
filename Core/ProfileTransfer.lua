-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- The export and decode pipeline is adapted from Total RP 3, used under Apache-2.0:
-- https://github.com/Total-RP/Total-RP-3/blob/eac17a37d623faf73c5ea10108f096eb8645f477/totalRP3/Core/ProfileUtil.lua

local SharedMedia = LibStub("LibSharedMedia-3.0");

---@type EavesdropperConstants
local Constants = ED.Constants;

---@type EavesdropperEnums
local Enums = ED.Enums;

local L = ED.Localization;

---@class EavesdropperProfileTransfer
local ProfileTransfer = {};

local SCHEMA_VERSION = 1;

local LABEL_PROFILE = "EAVESDROPPER PROFILE";
local LABEL_GLOBAL  = "EAVESDROPPER SETTINGS";

---Global keys that are never exported or imported. Flyway is migration state and says
---nothing about the sender's preferences.
local GLOBAL_EXCLUDED = {
	Flyway = true,
};

---Fields sanitizeShape keeps even though the default shape lacks them, with the bounds
---they are clamped to. Listed per setting so a field cannot leak into an unrelated table.
---Numeric fields need both a min and a max.
local EXTRA_SHAPE_FIELDS = {
	MinimapButton = {
		minimapPos = { type = "number", min = 0, max = 360 },
	},
};

---Profile keys whose value must be one of an enumeration's members.
local ENUM_KEYS = {
	AdvNameDisplayMode         = Enums.NAME_DISPLAY_MODE,
	FocusTarget                = Enums.FOCUS_TARGET,
	FontOutline                = Enums.CHAT_BOX.FONT_OUTLINE,
	MentionsNameDisplayMode    = Enums.NAME_DISPLAY_MODE,
	NameDisplayMode            = Enums.NAME_DISPLAY_MODE,
	NPCAndQuestNameDisplayMode = Enums.NAME_DISPLAY_MODE,
	TargetPriority             = Enums.TARGET_PRIORITY,
};

---Profile keys clamped to a numeric range. NotificationThrottle has no widget bounds to
---borrow, so it only gets a floor.
local NUMERIC_BOUNDS = {
	FontSize             = { min = Constants.CHAT_BOX.MIN_FONT_SIZE, max = Constants.CHAT_BOX.MAX_FONT_SIZE },
	MaxHistory           = { min = Constants.CHAT_BOX.MIN_HISTORY,   max = Constants.CHAT_BOX.MAX_HISTORY },
	MentionsHistorySize  = { min = Constants.CHAT_BOX.MIN_MENTIONS_HISTORY, max = Constants.CHAT_BOX.MAX_MENTIONS_HISTORY },
	NotificationThrottle = { min = 0 },
};

---Global keys clamped to a numeric range. Same shape as NUMERIC_BOUNDS, kept separate since
---global and profile settings are sanitized through different functions.
local GLOBAL_NUMERIC_BOUNDS = {
	GroupHistorySize = { min = Constants.CHAT_BOX.MIN_GROUP_HISTORY, max = Constants.CHAT_BOX.MAX_GROUP_HISTORY },
};

---Profile keys holding an r/g/b(/a) colour.
local COLOR_KEYS = {
	ColorBackground = true,
	ColorTitleBar   = true,
	HighlightColor  = true,
};

---Profile keys naming a LibSharedMedia entry, mapped to their media type.
local MEDIA_KEYS = {
	FontFace = SharedMedia.MediaType.FONT,
};

for _, key in pairs(Enums.NOTIFICATIONS_TYPE_SOUND_KEYS) do
	MEDIA_KEYS[key] = SharedMedia.MediaType.SOUND;
end

-- ============================================================================
-- SANITIZE
-- ============================================================================

---@param enumTable table
---@param value any
---@return boolean
local function isEnumValue(enumTable, value)
	for _, member in pairs(enumTable) do
		if member == value then return true; end
	end
	return false;
end

---Rebuilds a colour, requiring numeric r/g/b and clamping every channel to 0-1.
---@param value table
---@param default table
---@return table? colour
local function sanitizeColor(value, default)
	local clean = {};

	for _, channel in ipairs({ "r", "g", "b" }) do
		local n = value[channel];
		if type(n) ~= "number" then return nil; end
		clean[channel] = Saturate(n);
	end

	-- Alpha only exists on some colours; fall back to the default when absent.
	if default.a ~= nil then
		clean.a = (type(value.a) == "number") and Saturate(value.a) or default.a;
	end

	return clean;
end

---Fields holding a SetPoint anchor, in any shaped table.
local ANCHOR_FIELDS = {
	point         = true,
	relativePoint = true,
};

---Rebuilds a table from its default's shape, substituting the default for any field
---that is missing or of the wrong type.
---@param value table
---@param default table
---@param extraFields table? See EXTRA_SHAPE_FIELDS.
---@return table
local function sanitizeShape(value, default, extraFields)
	local clean = {};

	for field, defaultValue in pairs(default) do
		local v = value[field];

		if type(v) ~= type(defaultValue) then
			v = defaultValue;
		elseif ANCHOR_FIELDS[field] and not Constants.ANCHOR_POINTS[v] then
			-- An unrecognised anchor would error inside SetPoint rather than here.
			v = defaultValue;
		end

		clean[field] = v;
	end

	for field, spec in pairs(extraFields or {}) do
		local v = value[field];

		-- No default to fall back on, so a bad value is left out and the recipient keeps
		-- whatever they already had.
		if type(v) == spec.type then
			clean[field] = (spec.type == "number") and Clamp(v, spec.min, spec.max) or v;
		end
	end

	return clean;
end

---@param value table
---@return table filters
---@return number dropped
local function sanitizeFilters(value)
	local clean, dropped = {}, 0;

	for key, enabled in pairs(value) do
		if Constants.FILTER_OPTIONS[key] and type(enabled) == "boolean" then
			clean[key] = enabled;
		else
			dropped = dropped + 1;
		end
	end

	return clean, dropped;
end

---Validates one setting against its default.
---@param key string
---@param value any
---@param default any
---@return any? sanitized nil when the value must be dropped
---@return number dropped Count of nested keys discarded.
local function sanitizeValue(key, value, default)
	if type(value) ~= type(default) then return nil, 0; end

	if type(value) == "table" then
		if COLOR_KEYS[key] then
			return sanitizeColor(value, default), 0;
		elseif key == "Filters" or key == "MentionsFilters" then
			return sanitizeFilters(value);
		end

		return sanitizeShape(value, default), 0;
	end

	if ENUM_KEYS[key] then
		if not isEnumValue(ENUM_KEYS[key], value) then return nil, 0; end
		return value, 0;
	end

	local bounds = NUMERIC_BOUNDS[key];
	if bounds then
		return bounds.max and Clamp(value, bounds.min, bounds.max) or math.max(value, bounds.min), 0;
	end

	-- When SharedMedia name does not exist on import, fallback to the default.
	if MEDIA_KEYS[key] then
		if not SharedMedia:Fetch(MEDIA_KEYS[key], value, true) then return default, 0; end
		return value, 0;
	end

	return value, 0;
end

---SanitizeProfile Whitelists and type-checks an imported profile table.
---@param data table
---@return table clean
---@return number dropped Count of keys discarded or rejected.
function ProfileTransfer.SanitizeProfile(data)
	local defaults = ED.Database.defaults;
	local clean, dropped = {}, 0;

	for key, value in pairs(data) do
		local default = defaults[key];

		if default == nil then
			dropped = dropped + 1;
		else
			local sanitized, nested = sanitizeValue(key, value, default);

			if sanitized == nil then
				dropped = dropped + 1;
			else
				clean[key] = sanitized;
				dropped = dropped + nested;
			end
		end
	end

	return clean, dropped;
end

---SanitizeGlobals Whitelists and type-checks an imported global settings table.
---@param data table
---@return table clean
---@return number dropped Count of keys discarded or rejected.
function ProfileTransfer.SanitizeGlobals(data)
	local defaults = ED.Database.globalDefaults;
	local clean, dropped = {}, 0;

	for key, value in pairs(data) do
		local default = defaults[key];

		if default == nil or GLOBAL_EXCLUDED[key] then
			dropped = dropped + 1;
		elseif type(value) ~= type(default) then
			dropped = dropped + 1;
		elseif type(value) == "table" then
			clean[key] = sanitizeShape(value, default, EXTRA_SHAPE_FIELDS[key]);
		elseif GLOBAL_NUMERIC_BOUNDS[key] then
			local bounds = GLOBAL_NUMERIC_BOUNDS[key];
			clean[key] = bounds.max and Clamp(value, bounds.min, bounds.max) or math.max(value, bounds.min);
		else
			clean[key] = value;
		end
	end

	return clean, dropped;
end

-- ============================================================================
-- EXPORT
-- ============================================================================

---@param payloadType string
---@param name string?
---@param data table
---@return table packed
local function packPayload(payloadType, name, data)
	-- Positional to keep the payload compact. Name is "" rather than nil, since a nil hole
	-- would break both the length check and unpack on decode.
	return {
		SCHEMA_VERSION,
		ED.Globals.addon_version,
		payloadType,
		name or "",
		data,
	};
end

---@param label string
---@param payload table
---@param headers table
---@return string? text
local function encodePayload(label, payload, headers)
	local ok, serialized = pcall(C_EncodingUtil.SerializeCBOR, payload);
	if not ok then return nil; end

	return ED.EncodingUtil.EncodePEM(label, ED.EncodingUtil.CompressString(serialized), headers);
end

---ExportProfile Serializes the active profile to a shareable PEM string.
---Every key goes through GetSetting, so the payload carries resolved values, not a diff.
---@return string? text
function ProfileTransfer.ExportProfile()
	local db = ED.Database;
	local defaults = db.defaults;
	if not defaults then return nil; end

	local name = db:GetProfileName();
	local data = {};

	for key in pairs(defaults) do
		data[key] = db:GetSetting(key);
	end

	return encodePayload(LABEL_PROFILE, packPayload("profile", name, data), {
		{ key = "Name",          value = name },
		{ key = "Exported",      value = date("%Y-%m-%d %H:%M:%S") },
		{ key = "AddOn-Version", value = ED.Globals.addon_version },
	});
end

---ExportGlobals Serializes account-wide settings to a shareable PEM string.
---@return string? text
function ProfileTransfer.ExportGlobals()
	local db = ED.Database;
	local defaults = db.globalDefaults;
	if not defaults then return nil; end

	local data = {};

	for key in pairs(defaults) do
		if not GLOBAL_EXCLUDED[key] then
			local value = db:GetGlobalSetting(key);

			-- GetGlobalSetting hands back live tables; copy before they reach the payload.
			if type(value) == "table" then value = ED.Utils.ShallowCopy(value); end

			data[key] = value;
		end
	end

	return encodePayload(LABEL_GLOBAL, packPayload("global", nil, data), {
		{ key = "Exported",      value = date("%Y-%m-%d %H:%M:%S") },
		{ key = "AddOn-Version", value = ED.Globals.addon_version },
	});
end

-- ============================================================================
-- DECODE
-- ============================================================================

---Maps a PEM label onto the payload type it carries.
local LABEL_TYPES = {
	[LABEL_PROFILE] = "profile",
	[LABEL_GLOBAL]  = "global",
};

---DecodeString Unwraps a pasted string into its payload, or an error to show the user.
---The string declares its own kind, so check payloadType rather than assume it.
---Data is untrusted until it has been through the matching Sanitize method.
---@param text string
---@return table? payload
---@return string? errorMessage
function ProfileTransfer.DecodeString(text)
	local ok, label, data, headers = pcall(ED.EncodingUtil.DecodePEM, text);

	if not ok or not label then
		return nil, L.IMPORTEXPORT_ERROR_PEM_DECODE;
	end

	local expectedType = LABEL_TYPES[label];

	if not expectedType then
		return nil, L.IMPORTEXPORT_ERROR_PEM_LABEL;
	end

	local decompressed;
	ok, decompressed = pcall(ED.EncodingUtil.DecompressString, data);

	if not ok or type(decompressed) ~= "string" then
		return nil, L.IMPORTEXPORT_ERROR_DECOMPRESS;
	end

	local packed;
	ok, packed = pcall(C_EncodingUtil.DeserializeCBOR, decompressed);

	if not ok then
		return nil, L.IMPORTEXPORT_ERROR_DESERIALIZE_CBOR;
	end

	if type(packed) ~= "table" or #packed < 5 then
		return nil, L.IMPORTEXPORT_ERROR_PACKED_DATA_INVALID;
	end

	local schemaVersion, addonVersion, decodedType, name, settings = unpack(packed, 1, 5);

	-- A non-numeric version means the payload is (probably) malformed.
	if type(schemaVersion) ~= "number" then
		return nil, L.IMPORTEXPORT_ERROR_PACKED_DATA_INVALID;
	end

	if schemaVersion > SCHEMA_VERSION then
		return nil, L.IMPORTEXPORT_ERROR_SCHEMA_TOO_NEW;
	end

	-- A hand-edited string could set the label without the payload, or the reverse.
	if decodedType ~= expectedType or type(settings) ~= "table" then
		return nil, L.IMPORTEXPORT_ERROR_PACKED_DATA_INVALID;
	end

	-- The export date lives in the PEM header, never in the payload.
	local exported = type(headers) == "table" and headers.Exported or nil;

	return {
		schemaVersion = schemaVersion,
		addonVersion  = type(addonVersion) == "string" and addonVersion or nil,
		payloadType   = decodedType,
		name          = (type(name) == "string" and name ~= "") and name or nil,
		exported      = type(exported) == "string" and exported or nil,
		data          = settings,
	}, nil;
end

ED.ProfileTransfer = ProfileTransfer;
