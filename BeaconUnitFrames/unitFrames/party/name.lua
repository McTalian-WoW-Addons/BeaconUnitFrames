---@class BUFNamespace
local ns = select(2, ...)

---@class BUFParty
local BUFParty = ns.BUFParty

---@class BUFParty.Name: BUFFontString
local BUFPartyName = {
	configPath = "unitFrames.party.name",
	frameKey = BUFParty.relativeToFrames.NAME,
}

BUFPartyName.optionsTable = {
	type = "group",
	handler = BUFPartyName,
	name = ns.L["TargetName"],
	order = BUFParty.optionsOrder.NAME,
	args = {},
}

---@class BUFDbSchema.UF.Party
ns.dbDefaults.profile.unitFrames.party = ns.dbDefaults.profile.unitFrames.party

---@class BUFDbSchema.UF.Party.Name
ns.dbDefaults.profile.unitFrames.party.name = {
	width = 57,
	height = 12,
	anchorPoint = "TOPLEFT",
	relativeTo = BUFParty.relativeToFrames.FRAME,
	relativePoint = "TOPLEFT",
	xOffset = 46,
	yOffset = -6,
	useFontObjects = true,
	fontObject = "GameFontNormalSmall",
	fontColor = { NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.a },
	fontFace = "Friz Quadrata TT",
	fontSize = 12,
	fontFlags = {
		[ns.FontFlags.OUTLINE] = false,
		[ns.FontFlags.THICKOUTLINE] = false,
		[ns.FontFlags.MONOCHROME] = false,
	},
	fontShadowColor = { 0, 0, 0, 1 },
	fontShadowOffsetX = 1,
	fontShadowOffsetY = -1,
	justifyH = "LEFT",
	justifyV = "MIDDLE",
}

ns.options.args.party.args.partyName = BUFPartyName.optionsTable

ns.BUFFontString:ApplyMixin(BUFPartyName)
ns.Mixin(BUFPartyName, ns.BUFPartyPositionable)

function BUFPartyName:RefreshConfig()
	if not self.initialized then
		BUFParty.FrameInit(self)

		for _, bpi in ipairs(BUFParty.frames) do
			bpi.name = {}
			bpi.name.fontString = bpi.frame.Name
			bpi.name.fontString.bufOverrideParentFrame = bpi.frame
		end
	end
	self:RefreshFontStringConfig()
	BUFParty:RefreshPartyHighlights()
end

function BUFPartyName:ToggleDemoMode()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_ToggleDemoMode(bpi.name.fontString)
	end
end

function BUFPartyName:SetPosition()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetPosition(bpi.name.fontString)
	end
end

function BUFPartyName:SetSize()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetSize(bpi.name.fontString)
	end
end

function BUFPartyName:SetFont()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetFont(bpi.name.fontString)
	end
end

function BUFPartyName:UpdateFontColor()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_UpdateFontColor(bpi.name.fontString)
	end
end

function BUFPartyName:SetFontShadow()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_SetFontShadow(bpi.name.fontString)
	end
end

function BUFPartyName:UpdateJustification()
	for _, bpi in ipairs(BUFParty.frames) do
		self:_UpdateJustification(bpi.name.fontString)
	end
end

BUFParty.Name = BUFPartyName
