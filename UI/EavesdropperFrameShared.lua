-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

---@type EavesdropperEnums
local Enums = ED.Enums;

---@type EavesdropperConstants
local Constants = ED.Constants;

local L = ED.Localization;

---Shared mixin inherited by Eavesdropper_FrameMixin, Eavesdropper_Dedicated_FrameMixin,
---and Eavesdropper_Group_FrameMixin.
---Four getters are required on the proper mixins (as one uses DB and other uses local frame state):
---IsMouseEnabled(), IsWindowLocked(), IsScrollLocked(), IsTitleBarLocked()
---@class Eavesdropper_SharedFrameMixin
Eavesdropper_SharedFrameMixin = {};

-- ============================================================
-- OnLoad
-- ============================================================

---Configure ChatBox properties
---@param frame table
---@param maxLines number Lines beyond this are silently dropped, oldest first.
function Eavesdropper_SharedFrameMixin.InitChatBox(frame, maxLines)
	frame.ChatBox:SetJustifyH("LEFT");
	frame.ChatBox:SetIndentedWordWrap(true);
	frame.ChatBox:SetHyperlinksEnabled(true);
	frame.ChatBox:SetFading(false);
	frame.ChatBox:SetMaxLines(maxLines);
	frame.ChatBox.ScrollMarker.Text:SetText(L.SCROLLMARKER_TEXT);
end

---Set the three atlas states on a close button
---@param closeBtn Button
function Eavesdropper_SharedFrameMixin.InitCloseButton(closeBtn)
	closeBtn:SetNormalAtlas("uitools-icon-close");
	closeBtn:SetPushedAtlas("uitools-icon-close");
	closeBtn:SetHighlightAtlas("uitools-icon-close");
end

---Initialise local frame state shared by Dedicated and Group instance frames.
---Call from OnLoad before any method that reads these fields.
function Eavesdropper_SharedFrameMixin:InitInstanceFrameState()
	self.lockWindow = false;
	self.lockTitleBar = true;
	self.hideCloseButton = false;
	self.lockScroll = false;
	self.mouseEnabled = false;
	self.clickblock = 0;
	self.isMouseOver = false;
end

-- ============================================================
-- OnHide (instance frames)
-- ============================================================

---OnHide for Dedicated and Group instance frames.
function Eavesdropper_SharedFrameMixin:OnHideInstanceFrame()
	if not UIParent:IsShown() or self.isCombatHidden then return; end

	self:StopChatTicker();

	self:ResetNewIndicator();

	if self.newIndicatorTimer then
		self.newIndicatorTimer:Cancel();
		self.newIndicatorTimer = nil;
	end

	self:UnregisterAllEvents();
	self:SetScript("OnEnter", nil);
	self:SetScript("OnLeave", nil);
	self:SetParent(nil);

	self:OnUnregisterFrame();

	local frameName = self:GetName();
	if frameName and _G[frameName] == self then
		_G[frameName] = nil;
	end

	if self.alphaChannelMode and self.SetAlphaChannelMode then
		self:SetAlphaChannelMode(nil);
	end
end

---Override in concrete mixins to remove self from the owning frame-manager table.
function Eavesdropper_SharedFrameMixin:OnUnregisterFrame()
end

-- ============================================================
-- Chat refresh ticker
-- ============================================================

---Returns true when no line in this window can still change with age.
---An empty window counts as frozen.
---@return boolean
function Eavesdropper_SharedFrameMixin:IsTimestampFrozen()
	if not self.newestEntryTime then return true; end
	return (time() - self.newestEntryTime) >= Constants.TIMESTAMP_FREEZE_AGE;
end

