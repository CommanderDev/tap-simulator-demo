local startTime = os.clock()

local ReplicatedStorage = game:GetService( "ReplicatedStorage" )
--
local Knit = require( ReplicatedStorage.Packages.Knit )

-- EXPOSE SERVER MODULES
Knit.Modules = script.Modules

--EXPOSE SHARED MODULES
Knit.SharedModules = ReplicatedStorage.Shared.Modules
Knit.GameData = ReplicatedStorage.Shared.GameData
Knit.Packages = ReplicatedStorage.Packages

-- EXPOSE SERVER ASSETS
Knit.Assets = game.ServerStorage.Assets

-- EXPOSE SHARED ASSETS
Knit.SharedAssets = ReplicatedStorage.Assets

Knit.Enums = require(ReplicatedStorage.Shared.Enums)

Knit.Types = ReplicatedStorage.Shared.Types

-- ENVIRONMENT SWITCHES
Knit.IsStudio = game:GetService( "RunService" ):IsStudio()
Knit.IsClient = game:GetService( "RunService" ):IsClient()
Knit.IsServer = game:GetService( "RunService" ):IsServer()

-- ADD SERVICES
Knit.AddServicesDeep( script.Services )

Knit:Start():andThen(function()
    print( string.format("Server Successfully Compiled! [%.3f s]", (os.clock() - startTime)) )
end):catch(error )