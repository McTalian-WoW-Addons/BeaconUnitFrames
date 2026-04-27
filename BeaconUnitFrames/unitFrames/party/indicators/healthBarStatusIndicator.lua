---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Indicators
local BUFPartyIndicators = ns.BUFParty.Indicators

---@class BUFParty.Indicators.HealthBarStatusIndicator
local BUFPartyHealthBarStatusIndicator = {
	configPath = "unitFrames.party.healthBarStatusIndicator",
}

ns.Mixin(BUFPartyHealthBarStatusIndicator, ns.ProfileDbBackedHandler)

BUFPartyHealthBarStatusIndicator.optionsTable = {
	type = "group",
	handler = BUFPartyHealthBarStatusIndicator,
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
	},
}

---@class BUFDbSchema.UF.Party.HealthBarStatusIndicator
BUFPartyHealthBarStatusIndicator.dbDefaults = {
	enabled = true,
}

---@class BUFDbSchema.UF.Party
ns.dbDefaults.profile.unitFrames.party = ns.dbDefaults.profile.unitFrames.party
ns.dbDefaults.profile.unitFrames.party.healthBarStatusIndicator = BUFPartyHealthBarStatusIndicator.dbDefaults

-- Register under the parent Status Indicator group as a sibling tab to
-- portrait. Both share the parent's state resolution logic.
BUFPartyIndicators.StatusIndicator.optionsTable.args.healthBar = BUFPartyHealthBarStatusIndicator.optionsTable

-- Option getters/setters --------------------------------------------------

function BUFPartyHealthBarStatusIndicator:GetEnabled()
	return self:DbGet("enabled")
end

function BUFPartyHealthBarStatusIndicator:SetEnabled(_, v)
	self:DbSet("enabled", v)
	self:RefreshVisuals()
end

-- Implementation ----------------------------------------------------------

function BUFPartyHealthBarStatusIndicator:HideVisuals()
	self.activeState = nil
	self.currentColor = nil
	for _, bpi in ipairs(BUFParty.frames) do
		local bg = bpi.indicators
			and bpi.indicators.healthBarStatusIndicator
			and bpi.indicators.healthBarStatusIndicator.bg
		if bg then
			bg:Hide()
		end
	end
end

-- Anchor the underglow texture to match the health bar's full dimensions.
function BUFPartyHealthBarStatusIndicator:RefreshGeometry()
	for _, bpi in ipairs(BUFParty.frames) do
		local bg = bpi.indicators
			and bpi.indicators.healthBarStatusIndicator
			and bpi.indicators.healthBarStatusIndicator.bg
		if bg then
			local healthBar = bpi.frame.healthBar
			if healthBar then
				bg:ClearAllPoints()
				bg:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
				bg:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
				bg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
				bg:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
			end
		end
	end
end

-- One-time setup of the underglow texture. The underhighlight mask fades from
-- solid at the bottom to transparent at the top so the highlight reads as an
-- underglow on the health bar's bottom edge rather than a flat color slab.
-- BLEND blend so the chosen alpha controls translucency without shifting the
-- underlying bar's color.
local function CreateArt(self)
	for _, bpi in ipairs(BUFParty.frames) do
		bpi.indicators.healthBarStatusIndicator = bpi.indicators.healthBarStatusIndicator or {}

		local healthBar = bpi.frame.healthBar
		if not healthBar then
			return
		end

		-- Sit just above the health bar's status bar texture (which is on the
		-- ARTWORK layer at sublevel 0) so the underglow paints on top of the
		-- bar fill but stays below text/icons.
		local bg = healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
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

		bpi.indicators.healthBarStatusIndicator.bg = bg
		bpi.indicators.healthBarStatusIndicator.mask = mask
	end
end

function BUFPartyHealthBarStatusIndicator:RefreshConfig()
	if not self.initialized then
		self.initialized = true
		CreateArt(self)
	end

	self:RefreshGeometry()
	self:RefreshVisuals()
end

local function IsNameAvailable(bpi)
	local nameText = bpi.frame.Name
	if not nameText or not nameText:IsShown() then
		return false
	end

	local width = nameText:GetWidth() or 0
	local alpha = nameText:GetAlpha() or 0

	return width > 0 and alpha > 0
end

function BUFPartyHealthBarStatusIndicator:RefreshVisuals()
	if not self:GetEnabled() then
		self:HideVisuals()
		return
	end

	local coordinator = BUFPartyIndicators.StatusIndicator
	if not coordinator:GetEnabled() then
		self:HideVisuals()
		return
	end

	for i, bpi in ipairs(BUFParty.frames) do
		local bg = bpi.indicators
			and bpi.indicators.healthBarStatusIndicator
			and bpi.indicators.healthBarStatusIndicator.bg
		if bg then
			local unit = bpi.frame:GetUnit() or ("party" .. i)
			local state, r, g, b, a = coordinator:ResolveStateForUnit(unit)

			if state and IsNameAvailable(bpi) then
				self.activeState = state
				self.currentColor = { r, g, b, a }
				bg:SetVertexColor(r, g, b, a)
				bg:Show()
			else
				bg:Hide()
			end
		end
	end
end

BUFPartyIndicators.HealthBarStatusIndicator = BUFPartyHealthBarStatusIndicator
