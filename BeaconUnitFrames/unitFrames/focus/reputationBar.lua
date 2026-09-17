---@class BUFNamespace
local ns = select(2, ...)

---@class BUFFocus
local BUFFocus = ns.BUFFocus

---@class BUFFocus.ReputationBar: BUFTexture, Colorable, ReactionColorable, ClassColorable
local BUFFocusReputationBar = {
	configPath = "unitFrames.focus.reputationBar",
	frameKey = BUFFocus.relativeToFrames.REPUTATION_BAR,
}

BUFFocusReputationBar.optionsTable = {
	type = "group",
	name = ns.L["Reputation Bar"],
	handler = BUFFocusReputationBar,
	order = BUFFocus.optionsOrder.REPUTATION_BAR,
	args = {
		texturing = {
			type = "header",
			name = ns.L["Texturing"],
			order = ns.defaultOrderMap.TEXTURING_HEADER,
		},
		atlasTexture = {
			type = "select",
			name = ns.L["Atlas Texture"],
			desc = ns.L["AtlasTextureDesc"],
			order = ns.defaultOrderMap.ATLAS_TEXTURE,
			values = {
				["UI-HUD-UnitFrame-Target-PortraitOn-Type"] = DEFAULT,
				["_ItemUpgradeTooltip-NineSlice-EdgeBottom"] = ns.L["Bottom Glow"],
				["Interface/AddOns/BeaconUnitFrames/icons/underhighlight_mask.png"] = ns.L["Custom Bottom Glow"],
			},
			set = "SetAtlasTexture",
			get = "GetAtlasTexture",
		},
	},
}

---@class BUFDbSchema.UF.Focus.ReputationBar
BUFFocusReputationBar.dbDefaults = {
	width = 134,
	height = 10,
	anchorPoint = "TOPRIGHT",
	relativeTo = BUFFocus.relativeToFrames.FRAME,
	relativePoint = "TOPRIGHT",
	xOffset = -75,
	yOffset = -25,
	atlasTexture = "UI-HUD-UnitFrame-Target-PortraitOn-Type",
	useCustomColor = false,
	customColor = { 0.8, 0.8, 0.2, 1 },
	useReactionColor = true,
	useClassColor = false,
}

ns.BUFTexture:ApplyMixin(BUFFocusReputationBar)
ns.Mixin(BUFFocusReputationBar, ns.Colorable, ns.ClassColorable, ns.ReactionColorable)

---@class BUFDbSchema.UF.Focus
ns.dbDefaults.profile.unitFrames.focus = ns.dbDefaults.profile.unitFrames.focus
ns.dbDefaults.profile.unitFrames.focus.reputationBar = BUFFocusReputationBar.dbDefaults

ns.AddColorOptions(BUFFocusReputationBar.optionsTable.args)
ns.AddClassColorOptions(BUFFocusReputationBar.optionsTable.args)
ns.AddReactionColorOptions(BUFFocusReputationBar.optionsTable.args)

ns.options.args.focus.args.reputationBar = BUFFocusReputationBar.optionsTable

function BUFFocusReputationBar:SetAtlasTexture(info, value)
	self:DbSet("atlasTexture", value)
	self:SetTexture()
end

function BUFFocusReputationBar:GetAtlasTexture(info)
	return self:DbGet("atlasTexture")
end

function BUFFocusReputationBar:RefreshConfig()
	if not self.initialized then
		BUFFocus.FrameInit(self)

		self.texture = FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor
		self.atlasName = "UI-HUD-UnitFrame-Target-PortraitOn-Type"

		if not BUFFocus:IsHooked(FocusFrame, "CheckFaction") then
			BUFFocus:SecureHook(FocusFrame, "CheckFaction", function()
				self:RefreshColor()
			end)
		end
	end
	self:SetSize()
	self:SetPosition()
	self:SetTexture()
	self:RefreshColor()
end

function BUFFocusReputationBar:SetSize()
	self:_SetSize(self.texture)
	self:SetTexture()
end

function BUFFocusReputationBar:SetPosition()
	self:_SetPosition(self.texture)
end

function BUFFocusReputationBar:SetTexture()
	local atlasTexture = self:GetAtlasTexture()
	local useAtlasSize = self:GetUseAtlasSize()
	local sPos, ePos = string.find(atlasTexture, "%.")
	if not sPos then
		self.texture:SetAtlas(atlasTexture, useAtlasSize)
	else
		-- If there's a dot, it's a file path
		self.texture:SetTexture(atlasTexture)
	end
end

function BUFFocusReputationBar:RefreshColor()
	local useCustomColor = self:DbGet("useCustomColor")
	local useClassColor = self:DbGet("useClassColor")
	local useReactionColor = self:DbGet("useReactionColor")

	local r, g, b, a = nil, nil, nil, 1
	if useCustomColor then
		r, g, b, a = unpack(self:DbGet("customColor"))
	elseif useClassColor and (not useReactionColor or UnitPlayerControlled("focus")) then
		-- nil when the unit's identity is secret, which falls through to the reaction color
		r, g, b = ns.GetUnitClassColor("focus")
	end

	if r == nil and useReactionColor then
		r, g, b = ns.GetUnitReactionColor("focus")
	end

	if r == nil then
		return
	end

	self.texture:SetVertexColor(r, g, b, a)
end

BUFFocus.ReputationBar = BUFFocusReputationBar
