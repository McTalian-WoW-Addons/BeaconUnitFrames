---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty: BUFFeatureModule
local BUFParty = ns.NewFeatureModule("BUFParty")

BUFParty.configPath = "unitFrames.party"

BUFParty.relativeToFrames = {
	FRAME = "PartyFrame",
	PORTRAIT = "PartyPortrait",
	NAME = "PartyName",
	HEALTH = "PartyFrameHealthBar",
	POWER = "PartyFrameManaBar",
}

BUFParty.customRelativeToOptions = {
	[BUFParty.relativeToFrames.FRAME] = HUD_EDIT_MODE_PARTY_FRAMES_LABEL,
	[BUFParty.relativeToFrames.PORTRAIT] = ns.L["PartyPortrait"],
	[BUFParty.relativeToFrames.NAME] = ns.L["PartyName"],
	[BUFParty.relativeToFrames.HEALTH] = ns.L["PartyHealthBar"],
	[BUFParty.relativeToFrames.POWER] = ns.L["PartyManaBar"],
}

BUFParty.customRelativeToSorting = {
	BUFParty.relativeToFrames.FRAME,
	BUFParty.relativeToFrames.PORTRAIT,
	BUFParty.relativeToFrames.NAME,
	BUFParty.relativeToFrames.HEALTH,
	BUFParty.relativeToFrames.POWER,
}

