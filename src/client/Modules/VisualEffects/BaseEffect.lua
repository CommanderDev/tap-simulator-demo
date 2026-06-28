--!strict
-- BaseEffect
-- Author(s): Jesse Appleton
-- Date: 01/07/2026

--[[
    Base-class for all VFX effects.
]]

---------------------------------------------------------------------

-- Types
export type BaseEffect = {
    controller: any,
    spec: { [string]: any},
    handleId: string,

    channel: string?,
    tags: { string }?,

    _janitor: any,
    _destroyed: boolean,

    Start: (self: BaseEffect) -> (),
    Stop: (self: BaseEffect, reason: string?) -> (),
    Destroy: (self: BaseEffect) -> (),

}
-- Constants

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit)
local Janitor = require( Knit.Packages.Janitor )
local Promise = require( Knit.Packages.Promise )

-- Modules

-- Roblox Services

-- Variables

-- Objects

---------------------------------------------------------------------


local BaseEffect = {}
BaseEffect.__index = BaseEffect


function BaseEffect.new( controller: any, spec: { [string]: any}, handleId: string ): BaseEffect
    local self = setmetatable( {}, BaseEffect )
    self._janitor = Janitor.new()

    self.controller = controller
    self.spec = spec
    self.handleId = handleId

    self.channel = spec.channel
    self.tags = spec.tags

    self._destroyed = false

    return self
end

function BaseEffect:Track( instance: Instance ): Instance
    self._janitor:add(instance)
    return instance
end

function BaseEffect:TrackConnection( conn: RbxScriptConnection): RbxScriptConnection
    self._janitor:add(conn)
    return conn
end

function BaseEffect:OnDestroy( fn: () -> ()): ()
    self._janitor:add(fn)
end

function BaseEffect:Acquire(poolKey: string): Instance
    local instance = self.controller:Acquire(poolKey)

    self._janitor:add(function()
        if instance and instance.Parent then
            self.controller:Release(poolKey, instance)
        end
    end)
    return instance
end

function BaseEffect:Start(): ()
    -- Override
end

function BaseEffect:Stop(reason: string?): ()
    -- Override
end

function BaseEffect:Tick(): ()
    -- Override
end

function BaseEffect:Render(): ()
    -- Override
end

function BaseEffect:Destroy(): ()
    if self._destroyed then 
        return
    end

    self._destroyed = true

    pcall(function()
        self:Stop("Destroy")
    end)

    self._janitor:Destroy()
end

return BaseEffect