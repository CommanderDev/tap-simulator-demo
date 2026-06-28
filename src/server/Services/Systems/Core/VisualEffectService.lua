--!strict
-- VisualEffectService
-- Author(s): Jesse Appleton
-- Date: 01/06/2026

--[[
    Replicates VFX to player clients
]]

---------------------------------------------------------------------

-- Types
export type VFXSpec = { [string]: any }
export type StopFilter = {
	channel: string?,
	tags: { string }?,
	tagsAny: { string }?,
	tagsAll: { string }?,
}

-- Knit
local Knit = require(game.ReplicatedStorage.Packages.Knit)

-- Roblox Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

---------------------------------------------------------------------

local VisualEffectService = Knit.CreateService({
	Name = "VisualEffectService",
	Client = {
		EffectPlayed = Knit.CreateSignal(),
		EffectStopped = Knit.CreateSignal(),
		EffectsStoppedByFilter = Knit.CreateSignal(),
	},
})

function VisualEffectService:PlayTo(player: Player, effectName: string, spec: VFXSpec?): string
	local handleId = HttpService:GenerateGUID(false)
	self.Client.EffectPlayed:Fire(player, effectName, spec or {}, handleId)
	return handleId
end

function VisualEffectService:PlayAll(effectName: string, spec: VFXSpec?): string
	local handleId = HttpService:GenerateGUID(false)
	local payload = spec or {}

	for _, player in ipairs(Players:GetPlayers()) do
		self.Client.EffectPlayed:Fire(player, effectName, payload, handleId)
	end

	return handleId
end

function VisualEffectService:PlayNear(position: Vector3, radius: number, effectName: string, spec: VFXSpec?): string
	local handleId = HttpService:GenerateGUID(false)

	local payload = spec or {}
	local r = math.max(0, radius)

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			if (humanoidRootPart.Position - position).Magnitude <= r then
				self.Client.EffectPlayed:Fire(player, effectName, payload, handleId)
			end
		end
	end

	return handleId
end

function VisualEffectService:StopTo(player: Player, handleId: string, reason: string?): ()
	self.Client.EffectStopped:Fire(player, handleId, reason)
end

function VisualEffectService:StopAll(handleId: string, reason: string?): ()
	self.Client.EffectStopped:FireAll(handleId, reason)
end

function VisualEffectService:StopAllByFilter(filter: StopFilter, reason: string?): ()
	self.Client.EffectsStoppedByFilter:FireAll(filter, reason)
end

function VisualEffectService:StopAllTo(player: Player, filter: StopFilter, reason: string?): ()
	self.Client.EffectsStoppedByFilter:Fire(player, filter, reason)
end

function VisualEffectService:KnitStart(): () end
function VisualEffectService:KnitInit(): () end


return VisualEffectService
