
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

Knit.PlayerGui = Knit.Player:WaitForChild("PlayerGui")
Knit.MainUI = Knit.PlayerGui:WaitForChild("Main")
-- EXPOSE CLIENT MODULES
Knit.Modules = script:WaitForChild("Modules")
--EXPOSE SHARED MODULES
Knit.SharedModules = game.ReplicatedStorage.Shared.Modules
Knit.GameData = game.ReplicatedStorage.Shared.GameData
Knit.Packages = ReplicatedStorage.Packages
Knit.Types = ReplicatedStorage.Shared.Types

-- EXPOSE SHARED ASSETS
Knit.SharedAssets = ReplicatedStorage:WaitForChild("Assets")

Knit.Enums = require(ReplicatedStorage.Shared.Enums)
-- ENVIRONMENT SWITCHES
Knit.IsStudio = game:GetService("RunService"):IsStudio()
Knit.IsClient = game:GetService("RunService"):IsClient()
Knit.IsServer = game:GetService("RunService"):IsServer()

Knit.LocalPlayer = game.Players.LocalPlayer

-- ADD CONTROLLERS
local startTime = os.clock()
Knit.AddControllersDeep(script.Controllers)
Knit:Start()
	:andThen(function()
		print(string.format("Client Successfully Compiled! [%.3f s]", (os.clock() - startTime)))
		Knit.isLoaded = true
	end)
	:catch(error)
