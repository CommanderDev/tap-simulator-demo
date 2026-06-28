--!strict

export type SoundBus = "SFX" | "Music" | "UI" | "Ambience"
export type PlayKind = "2D" | "On" | "At" | "Music"
export type MusicAction = "Play" | "Pause" | "Resume" | "Stop"

export type SoundDefaults = {
	volume: number?,
	pitch: number?,
	looped: boolean?,
	startTime: number?,
	maxDistance: number?,
	rolloffMode: Enum.RollOffMode?,
}

export type WeightedVariant = {
	assetId: string,
	weight: number,
}

export type SoundSpec = {
    bus: SoundBus,
    assetId: string?,
    variants: { WeightedVariant }?,
    defaults: SoundDefaults?,
    tags: { string },
}

export type BusState = {
    folder: Folder,
    volume: number,
    muted: boolean,
}

export type PooledSound = {
    sound: Sound,
    inUse: boolean,
    connection: RbxScriptConnection,
}

export type Registry = { [string]: SoundSpec }

export type Bundle = { string }
export type Bundles = { [string]: Bundle }

export type PlayOptions = {
	volume: number?,
	pitch: number?,
	looped: boolean?,
	startTime: number?,
	maxDistance: number?,
	rolloffMode: Enum.RollOffMode?,
	fadeIn: number?,
	fadeOut: number?,
	seed: number?,
}

export type PlayPayload = {
    kind: PlayKind,
    soundId: string,
    options: PlayOptions?,
    position: Vector3?,
    target: Instance?,
}

return {}