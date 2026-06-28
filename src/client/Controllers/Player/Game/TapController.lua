-- TapController
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    FUNCTION    TapController:Tap() -> ()              -- request a tap (fire-and-forget, server-authoritative)
    FUNCTION    TapController:Rebirth() -> ( table )   -- request a rebirth; returns Promise< boolean >
]]

---------------------------------------------------------------------

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )
-- GameData
local TapData = require( Knit.GameData.TapData )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local TapController = Knit.CreateController {
    Name = "TapController";
    _lastTap = 0;
}

function TapController:Tap(): ()
    local now: number = os.clock()
    if ( (now - self._lastTap) < TapData.MinTapInterval ) then
        return
    end
    self._lastTap = now
    self.SoundController:Play2D("sfx.tap")
    self.TapService.Tap:Fire()
end

function TapController:Rebirth(): ( table )
    return self.TapService:Rebirth()
end


function TapController:KnitStart(): ()
end


function TapController:KnitInit(): ()
    self.TapService = Knit.GetService("TapService")
    self.SoundController = Knit.GetController("SoundController")
end


return TapController