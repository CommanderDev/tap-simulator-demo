-- HoverEffect
-- Author(s): Jesse Appleton
-- Date: 02/09/2026

--[[
    
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit)
local Janitor = require( Knit.Packages.Janitor )
local Promise = require( Knit.Packages.Promise )

-- Modules

-- Roblox Services
local TweenService = game:GetService("TweenService")
-- Variables

-- Objects

---------------------------------------------------------------------


local HoverEffect = {}
HoverEffect.__index = HoverEffect


function HoverEffect.new( holder: Frame ): ( {} )
    local self = setmetatable( {}, HoverEffect )
    self._janitor = Janitor.new()

    self._holder = holder

    self._defaultSize = holder.Size
    self._hoverSize = UDim2.new(self._defaultSize.X.Scale * 1.2, self._defaultSize.X.Offset * 1.2, self._defaultSize.Y.Scale * 1.2, self._defaultSize.Y.Offset * 1.2)
    
    self._janitor:add(holder.MouseEnter:Connect(function(): ()
        self:_onMouseEnter()
    end))

    self._janitor:add(holder.MouseLeave:Connect(function(): ()
        self:_onMouseLeave()
    end))

    return self
end


function HoverEffect:_onMouseEnter(): ()
    TweenService:Create(self._holder, TweenInfo.new(0.1), { Size = self._hoverSize }):Play()
end

function HoverEffect:_onMouseLeave(): ()
    TweenService:Create(self._holder, TweenInfo.new(0.1), { Size = self._defaultSize }):Play()
end

function HoverEffect:Destroy(): ()
    self._janitor:Destroy()
end


return HoverEffect