---Start the periodic refresh that ages the timestamps on this window.
---The first tick is offset randomly, so windows shown together do not refresh in the same frame.
---Stops itself once every line is frozen; TryAddMessage starts it again.
function Eavesdropper_SharedFrameMixin:StartChatTicker()
	self.usesChatTicker = true;

	if self.chatTicker or self.chatTickerDelay then return; end

	local interval = Constants.WINDOW_REFRESH_INTERVAL;

	self.chatTickerDelay = C_Timer.NewTimer(math.random() * interval, function()
		self.chatTickerDelay = nil;
		self.chatTicker = C_Timer.NewTicker(interval, function()
			-- Refresh before testing; the tick that freezes a window still has a label to draw.
			self:RefreshChat(true);

			if self:IsTimestampFrozen() then
				self:StopChatTicker();
			end
		end);
	end);
end

---Cancel the periodic refresh and any pending staggered start.
---The stagger uses NewTimer rather than After so it can be cancelled here.
function Eavesdropper_SharedFrameMixin:StopChatTicker()
	if self.chatTickerDelay then
		self.chatTickerDelay:Cancel();
		self.chatTickerDelay = nil;
	end

	if self.chatTicker then
		self.chatTicker:Cancel();
		self.chatTicker = nil;
	end
end

-- ============================================================
-- Data-driven refresh (MSP invalidation)
-- ============================================================

---True while the burst window's cooldown is running.
local dataRefreshOnCooldown = false;

---True if an invalidation arrived during the cooldown and still needs a redraw.
local dataRefreshPending = false;

---Redraw every open dedicated and group window.
---mentions and the main window are only redrawn if they are shown.
function Eavesdropper_SharedFrameMixin.RefreshAllWindows()
	ED.DedicatedFrame:ForEachFrame(function(frame)
		frame:RefreshChat(true);
	end);

	ED.GroupFrame:ForEachFrame(function(frame)
		frame:RefreshChat(true);
	end);

	if ED.Frame and ED.Frame:IsShown() then
		ED.Frame:RefreshChat(true);
	end

	if ED.MentionsFrame and ED.MentionsFrame:IsShown() then
		ED.MentionsFrame:RefreshChat(true);
	end
end

---Applies combat-hidden state to all four frame types and re-evaluates their visibility.
---Main frame's HandleVisibility ignores isCombatHidden, as it handles things differently.
---@param combatHidden boolean
function Eavesdropper_SharedFrameMixin.ApplyCombatHidden(combatHidden)
	ED.Frame:HandleVisibility();

	ED.MentionsFrame.isCombatHidden = combatHidden;
	ED.MentionsFrame:HandleVisibility();

	ED.DedicatedFrame:ForEachFrame(function(frame)
		frame.isCombatHidden = combatHidden;
		frame:HandleVisibility();
	end);

	ED.GroupFrame:ForEachFrame(function(frame)
		frame.isCombatHidden = combatHidden;
		frame:HandleVisibility();
	end);
end

---Rearms itself if something is pending when the cooldown expires, rather than always going
---idle. Keeps a sustained burst on a steady interval instead of having it basically spam.
local function ArmDataRefreshCooldown()
	C_Timer.NewTimer(Constants.DATA_REFRESH_THROTTLE, function()
		if not dataRefreshPending then
			dataRefreshOnCooldown = false;
			ED.Debug:Print("ScheduleDataRefresh: cooldown expired, idle");
			return;
		end

		dataRefreshPending = false;
		ED.Debug:Print("ScheduleDataRefresh: cooldown expired, trailing redraw");
		Eavesdropper_SharedFrameMixin.RefreshAllWindows();
		ArmDataRefreshCooldown();
	end);
end

---Entry point for MSP invalidation to request a redraw. Invalidation sources must always
---come through here, never call RefreshChat directly.
function Eavesdropper_SharedFrameMixin.ScheduleDataRefresh()
	if dataRefreshOnCooldown then
		dataRefreshPending = true;
		ED.Debug:Print("ScheduleDataRefresh: on cooldown, queued");
		return;
	end

	ED.Debug:Print("ScheduleDataRefresh: leading edge, redrawing now");
	Eavesdropper_SharedFrameMixin.RefreshAllWindows();

	dataRefreshOnCooldown = true;
	ArmDataRefreshCooldown();
