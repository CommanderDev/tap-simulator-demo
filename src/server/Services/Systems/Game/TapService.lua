-- TapService
-- Author(s): Jesse Appleton
-- Date: 06/28/2026

--[[
    SIGNAL (Client)     Tap -> ()                  -- client asks to tap
    METHOD (Client)     Rebirth() -> ( boolean )   -- client asks to rebirth; returns whether it happened
]]

---------------------------------------------------------------------

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )
local t = require( Knit.Packages.t )

-- GameData
local TapData = require( Knit.GameData.TapData )
local RebirthData = require( Knit.GameData.RebirthData )

-- Roblox Services
local Players = game:GetService("Players")

-- Variables

-- Objects

---------------------------------------------------------------------


local TapService = Knit.CreateService {
    Name = "TapService";
    Client = {
        Tap = Knit.CreateSignal();
    };
    _lastTap = {};
}


function TapService.Client:Rebirth( player: Player ): ( boolean )
    return self.Server:Rebirth( player )
end

function TapService:HandleTap( player: Player ): ()
    local now: number = os.clock()
    local last: number? = self._lastTap[ player ]
    if ( last ) and ( (now - last) < TapData.MinTapInterval ) then
        return 
    end
    self._lastTap[ player ] = now

    local rebirths: number = self.StatService:GetStat( player, "Rebirths" ) or 0
    self.StatService:IncrementStat( player, "Clicks", TapData.GetClicksPerTap(rebirths) )
end


local tRebirth = t.tuple( t.instanceIsA("Player") )
function TapService:Rebirth( player: Player ): ( boolean )
    assert( tRebirth(player) )

    local clicks: number = self.StatService:GetStat( player, "Clicks" ) or 0
    local rebirths: number = self.StatService:GetStat( player, "Rebirths" ) or 0
    if ( not RebirthData.CanRebirth(clicks, rebirths) ) then
        return false 
    end

    self.StatService:SetStat( player, "Clicks", 0 )
    self.StatService:IncrementStat( player, "Rebirths", 1 )
    return true
end


function TapService:KnitStart(): ()
    self.Client.Tap:Connect(function( player: Player )
        self:HandleTap( player )
    end)

    Players.PlayerRemoving:Connect(function( player: Player )
        self._lastTap[ player ] = nil
    end)
end


function TapService:KnitInit(): ()
    self.StatService = Knit.GetService("StatService")
end


return TapService