BUFParty.optionsTable = {
	type = "group",
	name = HUD_EDIT_MODE_PARTY_FRAMES_LABEL,
	handler = BUFParty,
	order = ns.BUFUnitFrames.optionsOrder.PARTY,
	childGroups = "tree",
	disabled = BUFParty.IsDisabled,
	args = {
		title = {
			type = "header",
			name = HUD_EDIT_MODE_PARTY_FRAMES_LABEL,
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

---@class BUFDbSchema.UF.Party
BUFParty.dbDefaults = {
	enabled = true,
}

---@class BUFDbSchema.UF
ns.dbDefaults.profile.unitFrames = ns.dbDefaults.profile.unitFrames
ns.dbDefaults.profile.unitFrames.party = BUFParty.dbDefaults

ns.options.args.party = BUFParty.optionsTable

BUFParty.optionsOrder = {
	FRAME = 1,
	PORTRAIT = 2,
	REPUTATION_BAR = 3,
	NAME = 4,
	LEVEL = 5,
	INDICATORS = 6,
	HEALTH = 7,
	POWER = 8,
	SPELL = 9,
	BUFFS = 10,
}

function BUFParty.IsDisabled()
	local useRaidFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
	return not BUFParty:DbGet("enabled") or useRaidFrames
end

function BUFParty:SetEnabled(info, value)
	self:DbSet("enabled", value)
	if value then
		self:RefreshConfig()
	else
		StaticPopup_Show("BUF_RELOAD_UI")
	end
end

function BUFParty:GetEnabled(info)
	return self:DbGet("enabled")
end

-- TODO: Might move this somewhere else for other frames that are repeated clones (party, raid, etc.)
---@class BUFPartyPositionable: Positionable
local BUFPartyPositionable = {}

---@param parentFrame PartyMemberFrameTemplate
---@return ScriptRegionResizing
function BUFPartyPositionable:GetRelativeFrame(parentFrame)
	local relativeTo = self:GetRelativeTo()
	if relativeTo == BUFParty.relativeToFrames.FRAME then
		return parentFrame
	elseif relativeTo == BUFParty.relativeToFrames.PORTRAIT then
		return parentFrame.Portrait
	elseif relativeTo == BUFParty.relativeToFrames.NAME then
		return parentFrame.Name
	elseif relativeTo == BUFParty.relativeToFrames.HEALTH then
		return parentFrame.HealthBarContainer.HealthBar
	elseif relativeTo == BUFParty.relativeToFrames.POWER then
		return parentFrame.ManaBar
	else
		error("Unknown relativeTo frame: " .. tostring(relativeTo))
	end
end

---@see Positionable.GetPositionAnchorInfo
function BUFPartyPositionable:GetPositionAnchorInfo(parentFrame)
	local relFrame = self:GetRelativeFrame(parentFrame)

	local anchorPoint = self:GetAnchorPoint() or "TOPLEFT"

	---@type string
	local relativePoint = self:GetRelativePoint() or anchorPoint

	local xOffset = self:GetXOffset() or 0
	local yOffset = self:GetYOffset() or 0

	---@type AnchorInfo
	local anchorInfo = {
		point = anchorPoint,
		relativeTo = relFrame,
		relativePoint = relativePoint,
		xOffset = xOffset,
		yOffset = yOffset,
	}

	return anchorInfo
end

local BUFPartyInstance = {}

function BUFPartyInstance:New(index)
	if index > MAX_PARTY_MEMBERS then
		error("BUFPartyInstance:New - index exceeds MAX_PARTY_MEMBERS")
	end
	---@class BUFPartyInstance
	---@field backdropFrame? BackdropTemplate
	---@field portrait? table
	---@field name? table
	---@field level? table
	---@field reputationBar? table
	---@field indicators? table
	---@field health? table
	---@field power? table
	---@field castBar? table
	local bpi = {}

	bpi.frame = PartyFrame["MemberFrame" .. index]
	bpi.healthBarContainer = bpi.frame.HealthBarContainer
	bpi.healthBar = bpi.healthBarContainer.HealthBar
	bpi.manaBar = bpi.frame.ManaBar
	bpi.altPowerBar = bpi.frame.PowerBarAlt
	bpi.unit = "party" .. index

	local ArtUpdater = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")
	ns.Mixin(ArtUpdater, ns.BUFSecureHandler)

	ArtUpdater:SecureSetFrameRef("AltPowerBar", bpi.altPowerBar)
	ArtUpdater:SecureSetFrameRef("HealthBar", bpi.healthBar)
	ArtUpdater:SecureSetFrameRef("PowerBar", bpi.manaBar)

	bpi.ArtUpdater = ArtUpdater

	return bpi
end

function BUFParty:OnEnable()
	---@type BUFPartyInstance[]
	self.frames = {}
	for i = 1, MAX_PARTY_MEMBERS do
		table.insert(self.frames, BUFPartyInstance:New(i))
	end
end

function BUFParty:HookUpdateSystemSetting()
	if not self:IsHooked(PartyFrame, "UpdateSystemSetting") then
		self:SecureHook(PartyFrame, "UpdateSystemSetting", function(s, setting, entireSystem)
			if setting == Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames then
				RunNextFrame(function()
					self:RefreshConfig()
				end)
			end
		end)
	end
end

function BUFParty:RefreshPartyMemberColors()
	if self:IsDisabled() then
		return
	end
	self.Health.foregroundHandler:RefreshConfig()
	self.Power.foregroundHandler:RefreshConfig()
end

function BUFParty:RefreshPartyHighlights()
	if self:IsDisabled() then
		return
	end
	if self.Indicators and self.Indicators.StatusIndicator then
		self.Indicators.StatusIndicator:RefreshVisuals()
	end
end

function BUFParty:OnGroupRosterUpdate()
	if InCombatLockdown() then
		self.outOfCombatFrame = self.outOfCombatFrame or CreateFrame("Frame")
		self.outOfCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		self.outOfCombatFrame:SetScript("OnEvent", function(f)
			self:RefreshPartyMemberColors()
			self:RefreshPartyHighlights()
			f:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end)
		return
	end

	-- Delay one frame so Blizzard's party unit remapping is finalized first.
	RunNextFrame(function()
		self:RefreshPartyMemberColors()
		self:RefreshPartyHighlights()
	end)
end

function BUFParty:OnPartyHighlightEvent(event, unit)
	if self:IsDisabled() then
		return
	end

	if unit and unit ~= "target" and unit ~= "mouseover" and not string.find(unit, "party", 1, true) then
		return
	end

	self:RefreshPartyHighlights()
end

function BUFParty:RefreshConfig()
	self:HookUpdateSystemSetting()

	if self:IsDisabled() then
		self:UnhookAll()
		self:HookUpdateSystemSetting()
		return
	end

	self.Portrait:RefreshConfig()
	self.Name:RefreshConfig()
	self.Indicators:RefreshConfig()
	self.Health:RefreshConfig()
	self.Power:RefreshConfig()
	self.Frame:RefreshConfig()

	if not self.initialized then
		self.initialized = true

		self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupRosterUpdate")
		self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnPartyHighlightEvent")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "OnPartyHighlightEvent")
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", "OnPartyHighlightEvent")
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", "OnPartyHighlightEvent")

		local manaBars = {}
		for i, frameInstance in ipairs(self.frames) do
			self:SecureHook(frameInstance.frame, "UpdateNotPresentIcon", function()
				-- Be careful in here, if you do anything insecure, it could cause lua errors during combat
				self.Health.foregroundHandler:RefreshConfig()
				self.Power.foregroundHandler:RefreshConfig()
			end)

			local ArtUpdater = frameInstance.ArtUpdater

			ArtUpdater:SetAttribute(
				"buf_restore_size_position",
				[[
				-- AltPowerBar:RunAttribute("buf_restore_size")
				HealthBar:RunAttribute("buf_restore_size")
				PowerBar:RunAttribute("buf_restore_size")

				HealthBar:RunAttribute("buf_restore_position")
				PowerBar:RunAttribute("buf_restore_position")
			]]
			)

			ArtUpdater:SetAttribute(
				"_onattributechanged",
				[[
				self:RunAttribute("buf_restore_size_position")
			]]
			)

			SecureHandlerWrapScript(
				PartyFrame.Background,
				"OnShow",
				ArtUpdater,
				[[
				control:RunAttribute("buf_restore_size_position")
			]]
			)

			SecureHandlerWrapScript(
				PartyFrame.Background,
				"OnHide",
				ArtUpdater,
				[[
				control:RunAttribute("buf_restore_size_position")
			]]
			)

			table.insert(manaBars, frameInstance.manaBar)

			self:SecureHook(frameInstance.frame, "UpdateArt", function()
				if InCombatLockdown() then
					-- Be careful in here, if you do anything insecure, it could cause lua errors during combat
					self.Power.foregroundHandler:RefreshConfig()
					self.Health.foregroundHandler:RefreshConfig()
					self.Indicators:RefreshConfig()
					self.Portrait:RefreshConfig()
					self.Name:RefreshConfig()

					self.outOfCombatFrame = self.outOfCombatFrame or CreateFrame("Frame")
					self.outOfCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
					self.outOfCombatFrame:SetScript("OnEvent", function(f)
						self:RefreshConfig()
						f:UnregisterEvent("PLAYER_REGEN_ENABLED")
					end)
				else
					self:RefreshConfig()
				end
			end)
		end

		self:SecureHook("UnitFrameManaBar_UpdateType", function(manaBar)
			for _, frameInstance in ipairs(self.frames) do
				if manaBar == frameInstance.manaBar then
					self.Power.foregroundHandler:RefreshConfig()
					self:RefreshPartyHighlights()
					break
				end
			end
		end)
	end
end

ns.BUFUnitFrames:RegisterFrame(BUFParty)

ns.BUFPartyPositionable = BUFPartyPositionable
ns.BUFParty = BUFParty
