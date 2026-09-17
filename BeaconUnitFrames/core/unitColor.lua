---@class BUFNamespace
local ns = select(2, ...)

-- UnitClass is identity-restricted, so it needs an ns.IsUnitIdentitySecret guard.
-- UnitSelectionColor carries no such flag and stays usable from tainted execution.

---Class color of a unit, nil when the class cannot be read.
---@param unit string?
---@return number? r, number? g, number? b
function ns.GetUnitClassColor(unit)
	if not unit or ns.IsUnitIdentitySecret(unit) then
		return nil
	end

	local _, class = UnitClass(unit)
	if not class then
		return nil
	end

	local r, g, b = GetClassColor(class)
	return r, g, b
end

---Reaction color of a unit, the same source Blizzard's own frames use.
---@param unit string?
---@return number? r, number? g, number? b
function ns.GetUnitReactionColor(unit)
	if not unit or not UnitExists(unit) then
		return nil
	end

	local r, g, b = UnitSelectionColor(unit)
	return r, g, b
end
