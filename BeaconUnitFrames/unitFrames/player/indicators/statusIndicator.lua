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
local BUFPlayerStatusIndicator = {}

-- Shared pulse state. `alpha` is what child indicators multiply onto their
-- texture's alpha when their `pulse` toggle is on.
BUFPlayerStatusIndicator.pulse = {
	counter = 0,
	sign = -1,
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

local function TickPulse(self, elapsed)
	local p = self.pulse
	p.counter = p.counter + (elapsed or 0)
	if p.counter > 0.5 then
		p.sign = -p.sign
	end
	p.counter = math.fmod(p.counter, 0.5)

	local alpha
	if p.sign == 1 then
		alpha = (55 + (p.counter * 400)) / 255
	else
		alpha = (255 - (p.counter * 400)) / 255
	end
	-- Floor so the indicator never fully disappears mid-pulse.
	if alpha < 0.4 then
		alpha = 0.4
	end
	p.alpha = alpha

	for _, sub in ipairs(self.subscribers) do
		if sub.OnPulse then
			sub:OnPulse(alpha)
		end
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
		driver:SetScript("OnUpdate", function(_, elapsed)
			TickPulse(BUFPlayerStatusIndicator, elapsed)
		end)
		self.driver = driver
	end

	if self.Portrait then
		self.Portrait:RefreshConfig()
	end
	if self.Name then
		self.Name:RefreshConfig()
	end
end

BUFPlayerIndicators.StatusIndicator = BUFPlayerStatusIndicator
