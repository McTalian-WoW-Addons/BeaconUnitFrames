---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.Indicators
local BUFPlayerIndicators = ns.BUFPlayer.Indicators

---@class BUFPlayer.Indicators.PortraitStatusIndicator
local BUFPlayerPortraitStatusIndicator = {
	configPath = "unitFrames.player.portraitStatusIndicator",
}

ns.Mixin(BUFPlayerPortraitStatusIndicator, ns.ProfileDbBackedHandler)

BUFPlayerPortraitStatusIndicator.optionsTable = {
	type = "group",
	handler = BUFPlayerPortraitStatusIndicator,
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
		pulse = {
			type = "toggle",
			name = ns.L["Pulse Animation"],
			desc = ns.L["PulseAnimationDesc"],
			set = "SetPulse",
			get = "GetPulse",
			order = 3,
		},
		showCombat = {
			type = "toggle",
			name = ns.L["Show Combat Highlight"],
			set = "SetShowCombat",
			get = "GetShowCombat",
			order = 4,
		},
		combatColor = {
			type = "color",
			name = ns.L["Combat Highlight Color"],
			hasAlpha = true,
			set = "SetCombatColor",
			get = "GetCombatColor",
			order = 5,
		},
		showResting = {
			type = "toggle",
			name = ns.L["Show Resting Highlight"],
			set = "SetShowResting",
			get = "GetShowResting",
			order = 6,
		},
		restingColor = {
			type = "color",
			name = ns.L["Resting Highlight Color"],
			hasAlpha = true,
			set = "SetRestingColor",
			get = "GetRestingColor",
			order = 7,
		},
	},
}

---@class BUFDbSchema.UF.Player.PortraitStatusIndicator
BUFPlayerPortraitStatusIndicator.dbDefaults = {
	enabled = true,
	thickness = 12,
	pulse = false,
	showCombat = true,
	showResting = true,
	combatColor = { 1, 0, 0, 0.9 },
	restingColor = { 1, 0.88, 0.25, 0.85 },
}

---@class BUFDbSchema.UF.Player
ns.dbDefaults.profile.unitFrames.player = ns.dbDefaults.profile.unitFrames.player
ns.dbDefaults.profile.unitFrames.player.portraitStatusIndicator = BUFPlayerPortraitStatusIndicator.dbDefaults

-- Register as a subgroup under the parent Status Indicator. The parent
-- module owns the pulse driver and the top-level options group; this
-- module just contributes its tab.
BUFPlayerIndicators.StatusIndicator.optionsTable.args.portrait = BUFPlayerPortraitStatusIndicator.optionsTable

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

-- Option getters/setters --------------------------------------------------

function BUFPlayerPortraitStatusIndicator:GetEnabled()
	return self:DbGet("enabled")
end
function BUFPlayerPortraitStatusIndicator:SetEnabled(_, v)
	self:DbSet("enabled", v)
	self:RefreshAll()
end

function BUFPlayerPortraitStatusIndicator:GetStyle()
	return self:DbGet("style")
end
function BUFPlayerPortraitStatusIndicator:SetStyle(_, v)
	self:DbSet("style", v)
	self:RefreshAll()
end

function BUFPlayerPortraitStatusIndicator:GetThickness()
	return self:DbGet("thickness")
end
function BUFPlayerPortraitStatusIndicator:SetThickness(_, v)
	self:DbSet("thickness", v)
	self:RefreshGeometry()
	self:RefreshVisuals()
end

function BUFPlayerPortraitStatusIndicator:GetPulse()
	return self:DbGet("pulse")
end
function BUFPlayerPortraitStatusIndicator:SetPulse(_, v)
	self:DbSet("pulse", v)
	self:RefreshVisuals()
	-- Notify the coordinator so it can start/stop the pulse driver as needed.
	-- Only do this if the coordinator is already initialized to avoid issues during setup.
	if BUFPlayerIndicators.StatusIndicator.initialized then
		BUFPlayerIndicators.StatusIndicator:UpdatePulseState()
	end
end

function BUFPlayerPortraitStatusIndicator:GetShowCombat()
	return self:DbGet("showCombat")
end
function BUFPlayerPortraitStatusIndicator:SetShowCombat(_, v)
	self:DbSet("showCombat", v)
	self:RefreshVisuals()
end

function BUFPlayerPortraitStatusIndicator:GetShowResting()
	return self:DbGet("showResting")
end
function BUFPlayerPortraitStatusIndicator:SetShowResting(_, v)
	self:DbSet("showResting", v)
	self:RefreshVisuals()
end

function BUFPlayerPortraitStatusIndicator:GetCombatColor()
	return unpack(self:DbGet("combatColor"))
end
function BUFPlayerPortraitStatusIndicator:SetCombatColor(_, r, g, b, a)
	self:DbSet("combatColor", { r, g, b, a })
	self:RefreshVisuals()
end

function BUFPlayerPortraitStatusIndicator:GetRestingColor()
	return unpack(self:DbGet("restingColor"))
end
function BUFPlayerPortraitStatusIndicator:SetRestingColor(_, r, g, b, a)
	self:DbSet("restingColor", { r, g, b, a })
	self:RefreshVisuals()
