-- WeightedChoice
-- Author(s): Jesse Appleton
-- Date: 01/11/2026

--[[
    Weighted table RNG Utility
]]

---------------------------------------------------------------------

-- Types
export type RNG = Random
export type WeightGetter<T> = (item: T, index: number) -> number

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

-- Objects

---------------------------------------------------------------------

local WeightedChoice = {}


local function _clampWeight(w: number?): number
	if w == nil then
		return 0
	end
	if w ~= w or w == math.huge or w == -math.huge then
		return 0
	end
	if w <= 0 then
		return 0
	end
	return w
end

local function _defaultGetWeight<T>(item: T, _index: number): number
    return _clampWeight(item.weight)
end

local function _sumWeights<T>(list: { T }, getWeight: WeightGetter<T>): number
	local total = 0
	for i = 1, #list do
		total += _clampWeight(getWeight(list[i], i))
	end
	return total
end

local function _pickByRoll<T>(list: { T }, getWeight: WeightGetter<T>, roll: number): (T?, number?)
	local running = 0
	for i = 1, #list do
		local w = _clampWeight(getWeight(list[i], i))
		if w > 0 then
			running += w
			if roll <= running then
				return list[i], i
			end
		end
	end
	return nil, nil
end

function WeightedChoice.Pick<T>(list: { T }, getWeight: WeightGetter<T>?, rng: RNG?): (T?, number?)
    if #list == 0 then 
        return nil, nil
    end

    local getter = getWeight or _defaultGetWeight :: any
    local total = _sumWeights(list, getter)
    if total <= 0 then 
        return nil, nil
    end

    local r = (rng or Random.new()):NextNumber() * total

    if r <= 0 then 
        r = total
    end
    return _pickByRoll(list, getter, r)
end

function WeightedChoice.PickSeeded<T>(list: { T }, seed: number, getWeight: WeightGetter<T>?): (T?, number?)
    local rng = Random.new(seed)
    return WeightedChoice.Pick(list, getWeight, rng)
end

function WeightedChoice.PickIndex(weights: { number }, rng: RNG?): number?
    if #weights == 0 then 
        return nil
    end

    local total = 0
    for index = 1, #weights do 
        total += _clampWeight(weights[index])
    end
    if total <= 0 then 
        return nil
    end

    local r = (rng or Random.new()):NextNumber() * total
    if r <= 0 then 
        r = total
    end

    local running = 0
    for index = 1, #weights do
        local w = _clampWeight(weights[index])
        if w > 0 then
            running += w
            if r <= running then 
                return index
            end
        end
    end

    return nil
end

export type CompiledPicker<T> = {
    Pick: (self: CompiledPicker<T>, rng: RNG?) -> (T?, number?),
    TotalWeight: (self: CompiledPicker<T>) -> number,
}

function WeightedChoice.Compile<T>(list: { T }, getWeight: WeightGetter<T>?): CompiledPicker<T>
    local getter = getWeight or _defaultGetWeight :: any

    local cumulative: { number } = table.create(#list)
    local total = 0

    for i = 1, #list do 
        total += _clampWeight(getter(list[i], i))
        cumulative[i] = total
    end

    local compiled = {} :: any

    function compiled:TotalWeight(): number
        return total
    end

    function compiled:Pick(rng: RNG?): (T?, number?)
        if #list == 0 or total <= 0 then 
            return nil, nil
        end

        local r = (rng or Random.new()):NextNumber() * total
        if r <= 0 then 
            r = total
        end

        local low, high = 1, #cumulative
        while low < high do 
            local mid = math.floor((low + high) / 2)
            if r <= cumulative[mid] then 
                high = mid
            else
                low = mid + 1
            end
        end

        if cumulative[low] <= 0 then 
            return nil, nil
        end

        return list[low], low
    end

    return compiled :: CompiledPicker<T>
end

return WeightedChoice