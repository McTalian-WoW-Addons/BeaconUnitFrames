---@class BUFNamespace
local ns = select(2, ...)

local drawLayerOptions = {
	BACKGROUND = "Background",
	BORDER = "Border",
	ARTWORK = "Artwork",
	OVERLAY = "Overlay",
}

local drawLayerSorting = {
	"BACKGROUND",
	"BORDER",
	"ARTWORK",
	"OVERLAY",
}

--- Add text layer options to the given options table
--- @param optionsTable table
--- @param _orderMap BUFOptionsOrder?
function ns.AddTextLayerOptions(optionsTable, _orderMap)
	local orderMap = _orderMap or ns.defaultOrderMap

	optionsTable.textLayering = optionsTable.textLayering
		or {
			type = "header",
			name = ns.L["Text Layering"],
			order = orderMap.TEXT_LAYERING_HEADER,
		}

	optionsTable.textDrawLayer = {
		type = "select",
		name = ns.L["Text Draw Layer"],
		desc = ns.L["TextDrawLayerDesc"],
		values = drawLayerOptions,
		sorting = drawLayerSorting,
		set = "SetTextDrawLayer",
		get = "GetTextDrawLayer",
		order = orderMap.TEXT_DRAW_LAYER,
	}

	optionsTable.textSublevel = {
		type = "range",
		name = ns.L["Text Sublevel"],
		desc = ns.L["TextSublevelDesc"],
		min = 0,
		max = 255,
		step = 1,
		bigStep = 5,
		set = "SetTextSublevel",
		get = "GetTextSublevel",
		order = orderMap.TEXT_SUBLEVEL,
	}
end

---@class TextLayerableHandler: MixinBase
---@field SetTextLayer fun(self: TextLayerableHandler)

---@class TextLayerable: TextLayerableHandler
local TextLayerable = {}

ns.Mixin(TextLayerable, ns.MixinBase)

function TextLayerable:SetTextDrawLayer(info, value)
	self:DbSet("textDrawLayer", value)
	self:SetTextLayer()
end

function TextLayerable:GetTextDrawLayer(info)
	return self:DbGet("textDrawLayer") or "ARTWORK"
end

function TextLayerable:SetTextSublevel(info, value)
	self:DbSet("textSublevel", value)
	self:SetTextLayer()
end

function TextLayerable:GetTextSublevel(info)
	return self:DbGet("textSublevel") or 0
end

--- Set the text layer of the given fontString
--- @param self TextLayerable
--- @param fontString FontString
function TextLayerable:_SetTextLayer(fontString)
	local drawLayer = self:GetTextDrawLayer()
	local sublevel = self:GetTextSublevel()
	if fontString then
		fontString:SetDrawLayer(drawLayer, sublevel)
	end
end

ns.TextLayerable = TextLayerable
