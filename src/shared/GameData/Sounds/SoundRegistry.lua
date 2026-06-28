--!strict
local Knit = require( game.ReplicatedStorage.Packages.Knit )
local SoundTypes = require( Knit.Types.SoundTypes )

local SoundRegistry: SoundTypes.Registry = {
    ["sfx.tap"] = {
        bus = "SFX",
        assetId = "rbxassetid://73737299125990",
        defaults = {
            volume = 1,
            pitch = 1,
            looped = false,
            startTime = 0,
            maxDistance = 100,
            rolloffMode = Enum.RollOffMode.Inverse,
        },
        tags = { "sfx", "tap" },
    }
}

return SoundRegistry