end

-- ============================================================
-- Scroll Marker
-- ============================================================

---Show or hide the scroll marker and move the ChatBox accordingly (to prevent overlap)
function Eavesdropper_SharedFrameMixin:OnChatboxRefresh()
	if self.ChatBox:GetScrollOffset() ~= 0 then
		if not self.ChatBox.ScrollMarker:IsShown() then
			self.ChatBox.ScrollMarker:Show();
			self.ChatBox:SetPoint("BOTTOM", self.ChatBox.ScrollMarker, "TOP", 0, 1);
		end
	else
		if self.ChatBox.ScrollMarker:IsShown() then
			self.ChatBox.ScrollMarker:Hide();
			self.ChatBox:SetPoint("BOTTOM", self, 0, 2);
		end
	end
end

---Scroll to bottom and refresh (hide) the scroll marker on mouse-up
function Eavesdropper_SharedFrameMixin:OnScrollMarkerMouseUp()
	self.ChatBox:ScrollToBottom();
	self:OnChatboxRefresh();
end

-- ============================================================
-- Mouse / Interaction
-- ============================================================

---Returns true when the cursor is over any visible part of this frame
function Eavesdropper_SharedFrameMixin:IsHoveringOverEavesdropperFrame()
	-- Check the frame itself.
	if self and self:IsMouseOver() then
		return true;
	end
	-- Check TitleBar and children.
	if self.TitleBar and (self.TitleBar:IsMouseOver() or self.TitleBar.CloseButton:IsMouseOver() or self.TitleBar.TitleButton:IsMouseOver()) then
		return true;
	end
	-- Check ResizeHandle.
	if self.ResizeHandle and self.ResizeHandle:IsMouseOver() then
		return true;
	end
	return false;
end

-- ============================================================
-- OnEnter / OnLeave
-- ============================================================

---Fade out the new-indicator (if active) then delegate hover state to ShowTitleBar.
---FadeOutNewIndicator is a no-op on frames without a NewIndicator widget.
function Eavesdropper_SharedFrameMixin:OnEnter()
	if self.isMouseOver then return; end
	self.isMouseOver = true;
	self:FadeOutNewIndicator();
	self:HandleHoverState(Enums.FRAME.MOUSE_HOVER_STATE.ON);
end

---Revert to the OFF hover state only after the cursor leaves all chrome regions
function Eavesdropper_SharedFrameMixin:OnLeave()
	if not self:IsHoveringOverEavesdropperFrame() then
		self.isMouseOver = false;
		self:HandleHoverState(Enums.FRAME.MOUSE_HOVER_STATE.OFF);
	end
end

---Delegate hover-state changes to ShowTitleBar
---@param hoverState EavesdropperMouseHoverState
function Eavesdropper_SharedFrameMixin:HandleHoverState(hoverState)
	self:ShowTitleBar(hoverState);
end

-- ============================================================
-- Mouse wheel
-- ============================================================

---Handle scroll wheel input when IsScrollLocked() is false
function Eavesdropper_SharedFrameMixin:OnMouseWheel(delta)
	if self:IsScrollLocked() then return; end

	if delta > 0 then
		if IsAltKeyDown() then
			self.ChatBox:ScrollToTop();
		elseif IsControlKeyDown() then
			ED.ChatBox:AdjustFontSize(self, Enums.FRAME.SCROLL_DIRECTION.UP);
		else
			self.ChatBox:ScrollUp();
		end
	else
		if IsAltKeyDown() then
			self.ChatBox:ScrollToBottom();
		elseif IsControlKeyDown() then
			ED.ChatBox:AdjustFontSize(self, Enums.FRAME.SCROLL_DIRECTION.DOWN);
		else
			self.ChatBox:ScrollDown();
		end
	end

	self.fade_time = GetTime();
