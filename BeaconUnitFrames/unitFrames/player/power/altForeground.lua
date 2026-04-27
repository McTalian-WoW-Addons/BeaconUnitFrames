---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.AltPower
local BUFPlayerAltPower = BUFPlayer.AltPower

---@class BUFPlayer.AltPower.Foreground: StatusBarForeground
local foregroundHandler = {
	configPath = "unitFrames.player.altPowerBar.foreground",
}

foregroundHandler.optionsTable = {
	type = "group",
	handler = foregroundHandler,
	name = ns.L["Foreground"],
	order = BUFPlayerAltPower.topGroupOrder.FOREGROUND,
	args = {},
}

---@class BUFDbSchema.UF.Player.AltPower.Foreground
foregroundHandler.dbDefaults = {
	useStatusBarTexture = false,
	statusBarTexture = "Blizzard",
	useCustomColor = false,
	customColor = { 0, 0, 1, 1 },
	usePowerColor = false,
}

BUFPlayerAltPower.foregroundHandler = foregroundHandler

ns.StatusBarForeground:ApplyMixin(foregroundHandler, false, false, true)

---@class BUFDbSchema.UF.Player.AltPower
ns.dbDefaults.profile.unitFrames.player.altPowerBar = ns.dbDefaults.profile.unitFrames.player.altPowerBar

ns.dbDefaults.profile.unitFrames.player.altPowerBar.foreground = foregroundHandler.dbDefaults

ns.options.args.player.args.altPowerBar.args.foreground = foregroundHandler.optionsTable

function foregroundHandler:RefreshConfig()
	local altPowerBar = PlayerFrame_GetAlternatePowerBar()
	if not altPowerBar then
		return
	end

	if not self.initialized then
		self.initialized = true
	end

	self.unit = "player"
	self.statusBar = altPowerBar

	self:RefreshStatusBarForegroundConfig()
end

function foregroundHandler:RefreshStatusBarTexture()
	if not self.statusBar then
		return
	end

	if self:GetUseStatusBarTexture() then
		self:_RefreshStatusBarTexture(self.statusBar)
		return
	end

	if self.statusBar.UpdateArt then
		self.statusBar:UpdateArt()
	end
end
