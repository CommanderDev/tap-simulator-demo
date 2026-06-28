-- HUD
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    Owns the in-game HUD. Requires each UI component class and instantiates it
    against the live ScreenGui (StarterGui.Main -> PlayerGui.Main), injecting the
    controllers each one needs. To add UI, require the class and drop it in CLASSES.
]]

---------------------------------------------------------------------

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )

-- Components
local UI = Knit.Modules.UI 
local CLASSES = {
    require( UI.StatsDisplay ),
    require( UI.TapButton ),
    require( UI.RebirthMenu ),
}

-- Roblox Services
local Players = game:GetService("Players")

---------------------------------------------------------------------


local HUD = Knit.CreateController {
    Name = "HUD";
    _components = {};
}


function HUD:KnitStart(): ()
    local player: Player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = playerGui:WaitForChild("Main"):WaitForChild("TapUI")

    local deps = {
        Gui = gui;
        DataController = self.DataController;
        TapController = self.TapController;
        UIController = self.UIController;
    }

    for _, class in CLASSES do
        table.insert( self._components, class.new(deps) )
    end
end


function HUD:KnitInit(): ()
    self.DataController = Knit.GetController("DataController")
    self.TapController = Knit.GetController("TapController")
    self.UIController = Knit.GetController("UIController")
end


return HUD