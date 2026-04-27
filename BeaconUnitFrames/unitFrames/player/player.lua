---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer: BUFFeatureModule
local BUFPlayer = ns.NewFeatureModule("BUFPlayer")

BUFPlayer.configPath = "unitFrames.player"

BUFPlayer.relativeToFrames = {
	FRAME = ns.Positionable.relativeToFrames.PLAYER_FRAME,
	PORTRAIT = ns.Positionable.relativeToFrames.PLAYER_PORTRAIT,
	NAME = ns.Positionable.relativeToFrames.PLAYER_NAME,
	HEALTH = ns.Positionable.relativeToFrames.PLAYER_HEALTH_BAR,
	POWER = ns.Positionable.relativeToFrames.PLAYER_POWER_BAR,
}

BUFPlayer.customRelativeToOptions = {
	[ns.Positionable.relativeToFrames.UI_PARENT] = ns.L["UIParent"],
	[BUFPlayer.relativeToFrames.FRAME] = HUD_EDIT_MODE_PLAYER_FRAME_LABEL,
	[BUFPlayer.relativeToFrames.PORTRAIT] = ns.L["PlayerPortrait"],
	[BUFPlayer.relativeToFrames.NAME] = ns.L["PlayerName"],
	[BUFPlayer.relativeToFrames.HEALTH] = ns.L["PlayerHealthBar"],
	[BUFPlayer.relativeToFrames.POWER] = ns.L["PlayerManaBar"],
}

BUFPlayer.customRelativeToSorting = {
	ns.Positionable.relativeToFrames.UI_PARENT,
	BUFPlayer.relativeToFrames.FRAME,
	BUFPlayer.relativeToFrames.PORTRAIT,
	BUFPlayer.relativeToFrames.NAME,
	BUFPlayer.relativeToFrames.HEALTH,
	BUFPlayer.relativeToFrames.POWER,
}

