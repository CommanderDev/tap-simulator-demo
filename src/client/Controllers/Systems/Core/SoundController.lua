--!strict
-- SoundController
-- Author(s): Jesse Appleton
-- Date: 01/11/2026

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game.ReplicatedStorage.Packages.Knit )

-- Modules
local WeightedChoice = require( Knit.SharedModules.WeightedChoice )
local SoundRegistry = require( Knit.GameData.Sounds.SoundRegistry )
local SoundBundles = require( Knit.GameData.Sounds.SoundBundles )
local SoundTypes = require( Knit.Types.SoundTypes )
-- Roblox Services
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
-- Variables

-- Objects

-- Types
type SoundBus = SoundTypes.SoundBus
type SoundDefaults = SoundTypes.SoundDefaults
type WeightedVariant = SoundTypes.WeightedVariant
type SoundSpec = SoundTypes.SoundSpec
type PlayOptions = SoundTypes.PlayOptions
type BusState = SoundTypes.BusState
type PooledSound = SoundTypes.PooledSound

---------------------------------------------------------------------

local SoundController = Knit.CreateController { 
    Name = "SoundController";

    _buses = {} :: { [SoundBus]: BusState },
    _baseByAssetId = {} :: { [string]: Sound},

    _poolBySoundId = {} :: { [string]: { PooledSound }},

    _music = nil :: Sound?,
    _emittersFolder = nil :: Folder?,
}

local function _ensureFolder(parentInstance: Instance, name: string, className: string): Instance
	local existing = parentInstance:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parentInstance
	return instance
end

function SoundController:_getSpec(soundId: string): SoundSpec
    local spec = SoundRegistry[soundId]
    assert(spec, "SoundController: Unknown sound ID: " .. soundId)
    return spec
end

