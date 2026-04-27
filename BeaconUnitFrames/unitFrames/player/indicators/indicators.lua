---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.Indicators: BUFParentHandler
local BUFPlayerIndicators = {}

BUFPlayerIndicators.optionsOrder = {
	GROUP_INDICATOR = 1,
	REST_INDICATOR = 2,
	STATUS_INDICATOR = 3,
	ATTACK_ICON = 4,
	READY_CHECK_INDICATOR = 5,
	ROLE_ICON = 6,
	LEADER_AND_GUIDE_ICON = 7,
	PVP_ICON = 8,
	PRESTIGE = 9,
	HIT_INDICATOR = 10,
	PLAY_TIME = 11,
}

local indicators = {
	type = "group",
	name = ns.L["Indicators and Icons"],
	order = BUFPlayer.optionsOrder.INDICATORS,
	childGroups = "tree",
	args = {},
}

ns.options.args.player.args.indicators = indicators

function BUFPlayerIndicators:RefreshConfig()
	self.AttackIcon:RefreshConfig()
	self.GroupIndicator:RefreshConfig()
	self.LeaderAndGuideIcon:RefreshConfig()
	self.PlayTime:RefreshConfig()
	self.PrestigePortrait:RefreshConfig()
	self.PvPIcon:RefreshConfig()
	self.ReadyCheckIndicator:RefreshConfig()
	self.RestIndicator:RefreshConfig()
	-- Parent StatusIndicator owns the shared pulse driver and refreshes
	-- both the Portrait and Name child indicators in turn.
	self.StatusIndicator:RefreshConfig()
	self.RoleIcon:RefreshConfig()
	self.HitIndicator:RefreshConfig()
end

BUFPlayer.Indicators = BUFPlayerIndicators
