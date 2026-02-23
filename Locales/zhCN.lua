-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: Apache-2.0

local title = C_AddOns.GetAddOnMetadata("Eavesdropper", "Title");
local L;

---@class ED.Locale.zhCN
L = {
	ADDON_TOOLTIP_HELP = "|cnGREEN_FONT_COLOR:左键单击∶打开设置|n右键单击∶打开档案|r",
	POPUP_LINK = "|n|n按|cnGREEN_FONT_COLOR:CTRL-C|r 复制高亮的内容，然后在浏览器里按|cnGREEN_FONT_COLOR:CTRL-V|r粘贴。",
	COPY_SYSTEM_MESSAGE = "已复制到剪切板。",

	FILTER = "过滤器",
	FILTER_HELP = "Choose which types of messages are visible in Eavesdropper.|n|n- Toggling a filter only changes what is currently shown.|n- No data is actually deleted; hidden messages will reappear if the filter is turned back on.|n|n|cnWARNING_FONT_COLOR:Note: Filters are applied instantly.|r",

	SCROLLMARKER_TEXT = "滚动到底部",

	FILTER_PUBLIC = "公众场合",
	FILTER_PARTY = "小队",
	FILTER_RAID = "团队",
	FILTER_RAID_WARNING = "团队警告",
	FILTER_INSTANCE = "副本",
	FILTER_GUILD = "公会",
	FILTER_GUILD_OFFICER = "公会官员",
	FILTER_WHISPER = "密语",
	FILTER_ROLLS = "Roll点",

	WINDOW_OPTIONS = "窗口设置",
	ENABLE_MOUSE = "启用鼠标",
	ENABLE_MOUSE_HELP = "Toggles whether you can interact with the Eavesdropper window using your mouse.|n|n- Enabled: Allows you to click on item links, and URLs within the history.|n- Disabled: Clicks pass through the window to the game world behind it, preventing accidental clicks during gameplay.",
	LOCK_SCROLL = "锁定滚动",
	LOCK_SCROLL_HELP = "Disables the ability to scroll through the message history.|n|n- Use this to ensure Eavesdropper always remains at the bottom of the list to show the latest messages.",
	LOCK_WINDOW = "锁定位置及大小",
	LOCK_WINDOW_HELP = "Prevents Eavesdropper from being moved or resized.|n|n- Check this once you have positioned the window to avoid accidental dragging during gameplay.",
	LOCK_TITLEBAR = "常显示标题栏",
	LOCK_TITLEBAR_HELP = "Toggles the visibility of the window's title bar.|n|n- Enabled: The title bar remains visible at all times.|n- Disabled: The title bar is hidden and only appears when you hover over the window.|n|nNote: You can enable 'Title Bar Target Name' in the settings to replace the 'Eavesdropper' text with your current target's name.",

	-- General Tab
	GENERAL_TITLE = "一般",
	TARGETING = "Targeting",
	TARGET_PRIORITY = "优先级",
	TARGET_PRIORITY_HELP = "Determines which unit's history Eavesdropper displays when you have both a target and a mouseover unit.|n|n- Prioritize: Choose which one takes precedence.|n- Only: Choose to ignore one type of interaction entirely.",
	TARGET_PRIORITY_PRIORITIZE_MOUSEOVER = "优先鼠标悬停的玩家",
	TARGET_PRIORITY_PRIORITIZE_TARGET = "优先被设为目标的玩家",
	TARGET_PRIORITY_MOUSEOVER_ONLY = "仅追踪鼠标悬停的玩家",
	TARGET_PRIORITY_TARGET_ONLY = "紧追踪被设为目标的玩家",

	INCLUDE_COMPANIONS = "Include Companions",
	INCLUDE_COMPANIONS_HELP = "Show the owner's history when targeting or hovering over their pets and companions.|n|n- When enabled, Eavesdropper treats pets as a bridge to their owner's data.|n- When disabled, Eavesdropper will ignore pets and companions entirely.",

	MESSAGES = "消息",
	MESSAGES_HELP = "这些选项仅对Eavesdropper历史消息生效",

	HISTORY_SIZE = "历史消息数",
	HISTORY_SIZE_HELP = "Set the maximum number of messages Eavesdropper stores for each unit.|n|n|cnWARNING_FONT_COLOR:Note: High values may cause temporary frame drops when refreshing the history window.|r",

	NAME_DISPLAY_MODE = "姓名格式",
	NAME_DISPLAY_MODE_HELP = "Choose how character names are formatted within Eavesdropper.",
	NAME_DISPLAY_MODE_FULL_NAME = "显示姓和名",
	NAME_DISPLAY_MODE_FIRST_NAME = "仅显示名",
	NAME_DISPLAY_MODE_ORIGINAL_NAME = "玩家原始名称",

	USE_RP_NAME_COLOR = "姓名颜色",
	USE_RP_NAME_COLOR_HELP = "Color names based on their custom RP settings (e.g., from TRP3).|n|n- If no RP color is detected, Eavesdropper falls back to the default Blizzard class color.",

	USE_RP_NAME_IN_ROLLS = "Format Roll Names",
	USE_RP_NAME_IN_ROLLS_HELP = "Toggles whether random roll results (/roll) use a character's RP name or their original in-game name.",

	USE_RP_NAME_FOR_TARGETS = "Format Emote Targets",
	USE_RP_NAME_FOR_TARGETS_HELP = "Toggles whether target names within Blizzard emotes (e.g., /wave, /point) use a character's RP name or their original in-game name.|n|n|cnWARNING_FONT_COLOR:Note: Due to how Blizzard handles emote strings, name substitution may not work consistently in all situations.|r",

	TIMESTAMP_BRACKETS = "Timestamp Brackets",
	TIMESTAMP_BRACKETS_HELP = "Toggles the visibility of brackets around message timestamps (e.g., [5m] vs 5m).",

	ADVANCED_FORMATTING = "Advanced Formatting",

	APPLY_ON_MAIN_CHAT = "Apply to Main Chat",
	APPLY_ON_MAIN_CHAT_HELP = "Toggles whether Advanced Formatting is applied to the main Blizzard chat window in addition to the Eavesdropper history window.|n|n|cnWARNING_FONT_COLOR:Note: Formatting is not retroactive. If the required RP data is unavailable at the time a message is received, standard in-game names will be displayed.|r",

	DISPLAY = "Display",
	THEMES_BACKGROUND_COLOR = "Background Color",
	THEMES_BACKGROUND_COLOR_HELP = "Adjust the color and transparency of Eavesdropper.|n|n- Use the slider in the color picker to set the background opacity.",
	THEMES_TITLEBAR_COLOR = "Title Bar Color",
	THEMES_TITLEBAR_COLOR_HELP = "Set the background color and opacity for the title bar.|n|n- The title bar is typically visible when hovering over Eavesdropper.",
	THEMES_SETTINGS_ELVUI = "ElvUI Theme",
	THEMES_SETTINGS_ELVUI_HELP = "Force Eavesdropper's settings window to use ElvUI skinning.|n|n|cnWARNING_FONT_COLOR:Note: Toggling this will automatically trigger a UI Reload to apply the new skin.|r",

	HIDE_CLOSE_BUTTON = "Hide Close Button",
	HIDE_CLOSE_BUTTON_HELP = "Toggles the visibility of the close button on the Eavesdropper frame.|n|n- If hidden, you can still control the window using |cnGREEN_FONT_COLOR:/ed show|r or |cnGREEN_FONT_COLOR:/ed hide|r.",
	HIDE_IN_COMBAT = "Hide In Combat",
	HIDE_IN_COMBAT_HELP = "Automatically hide Eavesdropper upon entering combat.|n|n|cnWARNING_FONT_COLOR:Note: Certain combat encounters or instances may restrict message capturing regardless of this setting.|r",
	HIDE_WHEN_EMPTY = "Hide When Empty",
	HIDE_WHEN_EMPTY_HELP = "Automatically hides Eavesdropper when there are no messages to display.|n|n- The window will reappear as soon as a new message is recorded.",

	TITLE_BAR_TARGET_NAME = "Title Bar Target Name",
	TITLE_BAR_TARGET_NAME_HELP = "Replaces the 'Eavesdropper' label in the title bar with the name of your current target. This provides a quick visual confirmation of which character's history is currently being tracked.",

	FONT = "Font",

	FONT_FACE = "Font Face",
	FONT_FACE_HELP = "Choose the typeface used for all text within Eavesdropper.|n|nNote: Fonts from other addons that use LibSharedMedia will also appear in this list.",

	FONT_SIZE = "Font Size",
	FONT_SIZE_HELP = "Adjust the size of the messages displayed in the history window.|n|n- You can also hold |cnGREEN_FONT_COLOR:Ctrl + Mouse Wheel Up/Down|r while hovering over Eavesdropper to change the size directly.",

	FONT_OUTLINE = "Font Outline",
	FONT_OUTLINE_HELP = "Apply a border to the text to improve readability against busy backgrounds.",
	FONT_OUTLINE_NONE = "None",
	FONT_OUTLINE_THIN = "Thin",
	FONT_OUTLINE_THICK = "Thick",

	FONT_SHADOW = "Font Shadow",
	FONT_SHADOW_HELP = "Toggles a soft drop shadow behind the text for added depth and contrast.",

	MINIMAP = "Minimap",

	MINIMAP_BUTTON = "Minimap Button",
	MINIMAP_BUTTON_HELP = "Toggles the display of the minimap button.",

	ADDON_COMPARTMENT_BUTTON = "Addon compartment",
	ADDON_COMPARTMENT_BUTTON_HELP = "Toggles the display of the addon compartment button.",

	-- Notifications Tab
	NOTIFICATIONS_TITLE = "Notifications",

	EMOTES = "Emotes",
	EMOTES_HELP = "When someone emotes at your character (e.g., /point, /laugh).",

	TARGET = "Target",
	TARGET_HELP = "Messages received from your current target.",

	NOTIFICATIONS_PLAY_SOUND = "Play Sound",
	NOTIFICATIONS_PLAY_SOUND_HELP = "Toggles whether Eavesdropper plays an audible alert for this notification type.",

	NOTIFICATIONS_SOUND_FILE = "Sound File",
	NOTIFICATIONS_SOUND_FILE_HELP = "Choose the specific sound file Eavesdropper will play for this alert.|n|nNote: Sounds from other addons that use LibSharedMedia will also appear in this list.",

	NOTIFICATION_FLASH_TASKBAR = "Flash Taskbar",
	NOTIFICATION_FLASH_TASKBAR_HELP = "Toggles whether the game's taskbar icon flashes when this notification type is triggered while the game is minimized.",

	-- Keywords Tab
	KEYWORDS_TITLE = "Keywords",

	KEYWORDS_HELP = "Highlight specific words or phrases that appear in chat.",

	KEYWORDS_ENABLE = "Enable",
	KEYWORDS_ENABLE_HELP = "Toggles the keyword highlighting system for Eavesdropper.|n|n|cnWARNING_FONT_COLOR:Note: Keyword lists are saved per profile, not per character.|r",

	KEYWORDS_LIST = "Keywords List",
	KEYWORDS_LIST_HELP = "Enter words or phrases to be highlighted in the chat history.|n|nSpecial Tags:|n|cnGREEN_FONT_COLOR:<firstname>|r - Your RP first name|n|cnGREEN_FONT_COLOR:<lastname>|r - Your RP last name|n|cnGREEN_FONT_COLOR:<oocname>|r - Your in-game name|n|cnGREEN_FONT_COLOR:<class>|r - Your RP class (falls back to game class)|n|cnGREEN_FONT_COLOR:<race>|r - Your RP race (falls back to game race)|n|nFormatting:|n- Separate multiple entries with commas.|n- Entries are case-insensitive (e.g., 'Hero' matches 'hero').|n- Spaces within a phrase are preserved.|n|n|cnWARNING_FONT_COLOR:Note: Spaces immediately before or after a comma are ignored.|r",

	KEYWORDS_HIGHLIGHT_COLOR = "Highlight Color",
	KEYWORDS_HIGHLIGHT_COLOR_HELP = "Set the color used for highlighted keywords in chat.",

	KEYWORDS_ENABLE_PARTIAL_MATCHING = "Partial Matching",
	KEYWORDS_ENABLE_PARTIAL_MATCHING_HELP = "Toggles whether keywords can be found inside larger words.|n|nExamples:|n- Enabled: 'Twin' will highlight inside 'Twins'.|n- Disabled: Only the exact word 'Twin' will highlight.|n|n|cnWARNING_FONT_COLOR:Note: This may cause 'false positives' (e.g., 'art' highlighting inside 'pARTy').|r",

	KEYWORDS_NOTIFICATIONS_HELP = "Messages received with a detected keyword.",

	-- Profiles Tab
	PROFILES_TITLE = "Profiles",

	PROFILES_CURRENTPROFILE = "Current Profile",
	PROFILES_CURRENTPROFILE_HELP = "The profile to use for this character.",

	PROFILES_NEWPROFILE = "New Profile",
	PROFILES_NEWPROFILE_HELP = "Create a new profile. Enter a name and press Enter to save it.",

	PROFILES_COPYFROM = "Copy From",
	PROFILES_COPYFROM_HELP = "Copy all settings from an existing profile into your currently active profile.|n|n|cnWARNING_FONT_COLOR:Warning: Selecting a profile from this dropdown will overwrite your current settings immediately without an additional confirmation.|r",

	PROFILES_RESETBUTTON = "Reset Profile",
	PROFILES_RESETBUTTON_HELP = "Reset all settings in the current profile back to their original defaults.|n|n|cnWARNING_FONT_COLOR:Warning: Clicking this button will reset your settings immediately without an additional confirmation.|r",

	PROFILES_DELETEPROFILE = "Delete Profile",
	PROFILES_DELETEPROFILE_HELP = "Permanently remove the selected profile from the Eavesdropper database.|n|n|cnWARNING_FONT_COLOR:Warning: Selecting a profile from this dropdown will delete it immediately without an additional confirmation.|r",

	ADDONINFO_BUILD = "|cnNORMAL_FONT_COLOR:Build:|r %s",
	ADDONINFO_BUILD_OUTDATED = title .. " is not optimized for this game build.|n|n|cnWARNING_FONT_COLOR:This may cause unexpected behavior.|r",
	ADDONINFO_BUILD_CURRENT = title .. " is optimized for your current game build.|n|n|cnGREEN_FONT_COLOR:All features should work as expected.|r",
	ADDONINFO_BLUESKY_SHILL_HELP = "Follow me on Bluesky!",
};

---@class ED.L : ED.Locale.zhCN, ED.Localization
ED.Localization = ED.LocalizationClass:New(L);
ED.Localization:RegisterNewLocale("zhCN", "Simplified Chinese", L);