end

-- Implementation ----------------------------------------------------------

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

function BUFPlayerPortraitStatusIndicator:HideVisuals()
	self.activeState = nil
	self.currentColor = nil
	if self.glow then
		self.glow:Hide()
	end
end

-- Anchor the glow texture so it extends `thickness` pixels past the portrait
-- on every side. Anchoring relative to the portrait texture lets us track
-- any user resize/reposition for free.
function BUFPlayerPortraitStatusIndicator:RefreshGeometry()
	if not self.glow then
		return
	end
	local t = self:GetThickness() or 0
	local portrait = BUFPlayer.container.PlayerPortrait
	self.glow:ClearAllPoints()
	self.glow:SetPoint("TOPLEFT", portrait, "TOPLEFT", -t, t)
	self.glow:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", t, -t)
end

-- One-time setup of the glow texture. Two masks are stacked so their alphas
-- multiply:
--   1. radial_glow.png  -> provides the soft falloff (transparent center,
--      bright rim, transparent corners)
--   2. portrait shape   -> clips the result to the portrait silhouette so
--      the halo follows whatever mask the user picked (circle, hex, etc.)
-- ADD blend so the resulting colored alpha brightens whatever sits behind
-- the portrait rather than slabbing solid color over it.
local function CreateArt(self)
	local portrait = BUFPlayer.container.PlayerPortrait
	local parent = portrait:GetParent()

	-- BACKGROUND draw layer keeps the glow behind the portrait (which sits
	-- on ARTWORK by default), so only the rim radiates past the portrait
	-- silhouette.
	local glow = parent:CreateTexture("BUFPlayer_PortraitStatusGlow", "BACKGROUND", nil, 7)
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
	-- is also clipped to the portrait silhouette. Its texture is set lazily
	-- in RefreshShapeMask whenever the portrait mask changes.
	local shapeMask = parent:CreateMaskTexture(nil, "BACKGROUND")
	shapeMask:SetAllPoints(glow)
	glow:AddMaskTexture(shapeMask)

	self.glow = glow
	self.glowMask = glowMask
	self.shapeMask = shapeMask
end

-- Mirror the portrait's current mask shape onto the secondary mask so the
-- glow is clipped to the same silhouette (circle, hex, diamond, etc.).
function BUFPlayerPortraitStatusIndicator:RefreshShapeMask()
	if not self.shapeMask then
		return
	end
	local maskPath = BUFPlayer.Portrait and BUFPlayer.Portrait:GetMask() or nil
	SetMaskAsset(self.shapeMask, maskPath)
end

function BUFPlayerPortraitStatusIndicator:RefreshAll()
	if not self.glow then
		return
	end
	self:RefreshShapeMask()
	self:RefreshGeometry()
	self:RefreshVisuals()
end

function BUFPlayerPortraitStatusIndicator:RefreshConfig()
	if not self.initialized then
		self.initialized = true
		CreateArt(self)

		-- PlayerFrame_UpdateStatus is called via the global, so hooksecurefunc
		-- propagates correctly.
		hooksecurefunc("PlayerFrame_UpdateStatus", function()
			BUFPlayerPortraitStatusIndicator:RefreshVisuals()
		end)

		-- The parent StatusIndicator owns the pulse driver and broadcasts the
		-- current pulse alpha to every subscriber, so portrait + name pulse
		-- in phase. We just register and react.
		BUFPlayerIndicators.StatusIndicator:Subscribe(self)

		-- Follow the portrait's mask shape changes so the halo stays clipped
		-- to whatever silhouette the user picked.
		if not BUFPlayer:IsHooked(BUFPlayer.Portrait, "RefreshMask") then
			BUFPlayer:SecureHook(BUFPlayer.Portrait, "RefreshMask", function()
				BUFPlayerPortraitStatusIndicator:RefreshShapeMask()
			end)
		end
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

function BUFPlayerPortraitStatusIndicator:RefreshVisuals()
	if not self.glow then
		return
	end

	if not self:GetEnabled() then
		self:HideVisuals()
		return
	end

	-- If the user disabled the portrait entirely, there's no edge to glow off.
	if BUFPlayer.Portrait and not BUFPlayer.Portrait:GetEnabled() then
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

	self.glow:SetVertexColor(r, g, b, a)
	self.glow:Show()

	-- The parent driver continues to tick; we just reset alpha here so a
	-- non-pulsing indicator stays at full alpha.
	self.glow:SetAlpha(1)
end

-- Called every frame by the parent StatusIndicator with the shared pulse
-- alpha. We only apply it when this indicator's pulse toggle is on AND it
-- is currently active; otherwise we hold full alpha.
function BUFPlayerPortraitStatusIndicator:OnPulse(pulseAlpha)
	if not self.glow or not self.activeState then
		return
	end
	if not self:GetPulse() then
		return
	end
	self.glow:SetAlpha(pulseAlpha)
end

BUFPlayerIndicators.PortraitStatusIndicator = BUFPlayerPortraitStatusIndicator
BUFPlayerIndicators.StatusIndicator.Portrait = BUFPlayerPortraitStatusIndicator