end

-- ============================================================
-- Hyperlink click
-- ============================================================

---Handle hyperlink clicks when IsMouseEnabled() is true
function Eavesdropper_SharedFrameMixin:OnHyperlinkClick(link, text, button)
	if not self:IsMouseEnabled() then return; end

	-- Suppress rapid clicks when scroll position just changed
	if GetTime() < (self.clickblock or 0) + Constants.FRAME.CLICKBLOCK_TIME then return; end

	local linkType, value = link:match("^(.-):(.*)$");

	-- Open edurls directly in the chat edit box
	if linkType == "edurl" and value then
		local editBox = ChatFrameUtil.ChooseBoxForSend();
		if not editBox:IsShown() then
			ChatFrameUtil.ActivateChat(editBox);
		end
		editBox:Insert(value);
		return;
	end

	-- Jump to Context: open (or focus) sender's dedicated window, scrolled to entryId.
	if linkType == "edjump" and value then
		local entryId, sender = value:match("^(%d+):(.+)$");
		if entryId and sender and ED.Database:GetGlobalSetting("DedicatedWindows") then
			ED.DedicatedFrame:JumpToEntry(sender, tonumber(entryId));
		end
		return;
	end

	SetItemRef(link, text, button, DEFAULT_CHAT_FRAME);

	self.fade_time = GetTime();
end

---Single reusable underline texture, reparented/repositioned per hover.
local NameHoverHighlight;

---@param region table
---@param left number
---@param bottom number
---@param width number
---@param height number
local function NameHoverHighlight_Show(region, left, bottom, width, height)
	if not NameHoverHighlight then
		NameHoverHighlight = region:GetParent():CreateTexture(nil, "BACKGROUND", nil, 1);
		NameHoverHighlight:SetColorTexture(0.8, 0.8, 0.8, 0.6); -- Matches Jump.png
	end

	local thickness = PixelUtil.ConvertPixelsToUIForRegion(1, region);

	NameHoverHighlight:SetParent(region:GetParent());
	NameHoverHighlight:ClearAllPoints();
	NameHoverHighlight:SetPoint("TOPLEFT", region, "TOPLEFT", left, bottom - height + thickness);
	NameHoverHighlight:SetPoint("BOTTOMRIGHT", region, "TOPLEFT", left + width, bottom - height);
	NameHoverHighlight:Show();
end

local function NameHoverHighlight_Hide()
	if NameHoverHighlight then
		NameHoverHighlight:Hide();
		NameHoverHighlight:ClearAllPoints();
	end
end

---Shows a tooltip on hover for Jump to Context links & underline under
---clickable sender names (supports Group and Mentions windows).
---@param link string
---@param text string
---@param region table
---@param left number
---@param bottom number
---@param width number?
---@param height number?
function Eavesdropper_SharedFrameMixin:OnHyperlinkEnter(link, text, region, left, bottom, width, height) -- luacheck: no unused (text)
	if not self:IsMouseEnabled() then return; end

	local linkType, value = link:match("^(.-):(.*)$");
	if not value then return; end

	if linkType == "edjump" then
		local _, sender = value:match("^(%d+):(.+)$");
		if not sender then return; end

		GameTooltip:SetOwner(self, "ANCHOR_NONE");
		GameTooltip:ClearAllPoints();
		GameTooltip:SetPoint("BOTTOMLEFT", region, "TOPLEFT", left, bottom);
		GameTooltip_SetTitle(GameTooltip, L.JUMP_TO_CONTEXT);
		GameTooltip_AddNormalLine(GameTooltip, L.JUMP_TO_CONTEXT_TOOLTIP:format(ED.Utils.StripRealmSuffix(sender)));
		GameTooltip:Show();
		return;
	end

	if linkType == "player" then
		if not width or not height then return; end
		NameHoverHighlight_Show(region, left, bottom, width, height);
	end
