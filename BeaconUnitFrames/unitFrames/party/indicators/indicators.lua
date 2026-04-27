---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Indicators: BUFParentHandler
local BUFPartyIndicators = {}

BUFPartyIndicators.optionsOrder = {
	STATUS_INDICATOR = 1,
	RESURRECTABLE_INDICATOR = 2,
	DISCONNECT_ICON = 3,
	READY_CHECK_INDICATOR = 4,
	ROLE_ICON = 5,
	LEADER_AND_GUIDE_ICON = 6,
	PVP_ICON = 7,
	NOT_PRESENT_ICON = 8,
}

local indicators = {
	type = "group",
	name = ns.L["Indicators and Icons"],
	order = BUFParty.optionsOrder.INDICATORS,
	childGroups = "tree",
	args = {},
}

ns.options.args.party.args.indicators = indicators

function BUFPartyIndicators:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		for _, bpi in ipairs(BUFParty.frames) do
			bpi.indicators = {}
		end
	end
	self.StatusIndicator:RefreshConfig()
	-- ResurrectableIndicator:RefreshConfig()
	-- DisconnectIcon:RefreshConfig()
	-- ReadyCheckIndicator:RefreshConfig()
	self.RoleIcon:RefreshConfig()
	-- LeaderAndGuideIcon:RefreshConfig()
	-- PvpIcon:RefreshConfig()
	-- NotPresentIcon:RefreshConfig()
end

BUFParty.Indicators = BUFPartyIndicators
