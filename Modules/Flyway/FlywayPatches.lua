-- Copyright The Sippy Cup Authors
-- Inspired by Total RP 3, Sippy Cup
-- SPDX-License-Identifier: GPL-3.0-or-later

---@type EavesdropperConstants
local Constants = ED.Constants;

ED.Flyway.Patches = {};

ED.Flyway.Patches["1"] = {
	run = function()
		if not EavesdropperDB then return; end

		if EavesdropperDB.profiles then
			local themeEnabled = true;

			for _, profileData in pairs(EavesdropperDB.profiles) do
				if profileData["ElvUITheme"] ~= nil then
					-- If theme was disabled in one profile, assume it as global
					if profileData["ElvUITheme"] == false then
						themeEnabled = false;
					end
					profileData["ElvUITheme"] = nil;
				end
			end

			EavesdropperDB.global.ElvUITheme = themeEnabled;
		end
	end,

	description = "Migrate profile-specific ElvUITheme to global, if disabled (default was enabled), we disable it globally.",
};

ED.Flyway.Patches["2"] = {
	run = function()
		if not EavesdropperDB or not EavesdropperDB.profiles then return; end

		local highestMaxHistory = 0;

		for _, profileData in pairs(EavesdropperDB.profiles) do
			local maxHistory = profileData["MaxHistory"];
			if type(maxHistory) == "number" and maxHistory > highestMaxHistory then
				highestMaxHistory = maxHistory;
			end
		end

		if highestMaxHistory > ED.Database.globalDefaults.GroupHistorySize then
			EavesdropperDB.global.GroupHistorySize = Clamp(highestMaxHistory, Constants.CHAT_BOX.MIN_GROUP_HISTORY, Constants.CHAT_BOX.MAX_GROUP_HISTORY);
		end
	end,

	description = "Raise the new global GroupHistorySize to match the highest per-profile MaxHistory, so existing large history setups aren't shrunk for Group Windows.",
};

ED.Flyway.Patches["3"] = {
	run = function()
		if not EavesdropperDB or not EavesdropperDB.profiles then return; end

		local defaults = ED.Database.defaults;

		for _, profileData in pairs(EavesdropperDB.profiles) do
			local maxHistory = profileData["MaxHistory"] or defaults.MaxHistory;
			local mentionsHistorySize = profileData["MentionsHistorySize"] or defaults.MentionsHistorySize;
			if maxHistory > mentionsHistorySize then
				profileData["MentionsHistorySize"] = Clamp(maxHistory, Constants.CHAT_BOX.MIN_MENTIONS_HISTORY, Constants.CHAT_BOX.MAX_MENTIONS_HISTORY);
			end

			local fontSize = profileData["FontSize"] or defaults.FontSize;
			local mentionsFontSize = profileData["MentionsFontSize"] or defaults.MentionsFontSize;
			if fontSize > mentionsFontSize then
				profileData["MentionsFontSize"] = Clamp(fontSize, Constants.CHAT_BOX.MIN_FONT_SIZE, Constants.CHAT_BOX.MAX_FONT_SIZE);
			end
		end
	end,

	description = "Raise per-profile MentionsHistorySize/MentionsFontSize to match that profile's MaxHistory/FontSize where higher, now that Mentions has its own independent settings instead of inheriting Main's live values.",
};
