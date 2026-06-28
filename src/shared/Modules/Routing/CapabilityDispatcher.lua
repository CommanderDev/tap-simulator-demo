--!strict

local CapabilityDispatcher = {}
CapabilityDispatcher.__index = CapabilityDispatcher

function CapabilityDispatcher.new(execPolicyEnum, execPolicyClientValue, execPolicyServerValue): ()
    local self = setmetatable({}, CapabilityDispatcher)
    self._ExecPolicy = execPolicyEnum
    self._ClientPolicy = execPolicyClientValue
    self._ServerPolicy = execPolicyServerValue
    
    return self
end

function CapabilityDispatcher:DispatchEvent(routing, execFn, sendClientFn, context, eventName: string, payload: any, recipients: { Player }?): ()
    local list = routing:GetEvent(eventName)
    for _, cap in ipairs(list) do
        if routing:Passes(cap, payload) then 
            local policy = (((context.resolved or {}).CapabilityTypes or {})[cap.type] or {}).execPolicy
            if not policy then 
                policy = cap.execPolicy
            end

            if policy == self._ServerPolicy then
                execFn(context, cap, payload)
            elseif policy == self._ClientPolicy then
                if sendClientFn and recipients then
                    sendClientFn(recipients, context, cap, payload)
                end
            end
        end
    end
end