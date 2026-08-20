-- Copyright The Eavesdropper Authors
-- SPDX-License-Identifier: GPL-3.0-or-later

---@type EavesdropperConstants
local Constants = ED.Constants;

---@class Eavesdropper_SimpleSliderMixin
Eavesdropper_SimpleSliderMixin = {};

local GetCursorPosition = GetCursorPosition;

function Eavesdropper_SimpleSliderMixin:OnLoad()
	self.Thumb:SetWidth(Constants.SCROLLBAR.SLIDER_WIDTH);
	self:SetWidth(Constants.SCROLLBAR.SLIDER_WIDTH);
	self:UpdateVisual();

	self.maxScrollRange = 0;
	self.scrollPercentage = 0;
	self.visibleExtentPercentage = 0;
	self.minimizeDelay = 0;
	self.thumbPadding = 1;

	self.messageFrame = self:GetParent();

	self.Thumb:SetScript("OnEnter", function()
		self:UpdateVisual();
	end);

	self.Thumb:SetScript("OnLeave", function()
		self:UpdateVisual();
	end);

	RunNextFrame(function()
		self:InitScrollbarForMessageFrame(self.messageFrame);
	end);
end

---Hook into the message frame's own refresh cycle so the slider stays in sync with scroll state.
---@param messageFrame table
function Eavesdropper_SimpleSliderMixin:InitScrollbarForMessageFrame(messageFrame)
	messageFrame:AddOnDisplayRefreshedCallback(function()
		self:OnDisplayRefreshed();
	end);
end

function Eavesdropper_SimpleSliderMixin:OnDisplayRefreshed()
	if not self.messageFrame then return; end

	local maxScrollRange = self.messageFrame:GetMaxScrollRange();
	local scrollPercentage = 0;

	if maxScrollRange > 0 then
		scrollPercentage = self.messageFrame:GetScrollOffset() / maxScrollRange;
	else
		maxScrollRange = 0;
	end

	scrollPercentage = 1.0 - scrollPercentage;

	local visibleExtentPercentage = 0;
	local messages = self.messageFrame:GetNumMessages();
	if messages > 1 then
		visibleExtentPercentage = 1 / messages;
	end

	self.maxScrollRange = maxScrollRange;
	self.scrollPercentage = scrollPercentage;
	self.visibleExtentPercentage = Saturate(visibleExtentPercentage);

	self:UpdateSlider();
end

function Eavesdropper_SimpleSliderMixin:OnEnter()
	self:UpdateVisual();
end

function Eavesdropper_SimpleSliderMixin:OnLeave()
	self:UpdateVisual();
end

function Eavesdropper_SimpleSliderMixin:OnShow()
	self.thumbPadding = PixelUtil.ConvertPixelsToUIForRegion(1, self);
	self.Thumb.Texture:ClearAllPoints();
	self.Thumb.Texture:SetPoint("TOPRIGHT", self.Thumb, "TOPRIGHT", -self.thumbPadding, -self.thumbPadding);
	self.Thumb.Texture:SetPoint("BOTTOMRIGHT", self.Thumb, "BOTTOMRIGHT", -self.thumbPadding, self.thumbPadding);
	self:UpdateVisual();

	if Constants.SCROLLBAR.MAXIMIZE_ON_SHOW then
		self:TriggerMaximizeMode();
	end
end

function Eavesdropper_SimpleSliderMixin:OnHide()
	self:OnMouseUp();
	self.forceMaximized = nil;
	self.minimizeDelay = nil;
	self:Minimize(true);
end

function Eavesdropper_SimpleSliderMixin:OnMouseDown()
	self.mouseDown = true;
	if self:IsMouseMotionFocus() then
		if self.Thumb:IsMouseOver() then
			self:StartDraggingThumb();
		else
			local _, y = GetCursorPosition();
			y = y / self:GetEffectiveScale();
			local top = self:GetTop();
			local bottom = self:GetBottom();

			if self.thumbRange > 0 then
				local percentage = (top - y) / (top - bottom);
				self:SetMessageFrameScrollPercentage(percentage);
				RunNextFrame(function()
					if self.mouseDown then
						self:OnMouseDown();
					end
				end);
			end
		end
	end
	self:UpdateVisual();
end

function Eavesdropper_SimpleSliderMixin:OnMouseUp()
	self.mouseDown = false;
	self:StopDraggingThumb();
	self:UpdateVisual();
end

---@param percentage number
function Eavesdropper_SimpleSliderMixin:SetMessageFrameScrollPercentage(percentage)
	percentage = Clamp(percentage, 0, 1);
	self.messageFrame:SetScrollOffset(math.floor(self.maxScrollRange * (1 - percentage) + 0.5));
end

---@param instant boolean?
function Eavesdropper_SimpleSliderMixin:Maximize(instant)
	local thumbFinalWidth = Constants.SCROLLBAR.SLIDER_WIDTH - 1 * self.thumbPadding;

	if instant then
		self.isMaximized = true;
		self.Track:SetAlpha(Constants.SCROLLBAR.TRACK_NORMAL_ALPHA);
		self.Thumb.Texture:SetWidth(thumbFinalWidth);
		self.minimizeDelay = Constants.SCROLLBAR.MINIMIZE_DELAY;
		return;
	end

	if not self.isMaximized then
		self.isMaximized = true;
		self.widthMultiplier = Constants.SCROLLBAR.SLIDER_WIDTH / 0.12;
		self.minimizeDelay = 0;

		self.Thumb:SetScript("OnUpdate", function(f, elapsed)
			local isAnimating;

			local alpha = self.Track:GetAlpha() + 1 * elapsed;
			if alpha > Constants.SCROLLBAR.TRACK_NORMAL_ALPHA then
				alpha = Constants.SCROLLBAR.TRACK_NORMAL_ALPHA;
			else
				isAnimating = true;
			end
			self.Track:SetAlpha(alpha);

			local width = self.Thumb.Texture:GetWidth() + self.widthMultiplier * elapsed;
			if width >= thumbFinalWidth then
				width = thumbFinalWidth;
			else
				isAnimating = true;
			end
			self.Thumb.Texture:SetWidth(width);

			if not isAnimating then
				f:SetScript("OnUpdate", nil);
				self.minimizeDelay = Constants.SCROLLBAR.MINIMIZE_DELAY;
			end
		end);
	end
