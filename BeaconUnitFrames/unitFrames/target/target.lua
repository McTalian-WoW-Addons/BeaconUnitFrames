---@class BUFNamespace
local ns = select(2, ...)

---@type BUFDbBackedHandler
local cvarsDb = Mixin({ configPath = "restoreCvars" }, ns.GlobalDbBackedHandler)

---@class BUFTarget: BUFFeatureModule
local BUFTarget = ns.NewFeatureModule("BUFTarget")

BUFTarget.configPath = "unitFrames.target"

BUFTarget.relativeToFrames = {
	FRAME = ns.Positionable.relativeToFrames.TARGET_FRAME,
	PORTRAIT = ns.Positionable.relativeToFrames.TARGET_PORTRAIT,
	REPUTATION_BAR = ns.Positionable.relativeToFrames.TARGET_REPUTATION_BAR,
	NAME = ns.Positionable.relativeToFrames.TARGET_NAME,
	LEVEL = ns.Positionable.relativeToFrames.TARGET_LEVEL,
	HEALTH = ns.Positionable.relativeToFrames.TARGET_HEALTH_BAR,
	POWER = ns.Positionable.relativeToFrames.TARGET_POWER_BAR,
}

BUFTarget.customRelativeToOptions = {
	[ns.Positionable.relativeToFrames.UI_PARENT] = ns.L["UIParent"],
	[BUFTarget.relativeToFrames.FRAME] = HUD_EDIT_MODE_TARGET_FRAME_LABEL,
	[BUFTarget.relativeToFrames.REPUTATION_BAR] = ns.L["TargetReputationBar"],
	[BUFTarget.relativeToFrames.PORTRAIT] = ns.L["TargetPortrait"],
	[BUFTarget.relativeToFrames.NAME] = ns.L["TargetName"],
	[BUFTarget.relativeToFrames.LEVEL] = ns.L["TargetLevel"],
	[BUFTarget.relativeToFrames.HEALTH] = ns.L["TargetHealthBar"],
	[BUFTarget.relativeToFrames.POWER] = ns.L["TargetManaBar"],
}

BUFTarget.customRelativeToSorting = {
	ns.Positionable.relativeToFrames.UI_PARENT,
	BUFTarget.relativeToFrames.FRAME,
	BUFTarget.relativeToFrames.REPUTATION_BAR,
	BUFTarget.relativeToFrames.PORTRAIT,
	BUFTarget.relativeToFrames.NAME,
	BUFTarget.relativeToFrames.LEVEL,
	BUFTarget.relativeToFrames.HEALTH,
	BUFTarget.relativeToFrames.POWER,
}

BUFTarget.optionsTable = {
	type = "group",
	name = HUD_EDIT_MODE_TARGET_FRAME_LABEL,
	handler = BUFTarget,
	order = ns.BUFUnitFrames.optionsOrder.TARGET,
	childGroups = "tree",
	disabled = BUFTarget.IsDisabled,
	args = {
		title = {
			type = "header",
			name = HUD_EDIT_MODE_TARGET_FRAME_LABEL,
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

---@class BUFDbSchema.UF.Target
BUFTarget.dbDefaults = {
	enabled = true,
}

---@class BUFDbSchema.UF
ns.dbDefaults.profile.unitFrames = ns.dbDefaults.profile.unitFrames
ns.dbDefaults.profile.unitFrames.target = BUFTarget.dbDefaults

ns.options.args.target = BUFTarget.optionsTable

BUFTarget.optionsOrder = {
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

function BUFTarget.IsDisabled()
	return not BUFTarget:DbGet("enabled")
end

function BUFTarget:SetEnabled(info, value)
	self:DbSet("enabled", value)
	if value then
		self:RefreshConfig()
	else
		StaticPopup_Show("BUF_RELOAD_UI")
	end
end

function BUFTarget:GetEnabled(info)
	return self:DbGet("enabled")
end

function BUFTarget:OnEnable()
	self.frame = TargetFrame
	self.container = self.frame.TargetFrameContainer
	self.content = self.frame.TargetFrameContent
	self.contentMain = self.content.TargetFrameContentMain
	self.contentContextual = self.content.TargetFrameContentContextual
	self.healthBarContainer = self.contentMain.HealthBarsContainer
	self.healthBar = self.healthBarContainer.HealthBar
	self.manaBar = self.contentMain.ManaBar
	self.altPowerBar = self.frame.powerBarAlt
end

function BUFTarget:RefreshConfig()
	if not self:GetEnabled() then
		return
	end
	if not self.initialized then
		local ClassificationCheckUpdater = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")
		Mixin(ClassificationCheckUpdater, ns.BUFSecureHandler)

		-- healthBarsContainer gets moved during CheckClassification
		-- if we don't anchor anything to it, we can avoid having to reapply our position/size changes
		-- leaving this in here in case there ever turns out to be a reliable secure trigger
		ClassificationCheckUpdater:SecureSetFrameRef("TargetHealthBarContainer", self.healthBarContainer)
		ClassificationCheckUpdater:SecureSetFrameRef("TargetHealthBar", self.healthBar)
		ClassificationCheckUpdater:SecureSetFrameRef("TargetManaBar", self.manaBar)

		ns.TargetClassificationCheckUpdater = ClassificationCheckUpdater
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
		if not cvarsDb:DbGet("showTempMaxHealthLoss") then
			cvarsDb:DbSet("showTempMaxHealthLoss", GetCVar("showTempMaxHealthLoss"))
		end
		ns.db.RegisterCallback(ns, "OnDatabaseShutdown", function()
			SetCVar("showTempMaxHealthLoss", cvarsDb:DbGet("showTempMaxHealthLoss"))
		end)
		SetCVar("showTempMaxHealthLoss", "0")

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
		local ClassificationCheckUpdater = ns.TargetClassificationCheckUpdater

		ClassificationCheckUpdater:SetAttribute(
			"buf_restore_size_position",
			[[
            TargetHealthBarContainer:RunAttribute("buf_restore_size")
            -- TargetHealthBar:RunAttribute("buf_restore_size")
            -- TargetManaBar:RunAttribute("buf_restore_size")
            
            -- TargetHealthBarContainer:RunAttribute("buf_restore_position")
            -- TargetManaBar:RunAttribute("buf_restore_position")
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

		-- I need something to securely trigger the classification check updater when the target changes
		-- but for now, we'll just completely ignore healthBarsContainer in anchors
	end
end

ns.BUFUnitFrames:RegisterFrame(BUFTarget)

ns.BUFTarget = BUFTarget
