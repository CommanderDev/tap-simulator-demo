--!strict
-- RoutingRegistry
-- Author(s): Jesse Appleton
-- Date: 01/11/2026

---------------------------------------------------------------------

export type CapabilitySpec = {
	type: string,
	trigger: any,
	tags: { string }?,
	params: { [string]: any }?,
	filters: any?,
}

export type RoutingRegistry = {
	GetPhase: (self: RoutingRegistry, phaseName: string) -> { CapabilitySpec },
	GetEvent: (self: RoutingRegistry, eventName: string) -> { CapabilitySpec },
	Passes: (self: RoutingRegistry, cap: CapabilitySpec, payload: any) -> boolean,
	GetEvaluator: (self: RoutingRegistry) -> any,
	RegisterOp: (op: string, fn: any) -> (),
}

---------------------------------------------------------------------

local PhaseRouter = require(script.Parent.PhaseRouter)
local EventRouter = require(script.Parent.EventRouter)
local FilterEvaluator = require(script.Parent.FilterEvaluator)

local RoutingRegistry = {}
RoutingRegistry.__index = RoutingRegistry

local _sharedEvaluator = nil

local function getSharedEvaluator()
	if _sharedEvaluator then
		return _sharedEvaluator
	end
	_sharedEvaluator = FilterEvaluator.new()
	return _sharedEvaluator
end

function RoutingRegistry.RegisterOp(op: string, fn: any)
	getSharedEvaluator():Register(op, fn)
end

function RoutingRegistry.new(capabilities: { CapabilitySpec }, evaluatorOverride: any?): RoutingRegistry
	local self = setmetatable({}, RoutingRegistry)

	self._phaseRouter = PhaseRouter.new()
	self._eventRouter = EventRouter.new()

	self._evaluator = evaluatorOverride or getSharedEvaluator()

	self._phaseRouter:RegisterAll(capabilities)
	self._eventRouter:RegisterAll(capabilities)

	return (self :: any)
end

function RoutingRegistry:GetPhase(phaseName: string): { CapabilitySpec }
	return self._phaseRouter:Get(phaseName)
end

function RoutingRegistry:GetEvent(eventName: string): { CapabilitySpec }
	return self._eventRouter:Get(eventName)
end

function RoutingRegistry:Passes(cap: CapabilitySpec, payload: any): boolean
	return self._evaluator:Passes(cap.filters, payload, nil)
end

function RoutingRegistry:GetEvaluator()
	return self._evaluator
end

return RoutingRegistry
