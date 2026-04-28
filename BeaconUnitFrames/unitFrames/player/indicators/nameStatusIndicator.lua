---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.Indicators
local BUFPlayerIndicators = ns.BUFPlayer.Indicators

---@class BUFPlayer.Indicators.NameStatusIndicator
local BUFPlayerNameStatusIndicator = {
	configPath = "unitFrames.player.nameStatusIndicator",
}

ns.Mixin(BUFPlayerNameStatusIndicator, ns.ProfileDbBackedHandler)

BUFPlayerNameStatusIndicator.optionsTable = {
	type = "group",
	handler = BUFPlayerNameStatusIndicator,
	name = ns.L["Health Bar"],
	order = 2,
	args = {
		enabled = {
			type = "toggle",
			name = ENABLE,
			set = "SetEnabled",
			get = "GetEnabled",
			order = ns.defaultOrderMap.ENABLE,
		},
		pulse = {
			type = "toggle",
			name = ns.L["Pulse Animation"],
			desc = ns.L["PulseAnimationDesc"],
			set = "SetPulse",
			get = "GetPulse",
			order = 4,
		},
		showCombat = {
			type = "toggle",
			name = ns.L["Show Combat Highlight"],
			set = "SetShowCombat",
			get = "GetShowCombat",
			order = 5,
		},
		combatColor = {
			type = "color",
			name = ns.L["Combat Highlight Color"],
			hasAlpha = true,
			set = "SetCombatColor",
			get = "GetCombatColor",
			order = 6,
		},
		showResting = {
			type = "toggle",
			name = ns.L["Show Resting Highlight"],
			set = "SetShowResting",
			get = "GetShowResting",
			order = 7,
		},
		restingColor = {
			type = "color",
			name = ns.L["Resting Highlight Color"],
			hasAlpha = true,
			set = "SetRestingColor",
			get = "GetRestingColor",
			order = 8,
		},
	},
}

---@class BUFDbSchema.UF.Player.NameStatusIndicator
BUFPlayerNameStatusIndicator.dbDefaults = {
	enabled = true,
	pulse = false,
	showCombat = true,
	showResting = true,
	combatColor = { 1, 0, 0, 0.5 },
	restingColor = { 1, 0.88, 0.25, 0.45 },
}

---@class BUFDbSchema.UF.Player
ns.dbDefaults.profile.unitFrames.player = ns.dbDefaults.profile.unitFrames.player
ns.dbDefaults.profile.unitFrames.player.nameStatusIndicator = BUFPlayerNameStatusIndicator.dbDefaults

-- Register under the parent Status Indicator group as a sibling tab to
-- portrait. Both share the parent's pulse driver.
BUFPlayerIndicators.StatusIndicator.optionsTable.args.name = BUFPlayerNameStatusIndicator.optionsTable

local function NormalizeColor(color, fallback)
	fallback = fallback or { 1, 1, 1, 1 }
	if type(color) ~= "table" then
		return fallback[1], fallback[2], fallback[3], fallback[4]
	end
	local r = color[1] or fallback[1]
	local g = color[2] or fallback[2]
	local b = color[3] or fallback[3]
	local a = color[4]
	if a == nil or a <= 0 then
		a = fallback[4]
	end
	return r, g, b, a
end

function BUFPlayerNameStatusIndicator:GetEnabled()
	return self:DbGet("enabled")
end
function BUFPlayerNameStatusIndicator:SetEnabled(_, v)
	self:DbSet("enabled", v)
	self:RefreshAll()
end

function BUFPlayerNameStatusIndicator:GetPulse()
	return self:DbGet("pulse")
end
function BUFPlayerNameStatusIndicator:SetPulse(_, v)
	self:DbSet("pulse", v)
	self:RefreshVisuals()
	-- Notify the coordinator so it can start/stop the pulse driver as needed.
	-- Only do this if the coordinator is already initialized to avoid issues during setup.
	if BUFPlayerIndicators.StatusIndicator.initialized then
		BUFPlayerIndicators.StatusIndicator:UpdatePulseState()
	end
end

function BUFPlayerNameStatusIndicator:GetShowCombat()
	return self:DbGet("showCombat")
end
function BUFPlayerNameStatusIndicator:SetShowCombat(_, v)
	self:DbSet("showCombat", v)
	self:RefreshVisuals()
end

function BUFPlayerNameStatusIndicator:GetShowResting()
	return self:DbGet("showResting")
end
function BUFPlayerNameStatusIndicator:SetShowResting(_, v)
	self:DbSet("showResting", v)
	self:RefreshVisuals()
end

function BUFPlayerNameStatusIndicator:GetCombatColor()
	return unpack(self:DbGet("combatColor"))
end
function BUFPlayerNameStatusIndicator:SetCombatColor(_, r, g, b, a)
	self:DbSet("combatColor", { r, g, b, a })
	self:RefreshVisuals()
end