end

---@param instant boolean?
function Eavesdropper_SimpleSliderMixin:Minimize(instant)
	if self.forceMaximized then return; end

	if instant then
		self.isMaximized = false;
		self.Track:SetAlpha(0);
		self.Thumb.Texture:SetWidth(Constants.SCROLLBAR.THUMB_MINIMIZED_WIDTH);
		return;
	end

	if self.isMaximized ~= false then
		self.isMaximized = false;
		self.widthMultiplier = Constants.SCROLLBAR.SLIDER_WIDTH / 0.2;

		self.Thumb:SetScript("OnUpdate", function(f, elapsed)
			if self.minimizeDelay and self.minimizeDelay > 0 then
				self.minimizeDelay = self.minimizeDelay - elapsed;
				return;
			end

			local isAnimating;

			local alpha = self.Track:GetAlpha() - 1 * elapsed;
			if alpha <= 0 then
				alpha = 0;
			else
				isAnimating = true;
			end
			self.Track:SetAlpha(alpha);

			local width = self.Thumb.Texture:GetWidth() - self.widthMultiplier * elapsed;
			if width <= Constants.SCROLLBAR.THUMB_MINIMIZED_WIDTH then
				width = Constants.SCROLLBAR.THUMB_MINIMIZED_WIDTH;
			else
				isAnimating = true;
			end
			self.Thumb.Texture:SetWidth(width);

			if not isAnimating then
				f:SetScript("OnUpdate", nil);
			end
		end);
	end
end

function Eavesdropper_SimpleSliderMixin:TriggerMaximizeMode()
	if not self.isMaximized then
		self.forceMaximized = true;
		self:Maximize(true);
		C_Timer.After(0.5, function()
			self.forceMaximized = nil;
			self:UpdateVisual();
		end);
	end
end

function Eavesdropper_SimpleSliderMixin:UpdateVisual()
	if self:IsDraggingThumb() then
		self.Thumb.Texture:SetColorTexture(1, 1, 1, Constants.SCROLLBAR.THUMB_DRAG_ALPHA);
		self:Maximize();
	else
		if self.Thumb:IsMouseMotionFocus() then
			self.Thumb.Texture:SetColorTexture(1, 1, 1, Constants.SCROLLBAR.THUMB_HIGHLIGHT_ALPHA);
		else
			self.Thumb.Texture:SetColorTexture(1, 1, 1, Constants.SCROLLBAR.THUMB_NORMAL_ALPHA);
		end

		if self:IsMouseMotionFocus() then
			self:Maximize();
		else
			self:Minimize();
		end
	end
end

function Eavesdropper_SimpleSliderMixin:StartDraggingThumb()
	self.x0, self.y0 = GetCursorPosition();
	self.scale = self:GetEffectiveScale();
	self.y0 = self.y0 / self.scale;
	self:UpdateSlider();
	self.fromScrollPercentage = self.scrollPercentage;
	self.isDraggingThumb = true;
	self.t = 0;
	self:SetScript("OnUpdate", self.OnUpdate_DraggingThumb);
end

function Eavesdropper_SimpleSliderMixin:StopDraggingThumb()
	self.isDraggingThumb = false;
	self.t = 0;
	self:SetScript("OnUpdate", nil);
end

function Eavesdropper_SimpleSliderMixin:OnUpdate_DraggingThumb()
	self.x, self.y = GetCursorPosition();
	self.y = self.y / self.scale;
	self.dy = self.y - self.y0;

	if self.thumbRange > 0 then
		self.percentage = self.fromScrollPercentage - self.dy / self.thumbRange;
		self:SetMessageFrameScrollPercentage(self.percentage);
	end
end

---@return boolean
function Eavesdropper_SimpleSliderMixin:IsDraggingThumb()
	return self.isDraggingThumb;
end

function Eavesdropper_SimpleSliderMixin:UpdateSlider()
	local sliderHeight = self:GetHeight();
	local thumbHeight = math.max(Constants.SCROLLBAR.THUMB_MIN_HEIGHT, self.visibleExtentPercentage * sliderHeight);
	local thumbRange = sliderHeight - thumbHeight;

	local offsetY;

	if thumbRange <= 0 then
		thumbRange = 0;
		offsetY = 0;
	else
		offsetY = thumbRange * self.scrollPercentage;
	end

	self.Thumb:SetPoint("TOPRIGHT", 0, -offsetY);
	self.Thumb:SetHeight(thumbHeight);
	self.thumbRange = thumbRange;

	self:SetShown(self.maxScrollRange > Constants.SCROLLBAR.SHOW_MIN_SCROLL_RANGE);
end

function Eavesdropper_SimpleSliderMixin:OnSizeChanged()
	if not self.sizeDirty then
		self.sizeDirty = true;
		RunNextFrame(function()
			self:UpdateSlider();
		end);
	end
end

function Eavesdropper_SimpleSliderMixin:FullUpdate()
	self:StopDraggingThumb();
	self:OnDisplayRefreshed();
	self:UpdateVisual();
end
