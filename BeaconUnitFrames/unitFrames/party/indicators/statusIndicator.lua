---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Indicators
local BUFPartyIndicators = ns.BUFParty.Indicators

---@class BUFParty.Indicators.StatusIndicator
---
--- Coordinator for party status indicators. Manages state resolution (which
--- highlight to show based on priority, aggro, target, mouseover) and notifies
--- child handlers (portrait/healthBar) of state changes.
---
--- This module is lightweight: it has no textures of its own. All visual/color
--- settings and rendering belong to the child handlers.
local BUFPartyStatusIndicator = {
	configPath = "unitFrames.party.statusIndicator",
}

ns.Mixin(BUFPartyStatusIndicator, ns.ProfileDbBackedHandler)

local priorityOptions = {
	AGGRO_TARGET_MOUSEOVER = ns.L["AggroTargetMouseover"],
	TARGET_AGGRO_MOUSEOVER = ns.L["TargetAggroMouseover"],
	AGGRO_MOUSEOVER_TARGET = ns.L["AggroMouseoverTarget"],
}

BUFPartyStatusIndicator.optionsTable = {
	type = "group",
	handler = BUFPartyStatusIndicator,
	name = ns.L["Status Indicator"],
	order = BUFPartyIndicators.optionsOrder.STATUS_INDICATOR,
	childGroups = "tab",
	args = {
		enabled = {
			type = "toggle",
			name = ENABLE,
			set = "SetEnabled",
			get = "GetEnabled",
			order = 1,
		},
		showAggro = {
			type = "toggle",
			name = ns.L["Show Aggro Highlight"],
			set = "SetShowAggro",
			get = "GetShowAggro",
			order = 2,
		},
		showTarget = {
			type = "toggle",
			name = ns.L["Show Target Highlight"],
			set = "SetShowTarget",
			get = "GetShowTarget",
			order = 3,
		},
		showMouseover = {
			type = "toggle",
			name = ns.L["Show Mouseover Highlight"],
			set = "SetShowMouseover",
			get = "GetShowMouseover",
			order = 4,
		},
		priority = {
			type = "select",
			name = ns.L["Highlight Priority"],
			values = priorityOptions,
			set = "SetPriority",
			get = "GetPriority",
			order = 5,
		},
		useThreatStatusColors = {
			type = "toggle",
			name = ns.L["Use Threat Status Colors"],
			set = "SetUseThreatStatusColors",
			get = "GetUseThreatStatusColors",
			order = 6,
		},
		aggroColor = {
			type = "color",
			name = ns.L["Aggro Highlight Color"],
			hasAlpha = true,
			disabled = "IsAggroColorDisabled",
			set = "SetAggroColor",
			get = "GetAggroColor",
			order = 7,
		},
		targetColor = {
			type = "color",
			name = ns.L["Target Highlight Color"],
			hasAlpha = true,
			set = "SetTargetColor",
			get = "GetTargetColor",
			order = 8,
		},
		mouseoverColor = {
			type = "color",
			name = ns.L["Mouseover Highlight Color"],
			hasAlpha = true,
			set = "SetMouseoverColor",
			get = "GetMouseoverColor",
			order = 9,
		},
	},
}

---@class BUFDbSchema.UF.Party.StatusIndicator
BUFPartyStatusIndicator.dbDefaults = {
	enabled = true,
	showAggro = true,
	showTarget = true,
	showMouseover = true,
	priority = "AGGRO_TARGET_MOUSEOVER",
	useThreatStatusColors = true,
	aggroColor = { 1, 0, 0, 0.9 },
	targetColor = { 1, 1, 1, 0.75 },
	mouseoverColor = { 1, 0.82, 0, 0.65 },
}

---@class BUFDbSchema.UF.Party
ns.dbDefaults.profile.unitFrames.party = ns.dbDefaults.profile.unitFrames.party
ns.dbDefaults.profile.unitFrames.party.statusIndicator = BUFPartyStatusIndicator.dbDefaults

ns.options.args.party.args.indicators.args.statusIndicator = BUFPartyStatusIndicator.optionsTable

local priorityOrderMap = {
	AGGRO_TARGET_MOUSEOVER = { "aggro", "target", "mouseover" },
	TARGET_AGGRO_MOUSEOVER = { "target", "aggro", "mouseover" },
	AGGRO_MOUSEOVER_TARGET = { "aggro", "mouseover", "target" },
}

local function GetPriorityOrder(self)
	local priority = self:GetPriority()
	return priorityOrderMap[priority] or priorityOrderMap.AGGRO_TARGET_MOUSEOVER
