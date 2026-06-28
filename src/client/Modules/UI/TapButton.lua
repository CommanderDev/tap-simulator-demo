-- TapButton
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    CONSTRUCTOR TapButton.new( props: { Gui: Instance, TapController: table } ) -> ( TapButton )
]]

---------------------------------------------------------------------

-- Roblox Services
local TweenService = game:GetService("TweenService")

-- Class
local UIComponent = require( script.Parent.UIComponent )

-- Constants
local PRESS_TWEEN = TweenInfo.new( 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out )

---------------------------------------------------------------------

local TapButton = setmetatable( {}, { __index = UIComponent } )
TapButton.__index = TapButton

function TapButton.new( props )
    local self = setmetatable( UIComponent.new(), TapButton )

    self._tap = props.TapController
    self._button = props.Gui:WaitForChild("TapButton")

    self._scale = Instance.new("UIScale")
    self._scale.Parent = self._button

    self:_track( self._button.Activated:Connect(function()
        self._tap:Tap()
        self:_pop()
    end) )

    return self
end

function TapButton:_pop(): ()
    self._scale.Scale = 0.94
    TweenService:Create( self._scale, PRESS_TWEEN, { Scale = 1 } ):Play()
end

function TapButton:Destroy(): ()
    if ( self._scale ) then
        self._scale:Destroy()
    end
    UIComponent.Destroy( self )
end

return TapButton