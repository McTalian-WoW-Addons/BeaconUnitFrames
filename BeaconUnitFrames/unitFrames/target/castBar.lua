---@class BUFNamespace
local ns = select(2, ...)

---@class BUFTarget
local BUFTarget = ns.BUFTarget

---@class BUFTarget.CastBar: FramePositionable
local CastBar = {
	configPath = "unitFrames.target.castBar",
}

ns.Mixin(CastBar, ns.FramePositionable)

CastBar.optionsTable = {
	type = "group",
	handler = CastBar,
	name = ns.L["CastBar"],
	order = BUFTarget.optionsOrder.CAST_BAR,
	args = {},
}

---@class BUFDbSchema.UF.Target.CastBar
CastBar.dbDefaults = {
	enablePositionOverride = false,
	anchorPoint = "TOPLEFT",
	relativeTo = ns.Positionable.relativeToFrames.TARGET_FRAME,
	relativePoint = "BOTTOMLEFT",
	xOffset = 43,
	yOffset = 5,
	frameStrata = "MEDIUM",
	frameLevel = 0,
}

ns.AddFramePositionableOptions(CastBar.optionsTable.args)

---@class BUFDbSchema.UF.Target
ns.dbDefaults.profile.unitFrames.target = ns.dbDefaults.profile.unitFrames.target
ns.dbDefaults.profile.unitFrames.target.castBar = CastBar.dbDefaults

ns.options.args.target.args.castBar = CastBar.optionsTable

function CastBar:RefreshConfig()
	if not self.initialized then
		BUFTarget.FrameInit(self)
		self.framePositionRelativeToOptions = {
			[ns.Positionable.relativeToFrames.UI_PARENT] = ns.L["UIParent"],
			[ns.Positionable.relativeToFrames.TARGET_FRAME] = HUD_EDIT_MODE_TARGET_FRAME_LABEL,
			[ns.Positionable.relativeToFrames.TARGET_HEALTH_BAR] = ns.L["TargetHealthBar"],
			[ns.Positionable.relativeToFrames.TARGET_POWER_BAR] = ns.L["TargetManaBar"],
		}
		self.framePositionRelativeToSorting = {
			ns.Positionable.relativeToFrames.UI_PARENT,
			ns.Positionable.relativeToFrames.TARGET_FRAME,
			ns.Positionable.relativeToFrames.TARGET_HEALTH_BAR,
			ns.Positionable.relativeToFrames.TARGET_POWER_BAR,
		}
	end

	-- The spellbar is created dynamically via CreateSpellbar in TargetFrame's OnLoad
	self.frame = BUFTarget.frame.spellbar

	self:ApplyFramePosition()
end

function CastBar:ApplyFramePosition()
	if not self:GetEnablePositionOverride() then
		-- Remove our hooks so Blizzard can manage placement
		if BUFTarget:IsHooked(self.frame, "AdjustPosition") then
			BUFTarget:Unhook(self.frame, "AdjustPosition")
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
	if not BUFTarget:IsHooked(self.frame, "AdjustPosition") then
		BUFTarget:SecureHook(self.frame, "AdjustPosition", function()
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
	if BUFTarget:IsHooked(self.frame, "AdjustPosition") then
		BUFTarget:Unhook(self.frame, "AdjustPosition")
	end
	if self._onShowHooked then
		self._onShowHooked = false
	end
	if self.frame and self.frame.AdjustPosition then
		self.frame:AdjustPosition()
	end
end

BUFTarget.CastBar = CastBar
