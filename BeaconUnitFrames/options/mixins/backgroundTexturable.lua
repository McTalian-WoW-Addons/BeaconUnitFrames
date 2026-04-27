---@class BUFNamespace
local ns = select(2, ...)

--- Add background texture and border options to the given options table
--- @param optionsTable table
--- @param _orderMap BUFOptionsOrder?
function ns.AddBackgroundTextureOptions(optionsTable, _orderMap)
	local orderMap = _orderMap or ns.defaultOrderMap

	optionsTable.backgroundHeader = optionsTable.backgroundHeader
		or {
			type = "header",
			name = ns.L["Background Options"],
			order = orderMap.BACKGROUND_HEADER,
		}

	optionsTable.useBackgroundTexture = {
		type = "toggle",
		name = ns.L["Use Background Texture"],
		desc = ns.L["UseBackgroundTextureDesc"],
		set = "SetUseBackgroundTexture",
		get = "GetUseBackgroundTexture",
		order = orderMap.USE_BACKGROUND_TEXTURE,
	}

	optionsTable.backgroundTexture = {
		type = "select",
		name = ns.L["Background Texture"],
		dialogControl = "LSM30_Background",
		values = function()
			return ns.lsm:HashTable(ns.lsm.MediaType.BACKGROUND)
		end,
		disabled = "IsBackgroundTextureDisabled",
		set = "SetBackgroundTexture",
		get = "GetBackgroundTexture",
		order = orderMap.BACKGROUND_TEXTURE,
	}

	optionsTable.borderHeader = optionsTable.borderHeader
		or {
			type = "header",
			name = ns.L["Border Options"],
			order = orderMap.BORDER_HEADER,
		}

	optionsTable.useBackdropBorder = {
		type = "toggle",
		name = ns.L["Use Border"],
		desc = ns.L["UseBackdropBorderDesc"],
		set = "SetUseBackdropBorder",
		get = "GetUseBackdropBorder",
		order = orderMap.USE_BACKDROP_BORDER,
	}

	optionsTable.backdropBorderTexture = {
		type = "select",
		name = ns.L["Border Texture"],
		dialogControl = "LSM30_Border",
		values = function()
			return ns.lsm:HashTable(ns.lsm.MediaType.BORDER)
		end,
		disabled = "IsBackdropBorderDisabled",
		set = "SetBackdropBorderTexture",
		get = "GetBackdropBorderTexture",
		order = orderMap.BACKDROP_BORDER_TEXTURE,
	}

	optionsTable.backdropEdgeSize = {
		type = "range",
		name = ns.L["Border Width"],
		min = 1,
		max = 32,
		step = 1,
		disabled = "IsBackdropBorderDisabled",
		set = "SetBackdropEdgeSize",
		get = "GetBackdropEdgeSize",
		order = orderMap.BACKDROP_EDGE_SIZE,
	}

	optionsTable.backdropBorderColor = {
		type = "color",
		name = ns.L["Border Color"],
		hasAlpha = true,
		disabled = "IsBackdropBorderDisabled",
		set = "SetBackdropBorderColor",
		get = "GetBackdropBorderColor",
		order = orderMap.BACKDROP_BORDER_COLOR,
	}

	optionsTable.backdropInsetLeft = {
		type = "range",
		name = ns.L["Inset Left"],
		min = -64,
		max = 64,
		step = 1,
		disabled = "IsBackdropBorderDisabled",
		set = "SetBackdropInsetLeft",
		get = "GetBackdropInsetLeft",
		order = orderMap.BACKDROP_INSET_LEFT,
	}

	optionsTable.backdropInsetRight = {
		type = "range",
		name = ns.L["Inset Right"],
		min = -64,
		max = 64,
		step = 1,
		disabled = "IsBackdropBorderDisabled",
		set = "SetBackdropInsetRight",
		get = "GetBackdropInsetRight",
		order = orderMap.BACKDROP_INSET_RIGHT,
	}

	optionsTable.backdropInsetTop = {
		type = "range",
		name = ns.L["Inset Top"],
		min = -64,
		max = 64,
		step = 1,
		disabled = "IsBackdropBorderDisabled",
		set = "SetBackdropInsetTop",
		get = "GetBackdropInsetTop",
		order = orderMap.BACKDROP_INSET_TOP,
	}

	optionsTable.backdropInsetBottom = {
		type = "range",
		name = ns.L["Inset Bottom"],
		min = -64,
		max = 64,
		step = 1,
		disabled = "IsBackdropBorderDisabled",
		set = "SetBackdropInsetBottom",
		get = "GetBackdropInsetBottom",
		order = orderMap.BACKDROP_INSET_BOTTOM,
	}
end

---@class BackgroundTexturableHandler: MixinBase
---@field RefreshBackgroundTexture fun(self: BackgroundTexturableHandler)

---@class BackgroundTexturable: BackgroundTexturableHandler
local BackgroundTexturable = {}

ns.Mixin(BackgroundTexturable, ns.MixinBase)

---Set whether to use a custom background texture
---@param info table AceConfig info table
---@param value boolean Whether to use custom texture
function BackgroundTexturable:SetUseBackgroundTexture(info, value)
	self:DbSet("useBackgroundTexture", value)
	self:RefreshBackgroundTexture()
end

