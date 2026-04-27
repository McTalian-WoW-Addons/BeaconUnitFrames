---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.AltPower
local BUFPlayerAltPower = BUFPlayer.AltPower

---@class BUFPlayer.AltPower.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.player.altPowerBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFPlayerAltPower.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Player.AltPower.Background
backgroundHandler.dbDefaults = {
	useBackgroundTexture = false,
	backgroundTexture = "None",
	useBackdropBorder = false,
	backdropBorderTexture = "None",
	backdropEdgeSize = 16,
	backdropBorderColor = { 1, 1, 1, 1 },
	backdropInsetLeft = 0,
	backdropInsetRight = 0,
	backdropInsetTop = 0,
	backdropInsetBottom = 0,
	customColor = { 0, 0, 0, 0 },
}

ns.StatusBarBackground:ApplyMixin(backgroundHandler)

---@class BUFDbSchema.UF.Player.AltPower
ns.dbDefaults.profile.unitFrames.player.altPowerBar = ns.dbDefaults.profile.unitFrames.player.altPowerBar
ns.dbDefaults.profile.unitFrames.player.altPowerBar.background = backgroundHandler.dbDefaults

ns.options.args.player.args.altPowerBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	local altPowerBar = PlayerFrame_GetAlternatePowerBar()
	if not altPowerBar then
		return
	end

	if not self.initialized then
		self.initialized = true

		self:InitBackground(altPowerBar)
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	if self.background then
		self.background:SetTexture("Interface/Buttons/WHITE8x8")
	end
end

BUFPlayerAltPower.backgroundHandler = backgroundHandler
