---@class BUFNamespace
local ns = select(2, ...)

local frameStrataOptions = {
	BACKGROUND = "BACKGROUND",
	LOW = "LOW",
	MEDIUM = "MEDIUM",
	HIGH = "HIGH",
	DIALOG = "DIALOG",
	FULLSCREEN = "FULLSCREEN",
	FULLSCREEN_DIALOG = "FULLSCREEN_DIALOG",
	TOOLTIP = "TOOLTIP",
}

local frameStrataSorting = {
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"FULLSCREEN",
	"FULLSCREEN_DIALOG",
	"TOOLTIP",
}

local anchorPointOptions = {
	TOPLEFT = ns.L["TOPLEFT"],
	TOP = ns.L["TOP"],
	TOPRIGHT = ns.L["TOPRIGHT"],
	LEFT = ns.L["LEFT"],
	CENTER = ns.L["CENTER"],
	RIGHT = ns.L["RIGHT"],
	BOTTOMLEFT = ns.L["BOTTOMLEFT"],
	BOTTOM = ns.L["BOTTOM"],
	BOTTOMRIGHT = ns.L["BOTTOMRIGHT"],
}

local anchorPointSort = {
	"TOPLEFT",
	"TOP",
	"TOPRIGHT",
	"LEFT",
	"CENTER",
	"RIGHT",
	"BOTTOMLEFT",
	"BOTTOM",
	"BOTTOMRIGHT",
}

--- Add frame positioning override options to the given options table.
--- These are opt-in overrides for frames that lack Edit Mode positioning support.
--- @param optionsTable table
--- @param _orderMap BUFOptionsOrder?
function ns.AddFramePositionableOptions(optionsTable, _orderMap)
	local orderMap = _orderMap or ns.defaultOrderMap

	optionsTable.framePositioningHeader = optionsTable.framePositioningHeader
		or {
			type = "header",
			name = ns.L["Frame Positioning"],
			order = orderMap.FRAME_POSITIONING_HEADER,
		}

	optionsTable.enablePositionOverride = {
		type = "toggle",
		name = ns.L["Override Position"],
		desc = ns.L["OverridePositionDesc"],
		set = "SetEnablePositionOverride",
		get = "GetEnablePositionOverride",
		order = orderMap.ENABLE_POSITION_OVERRIDE,
	}

	optionsTable.anchorPoint = {
		type = "select",
		name = ns.L["Anchor Point"],
		values = anchorPointOptions,
		sorting = anchorPointSort,
		set = "SetFrameAnchorPoint",
		get = "GetFrameAnchorPoint",
		disabled = "IsPositionOverrideDisabled",
		order = orderMap.FRAME_ANCHOR_POINT,
	}

	optionsTable.relativeTo = {
		type = "select",
		name = ns.L["Relative To"],
		desc = ns.L["RelativeToDesc"],
		values = "GetFrameRelativeToOptions",
		sorting = "GetFrameRelativeToSorting",
		set = "SetFrameRelativeTo",
		get = "GetFrameRelativeTo",
		disabled = "IsPositionOverrideDisabled",
		order = orderMap.FRAME_RELATIVE_TO,
	}

	optionsTable.relativePoint = {
		type = "select",
		name = ns.L["Relative Point"],
		values = anchorPointOptions,
		sorting = anchorPointSort,
		set = "SetFrameRelativePoint",
		get = "GetFrameRelativePoint",
		disabled = "IsPositionOverrideDisabled",
		order = orderMap.FRAME_RELATIVE_POINT,
	}

	optionsTable.xOffset = {
		type = "range",
		name = ns.L["X Offset"],
		min = -2000,
		softMin = -1000,
		softMax = 1000,
		max = 2000,
		step = 1,
		bigStep = 5,
		set = "SetFrameXOffset",
		get = "GetFrameXOffset",
		disabled = "IsPositionOverrideDisabled",
		order = orderMap.FRAME_X_OFFSET,
	}

	optionsTable.yOffset = {
		type = "range",
		name = ns.L["Y Offset"],
		min = -2000,
		softMin = -1000,
		softMax = 1000,
		max = 2000,
		step = 1,
		bigStep = 5,
		set = "SetFrameYOffset",
		get = "GetFrameYOffset",
		disabled = "IsPositionOverrideDisabled",
		order = orderMap.FRAME_Y_OFFSET,
	}

	optionsTable.frameStrata = {
		type = "select",
		name = ns.L["Frame Strata"],
		values = frameStrataOptions,
		sorting = frameStrataSorting,
		set = "SetFrameStrata",
		get = "GetFrameStrata",
		disabled = "IsPositionOverrideDisabled",
		order = orderMap.FRAME_STRATA,
	}

	optionsTable.frameLevel = {
		type = "range",
		name = ns.L["Frame Level"],
		min = 0,
		max = 10000,
		step = 1,
		bigStep = 10,
		set = "SetFramePositionLevel",
		get = "GetFramePositionLevel",
		disabled = "IsPositionOverrideDisabled",
		order = orderMap.FRAME_POSITION_LEVEL,
	}
