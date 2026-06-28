-- SoundService
-- Author(s): Jesse Appleton
-- Date: 01/11/2026

--[[
    Sound router
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )

-- Modules
local SoundRegistry = require( Knit.GameData.Sounds.SoundRegistry )
local SoundTypes = require( Knit.Types.SoundTypes )

-- Roblox Services
local Players = game:GetService("Players")

-- Variables

-- Objects

-- Types
type SoundBus = SoundTypes.SoundBus
type PlayOptions = SoundTypes.PlayOptions
type PlayKind = SoundTypes.PlayKind
type PlayPayload = SoundTypes.PlayPayload
type MusicAction = SoundTypes.MusicAction
---------------------------------------------------------------------


local SoundService = Knit.CreateService {
    Name = "SoundService";
    Client = {
        Play = Knit.CreateSignal(),
    };
}

local function _soundExists(soundId: string): boolean
    return SoundRegistry[soundId] ~= nil
end

local function _clampOpts(opts: PlayOptions?): PlayOptions?
	if not opts then
		return nil
	end

	local out: PlayOptions = {}

	if opts.volume ~= nil then out.volume = math.clamp(opts.volume, 0, 3) end
	if opts.pitch ~= nil then out.pitch = math.clamp(opts.pitch, 0.25, 3) end
	if opts.looped ~= nil then out.looped = opts.looped end
	if opts.startTime ~= nil then out.startTime = math.max(0, opts.startTime) end
	if opts.maxDistance ~= nil then out.maxDistance = math.clamp(opts.maxDistance, 0, 10000) end
	if opts.rolloffMode ~= nil then out.rolloffMode = opts.rolloffMode end
	if opts.fadeIn ~= nil then out.fadeIn = math.clamp(opts.fadeIn, 0, 10) end
	if opts.fadeOut ~= nil then out.fadeOut = math.clamp(opts.fadeOut, 0, 10) end
	if opts.seed ~= nil then out.seed = opts.seed end

	return out
end
function SoundService:_sanitizePayload(payload: PlayPayload): PlayPayload?
	if not payload or type(payload) ~= "table" then
		return nil
	end

	if type(payload.kind) ~= "string" then
		warn("Failed to sanitize payload: kind is not a string")
		return nil
	end

	if payload.kind == "Music" then
		if payload.action == nil then
			payload.action = "Play"
		elseif payload.action ~= "Play"
			and payload.action ~= "Pause"
			and payload.action ~= "Resume"
			and payload.action ~= "Stop" then
			warn("Failed to sanitize payload: Invalid music action")
			return nil
		end
	else
		payload.action = nil
	end

	if payload.kind == "Music" then
		if payload.action == "Play" then
			if type(payload.soundId) ~= "string" or payload.soundId == "" then
				warn("Failed to sanitize payload: Invalid SoundId")
				return nil
			end
			if not _soundExists(payload.soundId) then
				warn(("SoundService: Unknown soundId '%s'"):format(payload.soundId))
				return nil
			end
		else
			if payload.soundId ~= nil then
				if type(payload.soundId) ~= "string" or payload.soundId == "" then
					warn("Failed to sanitize payload: Invalid SoundId")
					return nil
				end
				if not _soundExists(payload.soundId) then
					warn(("SoundService: Unknown soundId '%s'"):format(payload.soundId))
					return nil
				end
			end
		end
	else
		if type(payload.soundId) ~= "string" or payload.soundId == "" then
			warn("Failed to sanitize payload: Invalid SoundId")
			return nil
		end
		if not _soundExists(payload.soundId) then
			warn(("SoundService: Unknown soundId '%s'"):format(payload.soundId))
			return nil
		end
	end

	if payload.kind == "At" and payload.position == nil then
		warn("SoundService: kind='At' requires position")
		return nil
	end
	if payload.kind == "On" and payload.target == nil then
		warn("SoundService: kind='On' requires target")
		return nil
	end

	local clean: PlayPayload = {
		kind = payload.kind,
		action = payload.action,
		soundId = payload.soundId,
		options = _clampOpts(payload.options),
		position = payload.position,
		target = payload.target,
	}

	return clean
end

function SoundService:_playersInRadius(position: Vector3, radius: number ): { Players } 
    local result = {}
    local r2 = radius * radius

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then 
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then 
                d = humanoidRootPart.Position - position
                local d2 = d.X * d.X + d.Y * d.Y + d.Z * d.Z
                if d2 <= r2 then
                    table.insert(result, player)
                end
            end
        end
    end

    return result
end

function SoundService:PlayForPlayer(player: Player, payload: PlayPayload): ()
   local clean = self:_sanitizePayload(payload)
   if not clean then 
        return
   end

   self.Client.Play:Fire(player, clean)
end

function SoundService:PlayForPlayers(players: { Players }, payload: PlayPayload): ()
    for _, player in pairs(players) do
        self:PlayForPlayer(player, payload)
    end
end

function SoundService:PlayForAll(payload: PlayPayload): ()
    for _, player in pairs(Players:GetPlayers()) do
        self:PlayForPlayer(player, payload)
    end
end

function SoundService:PlayInRadius(position: Vector3, radius: number, payload: PlayPayload): ()
    local clean = self:_sanitizePayload(payload)
    if not clean then 
        return
    end

    clean.position = position

    local recipients = self:_playersInRadius(position, radius)
    self:PlayForPlayers(recipients, clean)
end

function SoundService:Play2DForAll(soundId: string, payload: PlayPayload): ()
    self:PlayForAll({ kind = "2D", soundId = soundId, options = options})
end
function SoundService:PlayMusicForAll(soundId: string, options: PlayOptions?)
	self:PlayForAll({ kind = "Music", action = "Play", soundId = soundId, options = options })
end

function SoundService:StopMusicForAll(options: PlayOptions?)
	self:PlayForAll({ kind = "Music", action = "Stop", options = options })
end

function SoundService:PauseMusicForAll(options: PlayOptions?)
	self:PlayForAll({ kind = "Music", action = "Pause", options = options })
end

function SoundService:ResumeMusicForAll(options: PlayOptions?)
	self:PlayForAll({ kind = "Music", action = "Resume", options = options })
end

function SoundService:PlayAtInRadius(position: Vector3, radius: number, soundId: string, options: PlayOptions?)
	self:PlayInRadius(position, radius, {
		kind = "At",
		soundId = soundId,
		options = options,
		position = position,
	})
end

function SoundService:KnitStart(): ()
end


function SoundService:KnitInit(): ()
    
end


return SoundService