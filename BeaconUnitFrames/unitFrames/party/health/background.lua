---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Health
local BUFPartyHealth = BUFParty.Health

---@class BUFParty.Health.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.party.healthBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFPartyHealth.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Party.Health.Background
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

---@class BUFDbSchema.UF.Party.Health
ns.dbDefaults.profile.unitFrames.party.healthBar = ns.dbDefaults.profile.unitFrames.party.healthBar
ns.dbDefaults.profile.unitFrames.party.healthBar.background = backgroundHandler.dbDefaults

ns.options.args.party.args.healthBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		for _, bpi in ipairs(BUFParty.frames) do
			self:InitFrameBackground(bpi.health, bpi.healthBar)
		end
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RefreshBackgroundTexture()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_RefreshBackgroundTexture(bpi.health.background)
		self:_RefreshBorderFrame(bpi.health.borderFrame)
	end
end

function backgroundHandler:RefreshColor()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_RefreshColor(bpi.health.background)
	end
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	for _, bpi in ipairs(BUFParty.frames) do
		if bpi.health.background then
			bpi.health.background:SetTexture("Interface/Buttons/WHITE8x8")
		end
	end
end

BUFPartyHealth.backgroundHandler = backgroundHandler
