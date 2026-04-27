---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.Frame: Sizable, BackgroundTexturable
local BUFPlayerFrame = {
	configPath = "unitFrames.player.frame",
	frameKey = BUFPlayer.relativeToFrames.FRAME,
}

ns.Mixin(BUFPlayerFrame, ns.Sizable, ns.BackgroundTexturable)

BUFPlayer.Frame = BUFPlayerFrame

---@class BUFDbSchema.UF.Player
ns.dbDefaults.profile.unitFrames.player = ns.dbDefaults.profile.unitFrames.player

---@class BUFDbSchema.UF.Player.Frame
ns.dbDefaults.profile.unitFrames.player.frame = {
	width = 232,
	height = 100,
	enableFrameFlash = true,
	enableFrameTexture = true,
	enableStatusTexture = true,
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
frameOrder.STATUS_TEXTURE = frameOrder.FRAME_TEXTURE + 0.1

local frame = {
	type = "group",
	handler = BUFPlayerFrame,
	name = ns.L["Frame"],
	order = BUFPlayer.optionsOrder.FRAME,
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
		statusTexture = {
			type = "toggle",
			name = ns.L["EnableStatusTexture"],
			set = "SetEnableStatusTexture",
			get = "GetEnableStatusTexture",
			order = frameOrder.STATUS_TEXTURE,
		},
	},
}

ns.AddBackgroundTextureOptions(frame.args, frameOrder)
ns.AddSizableOptions(frame.args, frameOrder)

ns.options.args.player.args.frame = frame

function BUFPlayerFrame:SetEnableFrameFlash(info, value)
	self:DbSet("enableFrameFlash", value)
	BUFPlayerFrame:SetFrameFlash()
end

function BUFPlayerFrame:GetEnableFrameFlash(info)
	return self:DbGet("enableFrameFlash")
end

function BUFPlayerFrame:SetEnableFrameTexture(info, value)
	self:DbSet("enableFrameTexture", value)
	BUFPlayerFrame:SetFrameTexture()
end

function BUFPlayerFrame:GetEnableFrameTexture(info)
	return self:DbGet("enableFrameTexture")
end

function BUFPlayerFrame:SetEnableStatusTexture(info, value)
	self:DbSet("enableStatusTexture", value)
	BUFPlayerFrame:SetStatusTexture()
end

function BUFPlayerFrame:GetEnableStatusTexture(info)
	return self:DbGet("enableStatusTexture")
end

function BUFPlayerFrame:RefreshConfig()
	if not self.initialized then
		BUFPlayer.FrameInit(self)

		self.frame = BUFPlayer.frame

		local player = BUFPlayer

		if not player:IsHooked(player.container.FrameTexture, "SetShown") then
			player:SecureHook(player.container.FrameTexture, "SetShown", function(s, shown)
				if not self:GetEnableFrameTexture() then
					s:Hide()
				end
			end)
		end

		if not player:IsHooked(player.frame, "AnchorSelectionFrame") then
			player:SecureHook(player.frame, "AnchorSelectionFrame", function()
				if player.frame.Selection then
					player.frame.Selection:ClearAllPoints()
					player.frame.Selection:SetAllPoints(player.frame)
				end
			end)
		end
	end
	self:SetSize()
	self:SetFrameFlash()
	self:SetFrameTexture()
	self:SetStatusTexture()
	self:RefreshBackgroundTexture()
end

function BUFPlayerFrame:SetSize()
	self:_SetSize(self.frame)
	self.frame:SetHitRectInsets(0, 0, 0, 0)
end

function BUFPlayerFrame:SetFrameFlash()
	local player = BUFPlayer
	local enable = self:DbGet("enableFrameFlash")
	if enable then
		player:Unhook(player.container.FrameFlash, "Show")
	else
		player.container.FrameFlash:Hide()
		if not ns.BUFPlayer:IsHooked(player.container.FrameFlash, "Show") then
			player:SecureHook(player.container.FrameFlash, "Show", function(s)
				s:Hide()
			end)
		end
	end
end

