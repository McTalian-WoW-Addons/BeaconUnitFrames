---@class BUFNamespace
local ns = select(2, ...)

---@class BUFBoss
local BUFBoss = ns.BUFBoss

---@class BUFBoss.Health
local BUFBossHealth = BUFBoss.Health

---@class BUFBoss.Health.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.boss.healthBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFBossHealth.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Boss.Health.Background
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

---@class BUFDbSchema.UF.Boss.Health
ns.dbDefaults.profile.unitFrames.boss.healthBar = ns.dbDefaults.profile.unitFrames.boss.healthBar
ns.dbDefaults.profile.unitFrames.boss.healthBar.background = backgroundHandler.dbDefaults

ns.options.args.boss.args.healthBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		for _, bbi in ipairs(BUFBoss.frames) do
			self:InitFrameBackground(bbi.health, bbi.healthBar)
		end
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RefreshBackgroundTexture()
	for _, bbi in ipairs(BUFBoss.frames) do
		self:_RefreshBackgroundTexture(bbi.health.background)
		self:_RefreshBorderFrame(bbi.health.borderFrame)
	end
end

function backgroundHandler:RefreshColor()
	for _, bbi in ipairs(BUFBoss.frames) do
		self:_RefreshColor(bbi.health.background)
	end
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	for _, bbi in ipairs(BUFBoss.frames) do
		if bbi.health.background then
			bbi.health.background:SetTexture("Interface/Buttons/WHITE8x8")
		end
	end
end

BUFBossHealth.backgroundHandler = backgroundHandler
