---@class BUFNamespace
local ns = select(2, ...)

---@class BUFFocus
local BUFFocus = ns.BUFFocus

---@class BUFFocus.Power
local BUFFocusPower = BUFFocus.Power

---@class BUFFocus.Power.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.focus.powerBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFFocusPower.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Focus.Power.Background
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

---@class BUFDbSchema.UF.Focus.Power
ns.dbDefaults.profile.unitFrames.focus.powerBar = ns.dbDefaults.profile.unitFrames.focus.powerBar
ns.dbDefaults.profile.unitFrames.focus.powerBar.background = backgroundHandler.dbDefaults

ns.options.args.focus.args.powerBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		self:InitBackground(BUFFocus.manaBar)
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	if self.background then
		self.background:SetTexture("Interface/Buttons/WHITE8x8")
	end
end

BUFFocusPower.backgroundHandler = backgroundHandler
