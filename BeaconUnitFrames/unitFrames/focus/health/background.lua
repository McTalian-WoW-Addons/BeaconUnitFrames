---@class BUFNamespace
local ns = select(2, ...)

---@class BUFFocus
local BUFFocus = ns.BUFFocus

---@class BUFFocus.Health
local BUFFocusHealth = BUFFocus.Health

---@class BUFFocus.Health.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.focus.healthBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFFocusHealth.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Focus.Health.Background
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

---@class BUFDbSchema.UF.Focus.Health
ns.dbDefaults.profile.unitFrames.focus.healthBar = ns.dbDefaults.profile.unitFrames.focus.healthBar
ns.dbDefaults.profile.unitFrames.focus.healthBar.background = backgroundHandler.dbDefaults

ns.options.args.focus.args.healthBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		-- Same secure-sizing nuance as target: healthBarContainer is managed by
		-- attribute scripts, so anchor to healthBar to match what BUF actually sizes.
		self:InitBackground(BUFFocus.healthBar)
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	if self.background then
		self.background:SetTexture("Interface/Buttons/WHITE8x8")
	end
end

BUFFocusHealth.backgroundHandler = backgroundHandler
