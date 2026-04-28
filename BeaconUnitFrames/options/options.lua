---@type string
local addonName = select(1, ...)
---@class BUFNamespace
local ns = select(2, ...)

ns.lsm = LibStub("LibSharedMedia-3.0")

---@class BUFOptionsOrder
ns.defaultOrderMap = {
	DEMO_MODE = 1,
	ENABLE = 2,
	SIZING_HEADER = 2.5,
	USE_ATLAS_SIZE = 3,
	WIDTH = 4,
	HEIGHT = 5,
	SCALE = 5.5,
	POSITIONING_HEADER = 5.9,
	ANCHOR_POINT = 6,
	RELATIVE_TO = 7,
	RELATIVE_POINT = 8,
	X_OFFSET = 9,
	Y_OFFSET = 10,
	FRAME_LEVEL = 11,
	FRAME_POSITIONING_HEADER = 11.1,
	ENABLE_POSITION_OVERRIDE = 11.2,
	FRAME_ANCHOR_POINT = 11.3,
	FRAME_RELATIVE_TO = 11.4,
	FRAME_RELATIVE_POINT = 11.5,
	FRAME_X_OFFSET = 11.6,
	FRAME_Y_OFFSET = 11.7,
	FRAME_STRATA = 11.8,
	FRAME_POSITION_LEVEL = 11.85,
	CUSTOMIZATION_HEADER = 11.9,
	CUSTOM_TEXT = 12,
	JUSTIFY_H = 12.2,
	JUSTIFY_V = 12.4,
	FONT_SETTINGS_HEADER = 12.9,
	USE_FONT_OBJECTS = 13,
	FONT_OBJECT = 14,
	FONT_COLOR = 15,
	FONT_FACE = 16,
	FONT_SIZE = 17,
	FONT_FLAGS = 18,
	FONT_SHADOW_COLOR = 19,
	FONT_SHADOW_OFFSET_X = 20,
	FONT_SHADOW_OFFSET_Y = 21,
	TEXT_LAYERING_HEADER = 21.5,
	TEXT_DRAW_LAYER = 21.6,
	TEXT_SUBLEVEL = 21.7,
	TEXTURING_HEADER = 21.9,
	ATLAS_TEXTURE = 24,
	MASK = 24.1,
	MASK_WIDTH_SCALE = 24.2,
	MASK_HEIGHT_SCALE = 24.3,
	STATUS_BAR_HEADER = 24.9,
	USE_STATUS_BAR_TEXTURE = 25,
	STATUS_BAR_TEXTURE = 26,
	BACKGROUND_HEADER = 26.9,
	BACKGROUND_COLOR = 26.95,
	USE_BACKGROUND_TEXTURE = 27,
	BACKGROUND_TEXTURE = 28,
	BORDER_HEADER = 28.4,
	USE_BACKDROP_BORDER = 28.5,
	BACKDROP_BORDER_TEXTURE = 28.6,
	BACKDROP_EDGE_SIZE = 28.7,
	BACKDROP_BORDER_COLOR = 28.8,
	BACKDROP_INSET_LEFT = 28.81,
	BACKDROP_INSET_RIGHT = 28.82,
	BACKDROP_INSET_TOP = 28.83,
	BACKDROP_INSET_BOTTOM = 28.84,
	COLORING_HEADER = 28.9,
	USE_CUSTOM_COLOR = 29,
	CUSTOM_COLOR = 30,
	CLASS_COLOR = 31,
	POWER_COLOR = 32,
	REACTION_COLOR = 33,
}

ns.OptionsManager = {}

function ns.OptionsManager:Initialize()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, ns.options)
	ns.acd:SetDefaultSize(addonName, 650, 800)
end

---@class BUFOptions: AceConfig.OptionsTable
ns.options = {
	name = addonName,
	type = "group",
	childGroups = "select",
	args = {},
}

---@class BUFBaseHandler: BUFDbBackedHandler
---@field optionsTable table
---@field dbDefaults? table
---@field optionsOrder? BUFOptionsOrder
---@field initialized? boolean
---@field customRelativeToOptions table<string, string>?
---@field customRelativeToSorting string[]?
---@field CombatSafeRefresh? fun(self: BUFFeatureModule)
---@field RefreshConfig? fun(self: BUFConfigHandler)

---@class BUFConfigHandler: BUFBaseHandler
---@field frameKey? string
---@field module? BUFFeatureModule
---@field noAtlas boolean?

---@class BUFParentHandler: BUFBaseHandler

---@class BUFFeatureModule: AceModule, AceHook-3.0, AceEvent-3.0, BUFBaseHandler
---@field FrameInit? fun(self: BUFConfigHandler)
---@field relativeToFrames table<string, string>?

--- Create a new feature module
--- @param moduleName string
--- @return AceModule module basically a BUFFeatureModule
function ns.NewFeatureModule(moduleName)
	---@type BUFFeatureModule
	local module = ns.BUF:NewModule(moduleName, "AceHook-3.0", "AceEvent-3.0") --[[@as BUFFeatureModule]]

	Mixin(module, ns.ProfileDbBackedHandler)

	function module.FrameInit(s)
		s.initialized = true

		s.customRelativeToOptions = {}
		Mixin(s.customRelativeToOptions, module.customRelativeToOptions)
		s.customRelativeToSorting = {}
		Mixin(s.customRelativeToSorting, module.customRelativeToSorting)

		-- Can't anchor to ourselves
		if s.frameKey then
			s.customRelativeToOptions[s.frameKey] = nil
			for i, v in ipairs(s.customRelativeToSorting) do
				if v == s.frameKey then
					table.remove(s.customRelativeToSorting, i)
					break
				end
			end
		end
	end

	return module
end

StaticPopupDialogs["BUF_RELOAD_UI"] = {
	text = ns.L["ReloadUIRequired"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
