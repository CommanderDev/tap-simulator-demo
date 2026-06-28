--!strict
-- PhaseRouter
-- Author(s): Jesse Appleton
-- Date: 01/11/2026

--[[
    Routes phases to the appropriate handlers.
]]

export type TriggerMatch = "exact" | "wildcard"

export type Trigger = {
    phase: string,
    match: TriggerMatch?,
}

export type CapabilitySpec = {
    type: string,
    trigger: any,
    tags: { string }?,
    params: { [string]: any }?,
}

export type PhaseRouter = {
    Register: (self: PhaseRouter, cap: CapabilitySpec) -> (),
    RegisterAll: (self: PhaseRouter, caps: { CapabilitySpec }) -> (),
    Get: (self: PhaseRouter, trigger: Trigger, phaseName: string) -> { CapabilitySpec }?,
    Clear: (self: PhaseRouter) -> (),
}

local PhaseRouter = {}
PhaseRouter.__index = PhaseRouter

local function getMatch(trigger: any): TriggerMatch
	local m = trigger.match
	if m == nil then
		return "exact"
	end
	return m
end

local function addAll(dst: { CapabilitySpec }, src: { CapabilitySpec })
	for i = 1, #src do
		dst[#dst + 1] = src[i]
	end
end

function PhaseRouter.new(): PhaseRouter
	local self = setmetatable( {}, PhaseRouter )

	self._exact = {} :: { [string]: { CapabilitySpec } }
	self._wildcard = {} :: { [string]: { CapabilitySpec } }

	return (self :: any)
end

function PhaseRouter:Clear()
	table.clear(self._exact)
	table.clear(self._wildcard)
end

function PhaseRouter:Register(cap: CapabilitySpec)
	local trig = cap.trigger
	if type(trig) ~= "table" then
		return
	end

	local phaseName = trig.phase
	if type(phaseName) ~= "string" then
		return
	end

	local match = getMatch(trig)

	if match == "exact" then
		local list = self._exact[phaseName]
		if not list then
			list = {}
			self._exact[phaseName] = list
		end
		list[#list + 1] = cap
		return
	end

	if match == "wildcard" then
		self._wildcard[#self._wildcard + 1] = cap
		return
	end

	error(("[PhaseRouter] Unknown trigger.match '%s'"):format(tostring(match)))
end

function PhaseRouter:RegisterAll(caps: { CapabilitySpec })
	for i = 1, #caps do
		self:Register(caps[i])
	end
end

function PhaseRouter:Get(phaseName: string): { CapabilitySpec }
	local out = {} :: { CapabilitySpec }

	local exactList = self._exact[phaseName]
	if exactList then
		addAll(out, exactList)
	end

	if #self._wildcard > 0 then
		addAll(out, self._wildcard)
	end

	return out
end

return PhaseRouter