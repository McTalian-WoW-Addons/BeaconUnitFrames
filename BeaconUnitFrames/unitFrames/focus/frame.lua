---@class BUFNamespace
local ns = select(2, ...)

---@class BUFFocus
local BUFFocus = ns.BUFFocus

---@class BUFFocus.Frame: Sizable, BackgroundTexturable
local BUFFocusFrame = {
	configPath = "unitFrames.focus.frame",
	frameKey = BUFFocus.relativeToFrames.FRAME,
}

ns.Mixin(BUFFocusFrame, ns.Sizable, ns.BackgroundTexturable)

BUFFocus.Frame = BUFFocusFrame

---@class BUFDbSchema.UF.Focus
ns.dbDefaults.profile.unitFrames.focus = ns.dbDefaults.profile.unitFrames.focus

---@class BUFDbSchema.UF.Focus.Frame
ns.dbDefaults.profile.unitFrames.focus.frame = {
	width = 232,
	height = 100,
	enableFrameFlash = true,
	enableFrameTexture = true,
	useBackgroundTexture = false,
	backgroundTexture = "None",
	useBackdropBorder = false,
	backdropBorderTexture = "None",
	backdropEdgeSize = 16,
	backdropBorderColor = { 1, 1, 1, 1 },
}

local frameOrder = {}

ns.Mixin(frameOrder, ns.defaultOrderMap)
frameOrder.FRAME_FLASH = frameOrder.ENABLE + 0.1
frameOrder.FRAME_TEXTURE = frameOrder.FRAME_FLASH + 0.1
frameOrder.BACKDROP_AND_BORDER = frameOrder.FRAME_TEXTURE + 0.1

local frame = {
	type = "group",
	handler = BUFFocusFrame,
	name = ns.L["Frame"],
	order = BUFFocus.optionsOrder.FRAME,
	args = {
		frameFlash = {
			type = "toggle",
			name = ns.L["EnableFrameFlash"],
			set = "SetEnableFrameFlash",
			get = "GetEnableFrameFlash",
			order = frameOrder.FRAME_FLASH,
		},
		frameTexture = {
			type = "toggle",
			name = ns.L["EnableFrameTexture"],
			set = "SetEnableFrameTexture",
			get = "GetEnableFrameTexture",
			order = frameOrder.FRAME_TEXTURE,
		},
	},
}

ns.AddSizableOptions(frame.args, frameOrder)
ns.AddBackgroundTextureOptions(frame.args, frameOrder)

ns.options.args.focus.args.frame = frame

function BUFFocusFrame:SetEnableFrameFlash(info, value)
	self:DbSet("enableFrameFlash", value)
	self:SetFrameFlash()
end

function BUFFocusFrame:GetEnableFrameFlash(info)
	return self:DbGet("enableFrameFlash")
end

function BUFFocusFrame:SetEnableFrameTexture(info, value)
	self:DbSet("enableFrameTexture", value)
	self:SetFrameTexture()
end

function BUFFocusFrame:GetEnableFrameTexture(info)
	return self:DbGet("enableFrameTexture")
end

function BUFFocusFrame:RefreshConfig()
	if not self.initialized then
		BUFFocus.FrameInit(self)

		if not BUFFocus.frame then
			error("BUFFocus.frame is nil in BUFFocusFrame:RefreshConfig")
		end
		self.frame = BUFFocus.frame

		if not BUFFocus:IsHooked(BUFFocus.frame, "AnchorSelectionFrame") then
			BUFFocus:SecureHook(BUFFocus.frame, "AnchorSelectionFrame", function()
				if BUFFocus.frame.Selection then
					BUFFocus.frame.Selection:ClearAllPoints()
					BUFFocus.frame.Selection:SetAllPoints(BUFFocus.frame)
				end
			end)
		end
	end
	self:SetSize()
	self:SetFrameFlash()
	self:SetFrameTexture()
	self:RefreshBackgroundTexture()
end

function BUFFocusFrame:SetSize()
	self:_SetSize(self.frame)
end