end

---@class FramePositionableHandler: MixinBase
---@field framePositionRelativeToOptions table<string, string>?
---@field framePositionRelativeToSorting string[]?
---@field ApplyFramePosition fun(self: FramePositionableHandler)
---@field ResetFramePosition fun(self: FramePositionableHandler)

---@class FramePositionable: FramePositionableHandler
local FramePositionable = {}

ns.Mixin(FramePositionable, ns.MixinBase)

-- Enable/disable toggle

function FramePositionable:SetEnablePositionOverride(info, value)
	self:DbSet("enablePositionOverride", value)
	if value then
		self:ApplyFramePosition()
	else
		self:ResetFramePosition()
	end
end

function FramePositionable:GetEnablePositionOverride(info)
	return self:DbGet("enablePositionOverride")
end

function FramePositionable:IsPositionOverrideDisabled(info)
	return not self:DbGet("enablePositionOverride")
end

-- Anchor point

function FramePositionable:SetFrameAnchorPoint(info, value)
	self:DbSet("anchorPoint", value)
	self:ApplyFramePosition()
end

function FramePositionable:GetFrameAnchorPoint(info)
	return self:DbGet("anchorPoint")
end

-- Relative to

function FramePositionable:SetFrameRelativeTo(info, value)
	self:DbSet("relativeTo", value)
	self:ApplyFramePosition()
end

function FramePositionable:GetFrameRelativeTo(info)
	return self:DbGet("relativeTo")
end

function FramePositionable:GetFrameRelativeToOptions()
	if self.framePositionRelativeToOptions then
		return self.framePositionRelativeToOptions
	end
	return ns.Positionable.anchorRelativeToOptions
end

function FramePositionable:GetFrameRelativeToSorting()
	if self.framePositionRelativeToOptions and self.framePositionRelativeToSorting then
		return self.framePositionRelativeToSorting
	end
	return ns.Positionable.anchorRelativeToSort
end

-- Relative point

function FramePositionable:SetFrameRelativePoint(info, value)
	self:DbSet("relativePoint", value)
	self:ApplyFramePosition()
end

function FramePositionable:GetFrameRelativePoint(info)
	return self:DbGet("relativePoint")
end

-- X/Y offsets

function FramePositionable:SetFrameXOffset(info, value)
	self:DbSet("xOffset", value)
	self:ApplyFramePosition()
end

function FramePositionable:GetFrameXOffset(info)
	return self:DbGet("xOffset")
end

function FramePositionable:SetFrameYOffset(info, value)
	self:DbSet("yOffset", value)
	self:ApplyFramePosition()
end

function FramePositionable:GetFrameYOffset(info)
	return self:DbGet("yOffset")
end

-- Frame strata

function FramePositionable:SetFrameStrata(info, value)
	self:DbSet("frameStrata", value)
	self:ApplyFramePosition()
end

function FramePositionable:GetFrameStrata(info)
	return self:DbGet("frameStrata")
end

-- Frame level

function FramePositionable:SetFramePositionLevel(info, value)
	self:DbSet("frameLevel", value)
	self:ApplyFramePosition()
end

function FramePositionable:GetFramePositionLevel(info)
	return self:DbGet("frameLevel")
end

--- Apply the frame position override to the target frame.
--- The consuming handler must set self.frame before calling this.
--- @param targetFrame Frame The WoW frame to position
function FramePositionable:_ApplyFramePosition(targetFrame)
	if not targetFrame then
		return
	end

	local anchorPoint = self:GetFrameAnchorPoint() or "TOPLEFT"
	local relativeToKey = self:GetFrameRelativeTo()
	local relativePoint = self:GetFrameRelativePoint() or anchorPoint
	local xOffset = self:GetFrameXOffset() or 0
	local yOffset = self:GetFrameYOffset() or 0
	local strata = self:GetFrameStrata()
	local level = self:GetFramePositionLevel()

	local relFrame
	if relativeToKey then
		relFrame = ns.GetRelativeFrame(relativeToKey)
	end
	if not relFrame then
		relFrame = _G.UIParent
	end

	targetFrame:ClearAllPoints()
	targetFrame:SetPoint(anchorPoint, relFrame, relativePoint, xOffset, yOffset)

	if strata then
		targetFrame:SetFrameStrata(strata)
	end

	if level then
		if targetFrame.IsUsingParentLevel and targetFrame:IsUsingParentLevel() then
			targetFrame:SetUsingParentLevel(false)
		end
		targetFrame:SetFrameLevel(level)
	end
end

ns.FramePositionable = FramePositionable
