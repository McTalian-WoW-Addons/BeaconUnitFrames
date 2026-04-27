---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.Power
local BUFPlayerPower = BUFPlayer.Power

---@class BUFPlayer.Power.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.player.powerBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFPlayerPower.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Player.Power.Background
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

---@class BUFDbSchema.UF.Player.Power
ns.dbDefaults.profile.unitFrames.player.powerBar = ns.dbDefaults.profile.unitFrames.player.powerBar
ns.dbDefaults.profile.unitFrames.player.powerBar.background = backgroundHandler.dbDefaults

ns.options.args.player.args.powerBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		self:InitBackground(BUFPlayer.manaBar)
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	if self.background then
		self.background:SetTexture("Interface/Buttons/WHITE8x8")
	end
end

BUFPlayerPower.backgroundHandler = backgroundHandler
