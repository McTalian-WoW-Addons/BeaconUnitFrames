---@class BUFNamespace
local ns = select(2, ...)

--- Add status bar foreground options to the given options table
--- @param optionsTable table
--- @param _orderMap? BUFOptionsOrder
--- @param handler? StatusBarForeground
function ns.AddStatusBarForegroundOptions(optionsTable, _orderMap, handler)
	local orderMap = _orderMap or ns.defaultOrderMap
	ns.AddColorOptions(optionsTable, orderMap)
	ns.AddStatusBarTextureOptions(optionsTable, orderMap)

	if handler then
		if handler.classColorable then
			ns.AddClassColorOptions(optionsTable, orderMap)
		end
		if handler.reactionColorable then
			ns.AddReactionColorOptions(optionsTable, orderMap)
		end
		if handler.powerColorable then
			ns.AddPowerColorOptions(optionsTable, orderMap)
		end
	end
end

---@class StatusBarForegroundHandler
---@field unit string
---@field statusBar StatusBar
---@field defaultStatusBarTexture? string
---@field RefreshColor fun(self: StatusBarForeground)
---@field RefreshStatusBarTexture fun(self: StatusBarForeground)

---@class StatusBarForeground: StatusBarForegroundHandler, Colorable, ClassColorable, ReactionColorable, PowerColorable, StatusBarTexturable
local StatusBarForeground = {}

--- Apply mixins to a StatusBarForeground
--- @param self StatusBarForeground
--- @param handler BUFConfigHandler
--- @param classColorable? boolean Whether to apply ClassColorable mixin
--- @param reactionColorable? boolean Whether to apply ReactionColorable mixin
--- @param powerColorable? boolean Whether to apply PowerColorable mixin
function StatusBarForeground:ApplyMixin(handler, classColorable, reactionColorable, powerColorable)
	ns.Mixin(handler, ns.Colorable, ns.StatusBarTexturable)
	if classColorable then
		self.classColorable = true
		ns.Mixin(handler, ns.ClassColorable)
	else
		self.classColorable = false
	end
	if reactionColorable then
		self.reactionColorable = true
		ns.Mixin(handler, ns.ReactionColorable)
	else
		self.reactionColorable = false
	end
	if powerColorable then
		self.powerColorable = true
		ns.Mixin(handler, ns.PowerColorable)
	else
		self.powerColorable = false
	end
	ns.Mixin(handler, self)

	---@type StatusBarForeground
	handler = handler --[[@as StatusBarForeground]]

	if handler.optionsTable then
		ns.AddStatusBarForegroundOptions(handler.optionsTable.args, handler.optionsOrder, handler)
	end
end

function StatusBarForeground:RefreshStatusBarForegroundConfig()
	self:RefreshStatusBarTexture()
	self:RefreshColor()
end

function StatusBarForeground:_RefreshStatusBarTexture(statusBar)
	local useCustomTexture = self:GetUseStatusBarTexture()
	if useCustomTexture then
		local textureName = self:GetStatusBarTexture() or "Blizzard"
		local texturePath = ns.lsm:Fetch(ns.lsm.MediaType.STATUSBAR, textureName)
		if not texturePath then
			texturePath = ns.lsm:Fetch(ns.lsm.MediaType.STATUSBAR, "Blizzard") or "Interface\\Buttons\\WHITE8x8"
		end
		statusBar:SetStatusBarTexture(texturePath)
	else
		if self.defaultStatusBarTexture then
			statusBar:SetStatusBarTexture(self.defaultStatusBarTexture)
		end
	end
end

function StatusBarForeground:RefreshStatusBarTexture()
	self:_RefreshStatusBarTexture(self.statusBar)
end

function StatusBarForeground:_GetEffectiveUnit(unit)
	local trackedUnit = unit
	if UnitInVehicle("player") then
		if unit == "player" then
			trackedUnit = "vehicle"
		elseif unit == "pet" then
			trackedUnit = "player"
		end
	end
	return trackedUnit
end

function StatusBarForeground:_GetOptionsBasedColor(unit)
	local useClassColor = self.classColorable and self:GetUseClassColor()
	local useReactionColor = self.reactionColorable and self:GetUseReactionColor()
	local usePowerColor = self.powerColorable and self:GetUsePowerColor()
	local useCustomColor = self:GetUseCustomColor()

	local trackedUnit = self:_GetEffectiveUnit(unit)
	local r, g, b, a = nil, nil, nil, 1
	if useCustomColor then
		r, g, b, a = self:GetCustomColor()
	elseif useClassColor and (not useReactionColor or UnitPlayerControlled(unit)) then
		-- nil when the unit's identity is secret, which falls through to the reaction color
		r, g, b = ns.GetUnitClassColor(trackedUnit)
	end

	if r == nil and useReactionColor then
		r, g, b = ns.GetUnitReactionColor(trackedUnit)
	elseif r == nil and usePowerColor then
		if trackedUnit == nil or not UnitExists(trackedUnit) then
			return
		end
		local powerType, powerToken, rX, gY, bZ = UnitPowerType(trackedUnit)
		local info = PowerBarColor[powerToken]
		if info then
			r, g, b = info.r, info.g, info.b
		elseif not rX then
			local info = PowerBarColor[powerType]
			if info then
				r, g, b = info.r, info.g, info.b
			end
		else
			r, g, b = rX, gY, bZ
		end
	end

	return r, g, b, a
end

---@param statusBar StatusBar
---@param unit string
function StatusBarForeground:_RefreshColor(statusBar, unit)
	local r, g, b, a = self:_GetOptionsBasedColor(unit)
	a = a or 1.0
	if not r or not g or not b then
		return
	end
	statusBar:SetStatusBarColor(r, g, b, a)
end

function StatusBarForeground:RefreshColor()
	self:_RefreshColor(self.statusBar, self.unit)
end

ns.StatusBarForeground = StatusBarForeground
