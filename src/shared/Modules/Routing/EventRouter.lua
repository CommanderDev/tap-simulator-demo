--!strict
-- EventRouter
-- Author(s): Jesse Appleton
-- Date: 01/11/2026

--[[
    -- Routes events to the appropriate handlers.
]]

export type TriggerMatch = "exact" | "prefix" | "wildcard"

export type Trigger = {
    event: string,
    match: TriggerMatch?,
}

export type CapabilitySpec = {
    type: string,
    trigger: any,
    tags: { string }?,
    params: { [string]: any }?,
}

export type EventRouter = {
    Register: (self: EventRouter, cap: CapabilitySpec) -> (),
    RegisterAll: (self: EventRouter, caps: { CapabilitySpec }) -> (),
    Get: (self: EventRouter, trigger: Trigger, eventName: stirng) -> { CapabilitySpec }?,
    Clear: ( self: EventRouter ) -> (),
}

local EventRouter = {}
EventRouter.__index = EventRouter

local function getMatch(trigger: any): TriggerMatch
    local match = trigger.match
    if m == nil then 
        return "exact"
    end
    return match
end

local function addAll(dst: { CapabilitySpec }, src: { CapabilitySpec }): ()
    for index = 1, #src do 
        dst[#dst + 1] = src[index]
    end
end

local function iteratePrefixes(eventName: string, out: { string }): ()
    table.clear(out)

    local current = eventName
    while true do
        out[#out + 1] = current
		local lastOut = string.find(current, "%.[^%.]*$")
        if not lastOut then
            break
        end
        current = string.sub(current, 1, lastOut - 1)
    end
end

function EventRouter.new(): EventRouter
    local self = setmetatable( {}, EventRouter )

    self._exact = {} :: { [string]: { CapabilitySpec } }
    self._prefix = {} :: { [string]: { CapabilitySpec } }
    self._wildcard = {} :: { [string]: { CapabilitySpec } }

    self._prefixBuf = {} :: { string }

    return (self :: any)
end

function EventRouter:Clear(): ()
    table.clear(self._exact)
    table.clear(self._prefix)
    table.clear(self._wildcard)
end

function EventRouter:Register(cap: CapabilitySpec): ()
    local trig = cap.trigger
    if type(trig) ~= "table" then 
        return
    end

    local eventName = trig.event
    if type(eventName) ~= "string" then
        return
    end

    local match = getMatch(trig)

    if match == "exact" then 
        local list = self._exact[eventName]
        if not list then 
            list = {}
            self._exact[eventName] = list
        end
        list[#list + 1] = cap
        return
    end

    if match == "prefix" then 
        local list = self._prefix[eventName]
        if not list then 
            list = {}
            self._prefix[eventName] = list
        end
        list[#list + 1] = cap
        return
    end

    if match == "wildcard" then 
        self._wildcard[eventName] = cap
        return
    end

    error(("[EventRouter] Unknown trigger.match %s"):format(tostring(match)))
end

function EventRouter:RegisterAll(caps: { CapabilitySpec }): ()
    for index = 1, #caps do 
        self:Register(caps[index])
    end
end

function EventRouter:Get(eventName: string): { CapabilitySpec }?
    local out = {} :: { CapabilitySpec }
    local exactList = self._exact[eventName]
    if exactList then 
        addAll(out, exactList)
    end

    iteratePrefixes(eventName, self._prefixBuf)
    for index = 1, #self._prefixBuf do 
        local prefixKey = self._prefixBuf[index]
        local prefixList = self._prefix[prefixKey]
        if prefixList then 
            addAll(out, prefixList)
        end
    end

    if #self._wildcard > 0 then 
        addAll(out, self._wildcard)
    end

    return out
end

return EventRouter