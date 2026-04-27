---@class BUFNamespace
local ns = select(2, ...)

---@class BUFFocus: BUFFeatureModule
local BUFFocus = ns.NewFeatureModule("BUFFocus")

BUFFocus.configPath = "unitFrames.focus"

BUFFocus.relativeToFrames = {
	FRAME = ns.Positionable.relativeToFrames.FOCUS_FRAME,
	PORTRAIT = ns.Positionable.relativeToFrames.FOCUS_PORTRAIT,
	REPUTATION_BAR = ns.Positionable.relativeToFrames.FOCUS_REPUTATION_BAR,
	NAME = ns.Positionable.relativeToFrames.FOCUS_NAME,
	LEVEL = ns.Positionable.relativeToFrames.FOCUS_LEVEL,
	HEALTH = ns.Positionable.relativeToFrames.FOCUS_HEALTH_BAR,
	POWER = ns.Positionable.relativeToFrames.FOCUS_POWER_BAR,
}

BUFFocus.customRelativeToOptions = {
	[ns.Positionable.relativeToFrames.UI_PARENT] = ns.L["UIParent"],
	[BUFFocus.relativeToFrames.FRAME] = HUD_EDIT_MODE_FOCUS_FRAME_LABEL,
	[BUFFocus.relativeToFrames.REPUTATION_BAR] = ns.L["FocusReputationBar"],
	[BUFFocus.relativeToFrames.PORTRAIT] = ns.L["FocusPortrait"],
	[BUFFocus.relativeToFrames.NAME] = ns.L["FocusName"],
	[BUFFocus.relativeToFrames.LEVEL] = ns.L["FocusLevel"],
	[BUFFocus.relativeToFrames.HEALTH] = ns.L["FocusHealthBar"],
	[BUFFocus.relativeToFrames.POWER] = ns.L["FocusManaBar"],
}

BUFFocus.customRelativeToSorting = {
	ns.Positionable.relativeToFrames.UI_PARENT,
	BUFFocus.relativeToFrames.FRAME,
	BUFFocus.relativeToFrames.REPUTATION_BAR,
	BUFFocus.relativeToFrames.PORTRAIT,
	BUFFocus.relativeToFrames.NAME,
	BUFFocus.relativeToFrames.LEVEL,
	BUFFocus.relativeToFrames.HEALTH,
	BUFFocus.relativeToFrames.POWER,
}

BUFFocus.optionsTable = {
	type = "group",
	name = HUD_EDIT_MODE_FOCUS_FRAME_LABEL,
	handler = BUFFocus,
	order = ns.BUFUnitFrames.optionsOrder.FOCUS,
	childGroups = "tree",
	disabled = BUFFocus.IsDisabled,
	args = {
		title = {
			type = "header",
			name = HUD_EDIT_MODE_FOCUS_FRAME_LABEL,
			order = 0.001,
		},
		enable = {
			type = "toggle",
			name = ENABLE,
			set = "SetEnabled",
			disabled = false,
			get = "GetEnabled",
			order = 0.01,
		},
	},
}

---@class BUFDbSchema.UF.Focus
BUFFocus.dbDefaults = {
	enabled = true,
}

---@class BUFDbSchema.UF
ns.dbDefaults.profile.unitFrames = ns.dbDefaults.profile.unitFrames
ns.dbDefaults.profile.unitFrames.focus = BUFFocus.dbDefaults

ns.options.args.focus = BUFFocus.optionsTable

BUFFocus.optionsOrder = {
	FRAME = 1,
	PORTRAIT = 2,
	REPUTATION_BAR = 3,
	NAME = 4,
	LEVEL = 5,
	INDICATORS = 6,
	HEALTH = 7,
	POWER = 8,
	CAST_BAR = 9,
	BUFFS = 10,
}

function BUFFocus.IsDisabled()
	return not BUFFocus:DbGet("enabled")
end

function BUFFocus:SetEnabled(info, value)
	self:DbSet("enabled", value)
	if value then
		self:RefreshConfig()
	else
		StaticPopup_Show("BUF_RELOAD_UI")
	end
end

function BUFFocus:GetEnabled(info)
	return self:DbGet("enabled")
end

function BUFFocus:OnEnable()
	self.frame = FocusFrame
	self.container = self.frame.TargetFrameContainer
	self.content = self.frame.TargetFrameContent
	self.contentMain = self.content.TargetFrameContentMain
	self.contentContextual = self.content.TargetFrameContentContextual
	self.healthBarContainer = self.contentMain.HealthBarsContainer
	self.healthBar = self.healthBarContainer.HealthBar
	self.manaBar = self.contentMain.ManaBar
	self.altPowerBar = self.frame.powerBarAlt
end

function BUFFocus:RefreshConfig()
	if not self:GetEnabled() then
		return
	end
	if not self.initialized then
		local ClassificationCheckUpdater = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")
		Mixin(ClassificationCheckUpdater, ns.BUFSecureHandler)

		-- healthBarsContainer gets moved during CheckClassification
		-- if we don't anchor anything to it, we can avoid having to reapply our position/size changes
		-- leaving this in here in case there ever turns out to be a reliable secure trigger
		ClassificationCheckUpdater:SecureSetFrameRef("FocusHealthBarContainer", self.healthBarContainer)
		ClassificationCheckUpdater:SecureSetFrameRef("FocusHealthBar", self.healthBar)
		ClassificationCheckUpdater:SecureSetFrameRef("FocusManaBar", self.manaBar)

		ns.FocusClassificationCheckUpdater = ClassificationCheckUpdater
	end
	self.Frame:RefreshConfig()
	self.Portrait:RefreshConfig()
	self.Name:RefreshConfig()
	self.Level:RefreshConfig()
	self.Indicators:RefreshConfig()
	self.Health:RefreshConfig()
	self.Power:RefreshConfig()
	self.ReputationBar:RefreshConfig()
	self.Buffs:RefreshConfig()
	self.CastBar:RefreshConfig()

	if not self.initialized then
		self.initialized = true

		self:SecureHook(self.frame, "Update", function()
			-- Be careful in here, if you do anything insecure, it could cause lua errors during combat
			self.Health.foregroundHandler:RefreshConfig()
			self.Power.foregroundHandler:RefreshConfig()
		end)

		self:SecureHook("UnitFrameManaBar_UpdateType", function(manaBar)
			if manaBar == self.manaBar then
				self.Power.foregroundHandler:RefreshConfig()
				self.Health.foregroundHandler:RefreshConfig()
			end
		end)

		-- We won't end up actually triggering anything but keeping the code here
		-- in case something changes in the future.
		local ClassificationCheckUpdater = ns.FocusClassificationCheckUpdater

		ClassificationCheckUpdater:SetAttribute(
			"buf_restore_size_position",
			[[
            FocusHealthBarContainer:RunAttribute("buf_restore_size")
            -- FocusHealthBar:RunAttribute("buf_restore_size")
            -- FocusManaBar:RunAttribute("buf_restore_size")
            
            -- FocusHealthBarContainer:RunAttribute("buf_restore_position")
            -- FocusManaBar:RunAttribute("buf_restore_position")
        ]]
		)

		ClassificationCheckUpdater:SetAttribute(
			"_onattributechanged",
			[[
            self:RunAttribute("buf_restore_size_position")
            if name == "manual" then
                return
            end
        ]]
		)

		-- I need something to securely trigger the classification check updater when the focus changes
		-- but for now, we'll just completely ignore healthBarsContainer in anchors
	end
end

ns.BUFUnitFrames:RegisterFrame(BUFFocus)

ns.BUFFocus = BUFFocus