function SoundController:_pickAssetId(spec: SoundSpec, options: PlayOptions?): string
    if spec.assetId then 
        return spec.assetId
    end

    local variants = spec.variants
    assert(variants ~= nil and #variants > 0, "SoundController: spec missing assetid/variants")

    local seed = options and options.seed
    if seed then 
        local chosen = WeightedChoice.PickSeeded(variants, seed, function(value)
            return value.weight
        end)
        return chosen.assetId
    else
        local chosen = WeightedChoice.Pick(variants, function(value)
            return value.weight
        end)
        return chosen.assetId
    end
end

function SoundController:_busState(bus: SoundBus): BusState
    local state = self._buses[bus]
    assert(state, ("SoundController: bus %s missing"):format(bus))
    return state
end

function SoundController:_computeVolume(bus: SoundBus, baseVolume: number, overrideVolume: number?): number
    local state = self:_busState(bus)
    if state.muted then 
        return 0
    end

    local volume = baseVolume * state.volume
    if overrideVolume then 
        volume *= overrideVolume
    end

    return volume
end

function SoundController:_applyDefaults(sound: Sound, spec: SoundSpec, options: PlayOptions?): ()
    local defaults = spec.defaults or {}

    local looped = (options and options.looped ~= nil) and (options :: PlayOptions).looped or defaults.looped or false
    local startTime = (options and options.startTime) or defaults.startTime or 0
    local pitch = (options and options.pitch ) or defaults.pitch or 1
    local rollOffMode = (options and options.rollOffMode) or defaults.rollOffMode
    local maxDistance = (options and options.maxDistance) or defaults.maxDistance

    sound.Looped = looped
    sound.TimePosition = startTime
    sound.PlaybackSpeed = pitch

    if rollOffMode then 
        sound.RollOffMode = rollOffMode
    end
    if maxDistance then 
        sound.RollOffMaxDistance = maxDistance
    end
end

function SoundController:_getOrCreateBase(assetId: string, bus: SoundBus): Sound
    local existing = self._baseByAssetId[assetId]
    if existing then 
        return existing
    end

    local base = Instance.new("Sound")
    base.Name = assetId
    base.Volume = 1
    base.Looped = false
    base.SoundId = assetId
    base.Parent = self:_busState(bus).folder

    self._baseByAssetId[assetId] = base
    return base
end

function SoundController:_preloadAssetIds(assetIds: { string }, bus: SoundBus): ()
    local toPreload: { Instance } = {}
    for _, assetId in ipairs(assetIds) do 
        local base = self:_getOrCreateBase(assetId, bus)
        table.insert(toPreload, base)
    end

    if #toPreload > 0 then 
        ContentProvider:PreloadAsync(toPreload)
    end
end

function SoundController:_acquireFromPool(soundId: string, base: Sound): Sound
    local pool = self._poolBySoundId[soundId]
    if not pool then 
        pool = {}
        self._poolBySoundId[soundId] = pool
    end

    for _, entry in ipairs(pool) do 
        if not entry.inUse then 
            entry.inUse = true
            return entry.sound
        end
    end

    local clone = base:Clone()
    clone.Name = soundId

    local entry: PooledSound = { sound = clone, inUse = true, connection = nil }
    entry.connection = clone.Ended:Connect(function()
        entry.inUse = false
    end)

    table.insert(pool, entry)
    return clone
end

function SoundController:_playSoundInstance(sound: Sound, bus: SoundBus, spec: SoundSpec, options: PlayOptions? ): ()
    self:_applyDefaults(sound, spec, options)

    local baseVolume = (spec.defaults and spec.defaults.volume) or 1
    local finalVolume = self:_computeVolume(bus, baseVolume, options and options.volume)
    local fadeIn = options and options.fadeIn

    if fadeIn and fadeIn > 0 then 
        sound.Volume = 0
        local tween = TweenService:Create(sound, TweenInfo.new(fadeIn), { Volume = finalVolume })
        tween:Play()
    else
        sound.Volume = finalVolume
    end

    sound:Play()
end

function SoundController:PreloadBundle(bundleId: string)
    local bundle = SoundBundles[bundleId]
    assert(bundle, ("SoundController: Unknown bundle %s"):format(bundleId))

    local byBus: { [SoundBus]: { string} } = {
        SFX = {},
        UI = {},
        Music = {},
        Ambience = {},
    }

    for _, soundId in ipairs(bundle) do 
        local spec = self:_getSpec(soundId)
        local bus = spec.bus
        
        if spec.assetId then 
            table.insert(byBus[bus], spec.assetId)
        end

        if spec.variants then 
            for key, variant in ipairs(spec.variants) do 
                table.insert(byBus[bus], variant.assetId)
            end
        end
    end

    for bus, ids in pairs(byBus) do
        -- TODO: Add selective preloading
        if #ids > 0 then 
            self:_preloadAssetIds(ids, bus :: SoundBus)
        end
    end
end

function SoundController:PreloadByBus(bus: SoundBus): ()
    local assetIds: { string } = {}

    for soundId, spec in pairs(SoundRegistry) do
        if spec.bus == bus then
            if spec.assetId then
                table.insert(assetIds, spec.assetId)
            end

            if spec.variants then
                for _, variant in ipairs(spec.variants) do
                    table.insert(assetIds, variant.assetId)
                end
            end
        end
    end

    if #assetIds > 0 then
        self:_preloadAssetIds(assetIds, bus)
    end
end

function SoundController:PreloadByBusBatch(...): ()
    local buses: { SoundBus } = {...}
    local busSet: { [SoundBus]: boolean } = {}
    for _, bus in ipairs(buses) do
        busSet[bus] = true
    end

    local byBus: { [SoundBus]: { string } } = {}

    for soundId, spec in pairs(SoundRegistry) do
        if busSet[spec.bus] then
            if not byBus[spec.bus] then
                byBus[spec.bus] = {}
            end

            if spec.assetId then
                table.insert(byBus[spec.bus], spec.assetId)
            end

            if spec.variants then
                for _, variant in ipairs(spec.variants) do
                    table.insert(byBus[spec.bus], variant.assetId)
                end
            end
        end
    end

    for _, bus in ipairs(buses) do
        local assetIds = byBus[bus]
        if assetIds and #assetIds > 0 then
            self:_preloadAssetIds(assetIds, bus)
        end
    end
end

function SoundController:SetBusVolume(bus: SoundBus, volume: number): ()
    local state = self:_busState(bus)
    state.volume = math.clamp(volume, 0, 1)
end

function SoundController:SetBusMuted(bus: SoundBus, muted: boolean): ()
    local state = self:_busState(bus)
    state.muted = muted
end

function SoundController:Play2D(soundId: string, options: PlayOptions?): Sound?
    local spec = self:_getSpec(soundId)
    local assetId = self:_pickAssetId(spec, options)
    local bus = spec.bus

    local base = self:_getOrCreateBase(assetId, bus)
    local instance = self:_acquireFromPool(soundId, base)
    instance.Parent = self:_busState(bus).folder

    self:_playSoundInstance(instance, bus, spec, options)

    return instance
end

function SoundController:PlayOn(soundId: string, parent: Instance, options: PlayOptions?): Sound?
    local spec = self:_getSpec(soundId)
    local assetId = self:_pickAssetId(spec, options)
    local bus = spec.bus

    local base = self:_getOrCreateBase(assetId, bus)
    local instance = self:_acquireFromPool(soundId, base)
    instance.Parent = parent

    self:_playSoundInstance(instance, bus, spec, options)

    return instance
end

function SoundController:PlayAt(soundId: string, position: Vector3, options: PlayOptions?): Sound?
    local spec = self:_getSpec(soundId)
    local assetId = self:_pickAssetId(spec, options)
    local bus = spec.bus

    local emitters = self._emittersFolder
    assert(emitters, "SoundController: Emitters folder missing")

    local emitter = Instance.new("Part")
    emitter.Name = "SoundEmitter"
    emitter.Anchored = true
    emitter.CanCollide = false
    emitter.CanQuery = false
    emitter.CanTouch = false
    emitter.Transparency = 1
    emitter.Size = Vector3.new(0.2, 0.2, 0.2)
    emitter.Position = position
    emitter.Parent = emitters

    local base = self:_getOrCreateBase(assetId, bus)
    local instance = base:Clone()
    instance.Name = soundId
    instance.Parent = emitter

    self:_playSoundInstance(instance, bus, spec, options)

    if not instance.Looped then 
        instance.Ended:Once(function()
            emitter:Destroy()
        end)
    end

    return instance
end

function SoundController:PlayMusic(soundId: string, options: PlayOptions?): Sound?
    local spec = self:_getSpec(soundId)
    assert(spec.bus == "Music", "SoundController: PlayMusic expects a music bus sound id")

    if self._music then 
        self:StopMusic({ fadeOut = options and options.fadeOut or 0.25})
    end

    local assetId = self:_pickAssetId(spec, options)
    local base = self:_getOrCreateBase(assetId, "Music")
    local instance = base:Clone()
    instance.Name = soundId
    instance.Parent = self:_busState("Music").folder

    self._music = instance
    self._musicSoundId = soundId
    self:_playSoundInstance(instance, "Music", spec, options)

    return instance
end

function SoundController:StopMusic(options: PlayOptions?): ()
    local instance = self._music
    if not instance then 
        return
    end

    local fadeOut = options and options.fadeOut

    if fadeOut and fadeOut > 0 then 
        local tween = TweenService:Create(instance, TweenInfo.new(fadeOut), { Volume = 0 })
        tween:Play()
        tween.Completed:Once(function()
            if self._music == instance then 
                self._music = nil
            end
            instance:Stop()
            instance:Destroy()
        end)
    else
        if self._music == instance then 
            self._music = nil
        end
        instance:Stop()
        instance:Destroy()
    end
end

function SoundController:PauseMusic(options: PlayOptions?): ()
    local instance = self._music
    if not instance then return end

    local fadeOut = options and options.fadeOut
    if fadeOut and fadeOut > 0 then 
        local tween = TweenService:Create(instance, TweenInfo.new(fadeOut), { Volume = 0 })
        tween:Play()
        tween.Completed:Once(function()
            if self._music == instance then 
                instance:Pause()
            end
        end)
    else
        instance:Pause()
    end
end

function SoundController:ResumeMusic(options: PlayOptions?): ()
    local instance = self._music
    if not instance then return end
    instance:Resume()

    local fadeIn = options and options.fadeIn
    local spec = self:_getSpec(self._musicSoundId)
    local baseVolume = spec.defaults and spec.defaults.volume or 1
    if fadeIn and fadeIn > 0 then 
        local targetVolume = baseVolume
        instance.Volume = 0
        local tween = TweenService:Create(instance, TweenInfo.new(fadeIn), { Volume = targetVolume })
        tween:Play()
    else
        instance.Volume = baseVolume
    end
end

function SoundController:KnitStart(): ()
    self.SoundService.Play:Connect(function(payload: PlayPayload): ()
        if payload.kind == "Music" then 
            local action = payload.action or "Play"
            if action == "Play" then 
                self:PlayMusic(payload.soundId, payload.options)
            elseif action == "Pause" then 
                self:PauseMusic(payload.options)
            elseif action == "Resume" then 
                self:ResumeMusic(payload.options)
            elseif action == "Stop" then 
                self:StopMusic(payload.options)
            end
            
            return
        end
        self:PlayMusic(payload.soundId, payload.options)
    end)
end


function SoundController:KnitInit(): ()
    self.SoundService = Knit.GetService("SoundService")

    local sfxFolder = _ensureFolder(SoundService, "SFX", "Folder") :: Folder
    local uiFolder = _ensureFolder(SoundService, "UI", "Folder") :: Folder
    local musicFolder = _ensureFolder(SoundService, "Music", "Folder") :: Folder
    local ambienceFolder = _ensureFolder(SoundService, "Ambience", "Folder") :: Folder

    self._buses = {
        SFX = { folder = sfxFolder, volume = 1, muted = false },
        UI = { folder = uiFolder, volume = 1, muted = false },
        Music = { folder = musicFolder, volume = 1, muted = false },
        Ambience = { folder = ambienceFolder, volume = 1, muted = false },
    }

    local emitters = _ensureFolder(workspace, "_SoundEmitters", "Folder") :: Folder
    self._emittersFolder = emitters
end


return SoundController