end

function Eavesdropper_SharedFrameMixin:OnHyperlinkLeave()
	GameTooltip:Hide();
	NameHoverHighlight_Hide();
end

-- ============================================================
-- Mouse lock / propagation
-- ============================================================

---Mouse-click propagation depends on IsMouseEnabled(), passthrough on false.
function Eavesdropper_SharedFrameMixin:UpdateMouseLock()
	local isEnabled = self:IsMouseEnabled();

	-- Always keep the frame itself mouse-enabled so OnEnter/OnLeave still fire
	self:EnableMouse(true);

	if not isEnabled then
		-- Ghost mode: pass all clicks and motion through to the world
		self:SetPropagateMouseClicks(true);
		self:SetPropagateMouseMotion(true);

		if self.SetMouseMotionEnabled then
			self:SetMouseMotionEnabled(true);
			self:SetMouseClickEnabled(true);
		end
	else
		-- Normal mode: consume clicks, block world interaction
		self:SetPropagateMouseClicks(false);
		self:SetPropagateMouseMotion(false);

		if self.SetMouseMotionEnabled then
			self:SetMouseMotionEnabled(true);
		end
	end

	-- Enable/Disable OnHyperlinkClick
	-- This delay is essential otherwise it won't take effect
	RunNextFrame(function()
		self:SetHyperlinksEnabled(isEnabled);
		if self.ChatBox then
			self.ChatBox:SetHyperlinksEnabled(isEnabled);
		end
	end);
end

-- ============================================================
-- Drag
-- ============================================================

---Begin moving the frame; only fires from the title bar when not locked
function Eavesdropper_SharedFrameMixin:OnDragStart()
	if self:IsWindowLocked() then return; end

	self:StopMovingOrSizing();
	self:StartMoving();
end

-- ============================================================
-- Layout / Appearance
-- ============================================================

---Toggle the title bar; always shown when IsTitleBarLocked() is true
---@param hoverState EavesdropperMouseHoverState
function Eavesdropper_SharedFrameMixin:ShowTitleBar(hoverState)
	if self:IsTitleBarLocked() then
		hoverState = Enums.FRAME.MOUSE_HOVER_STATE.ON;
	end

	if hoverState then
		self.TitleBar:Show();
		self.ChatBox:SetPoint("TOP", self.TitleBar, "BOTTOM", 0, -1);
	else
		self.TitleBar:Hide();
		self.ChatBox:SetPoint("TOP", self, 0, -2);
	end
end

---Show or hide the resize handle; respects IsWindowLocked()
---@param show boolean
function Eavesdropper_SharedFrameMixin:ShowResizeHandle(show)
	if not self:IsWindowLocked() and show and not self.ResizeHandle:IsShown() then
		self.ResizeHandle:Show();
	elseif not show and self.ResizeHandle:IsShown() then
		self.ResizeHandle:Hide();
	end
end

---Applies saved position and size from a CharDB entry onto this frame so SaveToCharDB picks them up.
---@param pos table?
---@param size table?
function Eavesdropper_SharedFrameMixin:ApplySavedLayout(pos, size)
	if pos then
		self.savedPos = pos;
		self:ClearAllPoints();
		self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y);
	end
	if size then
		self.savedSize = size;
		self:SetSize(size.width, size.height);
	end
end

---Restore resize handle and close-button visibility from local frame state.
---Overridden by Eavesdropper_FrameMixin to also restore position and size from the DB.
function Eavesdropper_SharedFrameMixin:RestoreLayout()
	if not ED.Database then return; end

	if not self.lockWindow then
		self.ResizeHandle:Show();
	else
		self.ResizeHandle:Hide();
	end

	if self.hideCloseButton then
		self.TitleBar.CloseButton:Hide();
	else
		self.TitleBar.CloseButton:Show();
	end
end

