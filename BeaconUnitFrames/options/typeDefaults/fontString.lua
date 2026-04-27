---@class BUFNamespace
local ns = select(2, ...)

--- Add font string options to the given options table
--- @param optionsTable table
--- @param _orderMap BUFOptionsOrder?
function ns.AddFontStringOptions(optionsTable, _orderMap)
	local orderMap = _orderMap or ns.defaultOrderMap
	ns.AddPositionableOptions(optionsTable, orderMap)
	ns.AddSizableOptions(optionsTable, orderMap)
	ns.AddFontOptions(optionsTable, orderMap)
	ns.AddJustifiableOptions(optionsTable, orderMap)
	ns.AddTextLayerOptions(optionsTable, orderMap)
	ns.AddDemoOptions(optionsTable, orderMap)
end

---@class FontStringHandler
---@field RefreshFontStringConfig fun(self: BUFFontString)
---@field fontString FontString
---@field demoText string?

---@class BUFFontString: FontStringHandler, Justifiable, Fontable, Sizable, Positionable, TextLayerable, Demoable
local BUFFontString = {}

--- Apply mixins to a BUFFontString
---@param self BUFFontString
---@param handler BUFConfigHandler
function BUFFontString:ApplyMixin(handler)
	ns.Mixin(handler, ns.Demoable, ns.Sizable, ns.Positionable, ns.Justifiable, ns.Fontable, ns.TextLayerable, self)

	if handler.optionsTable then
		ns.AddFontStringOptions(handler.optionsTable.args, handler.optionsOrder)
	end
end

function BUFFontString:ToggleDemoMode()
	self:_ToggleDemoMode(self.fontString)
	if self.demoText then
		self.fontString:SetText(self.demoText)
	end
end

function BUFFontString:SetSize()
	self:_SetSize(self.fontString)
end

function BUFFontString:SetPosition()
	self:_SetPosition(self.fontString)
end

function BUFFontString:SetFont()
	self:_SetFont(self.fontString)
end

function BUFFontString:UpdateFontColor()
	self:_UpdateFontColor(self.fontString)
end

function BUFFontString:SetFontShadow()
	self:_SetFontShadow(self.fontString)
end

function BUFFontString:UpdateJustification()
	self:_UpdateJustification(self.fontString)
end

function BUFFontString:SetTextLayer()
	self:_SetTextLayer(self.fontString)
end

function BUFFontString:RefreshFontStringConfig()
	self:SetPosition()
	self:SetSize()
	self:SetFont()
	self:SetFontShadow()
	self:UpdateJustification()
	self:SetTextLayer()
end

ns.BUFFontString = BUFFontString
