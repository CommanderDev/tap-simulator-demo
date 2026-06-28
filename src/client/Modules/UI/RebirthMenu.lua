-- RebirthMenu
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    CONSTRUCTOR RebirthMenu.new( props: {
        Gui: Instance, TapController: table, DataController: table, UIController: table,
    } ) -> ( RebirthMenu )
]]

---------------------------------------------------------------------

-- Constants
local MENU_NAME = "Rebirth"

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )
-- Modules
local NumberUtility = require( Knit.SharedModules.NumberUtility )

-- GameData
local RebirthData = require( Knit.GameData.RebirthData )
local TapData = require( Knit.GameData.TapData )

-- Class
local UIComponent = require( script.Parent.UIComponent )

---------------------------------------------------------------------

local RebirthMenu = setmetatable( {}, { __index = UIComponent } )
RebirthMenu.__index = RebirthMenu

function RebirthMenu.new( props )
    local self = setmetatable( UIComponent.new(), RebirthMenu )

    self._tap = props.TapController
    self._data = props.DataController
    self._ui = props.UIController
    self._pending = false

    local gui: Instance = props.Gui
    self._openButton = gui:WaitForChild("RebirthButton")
    self._menu = gui:WaitForChild("RebirthMenu")

    local window = self._menu:WaitForChild("Window")
    self._confirm = window:WaitForChild("ConfirmButton")
    self._rebirthsValue = window:WaitForChild("RebirthsRow"):WaitForChild("Value")
    self._costValue = window:WaitForChild("CostRow"):WaitForChild("Value")
    self._multiplierValue = window:WaitForChild("MultiplierRow"):WaitForChild("Value")

    self:_track( self._openButton.Activated:Connect(function()
        self._ui:SetMenu( MENU_NAME )
    end) )
    self:_track( self._menu:WaitForChild("Backdrop").Activated:Connect(function()
        self._ui:SetMenu( nil )
    end) )
    self:_track( window:WaitForChild("CloseButton").Activated:Connect(function()
        self._ui:SetMenu( nil )
    end) )

    self:_track( self._ui.MenuChanged:Connect(function( menuName )
        self._menu.Visible = ( menuName == MENU_NAME )
    end) )
    self._menu.Visible = ( self._ui.Menu == MENU_NAME )

    self:_track( self._confirm.Activated:Connect(function()
        self:_onConfirm()
    end) )

    self:_track( self._data:ObserveDataChanged( "Stats", function( stats )
        self:_render( stats )
    end) )

    return self
end

function RebirthMenu:_render( stats ): ()
    if ( typeof(stats) ~= "table" ) then return end

    local clicks: number = stats.Clicks or 0
    local rebirths: number = stats.Rebirths or 0

    self._rebirthsValue.Text = NumberUtility.Abbreviate( rebirths )
    self._costValue.Text = NumberUtility.Abbreviate( RebirthData.GetCost(rebirths) )
    self._multiplierValue.Text = "+" .. NumberUtility.Abbreviate( TapData.GetClicksPerTap(rebirths + 1) )

    local canRebirth: boolean = RebirthData.CanRebirth( clicks, rebirths )
    self._confirm.AutoButtonColor = canRebirth
    self._confirm.BackgroundTransparency = if canRebirth then 0 else 0.45
end

function RebirthMenu:_onConfirm(): ()
    if ( self._pending ) then return end
    self._pending = true

    self._tap:Rebirth():andThen(function( success: boolean )
        if ( success ) then
            self._ui:SetMenu( nil )
        end
    end):catch( warn ):finally(function()
        self._pending = false
    end)
end

return RebirthMenu