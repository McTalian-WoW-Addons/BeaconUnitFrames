---@class BUFNamespace
local ns = select(2, ...)

---@class BUFPlayer
local BUFPlayer = ns.BUFPlayer

---@class BUFPlayer.Indicators
local BUFPlayerIndicators = ns.BUFPlayer.Indicators

---@class BUFPlayer.Indicators.StatusIndicator
---
--- Coordinator for the player's portrait and name status indicators.
--- Owns the single OnUpdate driver that produces a shared `pulseAlpha`
--- value, so both child indicators pulse in phase.
---
--- This module is intentionally lightweight: it has no DB schema of its
--- own, only the parent options group + the pulse loop. All visual /
--- color / enable state lives on the two child handlers.
---
--- **Subscriber Contract:**
--- - Call Subscribe() to register for pulse updates.
--- - Implement IsPulseNeeded() to return true when this subscriber wants pulsing.
--- - Call UpdatePulseState() after changing pulse settings so the driver can start/stop.
--- - Define OnPulse(alpha) to receive per-frame pulse alpha values when active.
local BUFPlayerStatusIndicator = {}

-- Shared pulse state. `alpha` is what child indicators multiply onto their
-- texture's alpha when their `pulse` toggle is on.
BUFPlayerStatusIndicator.pulse = {
	counter = 0,
	alpha = 1,
}

-- Subscribers receive the current pulse alpha each frame. Using a list
-- (rather than hard-coded calls into Portrait/Name) keeps the coordinator
-- decoupled and trivial to extend later.
BUFPlayerStatusIndicator.subscribers = {}

function BUFPlayerStatusIndicator:Subscribe(handler)
	table.insert(self.subscribers, handler)
end

function BUFPlayerStatusIndicator:GetPulseAlpha()
	return self.pulse.alpha
end

--- Check if any subscriber has pulse enabled and start/stop the driver accordingly.
function BUFPlayerStatusIndicator:UpdatePulseState()
	if not self.driver or self.updatingPulseState then
		return
	end

	-- Guard against recursive calls during initialization
	self.updatingPulseState = true

	local anyPulsing = false
	for _, sub in ipairs(self.subscribers) do
		-- Check if subscriber implements IsPulseNeeded() callback (new pattern).
		if sub.IsPulseNeeded then
			if sub:IsPulseNeeded() then
				anyPulsing = true
				break
			end
		-- Fallback: check if subscriber has GetPulse() and it's enabled.
		elseif sub.GetPulse then
			if sub:GetPulse() then
				anyPulsing = true
				break
			end
		end
	end

	if anyPulsing then
		self:_StartDriver()
	else
		self:_StopDriver()
	end

	self.updatingPulseState = false
end

local function TickPulse(self, elapsed)
	local p = self.pulse
	-- Increment a counter that represents position in the pulse cycle.
	-- Full cycle is 2 seconds (up and down breathing motion).
	p.counter = p.counter + (elapsed or 0)
	p.counter = math.fmod(p.counter, 2.0)

	-- Normalize counter to 0-1 range over the full 2-second cycle
	local t = p.counter / 2.0

	-- Apply ease-in-out sine easing for a smooth, natural breathing effect.
	-- This creates a single continuous wave: fade in, fade out, repeat.
	-- The formula produces a full sine wave cycle (0 → 1 → 0) over the period.
	local easedT = 0.5 * (1 - math.cos(t * math.pi * 2))

	-- Map eased value to alpha range [0.4, 1.0]
	-- 0.4 floor prevents the indicator from ever fully disappearing mid-pulse.
	local alpha = 0.4 + (easedT * 0.6)

	p.alpha = alpha

	for _, sub in ipairs(self.subscribers) do
		if sub.OnPulse then
			sub:OnPulse(alpha)
		end
	end
end

--- Start the OnUpdate driver if not already running.
function BUFPlayerStatusIndicator:_StartDriver()
	if not self.driverActive then
		self.driver:SetScript("OnUpdate", function(_, elapsed)
			TickPulse(self, elapsed)
		end)
		self.driverActive = true
	end
end

--- Stop the OnUpdate driver.
function BUFPlayerStatusIndicator:_StopDriver()
	if self.driverActive then
		self.driver:SetScript("OnUpdate", nil)
		self.driverActive = false
	end
end

-- Parent options group. Children (`portrait`, `name`) are inserted by their
-- respective modules so they render as nested subgroups.
BUFPlayerStatusIndicator.optionsTable = {
	type = "group",
	name = ns.L["Status Indicator"],
	order = BUFPlayerIndicators.optionsOrder.STATUS_INDICATOR,
	childGroups = "tab",
	args = {},
}

ns.options.args.player.args.indicators.args.statusIndicator = BUFPlayerStatusIndicator.optionsTable

function BUFPlayerStatusIndicator:RefreshConfig()
	if not self.initialized then
		self.initialized = true

		-- Single OnUpdate driver shared by both child indicators. Using a
		-- standalone Frame avoids the XML-captured-reference pitfall of
		-- hooksecurefunc("PlayerFrame_OnUpdate", ...).
		local driver = CreateFrame("Frame")
		-- Start in stopped state; UpdatePulseState will start it if needed.
		self.driver = driver
		self.driverActive = false
	end

	if self.Portrait then
		self.Portrait:RefreshConfig()
	end
	if self.Name then
		self.Name:RefreshConfig()
	end

	-- Evaluate pulse state after child configs are refreshed so we know what's enabled.
	self:UpdatePulseState()
end

BUFPlayerIndicators.StatusIndicator = BUFPlayerStatusIndicator
