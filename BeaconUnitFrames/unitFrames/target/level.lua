---@class BUFNamespace
local ns = select(2, ...)

---@class BUFTarget
local BUFTarget = ns.BUFTarget

---@class BUFTarget.Level: BUFFontString
local BUFTargetLevel = {
	configPath = "unitFrames.target.level",
	frameKey = BUFTarget.relativeToFrames.LEVEL,
}

BUFTargetLevel.optionsTable = {
	type = "group",
	handler = BUFTargetLevel,
	name = LEVEL,
	order = BUFTarget.optionsOrder.LEVEL,
	args = {},
}

---@class BUFDbSchema.UF.Target.Level
BUFTargetLevel.dbDefaults = {
	anchorPoint = "TOPLEFT",
	relativeTo = BUFTarget.relativeToFrames.REPUTATION_BAR,
	relativePoint = "TOPRIGHT",
	xOffset = -133,
	yOffset = -2,
	useFontObjects = true,
	fontObject = "GameNormalNumberFont",
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
	justifyH = "CENTER",
	textDrawLayer = "ARTWORK",
	textSublevel = 0,
}

ns.BUFFontString:ApplyMixin(BUFTargetLevel)

---@class BUFDbSchema.UF.Target
ns.dbDefaults.profile.unitFrames.target = ns.dbDefaults.profile.unitFrames.target
ns.dbDefaults.profile.unitFrames.target.level = BUFTargetLevel.dbDefaults

ns.options.args.target.args.level = BUFTargetLevel.optionsTable

function BUFTargetLevel:RefreshConfig()
	if not self.initialized then
		BUFTarget.FrameInit(self)

		self.fontString = BUFTarget.contentMain.LevelText

		BUFTarget:SecureHook(self.fontString, "SetVertexColor", function()
			self:UpdateFontColor()
		end)
	end
	self:RefreshFontStringConfig()
end

BUFTarget.Level = BUFTargetLevel
