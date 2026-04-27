---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.Name: BUFFontString, TextCustomizable
local BUFPlayerName = {
	configPath = "unitFrames.player.name",
	frameKey = BUFPlayer.relativeToFrames.NAME,
}

BUFPlayerName.optionsTable = {
	type = "group",
	handler = BUFPlayerName,
	name = CALENDAR_PLAYER_NAME,
	order = BUFPlayer.optionsOrder.NAME,
	args = {},
}

ns.BUFFontString:ApplyMixin(BUFPlayerName)
ns.Mixin(BUFPlayerName, ns.TextCustomizable)

BUFPlayer.Name = BUFPlayerName

---@class BUFDbSchema.UF.Player
ns.dbDefaults.profile.unitFrames.player = ns.dbDefaults.profile.unitFrames.player

---@class BUFDbSchema.UF.Player.Name
ns.dbDefaults.profile.unitFrames.player.name = {
	width = 96,
	height = 12,
	anchorPoint = "TOPLEFT",
	relativeTo = BUFPlayer.relativeToFrames.FRAME,
	relativePoint = "TOPLEFT",
	xOffset = 88,
	yOffset = -27,
	customText = nil,
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

ns.AddTextCustomizableOptions(BUFPlayerName.optionsTable.args)

ns.options.args.player.args.playerName = BUFPlayerName.optionsTable

function BUFPlayerName:RefreshConfig()
	if not self.initialized then
		BUFPlayer.FrameInit(self)

		self.fontString = PlayerName

		if not BUFPlayer:IsHooked("PlayerFrame_UpdatePlayerNameTextAnchor") then
			BUFPlayer:SecureHook("PlayerFrame_UpdatePlayerNameTextAnchor", function()
				self:SetPosition()
			end)
		end
	end
	self:RefreshFontStringConfig()
	self:RefreshText()
end

function BUFPlayerName:RefreshText()
	local customText = self:DbGet("customText")
	if customText and customText ~= "" then
		PlayerName:SetText(customText)
	else
		PlayerName:SetText(UnitName("player"))
	end
end