---Hide in combat when the setting is on; otherwise show the frame.
---Overridden by Eavesdropper_FrameMixin for HideWhenEmpty and WindowVisible logic.
function Eavesdropper_SharedFrameMixin:HandleVisibility()
	if ED.Database:GetSetting("HideInCombat") and ED.Utils.CombatLockdown() then
		self:Hide();
		return;
	end

	self:Show();
end

---Apply font, filters, layout, colors, and history to this frame.
---Instance frames call this directly; the main frame's ApplyProfileSettings
---calls this then additionally refreshes the settings panel.
function Eavesdropper_SharedFrameMixin:ApplyWindowSettings()
	ED.ChatBox:ApplyFontOptions(self);
	ED.ChatFilters:UpdateFilters(self);
	self:RestoreLayout();
	self:ApplyThemeColors();
	self:RefreshChat();
end

---Apply background and title bar colors from the database
function Eavesdropper_SharedFrameMixin:ApplyThemeColors()
	if not ED.Database then return; end

	local background = self.Background;
	if background then
		local bg = ED.Database:GetSetting("ColorBackground");
		if type(bg) ~= "table" then
			bg = { r = 0, g = 0, b = 0, a = 0.5 };
		end
		background:SetColorTexture(bg.r, bg.g, bg.b, bg.a);
	end

	if self.TitleBar and self.TitleBar.Background then
		local tb = ED.Database:GetSetting("ColorTitleBar");
		if type(tb) ~= "table" then
			tb = { r = 0, g = 0, b = 0, a = 0.25 };
		end
		self.TitleBar.Background:SetColorTexture(tb.r, tb.g, tb.b, tb.a);
	end
end

---Close button (12px) + right offset (2px) + gap (2px).
local CloseButtonReserved = 16;
---Internal padding added to measured text width so the label stays visually centered.
local TitleButtonPadding = 24;
local MinTitleButtonWidth = 110;

---Resize the TitleButton to fit its text, clamped between the minimum width and available TitleBar width.
function Eavesdropper_SharedFrameMixin:ResizeTitleButton()
	local titleButton = self.TitleBar and self.TitleBar.TitleButton;
	if not titleButton or not titleButton.Text then return; end

	local textWidth = titleButton.Text:GetStringWidth() + TitleButtonPadding;
	local maxWidth = self.TitleBar:GetWidth() - CloseButtonReserved;
	local width = Clamp(textWidth, MinTitleButtonWidth, maxWidth);

	titleButton:SetWidth(width);
end

---Recalculate the TitleButton width when the frame is resized.
function Eavesdropper_SharedFrameMixin:OnSizeChanged()
	self:ResizeTitleButton();
end

-- ============================================================
-- New-Indicator helpers
-- ============================================================

---Hard reset: stop all animations and clear both state flags.
---Safe to call when self.NewIndicator is nil.
function Eavesdropper_SharedFrameMixin:ResetNewIndicator()
	if not self.NewIndicator then return; end
	if self.NewIndicator.NewIndicatorFadeIn then self.NewIndicator.NewIndicatorFadeIn:Stop(); end
	if self.NewIndicator.NewIndicatorFadeOut then self.NewIndicator.NewIndicatorFadeOut:Stop(); end
	self.NewIndicator.isFadedIn = false;
	self.NewIndicator.isFadedOut = false;
end

---Play the fade-in animation if the indicator is not already visible.
---Safe to call when self.NewIndicator is nil.
function Eavesdropper_SharedFrameMixin:FadeInNewIndicator()
	if not self.NewIndicator then return; end
	if self.NewIndicator.isFadedIn then return; end
	self.NewIndicator:Show();
	self.NewIndicator.NewIndicatorFadeIn:Stop();
	self.NewIndicator.NewIndicatorFadeOut:Stop();
	self.NewIndicator.NewIndicatorFadeIn:Play();
	self.NewIndicator.isFadedIn = true;
	self.NewIndicator.isFadedOut = false;
