local StructureConfig = {
	IncludeAllServices = true,
	IncludeProperties = true,
	IncludeTags = true,
	IncludeWorkspaceTree = true,
	IgnoreDefaultProps = true,
	UseDynamicPropScan = true,
	BatchSize = 400,
	MaxTextBytes = 8 * 1024 * 1024,
	YieldSeconds = 0.008,
}
local StructureState = {
	objects = {},
	attributes = {},
	descendantCounts = {},
	errors = {},
	processed = 0,
}
local StructurePaths = {
	Attributes = Config.MainFolder .. "/ATTRIBUTES.txt",
	Workspace = Config.MainFolder .. "/WORKSPACE.txt",
	RemoteFolder = Config.MainFolder .. "/REMOTE LIVE",
	RemoteEvents = Config.MainFolder .. "/REMOTE LIVE/RemoteEvents.txt",
	RemoteFunctions = Config.MainFolder .. "/REMOTE LIVE/RemoteFunctions.txt",
	Unreliable = Config.MainFolder .. "/REMOTE LIVE/UnreliableRemoteEvents.txt",
	RemoteIndex = Config.MainFolder .. "/REMOTE LIVE/RemoteIndex.txt",
	ObjectsJson = Config.MainFolder .. "/Metadata/Objects.json",
	AttributesJson = Config.MainFolder .. "/Metadata/Attributes.json",
	RemotesJson = Config.MainFolder .. "/Metadata/Remotes.json",
	Checkpoint = Config.MainFolder .. "/Metadata/StructureCheckpoint.json",
	Errors = Config.MainFolder .. "/Logs/StructureErrors.txt",
}
