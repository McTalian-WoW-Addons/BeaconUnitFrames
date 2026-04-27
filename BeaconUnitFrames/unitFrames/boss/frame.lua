---@class BUFNamespace
local ns = select(2, ...)

---@class BUFBoss
local BUFBoss = ns.BUFBoss

---@class BUFBoss.Frame: Demoable, Sizable, BackgroundTexturable
local BUFBossFrame = {
	configPath = "unitFrames.boss.frame",
	frameKey = BUFBoss.relativeToFrames.FRAME,
}

ns.Mixin(BUFBossFrame, ns.Demoable, ns.Sizable, ns.BackgroundTexturable)

BUFBoss.Frame = BUFBossFrame

---@class BUFDbSchema.UF.Boss
ns.dbDefaults.profile.unitFrames.boss = ns.dbDefaults.profile.unitFrames.boss

---@class BUFDbSchema.UF.Boss.Frame
ns.dbDefaults.profile.unitFrames.boss.frame = {
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
	handler = BUFBossFrame,
	name = ns.L["Frame"],
	order = BUFBoss.optionsOrder.FRAME,
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

ns.AddDemoOptions(frame.args, frameOrder)
ns.AddSizableOptions(frame.args, frameOrder)
ns.AddBackgroundTextureOptions(frame.args, frameOrder)

ns.options.args.boss.args.frame = frame

function BUFBossFrame:SetEnableFrameFlash(info, value)
	self:DbSet("enableFrameFlash", value)
	self:SetFrameFlash()
end

function BUFBossFrame:GetEnableFrameFlash(info)
	return self:DbGet("enableFrameFlash")
end

function BUFBossFrame:SetEnableFrameTexture(info, value)
	self:DbSet("enableFrameTexture", value)
	self:SetFrameTexture()
end

function BUFBossFrame:GetEnableFrameTexture(info)
	return self:DbGet("enableFrameTexture")
end

function BUFBossFrame:ToggleDemoMode()
	self:_ToggleDemoMode(self.frame)
	for _, bbi in ipairs(BUFBoss.frames) do
		if self.demoMode then
			bbi.frame:Show()
		else
			bbi.frame:Hide()
		end
	end
end

function BUFBossFrame:RefreshConfig()
	if not self.initialized then
		BUFBoss.FrameInit(self)

		self.frame = BossTargetFrameContainer
	end
	self:SetSize()
	self:SetFrameFlash()
	self:SetFrameTexture()
	self:RefreshBackgroundTexture()
end

function BUFBossFrame:SetSize()
	for _, bbi in ipairs(BUFBoss.frames) do
		self:_SetSize(bbi.frame)
	end
	local width = self:GetWidth()
	local height = self:GetHeight() * #BUFBoss.frames
	self.frame:SetSize(width, height)

	if self.frame.Selection then
		self.frame.Selection:ClearAllPoints()
		self.frame.Selection:SetAllPoints(self.frame)
	end
end

function BUFBossFrame:SetFrameFlash()
	local enable = self:GetEnableFrameFlash()
	if enable then
		for _, bbi in ipairs(BUFBoss.frames) do
			BUFBoss:Unhook(bbi.container.Flash, "Show")
			bbi.container.Flash:Show()
		end
	else
		for _, bbi in ipairs(BUFBoss.frames) do
			bbi.container.Flash:Hide()
			if not BUFBoss:IsHooked(bbi.container.Flash, "Show") then
				BUFBoss:SecureHook(bbi.container.Flash, "Show", function(s)
					s:Hide()
				end)
			end
		end
	end
end

function BUFBossFrame:SetFrameTexture()
	local enable = self:GetEnableFrameTexture()
	if enable then
		for _, bbi in ipairs(BUFBoss.frames) do
			BUFBoss:Unhook(bbi.container.FrameTexture, "Show")
			BUFBoss:Unhook(bbi.healthBarContainer.HealthBarMask, "Show")
			BUFBoss:Unhook(bbi.manaBar.ManaBarMask, "Show")
			bbi.container.FrameTexture:Show()
			bbi.healthBarContainer.HealthBarMask:Show()
			bbi.manaBar.ManaBarMask:Show()
		end
	else
		for _, bbi in ipairs(BUFBoss.frames) do
			bbi.container.FrameTexture:Hide()
			bbi.healthBarContainer.HealthBarMask:Hide()
			bbi.manaBar.ManaBarMask:Hide()

			if not BUFBoss:IsHooked(bbi.container.FrameTexture, "Show") then
				BUFBoss:SecureHook(bbi.container.FrameTexture, "Show", function(s)
					s:Hide()
				end)
			end

			if not BUFBoss:IsHooked(bbi.healthBarContainer.HealthBarMask, "Show") then
				BUFBoss:SecureHook(bbi.healthBarContainer.HealthBarMask, "Show", function(s)
					s:Hide()
				end)
			end

			if not BUFBoss:IsHooked(bbi.manaBar.ManaBarMask, "Show") then
				BUFBoss:SecureHook(bbi.manaBar.ManaBarMask, "Show", function(s)
					s:Hide()
				end)
			end
		end
	end
end

function BUFBossFrame:RefreshBackgroundTexture()
	local useBackgroundTexture = self:GetUseBackgroundTexture()
	local backgroundTexture = self:GetBackgroundTexture()
	local useBackdropBorder = self:GetUseBackdropBorder()
	local backdropBorderTexture = self:GetBackdropBorderTexture()
	local backdropEdgeSize = self:GetBackdropEdgeSize()
	local backdropInsetLeft = self:GetBackdropInsetLeft()
	local backdropInsetRight = self:GetBackdropInsetRight()
	local backdropInsetTop = self:GetBackdropInsetTop()
	local backdropInsetBottom = self:GetBackdropInsetBottom()

	for _, bbi in ipairs(BUFBoss.frames) do
		if not useBackgroundTexture and not useBackdropBorder then
			if bbi.backdropFrame then
				bbi.backdropFrame:Hide()
			end
		else
			if not bbi.backdropFrame then
				bbi.backdropFrame = CreateFrame("Frame", nil, bbi.frame, "BackdropTemplate")
				bbi.backdropFrame:SetFrameStrata("BACKGROUND")
			end

			local bgTexturePath = nil
			if useBackgroundTexture then
				bgTexturePath = ns.lsm:Fetch(ns.lsm.MediaType.BACKGROUND, backgroundTexture)
				if not bgTexturePath then
					bgTexturePath = "Interface/None"
				end
			end

			local borderTexturePath = nil
			if useBackdropBorder then
				borderTexturePath = ns.lsm:Fetch(ns.lsm.MediaType.BORDER, backdropBorderTexture)
				if not borderTexturePath then
					borderTexturePath = "Interface/Tooltips/UI-Tooltip-Border"
				end
			end

			bbi.backdropFrame:ClearAllPoints()
			bbi.backdropFrame:SetPoint("TOPLEFT", bbi.frame, "TOPLEFT", backdropInsetLeft, -backdropInsetTop)
			bbi.backdropFrame:SetPoint(
				"BOTTOMRIGHT",
				bbi.frame,
				"BOTTOMRIGHT",
				-backdropInsetRight,
				backdropInsetBottom
			)

			bbi.backdropFrame:SetBackdrop({
				bgFile = bgTexturePath,
				edgeFile = borderTexturePath,
				tile = true,
				tileSize = 16,
				edgeSize = useBackdropBorder and backdropEdgeSize or 0,
				insets = { left = 0, right = 0, top = 0, bottom = 0 },
			})

			if useBackdropBorder then
				local r, g, b, a = self:GetBackdropBorderColor()
				bbi.backdropFrame:SetBackdropBorderColor(r, g, b, a)
			end

			bbi.backdropFrame:Show()
		end
	end
end
