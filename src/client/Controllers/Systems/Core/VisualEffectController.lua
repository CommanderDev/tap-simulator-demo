--!strict
-- VisualEffectController
-- Author(s): Jesse Appleton
-- Date: 01/07/2026

--[[
    Client side VFX runtime
]]

---------------------------------------------------------------------

-- Types
type Pool = {
    _key: string,
    _template: Instance,
    _parent: Instance?,
    _available: { Instance },
    _inUse: { [Instance]: boolean },
    _max: number,

    Acquire: (self: Pool) -> Instance,
    Release: (self: Pool, instance: Instance) -> (),
    Clear: (self: Pool) -> (),
}

-- Constants

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )

-- Modules

-- Roblox Services
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
-- Variables

-- Objects

---------------------------------------------------------------------

local VisualEffectController = Knit.CreateController { 
Name = "VisualEffectController",
    _active = {} :: { [string]: any},
    _pools = {} :: { [string]: any},
    _effectClasses = {} :: {[string]: { [string]: any}},
 }

local function createPool(key: string, template: Instance, maxCount: number?, parent: Instance): Pool
    local self = {} :: any
    self._key = key
    self._template = template
    self._parent = parent
    self._available = {}
    self._inUse = {}
    self._max = maxCount or 64

    function self:Acquire(): Instance
        local instance = table.remove(self._available)
        
        if instance and instance.Parent ~= nil then
            instance = nil
        end
        
        if not instance then 
            instance = self._template:Clone()
        end

        self._inUse[instance] = true
        
        if self._parent then 
            pcall(function()
                instance.Parent = self._parent
            end)
        end
        return instance
    end

    function self:Release(instance: Instance): boolean
        if not instance then
            return false
        end

        if not self._inUse[instance] then 
            return false
        end

        self._inUse[instance] = nil

        pcall(function()
            for _, descendant in ipairs(instance:GetDescendants()) do
                if descendant:IsA("ParticleEmitter") then
                    descendant.Enabled = false
                    descendant.Rate = 0
                elseif descendant:IsA("Sound") then
                    descendant:Stop()
                elseif descendant:IsA("WeldConstraint") then
                    descendant:Destroy()
                end
            end
        end)

        local success = pcall(function()
            instance.Parent = nil
        end)
        
        if not success then
            pcall(function()
                instance:Destroy()
            end)
            return false
        end

        if #self._available < self._max then 
            table.insert(self._available, instance)
            return true
        else
            pcall(function()
                instance:Destroy()
            end)
            return false
        end
    end

    function self:Clear(): ()
        for instance in pairs(self._inUse) do
            instance:Destroy()
        end
        
        table.clear(self._inUse)
        table.clear(self._available)
    end

    return self :: Pool
end

function VisualEffectController:DefinePool(poolKey: string, template: Instance, maxCount: number?, parent: Instance?)
    self._pools[poolKey] = createPool(poolKey, template, maxCount, parent)
end

function VisualEffectController:Acquire(poolKey: string): Instance
    local pool = self._pools[poolKey]
    assert(pool, ("No pool defined for key %s"):format(poolKey))
    
    return pool:Acquire()
end

function VisualEffectController:Release(poolKey: string, instance: Instance): ()
    local pool = self._pools[poolKey]
    if not pool then 
        instance:Destroy()
        return
    end
    pool:Release(instance)
end

function VisualEffectController:Stop(handleId: string, reason: string?): ()
    local effect = self._active[handleId]
    if not effect then 
        return
    end

    local okStop = (type(effect.Stop) == "function") 
    if okStop then
        effect:Stop(reason)
    end

    if type(effect.Destroy) == "function" then 
        effect:Destroy()
    end

    self._active[handleId] = nil
end

function VisualEffectController:Play(effectName: string, spec: { [string]: any}?, handleId: string?): string
    local id = handleId or HttpService:GenerateGUID(false)

    if self._active[id] then 
        self:Stop(id, "replaced")
    end

    local effectClass = self._effectClasses[effectName]
    if not effectClass then
		warn(("[VFX] Missing effect module '%s'"):format(effectName))
        return id
    end

    local effect = effectClass.new(self, spec or {}, id)

    self._active[id] = effect
    if type(effect.Start) == "function" then
        effect:Start()
    end

    return id
end

function VisualEffectController:KnitStart(): ()
    for _, effectClass in pairs(Knit.Modules.VisualEffects:GetDescendants()) do 
        if effectClass:IsA("ModuleScript") then
            self._effectClasses[effectClass.Name] = require(effectClass)
        end
    end

    RunService.Heartbeat:Connect(function(dt: number): ()
        for id, effect in pairs(self._active) do 
            if type(effect.Tick) == "function" then 
                effect:Tick(dt)
            end
        end
    end)

    RunService.RenderStepped:Connect(function(dt: number): ()
        for id, effect in pairs(self._active) do 
            if type(effect.Render) == "function" then
                effect:Render(dt)
            end
        end
    end)

    self.VisualEffectService.EffectPlayed:Connect(function(effectName: string, spec: { [string]: any}?, handleId: string?): string
        self:Play(effectName, spec, handleId)
    end)
    self.VisualEffectService.EffectStopped:Connect(function(handleId: string, reason: string?): ()
        self:Stop(handleId, reason)
    end)

    self.VisualEffectService.EffectsStoppedByFilter:Connect(function(filter: any, reason: string?): ()
        for id, effect in pairs(self._active) do 
            local ok = true

            if filter.channel then
                ok = (effect.channel == filter.channel)
            end

            if ok and filter.tags then 
                local tags = effect.tags or {}
                for _, tag in ipairs(filter.tags) do 
                    local found = false
                    for _, effectTag in ipairs(tags) do 
                        if effectTag == tag then 
                            found = true
                            break
                        end
                    end
                    if not found then 
                        ok = false
                        break
                    end
                end
            end

            if ok then 
                self:Stop(id, reason or "filtered")
            end
        end
    end)
end


function VisualEffectController:KnitInit(): ()
    self.VisualEffectService = Knit.GetService("VisualEffectService")
end


return VisualEffectController