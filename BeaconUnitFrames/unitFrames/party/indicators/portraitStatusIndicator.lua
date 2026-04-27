---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Indicators
local BUFPartyIndicators = ns.BUFParty.Indicators

---@class BUFParty.Indicators.PortraitStatusIndicator
local BUFPartyPortraitStatusIndicator = {
	configPath = "unitFrames.party.portraitStatusIndicator",
}

ns.Mixin(BUFPartyPortraitStatusIndicator, ns.ProfileDbBackedHandler)

BUFPartyPortraitStatusIndicator.optionsTable = {
	type = "group",
	handler = BUFPartyPortraitStatusIndicator,
	name = ns.L["Portrait"],
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = ENABLE,
			set = "SetEnabled",
			get = "GetEnabled",
			order = ns.defaultOrderMap.ENABLE,
		},
		thickness = {
			type = "range",
			name = ns.L["Glow Size"],
			desc = ns.L["GlowSizeDesc"],
			min = 1,
			max = 32,
			step = 1,
			set = "SetThickness",
			get = "GetThickness",
			order = 2,
		},
	},
}

---@class BUFDbSchema.UF.Party.PortraitStatusIndicator
BUFPartyPortraitStatusIndicator.dbDefaults = {
	enabled = true,
	thickness = 8,
}

---@class BUFDbSchema.UF.Party
ns.dbDefaults.profile.unitFrames.party = ns.dbDefaults.profile.unitFrames.party
ns.dbDefaults.profile.unitFrames.party.portraitStatusIndicator = BUFPartyPortraitStatusIndicator.dbDefaults

-- Register as a subgroup under the parent Status Indicator. The parent
-- module owns the state resolution logic; this module just contributes its tab.
BUFPartyIndicators.StatusIndicator.optionsTable.args.portrait = BUFPartyPortraitStatusIndicator.optionsTable

local function SetMaskAsset(maskTexture, path)
	if not path or path == "" then
		return
	end
	-- Atlases have no file extension; texture paths contain a dot.
	if string.find(path, "%.") then
		maskTexture:SetTexture(path)
	else
		maskTexture:SetAtlas(path, false)
	end
end

-- Option getters/setters --------------------------------------------------

function BUFPartyPortraitStatusIndicator:GetEnabled()
	return self:DbGet("enabled")
end

function BUFPartyPortraitStatusIndicator:SetEnabled(_, v)
	self:DbSet("enabled", v)
	self:RefreshVisuals()
end

function BUFPartyPortraitStatusIndicator:GetThickness()
	return self:DbGet("thickness")
end

function BUFPartyPortraitStatusIndicator:SetThickness(_, v)
	self:DbSet("thickness", v)
	self:RefreshGeometry()
	self:RefreshVisuals()
end

-- Implementation ----------------------------------------------------------

function BUFPartyPortraitStatusIndicator:HideVisuals()
	self.activeState = nil
	self.currentColor = nil
	for _, bpi in ipairs(BUFParty.frames) do
		local glow = bpi.indicators
			and bpi.indicators.portraitStatusIndicator
			and bpi.indicators.portraitStatusIndicator.glow
		if glow then
			glow:Hide()
		end
	end
end

-- Anchor the glow texture so it extends `thickness` pixels past the portrait
-- on every side. Anchoring relative to the portrait texture lets us track
-- any user resize/reposition for free.
function BUFPartyPortraitStatusIndicator:RefreshGeometry()
	local t = self:GetThickness() or 0

	for _, bpi in ipairs(BUFParty.frames) do
		local glow = bpi.indicators
			and bpi.indicators.portraitStatusIndicator
			and bpi.indicators.portraitStatusIndicator.glow
		if glow then
			local portrait = bpi.frame.Portrait
			glow:ClearAllPoints()
			glow:SetPoint("TOPLEFT", portrait, "TOPLEFT", -t, t)
			glow:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", t, -t)
		end
	end
end

