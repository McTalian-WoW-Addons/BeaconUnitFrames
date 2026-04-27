---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

--- The alternate power bar (AlternatePowerBar) is a 3rd bar shown for certain specs
--- that have both a primary class resource AND a secondary Mana resource (e.g.
--- Balance Druid: primary = Astral Power, secondary = Mana shown here).
--- PlayerFrame.activeAlternatePowerBar is nil when the current spec has no secondary power.

---@class BUFPlayer.AltPower: BUFStatusBar
local BUFPlayerAltPower = {
	configPath = "unitFrames.player.altPowerBar",
	frameKey = BUFPlayer.relativeToFrames.POWER,
}

BUFPlayerAltPower.optionsTable = {
	type = "group",
	handler = BUFPlayerAltPower,
	name = ns.L["PlayerAltPowerBar"],
	order = BUFPlayer.optionsOrder.ALT_POWER,
	childGroups = "tree",
	args = {},
}

---@class BUFDbSchema.UF.Player.AltPower
BUFPlayerAltPower.dbDefaults = {
	width = 124,
	height = 9,
	anchorPoint = "TOPLEFT",
	relativeTo = BUFPlayer.relativeToFrames.FRAME,
	relativePoint = "TOPLEFT",
	xOffset = 85,
	yOffset = -73,
	frameLevel = 3,
}

ns.BUFStatusBar:ApplyMixin(BUFPlayerAltPower)

BUFPlayer.AltPower = BUFPlayerAltPower

---@class BUFDbSchema.UF.Player
ns.dbDefaults.profile.unitFrames.player = ns.dbDefaults.profile.unitFrames.player

ns.dbDefaults.profile.unitFrames.player.altPowerBar = BUFPlayerAltPower.dbDefaults

ns.options.args.player.args.altPowerBar = BUFPlayerAltPower.optionsTable

local altPowerBarOrder = {}

ns.Mixin(altPowerBarOrder, ns.defaultOrderMap)
altPowerBarOrder.FOREGROUND = altPowerBarOrder.FRAME_LEVEL + 0.1
altPowerBarOrder.BACKGROUND = altPowerBarOrder.FOREGROUND + 0.1

BUFPlayerAltPower.topGroupOrder = altPowerBarOrder

function BUFPlayerAltPower:RefreshConfig()
	if not self.initialized then
		BUFPlayer.FrameInit(self)
	end

	local altPowerBar = PlayerFrame_GetAlternatePowerBar()
	if not altPowerBar then
		-- This spec has no secondary power bar; nothing to configure.
		return
	end

	-- Blizzard does not reposition/resize the alt power bar during vehicle transitions,
	-- so we do not need buf_restore_size/position attributes — just guard combat lockdown.
	if InCombatLockdown() then
		return
	end

	self.barOrContainer = altPowerBar
	self:RefreshStatusBarConfig()
end
