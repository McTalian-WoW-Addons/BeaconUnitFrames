---@class BUFNamespace
local ns = select(2, ...)

---@class BUFToT
local BUFToT = ns.BUFToT

---@class BUFToT.Frame: Sizable, BackgroundTexturable, FramePositionable
local BUFToTFrame = {
	configPath = "unitFrames.tot.frame",
	frameKey = BUFToT.relativeToFrames.FRAME,
}

ns.Mixin(BUFToTFrame, ns.Sizable, ns.BackgroundTexturable, ns.FramePositionable)

BUFToT.Frame = BUFToTFrame

---@class BUFDbSchema.UF.ToT
ns.dbDefaults.profile.unitFrames.tot = ns.dbDefaults.profile.unitFrames.tot

---@class BUFDbSchema.UF.ToT.Frame
ns.dbDefaults.profile.unitFrames.tot.frame = {
	width = 120,
	height = 49,
	enableFrameTexture = true,
	useBackgroundTexture = false,
	backgroundTexture = "None",
	enablePositionOverride = false,
	anchorPoint = "TOPLEFT",
	relativeTo = ns.Positionable.relativeToFrames.UI_PARENT,
	relativePoint = "TOPLEFT",
	xOffset = 0,
	yOffset = 0,
	frameStrata = "MEDIUM",
	frameLevel = 0,
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
	handler = BUFToTFrame,
	name = ns.L["Frame"],
	order = BUFToT.optionsOrder.FRAME,
	args = {
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
ns.AddFramePositionableOptions(frame.args, frameOrder)

ns.options.args.tot.args.frame = frame

function BUFToTFrame:SetEnableFrameTexture(info, value)
	self:DbSet("enableFrameTexture", value)
	self:SetFrameTexture()
end

function BUFToTFrame:GetEnableFrameTexture(info)
	return self:DbGet("enableFrameTexture")
end

function BUFToTFrame:RefreshConfig()
	if not self.initialized then
		BUFToT.FrameInit(self)
		self.framePositionRelativeToOptions = {
			[ns.Positionable.relativeToFrames.UI_PARENT] = ns.L["UIParent"],
			[ns.Positionable.relativeToFrames.TARGET_FRAME] = HUD_EDIT_MODE_TARGET_FRAME_LABEL,
			[ns.Positionable.relativeToFrames.PLAYER_FRAME] = HUD_EDIT_MODE_PLAYER_FRAME_LABEL,
			[ns.Positionable.relativeToFrames.FOCUS_FRAME] = HUD_EDIT_MODE_FOCUS_FRAME_LABEL,
			[ns.Positionable.relativeToFrames.PET_FRAME] = HUD_EDIT_MODE_PET_FRAME_LABEL,
		}
		self.framePositionRelativeToSorting = {
			ns.Positionable.relativeToFrames.UI_PARENT,
			ns.Positionable.relativeToFrames.TARGET_FRAME,
			ns.Positionable.relativeToFrames.PLAYER_FRAME,
			ns.Positionable.relativeToFrames.FOCUS_FRAME,
			ns.Positionable.relativeToFrames.PET_FRAME,
		}
	end
	if not self.frame then
		self.frame = BUFToT.frame
	end
	if self.frame and self.frame.AnchorSelectionFrame then
		if not BUFToT:IsHooked(self.frame, "AnchorSelectionFrame") then
			BUFToT:SecureHook(self.frame, "AnchorSelectionFrame", function()
				if self.frame.Selection then
					self.frame.Selection:ClearAllPoints()
					self.frame.Selection:SetAllPoints(self.frame)
				end
			end)
		end
	end
	self:SetSize()
	self:SetFrameTexture()
	self:RefreshBackgroundTexture()
	self:ApplyFramePosition()
end

function BUFToTFrame:SetSize()
	self:_SetSize(self.frame)
end

function BUFToTFrame:SetFrameTexture()
	local enable = self:DbGet("enableFrameTexture")
	local texture = BUFToT.frame.FrameTexture
	local healthBarMask = BUFToT.healthBar.HealthBarMask
	local manaBarMask = BUFToT.manaBar.ManaBarMask
	if enable then
		BUFToT:Unhook(texture, "Show")
		BUFToT:Unhook(healthBarMask, "Show")
		BUFToT:Unhook(manaBarMask, "Show")
		texture:Show()
		healthBarMask:Show()
		manaBarMask:Show()
	else
		texture:Hide()
		healthBarMask:Hide()
		manaBarMask:Hide()

		if not BUFToT:IsHooked(texture, "Show") then
			BUFToT:SecureHook(texture, "Show", function(s)
				s:Hide()
			end)
		end

		if not BUFToT:IsHooked(healthBarMask, "Show") then
			BUFToT:SecureHook(healthBarMask, "Show", function(s)
				s:Hide()
			end)
		end

		if not BUFToT:IsHooked(manaBarMask, "Show") then
			BUFToT:SecureHook(manaBarMask, "Show", function(s)
				s:Hide()
			end)
		end
	end
end

function BUFToTFrame:RefreshBackgroundTexture()
	local useBackgroundTexture = self:DbGet("useBackgroundTexture")
	local useBackdropBorder = self:DbGet("useBackdropBorder")

	if not useBackgroundTexture and not useBackdropBorder then
		if self.backdropFrame then
			self.backdropFrame:Hide()
		end
		return
	end

	if not self.backdropFrame then
		self.backdropFrame = CreateFrame("Frame", nil, BUFToT.frame, "BackdropTemplate")
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
	self.backdropFrame:SetPoint("TOPLEFT", BUFToT.frame, "TOPLEFT", backdropInsetLeft, -backdropInsetTop)
	self.backdropFrame:SetPoint("BOTTOMRIGHT", BUFToT.frame, "BOTTOMRIGHT", -backdropInsetRight, backdropInsetBottom)

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

function BUFToTFrame:ApplyFramePosition()
	if not self:GetEnablePositionOverride() then
		return
	end
	self:_ApplyFramePosition(self.frame)
end

function BUFToTFrame:ResetFramePosition()
	-- Blizzard repositions TargetOfTarget on updates; unhooking our override
	-- and forcing a frame update lets the default layout reassert itself.
	if self.frame and self.frame.Update then
		self.frame:Update()
	end
end
