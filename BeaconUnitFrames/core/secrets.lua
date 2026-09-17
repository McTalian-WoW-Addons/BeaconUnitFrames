---@class BUFNamespace
local ns = select(2, ...)

-- Unit data is hidden from tainted execution ("secret values"). A secret value cannot be
-- used in a boolean test, compared, or used as a table key, so every query the API docs flag
-- as SecretWhen<Something>Restricted has to be guarded before its result is inspected.

---@param predicateName string
---@param ... any
---@return boolean
local function ShouldBeSecret(predicateName, ...)
	local predicate = C_Secrets and C_Secrets[predicateName]
	if not predicate then
		return false
	end

	return predicate(...)
end

---Whether identity queries (UnitClass, UnitIsPVP, ...) return secret values for this unit.
---@param unit string?
---@return boolean
function ns.IsUnitIdentitySecret(unit)
	if not unit then
		return false
	end

	return ShouldBeSecret("ShouldUnitIdentityBeSecret", unit)
end

---Whether comparisons between two units (UnitIsUnit, ...) return secret values.
---@param unit string?
---@param otherUnit string?
---@return boolean
function ns.IsUnitComparisonSecret(unit, otherUnit)
	if not unit or not otherUnit then
		return false
	end

	return ShouldBeSecret("ShouldUnitComparisonBeSecret", unit, otherUnit)
end

---Whether threat queries (UnitThreatSituation, ...) return secret values for this unit.
---@param unit string?
---@param mobUnit string?
---@return boolean
function ns.IsUnitThreatStateSecret(unit, mobUnit)
	if not unit then
		return false
	end

	return ShouldBeSecret("ShouldUnitThreatStateBeSecret", unit, mobUnit)
end