function BUFPlayerNameStatusIndicator:GetRestingColor()
	return unpack(self:DbGet("restingColor"))
end
function BUFPlayerNameStatusIndicator:SetRestingColor(_, r, g, b, a)
	self:DbSet("restingColor", { r, g, b, a })
	self:RefreshVisuals()
end

function BUFPlayerNameStatusIndicator:HideVisuals()
	self.activeState = nil
	self.currentColor = nil
	if self.bg then
		self.bg:Hide()
	end
end

function BUFPlayerNameStatusIndicator:RefreshGeometry()
	if not self.bg then
		return
	end
	-- Bottom-aligned to the health bar, matching its full width and height.
	-- The underhighlight mask handles the visual: solid at the bottom edge
	-- of the bar, fading toward the top.
	local healthBar = BUFPlayer.healthBar
	self.bg:ClearAllPoints()
	self.bg:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
	self.bg:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
	self.bg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
	self.bg:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
end

local function CreateArt(self)
	local healthBar = BUFPlayer.healthBar

	-- Sit just above the health bar's status bar texture (which is on the
	-- ARTWORK layer at sublevel 0) so the underglow paints on top of the
	-- bar fill but stays below text/icons.
	local bg = healthBar:CreateTexture("BUFPlayer_HealthBarStatusGlow", "ARTWORK", nil, 1)
	bg:SetTexture("Interface/Buttons/WHITE8X8")
	-- BLEND so the chosen alpha controls translucency. ADD on a colored
	-- health bar would shift the bar color too aggressively.
	bg:SetBlendMode("BLEND")
	bg:Hide()

	-- The bundled underhighlight mask fades from solid at the bottom to
	-- transparent at the top so the highlight reads as an underglow on the
	-- health bar's bottom edge rather than a flat color slab.
	local mask = healthBar:CreateMaskTexture(nil, "ARTWORK")
	mask:SetTexture(
		"Interface/AddOns/BeaconUnitFrames/icons/underhighlight_mask.png",
		"CLAMPTOBLACKADDITIVE",
		"CLAMPTOBLACKADDITIVE"
	)
	mask:SetAllPoints(bg)
	bg:AddMaskTexture(mask)

	self.bg = bg
	self.mask = mask
end

function BUFPlayerNameStatusIndicator:RefreshAll()
	if not self.bg then
		return
	end
	self:RefreshGeometry()
	self:RefreshVisuals()
end

function BUFPlayerNameStatusIndicator:RefreshConfig()
	if not self.initialized then
		self.initialized = true
		CreateArt(self)

		hooksecurefunc("PlayerFrame_UpdateStatus", function()
			BUFPlayerNameStatusIndicator:RefreshVisuals()
		end)

		-- Subscribe to the parent StatusIndicator's pulse driver so portrait
		-- and name pulse in phase.
		BUFPlayerIndicators.StatusIndicator:Subscribe(self)
	end

	self:RefreshAll()
end

local function ResolveStateAndColor(self)
	if IsResting() and self:GetShowResting() then
		return "resting", self:DbGet("restingColor"), self.dbDefaults.restingColor
	end
	-- inCombat is set by PLAYER_ENTER_COMBAT (melee auto-attack); onHateList is
	-- set by PLAYER_REGEN_DISABLED (the broader "entered combat" state). Check
	-- both so the indicator appears whenever the player is in any form of combat.
	if BUFPlayer.frame and (BUFPlayer.frame.inCombat or BUFPlayer.frame.onHateList) and self:GetShowCombat() then
		return "combat", self:DbGet("combatColor"), self.dbDefaults.combatColor
	end
	return nil, nil, nil
end

function BUFPlayerNameStatusIndicator:RefreshVisuals()
	if not self.bg then
		return
	end

	if not self:GetEnabled() then
		self:HideVisuals()
		return
	end

	if BUFPlayer.Name and BUFPlayer.Name.GetEnabled and not BUFPlayer.Name:GetEnabled() then
		self:HideVisuals()
		return
	end

	local state, color, fallback = ResolveStateAndColor(self)
	if not state then
		self:HideVisuals()
		return
	end

	local r, g, b, a = NormalizeColor(color, fallback)
	self.activeState = state
	self.currentColor = { r, g, b, a }

	self.bg:SetVertexColor(r, g, b, a)
	self.bg:Show()

	self.bg:SetAlpha(1)
end

-- Called by the parent StatusIndicator each frame with the shared pulse
-- alpha. Only applied when this indicator's pulse toggle is on.
function BUFPlayerNameStatusIndicator:OnPulse(pulseAlpha)
	if not self.bg or not self.activeState then
		return
	end
	if not self:GetPulse() then
		return
	end
	self.bg:SetAlpha(pulseAlpha)
end

BUFPlayerIndicators.NameStatusIndicator = BUFPlayerNameStatusIndicator
BUFPlayerIndicators.StatusIndicator.Name = BUFPlayerNameStatusIndicator
