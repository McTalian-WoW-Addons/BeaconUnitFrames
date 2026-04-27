---@class BUFNamespace
local ns = select(2, ...)

---@class BUFFocus
local BUFFocus = ns.BUFFocus

---@class BUFFocus.CastBar: FramePositionable
local CastBar = {
	configPath = "unitFrames.focus.castBar",
}

ns.Mixin(CastBar, ns.FramePositionable)

CastBar.optionsTable = {
	type = "group",
	handler = CastBar,
	name = ns.L["CastBar"],
	order = BUFFocus.optionsOrder.CAST_BAR,
	args = {},
}

---@class BUFDbSchema.UF.Focus.CastBar
CastBar.dbDefaults = {
	enablePositionOverride = false,
	anchorPoint = "TOPLEFT",
	relativeTo = ns.Positionable.relativeToFrames.FOCUS_FRAME,
	relativePoint = "BOTTOMLEFT",
	xOffset = 43,
	yOffset = 5,
	frameStrata = "MEDIUM",
	frameLevel = 0,
}

ns.AddFramePositionableOptions(CastBar.optionsTable.args)

---@class BUFDbSchema.UF.Focus
ns.dbDefaults.profile.unitFrames.focus = ns.dbDefaults.profile.unitFrames.focus
ns.dbDefaults.profile.unitFrames.focus.castBar = CastBar.dbDefaults

ns.options.args.focus.args.castBar = CastBar.optionsTable

function CastBar:RefreshConfig()
	if not self.initialized then
		BUFFocus.FrameInit(self)
		self.framePositionRelativeToOptions = {
			[ns.Positionable.relativeToFrames.UI_PARENT] = ns.L["UIParent"],
			[ns.Positionable.relativeToFrames.FOCUS_FRAME] = HUD_EDIT_MODE_FOCUS_FRAME_LABEL,
			[ns.Positionable.relativeToFrames.FOCUS_HEALTH_BAR] = ns.L["FocusHealthBar"],
			[ns.Positionable.relativeToFrames.FOCUS_POWER_BAR] = ns.L["FocusManaBar"],
		}
		self.framePositionRelativeToSorting = {
			ns.Positionable.relativeToFrames.UI_PARENT,
			ns.Positionable.relativeToFrames.FOCUS_FRAME,
			ns.Positionable.relativeToFrames.FOCUS_HEALTH_BAR,
			ns.Positionable.relativeToFrames.FOCUS_POWER_BAR,
		}
	end

	-- The spellbar is created dynamically via CreateSpellbar in FocusFrame's OnLoad
	self.frame = BUFFocus.frame.spellbar

	self:ApplyFramePosition()
end

function CastBar:ApplyFramePosition()
	if not self:GetEnablePositionOverride() then
		-- Remove our hooks so Blizzard can manage placement
		if BUFFocus:IsHooked(self.frame, "AdjustPosition") then
			BUFFocus:Unhook(self.frame, "AdjustPosition")
		end
		if self._onShowHooked then
			-- Can't unhook a HookScript; flag it to no-op instead
			self._onShowHooked = false
		end
		-- Let Blizzard recalculate position
		self.frame:AdjustPosition()
		return
	end

	self:_ApplyFramePosition(self.frame)

	-- SecureHook fires after Blizzard's AdjustPosition runs.
	-- _ApplyFramePosition calls ClearAllPoints before SetPoint,
	-- so it cleanly overrides whatever Blizzard just set.
	if not BUFFocus:IsHooked(self.frame, "AdjustPosition") then
		BUFFocus:SecureHook(self.frame, "AdjustPosition", function()
			self:_ApplyFramePosition(self.frame)
		end)
	end

	-- The XML template wires OnShow directly to AdjustPosition via
	-- <OnShow method="AdjustPosition"/>. HookScript appends after it,
	-- so Blizzard positions first, then we immediately override.
	if not self._onShowHooked then
		self._onShowHooked = true
		self.frame:HookScript("OnShow", function(s)
			if not self._onShowHooked then
				return
			end
			self:_ApplyFramePosition(s)
		end)
	end
end

function CastBar:ResetFramePosition()
	if BUFFocus:IsHooked(self.frame, "AdjustPosition") then
		BUFFocus:Unhook(self.frame, "AdjustPosition")
	end
	if self._onShowHooked then
		self._onShowHooked = false
	end
	if self.frame and self.frame.AdjustPosition then
		self.frame:AdjustPosition()
	end
end

BUFFocus.CastBar = CastBar
