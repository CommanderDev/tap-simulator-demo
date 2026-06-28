--!strict
-- FilterEvaluator
-- Author(s): Jesse Appleton
-- Date: 01/11/2026

--[[
    Generic filter evaluation for routed specs
]]

export type Filters = {
    op: string,
    path: string?,
    value: any?,
    values: { any }?,
}

export type FilterList = { Filter }

export type EvalContext = {}

export type OpFn = (payload: any, filter: Filter, context: EvalContext) -> boolean

export type FilterEvaluator = {
    Register: (self: FilterEvaluator, op: string, fn: OpFn) -> (),
    Passes: (self: FilterEvaluator, filters: FilterList, payload: any, context: EvalContext) -> boolean,
    GetOps: (self: FilterEvaluator) -> { [string]: OpFn },
}

local FilterEvaluator = {}
FilterEvaluator.__index = FilterEvaluator

local function readPath(payload: any, path: string): any
    local cur = payload
	for key in string.gmatch(path, "[^%.]+") do
        if type(cur) ~= "table" then 
            return nil
        end
        cur = cur[key]
    end

    return cur
end

local function isArray(t: any): boolean
    if type(t) ~= "table" then return false end
    
    return t[1] ~= nil
end

local function arrayHas(list: any, value: any): boolean
    if type(list) ~= "table" then return false end
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

function FilterEvaluator.new(): FilterEvaluator
    local self = setmetatable( {}, FilterEvaluator )
    self._ops = {}

    self._ops["eq"] = function(payload, filter)
        local v = filter.path and readPath(payload, filter.path) or payload
        return v == filter.value
    end

    self._ops["neq"] = function(payload, filter)
        local v = filter.path and readPath(payload, filter.path) or payload
        return v ~= filter.value
    end

    self._ops["num.gte"] = function(payload, filter)
        local v = filter.path and readPath(payload, filter.path) or payload
        return type(v) == "number" and type(filter.value) == "number" and v >= filter.value
    end

    self._ops["num.lte"] = function(payload, filter)
		local v = filter.path and readPath(payload, filter.path) or nil
		return type(v) == "number" and type(filter.value) == "number" and v <= filter.value
	end

    self._ops["num.between"] = function(payload, filter)
		local v = filter.path and readPath(payload, filter.path) or nil
		local vals = filter.values
		if type(v) ~= "number" or type(vals) ~= "table" then return false end
		local a, b = vals[1], vals[2]
		return type(a) == "number" and type(b) == "number" and v >= a and v <= b
	end
    
    self._ops["str.contains"] = function(payload, filter)
		local v = filter.path and readPath(payload, filter.path) or nil
		if type(v) ~= "string" or type(filter.value) ~= "string" then return false end
		return string.find(v, filter.value, 1, true) ~= nil
	end

    self._ops["arr.has"] = function(payload, filter)
		local v = filter.path and readPath(payload, filter.path) or nil
		return arrayHas(v, filter.value)
	end

	self._ops["arr.missing"] = function(payload, filter)
		local v = filter.path and readPath(payload, filter.path) or nil
		return not arrayHas(v, filter.value)
	end

    self._ops["arr.hasAny"] = function(payload, filter)
		local v = filter.path and readPath(payload, filter.path) or nil
		local vals = filter.values
		if type(vals) ~= "table" or type(v) ~= "table" then return false end
		for _, want in ipairs(vals) do
			if arrayHas(v, want) then
				return true
			end
		end
		return false
	end

    self._ops["arr.hasAll"] = function(payload, filter)
		local v = filter.path and readPath(payload, filter.path) or nil
		local vals = filter.values
		if type(vals) ~= "table" or type(v) ~= "table" then return false end
		for _, want in ipairs(vals) do
			if not arrayHas(v, want) then
				return false
			end
		end
		return true
	end

    return (self :: any)
end

function FilterEvaluator:Register(op: string, fn: OpFn)
    assert(type(op) == "string", "op must be a string")
    assert(type(fn) == "function", "fn must be a function")
    self._ops[op] = fn
end

function FilterEvaluator:GetOps(): ()
    return self._ops
end

function FilterEvaluator:Passes(filters: FilterList, payload: any, context: EvalContext): boolean
    if filters == nil then
        return true
    end

    if type(filters) == "table" and not isArray(filters) and (filters :: any).op ~= nil then
        filters ={ { filters :: any }}
    end

    if type(filters) ~= "table" then 
        return true
    end

    for _, f in ipairs(filters :: any) do 
        if type(f) ~= "table" then 
            return false
        end

        local op = f.op
        local fn = self._ops[op]
        if not fn then 
            return false
        end

        if fn(payload, f, context) ~= true then 
            return false
        end
    end

    return true
end

return FilterEvaluator