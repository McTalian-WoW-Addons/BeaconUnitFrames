---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Power
local BUFPartyPower = BUFParty.Power

---@class BUFParty.Power.Background: StatusBarBackground
local backgroundHandler = {
	configPath = "unitFrames.party.powerBar.background",
}

backgroundHandler.optionsTable = {
	type = "group",
	handler = backgroundHandler,
	name = BACKGROUND,
	order = BUFPartyPower.topGroupOrder.BACKGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Party.Power.Background
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

---@class BUFDbSchema.UF.Party.Power
ns.dbDefaults.profile.unitFrames.party.powerBar = ns.dbDefaults.profile.unitFrames.party.powerBar
ns.dbDefaults.profile.unitFrames.party.powerBar.background = backgroundHandler.dbDefaults

ns.options.args.party.args.powerBar.args.background = backgroundHandler.optionsTable

function backgroundHandler:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		for _, bpi in ipairs(BUFParty.frames) do
			self:InitFrameBackground(bpi.power, bpi.manaBar)
		end
	end
	self:RefreshStatusBarBackgroundConfig()
end

function backgroundHandler:RefreshBackgroundTexture()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_RefreshBackgroundTexture(bpi.power.background)
		self:_RefreshBorderFrame(bpi.power.borderFrame)
	end
end

function backgroundHandler:RefreshColor()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_RefreshColor(bpi.power.background)
	end
end

function backgroundHandler:RestoreDefaultBackgroundTexture()
	for _, bpi in ipairs(BUFParty.frames) do
		if bpi.power.background then
			bpi.power.background:SetTexture("Interface/Buttons/WHITE8x8")
		end
	end
end

BUFPartyPower.backgroundHandler = backgroundHandler
