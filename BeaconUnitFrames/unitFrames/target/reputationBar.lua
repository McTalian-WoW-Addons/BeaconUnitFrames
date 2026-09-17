---@class BUFNamespace
local ns = select(2, ...)

---@class BUFTarget
local BUFTarget = ns.BUFTarget

---@class BUFTarget.ReputationBar: BUFTexture, Colorable, ReactionColorable, ClassColorable
local BUFTargetReputationBar = {
	configPath = "unitFrames.target.reputationBar",
	frameKey = BUFTarget.relativeToFrames.REPUTATION_BAR,
}

BUFTargetReputationBar.optionsTable = {
	type = "group",
	name = ns.L["Reputation Bar"],
	handler = BUFTargetReputationBar,
	order = BUFTarget.optionsOrder.REPUTATION_BAR,
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

---@class BUFDbSchema.UF.Target.ReputationBar
BUFTargetReputationBar.dbDefaults = {
	width = 134,
	height = 10,
	anchorPoint = "TOPRIGHT",
	relativeTo = BUFTarget.relativeToFrames.FRAME,
	relativePoint = "TOPRIGHT",
	xOffset = -75,
	yOffset = -25,
	atlasTexture = "UI-HUD-UnitFrame-Target-PortraitOn-Type",
	useCustomColor = false,
	customColor = { 0.8, 0.8, 0.2, 1 },
	useReactionColor = true,
	useClassColor = false,
}

ns.BUFTexture:ApplyMixin(BUFTargetReputationBar)
ns.Mixin(BUFTargetReputationBar, ns.Colorable, ns.ClassColorable, ns.ReactionColorable)

---@class BUFDbSchema.UF.Target
ns.dbDefaults.profile.unitFrames.target = ns.dbDefaults.profile.unitFrames.target
ns.dbDefaults.profile.unitFrames.target.reputationBar = BUFTargetReputationBar.dbDefaults

ns.AddColorOptions(BUFTargetReputationBar.optionsTable.args)
ns.AddClassColorOptions(BUFTargetReputationBar.optionsTable.args)
ns.AddReactionColorOptions(BUFTargetReputationBar.optionsTable.args)

ns.options.args.target.args.reputationBar = BUFTargetReputationBar.optionsTable

function BUFTargetReputationBar:SetAtlasTexture(info, value)
	self:DbSet("atlasTexture", value)
	self:SetTexture()
end

function BUFTargetReputationBar:GetAtlasTexture(info)
	return self:DbGet("atlasTexture")
end

function BUFTargetReputationBar:RefreshConfig()
	if not self.initialized then
		BUFTarget.FrameInit(self)

		self.texture = TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor

		if not BUFTarget:IsHooked(TargetFrame, "CheckFaction") then
			BUFTarget:SecureHook(TargetFrame, "CheckFaction", function()
				self:RefreshColor()
			end)
		end
	end
	self:SetSize()
	self:SetPosition()
	self:SetTexture()
	self:RefreshColor()
end

function BUFTargetReputationBar:SetSize()
	self:_SetSize(self.texture)
end

function BUFTargetReputationBar:SetPosition()
	self:_SetPosition(self.texture)
end

function BUFTargetReputationBar:SetTexture()
	local atlasTexture = self:DbGet("atlasTexture")
	local sPos, ePos = string.find(atlasTexture, "%.")
	if not sPos then
		self.texture:SetAtlas(atlasTexture, false)
	else
		-- If there's a dot, it's a file path
		self.texture:SetTexture(atlasTexture)
	end
end

function BUFTargetReputationBar:RefreshColor()
	local useCustomColor = self:DbGet("useCustomColor")
	local useClassColor = self:DbGet("useClassColor")
	local useReactionColor = self:DbGet("useReactionColor")

	local r, g, b, a = nil, nil, nil, 1
	if useCustomColor then
		r, g, b, a = unpack(self:DbGet("customColor"))
	elseif useClassColor and (not useReactionColor or UnitPlayerControlled("target")) then
		-- nil when the unit's identity is secret, which falls through to the reaction color
		r, g, b = ns.GetUnitClassColor("target")
	end

	if r == nil and useReactionColor then
		r, g, b = ns.GetUnitReactionColor("target")
	end

	if r == nil then
		return
	end

	self.texture:SetVertexColor(r, g, b, a)
end

BUFTarget.ReputationBar = BUFTargetReputationBar