---Get whether to use a custom background texture
---@param info? table AceConfig info table
---@return boolean|nil Whether to use custom texture
function BackgroundTexturable:GetUseBackgroundTexture(info)
	return self:DbGet("useBackgroundTexture")
end

---Set the background texture
---@param info table AceConfig info table
---@param value string The texture name
function BackgroundTexturable:SetBackgroundTexture(info, value)
	self:DbSet("backgroundTexture", value)
	self:RefreshBackgroundTexture()
end

---Get the background texture
---@param info? table AceConfig info table
---@return string|nil The texture name
function BackgroundTexturable:GetBackgroundTexture(info)
	return self:DbGet("backgroundTexture")
end

---Check if background texture selection is disabled
---@param info table AceConfig info table
---@return boolean Whether texture selection is disabled
function BackgroundTexturable:IsBackgroundTextureDisabled(info)
	return self:DbGet("useBackgroundTexture") == false
end

---Set whether to use a backdrop border
---@param info table AceConfig info table
---@param value boolean Whether to use backdrop border
function BackgroundTexturable:SetUseBackdropBorder(info, value)
	self:DbSet("useBackdropBorder", value)
	self:RefreshBackgroundTexture()
end

---Get whether to use a backdrop border
---@param info? table AceConfig info table
---@return boolean|nil Whether to use backdrop border
function BackgroundTexturable:GetUseBackdropBorder(info)
	return self:DbGet("useBackdropBorder")
end

---Set the backdrop border texture
---@param info table AceConfig info table
---@param value string The border texture name
function BackgroundTexturable:SetBackdropBorderTexture(info, value)
	self:DbSet("backdropBorderTexture", value)
	self:RefreshBackgroundTexture()
end

---Get the backdrop border texture
---@param info? table AceConfig info table
---@return string|nil The border texture name
function BackgroundTexturable:GetBackdropBorderTexture(info)
	return self:DbGet("backdropBorderTexture")
end

---Set the backdrop edge size (border width)
---@param info table AceConfig info table
---@param value number The edge size in pixels
function BackgroundTexturable:SetBackdropEdgeSize(info, value)
	self:DbSet("backdropEdgeSize", value)
	self:RefreshBackgroundTexture()
end

---Get the backdrop edge size (border width)
---@param info? table AceConfig info table
---@return number|nil The edge size in pixels
function BackgroundTexturable:GetBackdropEdgeSize(info)
	return self:DbGet("backdropEdgeSize") or 16
end

---Set the backdrop border color
---@param info table AceConfig info table
---@param r number Red channel (0-1)
---@param g number Green channel (0-1)
---@param b number Blue channel (0-1)
---@param a number Alpha channel (0-1)
function BackgroundTexturable:SetBackdropBorderColor(info, r, g, b, a)
	self:DbSet("backdropBorderColor", { r, g, b, a })
	self:RefreshBackgroundTexture()
end

---Get the backdrop border color
---@param info? table AceConfig info table
---@return number r
---@return number g
---@return number b
---@return number a
function BackgroundTexturable:GetBackdropBorderColor(info)
	local color = self:DbGet("backdropBorderColor")
	if color then
		return color[1], color[2], color[3], color[4]
	end
	return 1, 1, 1, 1
end

---Check if backdrop border options are disabled
---@param info table AceConfig info table
---@return boolean Whether border options are disabled
function BackgroundTexturable:IsBackdropBorderDisabled(info)
	return self:DbGet("useBackdropBorder") == false
end

---Set backdrop inset on left side
---@param info table AceConfig info table
---@param value number Left inset in pixels
function BackgroundTexturable:SetBackdropInsetLeft(info, value)
	self:DbSet("backdropInsetLeft", value)
	self:RefreshBackgroundTexture()
end

---Get backdrop inset on left side
---@param info? table AceConfig info table
---@return number
function BackgroundTexturable:GetBackdropInsetLeft(info)
	return self:DbGet("backdropInsetLeft") or 0
end

---Set backdrop inset on right side
---@param info table AceConfig info table
---@param value number Right inset in pixels
function BackgroundTexturable:SetBackdropInsetRight(info, value)
	self:DbSet("backdropInsetRight", value)
	self:RefreshBackgroundTexture()
end

---Get backdrop inset on right side
---@param info? table AceConfig info table
---@return number
function BackgroundTexturable:GetBackdropInsetRight(info)
	return self:DbGet("backdropInsetRight") or 0
end

---Set backdrop inset on top side
---@param info table AceConfig info table
---@param value number Top inset in pixels
function BackgroundTexturable:SetBackdropInsetTop(info, value)
	self:DbSet("backdropInsetTop", value)
	self:RefreshBackgroundTexture()
end

---Get backdrop inset on top side
---@param info? table AceConfig info table
---@return number
function BackgroundTexturable:GetBackdropInsetTop(info)
	return self:DbGet("backdropInsetTop") or 0
end

---Set backdrop inset on bottom side
---@param info table AceConfig info table
---@param value number Bottom inset in pixels
function BackgroundTexturable:SetBackdropInsetBottom(info, value)
	self:DbSet("backdropInsetBottom", value)
	self:RefreshBackgroundTexture()
end

---Get backdrop inset on bottom side
---@param info? table AceConfig info table
---@return number
function BackgroundTexturable:GetBackdropInsetBottom(info)
	return self:DbGet("backdropInsetBottom") or 0
end

ns.BackgroundTexturable = BackgroundTexturable
