-- StatsDisplay
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[

    CONSTRUCTOR StatsDisplay.new( props: { Gui: Instance, DataController: table } ) -> ( StatsDisplay )
]]

---------------------------------------------------------------------

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )
-- Modules
local NumberUtility = require( Knit.SharedModules.NumberUtility )

-- GameData
local TapData = require( Knit.GameData.TapData )

-- Class
local UIComponent = require( script.Parent.UIComponent )

---------------------------------------------------------------------

local StatsDisplay = setmetatable( {}, { __index = UIComponent } )
StatsDisplay.__index = StatsDisplay

function StatsDisplay.new( props )
    local self = setmetatable( UIComponent.new(), StatsDisplay )

    self._data = props.DataController

    local gui: Instance = props.Gui
    local statsPanel = gui:WaitForChild("StatsPanel")
    self._clicksLabel = statsPanel:WaitForChild("ClicksLabel")
    self._perTapLabel = statsPanel:WaitForChild("PerTapLabel")
    self._rebirthsLabel = gui:WaitForChild("RebirthsChip"):WaitForChild("RebirthsLabel")

    self:_track( self._data:ObserveDataChanged( "Stats", function( stats )
        self:_render( stats )
    end ) )

    return self
end

function StatsDisplay:_render( stats ): ()
    if ( typeof(stats) ~= "table" ) then return end

    local clicks: number = stats.Clicks or 0
    local rebirths: number = stats.Rebirths or 0

    self._clicksLabel.Text = NumberUtility.Abbreviate( clicks )
    self._perTapLabel.Text = "+" .. NumberUtility.Abbreviate( TapData.GetClicksPerTap(rebirths) ) .. " per tap"
    self._rebirthsLabel.Text = "Rebirths: " .. NumberUtility.Abbreviate( rebirths )
end

return StatsDisplay