end

---Play the fade-out animation if the indicator is currently visible.
---Safe to call when self.NewIndicator is nil.
function Eavesdropper_SharedFrameMixin:FadeOutNewIndicator()
	if not self.NewIndicator then return; end
	if not self.NewIndicator.isFadedIn or self.NewIndicator.isFadedOut then return; end
	self.NewIndicator.NewIndicatorFadeIn:Stop();
	self.NewIndicator.NewIndicatorFadeOut:Stop();
	self.NewIndicator.NewIndicatorFadeOut:Play();
	self.NewIndicator.isFadedOut = true;
	self.NewIndicator.isFadedIn = false;
end

---(Re-)schedule the auto fade-out timer; cancels any running timer first.
function Eavesdropper_SharedFrameMixin:ScheduleNewIndicatorFadeOut()
	if self.newIndicatorTimer then
		self.newIndicatorTimer:Cancel();
		self.newIndicatorTimer = nil;
	end

	self.newIndicatorTimer = C_Timer.NewTimer(Constants.CHAT_NEW_INDICATOR_FADE_OUT, function()
		self:FadeOutNewIndicator();
		self.newIndicatorTimer = nil;
	end);
end

-- ============================================================
-- Chat helpers
-- ============================================================

---Populate the ChatBox from history for player; tries the full name-realm first and then bare name.
---@param player string
---@param maxMessages number
function Eavesdropper_SharedFrameMixin:PopulateHistoryMessages(player, maxMessages)
	local chatFull = ED.ChatHistory:GetPlayerHistory(player, maxMessages, self);
	if chatFull and #chatFull > 0 then
		for _, entry in ipairs(chatFull) do
			self:AddMessage(entry, true);
		end
		return;
	end

	local chatBare = ED.ChatHistory:GetPlayerHistory(ED.Utils.StripRealmSuffix(player), maxMessages, self);
	if chatBare and #chatBare > 0 then
		for _, entry in ipairs(chatBare) do
			self:AddMessage(entry, true);
		end
	end
end

---Record the newest displayed entry's timestamp, read by IsTimestampFrozen.
---Takes the maximum, as group windows merge several histories out of order.
---@param entry EavesdropperChatEntry
function Eavesdropper_SharedFrameMixin:TrackNewestEntry(entry)
	if not entry.t then return; end

	if not self.newestEntryTime or entry.t > self.newestEntryTime then
		self.newestEntryTime = entry.t;
	end
end

---Record the clickblock timestamp then delegate to AddMessage.
---Dedicated and Group frames override this to also handle the new-message indicator.
---@param entry EavesdropperChatEntry
function Eavesdropper_SharedFrameMixin:TryAddMessage(entry)
	if self.ChatBox:GetScrollOffset() == 0 then
		self.clickblock = GetTime();
	end

	self:AddMessage(entry);

	-- A new message un-freezes the window; the flag skips the Magnifier-driven main frame.
	if self.usesChatTicker then
		self:StartChatTicker();
	end
end

-- ============================================================
-- Screenshot Helper
-- ============================================================

function Eavesdropper_SharedFrameMixin:SetAlphaChannelMode(mode)
	-- mode 1: All Widgets turn black + white fullscreen backdrop
	-- mode 2: Widgets use original colors + black fullscreen backdrop
	-- other : Disable

	-- Nothing to restore if this frame was never colorized
	if not mode and not self.alphaChannelMode then return; end

	self.alphaChannelMode = mode;

	local frameStrata;

	ED.ScreenshotHelper.SetupObjectColorByMode(self, mode);

	if mode == 1 or mode == 2 then
		frameStrata = "MEDIUM";
		self:Raise();
	else
		frameStrata = "BACKGROUND";
		self:ApplyThemeColors();
	end

	self:SetFrameStrata(frameStrata);
end
