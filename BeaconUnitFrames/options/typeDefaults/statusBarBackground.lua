---@class BUFNamespace
local ns = select(2, ...)

--- Add status bar background options to the given options table.
--- Background colour is placed first so it is immediately visible without scrolling.
--- @param optionsTable table
--- @param _orderMap? BUFOptionsOrder
function ns.AddStatusBarBackgroundOptions(optionsTable, _orderMap)
	local orderMap = _orderMap or ns.defaultOrderMap

	-- Background colour sits right below the "Background Options" header so
	-- it is visible without scrolling, before the texture picker.
	optionsTable.customColor = {
		type = "color",
		name = ns.L["Background Color"],
		hasAlpha = true,
		set = "SetCustomColor",
		get = "GetCustomColor",
		order = orderMap.BACKGROUND_COLOR,
	}

	ns.AddBackgroundTextureOptions(optionsTable, orderMap)
end

---@class StatusBarBackgroundHandler
---@field background Texture           fill texture, renders behind the bar at BACKGROUND draw layer
---@field borderFrame Frame|nil        border-only BackdropTemplate frame parented to UIParent at MEDIUM strata
---@field RefreshColor fun(self: StatusBarBackground)
---@field RefreshBackgroundTexture fun(self: StatusBarBackground)
---@field RestoreDefaultBackgroundTexture fun(self: StatusBarBackground)

---@class StatusBarBackground: StatusBarBackgroundHandler, Colorable, BackgroundTexturable
local StatusBarBackground = {}

local function SyncBorderFrameVisibility(borderFrame)
	if not borderFrame then
		return
	end

	local parent = borderFrame.bufBackgroundParent or borderFrame:GetParent()
	local shouldShow = borderFrame.bufBorderEnabled and parent and parent:IsVisible()
	borderFrame:SetShown(shouldShow)
end

local function RegisterBorderVisibilityHooks(borderFrame)
	if not borderFrame or borderFrame.bufVisibilityHooksRegistered then
		return
	end

	local parent = borderFrame.bufBackgroundParent or borderFrame:GetParent()
	if not parent or not parent.HookScript then
		return
	end

	parent:HookScript("OnShow", function()
		SyncBorderFrameVisibility(borderFrame)
	end)
	parent:HookScript("OnHide", function()
		SyncBorderFrameVisibility(borderFrame)
	end)

	borderFrame.bufVisibilityHooksRegistered = true
end

--- Apply mixins to a StatusBarBackground
--- @param self StatusBarBackground
--- @param handler BUFConfigHandler
function StatusBarBackground:ApplyMixin(handler)
	ns.Mixin(handler, ns.Colorable, ns.BackgroundTexturable)
	ns.Mixin(handler, self)

	if handler.optionsTable then
		ns.AddStatusBarBackgroundOptions(handler.optionsTable.args, handler.optionsOrder)
	end
end

--- Create the background fill texture and border overlay frame for a single-frame background handler.
--- Textures created directly on barOrContainer are safe on secure frames and never cause taint.
--- The border frame is parented to UIParent (not the secure frame hierarchy) and rendered at
--- MEDIUM strata so the border edge is visible above the bar fill at LOW strata.
--- @param barOrContainer Frame  The bar or its container to anchor both objects to.
function StatusBarBackground:InitBackground(barOrContainer)
	self.background = barOrContainer:CreateTexture(nil, "BACKGROUND", nil, -8)
	self.background:SetAllPoints(barOrContainer)

	self.borderFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	self.borderFrame:SetFrameStrata("MEDIUM")
	self.borderFrame.bufBackgroundParent = barOrContainer
	RegisterBorderVisibilityHooks(self.borderFrame)
end

--- Create background fill texture and border overlay for one entry in a multi-frame handler.
--- Writes `background` and `borderFrame` into store (e.g. bbi.health or bpi.power).
--- @param store table           Table to write into.
--- @param barOrContainer Frame  The bar or its container.
function StatusBarBackground:InitFrameBackground(store, barOrContainer)
	store.background = barOrContainer:CreateTexture(nil, "BACKGROUND", nil, -8)
	store.background:SetAllPoints(barOrContainer)

	store.borderFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	store.borderFrame:SetFrameStrata("MEDIUM")
	store.borderFrame.bufBackgroundParent = barOrContainer
	RegisterBorderVisibilityHooks(store.borderFrame)
end

function StatusBarBackground:RefreshStatusBarBackgroundConfig()
	self:RefreshBackgroundTexture()
	self:RefreshColor()
end

