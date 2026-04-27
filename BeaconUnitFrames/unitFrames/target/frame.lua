---@class BUFNamespace
local ns = select(2, ...)

---@class BUFTarget
local BUFTarget = ns.BUFTarget

---@class BUFTarget.Frame: Sizable, BackgroundTexturable
local BUFTargetFrame = {
	configPath = "unitFrames.target.frame",
	frameKey = BUFTarget.relativeToFrames.FRAME,
}

ns.Mixin(BUFTargetFrame, ns.Sizable, ns.BackgroundTexturable)

BUFTarget.Frame = BUFTargetFrame

---@class BUFDbSchema.UF.Target
ns.dbDefaults.profile.unitFrames.target = ns.dbDefaults.profile.unitFrames.target

---@class BUFDbSchema.UF.Target.Frame
ns.dbDefaults.profile.unitFrames.target.frame = {
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
	handler = BUFTargetFrame,
	name = ns.L["Frame"],
	order = BUFTarget.optionsOrder.FRAME,
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

ns.options.args.target.args.frame = frame

function BUFTargetFrame:SetEnableFrameFlash(info, value)
	self:DbSet("enableFrameFlash", value)
	self:SetFrameFlash()
end

function BUFTargetFrame:GetEnableFrameFlash(info)
	return self:DbGet("enableFrameFlash")
end

function BUFTargetFrame:SetEnableFrameTexture(info, value)
	self:DbSet("enableFrameTexture", value)
	self:SetFrameTexture()
end

function BUFTargetFrame:GetEnableFrameTexture(info)
	return self:DbGet("enableFrameTexture")
end

function BUFTargetFrame:RefreshConfig()
	if not self.initialized then
		BUFTarget.FrameInit(self)

		self.frame = BUFTarget.frame

		if not BUFTarget:IsHooked(BUFTarget.frame, "AnchorSelectionFrame") then
			BUFTarget:SecureHook(BUFTarget.frame, "AnchorSelectionFrame", function()
				if BUFTarget.frame.Selection then
					BUFTarget.frame.Selection:ClearAllPoints()
					BUFTarget.frame.Selection:SetAllPoints(BUFTarget.frame)
				end
			end)
		end
	end
	self:SetSize()
	self:SetFrameFlash()
	self:SetFrameTexture()
	self:RefreshBackgroundTexture()
end

function BUFTargetFrame:SetSize()
	self:_SetSize(self.frame)
end

function BUFTargetFrame:SetFrameFlash()
	local target = BUFTarget
	local enable = self:DbGet("enableFrameFlash")
	if enable then
		target:Unhook(target.container.Flash, "Show")
		target.container.Flash:Show()
	else
		target.container.Flash:Hide()
		if not target:IsHooked(target.container.Flash, "Show") then
			target:SecureHook(target.container.Flash, "Show", function(s)
				s:Hide()
			end)
		end
	end
end

function BUFTargetFrame:SetFrameTexture()
	local enable = self:DbGet("enableFrameTexture")
	local texture = BUFTarget.container.FrameTexture
	local healthBarMask = BUFTarget.healthBarContainer.HealthBarMask
	local manaBarMask = BUFTarget.manaBar.ManaBarMask
	if enable then
		BUFTarget:Unhook(texture, "Show")
		BUFTarget:Unhook(healthBarMask, "Show")
		BUFTarget:Unhook(manaBarMask, "Show")
		texture:Show()
		healthBarMask:Show()
		manaBarMask:Show()
	else
		texture:Hide()
		healthBarMask:Hide()
		manaBarMask:Hide()

		if not BUFTarget:IsHooked(texture, "Show") then
			BUFTarget:SecureHook(texture, "Show", function(s)
				s:Hide()
			end)
		end

		if not BUFTarget:IsHooked(healthBarMask, "Show") then
			BUFTarget:SecureHook(healthBarMask, "Show", function(s)
				s:Hide()
			end)
		end

		if not BUFTarget:IsHooked(manaBarMask, "Show") then
			BUFTarget:SecureHook(manaBarMask, "Show", function(s)
				s:Hide()
			end)
		end
	end
end

function BUFTargetFrame:RefreshBackgroundTexture()
	local useBackgroundTexture = self:DbGet("useBackgroundTexture")
	local useBackdropBorder = self:DbGet("useBackdropBorder")

	if not useBackgroundTexture and not useBackdropBorder then
		if self.backdropFrame then
			self.backdropFrame:Hide()
		end
		return
	end

	if not self.backdropFrame then
		self.backdropFrame = CreateFrame("Frame", nil, BUFTarget.frame, "BackdropTemplate")
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
	self.backdropFrame:SetPoint("TOPLEFT", BUFTarget.frame, "TOPLEFT", backdropInsetLeft, -backdropInsetTop)
	self.backdropFrame:SetPoint("BOTTOMRIGHT", BUFTarget.frame, "BOTTOMRIGHT", -backdropInsetRight, backdropInsetBottom)

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
