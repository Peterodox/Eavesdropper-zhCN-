-- Copyright The Eavesdropper Authors
-- Inspired by Total RP 3
-- SPDX-License-Identifier: GPL-3.0-or-later

---@class EavesdropperEncodingUtil
local EncodingUtil = {};

-- Named explicitly; encode and decode must agree on both.
local COMPRESSION_METHOD = Enum.CompressionMethod.Deflate;
local BASE64_VARIANT     = Enum.Base64Variant.Standard;

local PEM_LINE_LENGTH = 78;

-- Whole block in one match. %1 pins the end label to the begin label.
local PEM_BLOCK_PATTERN = "%-%-%-%-%-BEGIN ([^-]+)%-%-%-%-%-%s+(.-)%s+%-%-%-%-%-END %1%-%-%-%-%-";

-- Optional header preamble, split from the body by a blank line.
local PEM_BODY_PATTERN = "^(.-\n)\n(.*)$";

-- Headers are newline terminated "Some-Key: Value" strings.
local PEM_HEADER_PATTERN = "([%w%-]+):%s*(.-)\n";

-- ============================================================================
-- COMPRESSION
-- ============================================================================

---CompressString Compresses a string using the addon's fixed compression method.
---@param data string
---@return string
function EncodingUtil.CompressString(data)
	return C_EncodingUtil.CompressString(data, COMPRESSION_METHOD);
end

---DecompressString Decompresses a string produced by EncodingUtil.CompressString.
---Errors on malformed input; callers are expected to pcall this.
---@param data string
---@return string
function EncodingUtil.DecompressString(data)
	return C_EncodingUtil.DecompressString(data, COMPRESSION_METHOD);
end

-- ============================================================================
-- PEM ENCODING
-- ============================================================================

---EncodePEM Wraps binary data in a PEM block with optional headers.
---@param label string Block label, e.g. "EAVESDROPPER PROFILE". Must not contain '-'.
---@param data string Raw bytes; base64-encoded into the block body.
---@param headers table? Array of { key = string, value = any }; nil values are skipped.
---@return string
function EncodingUtil.EncodePEM(label, data, headers)
	local buffer = {};

	buffer[#buffer + 1] = string.format("-----BEGIN %s-----", label);

	if headers then
		local wroteHeader = false;

		for _, header in ipairs(headers) do
			if header.value ~= nil then
				-- A newline in a value would forge a block structure.
				local value = tostring(header.value):gsub("%s+", " ");
				buffer[#buffer + 1] = string.format("%s: %s", header.key, value);
				wroteHeader = true;
			end
		end

		if wroteHeader then
			buffer[#buffer + 1] = "";
		end
	end

	local encoded = C_EncodingUtil.EncodeBase64(data, BASE64_VARIANT);
	local length  = #encoded;
	local offset  = 1;

	while offset <= length do
		buffer[#buffer + 1] = string.sub(encoded, offset, offset + PEM_LINE_LENGTH - 1);
		offset = offset + PEM_LINE_LENGTH;
	end

	buffer[#buffer + 1] = string.format("-----END %s-----", label);

	return table.concat(buffer, "\n");
end

---DecodePEM Extracts the first PEM block from a string.
---Never errors; returns nil on any failure and lets the caller decide what that means.
---@param text string
---@return string? label
---@return string? data Decoded raw bytes.
---@return table? headers Map of header key to value.
function EncodingUtil.DecodePEM(text)
	if type(text) ~= "string" then return nil; end

	local label, body = string.match(text, PEM_BLOCK_PATTERN);
	if not label then return nil; end

	local headerText, encoded = string.match(body, PEM_BODY_PATTERN);
	if not headerText then
		headerText = "";
		encoded    = body;
	end

	local headers = {};

	for key, value in string.gmatch(headerText, PEM_HEADER_PATTERN) do
		headers[key] = value;
	end

	-- The body is wrapped across lines; join it back up before decoding.
	encoded = string.gsub(encoded, "%s+", "");

	local ok, data = pcall(C_EncodingUtil.DecodeBase64, encoded, BASE64_VARIANT);
	if not ok or type(data) ~= "string" then return nil; end

	return label, data, headers;
end

ED.EncodingUtil = EncodingUtil;
