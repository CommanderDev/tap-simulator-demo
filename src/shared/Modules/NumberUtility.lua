-- NumberUtility
--  Author(s): Jesse Appleton
-- Date: 04/15/2026

local NumberUtility = {}

local SUFFIXES = {
	{ Value = 1e63, Suffix = "Vg" },
	{ Value = 1e60, Suffix = "Nd" },
	{ Value = 1e57, Suffix = "Od" },
	{ Value = 1e54, Suffix = "Spd" },
	{ Value = 1e51, Suffix = "Sxd" },
	{ Value = 1e48, Suffix = "Qid" },
	{ Value = 1e45, Suffix = "Qad" },
	{ Value = 1e42, Suffix = "Td" },
	{ Value = 1e39, Suffix = "Dd" },
	{ Value = 1e36, Suffix = "Ud" },
	{ Value = 1e33, Suffix = "Dc" },
	{ Value = 1e30, Suffix = "No" },
	{ Value = 1e27, Suffix = "Oc" },
	{ Value = 1e24, Suffix = "Sp" },
	{ Value = 1e21, Suffix = "Sx" },
	{ Value = 1e18, Suffix = "Qi" },
	{ Value = 1e15, Suffix = "Qa" },
	{ Value = 1e12, Suffix = "T" },
	{ Value = 1e9, Suffix = "B" },
	{ Value = 1e6, Suffix = "M" },
	{ Value = 1e3, Suffix = "K" },
}

local function isFinite(value)
	return value == value and value ~= math.huge and value ~= -math.huge
end

function NumberUtility.ToNumber(value, defaultValue)
	local num = tonumber(value)
	if num == nil then
		return defaultValue or 0
	end
	return num
end

function NumberUtility.IsFinite(value)
	return typeof(value) == "number" and isFinite(value)
end

function NumberUtility.Round(value, decimals)
	value = NumberUtility.ToNumber(value, 0)
	decimals = math.max(0, NumberUtility.ToNumber(decimals, 0))

	local multiplier = 10 ^ decimals
	return math.round(value * multiplier) / multiplier
end

function NumberUtility.Floor(value, decimals)
	value = NumberUtility.ToNumber(value, 0)
	decimals = math.max(0, NumberUtility.ToNumber(decimals, 0))

	local multiplier = 10 ^ decimals
	return math.floor(value * multiplier) / multiplier
end

function NumberUtility.Ceil(value, decimals)
	value = NumberUtility.ToNumber(value, 0)
	decimals = math.max(0, NumberUtility.ToNumber(decimals, 0))

	local multiplier = 10 ^ decimals
	return math.ceil(value * multiplier) / multiplier
end

function NumberUtility.Clamp(value, minValue, maxValue)
	value = NumberUtility.ToNumber(value, 0)
	minValue = NumberUtility.ToNumber(minValue, value)
	maxValue = NumberUtility.ToNumber(maxValue, value)

	return math.clamp(value, minValue, maxValue)
end

function NumberUtility.TrimTrailingZeroes(valueString)
	valueString = tostring(valueString)

	if not string.find(valueString, "%.") then
		return valueString
	end

	valueString = string.gsub(valueString, "0+$", "")
	valueString = string.gsub(valueString, "%.$", "")

	return valueString
end

function NumberUtility.ToFixed(value, decimals)
	value = NumberUtility.ToNumber(value, 0)
	decimals = math.max(0, NumberUtility.ToNumber(decimals, 0))

	return string.format("%." .. decimals .. "f", value)
end

function NumberUtility.ToCleanFixed(value, decimals)
	return NumberUtility.TrimTrailingZeroes(NumberUtility.ToFixed(value, decimals))
end

function NumberUtility.AddCommas(value)
	value = NumberUtility.ToNumber(value, 0)

	local sign = value < 0 and "-" or ""
	local absValue = math.abs(value)

	local integerPart, decimalPart = tostring(absValue):match("^(%d+)(%.%d+)?$")
	integerPart = integerPart or "0"
	decimalPart = decimalPart or ""

	while true do
		local formatted, count = string.gsub(integerPart, "^(-?%d+)(%d%d%d)", "%1,%2")
		integerPart = formatted
		if count == 0 then
			break
		end
	end

	return sign .. integerPart .. decimalPart
end

function NumberUtility.FormatWithCommas(value, decimals)
	value = NumberUtility.ToNumber(value, 0)
	decimals = NumberUtility.ToNumber(decimals, nil)

	if decimals ~= nil then
		value = NumberUtility.Round(value, decimals)
		local formatted = NumberUtility.ToFixed(value, decimals)
		local integerPart, decimalPart = formatted:match("^(%-?%d+)(%.%d+)?$")
		decimalPart = decimalPart or ""

		local sign = ""
		if string.sub(integerPart, 1, 1) == "-" then
			sign = "-"
			integerPart = string.sub(integerPart, 2)
		end

		while true do
			local result, count = string.gsub(integerPart, "^(%d+)(%d%d%d)", "%1,%2")
			integerPart = result
			if count == 0 then
				break
			end
		end

		return sign .. integerPart .. decimalPart
	end

	return NumberUtility.AddCommas(value)
end

