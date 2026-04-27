---@class BUFNamespace
local ns = select(2, ...)

---@class BUFTarget
local BUFTarget = ns.BUFTarget

---@class BUFTarget.Name: BUFFontString
local BUFTargetName = {
	configPath = "unitFrames.target.name",
	frameKey = BUFTarget.relativeToFrames.NAME,
}

BUFTargetName.optionsTable = {
	type = "group",
	handler = BUFTargetName,
	name = ns.L["TargetName"],
	order = BUFTarget.optionsOrder.NAME,
	args = {},
}

ns.BUFFontString:ApplyMixin(BUFTargetName)

BUFTarget.Name = BUFTargetName

---@class BUFDbSchema.UF.Target
ns.dbDefaults.profile.unitFrames.target = ns.dbDefaults.profile.unitFrames.target

---@class BUFDbSchema.UF.Target.Name
ns.dbDefaults.profile.unitFrames.target.name = {
	width = 96,
	height = 12,
	anchorPoint = "TOPLEFT",
	relativeTo = BUFTarget.relativeToFrames.REPUTATION_BAR,
	relativePoint = "TOPRIGHT",
	xOffset = -106,
	yOffset = -1,
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
	textDrawLayer = "ARTWORK",
	textSublevel = 0,
}

ns.options.args.target.args.targetName = BUFTargetName.optionsTable

function BUFTargetName:RefreshConfig()
	if not self.initialized then
		BUFTarget.FrameInit(self)

		self.fontString = ns.BUFTarget.contentMain.Name
	end
	self:RefreshFontStringConfig()
end
