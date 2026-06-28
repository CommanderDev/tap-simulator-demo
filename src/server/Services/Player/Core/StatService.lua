-- StatService
-- Author(s): Jesse Appleton
-- Date: 01/15/2026

--[[
    
]]

---------------------------------------------------------------------

-- Constants
local LEADERSTAT_NAMES = { "Clicks", "Rebirths" }

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )

-- Modules
local Signal = require( Knit.Packages.Signal )
local NumberUtility = require( Knit.SharedModules.NumberUtility )

-- Roblox Services
local Players = game:GetService("Players")

-- Variables

-- Objects

---------------------------------------------------------------------


local StatService = Knit.CreateService {
    Name = "StatService";
    Client = {

    };
    _signals = {},
    _leaderstats = {}, 
}

function StatService:GetStatChangedSignal( player: Player, stat: string ): Signal
    local signals = self._signals[player]
    if not signals then
        signals = {}
        self._signals[player] = signals
    end

    local signal = signals[stat]
    if not signal then
        signal = Signal.new()
        signals[stat] = signal
    end
    return signal
end

function StatService:IncrementStat( player: Player, stat: string, amount: number ): ()
    local currentValue = self:GetStat( player, stat )
    self:SetStat( player, stat, currentValue + amount )
end

function StatService:SetStat( player: Player, stat: string, value: number ): ()
    local playerData = self.DataService:GetPlayerDataAsync( player )
    if not playerData then
        return
    end

    local stats = playerData.Data.Stats
    stats[stat] = value
    self.DataService:ReplicateTableIndex(player, "Stats", stat)
    self:GetStatChangedSignal(player, stat):Fire(value)
    self:_updateLeaderstat( player, stat, value )
end

function StatService:GetStat( player: Player, stat: string ): number
    local playerData = self.DataService:GetPlayerDataAsync( player )
    if not playerData then
        return 0
    end

    local stats = playerData.Data.Stats
    return stats[stat]
end

function StatService:_updateLeaderstat( player: Player, stat: string, value: number ): ()
    local values = self._leaderstats[player]
    if not values then
        return
    end

    local stringValue = values[stat]
    if not stringValue then
        return
    end

    stringValue.Value = NumberUtility.Abbreviate( value or 0 )
end

function StatService:_setupLeaderstats( player: Player, profile ): ()
    if self._leaderstats[player] then
        return 
    end

    local stats = profile.Data.Stats or {}

    local values = {}
    self._leaderstats[player] = values

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"

    for _, statName in ipairs( LEADERSTAT_NAMES ) do
        local stringValue = Instance.new("StringValue")
        stringValue.Name = statName
        stringValue.Value = NumberUtility.Abbreviate( stats[statName] or 0 )
        stringValue.Parent = leaderstats
        values[statName] = stringValue
    end

    leaderstats.Parent = player
end

function StatService:KnitStart(): ()
    self.DataService.PlayerDataLoaded:Connect(function( player, profile )
        self:_setupLeaderstats( player, profile )
    end)

    for _, player in ipairs( Players:GetPlayers() ) do
        local profile = self.DataService.PlayerData[player]
        if profile then
            task.spawn(function()
                self:_setupLeaderstats( player, profile )
            end)
        end
    end

    Players.PlayerRemoving:Connect(function( player )
        self._leaderstats[player] = nil
    end)
end


function StatService:KnitInit(): ()
    self.DataService = Knit.GetService("DataService")
end


return StatService