-- One-time setup of the glow texture. Two masks are stacked so their alphas
-- multiply:
--   1. radial_glow.png  -> provides the soft falloff (transparent center,
--      bright rim, transparent corners)
--   2. portrait shape   -> clips the result to the portrait silhouette
-- ADD blend so the resulting colored alpha brightens whatever sits behind
-- the portrait rather than slabbing solid color over it.
local function CreateArt(self)
	for _, bpi in ipairs(BUFParty.frames) do
		bpi.indicators.portraitStatusIndicator = bpi.indicators.portraitStatusIndicator or {}

		local portrait = bpi.frame.Portrait
		local parent = portrait:GetParent()

		-- BACKGROUND draw layer keeps the glow behind the portrait (which sits
		-- on ARTWORK by default), so only the rim radiates past the portrait
		-- silhouette.
		local glow = parent:CreateTexture(nil, "BACKGROUND", nil, 7)
		glow:SetTexture("Interface/Buttons/WHITE8X8")
		glow:SetBlendMode("ADD")
		glow:Hide()

		-- Mask 1: the bundled radial_glow.png provides the falloff.
		local glowMask = parent:CreateMaskTexture(nil, "BACKGROUND")
		glowMask:SetTexture(
			"Interface/AddOns/BeaconUnitFrames/icons/radial_glow.png",
			"CLAMPTOBLACKADDITIVE",
			"CLAMPTOBLACKADDITIVE"
		)
		glowMask:SetAllPoints(glow)
		glow:AddMaskTexture(glowMask)

		-- Mask 2: portrait shape. Multiplied with the radial mask so the halo
		-- is also clipped to the portrait silhouette.
		local shapeMask = parent:CreateMaskTexture(nil, "BACKGROUND")
		shapeMask:SetAllPoints(glow)
		glow:AddMaskTexture(shapeMask)

		bpi.indicators.portraitStatusIndicator.glow = glow
		bpi.indicators.portraitStatusIndicator.glowMask = glowMask
		bpi.indicators.portraitStatusIndicator.shapeMask = shapeMask
	end
end

-- Mirror the portrait's current mask shape onto the secondary mask so the
-- glow is clipped to the same silhouette (circle, hex, diamond, etc.).
function BUFPartyPortraitStatusIndicator:RefreshShapeMask()
	for _, bpi in ipairs(BUFParty.frames) do
		local shapeMask = bpi.indicators
			and bpi.indicators.portraitStatusIndicator
			and bpi.indicators.portraitStatusIndicator.shapeMask
		if shapeMask then
			local maskPath = BUFParty.Portrait and BUFParty.Portrait:GetMask() or nil
			SetMaskAsset(shapeMask, maskPath)
		end
	end
end

function BUFPartyPortraitStatusIndicator:RefreshConfig()
	if not self.initialized then
		self.initialized = true
		CreateArt(self)
	end

	self:RefreshShapeMask()
	self:RefreshGeometry()
	self:RefreshVisuals()
end

local function IsPortraitAvailable(bpi)
	local portrait = bpi.frame.Portrait
	if not portrait or not portrait:IsShown() then
		return false
	end

	if not BUFParty.Portrait:GetEnabled() then
		return false
	end

	local width = portrait:GetWidth() or 0
	local height = portrait:GetHeight() or 0
	local alpha = portrait:GetAlpha() or 0

	return width > 0 and height > 0 and alpha > 0
end

function BUFPartyPortraitStatusIndicator:RefreshVisuals()
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
		local glow = bpi.indicators
			and bpi.indicators.portraitStatusIndicator
			and bpi.indicators.portraitStatusIndicator.glow
		if glow then
			local unit = bpi.frame:GetUnit() or ("party" .. i)
			local state, r, g, b, a = coordinator:ResolveStateForUnit(unit)

			if state and IsPortraitAvailable(bpi) then
				self.activeState = state
				self.currentColor = { r, g, b, a }
				glow:SetVertexColor(r, g, b, a)
				glow:Show()
			else
				glow:Hide()
			end
		end
	end
end

BUFPartyIndicators.PortraitStatusIndicator = BUFPartyPortraitStatusIndicator