end

-- Option getters/setters --------------------------------------------------

function BUFPartyStatusIndicator:GetEnabled(info)
	return self:DbGet("enabled")
end

function BUFPartyStatusIndicator:SetEnabled(info, value)
	self:DbSet("enabled", value)
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:GetShowAggro(info)
	return self:DbGet("showAggro")
end

function BUFPartyStatusIndicator:SetShowAggro(info, value)
	self:DbSet("showAggro", value)
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:GetShowTarget(info)
	return self:DbGet("showTarget")
end

function BUFPartyStatusIndicator:SetShowTarget(info, value)
	self:DbSet("showTarget", value)
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:GetShowMouseover(info)
	return self:DbGet("showMouseover")
end

function BUFPartyStatusIndicator:SetShowMouseover(info, value)
	self:DbSet("showMouseover", value)
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:GetPriority(info)
	return self:DbGet("priority")
end

function BUFPartyStatusIndicator:SetPriority(info, value)
	self:DbSet("priority", value)
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:GetUseThreatStatusColors(info)
	return self:DbGet("useThreatStatusColors")
end

function BUFPartyStatusIndicator:SetUseThreatStatusColors(info, value)
	self:DbSet("useThreatStatusColors", value)
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:IsAggroColorDisabled(info)
	return self:GetUseThreatStatusColors()
end

function BUFPartyStatusIndicator:GetAggroColor(info)
	return unpack(self:DbGet("aggroColor"))
end

function BUFPartyStatusIndicator:SetAggroColor(info, r, g, b, a)
	self:DbSet("aggroColor", { r, g, b, a })
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:GetTargetColor(info)
	return unpack(self:DbGet("targetColor"))
end

function BUFPartyStatusIndicator:SetTargetColor(info, r, g, b, a)
	self:DbSet("targetColor", { r, g, b, a })
	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:GetMouseoverColor(info)
	return unpack(self:DbGet("mouseoverColor"))
end

function BUFPartyStatusIndicator:SetMouseoverColor(info, r, g, b, a)
	self:DbSet("mouseoverColor", { r, g, b, a })
	self:RefreshVisuals()
end

-- State resolution -------------------------------------------------------

--- Resolve what state and color should be shown for a specific party member.
--- Returns (state, r, g, b, a) where state is one of "aggro", "target", "mouseover", or nil.
function BUFPartyStatusIndicator:ResolveStateForUnit(unit)
	if not UnitExists(unit) then
		return nil
	end

	local priorityOrder = GetPriorityOrder(self)
	local showAggro = self:GetShowAggro()
	local showTarget = self:GetShowTarget()
	local showMouseover = self:GetShowMouseover()
	local useThreatStatusColors = self:GetUseThreatStatusColors()
	local aggroColor = self:DbGet("aggroColor")
	local targetColor = self:DbGet("targetColor")
	local mouseoverColor = self:DbGet("mouseoverColor")

	for _, state in ipairs(priorityOrder) do
		if state == "aggro" and showAggro then
			local threatStatus = UnitThreatSituation(unit)
			if threatStatus and threatStatus > 0 then
				local r, g, b, a
				if useThreatStatusColors then
					r, g, b = GetThreatStatusColor(threatStatus)
					a = aggroColor[4]
				else
					r, g, b, a = unpack(aggroColor)
				end
				return "aggro", r, g, b, a
			end
		elseif state == "target" and showTarget and UnitIsUnit(unit, "target") then
			return "target", unpack(targetColor)
		elseif state == "mouseover" and showMouseover and UnitIsUnit(unit, "mouseover") then
			return "mouseover", unpack(mouseoverColor)
		end
	end

	return nil
end

-- Lifecycle ---------------------------------------------------------------

function BUFPartyStatusIndicator:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		-- Wire up child handlers. Their modules populate these references after loading.
		self.Portrait = BUFPartyIndicators.PortraitStatusIndicator
		self.HealthBar = BUFPartyIndicators.HealthBarStatusIndicator
	end

	if self.Portrait then
		self.Portrait:RefreshConfig()
	end
	if self.HealthBar then
		self.HealthBar:RefreshConfig()
	end

	self:RefreshVisuals()
end

function BUFPartyStatusIndicator:RefreshVisuals()
	if self.Portrait then
		self.Portrait:RefreshVisuals()
	end
	if self.HealthBar then
		self.HealthBar:RefreshVisuals()
	end
end

BUFPartyIndicators.StatusIndicator = BUFPartyStatusIndicator