function BUFFocusFrame:SetFrameFlash()
	local enable = self:DbGet("enableFrameFlash")
	if enable then
		BUFFocus:Unhook(BUFFocus.container.Flash, "Show")
		BUFFocus.container.Flash:Show()
	else
		BUFFocus.container.Flash:Hide()
		if not BUFFocus:IsHooked(BUFFocus.container.Flash, "Show") then
			BUFFocus:SecureHook(BUFFocus.container.Flash, "Show", function(s)
				s:Hide()
			end)
		end
	end
end

function BUFFocusFrame:SetFrameTexture()
	local enable = self:DbGet("enableFrameTexture")
	local texture = BUFFocus.container.FrameTexture
	local healthBarMask = BUFFocus.healthBarContainer.HealthBarMask
	local manaBarMask = BUFFocus.manaBar.ManaBarMask
	if enable then
		BUFFocus:Unhook(texture, "Show")
		BUFFocus:Unhook(healthBarMask, "Show")
		BUFFocus:Unhook(manaBarMask, "Show")
		texture:Show()
		healthBarMask:Show()
		manaBarMask:Show()
	else
		texture:Hide()
		healthBarMask:Hide()
		manaBarMask:Hide()

		if not BUFFocus:IsHooked(texture, "Show") then
			BUFFocus:SecureHook(texture, "Show", function(s)
				s:Hide()
			end)
		end

		if not BUFFocus:IsHooked(healthBarMask, "Show") then
			BUFFocus:SecureHook(healthBarMask, "Show", function(s)
				s:Hide()
			end)
		end

		if not BUFFocus:IsHooked(manaBarMask, "Show") then
			BUFFocus:SecureHook(manaBarMask, "Show", function(s)
				s:Hide()
			end)
		end
	end
end

function BUFFocusFrame:RefreshBackgroundTexture()
	local useBackgroundTexture = self:DbGet("useBackgroundTexture")
	local useBackdropBorder = self:DbGet("useBackdropBorder")

	if not useBackgroundTexture and not useBackdropBorder then
		if self.backdropFrame then
			self.backdropFrame:Hide()
		end
		return
	end

	if not self.backdropFrame then
		self.backdropFrame = CreateFrame("Frame", nil, BUFFocus.frame, "BackdropTemplate")
		self.backdropFrame:SetFrameStrata("BACKGROUND")
	end

	local bgTexturePath = nil
	if useBackgroundTexture then
		local backgroundTexture = self:DbGet("backgroundTexture")
		bgTexturePath = ns.lsm:Fetch(ns.lsm.MediaType.BACKGROUND, backgroundTexture)
		if not bgTexturePath then
			bgTexturePath = "Interface/None"
		end
	end

	local borderTexturePath = nil
	if useBackdropBorder then
		local backdropBorderTexture = self:DbGet("backdropBorderTexture")
		borderTexturePath = ns.lsm:Fetch(ns.lsm.MediaType.BORDER, backdropBorderTexture)
		if not borderTexturePath then
			borderTexturePath = "Interface/Tooltips/UI-Tooltip-Border"
		end
	end

	local backdropInsetLeft = self:GetBackdropInsetLeft()
	local backdropInsetRight = self:GetBackdropInsetRight()
	local backdropInsetTop = self:GetBackdropInsetTop()
	local backdropInsetBottom = self:GetBackdropInsetBottom()

	self.backdropFrame:ClearAllPoints()
	self.backdropFrame:SetPoint("TOPLEFT", BUFFocus.frame, "TOPLEFT", backdropInsetLeft, -backdropInsetTop)
	self.backdropFrame:SetPoint("BOTTOMRIGHT", BUFFocus.frame, "BOTTOMRIGHT", -backdropInsetRight, backdropInsetBottom)

	local backdropEdgeSize = self:DbGet("backdropEdgeSize")
	self.backdropFrame:SetBackdrop({
		bgFile = bgTexturePath,
		edgeFile = borderTexturePath,
		tile = true,
		tileSize = 16,
		edgeSize = useBackdropBorder and backdropEdgeSize or 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})

	if useBackdropBorder then
		local color = self:DbGet("backdropBorderColor")
		self.backdropFrame:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
	end

	self.backdropFrame:Show()
end
