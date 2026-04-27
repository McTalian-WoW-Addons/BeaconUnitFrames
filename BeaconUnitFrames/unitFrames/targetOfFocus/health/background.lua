---@class BUFNamespace
local ns = select(2, ...)

---@class BUFToFocus
local BUFToFocus = ns.BUFToFocus

---@class BUFToFocus.Health
local BUFToFocusHealth = BUFToFocus.Health

---@class BUFToFocus.Health.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.tofocus.healthBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFToFocusHealth.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.ToFocus.Health.Background
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

---@class BUFDbSchema.UF.ToFocus.Health
ns.dbDefaults.profile.unitFrames.tofocus.healthBar = ns.dbDefaults.profile.unitFrames.tofocus.healthBar
ns.dbDefaults.profile.unitFrames.tofocus.healthBar.background = backgroundHandler.dbDefaults

ns.options.args.tofocus.args.healthBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		self:InitBackground(BUFToFocus.healthBar)
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	if self.background then
		self.background:SetTexture("Interface/Buttons/WHITE8x8")
	end
end

BUFToFocusHealth.backgroundHandler = backgroundHandler