function NumberUtility.Abbreviate(value, decimals)
	value = NumberUtility.ToNumber(value, 0)
	decimals = math.max(0, NumberUtility.ToNumber(decimals, 1))

	if not isFinite(value) then
		return "0"
	end

	local sign = value < 0 and "-" or ""
	local absValue = math.abs(value)

	if absValue < 1000 then
		return sign .. NumberUtility.ToCleanFixed(absValue, decimals)
	end

	for _, suffixData in ipairs(SUFFIXES) do
		if absValue >= suffixData.Value then
			local shortened = absValue / suffixData.Value
			return sign .. NumberUtility.ToCleanFixed(shortened, decimals) .. suffixData.Suffix
		end
	end

	return sign .. tostring(value)
end

function NumberUtility.AbbreviateFloor(value, decimals)
	value = NumberUtility.ToNumber(value, 0)
	decimals = math.max(0, NumberUtility.ToNumber(decimals, 1))

	if not isFinite(value) then
		return "0"
	end

	local sign = value < 0 and "-" or ""
	local absValue = math.abs(value)

	if absValue < 1000 then
		return sign .. NumberUtility.ToCleanFixed(absValue, decimals)
	end

	for _, suffixData in ipairs(SUFFIXES) do
		if absValue >= suffixData.Value then
			local shortened = NumberUtility.Floor(absValue / suffixData.Value, decimals)
			return sign .. NumberUtility.ToCleanFixed(shortened, decimals) .. suffixData.Suffix
		end
	end

	return sign .. tostring(value)
end

function NumberUtility.ToCurrency(value, currencySymbol, decimals, useAbbreviation)
	value = NumberUtility.ToNumber(value, 0)
	currencySymbol = currencySymbol or "$"
	decimals = NumberUtility.ToNumber(decimals, 2)

	local sign = value < 0 and "-" or ""
	local absValue = math.abs(value)

	if useAbbreviation then
		return sign .. currencySymbol .. NumberUtility.Abbreviate(absValue, decimals)
	end

	return sign .. currencySymbol .. NumberUtility.FormatWithCommas(absValue, decimals)
end

function NumberUtility.ToPercent(value, decimals, alreadyPercent)
	value = NumberUtility.ToNumber(value, 0)
	decimals = math.max(0, NumberUtility.ToNumber(decimals, 0))

	if not alreadyPercent then
		value = value * 100
	end

	return NumberUtility.ToCleanFixed(value, decimals) .. "%"
end

function NumberUtility.Ordinal(value)
	value = math.floor(NumberUtility.ToNumber(value, 0))

	local absValue = math.abs(value)
	local lastTwo = absValue % 100
	local lastOne = absValue % 10

	if lastTwo >= 11 and lastTwo <= 13 then
		return tostring(value) .. "th"
	end

	if lastOne == 1 then
		return tostring(value) .. "st"
	elseif lastOne == 2 then
		return tostring(value) .. "nd"
	elseif lastOne == 3 then
		return tostring(value) .. "rd"
	else
		return tostring(value) .. "th"
	end
end

function NumberUtility.FormatDuration(seconds)
	seconds = math.max(0, math.floor(NumberUtility.ToNumber(seconds, 0)))

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local remainingSeconds = seconds % 60

	if hours > 0 then
		return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
	end

	return string.format("%02d:%02d", minutes, remainingSeconds)
end

function NumberUtility.FormatDurationWords(seconds)
	seconds = math.max(0, math.floor(NumberUtility.ToNumber(seconds, 0)))

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local remainingSeconds = seconds % 60

	local parts = {}

	if days > 0 then
		table.insert(parts, days .. "d")
	end
	if hours > 0 then
		table.insert(parts, hours .. "h")
	end
	if minutes > 0 then
		table.insert(parts, minutes .. "m")
	end
	if remainingSeconds > 0 or #parts == 0 then
		table.insert(parts, remainingSeconds .. "s")
	end

	return table.concat(parts, " ")
end

function NumberUtility.GetSuffix(value)
	value = math.abs(NumberUtility.ToNumber(value, 0))

	for _, suffixData in ipairs(SUFFIXES) do
		if value >= suffixData.Value then
			return suffixData.Suffix
		end
	end

	return ""
end

function NumberUtility.Format(value, options)
	options = options or {}

	local style = options.Style or "Abbreviated"
	local decimals = options.Decimals
	local currencySymbol = options.CurrencySymbol or "$"

	if style == "Commas" then
		return NumberUtility.FormatWithCommas(value, decimals)
	elseif style == "Currency" then
		return NumberUtility.ToCurrency(
			value,
			currencySymbol,
			decimals or 2,
			options.Abbreviate == true
		)
	elseif style == "Percent" then
		return NumberUtility.ToPercent(value, decimals or 0, options.AlreadyPercent == true)
	elseif style == "Duration" then
		return NumberUtility.FormatDuration(value)
	elseif style == "DurationWords" then
		return NumberUtility.FormatDurationWords(value)
	elseif style == "Ordinal" then
		return NumberUtility.Ordinal(value)
	elseif style == "Fixed" then
		return NumberUtility.ToFixed(value, decimals or 0)
	elseif style == "CleanFixed" then
		return NumberUtility.ToCleanFixed(value, decimals or 0)
	else
		return NumberUtility.Abbreviate(value, decimals or 1)
	end
end

return NumberUtility