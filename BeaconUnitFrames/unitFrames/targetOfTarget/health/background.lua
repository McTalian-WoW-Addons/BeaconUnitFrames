---@class BUFNamespace
local ns = select(2, ...)

---@class BUFToT
local BUFToT = ns.BUFToT

---@class BUFToT.Health
local BUFToTHealth = BUFToT.Health

---@class BUFToT.Health.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.tot.healthBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFToTHealth.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.ToT.Health.Background
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

---@class BUFDbSchema.UF.ToT.Health
ns.dbDefaults.profile.unitFrames.tot.healthBar = ns.dbDefaults.profile.unitFrames.tot.healthBar
ns.dbDefaults.profile.unitFrames.tot.healthBar.background = backgroundHandler.dbDefaults

ns.options.args.tot.args.healthBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		self:InitBackground(BUFToT.healthBar)
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	if self.background then
		self.background:SetTexture("Interface/Buttons/WHITE8x8")
	end
end

BUFToTHealth.backgroundHandler = backgroundHandler