function StatusBarBackground:RefreshBackgroundTexture()
	self:_RefreshBackgroundTexture(self.background)
	self:_RefreshBorderFrame(self.borderFrame)
end

--- Refresh the fill texture.  Handles both Texture regions (bar backgrounds) and
--- BackdropTemplate frames (kept for compatibility with frame.lua's direct usage).
--- @param background Texture|Frame
function StatusBarBackground:_RefreshBackgroundTexture(background)
	if not background then
		return
	end

	if background.SetBackdrop then
		-- BackdropTemplate frame path: fill only, no border (border is handled by _RefreshBorderFrame).
		local bgTexturePath
		if self:GetUseBackgroundTexture() then
			local textureName = self:GetBackgroundTexture() or "None"
			bgTexturePath = ns.lsm:Fetch(ns.lsm.MediaType.BACKGROUND, textureName)
			if not bgTexturePath then
				bgTexturePath = "Interface/Buttons/WHITE8x8"
			end
		else
			bgTexturePath = "Interface/Buttons/WHITE8x8"
		end

		local parent = background.bufBackgroundParent or background:GetParent()
		background:ClearAllPoints()
		background:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
		background:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
		background:SetBackdrop({
			bgFile = bgTexturePath,
			edgeFile = nil,
			tile = true,
			tileSize = 16,
			edgeSize = 0,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		background:Show()
		return
	end

	-- Texture path (normal bar backgrounds).
	if self:GetUseBackgroundTexture() then
		local textureName = self:GetBackgroundTexture() or "None"
		local texturePath = ns.lsm:Fetch(ns.lsm.MediaType.BACKGROUND, textureName)
		if not texturePath then
			texturePath = "Interface/Buttons/WHITE8x8"
		end
		background:SetTexture(texturePath)
	else
		self:RestoreDefaultBackgroundTexture()
	end
	background:Show()
end

--- Apply or hide the border overlay frame based on current settings.
--- @param borderFrame Frame|nil
function StatusBarBackground:_RefreshBorderFrame(borderFrame)
	if not borderFrame then
		return
	end

	if not self:GetUseBackdropBorder() then
		borderFrame.bufBorderEnabled = false
		if borderFrame.SetBackdrop then
			borderFrame:SetBackdrop(nil)
		end
		borderFrame:Hide()
		return
	end

	local borderTextureName = self:GetBackdropBorderTexture() or "None"
	local borderTexturePath = ns.lsm:Fetch(ns.lsm.MediaType.BORDER, borderTextureName)
	if not borderTexturePath then
		borderTexturePath = "Interface/Tooltips/UI-Tooltip-Border"
	end

	local parent = borderFrame.bufBackgroundParent or borderFrame:GetParent()
	borderFrame.bufBorderEnabled = true
	borderFrame:ClearAllPoints()
	-- PixelUtil.SetPoint snaps offsets to the nearest physical screen pixel,
	-- preventing the uneven left/right/top/bottom thickness artifact that appears
	-- when sub-pixel float offsets cause rounding in the renderer.
	PixelUtil.SetPoint(
		borderFrame,
		"TOPLEFT",
		parent,
		"TOPLEFT",
		self:GetBackdropInsetLeft(),
		-self:GetBackdropInsetTop()
	)
	PixelUtil.SetPoint(
		borderFrame,
		"BOTTOMRIGHT",
		parent,
		"BOTTOMRIGHT",
		-self:GetBackdropInsetRight(),
		self:GetBackdropInsetBottom()
	)
	borderFrame:SetBackdrop({
		bgFile = nil,
		edgeFile = borderTexturePath,
		tile = false,
		tileSize = 0,
		edgeSize = self:GetBackdropEdgeSize(),
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})

	local br, bg, bb, ba = self:GetBackdropBorderColor()
	borderFrame:SetBackdropBorderColor(br, bg, bb, ba)
	SyncBorderFrameVisibility(borderFrame)
end

function StatusBarBackground:RestoreDefaultBackgroundTexture()
	if self.background then
		-- WHITE8x8 lets SetVertexColor drive the actual displayed colour.
		self.background:SetTexture("Interface/Buttons/WHITE8x8")
	end
end

function StatusBarBackground:RefreshColor()
	self:_RefreshColor(self.background)
end

function StatusBarBackground:_RefreshColor(background)
	if not background then
		return
	end
	local r, g, b, a = self:GetCustomColor()
	if background.SetBackdropColor then
		background:SetBackdropColor(r, g, b, a)
	else
		background:SetVertexColor(r, g, b, a)
	end
end

ns.StatusBarBackground = StatusBarBackground