BUFPlayer.optionsTable = {
	type = "group",
	name = HUD_EDIT_MODE_PLAYER_FRAME_LABEL,
	handler = BUFPlayer,
	order = ns.BUFUnitFrames.optionsOrder.PLAYER,
	childGroups = "tree",
	disabled = BUFPlayer.IsDisabled,
	args = {
		title = {
			type = "header",
			name = HUD_EDIT_MODE_PLAYER_FRAME_LABEL,
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

---@class BUFDbSchema.UF.Player
BUFPlayer.dbDefaults = {
	enabled = true,
}

---@class BUFDbSchema.UF
ns.dbDefaults.profile.unitFrames = ns.dbDefaults.profile.unitFrames
ns.dbDefaults.profile.unitFrames.player = BUFPlayer.dbDefaults

ns.options.args.player = BUFPlayer.optionsTable

BUFPlayer.optionsOrder = {
	FRAME = 1,
	PORTRAIT = 2,
	NAME = 3,
	LEVEL = 4,
	INDICATORS = 5,
	HEALTH = 6,
	POWER = 7,
	ALT_POWER = 7.5,
	CLASS_RESOURCES = 8,
}

function BUFPlayer.IsDisabled()
	return not BUFPlayer:DbGet("enabled")
end

function BUFPlayer:SetEnabled(info, value)
	self:DbSet("enabled", value)
	if value then
		self:RefreshConfig()
	else
		StaticPopup_Show("BUF_RELOAD_UI")
	end
end

function BUFPlayer:GetEnabled(info)
	return self:DbGet("enabled")
end

function BUFPlayer:OnEnable()
	self.frame = PlayerFrame
	self.container = self.frame.PlayerFrameContainer
	self.content = self.frame.PlayerFrameContent
	self.contentMain = self.content.PlayerFrameContentMain
	self.contentContextual = PlayerFrame_GetPlayerFrameContentContextual()
	self.restLoop = self.contentContextual.PlayerRestLoop
	self.healthBarContainer = PlayerFrame_GetHealthBarContainer()
	self.healthBar = PlayerFrame_GetHealthBar()
	self.manaBarArea = self.contentMain.ManaBarArea
	self.manaBar = PlayerFrame_GetManaBar()
	self.altPowerBar = PlayerFrame_GetAlternatePowerBar()
end

function BUFPlayer:RefreshConfig()
	if not self:GetEnabled() then
		return
	end
	if not self.artUpdaterCreated then
		local ArtUpdater = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")
		ns.Mixin(ArtUpdater, ns.BUFSecureHandler)

		-- Kudos to Spyro from the WoWUIDev Discord for figuring out repositioning/resizing
		-- on entering/exiting vehicles
		ArtUpdater:SecureSetFrameRef("AlternatePowerBarArea", PlayerFrameAlternatePowerBarArea)
		ArtUpdater:SecureSetFrameRef("PlayerHealthBarContainer", PlayerFrame_GetHealthBarContainer())
		ArtUpdater:SecureSetFrameRef("PlayerHealthBar", PlayerFrame_GetHealthBar())
		ArtUpdater:SecureSetFrameRef("PlayerManaBar", PlayerFrame_GetManaBar())

		ns.PlayerArtUpdater = ArtUpdater
		self.artUpdaterCreated = true
	end

	self.Frame:RefreshConfig()
	self.Portrait:RefreshConfig()
	self.Name:RefreshConfig()
	self.Level:RefreshConfig()
	self.Indicators:RefreshConfig()
	self.Health:RefreshConfig()
	self.Power:RefreshConfig()
	self.AltPower:RefreshConfig()
	self.ClassResources:RefreshConfig()

	if not self.hooksInitialized then
		local ArtUpdater = ns.PlayerArtUpdater
		self.hooksInitialized = true

		ArtUpdater:SetAttribute(
			"buf_restore_size_position",
			[[
            PlayerHealthBarContainer:RunAttribute("buf_restore_size")
            PlayerHealthBar:RunAttribute("buf_restore_size")
            PlayerManaBar:RunAttribute("buf_restore_size")

            PlayerHealthBarContainer:RunAttribute("buf_restore_position")
            PlayerManaBar:RunAttribute("buf_restore_position")
        ]]
		)

		ArtUpdater:SetAttribute(
			"_onattributechanged",
			[[
            self:RunAttribute("buf_restore_size_position")
            if name == "manual" then
                return
            end

			local vehicleUnitState = tostring(self:GetAttribute("vehicleunit"))
			local vehicleUIState = tostring(self:GetAttribute("vehiclestate"))
			if vehicleUnitState == "1" or vehicleUIState == "1" then
				AlternatePowerBarArea:Hide()
			elseif UsingAltPowerBar then
				AlternatePowerBarArea:Show()
			else
				AlternatePowerBarArea:Hide()
			end
        ]]
		)

		-- Manual trigger by pressing SHIFT+ALT in case the other triggers fail
		RegisterAttributeDriver(ArtUpdater, "manual", "[mod:shift,mod:alt] 1; 0")

		-- Triggers that check for the vehicle existence
		-- This works to restore the PlayerFrame's components when entering a vehicle
		RegisterAttributeDriver(ArtUpdater, "vehicleunit", "[@vehicle,exists] 1; 0")
		RegisterAttributeDriver(ArtUpdater, "vehiclestate", "[vehicleui][overridebar][possessbar] 1; 0")

		local function WrapRestoreScripts(frame)
			for _, script in ipairs({ "OnShow", "OnHide", "OnAttributeChanged" }) do
				SecureHandlerWrapScript(
					frame,
					script,
					ArtUpdater,
					[[
                    control:RunAttribute("buf_restore_size_position")
                ]]
				)
			end
		end

		-- Trigger secure restoration on transitions that commonly happen while mounting/dismounting.
		WrapRestoreScripts(PetFrame)
		WrapRestoreScripts(PlayerFrameAlternatePowerBarArea)

		ArtUpdater:SecureExecute([[ UsingAltPowerBar = %s ]], tostring(PlayerFrame.activeAlternatePowerBar ~= nil))
		if not self:IsHooked("PlayerFrame_UpdateArt") then
			self:SecureHook("PlayerFrame_UpdateArt", function()
				if not InCombatLockdown() then
					ArtUpdater:SecureExecute(
						[[
                    UsingAltPowerBar = %s
                    self:RunAttribute("buf_restore_size_position")
                ]],
						tostring(PlayerFrame.activeAlternatePowerBar ~= nil)
					)
				else
					local frame = CreateFrame("Frame")
					frame:RegisterEvent("PLAYER_REGEN_ENABLED")
					frame:SetScript("OnEvent", function(self)
						BUFPlayer:RefreshConfig()
						self:UnregisterEvent("PLAYER_REGEN_ENABLED")
					end)
				end
				self.Health.foregroundHandler:RefreshConfig()
				self.Power.foregroundHandler:RefreshConfig()
				self.Power:SetUnprotectedSize()
				self.AltPower:RefreshConfig()
				self.Indicators:RefreshConfig()
				self.ClassResources:RefreshConfig()
			end)
		end
	end

	self.initialized = true
end

ns.BUFUnitFrames:RegisterFrame(BUFPlayer)

ns.BUFPlayer = BUFPlayer