function BUFPlayerFrame:SetFrameTexture()
	local enable = self:DbGet("enableFrameTexture")
	local texture = BUFPlayer.container.FrameTexture
	local vehicleTexture = BUFPlayer.container.VehicleFrameTexture
	local alternatePowerTexture = BUFPlayer.container.AlternatePowerFrameTexture
	local healthBarMask = BUFPlayer.healthBarContainer.HealthBarMask
	local manaBarMask = BUFPlayer.manaBar.ManaBarMask
	local altPowerBar = PlayerFrame_GetAlternatePowerBar()
	local altPowerBarMask = altPowerBar and altPowerBar.PowerBarMask or nil

	if enable then
		BUFPlayer:Unhook(texture, "Show")
		BUFPlayer:Unhook(vehicleTexture, "Show")
		BUFPlayer:Unhook(alternatePowerTexture, "Show")
		BUFPlayer:Unhook(healthBarMask, "Show")
		BUFPlayer:Unhook(manaBarMask, "Show")
		if altPowerBarMask then
			BUFPlayer:Unhook(altPowerBarMask, "Show")
		end
		if UnitInVehicle("player") then
			vehicleTexture:Show()
			texture:Hide()
			alternatePowerTexture:Hide()
		elseif PlayerFrame_GetAlternatePowerBar() ~= nil then
			alternatePowerTexture:Show()
			texture:Hide()
			vehicleTexture:Hide()
		else
			texture:Show()
			vehicleTexture:Hide()
			alternatePowerTexture:Hide()
		end
		healthBarMask:Show()
		manaBarMask:Show()
		if altPowerBarMask then
			altPowerBarMask:Show()
		end
	else
		texture:Hide()
		vehicleTexture:Hide()
		alternatePowerTexture:Hide()
		healthBarMask:Hide()
		manaBarMask:Hide()
		if altPowerBarMask then
			altPowerBarMask:Hide()
		end

		local function HideOnShow(s)
			s:Hide()
		end

		if not BUFPlayer:IsHooked(texture, "Show") then
			BUFPlayer:SecureHook(texture, "Show", HideOnShow)
		end

		if not BUFPlayer:IsHooked(vehicleTexture, "Show") then
			BUFPlayer:SecureHook(vehicleTexture, "Show", HideOnShow)
		end

		if not BUFPlayer:IsHooked(alternatePowerTexture, "Show") then
			BUFPlayer:SecureHook(alternatePowerTexture, "Show", HideOnShow)
		end

		if not BUFPlayer:IsHooked(alternatePowerTexture, "SetShown") then
			BUFPlayer:SecureHook(alternatePowerTexture, "SetShown", HideOnShow)
		end

		if not BUFPlayer:IsHooked(healthBarMask, "Show") then
			BUFPlayer:SecureHook(healthBarMask, "Show", HideOnShow)
		end

		if not BUFPlayer:IsHooked(manaBarMask, "Show") then
			BUFPlayer:SecureHook(manaBarMask, "Show", HideOnShow)
		end

		if not BUFPlayer:IsHooked(manaBarMask, "SetShown") then
			BUFPlayer:SecureHook(manaBarMask, "SetShown", HideOnShow)
		end

		if altPowerBarMask and not BUFPlayer:IsHooked(altPowerBarMask, "Show") then
			BUFPlayer:SecureHook(altPowerBarMask, "Show", HideOnShow)
		end

		if altPowerBarMask and not BUFPlayer:IsHooked(altPowerBarMask, "SetShown") then
			BUFPlayer:SecureHook(altPowerBarMask, "SetShown", HideOnShow)
		end
	end
end

function BUFPlayerFrame:SetStatusTexture()
	local player = BUFPlayer
	local enable = self:DbGet("enableStatusTexture")
	if enable then
		player:Unhook(player.contentMain.StatusTexture, "Show")
	else
		player.contentMain.StatusTexture:Hide()
		if not ns.BUFPlayer:IsHooked(player.contentMain.StatusTexture, "Show") then
			player:SecureHook(player.contentMain.StatusTexture, "Show", function(s)
				s:Hide()
			end)
		end
	end
end

function BUFPlayerFrame:RefreshBackgroundTexture()
	local useBackgroundTexture = self:DbGet("useBackgroundTexture")
	local useBackdropBorder = self:DbGet("useBackdropBorder")

	if not useBackgroundTexture and not useBackdropBorder then
		if self.backdropFrame then
			self.backdropFrame:Hide()
		end
		return
	end

	if self.backdropFrame == nil then
		self.backdropFrame = CreateFrame("Frame", nil, ns.BUFPlayer.frame, "BackdropTemplate")
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
	self.backdropFrame:SetPoint("TOPLEFT", ns.BUFPlayer.frame, "TOPLEFT", backdropInsetLeft, -backdropInsetTop)
	self.backdropFrame:SetPoint(
		"BOTTOMRIGHT",
		ns.BUFPlayer.frame,
		"BOTTOMRIGHT",
		-backdropInsetRight,
		backdropInsetBottom
	)

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
