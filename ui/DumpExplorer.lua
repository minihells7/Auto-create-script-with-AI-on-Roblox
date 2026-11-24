if _G.DUMP_EXPLORER_LOADED and not _G.DUMP_EXPLORER_DEBUG then
	return
end
pcall(function() getgenv().DUMP_EXPLORER_LOADED = true end)

if not game:IsLoaded() then game.Loaded:Wait() end

local function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

cloneref = missing("function", cloneref, function(...) return ... end)
gethui = missing("function", gethui or get_hidden_gui, function() return game:GetService("CoreGui") end)
syn = missing("table", syn, {})
syn_protect_gui = missing("function", syn and syn.protect_gui)
sethidden = missing("function", sethiddenproperty or set_hidden_property or set_hidden_prop)
gethidden = missing("function", gethiddenproperty or get_hidden_property or get_hidden_prop)
queueteleport = missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))
httprequest = missing("function", request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request))
everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))
firetouchinterest = missing("function", firetouchinterest)

local waxwritefile, waxreadfile = writefile, readfile
writefile = missing("function", waxwritefile) and function(file, data, safe)
	if safe == true then return pcall(waxwritefile, file, data) end
	waxwritefile(file, data)
end
readfile = missing("function", waxreadfile) and function(file, safe)
	if safe == true then return pcall(waxreadfile, file) end
	return waxreadfile(file)
end
isfile = missing("function", isfile, readfile and function(file)
	local success, result = pcall(function() return readfile(file) end)
	return success and result ~= nil and result ~= ""
end)
makefolder = missing("function", makefolder)
isfolder = missing("function", isfolder)
waxgetcustomasset = missing("function", getcustomasset or getsynasset)
hookfunction = missing("function", hookfunction)
hookmetamethod = missing("function", hookmetamethod)
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)
checkcaller = missing("function", checkcaller, function() return false end)
newcclosure = missing("function", newcclosure, function(f) return f end)
getgc = missing("function", getgc or get_gc_objects)
setthreadidentity = missing("function", setthreadidentity or (syn and syn.set_thread_identity) or syn_context_set or setthreadcontext)
replicatesignal = missing("function", replicatesignal)
getconnections = missing("function", getconnections or get_signal_cons)

Services = setmetatable({}, {
	__index = function(self, name)
		local success, cache = pcall(function()
			return cloneref(game:GetService(name))
		end)
		if success then
			rawset(self, name, cache)
			return cache
		else
			error("Invalid Service: " .. tostring(name))
		end
	end
})

local Players = Services.Players
local RunService = Services.RunService
local HttpService = Services.HttpService
local MarketplaceService = Services.MarketplaceService
local LocalPlayer = Players.LocalPlayer
local function resolveServiceRoot(name)
	if name == "PlayerGui" then
		if not LocalPlayer then return nil end
		local ok, pg = pcall(function()
			return LocalPlayer:WaitForChild("PlayerGui", 5)
		end)
		return ok and pg or nil
	end
	local ok, svc = pcall(function() return Services[name] end)
	return ok and svc or nil
end
local function sanitizeName(name)
	name = tostring(name)
	name = name:gsub('[<>:"/\\|?*%c]', "_")
	name = name:gsub("%s+", " ")
	name = name:gsub("^%s+", "")
	name = name:gsub("%.+$", "")
	name = name:gsub("%s+$", "")
	return name == "" and "_" or name
end
local function resolveGameName()
	local name
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		name = info.Name
	end
	if not name or name == "" then
		local okN, gn = pcall(function() return game.Name end)
		if okN and type(gn) == "string" and gn ~= "" and gn ~= "Game" and gn ~= "Place" then
			name = gn
		end
	end
	name = sanitizeName(name or "")
	if name == "_" or name == "" then
		name = "Place " .. tostring(game.PlaceId)
	end
	return name
end
local Config = {
	BaseFolder = "INFORMATION",
	ServiceList = { "ReplicatedFirst", "ReplicatedStorage", "Players", "Workspace", "PlayerGui" },
	EnableLiveHooks = false,
	EnableIncomingHooks = false,
	EnableRakNetAnalysis = true,
	SoakSeconds = 5,
	SkipRobloxScripts = true,
	RobloxScriptExtraNames = {},
	CrashGuard = true,
	AlwaysStub = {
		"ReplicatedStorage.xisd.Enums",
	},
	FastModeYieldSeconds = 3,
	MaxRetries = 2,
	RetryBaseDelay = 0.1,
	RetryBackoffFactor = 1.5,
	CheckpointInterval = 60,
	YieldEvery = 80,
	SaveDelay = 0,
	MaxDecompileBytes = 400000,
	HeavyScriptYieldMs = 15,
	FastSave = true,
	FastSaveBudgetMs = 14,
	LogFlushEvery = 60,
	FastMode = false,
	NameSeparator = " ",
	WriteStubForPanics = true,
	MaxSampleArgs = 5,
	MaxCallLogEntries = 500,
	MaxCallLogPerRemote = 40,
	MaxHookQueue = 2000,
	HookDrainBudget = 200,
	HookMaxObserverErrors = 100,
	CanaryTimeoutSeconds = 1.0,
	ExposeDebugHandle = true,
	SelfTest = false,
}
Config.GameName = resolveGameName()
Config.MainFolder = Config.BaseFolder .. "/" .. Config.GameName
local Env = {
	isfolder = isfolder,
	makefolder = makefolder,
	isfile = isfile,
	readfile = waxreadfile,
	writefile = waxwritefile,
	delfile = missing("function", delfile),
	listfiles = missing("function", listfiles),
	decompile = missing("function", decompile),
	getscriptclosure = missing("function", getscriptclosure),
	getscriptbytecode = missing("function", getscriptbytecode),
	hookmetamethod = hookmetamethod,
	hookfunction = hookfunction,
	getconnections = getconnections,
	getnamecallmethod = getnamecallmethod,
	setnamecallmethod = missing("function", setnamecallmethod),
	checkcaller = checkcaller,
	getcallingscript = missing("function", getcallingscript),
	isexecutorclosure = missing("function", isexecutorclosure),
	getfenv = missing("function", getfenv),
	restorefunction = missing("function", restorefunction),
}
local function has(name)
	return typeof(Env[name]) == "function"
end
local Paths = {
	Root = Config.MainFolder,
	Progress = Config.MainFolder .. "/Metadata progress.json",
	Metadata = Config.MainFolder .. "/Metadata objects.json",
	FailedLog = Config.MainFolder .. "/Logs failed.txt",
	MainLog = Config.MainFolder .. "/Logs dump_log.txt",
	Index = Config.MainFolder .. "/INDEX.txt",
	RemoteMap = Config.MainFolder .. "/REMOTE_MAP.txt",
	CallLog = Config.MainFolder .. "/CALL_LOG.txt",
	ScriptToRem = Config.MainFolder .. "/SCRIPT_TO_REMOTE.txt",
	HookScripts = Config.MainFolder .. "/HOOK_SCRIPTS",
	DispatcherMap = Config.MainFolder .. "/DISPATCHER_ACTIONS.txt",
	GameContext = Config.MainFolder .. "/GAME_CONTEXT.txt",
	EnemiesCatalog = Config.MainFolder .. "/ENEMIES_CATALOG.txt",
	ToolsInventory = Config.MainFolder .. "/TOOLS_INVENTORY.txt",
	PlayerState = Config.MainFolder .. "/PLAYER_STATE.txt",
	ModuleDeps = Config.MainFolder .. "/MODULE_DEPENDENCIES.txt",
	NetRemotes = Config.MainFolder .. "/NET_REMOTES.txt",
	RakNetAnalysis = Config.MainFolder .. "/RAKNET_ANALYSIS.txt",
	WorldItems = Config.MainFolder .. "/WORLD_ITEMS.txt",
	GameModules = Config.MainFolder .. "/GAME_MODULES.txt",
	WorkspaceRemotes = Config.MainFolder .. "/WORKSPACE_REMOTES.txt",
	CrashGuard = Config.MainFolder .. "/Metadata/crash_guard.json",
	Quarantine = Config.MainFolder .. "/Metadata/crash_quarantine.json",
}
local State = {
	StartTime = tick(),
	Total = 0,
	Processed = 0,
	Success = 0,
	Failed = 0,
	Skipped = 0,
	Panicked = 0,
	RobloxSkipped = 0,
	FailedList = {},
	ObjectsMeta = {},
	Checkpoint = { currentService = nil, lastObjectId = nil, lastStatus = nil },
	LogBuffer = {},
	Remotes = {},
	CallLog = {},
	CallLogSuppressed = 0,
	ScriptRemote = {},
	HooksInstalled = false,
	HookCleanups = {},
	NamecallHook = nil,
	HookQueue = nil,
	RunId = nil,
	Cleanups = {},
	Cancelled = false,
	ShuttingDown = false,
	DispatcherActions = {},
	IncomingConns = {},
	IncomingCBPaths = {},
}
local ExecutorSupport = (function()
	local Module = { Name = "Unknown" }
	do
		local ok, name = pcall(identifyexecutor)
		if ok and type(name) == "string" and name ~= "" then Module.Name = name end
	end
	local SETTINGS_PATH = Config.BaseFolder .. "/Settings.json"
	local function ReadSettings()
		if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return {} end
		local ok, data = pcall(function()
			if not isfile(SETTINGS_PATH) then return {} end
			return HttpService:JSONDecode(readfile(SETTINGS_PATH))
		end)
		return (ok and type(data) == "table") and data or {}
	end
	function Module.SetSetting(key, value)
		if typeof(writefile) ~= "function" then return false end
		local data = ReadSettings()
		data[key] = value
		return pcall(function()
			if typeof(isfolder) == "function" and typeof(makefolder) == "function"
				and not isfolder(Config.BaseFolder) then
				makefolder(Config.BaseFolder)
			end
			writefile(SETTINGS_PATH, HttpService:JSONEncode(data))
		end)
	end
	function Module.GetSetting(key, default)
		local v = ReadSettings()[key]
		if v == nil then return default end
		return v
	end
	function Module.GetSupport() return "N/A" end
	return Module
end)()
local OutgoingMethods = {
	FireServer = { RemoteEvent = true, UnreliableRemoteEvent = true },
	fireServer = { RemoteEvent = true, UnreliableRemoteEvent = true },
	InvokeServer= { RemoteFunction = true },
	invokeServer= { RemoteFunction = true },
	Fire = { BindableEvent = true },
	fire = { BindableEvent = true },
	Invoke = { BindableFunction = true },
	invoke = { BindableFunction = true },
}
local IncomingMethod = {
	RemoteEvent = "OnClientEvent",
	RemoteFunction = "OnClientInvoke",
	UnreliableRemoteEvent = "OnClientEvent",
	BindableEvent = "Event",
	BindableFunction = "OnInvoke",
}
local RemoteClasses = {
	RemoteEvent = true,
	RemoteFunction = true,
	UnreliableRemoteEvent = true,
	BindableEvent = true,
	BindableFunction = true,
}
local flushLog
local function writeLog(msg)
	local line = string.format("[%s] %s", os.date("%H:%M:%S"), msg)
	print("[Dump] " .. line)
	table.insert(State.LogBuffer, line)
	if #State.LogBuffer >= Config.LogFlushEvery then
		flushLog()
	end
end
flushLog = function()
	if #State.LogBuffer == 0 then return end
	if has("writefile") then
		pcall(function()
			local chunk = table.concat(State.LogBuffer, "\n") .. "\n"
			if typeof(appendfile) == "function" and has("isfile") and Env.isfile(Paths.MainLog) then
				appendfile(Paths.MainLog, chunk)
			else
				local existing = ""
				if has("isfile") and Env.isfile(Paths.MainLog) then
					local ok, c = pcall(Env.readfile, Paths.MainLog)
					if ok and c then existing = c end
				end
				Env.writefile(Paths.MainLog, existing .. chunk)
			end
		end)
	end
	State.LogBuffer = {}
end
local function createFolderRecursive(path)
	if not has("makefolder") or not has("isfolder") then return end
	local accum = ""
	for part in path:gmatch("[^/]+") do
		accum = (accum == "") and part or (accum .. "/" .. part)
		pcall(function()
			if not Env.isfolder(accum) then Env.makefolder(accum) end
		end)
	end
end
local function writeFileSafe(path, content)
	if not has("writefile") then return false end
	return pcall(Env.writefile, path, content)
end
local WriteQueue = {
	queue = {},
	running = false,
	pending = 0,
	done = 0,
	errors = 0,
}
local function writeQueuePush(path, content)
	if not has("writefile") then return false, "no_writefile" end
	local ok, err
	local resolved = false
	local co = coroutine.running()
	WriteQueue.pending += 1
	table.insert(WriteQueue.queue, {
		path = path,
		content = content,
		resolve = function(rok, rerr)
			ok, err = rok, rerr
			resolved = true
			if co then
				task.spawn(co)
			end
		end,
	})
	if not WriteQueue.running then
		WriteQueue.running = true
		task.spawn(function()
			local baseBudget = (Config.FastSaveBudgetMs or 14) / 1000
			while #WriteQueue.queue > 0 do
				local depth = #WriteQueue.queue
				local budgetSec = baseBudget * math.min(1 + depth / 200, 1.75)
				local frameStart = os.clock()
				while #WriteQueue.queue > 0 do
					local item = table.remove(WriteQueue.queue, 1)
					local wok, werr = pcall(Env.writefile, item.path, item.content)
					WriteQueue.done += 1
					WriteQueue.pending -= 1
					if not wok then WriteQueue.errors += 1 end
					item.resolve(wok, werr)
					if os.clock() - frameStart >= budgetSec then
						task.wait()
						frameStart = os.clock()
						depth = #WriteQueue.queue
						budgetSec = baseBudget * math.min(1 + depth / 200, 1.75)
					end
				end
				task.wait()
			end
			WriteQueue.running = false
		end)
	end
	if not resolved then
		coroutine.yield()
	end
	return ok, err
end
local _writeFileSafeBase = writeFileSafe
writeFileSafe = function(path, content)
	if Config.FastMode then
		if not has("writefile") then return false, "no_writefile" end
		local ok, err = pcall(Env.writefile, path, content)
		return ok, err
	elseif Config.FastSave then
		return writeQueuePush(path, content)
	else
		return _writeFileSafeBase(path, content)
	end
end
local function createAllFolders()
	local dirs = {
		Config.BaseFolder,
		Config.MainFolder,
		Config.MainFolder .. "/Metadata",
		Config.MainFolder .. "/Logs",
		Paths.HookScripts,
	}
	for _, d in ipairs(dirs) do createFolderRecursive(d) end
end
local function loadCheckpoint()
	if has("isfile") and Env.isfile(Paths.Progress) then
		local ok, c = pcall(Env.readfile, Paths.Progress)
		if ok and c and #c > 0 then
			local ok2, d = pcall(function() return HttpService:JSONDecode(c) end)
			if ok2 and type(d) == "table" then State.Checkpoint = d end
		end
	end
	if has("isfile") and Env.isfile(Paths.Metadata) then
		local ok, c = pcall(Env.readfile, Paths.Metadata)
		if ok and c and #c > 0 then
			local ok2, d = pcall(function() return HttpService:JSONDecode(c) end)
			if ok2 and type(d) == "table" then State.ObjectsMeta = d end
		end
	end
end
local function saveCheckpoint()
	pcall(function()
		Env.writefile(Paths.Progress, HttpService:JSONEncode(State.Checkpoint))
	end)
end
local function saveMetadata()
	pcall(function()
		if not Config.FastMode then
			local n = 0
			for _ in pairs(State.ObjectsMeta) do n += 1; if n > 300 then break end end
			if n > 300 then task.wait() end
		end
		Env.writefile(Paths.Metadata, HttpService:JSONEncode(State.ObjectsMeta))
	end)
end
local function getFullPath(instance)
	local ok, path = pcall(function() return instance:GetFullName() end)
	return ok and path or tostring(instance)
end
local function serializeArgType(v)
	local t = typeof(v)
	if t == "Instance" then
		local ok, cn = pcall(function() return v.ClassName end)
		local ok2, nm = pcall(function() return v.Name end)
		return "Instance(" .. (ok and cn or "?") .. ":" .. (ok2 and nm or "?") .. ")"
	elseif t == "table" then
		local keys = 0
		for _ in pairs(v) do keys += 1 end
		return "table{" .. keys .. " keys}"
	elseif t == "function" then
		return "function"
	elseif t == "string" then
		local s = tostring(v)
		s = s:gsub("[%c]", "?")
		if #s > 40 then s = s:sub(1,37) .. "..." end
		return 'string("' .. s .. '")'
	elseif t == "buffer" then
		local length = "unknown"
		if type(buffer) == "table" and type(buffer.len) == "function" then
			local ok, n = pcall(buffer.len, v)
			if ok and type(n) == "number" then length = tostring(n) end
		end
		return "buffer(len=" .. length .. ")"
	elseif t == "number" or t == "boolean" then
		return t .. "(" .. tostring(v) .. ")"
	else
		return t
	end
end
local function serializeArgs(args)
	local parts = {}
	local n = args.n or #args
	for i = 1, math.min(n, 6) do
		parts[i] = serializeArgType(args[i])
	end
	if n > 6 then parts[#parts + 1] = "...+" .. (n - 6) end
	return "{" .. table.concat(parts, ", ") .. "}"
end
local function getCallerInfo()
	local script_name = "?"
	local source = "?"
	local line = "?"
	if has("getcallingscript") then
		local ok, cs = pcall(Env.getcallingscript)
		if ok and cs then
			local ok2, fn = pcall(function() return cs:GetFullName() end)
			script_name = ok2 and fn or tostring(cs)
		end
	end
	pcall(function()
		for level = 3, 10 do
			local s, l = debug.info(level, "sl")
			if not s then break end
			if s ~= "[C]" then
				source = s
				line = tostring(l)
				break
			end
		end
	end)
	return script_name, source, line
end
local function registerRemote(instance)
	local ok, fullPath = pcall(function() return instance:GetFullName() end)
	if not ok then return end
	if State.Remotes[fullPath] then return end
	local ok2, className = pcall(function() return instance.ClassName end)
	if not ok2 or not RemoteClasses[className] then return end
	local inMethod = IncomingMethod[className] or "?"
	local outMethod = "?"
	if className == "RemoteEvent" or className == "UnreliableRemoteEvent" then
		outMethod = "FireServer"
	elseif className == "RemoteFunction" then
		outMethod = "InvokeServer"
	elseif className == "BindableEvent" then
		outMethod = "Fire"
	elseif className == "BindableFunction" then
		outMethod = "Invoke"
	end
	State.Remotes[fullPath] = {
		instance = instance,
		className = className,
		fullPath = fullPath,
		inMethod = inMethod,
		outMethod = outMethod,
		outCalls = 0,
		inCalls = 0,
		logged = 0,
		argSamples = {},
		callers = {},
		seenIncoming = false,
	}
end
local function recordCall(direction, fullPath, args, callerScript)
	local remote = State.Remotes[fullPath]
	if remote then
		if direction == "OUT" then
			remote.outCalls += 1
			if #remote.argSamples < Config.MaxSampleArgs then
				table.insert(remote.argSamples, serializeArgs(args))
			end
			if callerScript and callerScript ~= "?" then
				remote.callers[callerScript] = true
				State.ScriptRemote[callerScript] = State.ScriptRemote[callerScript] or {}
				State.ScriptRemote[callerScript][fullPath] = direction
			end
			local firstArg = args[1]
			if type(firstArg) == "string" and #firstArg <= 60 and not firstArg:find("%s") then
				State.DispatcherActions[fullPath] = State.DispatcherActions[fullPath] or {}
				local bucket = State.DispatcherActions[fullPath]
				if not bucket[firstArg] then
					bucket[firstArg] = { calls = 0, argSamples = {} }
				end
				local entry = bucket[firstArg]
				entry.calls += 1
				local nArgs = args.n or #args
				if #entry.argSamples < 4 and nArgs > 1 then
					local rest = {}
					for i = 2, math.min(nArgs, 5) do
						rest[#rest + 1] = serializeArgType(args[i])
					end
					if #rest > 0 then
						table.insert(entry.argSamples, "{" .. table.concat(rest, ", ") .. "}")
					end
				end
			end
		else
			remote.inCalls += 1
			remote.seenIncoming = true
		end
	end
	local capped = remote ~= nil and (remote.logged or 0) >= Config.MaxCallLogPerRemote
	if capped then
		State.CallLogSuppressed = State.CallLogSuppressed + 1
	elseif #State.CallLog < Config.MaxCallLogEntries then
		if remote then remote.logged = (remote.logged or 0) + 1 end
		table.insert(State.CallLog, string.format(
			"[%s] [%s] %s | args: %s | caller: %s",
			os.date("%H:%M:%S"),
			direction,
			fullPath,
			serializeArgs(args),
			callerScript or "?"
		))
	end
end
local Ring = {}
function Ring.new(cap)
	cap = math.max(1, math.floor(tonumber(cap) or 1))
	return { cap = cap, head = 1, tail = 1, count = 0,
			 pushed = 0, dropped = 0, popped = 0, cleared = 0, slots = {} }
end
function Ring.push(r, item)
	r.pushed = r.pushed + 1
	if r.count >= r.cap then
		r.dropped = r.dropped + 1
		return false
	end
	r.slots[r.head] = item
	r.head = r.head % r.cap + 1
	r.count = r.count + 1
	return true
end
function Ring.pop(r)
	if r.count == 0 then return nil end
	local item = r.slots[r.tail]
	r.slots[r.tail] = nil
	r.tail = r.tail % r.cap + 1
	r.count = r.count - 1
	r.popped = r.popped + 1
	return item
end
function Ring.clear(r)
	r.cleared = r.cleared + r.count
	r.count = 0
	r.head = 1
	r.tail = 1
	r.slots = {}
end
function Ring.invariantOk(r)
	return r.pushed - r.dropped - r.popped - r.cleared == r.count
end
local Hook = { SCHEMA = 1, reg = nil }
function Hook.defaultStore()
	if typeof(getgenv) ~= "function" then return nil end
	local ok, g = pcall(getgenv)
	if ok and type(g) == "table" then return g end
	return nil
end
function Hook.newOwner()
	return tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
end
local function hookNewReg(owner)
	return {
		schema = Hook.SCHEMA, target = "game.__namecall",
		original = nil, observer = nil, owner = owner, state = "installing",
		installs = 0, swaps = 0, errors = 0,
		earlyCalls = 0, tamperCalls = 0,
		methodErrors = 0, observerErrors = 0, restoreErrors = 0, consecRestoreErrors = 0,
		tripped = false, reason = nil, hasSetMethod = false,
		maxObserverErrors = 100,
		canaryOk = false, canarySeq = 0,
		canaryExpected = nil, canaryConfirmed = nil, canaryTarget = nil,
	}
end
local function hookInstrument(REG, obs, getm, setm, self, ...)
	local okM, m = pcall(getm)
	if not (okM and type(m) == "string") then
		REG.methodErrors = REG.methodErrors + 1
		REG.errors = REG.errors + 1
		return
	end
	local okO, did = pcall(obs, self, m, ...)
	if not okO then
		REG.observerErrors = REG.observerErrors + 1
		REG.errors = REG.errors + 1
		if REG.observerErrors > REG.maxObserverErrors then
			REG.observer = nil
			REG.tripped = true
			REG.reason = "observer_errors"
		end
	end
	if setm and ((not okO) or did) then
		if pcall(setm, m) then
			REG.consecRestoreErrors = 0
		else
			REG.restoreErrors = REG.restoreErrors + 1
			REG.consecRestoreErrors = REG.consecRestoreErrors + 1
			REG.errors = REG.errors + 1
			if REG.consecRestoreErrors >= 3 then
				REG.observer = nil
				REG.tripped = true
				REG.reason = "restore_errors"
			end
		end
	end
end
local function hookCountMissing(REG)
	if REG.state == "installing" then
		REG.earlyCalls = REG.earlyCalls + 1
	else
		REG.tamperCalls = REG.tamperCalls + 1
	end
end
function Hook.makeTrampoline(REG, getm, setm)
	return function(self, ...)
		local orig = REG.original
		if orig == nil then
			pcall(hookCountMissing, REG)
			return
		end
		local obs = REG.observer
		if obs then
			pcall(hookInstrument, REG, obs, getm, setm, self, ...)
		end
		return orig(self, ...)
	end
end
function Hook.makeObserver(REG, ring, outgoing)
	local function getClass(o) return o.ClassName end
	local function getName(o) return o.Name end
	local function findCaller()
		local own = debug.info(1, "s")
		for level = 2, 10 do
			local s = debug.info(level, "s")
			if s == nil then break end
			if s ~= "[C]" and s ~= own then return s end
		end
		return nil
	end
	return function(self, m, ...)
		if REG.canaryExpected ~= nil and m == "Fire" and self == REG.canaryTarget then
			local okN, nm = pcall(getName, self)
			if okN and nm == REG.canaryExpected then REG.canaryConfirmed = nm end
			return true
		end
		local byClass = outgoing[m]
		if not byClass then return end
		local okC, cn = pcall(getClass, self)
		if not (okC and cn and byClass[cn]) then return end
		local caller = "?"
		local okF, src = pcall(findCaller)
		if okF and type(src) == "string" then caller = src end
		Ring.push(ring, { instance = self, caller = caller, args = table.pack(...) })
		return true
	end
end
local function hookCanaryFail(REG, myOwner, obs, id, reason)
	if REG.canaryExpected == id then
		REG.canaryExpected = nil
		REG.canaryTarget = nil
	end
	if REG.owner ~= myOwner then
		return false, reason .. " (superseded)"
	end
	REG.observer = nil
	REG.canaryOk = false
	REG.state = "failed"
	REG.reason = reason
	return false, reason
end
local function hookCanaryInner(REG, obs, o)
	local timeout = o.canaryTimeout or Config.CanaryTimeoutSeconds
	local waitf = o.wait or task.wait
	local newTarget = o.newCanaryTarget or function(id)
		local t = Instance.new("BindableEvent")
		t.Name = id
		return t
	end
	local fire = o.fireCanary or function(t, id) t:Fire(id) end
	local myOwner = REG.owner
	REG.canarySeq = REG.canarySeq + 1
	local id = tostring(myOwner) .. ":" .. tostring(REG.canarySeq)
	REG.canaryConfirmed = nil
	REG.canaryExpected = id
	local okT, target = pcall(newTarget, id)
	if not okT or target == nil then
		return hookCanaryFail(REG, myOwner, obs, id, "canary_failed (target)")
	end
	REG.canaryTarget = target
	REG.observer = obs
	pcall(fire, target, id)
	local t0 = os.clock()
	while REG.canaryConfirmed ~= id and (os.clock() - t0) < timeout do
		waitf()
	end
	local confirmed = (REG.canaryConfirmed == id)
	if REG.canaryExpected == id then
		REG.canaryExpected = nil
		REG.canaryTarget = nil
	end
	pcall(function() target:Destroy() end)
	if confirmed then
		REG.canaryOk = true
		return true
	end
	return hookCanaryFail(REG, myOwner, obs, id, "canary_failed")
end
function Hook.runCanary(REG, obs, o)
	local myOwner = REG.owner
	local ok, res, why = pcall(hookCanaryInner, REG, obs, o)
	if ok then return res, why end
	REG.canaryExpected = nil
	REG.canaryTarget = nil
	if REG.owner == myOwner then
		REG.observer = nil
		REG.canaryOk = false
		REG.state = "failed"
		REG.reason = "canary_error: " .. tostring(res)
	end
	return false, "canary_error: " .. tostring(res)
end
function Hook.engage(opts)
	local o = opts or {}
	local store
	if o.store == false then store = nil
	elseif o.store then store = o.store
	else store = Hook.defaultStore() end
	if not store then return false, "no_persistent_store" end
	local hookmeta = o.hookmeta or Env.hookmetamethod
	local getm = o.getm or Env.getnamecallmethod
	local setm
	if o.setm == false then setm = nil
	elseif o.setm then setm = o.setm
	elseif typeof(Env.setnamecallmethod) == "function" then setm = Env.setnamecallmethod end
	if typeof(hookmeta) ~= "function" or typeof(getm) ~= "function" then
		return false, "hookmetamethod/getnamecallmethod unavailable"
	end
	if not o.ring then return false, "no_ring" end
	local owner = o.owner or Hook.newOwner()
	local outgoing = o.outgoing or OutgoingMethods
	local target = o.target or game
	local REG = store.__DUMP_HOOK
	local mode
	if REG == nil then
		REG = hookNewReg(owner)
		REG.maxObserverErrors = o.maxObserverErrors or Config.HookMaxObserverErrors
		REG.hasSetMethod = (setm ~= nil)
		store.__DUMP_HOOK = REG
		Hook.reg = REG
		local tramp = Hook.makeTrampoline(REG, getm, setm)
		local ok, res = pcall(hookmeta, target, "__namecall", tramp)
		if ok and typeof(res) == "function" then
			REG.original = res
			REG.state = "ready"
			REG.installs = 1
		else
			REG.state = "failed"
			REG.reason = ok and "hookmetamethod_returned_non_function"
				or ("hookmetamethod_failed: " .. tostring(res))
			if ok then
				pcall(writeLog, "[ERROR] hookmetamethod returned a non-function: __namecall may be left without an original until rejoin. Do not use Live Hooks with this executor.")
			end
			return false, REG.reason
		end
		mode = "installed"
	else
		if type(REG) ~= "table" then return false, "invalid_registry" end
		if REG.schema ~= Hook.SCHEMA then
			return false, "schema_mismatch (registry=" .. tostring(REG.schema)
				.. " expected=" .. tostring(Hook.SCHEMA) .. ") - rejoin required"
		end
		if REG.state ~= "ready" then
			return false, "registry_state_" .. tostring(REG.state) .. " - rejoin required"
		end
		if REG.original == nil then return false, "invalid_registry (original missing)" end
		Hook.reg = REG
		REG.swaps = REG.swaps + 1
		REG.observerErrors = 0
		REG.consecRestoreErrors = 0
		REG.tripped = false
		REG.reason = nil
		REG.maxObserverErrors = o.maxObserverErrors or Config.HookMaxObserverErrors
		mode = "swapped"
	end
	REG.owner = owner
	local obs = Hook.makeObserver(REG, o.ring, outgoing)
	local okCan, why = Hook.runCanary(REG, obs, o)
	if not okCan then return false, why end
	return true, mode
end
function Hook.detach(owner)
	local REG = Hook.reg
	if not REG then return false end
	if owner ~= nil and REG.owner ~= owner then return false end
	REG.observer = nil
	return true
end
function Hook.statsLine(ring)
	local R = Hook.reg
	local q = ring or { count = 0, pushed = 0, dropped = 0, popped = 0, cleared = 0 }
	return string.format(
		"count=%d pushed=%d dropped=%d popped=%d cleared=%d | earlyCalls=%d tamperCalls=%d swaps=%d installs=%d errors=%d tripped=%s",
		q.count, q.pushed, q.dropped, q.popped, q.cleared,
		R and R.earlyCalls or 0, R and R.tamperCalls or 0, R and R.swaps or 0,
		R and R.installs or 0, R and R.errors or 0, tostring(R and R.tripped or false))
end
local _HookActive = false
local _HeartbeatConn = nil
local _DescConn = nil
local function _processQueue()
	local ring = State.HookQueue
	if not ring then return end
	local budget = Config.HookDrainBudget
	while budget > 0 do
		local item = Ring.pop(ring)
		if not item then break end
		budget = budget - 1
		local inst = item.instance
		local okP, fullPath = pcall(function() return inst:GetFullName() end)
		if okP and fullPath then
			pcall(registerRemote, inst)
			pcall(recordCall, "OUT", fullPath, item.args or {}, item.caller or "?")
		end
	end
end
function Hook.drainAll()
	local ring = State.HookQueue
	if not ring then return end
	local guard = 0
	while ring.count > 0 and guard < 100000 do
		_processQueue()
		guard = guard + 1
	end
end
local function attachIncomingRemote(fullPath, remoteData)
	if not Config.EnableIncomingHooks then return end
	if State.IncomingConns[fullPath] or
	   (function() for _, p in ipairs(State.IncomingCBPaths) do if p == fullPath then return true end end end)()
	then return end
	local inst = remoteData.instance
	local cn = remoteData.className
	if cn == "RemoteEvent" or cn == "UnreliableRemoteEvent" then
		local ok, conn = pcall(function()
			return inst.OnClientEvent:Connect(function(...)
				local args = table.pack(...)
				pcall(recordCall, "IN", fullPath, args, "server")
			end)
		end)
		if ok and conn then
			State.IncomingConns[fullPath] = { disconnect = function() pcall(function() conn:Disconnect() end) end }
		end
	elseif cn == "RemoteFunction" then
		if not has("hookfunction") or not has("getcallbackvalue") then return end
		local okCB, originalCB = pcall(Env.getcallbackvalue, inst, "OnClientInvoke")
		if not okCB then return end
		if originalCB == nil then
			writeLog("  [IN] RemoteFunction sem OnClientInvoke definido: " .. fullPath)
			return
		end
		local okH = pcall(function()
			Env.hookfunction(originalCB, function(...)
				local args = table.pack(...)
				pcall(recordCall, "IN", fullPath, args, "server")
				return originalCB(...)
			end)
		end)
		if okH then
			State.IncomingCBPaths[#State.IncomingCBPaths + 1] = fullPath
		end
	end
end
local function attachAllIncoming()
	if not Config.EnableIncomingHooks then return end
	local attached, failed = 0, 0
	for fullPath, data in pairs(State.Remotes) do
		local ok, err = pcall(attachIncomingRemote, fullPath, data)
		if ok then attached += 1 else failed += 1
			writeLog("  [IN-ERR] " .. fullPath .. ": " .. tostring(err))
		end
	end
	writeLog(string.format("Incoming hooks attached: %d | failed: %d", attached, failed))
end
local function detachAllIncoming()
	for _, entry in pairs(State.IncomingConns) do
		pcall(entry.disconnect)
	end
	State.IncomingConns = {}
	State.IncomingCBPaths = {}
end
local function safeGetService(name)
	local ok, svc = pcall(function()
		return cloneref(game:GetService(name))
	end)
	return ok and svc or nil
end
local function installHooks()
	if State.HooksInstalled then return end
	State.HooksInstalled = true
	for _, svcName in ipairs({ "ReplicatedStorage", "Workspace" }) do
		local svc = safeGetService(svcName)
		if svc then
			pcall(function()
				for _, d in ipairs(svc:GetDescendants()) do
					if RemoteClasses[d.ClassName] then
						registerRemote(d)
					end
				end
			end)
		end
	end
	if Config.EnableLiveHooks then
		State.RunId = State.RunId or Hook.newOwner()
		State.HookQueue = Ring.new(Config.MaxHookQueue)
		_HeartbeatConn = RunService.Heartbeat:Connect(_processQueue)
		if has("hookmetamethod") and has("getnamecallmethod") then
			local okE, okOrWhy, info = pcall(Hook.engage, { ring = State.HookQueue, owner = State.RunId })
			local engaged = okE and okOrWhy == true
			local detail = engaged and info or (okE and info or okOrWhy)
			if engaged then
				_HookActive = true
				writeLog("Hook __namecall " .. tostring(detail) .. " (persistent registry; observer attached; ring cap="
					.. tostring(Config.MaxHookQueue) .. ")")
			else
				writeLog("[WARN] Live hooks OFF (fail-closed): " .. tostring(detail))
			end
		else
			writeLog("[INFO] hookmetamethod not available in this executor")
		end
		writeLog("Soak with live hooks (" .. Config.SoakSeconds .. "s)...")
	else
		writeLog("Safe mode (EnableLiveHooks=false) — passive scan, no hookmetamethod")
		writeLog("Waiting " .. Config.SoakSeconds .. "s for lazy-loaded remotes...")
	end
	pcall(function()
		if _DescConn then pcall(function() _DescConn:Disconnect() end); _DescConn = nil end
		_DescConn = game.DescendantAdded:Connect(function(inst)
			if inst and RemoteClasses[inst.ClassName] then
				registerRemote(inst)
				if Config.EnableIncomingHooks then
					local ok2, fullPath2 = pcall(function() return inst:GetFullName() end)
					if ok2 and fullPath2 and State.Remotes[fullPath2] then
						pcall(attachIncomingRemote, fullPath2, State.Remotes[fullPath2])
					end
				end
			end
		end)
	end)
	if Config.EnableIncomingHooks then
		local inSupported = has("hookfunction") or true
		if inSupported then
			attachAllIncoming()
			writeLog("Incoming capture: active (RemoteEvent via Connect | RemoteFunction via hookfunction)")
		else
			writeLog("[INFO] Incoming hooks: hookfunction indisponível neste executor.")
		end
	else
		writeLog("Incoming capture: disabled (EnableIncomingHooks=false)")
	end
end
local function uninstallHooks()
	if State.RunId then Hook.detach(State.RunId) end
	pcall(detachAllIncoming)
	pcall(Hook.drainAll)
	if _HeartbeatConn then
		pcall(function() _HeartbeatConn:Disconnect() end)
		_HeartbeatConn = nil
	end
	if State.HookQueue then
		Ring.clear(State.HookQueue)
		writeLog("Hooks stopped. " .. Hook.statsLine(State.HookQueue))
	else
		writeLog("Hooks stopped. Queue drained.")
	end
	_HookActive = false
	State.HooksInstalled = false
end
local Lifecycle = {}
function Lifecycle.add(fn)
	if type(fn) == "function" then State.Cleanups[#State.Cleanups + 1] = fn end
end
function Lifecycle.shutdown(reason)
	if State.ShuttingDown then return end
	State.ShuttingDown = true
	State.Cancelled = true
	for i = #State.Cleanups, 1, -1 do pcall(State.Cleanups[i]) end
	State.Cleanups = {}
	if State.HooksInstalled or State.RunId then pcall(uninstallHooks) end
	if _DescConn then pcall(function() _DescConn:Disconnect() end); _DescConn = nil end
	local store = Hook.defaultStore()
	if store and store.__DumpExplorerCleanup == Lifecycle.handle then store.__DumpExplorerCleanup = nil end
	if store and store.__DumpExplorerState == State then store.__DumpExplorerState = nil end
	pcall(writeLog, "Session cleaned (" .. tostring(reason or "?") .. ")")
end
function Lifecycle.boot()
	local store = Hook.defaultStore()
	if not store then return end
	local prev = store.__DumpExplorerCleanup
	if type(prev) == "function" then pcall(prev, "reexecution") end
	Lifecycle.handle = function(reason) Lifecycle.shutdown(reason or "external") end
	store.__DumpExplorerCleanup = Lifecycle.handle
	if Config.ExposeDebugHandle then store.__DumpExplorerState = State end
end
local function cancelPoint()
	if State.Cancelled then error("DumpExplorer cancelled", 0) end
end
local SelfTest = { results = {}, failed = 0, passed = 0 }
local function stCheck(name, cond, detail)
	if cond then
		SelfTest.passed = SelfTest.passed + 1
		SelfTest.results[#SelfTest.results + 1] = "PASS " .. name
	else
		SelfTest.failed = SelfTest.failed + 1
		SelfTest.results[#SelfTest.results + 1] = "FAIL " .. name .. (detail and (" | " .. tostring(detail)) or "")
	end
end
function SelfTest.ring()
	local r = Ring.new(4)
	stCheck("ST-05.new: invariante", Ring.invariantOk(r) and r.count == 0)
	for i = 1, 4 do Ring.push(r, i); stCheck("ST-05.fill " .. i .. ": invariante", Ring.invariantOk(r)) end
	stCheck("ST-05.capacidade: count==cap", r.count == 4 and r.dropped == 0)
	for i = 5, 7 do
		local acc = Ring.push(r, i)
		stCheck("ST-05.overflow " .. i .. ": rejeita (descarta o novo)", acc == false and Ring.invariantOk(r))
	end
	stCheck("ST-05.overflow: pushed=7 dropped=3 count=4", r.pushed == 7 and r.dropped == 3 and r.count == 4)
	local a, b = Ring.pop(r), Ring.pop(r)
	stCheck("ST-05.FIFO: 1,2", a == 1 and b == 2 and r.popped == 2 and Ring.invariantOk(r))
	Ring.push(r, 8); Ring.push(r, 9)
	stCheck("ST-05.wrap-around: invariante", Ring.invariantOk(r) and r.count == 4)
	local seq = {}
	while true do local x = Ring.pop(r); if x == nil then break end; seq[#seq + 1] = x end
	stCheck("ST-05.wrap-around: ordem 3,4,8,9", table.concat(seq, ",") == "3,4,8,9", table.concat(seq, ","))
	stCheck("ST-05.vazia: pop devolve nil", Ring.pop(r) == nil and Ring.invariantOk(r))
	local c = Ring.new(5)
	for i = 1, 8 do Ring.push(c, i) end
	Ring.pop(c)
	local pBefore, dBefore = c.pushed, c.dropped
	Ring.clear(c)
	stCheck("ST-05.clear: count=0, cleared=4", c.count == 0 and c.cleared == 4, c.cleared)
	stCheck("ST-05.clear: pushed/dropped preservados", c.pushed == pBefore and c.dropped == dBefore)
	stCheck("ST-05.clear: invariante", Ring.invariantOk(c))
	Ring.push(c, 100)
	stCheck("ST-05.pos-clear: aceita e devolve", c.count == 1 and Ring.pop(c) == 100 and Ring.invariantOk(c))
	Ring.clear(c)
	stCheck("ST-05.clear vazia: sem efeito", c.cleared == 4 and Ring.invariantOk(c))
	local one = Ring.new(1)
	Ring.push(one, "a"); local acc = Ring.push(one, "b")
	stCheck("ST-05.cap1: rejeita segundo", acc == false and Ring.pop(one) == "a" and Ring.invariantOk(one))
	local seed = 12345
	local function rnd(n) seed = (seed * 16807) % 2147483647; return seed % n end
	local q, model, ok = Ring.new(7), {}, true
	local mPushed, mDropped, mPopped, mCleared = 0, 0, 0, 0
	for step = 1, 2000 do
		local op = rnd(10)
		if op < 5 then
			mPushed = mPushed + 1
			if #model >= 7 then mDropped = mDropped + 1; Ring.push(q, step)
			else model[#model + 1] = step; Ring.push(q, step) end
		elseif op < 9 then
			local got = Ring.pop(q)
			local want = table.remove(model, 1)
			if want ~= nil then mPopped = mPopped + 1 end
			if got ~= want then ok = false end
		else
			mCleared = mCleared + #model; model = {}; Ring.clear(q)
		end
		if not Ring.invariantOk(q) or q.count ~= #model then ok = false end
	end
	stCheck("ST-05.modelo (2000 passos, semente fixa): FIFO, contadores e invariante",
		ok and q.pushed == mPushed and q.dropped == mDropped and q.popped == mPopped and q.cleared == mCleared)
end
local function stNewSim()
	local sim = { st = { method = nil }, calls = {}, getmCalls = 0, setmCalls = 0, hookCalls = 0 }
	sim.target = {
		__namecall = function(self, ...)
			sim.calls[#sim.calls + 1] = { self = self, method = sim.st.method, n = select("#", ...), args = table.pack(...) }
			return "r1", nil, "r3"
		end,
	}
	sim.hookmeta = function(tgt, name, fn)
		sim.hookCalls = sim.hookCalls + 1
		local orig = tgt[name]
		tgt[name] = fn
		return orig
	end
	sim.getm = function() sim.getmCalls = sim.getmCalls + 1; return sim.st.method end
	sim.setm = function(m) sim.setmCalls = sim.setmCalls + 1; sim.st.method = m end
	function sim.dispatch(self, method, ...)
		sim.st.method = method
		return sim.target.__namecall(self, ...)
	end
	sim.newCanaryTarget = function(id) return { ClassName = "BindableEvent", Name = id } end
	sim.fireCanary = function(t, id) sim.dispatch(t, "Fire", id) end
	return sim
end
local function stOpts(sim, store, ring, extra)
	local o = { store = store, hookmeta = sim.hookmeta, getm = sim.getm, setm = sim.setm,
				target = sim.target, ring = ring, outgoing = { Fire = { BindableEvent = true } },
				newCanaryTarget = sim.newCanaryTarget, fireCanary = sim.fireCanary,
				wait = function() end, canaryTimeout = 0.05, maxObserverErrors = 3 }
	if extra then for k, v in pairs(extra) do o[k] = v end end
	return o
end
local function stInst() return { ClassName = "BindableEvent", Name = "x" } end
function SelfTest.hook()
	local sim, store, ring = stNewSim(), {}, Ring.new(50)
	local ok, mode = Hook.engage(stOpts(sim, store, ring, { owner = "A" }))
	local R = store.__DUMP_HOOK
	stCheck("ST-07.1a primeira instalação: ok/installed", ok == true and mode == "installed", tostring(mode))
	stCheck("ST-07.1b estado ready, installs=1, hookmetamethod chamado 1x", R and R.state == "ready" and R.installs == 1 and sim.hookCalls == 1)
	stCheck("ST-07.1c canário confirmado com o id correto", R and R.canaryOk == true and R.canarySeq == 1 and R.canaryExpected == nil and R.canaryTarget == nil)
	stCheck("ST-07.1d earlyCalls==0", R and R.earlyCalls == 0)
	stCheck("ST-07.1e canário NÃO entrou na fila", ring.count == 0 and #sim.calls == 1, "calls=" .. #sim.calls)
	local callsBefore = #sim.calls
	local inst = stInst()
	local a, b, c, d = sim.dispatch(inst, "Fire", 1, nil, 3)
	stCheck("ST-07.2a original chamado exatamente 1x", #sim.calls == callsBefore + 1)
	local last = sim.calls[#sim.calls]
	stCheck("ST-07.2b args com nil preservados no original (n==3, [2]==nil)", last.n == 3 and last.args[1] == 1 and last.args[2] == nil and last.args[3] == 3)
	stCheck("ST-07.2c múltiplos retornos preservados (r1,nil,r3)", a == "r1" and b == nil and c == "r3" and d == nil)
	stCheck("ST-07.2d método de namecall preservado no original", last.method == "Fire")
	stCheck("ST-07.2e fila recebeu 1 item com args.n==3 e args[2]==nil", ring.count == 1)
	local item = Ring.pop(ring)
	stCheck("ST-07.2f item: instance/args.n/nil no meio", item and item.instance == inst and item.args.n == 3 and item.args[2] == nil)
	sim.dispatch(inst, "GetFullName")
	stCheck("ST-07.3 método fora da tabela: encaminha 1x, não enfileira", ring.count == 0 and sim.calls[#sim.calls].method == "GetFullName")
	local rings, ids = { ring }, { R.canarySeq }
	for i = 1, 3 do
		local nr = Ring.new(50)
		local ok2, mode2 = Hook.engage(stOpts(sim, store, nr, { owner = "B" .. i }))
		rings[#rings + 1] = nr
		ids[#ids + 1] = R.canarySeq
		stCheck("ST-07.4." .. i .. "a reexecução: swapped", ok2 == true and mode2 == "swapped", tostring(mode2))
	end
	stCheck("ST-07.4b installs continua 1; hookmetamethod ainda 1x; swaps==3", R.installs == 1 and sim.hookCalls == 1 and R.swaps == 3)
	stCheck("ST-07.4c ids de canário distintos e crescentes", ids[1] < ids[2] and ids[2] < ids[3] and ids[3] < ids[4])
	local cb = #sim.calls
	sim.dispatch(stInst(), "Fire", "x")
	stCheck("ST-07.4d após 3 trocas: original 1x, SÓ o anel novo recebe (sem empilhar)",
		#sim.calls == cb + 1 and rings[4].count == 1 and rings[3].count == 0 and rings[2].count == 0 and rings[1].count == 0)
	stCheck("ST-07.4e owner atualizado", R.owner == "B3")
	do
		local sm0 = sim.setmCalls
		sim.dispatch(inst, "GetFullName")
		local filteredCalls = sim.setmCalls - sm0
		sim.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.3b restauração só quando o observer fez trabalho (filtrado 0x, casado 1x)", filteredCalls == 0 and sim.setmCalls - sm0 == 1, filteredCalls .. "/" .. (sim.setmCalls - sm0))
	end
	stCheck("ST-07.5a detach de owner antigo é ignorado", Hook.detach("A") == false and R.observer ~= nil)
	stCheck("ST-07.5b detach do owner atual deixa inerte", Hook.detach("B3") == true and R.observer == nil)
	local gm, rc = sim.getmCalls, rings[4].count
	local cb2 = #sim.calls
	local x1, x2, x3 = sim.dispatch(stInst(), "Fire", 9)
	stCheck("ST-07.5c inerte: getnamecallmethod chamado 0x, nada enfileirado, original 1x, retornos intactos",
		sim.getmCalls == gm and rings[4].count == rc and #sim.calls == cb2 + 1 and x1 == "r1" and x2 == nil and x3 == "r3")
	local sim6 = stNewSim()
	local ok6, why6 = Hook.engage(stOpts(sim6, false, Ring.new(5)))
	stCheck("ST-07.6 sem getgenv: fail-closed, nada instalado", ok6 == false and why6 == "no_persistent_store" and sim6.hookCalls == 0)
	local sim7 = stNewSim()
	local ok7, why7 = Hook.engage(stOpts(sim7, { __DUMP_HOOK = { schema = 999, state = "ready", original = function() end } }, Ring.new(5)))
	stCheck("ST-07.7a schema incompatível: fail-closed", ok7 == false and tostring(why7):find("schema_mismatch", 1, true) ~= nil and sim7.hookCalls == 0, tostring(why7))
	local ok7b, why7b = Hook.engage(stOpts(sim7, { __DUMP_HOOK = { schema = Hook.SCHEMA, state = "installing" } }, Ring.new(5)))
	stCheck("ST-07.7b 'installing' órfão: fail-closed", ok7b == false and tostring(why7b):find("installing", 1, true) ~= nil and sim7.hookCalls == 0)
	local ok7c, why7c = Hook.engage(stOpts(sim7, { __DUMP_HOOK = { schema = Hook.SCHEMA, state = "failed" } }, Ring.new(5)))
	stCheck("ST-07.7c 'failed': fail-closed, sem retry", ok7c == false and tostring(why7c):find("failed", 1, true) ~= nil and sim7.hookCalls == 0)
	local ok7d = Hook.engage(stOpts(sim7, { __DUMP_HOOK = "lixo" }, Ring.new(5)))
	stCheck("ST-07.7d registro inválido: fail-closed", ok7d == false and sim7.hookCalls == 0)
	local sim8 = stNewSim(); sim8.hookmeta = function() error("boom") end
	local st8 = {}
	local ok8, why8 = Hook.engage(stOpts(sim8, st8, Ring.new(5)))
	stCheck("ST-07.8a hookmetamethod com erro: failed", ok8 == false and st8.__DUMP_HOOK.state == "failed" and tostring(why8):find("hookmetamethod_failed", 1, true) ~= nil)
	local sim8b = stNewSim(); sim8b.hookmeta = function() return nil end
	local st8b = {}
	local ok8b = Hook.engage(stOpts(sim8b, st8b, Ring.new(5)))
	stCheck("ST-07.8b hookmetamethod sem retorno: failed", ok8b == false and st8b.__DUMP_HOOK.state == "failed")
	do
		local s8, st8c = stNewSim(), {}
		s8.hookmeta = function(tgt, name, fn) s8.hookCalls = s8.hookCalls + 1; tgt[name] = fn; return nil end
		Hook.engage(stOpts(s8, st8c, Ring.new(5)))
		local R8 = st8c.__DUMP_HOOK
		local r1 = s8.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.8c LIMITAÇÃO documentada: hook aplicado sem original => chamadas NÃO encaminhadas e contadas (tamperCalls)",
			R8.state == "failed" and R8.tamperCalls == 1 and #s8.calls == 0 and r1 == nil)
	end
	local variants = {
		{ "ausente (nil)",   function() return nil end },
		{ "com erro",        function() error("falha") end },
		{ "não-string",      function() return 42 end },
	}
	for _, v in ipairs(variants) do
		local s9b, st9b, r9b = stNewSim(), {}, Ring.new(10)
		s9b.getm = v[2]
		local okc = Hook.engage(stOpts(s9b, st9b, r9b, { fireCanary = function(t, id) st9b.__DUMP_HOOK.canaryConfirmed = id end }))
		local R9b = st9b.__DUMP_HOOK
		local cb9 = #s9b.calls
		local y1, y2, y3 = s9b.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.9 getnamecallmethod " .. v[1] .. ": original 1x, retornos intactos, nada enfileirado, methodErrors++",
			okc == true and #s9b.calls == cb9 + 1 and y1 == "r1" and y3 == "r3" and r9b.count == 0 and R9b.methodErrors == 1,
			"methodErrors=" .. tostring(R9b and R9b.methodErrors))
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s, st, r, { setm = false }))
		local R2 = st.__DUMP_HOOK
		local cb10 = #s.calls
		s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.10a setnamecallmethod ausente: encaminha 1x, enfileira, sem restauração",
			#s.calls == cb10 + 1 and r.count == 1 and R2.hasSetMethod == false and s.setmCalls == 0)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		local failNext = 0
		s.setm = function(m) s.setmCalls = s.setmCalls + 1; if failNext > 0 then failNext = failNext - 1; error("setm falhou") end; s.st.method = m end
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		local function callOnce() local cb = #s.calls; local a1, a2, a3 = s.dispatch(stInst(), "Fire", 1); return (#s.calls == cb + 1) and a1 == "r1" and a3 == "r3" end
		failNext = 2
		local c1, c2 = callOnce(), callOnce()
		stCheck("ST-07.10b duas falhas seguidas: continua encaminhando 1x, não dispara o disjuntor",
			c1 and c2 and R2.restoreErrors == 2 and R2.consecRestoreErrors == 2 and R2.observer ~= nil and R2.tripped == false)
		failNext = 0
		callOnce()
		stCheck("ST-07.10c um sucesso zera as consecutivas", R2.consecRestoreErrors == 0 and R2.restoreErrors == 2)
		failNext = 3
		local c3, c4, c5 = callOnce(), callOnce(), callOnce()
		stCheck("ST-07.10d três falhas seguidas: disjuntor desativa o observer (restore_errors), ainda encaminha",
			c3 and c4 and c5 and R2.tripped == true and R2.observer == nil and R2.reason == "restore_errors")
		local gm2, cnt = s.getmCalls, r.count
		local c6 = callOnce()
		stCheck("ST-07.10e após o disparo: inerte (getnamecallmethod 0x) e continua encaminhando", c6 and s.getmCalls == gm2 and r.count == cnt)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		R2.observer = function() error("observer quebrado") end
		local okAll = true
		for i = 1, 3 do
			local cb = #s.calls
			local a1, a2, a3 = s.dispatch(stInst(), "Fire", i)
			if not (#s.calls == cb + 1 and a1 == "r1" and a3 == "r3") then okAll = false end
		end
		stCheck("ST-07.11a observer com erro: sempre encaminha 1x, retornos intactos", okAll and R2.observerErrors == 3 and R2.observer ~= nil)
		s.dispatch(stInst(), "Fire", 4)
		stCheck("ST-07.11b erros além do limite: disjuntor (observer_errors)", R2.tripped == true and R2.observer == nil and R2.reason == "observer_errors", tostring(R2.reason))
		local s2, st2, r2 = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s2, st2, r2))
		st2.__DUMP_HOOK.observer = function() return "ignorado", 1, 2 end
		local cb = #s2.calls
		local z1, z2, z3, z4 = s2.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.11c observer devolve valores: ignorados, retornos do original intactos", #s2.calls == cb + 1 and z1 == "r1" and z2 == nil and z3 == "r3" and z4 == nil)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		R2.errors, R2.observerErrors, R2.methodErrors, R2.restoreErrors, R2.consecRestoreErrors, R2.maxObserverErrors = nil, nil, nil, nil, nil, nil
		s.getm = function() error("x") end
		local okAll = true
		for i = 1, 2 do
			local cb = #s.calls
			local a1, a2, a3 = s.dispatch(stInst(), "Fire", i)
			if not (#s.calls == cb + 1 and a1 == "r1" and a3 == "r3") then okAll = false end
		end
		stCheck("ST-07.11d REG adulterado (campos nil): ainda encaminha 1x com retornos intactos", okAll)
	end
	do
		local called = 0
		local Rd = { state = "installing", original = nil, observer = nil, earlyCalls = 0, tamperCalls = 0, maxObserverErrors = 3 }
		local t = Hook.makeTrampoline(Rd, function() return "Fire" end, nil)
		local ret = t({}, 1)
		stCheck("ST-07.12a D1 (installing): conta earlyCalls e NÃO encaminha", Rd.earlyCalls == 1 and Rd.tamperCalls == 0 and ret == nil)
		Rd.state = "ready"
		local obsCalled = false
		Rd.observer = function() obsCalled = true end
		t({}, 1)
		stCheck("ST-07.12c D1 com observer ligado: o observer NÃO é chamado", obsCalled == false)
		stCheck("ST-07.12b original nil fora de 'installing': conta tamperCalls", Rd.earlyCalls == 1 and Rd.tamperCalls == 1)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local okc, whyc = Hook.engage(stOpts(s, st, r, { fireCanary = function() end }))
		local R2 = st.__DUMP_HOOK
		stCheck("ST-07.13a canário descartado: timeout, observer desativado, failed",
			okc == false and whyc == "canary_failed" and R2.observer == nil and R2.state == "failed" and R2.canaryOk == false and R2.canaryExpected == nil)
		local cb = #s.calls
		local q1, q2, q3 = s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.13b após falha do canário: continua encaminhando 1x", #s.calls == cb + 1 and q1 == "r1" and q3 == "r3" and r.count == 0)
		local ok2, why2 = Hook.engage(stOpts(s, st, Ring.new(5)))
		stCheck("ST-07.13c nova execução: fail-closed (registry_state_failed), sem novo hook", ok2 == false and tostring(why2):find("registry_state_failed", 1, true) ~= nil and s.hookCalls == 1)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		local resetSeen = nil
		local ok2 = Hook.engage(stOpts(s, st, Ring.new(5), { owner = "N", fireCanary = function(t, id)
			resetSeen = (R2.canaryConfirmed == nil)
			R2.canaryConfirmed = "id-velho"
		end }))
		stCheck("ST-07.13d reset antes da troca e confirmação de id errado NÃO vale", resetSeen == true and ok2 == false and R2.state == "failed")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local ok = Hook.engage(stOpts(s, st, r, { newCanaryTarget = function() error("sem Instance") end }))
		stCheck("ST-07.13e alvo do canário falha: fail-closed", ok == false and st.__DUMP_HOOK.observer == nil and st.__DUMP_HOOK.state == "failed")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local ok = Hook.engage(stOpts(s, st, r, { fireCanary = function(t, id)
			s.dispatch({ ClassName = "BindableEvent", Name = id }, "Fire", id)
		end }))
		stCheck("ST-07.13f objeto diferente com o mesmo Name não confirma o canário", ok == false and st.__DUMP_HOOK.state == "failed")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		s.getm = function() error("getnamecallmethod quebrado") end
		local ok, why = Hook.engage(stOpts(s, st, r))
		local cb = #s.calls
		local q = s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.13g getnamecallmethod quebrado: canário falha e o jogo continua sendo encaminhado",
			ok == false and why == "canary_failed" and st.__DUMP_HOOK.observer == nil and #s.calls == cb + 1 and q == "r1")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local ok, why = Hook.engage(stOpts(s, st, r, { fireCanary = function() end, wait = function() error("sem task.wait") end }))
		local R2 = st.__DUMP_HOOK
		stCheck("ST-07.13h erro dentro do canário: observer nil, failed, canaryExpected limpo",
			ok == false and R2.observer == nil and R2.state == "failed" and R2.canaryExpected == nil and tostring(why):find("canary_error", 1, true) ~= nil, tostring(why))
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		local otherObs = function() end
		local ok, why = Hook.engage(stOpts(s, st, Ring.new(5), { owner = "ANTIGA", fireCanary = function()
			R2.owner = "NOVA"; R2.observer = otherObs
		end }))
		stCheck("ST-07.13i execução superada: não derruba o observer da nova, estado intacto",
			ok == false and tostring(why):find("superseded", 1, true) ~= nil and R2.observer == otherObs and R2.state == "ready")
	end
	do
		local s, st, r1 = stNewSim(), {}, Ring.new(5)
		Hook.engage(stOpts(s, st, r1))
		st.__DUMP_HOOK = nil
		local r2 = Ring.new(5)
		Hook.engage(stOpts(s, st, r2))
		local cb, b1, b2 = #s.calls, r1.count, r2.count
		s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.14 LIMITAÇÃO documentada (simulação): sem registro, a 2ª instalação empilha (2 camadas, as duas observam a mesma chamada) e o original ainda roda 1x",
			s.hookCalls == 2 and r1.count == b1 + 1 and r2.count == b2 + 1 and #s.calls == cb + 1)
	end
end
function SelfTest.run()
	local savedReg = Hook.reg
	SelfTest.results, SelfTest.failed, SelfTest.passed = {}, 0, 0
	local okR, errR = pcall(SelfTest.ring)
	if not okR then stCheck("ST-05 abortou", false, errR) end
	local okH, errH = pcall(SelfTest.hook)
	if not okH then stCheck("ST-07 abortou", false, errH) end
	local lines = {
		"TESTES DE LOGICA EM SIMULACAO (ST-05, ST-07) - NAO SAO TESTES DO EXECUTOR REAL",
		"Nenhum hook real foi instalado em `game`. Resultado deste file NAO prova o comportamento no Roblox.",
		string.format("PASS=%d FAIL=%d", SelfTest.passed, SelfTest.failed), "",
	}
	for _, l in ipairs(SelfTest.results) do lines[#lines + 1] = l end
	Hook.reg = savedReg
	local text = table.concat(lines, "\n")
	pcall(function()
		if has("writefile") then
			local dir = Config.BaseFolder .. "/_selftest"
			createFolderRecursive(dir)
			Env.writefile(dir .. "/selftest_" .. tostring(os.time()) .. ".txt", text)
		end
	end)
	pcall(print, "[DumpExplorer][selftest] PASS=" .. SelfTest.passed .. " FAIL=" .. SelfTest.failed .. " (simulação de lógica, não é teste do executor real)")
	return text
end
local PANIC_MARKERS = {
	"-- decompilation panicked",
	"decompilation panicked",
	"paniced",
	"panicked",
}
local function isPanicString(s)
	if type(s) ~= "string" then return false end
	local sl = s:lower()
	for _, m in ipairs(PANIC_MARKERS) do
		if sl:find(m, 1, true) then return true end
	end
	return false
end
local function buildHeader(obj, fullName, serviceName, method)
	return table.concat({
		"--[[",
		"    DUMP: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"    Service  : " .. serviceName,
		"    Path     : " .. fullName,
		"    Class    : " .. obj.ClassName,
		"    Method   : " .. tostring(method),
		"    PlaceId  : " .. tostring(game.PlaceId),
		"]]", "",
	}, "\n")
end
local function buildStub(obj, fullName, serviceName)
	local lines = {
		"--[[",
		"    STUB — decompilation unavailable",
		"    Service  : " .. serviceName,
		"    Path     : " .. fullName,
		"    Class    : " .. obj.ClassName,
		"    PlaceId  : " .. tostring(game.PlaceId),
		"    Date     : " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
		"    ANCESTRY:",
	}
	local cur = obj
	local depth = 0
	while cur and depth < 15 do
		local okN, n = pcall(function() return cur.Name end)
		local okC, c = pcall(function() return cur.ClassName end)
		table.insert(lines, "    " .. string.rep("  ", depth) .. "- " .. tostring(okN and n or "?") .. " (" .. tostring(okC and c or "?") .. ")")
		local okP, p = pcall(function() return cur.Parent end)
		if not okP or not p or p == game then break end
		cur = p
		depth += 1
	end
	local okA, attrs = pcall(function() return obj:GetAttributes() end)
	if okA and attrs and next(attrs) then
		table.insert(lines, "")
		table.insert(lines, "    ATTRIBUTES:")
		for k, v in pairs(attrs) do
			table.insert(lines, "    " .. tostring(k) .. " = " .. tostring(v))
		end
	end
	local okCh, children = pcall(function() return obj:GetChildren() end)
	if okCh and children and #children > 0 then
		table.insert(lines, "")
		table.insert(lines, "    DIRECT CHILDREN:")
		for _, child in ipairs(children) do
			local okCN, cn = pcall(function() return child.Name end)
			local okCC, cc = pcall(function() return child.ClassName end)
			table.insert(lines, "    - " .. tostring(okCN and cn or "?") .. " (" .. tostring(okCC and cc or "?") .. ")")
		end
	end
	table.insert(lines, "]]")
	return table.concat(lines, "\n")
end
local function tryClosure(obj)
	if not has("getscriptclosure") then return nil end
	local ok, cl = pcall(Env.getscriptclosure, obj)
	if not ok or type(cl) ~= "function" then return nil end
	local lines = {
		"-- SOURCE: getscriptclosure",
		"-- Executor did not decompile but exposed the closure.",
		"",
	}
	pcall(function()
		local info = debug.getinfo(cl) or {}
		if info.what then
			table.insert(lines, string.format(
				"-- what=%s | nups=%s | numparams=%s",
				info.what, tostring(info.nups), tostring(info.numparams)
			))
		end
		for i = 1, (info.nups or 0) do
			local n, v = debug.getupvalue(cl, i)
			if n then
				table.insert(lines, string.format("-- upvalue[%d] %s : %s", i, n, type(v)))
			end
		end
	end)
	return table.concat(lines, "\n")
end
local function tryBytecodeRef(obj)
	if not has("getscriptbytecode") then return nil end
	local ok, bc = pcall(Env.getscriptbytecode, obj)
	if not ok or type(bc) ~= "string" or #bc == 0 then return nil end
	return string.format(
		"-- SOURCE: getscriptbytecode\n-- Bytecode available (%d bytes) — use an external decompiler.\n",
		#bc
	)
end
local function checkBytecodeAccessible(obj)
	if not has("getscriptbytecode") then
		return nil, 0
	end
	local ok, bc = pcall(Env.getscriptbytecode, obj)
	if not ok or type(bc) ~= "string" then
		return false, 0
	end
	if #bc == 0 then
		return false, 0
	end
	return true, #bc
end
local function tryDecompile(obj, fullName, serviceName)
	if Config.SkipAllScriptContent then
		return true, buildStub(obj, fullName, serviceName), "stub_skipped", 0, "panicked"
	end
	local bytecodeOk, bytecodeSize = checkBytecodeAccessible(obj)
	if bytecodeOk == false then
		writeLog("  [SKIP] no bytecode: " .. fullName)
		if Config.WriteStubForPanics then
			return true, buildStub(obj, fullName, serviceName), "stub_no_bytecode", 1, "no_bytecode"
		end
		return false, nil, "no accessible bytecode", 0, "failed"
	end
	local maxBytes = tonumber(Config.MaxDecompileBytes) or 400000
	if bytecodeOk == true and bytecodeSize > maxBytes then
		writeLog(string.format(
			"  [SKIP] script pesado (%d bytes; limite %d): %s",
			bytecodeSize, maxBytes, fullName
		))
		local ref = string.format(
			"-- SOURCE: bytecode_ref (too large: %d bytes, skip decompile)\n",
			bytecodeSize
		)
		return true,
			buildHeader(obj, fullName, serviceName, "getscriptbytecode") .. ref,
			"getscriptbytecode", 1, "bytecode_ref"
	end
	if bytecodeOk == true and bytecodeSize > 100000 then
		local yieldMs = tonumber(Config.HeavyScriptYieldMs) or 50
		task.wait(math.max(0, yieldMs) / 1000)
	end
	local delay = Config.RetryBaseDelay
	if has("decompile") then
		for attempt = 1, Config.MaxRetries do
			local ok, source = pcall(Env.decompile, obj)
			if ok and type(source) == "string" and #source > 0 and not isPanicString(source) then
				return true, buildHeader(obj, fullName, serviceName, "decompile") .. source, "decompile", attempt, "success"
			end
			local panic = (ok and isPanicString(source)) or (not ok and isPanicString(tostring(source or "")))
			if panic then
				writeLog("  [PANIC] " .. fullName)
				break
			end
			if attempt < Config.MaxRetries then
				task.wait(delay)
				delay = delay * Config.RetryBackoffFactor
			end
		end
	end
	local cl = tryClosure(obj)
	if cl then
		return true, buildHeader(obj, fullName, serviceName, "getscriptclosure") .. cl, "getscriptclosure", 1, "closure_stub"
	end
	if bytecodeOk == true then
		local bcRef = string.format(
			"-- SOURCE: getscriptbytecode\n-- Bytecode accessible (%d bytes) — decompile failed but data exists.\n-- Use an external decompiler (luau-decompile).\n",
			bytecodeSize
		)
		return true, buildHeader(obj, fullName, serviceName, "getscriptbytecode") .. bcRef, "getscriptbytecode", 1, "bytecode_ref"
	end
	local bc = tryBytecodeRef(obj)
	if bc then
		return true, buildHeader(obj, fullName, serviceName, "getscriptbytecode") .. bc, "getscriptbytecode", 1, "bytecode_ref"
	end
	if Config.WriteStubForPanics then
		return true, buildStub(obj, fullName, serviceName), "stub", 1, "panicked"
	end
	return false, nil, "all methods failed", Config.MaxRetries, "failed"
end
local function getRelativeParts(obj, serviceRoot)
	local parts = {}
	local cur = obj
	while cur and cur ~= serviceRoot do
		table.insert(parts, 1, sanitizeName(cur.Name))
		local ok, p = pcall(function() return cur.Parent end)
		if not ok then break end
		cur = p
	end
	return parts
end
local function getOutputPath(obj, serviceName, serviceRoot)
	local parts = getRelativeParts(obj, serviceRoot)
	local nameParts = { serviceName }
	for _, p in ipairs(parts) do table.insert(nameParts, p) end
	local fileName = table.concat(nameParts, Config.NameSeparator) .. ".lua"
	local dir = Config.MainFolder
	return dir, dir .. "/" .. fileName
end
local function validateExisting(path, id)
	if not has("isfile") or not Env.isfile(path) then return false end
	local ok, c = pcall(Env.readfile, path)
	if not ok or not c or #c == 0 then return false end
	local meta = State.ObjectsMeta[id]
	if meta then
		return meta.status == "success" or meta.status == "closure_stub"
			or meta.status == "bytecode_ref" or meta.status == "panicked"
			or meta.status == "no_bytecode"
	end
	return true
end
local RobloxScriptFilter = {}
do
	local cache = setmetatable({}, { __mode = "k" })
	local PLAYERSCRIPTS_PARENTS = { PlayerScripts = true, StarterPlayerScripts = true, StarterCharacterScripts = true }
	local PLAYERSCRIPTS_NAMES = {
		PlayerModule = true, RbxCharacterSounds = true, PlayerScriptsLoader = true,
		ChatScript = true, BubbleChat = true, ControlScript = true, CameraScript = true,
	}
	local CHAT_NAMES = {
		ChatScript = true, ChatModules = true, ChatServiceRunner = true,
		BubbleChat = true, ChatMain = true, ClientChatModules = true,
	}
	local roots = {}
	for _, name in ipairs({ "CoreGui", "CorePackages", "RobloxReplicatedStorage" }) do
		local svc = safeGetService(name)
		if svc then roots[#roots + 1] = svc end
	end
	local function prop(inst, key)
		local ok, v = pcall(function() return inst[key] end)
		if ok then return v end
		return nil
	end
	local function ownedNode(node, parent)
		local name = prop(node, "Name")
		if type(name) ~= "string" then return false end
		for _, extra in ipairs(Config.RobloxScriptExtraNames or {}) do
			if name == extra then return true end
		end
		local pcls = parent and prop(parent, "ClassName") or nil
		if PLAYERSCRIPTS_PARENTS[pcls] and (PLAYERSCRIPTS_NAMES[name] or name:sub(1, 3) == "Rbx") then
			return true
		end
		if pcls == "Chat" and CHAT_NAMES[name] then return true end
		if name == "Animate" and prop(node, "ClassName") == "LocalScript" then
			local emote = node:FindFirstChild("PlayEmote")
			if emote and emote:IsA("BindableFunction") then return true end
		end
		return false
	end
	function RobloxScriptFilter.isRoblox(obj)
		if not Config.SkipRobloxScripts then return false end
		local cached = cache[obj]
		if cached ~= nil then return cached end
		local result = false
		pcall(function()
			for _, root in ipairs(roots) do
				if obj:IsDescendantOf(root) then result = true; return end
			end
			local node, depth = obj, 0
			while node and node ~= game and depth < 64 do
				local parent = node.Parent
				if ownedNode(node, parent) then result = true; return end
				node = parent
				depth += 1
			end
		end)
		cache[obj] = result
		return result
	end
end
local function isRobloxScript(obj)
	return RobloxScriptFilter.isRoblox(obj)
end
local CrashGuard = { quarantine = {} }
local function crashGuardRead(path)
	if not has("isfile") or not has("readfile") then return nil end
	local okF, exists = pcall(Env.isfile, path)
	if not okF or not exists then return nil end
	local ok, c = pcall(Env.readfile, path)
	if not ok or type(c) ~= "string" or #c == 0 then return nil end
	local ok2, d = pcall(function() return HttpService:JSONDecode(c) end)
	if ok2 and type(d) == "table" then return d end
	return nil
end
function CrashGuard.persist()
	if not has("writefile") then return end
	pcall(Env.writefile, Paths.Quarantine, HttpService:JSONEncode(CrashGuard.quarantine))
end
function CrashGuard.load()
	if not Config.CrashGuard then return end
	local q = crashGuardRead(Paths.Quarantine)
	if q then CrashGuard.quarantine = q end
	local marker = crashGuardRead(Paths.CrashGuard)
	if marker and marker.status == "running" and type(marker.id) == "string" then
		CrashGuard.quarantine[marker.id] = tostring(marker.fullName or marker.id)
		CrashGuard.persist()
		writeLog("[CRASH-GUARD] A execução anterior terminou enquanto lia: " .. tostring(marker.fullName)
			.. " (" .. tostring(marker.className) .. "). Esse script será pulado.")
		if has("writefile") then
			pcall(Env.writefile, Paths.CrashGuard, HttpService:JSONEncode({ status = "idle" }))
		end
	end
end
function CrashGuard.begin(id, fullName, className)
	if not Config.CrashGuard or not has("writefile") then return end
	local ok = pcall(Env.writefile, Paths.CrashGuard, HttpService:JSONEncode({
		status = "running", id = id, fullName = fullName, className = className, time = os.time(),
	}))
end
function CrashGuard.finish()
	if not Config.CrashGuard or not has("writefile") then return end
	pcall(Env.writefile, Paths.CrashGuard, HttpService:JSONEncode({ status = "idle" }))
end
local function getObjectId(obj, serviceName, fullName)
	return serviceName .. "::" .. fullName .. "::" .. obj.ClassName
end
local function processObject(obj, serviceName, serviceRoot)
	if not obj:IsA("LuaSourceContainer") then return "skip_type" end
	if isRobloxScript(obj) then
		State.RobloxSkipped += 1
		local okR, rName = pcall(function() return obj:GetFullName() end)
		writeLog("  [ROBLOX] ignorado: " .. (okR and rName or tostring(obj.Name)))
		return "roblox_skip"
	end
	local ok, fullName = pcall(function() return obj:GetFullName() end)
	if not ok then fullName = serviceName .. "." .. obj.Name end
	local id = getObjectId(obj, serviceName, fullName)
	local folderPath, filePath = getOutputPath(obj, serviceName, serviceRoot)
	local wasInterrupted = State.Checkpoint.lastStatus == "in_progress"
		and State.Checkpoint.lastObjectId == id
	if not wasInterrupted and validateExisting(filePath, id) then
		State.Skipped += 1
		return "skipped"
	end
	State.Checkpoint.lastObjectId = id
	State.Checkpoint.lastStatus = "in_progress"
	State.Checkpoint.currentService = serviceName
	createFolderRecursive(folderPath)
	local success, source, methodUsed, attempts, resolvedStatus
	local forcedStub = false
	for _, n in ipairs(Config.AlwaysStub or {}) do
		if n == fullName then forcedStub = true; break end
	end
	if CrashGuard.quarantine[id] or forcedStub then
		writeLog("  [CRASH-GUARD] pulado (" .. (forcedStub and "AlwaysStub" or "derrubou o executor antes") .. "): " .. fullName)
		success, source, methodUsed, attempts, resolvedStatus =
			true, buildStub(obj, fullName, serviceName), "stub_crash_guard", 0, "panicked"
	else
		CrashGuard.begin(id, fullName, obj.ClassName)
		local okT, r1, r2, r3, r4, r5 = pcall(tryDecompile, obj, fullName, serviceName)
		CrashGuard.finish()
		if not okT then error(r1, 0) end
		success, source, methodUsed, attempts, resolvedStatus = r1, r2, r3, r4, r5
	end
	local meta = {
		name = obj.Name, fullName = fullName, className = obj.ClassName,
		file = filePath, method = methodUsed, attempts = attempts,
		timestamp = os.time(),
	}
	if success then
		if writeFileSafe(filePath, source) then
			meta.status = resolvedStatus
			if resolvedStatus == "success" then
				State.Success += 1
				writeLog("OK    " .. fullName)
			elseif resolvedStatus == "closure_stub" then
				State.Success += 1
				writeLog("CLOS  " .. fullName)
			elseif resolvedStatus == "bytecode_ref" then
				State.Success += 1
				writeLog("BYTE  " .. fullName)
			elseif resolvedStatus == "no_bytecode" then
				State.Skipped += 1
				writeLog("SKIP  " .. fullName .. " (no bytecode)")
			elseif resolvedStatus == "panicked" then
				State.Panicked += 1
				writeLog("PANIC " .. fullName)
			end
		else
			meta.status = "write_error"
			State.Failed += 1
			table.insert(State.FailedList, fullName .. " (write_error)")
			writeLog("WRERR " .. fullName)
		end
	else
		meta.status = "failed"
		State.Failed += 1
		table.insert(State.FailedList, fullName .. " — " .. tostring(methodUsed))
		writeLog("FAIL  " .. fullName)
	end
	State.ObjectsMeta[id] = meta
	State.Checkpoint.lastStatus = meta.status
	State.Processed += 1
	if State.Processed % Config.CheckpointInterval == 0 then
		saveCheckpoint()
		saveMetadata()
	end
	return meta.status
end
local function processService(serviceName)
	local serviceRoot = resolveServiceRoot(serviceName)
	if not serviceRoot then
		writeLog("[ERROR] Service inaccessible: " .. serviceName)
		return
	end
	writeLog("═══ Service: " .. serviceName)
	State.Checkpoint.currentService = serviceName
	local ok, descendants = pcall(function() return serviceRoot:GetDescendants() end)
	if not ok then
		writeLog("[ERROR] GetDescendants() failed on " .. serviceName)
		return
	end
	State.Total += #descendants
	local skippedBefore = State.Skipped
	local robloxBefore = State.RobloxSkipped
	writeLog("Objects: " .. #descendants)
	local lastFastYield = os.clock()
	for i, obj in ipairs(descendants) do
		local prevProcessed = State.Processed
		local ok2, err = pcall(processObject, obj, serviceName, serviceRoot)
		if not ok2 then
			State.Failed += 1
			local label = "?"
			pcall(function() label = obj:GetFullName() end)
			table.insert(State.FailedList, label .. " (error: " .. tostring(err) .. ")")
		end
		if Config.FastMode then
			local gap = tonumber(Config.FastModeYieldSeconds) or 0
			if gap > 0 and os.clock() - lastFastYield >= gap then
				task.wait()
				lastFastYield = os.clock()
			end
		elseif i % Config.YieldEvery == 0 then
			cancelPoint()
			task.wait()
		end
	end
	writeLog(string.format("Completed %s | existing: %d | processed: %d | roblox ignored: %d",
		serviceName, State.Skipped - skippedBefore, State.Processed, State.RobloxSkipped - robloxBefore))
	saveCheckpoint()
	saveMetadata()
end
local function describeItem(obj)
	local lines = {}
	local okIsA, isPart = pcall(function() return obj:IsA("BasePart") end)
	table.insert(lines, string.format("    Item: %s (%s) Part=%s", obj.Name, obj.ClassName, tostring(okIsA and isPart)))
	local okCh, children = pcall(function() return obj:GetChildren() end)
	if okCh then
		for _, child in ipairs(children) do
			if child:IsA("LuaSourceContainer") or child:IsA("Tool") then
				table.insert(lines, string.format("      - %s (%s)", child.Name, child.ClassName))
			end
		end
	end
	local okA, attrs = pcall(function() return obj:GetAttributes() end)
	if okA and attrs then
		for k, v in pairs(attrs) do
			table.insert(lines, string.format("      attr %s = %s", k, tostring(v)))
		end
	end
	return lines
end
local function generateWorkspaceReport()
	local ok, ws = pcall(safeGetService, "Workspace")
	if not ok or not ws then return end
	local okCh, children = pcall(function() return ws:GetChildren() end)
	if not okCh then return end
	local lines = { "WORKSPACE:", "" }
	local counter = 0
	for _, child in ipairs(children) do
		if child:IsA("Folder") or child:IsA("Model") then
			table.insert(lines, child.Name .. ":")
			local okI, items = pcall(function() return child:GetChildren() end)
			if okI then
				for _, item in ipairs(items) do
					table.insert(lines, "  - " .. item.Name)
					for _, l in ipairs(describeItem(item)) do table.insert(lines, l) end
					counter += 1
					if counter % Config.YieldEvery == 0 then task.wait(); cancelPoint() end
				end
			end
			table.insert(lines, "")
		end
	end
	writeFileSafe(Config.MainFolder .. "/Workspace Structure.txt", table.concat(lines, "\n"))
	writeLog("Workspace structure saved.")
end
local GuiProps = {
	Common = { "Visible","Position","Size","BackgroundColor3","BackgroundTransparency","ZIndex","LayoutOrder" },
	TextLabel = { "Text","TextColor3","TextSize","Font","TextWrapped","RichText" },
	TextButton = { "Text","TextColor3","TextSize","Font" },
	ImageLabel = { "Image","ImageColor3","ImageTransparency" },
	ImageButton = { "Image","ImageColor3" },
	ScreenGui = { "Enabled","IgnoreGuiInset","DisplayOrder","ZIndexBehavior" },
}
local function readGuiProps(obj)
	local lines = {}
	local function readSet(set)
		for _, prop in ipairs(set) do
			local ok, v = pcall(function() return obj[prop] end)
			if ok then table.insert(lines, prop .. "=" .. tostring(v)) end
		end
	end
	readSet(GuiProps.Common)
	if GuiProps[obj.ClassName] then readSet(GuiProps[obj.ClassName]) end
	return lines
end
local walkGui
walkGui = function(obj, depth, lines, ys)
	local indent = string.rep("  ", depth)
	local isScript = obj:IsA("LuaSourceContainer")
	table.insert(lines, string.format("%s- %s (%s)", indent, obj.Name, obj.ClassName))
	if isScript then
		table.insert(lines, indent .. "    [Script — dump at " .. Config.MainFolder .. "/]")
		return
	end
	for _, l in ipairs(readGuiProps(obj)) do
		table.insert(lines, indent .. "    " .. l)
	end
	local ok, ch = pcall(function() return obj:GetChildren() end)
	if ok then
		for _, child in ipairs(ch) do
			walkGui(child, depth + 1, lines, ys)
			ys.n += 1
			if ys.n % Config.YieldEvery == 0 then task.wait(); cancelPoint() end
		end
	end
end
local function generatePlayerGuiReport()
	local root = resolveServiceRoot("PlayerGui")
	if not root then return end
	local ok, ch = pcall(function() return root:GetChildren() end)
	if not ok then return end
	local lines = { "PLAYERGUI:", "" }
	local ys = { n = 0 }
	for _, sg in ipairs(ch) do
		walkGui(sg, 0, lines, ys)
		table.insert(lines, "")
	end
	writeFileSafe(Config.MainFolder .. "/PlayerGui Structure.txt", table.concat(lines, "\n"))
	writeLog("PlayerGui structure saved.")
end
local function generateHookScript(remoteData)
	local p = remoteData.fullPath
	local cls = remoteData.className
	local outMethod = remoteData.outMethod
	local inMethod = remoteData.inMethod
	local lines = {
		"--[[",
		"    Hook automatically generated by the dump system",
		"    Remote  : " .. p,
		"    Class   : " .. cls,
		"    PlaceId : " .. tostring(game.PlaceId),
		"    Date    : " .. os.date("%Y-%m-%d %H:%M:%S"),
		"]]",
		"",
		"local Event = game:" .. "GetDescendants()" .. " -- use the path below",
		"-- Path: " .. p,
		"",
	}
	local pathParts = {}
	for part in p:gmatch("[^%.]+") do table.insert(pathParts, part) end
	if #pathParts >= 2 then
		local svcName = pathParts[1]
		local access = 'game:GetService("' .. svcName .. '")'
		for i = 2, #pathParts do
			access = access .. ':WaitForChild("' .. pathParts[i] .. '")'
		end
		table.insert(lines, "local Event = " .. access)
		table.insert(lines, "")
	end
	table.insert(lines, "-- ══ HOOK OUTGOING (" .. outMethod .. ") ══")
	if cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "UnreliableRemoteEvent" then
		table.insert(lines, "local mtHook; mtHook = hookmetamethod(game, \"__namecall\", function(...)")
		table.insert(lines, "    local self = ...")
		table.insert(lines, '    if rawequal(self, Event) and getnamecallmethod() == "' .. outMethod .. '" then')
		table.insert(lines, "        local args = table.pack(...)")
		table.insert(lines, '        print("[HOOK OUT] ' .. p .. '", table.unpack(args, 2, args.n))')
		table.insert(lines, "        return mtHook(table.unpack(args, 1, args.n))")
		table.insert(lines, "    end")
		table.insert(lines, "    return mtHook(...)")
		table.insert(lines, "end)")
	else
		table.insert(lines, "local OldFn; OldFn = hookfunction(Event." .. outMethod .. ", function(...)")
		table.insert(lines, '    print("[HOOK OUT] ' .. p .. '", ...)')
		table.insert(lines, "    return OldFn(...)")
		table.insert(lines, "end)")
	end
	table.insert(lines, "")
	table.insert(lines, "-- ══ HOOK INCOMING (" .. inMethod .. ") ══")
	if cls == "RemoteFunction" or cls == "BindableFunction" then
		table.insert(lines, "local Callback = getcallbackvalue(Event, \"" .. inMethod .. "\")")
		table.insert(lines, "Event." .. inMethod .. " = function(...)")
		table.insert(lines, '    print("[HOOK IN] ' .. p .. '", ...)')
		table.insert(lines, "    return Callback(...)")
		table.insert(lines, "end")
	else
		table.insert(lines, "Event." .. inMethod .. ":Connect(function(...)")
		table.insert(lines, '    print("[HOOK IN] ' .. p .. '", ...)')
		table.insert(lines, "end)")
	end
	return table.concat(lines, "\n")
end
local function generateRemoteMap()
	local lines = {
		"REMOTE MAP",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"LEGEND: [OUT=outgoing calls] [IN=incoming calls] [CALLERS=scripts that called]",
		string.rep("═", 90),
		"",
	}
	local sorted = {}
	for path, data in pairs(State.Remotes) do
		table.insert(sorted, { path = path, data = data })
	end
	table.sort(sorted, function(a, b)
		return (a.data.outCalls + a.data.inCalls) > (b.data.outCalls + b.data.inCalls)
	end)
	for _, entry in ipairs(sorted) do
		local d = entry.data
		local callerList = {}
		for caller, _ in pairs(d.callers) do
			table.insert(callerList, "    CALLER  : " .. caller)
		end
		table.insert(lines, "REMOTE  : " .. d.fullPath)
		table.insert(lines, "CLASS   : " .. d.className)
		table.insert(lines, string.format(
			"METHOD  : OUT=%s  IN=%s",
			d.outMethod, d.inMethod
		))
		table.insert(lines, string.format(
			"CALLS   : OUT=%d  IN=%d",
			d.outCalls, d.inCalls
		))
		if d.isDispatcher then
			table.insert(lines, string.format(
				"DISPATCHER: YES — %d distinct actions detected (see DISPATCHER_ACTIONS.txt)",
				d.dispatcherActionCount or 0
			))
		end
		if #d.argSamples > 0 then
			table.insert(lines, "ARGS    : " .. table.concat(d.argSamples, " | "))
		end
		for _, cl in ipairs(callerList) do table.insert(lines, cl) end
		table.insert(lines, string.rep("─", 70))
	end
	table.insert(lines, "")
	table.insert(lines, "TOTAL REMOTES MAPPED: " .. #sorted)
	writeFileSafe(Paths.RemoteMap, table.concat(lines, "\n"))
	writeLog("REMOTE_MAP.txt saved (" .. #sorted .. " remotes).")
end
local function generateCallLog()
	if #State.CallLog == 0 then return end
	local header = string.format("# CALL_LOG caps: global=%d, per-remote=%d | suppressed by per-remote cap: %d (REMOTE_MAP counters are exact)",
		Config.MaxCallLogEntries, Config.MaxCallLogPerRemote, State.CallLogSuppressed)
	writeFileSafe(Paths.CallLog, header .. "\n" .. table.concat(State.CallLog, "\n"))
	writeLog("CALL_LOG.txt saved (" .. #State.CallLog .. " entries).")
end
local function generateScriptToRemote()
	local lines = {
		"MAP: SCRIPT → REMOTE",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
		string.rep("═", 80),
		"",
	}
	for scriptName, remotes in pairs(State.ScriptRemote) do
		table.insert(lines, "SCRIPT: " .. scriptName)
		for remotePath, dir in pairs(remotes) do
			table.insert(lines, "  [" .. dir .. "] " .. remotePath)
		end
		table.insert(lines, "")
	end
	writeFileSafe(Paths.ScriptToRem, table.concat(lines, "\n"))
	writeLog("SCRIPT_TO_REMOTE.txt saved.")
end
local function generateHookScripts()
	createFolderRecursive(Paths.HookScripts)
	local count = 0
	for fullPath, remoteData in pairs(State.Remotes) do
		local safeName = fullPath:gsub("[^%w]", "_")
		local path = Paths.HookScripts .. "/" .. safeName .. ".lua"
		if writeFileSafe(path, generateHookScript(remoteData)) then
			count += 1
		end
	end
	writeLog("HOOK_SCRIPTS generated: " .. count)
end
local KnownNetRemotePatterns = {
	["RE/"] = "RemoteEvent",
	["RF/"] = "RemoteFunction",
}
local function generateDispatcherMap()
	local hasAny = false
	for _ in pairs(State.DispatcherActions) do hasAny = true; break end
	if not hasAny then
		writeLog("DISPATCHER_ACTIONS: no actions captured (live hooks off or no calls during the soak).")
		return
	end
	local lines = {
		"DISPATCHER REMOTE ACTIONS MAP",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: Remotes whose 1st argument is a string identifying the action.",
		"Common pattern: RemoteFunction:InvokeServer('ActionName', arg2, arg3, ...)",
		"USE THIS to learn the real server API — each action is a distinct endpoint.",
		string.rep("═", 90),
		"",
	}
	local remotePaths = {}
	for path in pairs(State.DispatcherActions) do
		remotePaths[#remotePaths + 1] = path
	end
	table.sort(remotePaths)
	for _, path in ipairs(remotePaths) do
		local bucket = State.DispatcherActions[path]
		local totalActions, totalCalls = 0, 0
		for _, entry in pairs(bucket) do
			totalActions += 1
			totalCalls   += entry.calls
		end
		lines[#lines + 1] = "REMOTE  : " .. path
		lines[#lines + 1] = string.format("SUMMARY : %d distinct actions | %d total calls captured", totalActions, totalCalls)
		lines[#lines + 1] = ""
		local actions = {}
		for name, entry in pairs(bucket) do
			actions[#actions + 1] = { name = name, calls = entry.calls, argSamples = entry.argSamples }
		end
		table.sort(actions, function(a, b) return a.calls > b.calls end)
		for _, action in ipairs(actions) do
			lines[#lines + 1] = string.format("  ACTION  : %q", action.name)
			lines[#lines + 1] = string.format("  CALLS   : %d", action.calls)
			if #action.argSamples > 0 then
				lines[#lines + 1] = "  ARGS    : " .. table.concat(action.argSamples, " | ")
			else
				lines[#lines + 1] = "  ARGS    : (no additional args captured)"
			end
			lines[#lines + 1] = "  " .. string.rep("─", 60)
		end
		lines[#lines + 1] = string.rep("═", 90)
		lines[#lines + 1] = ""
	end
	writeFileSafe(Paths.DispatcherMap, table.concat(lines, "\n"))
	writeLog("DISPATCHER_ACTIONS.txt saved.")
end
local function generateToolsInventory()
	local lines = {
		"TOOLS INVENTORY",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: All Tools found in the game with their child scripts,",
		"attributes and internal structure. 'Data' ModuleScripts contain ability tables.",
		string.rep("═", 90),
		"",
	}
	local toolCount = 0
	local seen = {}
	local function scanForTools(root, rootName)
		if not root then return end
		local ok, descendants = pcall(function() return root:GetDescendants() end)
		if not ok then return end
		for _, obj in ipairs(descendants) do
			if not seen[obj] then
				local okC, cls = pcall(function() return obj.ClassName end)
				if okC and cls == "Tool" then
					seen[obj] = true
					toolCount += 1
					local okP, fullPath = pcall(function() return obj:GetFullName() end)
					local okN, name = pcall(function() return obj.Name end)
					local okTT, tooltip = pcall(function() return obj.ToolTip end)
					lines[#lines + 1] = "TOOL    : " .. (okN and name or "?")
					lines[#lines + 1] = "PATH    : " .. (okP and fullPath or "?")
					lines[#lines + 1] = "SERVICE : " .. rootName
					if okTT and tooltip and tooltip ~= "" then
						lines[#lines + 1] = "TOOLTIP : " .. tostring(tooltip)
					end
					local okA, attrs = pcall(function() return obj:GetAttributes() end)
					if okA and attrs and next(attrs) then
						lines[#lines + 1] = "ATTRIBS :"
						for k, v in pairs(attrs) do
							lines[#lines + 1] = string.format("  %s = %s", tostring(k), tostring(v))
						end
					end
					local okCh, children = pcall(function() return obj:GetChildren() end)
					if okCh and children then
						local scripts, modules, parts, values, outros = {}, {}, {}, {}, {}
						for _, child in ipairs(children) do
							local okCC, cc = pcall(function() return child.ClassName end)
							local okCN, cn = pcall(function() return child.Name end)
							if okCC then
								local entry = string.format("%s (%s)", okCN and cn or "?", cc)
								if cc == "LocalScript" or cc == "Script" then
									scripts[#scripts + 1] = entry
								elseif cc == "ModuleScript" then
									modules[#modules + 1] = entry
									if cn == "Data" or cn == "Config" then
										lines[#lines + 1] = "  [ModuleScript '" .. cn .. "' — contains data/abilities table of the tool]"
									end
								elseif cc == "Part" or cc == "MeshPart" or cc == "SpecialMesh" then
									parts[#parts + 1] = entry
								elseif cc:find("Value$") then
									local okV, val = pcall(function() return child.Value end)
									values[#values + 1] = entry .. (okV and (" = " .. tostring(val)) or "")
								else
									outros[#outros + 1] = entry
								end
							end
						end
						if #scripts  > 0 then lines[#lines + 1] = "SCRIPTS : " .. table.concat(scripts, ", ") end
						if #modules  > 0 then lines[#lines + 1] = "MODULES : " .. table.concat(modules, ", ") end
						if #parts    > 0 then lines[#lines + 1] = "PARTS   : " .. table.concat(parts, ", ") end
						if #values   > 0 then lines[#lines + 1] = "VALUES  : " .. table.concat(values, ", ") end
						if #outros   > 0 then lines[#lines + 1] = "OTHERS  : " .. table.concat(outros, ", ") end
					end
					lines[#lines + 1] = string.rep("─", 70)
					lines[#lines + 1] = ""
				end
			end
		end
	end
	local servicesToScan = {
		{ "ReplicatedStorage", safeGetService("ReplicatedStorage") },
		{ "Workspace",         safeGetService("Workspace")         },
		{ "StarterPack",       safeGetService("StarterPack")       },
		{ "StarterGui",        safeGetService("StarterGui")        },
		{ "Players",           safeGetService("Players")           },
	}
	for _, pair in ipairs(servicesToScan) do
		scanForTools(pair[2], pair[1])
		task.wait()
	end
	lines[#lines + 1] = string.format("TOTAL TOOLS FOUND: %d", toolCount)
	writeFileSafe(Paths.ToolsInventory, table.concat(lines, "\n"))
	writeLog(string.format("TOOLS_INVENTORY.txt saved (%d tools).", toolCount))
end
local KnownWorkspaceAttrs = {
	MAP = "Defines the current sea/phase of the game (e.g. Sea1, Sea2, Sea3)",
	GameMode = "Current game mode",
	Version = "Game version",
	Map = "Active map (alias of MAP)",
	Stage = "Current stage or phase",
	Region = "Current server region",
	World = "Current world",
	Level = "Server level or tier",
	Season = "Current season",
	Event = "Active event on the server",
}
local KnownPlaceIds = {
	["2753915549"] = "Blox Fruits — Sea 1 (level 1–675)",
	["4442272183"] = "Blox Fruits — Sea 2 (level 700–1450)",
	["7449423635"] = "Blox Fruits — Sea 3 (level 1500–2800)",
}
local function generateGameContext()
	local lines = {
		"GAME CONTEXT",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
		string.rep("═", 80),
		"",
		"── IDENTIFICATION ──────────────────────────────────────────────────────────",
		"PlaceId   : " .. tostring(game.PlaceId),
		"PlaceName : " .. tostring(game.Name),
		"GameName  : " .. tostring(Config.GameName),
		"JobId     : " .. tostring(game.JobId),
	}
	local placeDesc = KnownPlaceIds[tostring(game.PlaceId)]
	if placeDesc then
		lines[#lines + 1] = "Game      : " .. placeDesc
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "── WORKSPACE ATTRIBUTES (interpreted) ─────────────────────────────────────"
	local ws = safeGetService("Workspace")
	if ws then
		local okA, wsAttrs = pcall(function() return ws:GetAttributes() end)
		if okA and wsAttrs then
			local hasAttrs = false
			for k, v in pairs(wsAttrs) do
				hasAttrs = true
				local meaning = KnownWorkspaceAttrs[k] or KnownWorkspaceAttrs[k:lower()] or "(unknown attribute)"
				lines[#lines + 1] = string.format("  %-20s = %-30s  ← %s", tostring(k), tostring(v), meaning)
				if k == "MAP" or k == "Map" then
					local mapVal = tostring(v)
					if mapVal:find("Sea1") or mapVal:find("1") then
						lines[#lines + 1] = "  *** SEA 1 DETECTED — Max level ~675. Place: 2753915549 ***"
					elseif mapVal:find("Sea2") or mapVal:find("2") then
						lines[#lines + 1] = "  *** SEA 2 DETECTED — Max level ~1450. Place: 4442272183 ***"
					elseif mapVal:find("Sea3") or mapVal:find("3") then
						lines[#lines + 1] = "  *** SEA 3 DETECTED — Max level ~2800. Place: 7449423635 ***"
					end
				end
			end
			if not hasAttrs then
				lines[#lines + 1] = "  (no attributes on root Workspace)"
			end
		end
	end
	lines[#lines + 1] = ""
	if ws then
		lines[#lines + 1] = "── WORKSPACE — GENERAL INFORMATION ───────────────────────────────────────"
		local okDGT, dgt = pcall(function() return ws.DistributedGameTime end)
		if okDGT then
			lines[#lines + 1] = string.format("  DistributedGameTime : %.1f s (server uptime)", dgt)
		end
		local okSS, ss = pcall(function() return ws.StreamingEnabled end)
		if okSS then
			lines[#lines + 1] = "  StreamingEnabled   : " .. tostring(ss)
		end
		local okGrav, grav = pcall(function() return ws.Gravity end)
		if okGrav then
			lines[#lines + 1] = "  Gravity             : " .. tostring(grav)
		end
		local okCh, wsChildren = pcall(function() return ws:GetChildren() end)
		if okCh then
			local topNames = {}
			for _, child in ipairs(wsChildren) do
				local okCN, cn = pcall(function() return child.Name end)
				if okCN then topNames[#topNames + 1] = cn end
			end
			lines[#lines + 1] = string.format("  Direct children (%d): %s", #topNames, table.concat(topNames, ", "):sub(1, 200))
		end
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = "── ROBLOX SERVICES AVAILABLE ─────────────────────────────────────────────"
	local checkServices = {
		"ReplicatedStorage","ReplicatedFirst","Workspace","Players","Lighting",
		"SoundService","StarterGui","StarterPack","StarterPlayer","Teams",
		"TextChatService","CollectionService","PhysicsService","TweenService",
		"RunService","UserInputService","VirtualUser","VirtualInputManager","HttpService",
	}
	for _, svcName in ipairs(checkServices) do
		local svc = safeGetService(svcName)
		lines[#lines + 1] = string.format("  %-30s : %s", svcName, svc and "OK" or "inaccessible")
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "── EXECUTION ENVIRONMENT ──────────────────────────────────────────────────"
	pcall(function()
		lines[#lines + 1] = "  Executor : " .. tostring(identifyexecutor())
	end)
	local envFuncs = {
		"decompile","getscriptclosure","getscriptbytecode","hookmetamethod",
		"hookfunction","getconnections","getnamecallmethod","checkcaller",
		"getcallingscript","isexecutorclosure","writefile","readfile",
		"isfile","isfolder","makefolder","loadstring",
	}
	local available, missing = {}, {}
	for _, fn in ipairs(envFuncs) do
		if typeof(Env[fn]) == "function" then
			available[#available + 1] = fn
		else
			missing[#missing + 1] = fn
		end
	end
	lines[#lines + 1] = "  Available   : " .. table.concat(available, ", ")
	lines[#lines + 1] = "  Missing     : " .. (#missing > 0 and table.concat(missing, ", ") or "none")
	lines[#lines + 1] = ""
	writeFileSafe(Paths.GameContext, table.concat(lines, "\n"))
	writeLog("GAME_CONTEXT.txt saved.")
end
local function generateEnemiesCatalog()
	local ws = safeGetService("Workspace")
	if not ws then
		writeLog("ENEMIES_CATALOG: Workspace inaccessible.")
		return
	end
	local enemyContainers = {}
	local function tryAdd(name)
		local ok, obj = pcall(function() return ws:FindFirstChild(name) end)
		if ok and obj then enemyContainers[#enemyContainers + 1] = { name = name, obj = obj } end
	end
	tryAdd("Enemies")
	tryAdd("NPCs")
	tryAdd("Mobs")
	tryAdd("Monsters")
	tryAdd("Characters")
	local okCh, wsChildren = pcall(function() return ws:GetChildren() end)
	if okCh then
		for _, child in ipairs(wsChildren) do
			local okCC, cc = pcall(function() return child.ClassName end)
			local okCN, cn = pcall(function() return child.Name end)
			if okCC and (cc == "Folder" or cc == "Model") then
				local okC2, c2 = pcall(function() return child:GetChildren() end)
				if okC2 and #c2 > 2 then
					local hasHum = false
					for _, item in ipairs(c2) do
						if pcall(function() return item:FindFirstChildOfClass("Humanoid") end) then
							local okH, h = pcall(function() return item:FindFirstChildOfClass("Humanoid") end)
							if okH and h then hasHum = true; break end
						end
					end
					if hasHum then
						local alreadyAdded = false
						for _, ec in ipairs(enemyContainers) do
							if ec.obj == child then alreadyAdded = true; break end
						end
						if not alreadyAdded then
							enemyContainers[#enemyContainers + 1] = { name = okCN and cn or "?", obj = child }
						end
					end
				end
			end
		end
	end
	local lines = {
		"ENEMY / NPC CATALOG",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: Snapshot of the enemies/NPCs present on the server at the time of the dump.",
		"Level extracted from the '[Lv. N]' pattern in the name. Bosses detected by '[Boss]'.",
		string.rep("═", 90),
		"",
	}
	local totalMobs, totalBosses = 0, 0
	local levelMap = {}
	for _, container in ipairs(enemyContainers) do
		lines[#lines + 1] = "CONTAINER: " .. container.name
		local okCh2, children = pcall(function() return container.obj:GetChildren() end)
		if not okCh2 then
			lines[#lines + 1] = "  (inaccessible)"
			lines[#lines + 1] = ""
		else
			local nameCounts = {}
			local namePositions = {}
			for _, mob in ipairs(children) do
				local okN, mobName = pcall(function() return mob.Name end)
				if okN and mobName then
					nameCounts[mobName] = (nameCounts[mobName] or 0) + 1
					if not namePositions[mobName] then
						local okHRP, hrp = pcall(function() return mob:FindFirstChild("HumanoidRootPart") end)
						if okHRP and hrp then
							local okPos, pos = pcall(function() return hrp.Position end)
							if okPos then
								namePositions[mobName] = string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
							end
						end
					end
				end
			end
			local sortedNames = {}
			for name in pairs(nameCounts) do sortedNames[#sortedNames + 1] = name end
			table.sort(sortedNames)
			for _, mobName in ipairs(sortedNames) do
				local count = nameCounts[mobName]
				local level = tonumber(mobName:match("%[Lv%. (%d+)%]"))
				local isBoss = mobName:find("%[Boss%]") ~= nil or mobName:find("Boss") ~= nil
				local levelStr = level and tostring(level) or "?"
				local typeStr = isBoss and "BOSS" or "MOB"
				totalMobs += count
				if isBoss then totalBosses += count end
				lines[#lines + 1] = string.format("  [%-4s] %-50s  Lv:%-5s  x%d",
					typeStr, mobName, levelStr, count)
				if namePositions[mobName] then
					lines[#lines + 1] = "         Sample position: " .. namePositions[mobName]
				end
				if level then
					levelMap[level] = levelMap[level] or {}
					local alreadyIn = false
					for _, n in ipairs(levelMap[level]) do if n == mobName then alreadyIn = true; break end end
					if not alreadyIn then levelMap[level][#levelMap[level] + 1] = mobName end
				end
			end
			lines[#lines + 1] = ""
		end
		task.wait()
	end
	if next(levelMap) then
		lines[#lines + 1] = string.rep("═", 90)
		lines[#lines + 1] = "SUMMARY BY LEVEL:"
		lines[#lines + 1] = ""
		local sortedLevels = {}
		for lv in pairs(levelMap) do sortedLevels[#sortedLevels + 1] = lv end
		table.sort(sortedLevels)
		for _, lv in ipairs(sortedLevels) do
			lines[#lines + 1] = string.format("  Lv %-5d: %s", lv, table.concat(levelMap[lv], " | "))
		end
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = string.format("TOTAL INSTANCES: %d mobs | %d bosses", totalMobs, totalBosses)
	if #enemyContainers == 0 then
		lines[#lines + 1] = "(No enemy containers found — game may have a different structure)"
	end
	writeFileSafe(Paths.EnemiesCatalog, table.concat(lines, "\n"))
	writeLog(string.format("ENEMIES_CATALOG.txt saved (%d instances).", totalMobs))
end
local function markDispatchersInState()
	for path in pairs(State.DispatcherActions) do
		if State.Remotes[path] then
			State.Remotes[path].isDispatcher = true
			local count = 0
			for _ in pairs(State.DispatcherActions[path]) do count += 1 end
			State.Remotes[path].dispatcherActionCount = count
		end
	end
end
local function generatePlayerState()
	local LP = Players.LocalPlayer
	if not LP then
		writeLog("PLAYER_STATE: LocalPlayer inaccessible.")
		return
	end
	local lines = {
		"LOCAL PLAYER STATE",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: Snapshot of the LocalPlayer state at the time of the dump.",
		"Includes leaderstats, ValueObjects, attributes and character state.",
		string.rep("═", 80),
		"",
	}
	local okN, lpName = pcall(function() return LP.Name end)
	local okID, lpId = pcall(function() return LP.UserId end)
	local okTm, team = pcall(function() return LP.Team and LP.Team.Name or "none" end)
	lines[#lines + 1] = "── IDENTIFICATION ────────────────────────────────────────────"
	lines[#lines + 1] = "  Name   : " .. (okN and lpName or "?")
	lines[#lines + 1] = "  UserId : " .. (okID and tostring(lpId) or "?")
	lines[#lines + 1] = "  Team   : " .. (okTm and tostring(team) or "?")
	lines[#lines + 1] = ""
	local okLS, ls = pcall(function() return LP:FindFirstChild("leaderstats") end)
	if okLS and ls then
		lines[#lines + 1] = "── LEADERSTATS ───────────────────────────────────────────────"
		local okLSC, lsChildren = pcall(function() return ls:GetChildren() end)
		if okLSC then
			for _, stat in ipairs(lsChildren) do
				local okSN, sn = pcall(function() return stat.Name end)
				local okSV, sv = pcall(function() return stat.Value end)
				local okSC, sc = pcall(function() return stat.ClassName end)
				lines[#lines + 1] = string.format("  %-20s = %-20s  (%s)",
					okSN and sn or "?", okSV and tostring(sv) or "?", okSC and sc or "?")
			end
		end
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = "── PLAYER VALUE OBJECTS ──────────────────────────────────────"
	local okLPC, lpChildren = pcall(function() return LP:GetChildren() end)
	if okLPC then
		for _, child in ipairs(lpChildren) do
			local okCC, cc = pcall(function() return child.ClassName end)
			local okCN, cn = pcall(function() return child.Name end)
			if okCC and cc:find("Value$") then
				local okV, val = pcall(function() return child.Value end)
				lines[#lines + 1] = string.format("  %-25s = %-20s  (%s)",
					okCN and cn or "?", okV and tostring(val) or "?", cc)
			end
		end
	end
	lines[#lines + 1] = ""
	local okAtt, attrs = pcall(function() return LP:GetAttributes() end)
	if okAtt and attrs and next(attrs) then
		lines[#lines + 1] = "── PLAYER ATTRIBUTES ─────────────────────────────────────────"
		for k, v in pairs(attrs) do
			lines[#lines + 1] = string.format("  %-25s = %s", tostring(k), tostring(v))
		end
		lines[#lines + 1] = ""
	end
	local okChar, char = pcall(function() return LP.Character end)
	if okChar and char then
		lines[#lines + 1] = "── CHARACTER ─────────────────────────────────────────────────"
		local okHum, hum = pcall(function() return char:FindFirstChildOfClass("Humanoid") end)
		if okHum and hum then
			local okH, hp = pcall(function() return hum.Health end)
			local okMH, mh = pcall(function() return hum.MaxHealth end)
			local okWS, ws = pcall(function() return hum.WalkSpeed end)
			local okDN, dn = pcall(function() return hum.DisplayName end)
			lines[#lines + 1] = string.format("  Health    : %s / %s",
				okH and tostring(hp) or "?", okMH and tostring(mh) or "?")
			lines[#lines + 1] = "  WalkSpeed : " .. (okWS and tostring(ws) or "?")
			if okDN and dn and dn ~= "" then
				lines[#lines + 1] = "  Display   : " .. dn
			end
		end
		local okCA, cAttrs = pcall(function() return char:GetAttributes() end)
		if okCA and cAttrs and next(cAttrs) then
			lines[#lines + 1] = "  Character Attributes:"
			for k, v in pairs(cAttrs) do
				lines[#lines + 1] = string.format("    %-20s = %s", tostring(k), tostring(v))
			end
		end
		local okCCh, cChildren = pcall(function() return char:GetChildren() end)
		if okCCh then
			local equipped = {}
			for _, item in ipairs(cChildren) do
				local okIC, ic = pcall(function() return item.ClassName end)
				if okIC and ic == "Tool" then
					local okIN, iname = pcall(function() return item.Name end)
					equipped[#equipped + 1] = okIN and iname or "?"
				end
			end
			if #equipped > 0 then
				lines[#lines + 1] = "  Equipped Tools: " .. table.concat(equipped, ", ")
			end
		end
		lines[#lines + 1] = ""
	end
	local okBP, bp = pcall(function() return LP:FindFirstChildOfClass("Backpack") end)
	if okBP and bp then
		lines[#lines + 1] = "── BACKPACK ──────────────────────────────────────────────────"
		local okBPC, bpChildren = pcall(function() return bp:GetChildren() end)
		if okBPC then
			if #bpChildren == 0 then
				lines[#lines + 1] = "  (empty)"
			else
				for _, item in ipairs(bpChildren) do
					local okIN, iname = pcall(function() return item.Name end)
					local okIC, ic = pcall(function() return item.ClassName end)
					lines[#lines + 1] = string.format("  - %s (%s)", okIN and iname or "?", okIC and ic or "?")
				end
			end
		end
		lines[#lines + 1] = ""
	end
	writeFileSafe(Paths.PlayerState, table.concat(lines, "\n"))
	writeLog("PLAYER_STATE.txt saved.")
end
local function classifyScript(fullName, className)
	local fn = fullName:lower()
	if fn:find("playergui") or fn:find("screengui") then return "[UI      ]"
	elseif fn:find("effect") or fn:find("particle") or fn:find("vfx") then return "[EFFECT  ]"
	elseif fn:find("module") or className == "ModuleScript" then return "[MODULE  ]"
	elseif fn:find("remotes") or fn:find("remote") then return "[REMOTE  ]"
	elseif fn:find("starterpack") or fn:find("startergui") or fn:find("starterplayer") then return "[STARTER ]"
	elseif fn:find("serverscriptservice") or fn:find("serverscript") then return "[SERVER  ]"
	elseif fn:find("replicatedfirst") then return "[FIRST   ]"
	elseif fn:find("soundservice") or fn:find("sound") then return "[SOUND   ]"
	elseif fn:find("lighting") then return "[LIGHT   ]"
	elseif fn:find("workspace") then return "[WORLD   ]"
	elseif className == "LocalScript" then return "[LOCAL   ]"
	elseif className == "Script" then return "[SCRIPT  ]"
	else return "[?       ]" end
end
local function generateModuleDependencies()
	if not has("isfile") or not has("readfile") then
		writeLog("MODULE_DEPENDENCIES: readfile unavailable, skipping.")
		return
	end
	if not has("isfolder") then
		writeLog("MODULE_DEPENDENCIES: isfolder unavailable, skipping.")
		return
	end
	local folder = Config.MainFolder
	local okLF, files = pcall(function()
		if typeof(listfiles) == "function" then
			return listfiles(folder)
		end
		return nil
	end)
	local luaFiles = {}
	if okLF and files and type(files) == "table" then
		for _, f in ipairs(files) do
			if type(f) == "string" and f:sub(-4) == ".lua" then
				luaFiles[#luaFiles + 1] = f
			end
		end
	end
	if #luaFiles == 0 then
		writeLog("MODULE_DEPENDENCIES: listfiles unavailable or no .lua files saved yet — skipping.")
		return
	end
	local lines = {
		"MODULE DEPENDENCY GRAPH",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: require() calls found in the decompiled scripts.",
		"Makes it possible to understand which modules depend on which.",
		string.rep("═", 80),
		"",
	}
	local depGraph = {}
	local totalRequires = 0
	for _, filePath in ipairs(luaFiles) do
		local okR, content = pcall(Env.readfile, filePath)
		if okR and type(content) == "string" and #content > 0 then
			local deps = {}
			for reqArg in content:gmatch("require%s*%(([^%)]+)%)") do
				reqArg = reqArg:gsub("%s+", "")
				if reqArg ~= "" then
					deps[#deps + 1] = reqArg
					totalRequires += 1
				end
			end
			if #deps > 0 then
				local shortName = filePath:match("[^/]+$") or filePath
				depGraph[shortName] = deps
			end
		end
	end
	if next(depGraph) then
		local sortedScripts = {}
		for name in pairs(depGraph) do sortedScripts[#sortedScripts + 1] = name end
		table.sort(sortedScripts)
		for _, scriptName in ipairs(sortedScripts) do
			lines[#lines + 1] = "SCRIPT: " .. scriptName
			for _, dep in ipairs(depGraph[scriptName]) do
				lines[#lines + 1] = "  require(" .. dep .. ")"
			end
			lines[#lines + 1] = ""
		end
		lines[#lines + 1] = string.format("Total scripts with require: %d | Total calls: %d",
			#sortedScripts, totalRequires)
	else
		lines[#lines + 1] = "(No require() found in the saved scripts)"
	end
	writeFileSafe(Paths.ModuleDeps, table.concat(lines, "\n"))
	writeLog(string.format("MODULE_DEPENDENCIES.txt saved (%d requires).", totalRequires))
end
local function generateNetRemotes()
	local rs = safeGetService("ReplicatedStorage")
	if not rs then
		writeLog("NET_REMOTES: ReplicatedStorage inaccessible.")
		return
	end
	local lines = {
		"NET REMOTES (Modules.Net)",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: Remotes of the ReplicatedStorage.Modules.Net subsystem.",
		"Blox Fruits pattern: 'RE/Name' = RemoteEvent, 'RF/Name' = RemoteFunction.",
		"They are the communication backbone for gun, craft, fruit customization, etc.",
		string.rep("═", 80),
		"",
	}
	local netContainers = {}
	local function tryAddNet(root, path)
		if not root then return end
		local ok, obj = pcall(function() return root:FindFirstChild("Net") end)
		if ok and obj then
			netContainers[#netContainers + 1] = { obj = obj, path = path .. ".Net" }
		end
		local ok2, mods = pcall(function() return root:FindFirstChild("Modules") end)
		if ok2 and mods then
			local ok3, net = pcall(function() return mods:FindFirstChild("Net") end)
			if ok3 and net then
				netContainers[#netContainers + 1] = { obj = net, path = path .. ".Modules.Net" }
			end
		end
	end
	tryAddNet(rs, "ReplicatedStorage")
	local totalFound = 0
	local reCount, rfCount, otherCount = 0, 0, 0
	for _, container in ipairs(netContainers) do
		lines[#lines + 1] = "CONTAINER: " .. container.path
		lines[#lines + 1] = ""
		local ok, children = pcall(function() return container.obj:GetDescendants() end)
		if not ok then
			lines[#lines + 1] = "  (inaccessible)"
			lines[#lines + 1] = ""
		else
			local reLines, rfLines, otherLines = {}, {}, {}
			for _, child in ipairs(children) do
				local okN, name = pcall(function() return child.Name end)
				local okC, cls = pcall(function() return child.ClassName end)
				local okP, fpath = pcall(function() return child:GetFullName() end)
				if okN and okC then
					if cls == "RemoteEvent" or cls == "RemoteFunction"
						or cls == "UnreliableRemoteEvent" or cls == "BindableEvent"
						or cls == "BindableFunction" then
						pcall(registerRemote, child)
						totalFound += 1
						local inferredType = "?"
						if name:sub(1, 3) == "RE/" then
							inferredType = "RemoteEvent (RE/ pattern)"
							reCount += 1
						elseif name:sub(1, 3) == "RF/" then
							inferredType = "RemoteFunction (RF/ pattern)"
							rfCount += 1
						else
							otherCount += 1
						end
						local entry = string.format("  %-45s  [%s]  → %s",
							name, cls, inferredType)
						local fullEntry = {
							entry,
							"    Path: " .. (okP and fpath or "?"),
						}
						if name:sub(1, 3) == "RE/" then
							for _, l in ipairs(fullEntry) do reLines[#reLines + 1] = l end
						elseif name:sub(1, 3) == "RF/" then
							for _, l in ipairs(fullEntry) do rfLines[#rfLines + 1] = l end
						else
							for _, l in ipairs(fullEntry) do otherLines[#otherLines + 1] = l end
						end
					end
				end
				task.wait()
			end
			if #reLines > 0 then
				lines[#lines + 1] = "── RemoteEvents (RE/*) ──────────────────────────────────────────"
				for _, l in ipairs(reLines) do lines[#lines + 1] = l end
				lines[#lines + 1] = ""
			end
			if #rfLines > 0 then
				lines[#lines + 1] = "── RemoteFunctions (RF/*) ───────────────────────────────────────"
				for _, l in ipairs(rfLines) do lines[#lines + 1] = l end
				lines[#lines + 1] = ""
			end
			if #otherLines > 0 then
				lines[#lines + 1] = "── Others ───────────────────────────────────────────────────────"
				for _, l in ipairs(otherLines) do lines[#lines + 1] = l end
				lines[#lines + 1] = ""
			end
		end
		task.wait()
	end
	if #netContainers == 0 then
		lines[#lines + 1] = "(Modules.Net container not found — game may not use this pattern)"
	end
	lines[#lines + 1] = string.rep("═", 80)
	lines[#lines + 1] = string.format(
		"TOTAL: %d Net remotes | RE/: %d | RF/: %d | others: %d",
		totalFound, reCount, rfCount, otherCount
	)
	lines[#lines + 1] = "NOTE: These remotes were added to State.Remotes — they also appear in REMOTE_MAP."
	writeFileSafe(Paths.NetRemotes, table.concat(lines, "\n"))
	writeLog(string.format("NET_REMOTES.txt saved (%d remotes).", totalFound))
end
local function generateRakNetAnalysis()
	if not Config.EnableRakNetAnalysis then
		writeLog("RAKNET_ANALYSIS: disabled in settings. Skipping.")
		return
	end
	local lines = {
		"NETWORK PROTOCOL / RAKNET COMPATIBILITY ANALYSIS",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"Mode: PASSIVE STRUCTURAL INSPECTION (no hooks, no module execution)",
		string.rep("═", 84),
		"",
		"PURPOSE",
		"Assess whether the place exposes recognizable networking-library or packet-buffer evidence.",
		"A name match is only a lead; it does not prove that the game uses RakNet or ByteNet.",
		"",
		"LIMITATIONS",
		"This dump observes Roblox Instances and its existing remote-call summaries. It does not",
		"capture RakNet transport frames, packet IDs, reliability channels, or raw socket traffic.",
		"No protocol decoder is enabled by this report.",
		"",
	}
	local roots = {}
	for _, serviceName in ipairs({ "ReplicatedStorage", "ReplicatedFirst", "StarterPlayer" }) do
		local root = safeGetService(serviceName)
		if root then roots[#roots + 1] = { instance = root, name = serviceName } end
	end
	local terms = {
		"raknet", "bytenet", "rednet", "netwire", "network", "protocol",
		"serializer", "codec", "packet", "replication", "remote"
	}
	local matches, scanned = {}, 0
	local seen = {}
	for _, rootInfo in ipairs(roots) do
		local ok, descendants = pcall(function() return rootInfo.instance:GetDescendants() end)
		if ok and type(descendants) == "table" then
			for _, obj in ipairs(descendants) do
				scanned += 1
				local okName, name = pcall(function() return obj.Name end)
				local okClass, className = pcall(function() return obj.ClassName end)
				if okName and okClass then
					local lower = string.lower(tostring(name))
					local matched = {}
					for _, term in ipairs(terms) do
						if lower:find(term, 1, true) then matched[#matched + 1] = term end
					end
					if #matched > 0 then
						local okPath, path = pcall(function() return obj:GetFullName() end)
						local key = okPath and path or (rootInfo.name .. "/" .. tostring(name))
						if not seen[key] then
							seen[key] = true
							matches[#matches + 1] = {
								path = key, name = tostring(name), className = tostring(className),
								terms = table.concat(matched, ", ")
							}
						end
					end
				end
				if scanned % Config.YieldEvery == 0 then task.wait(); cancelPoint() end
			end
		end
	end
	table.sort(matches, function(a, b) return a.path < b.path end)
	lines[#lines + 1] = "SCAN SUMMARY"
	lines[#lines + 1] = "Roots inspected: " .. tostring(#roots)
	lines[#lines + 1] = "Instances inspected: " .. tostring(scanned)
	lines[#lines + 1] = "Name/path candidates: " .. tostring(#matches)
	lines[#lines + 1] = "Registered remotes: " .. tostring((function()
		local n = 0; for _ in pairs(State.Remotes) do n += 1 end; return n
	end)())
	lines[#lines + 1] = ""
	if #matches > 0 then
		lines[#lines + 1] = "CANDIDATES (NOT VERIFIED PROTOCOL IDENTIFICATION)"
		for _, item in ipairs(matches) do
			lines[#lines + 1] = "[" .. item.className .. "] " .. item.path
			lines[#lines + 1] = "  Matched terms: " .. item.terms
		end
	else
		lines[#lines + 1] = "No recognizable networking-library names were found in inspected roots."
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "RAKNET VALUE FOR THIS DUMP"
	lines[#lines + 1] = "Status: NOT ESTABLISHED"
	lines[#lines + 1] = "Reason: current capture path records Roblox remote calls, not RakNet transport packets."
	lines[#lines + 1] = "Next evidence needed: confirmed library/module source, packet schema, and a legitimate"
	lines[#lines + 1] = "buffer capture point. Only then should a format-specific, read-only decoder be considered."
	lines[#lines + 1] = ""
	lines[#lines + 1] = "SAFE RECOMMENDATION"
	lines[#lines + 1] = "Keep remote discovery and call logging as the primary network analysis path."
	lines[#lines + 1] = "Treat buffer arguments as opaque values unless their format is independently identified."
	writeFileSafe(Paths.RakNetAnalysis, table.concat(lines, "\n"))
	writeLog(string.format("RAKNET_ANALYSIS.txt saved | scanned=%d | candidates=%d", scanned, #matches))
end
local function generateWorkspaceRemotes()
	local ws = safeGetService("Workspace")
	if not ws then
		writeLog("WORKSPACE_REMOTES: Workspace inaccessible.")
		return
	end
	local lines = {
		"REMOTES IN WORKSPACE",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: RemoteEvents/Functions found INSIDE Workspace models.",
		"These remotes only exist at runtime and live in specific models (islands, boats, etc.).",
		"They are not in ReplicatedStorage — they are invisible to the standard passive scan.",
		string.rep("═", 80),
		"",
	}
	local totalFound = 0
	local byParent = {}
	local ok, descendants = pcall(function() return ws:GetDescendants() end)
	if not ok then
		lines[#lines + 1] = "(GetDescendants failed on Workspace)"
		writeFileSafe(Paths.WorkspaceRemotes, table.concat(lines, "\n"))
		return
	end
	local batchN = 0
	for _, obj in ipairs(descendants) do
		batchN += 1
		if batchN % Config.YieldEvery == 0 then task.wait(); cancelPoint() end
		local okC, cls = pcall(function() return obj.ClassName end)
		if okC and (cls == "RemoteEvent" or cls == "RemoteFunction"
			or cls == "UnreliableRemoteEvent" or cls == "BindableEvent"
			or cls == "BindableFunction") then
			local okP, fpath = pcall(function() return obj:GetFullName() end)
			local okN, name = pcall(function() return obj.Name end)
			local okPar, par = pcall(function() return obj.Parent end)
			local okPN, parName = false, "?"
			if okPar and par then
				okPN, parName = pcall(function() return par:GetFullName() end)
			end
			pcall(registerRemote, obj)
			totalFound += 1
			local parentKey = okPN and parName or "?"
			byParent[parentKey] = byParent[parentKey] or {}
			byParent[parentKey][#byParent[parentKey] + 1] = {
				name = okN and name or "?",
				cls = cls,
				fpath = okP and fpath or "?",
			}
		end
	end
	local sortedParents = {}
	for pname in pairs(byParent) do sortedParents[#sortedParents + 1] = pname end
	table.sort(sortedParents)
	for _, pname in ipairs(sortedParents) do
		lines[#lines + 1] = "MODEL/FOLDER: " .. pname
		for _, r in ipairs(byParent[pname]) do
			lines[#lines + 1] = string.format("  %-40s  [%s]", r.name, r.cls)
			lines[#lines + 1] = "    Path: " .. r.fpath
		end
		lines[#lines + 1] = ""
	end
	if totalFound == 0 then
		lines[#lines + 1] = "(No remotes found in Workspace models)"
	else
		lines[#lines + 1] = string.rep("═", 80)
		lines[#lines + 1] = string.format("TOTAL: %d remotes in Workspace | added to REMOTE_MAP.", totalFound)
	end
	writeFileSafe(Paths.WorkspaceRemotes, table.concat(lines, "\n"))
	writeLog(string.format("WORKSPACE_REMOTES.txt saved (%d remotes).", totalFound))
end
local function generateWorldItems()
	local ws = safeGetService("Workspace")
	if not ws then
		writeLog("WORLD_ITEMS: Workspace inaccessible.")
		return
	end
	local lines = {
		"WORLD ITEMS (root Workspace and _WorldOrigin)",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: Loose items on the ground detected at runtime.",
		"Fruits: Tools/Models with 'Fruit' in the name and a Handle child.",
		"Event items: children of workspace._WorldOrigin.",
		"Chests and interactables: detected by ProximityPrompt or ClickDetector.",
		string.rep("═", 80),
		"",
	}
	local fruitsFound, eventItems, chests, outros = {}, {}, {}, {}
	local okCh, wsChildren = pcall(function() return ws:GetChildren() end)
	if okCh then
		for _, obj in ipairs(wsChildren) do
			local okN, name = pcall(function() return obj.Name end)
			local okC, cls = pcall(function() return obj.ClassName end)
			if okN and okC then
				local lname = name:lower()
				if (cls == "Tool" or cls == "Model") and lname:find("fruit") then
					local okH, hasHandle = pcall(function() return obj:FindFirstChild("Handle") ~= nil end)
					if okH and hasHandle then
						local okPos, pos = pcall(function()
							local h = obj:FindFirstChild("Handle")
							return h and h.Position
						end)
						fruitsFound[#fruitsFound + 1] = {
							name = name, cls = cls,
							pos = okPos and pos and string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z) or "?",
						}
					end
				elseif pcall(function()
					return obj:FindFirstChildOfClass("ProximityPrompt")
						or obj:FindFirstChildOfClass("ClickDetector")
				end) then
					local hasPrompt = pcall(function() return obj:FindFirstChildOfClass("ProximityPrompt") ~= nil end)
					chests[#chests + 1] = { name = name, cls = cls, type = hasPrompt and "ProximityPrompt" or "ClickDetector" }
				end
			end
		end
	end
	local okWO, worldOrigin = pcall(function() return ws:FindFirstChild("_WorldOrigin") end)
	if okWO and worldOrigin then
		local okWOC, woChildren = pcall(function() return worldOrigin:GetChildren() end)
		if okWOC then
			for _, obj in ipairs(woChildren) do
				local okN, name = pcall(function() return obj.Name end)
				local okC, cls = pcall(function() return obj.ClassName end)
				if okN and okC then
					local hasPrompt = false
					pcall(function()
						hasPrompt = obj:FindFirstChildOfClass("ProximityPrompt") ~= nil
							or obj:FindFirstChildOfClass("ClickDetector") ~= nil
					end)
					eventItems[#eventItems + 1] = {
						name = name, cls = cls,
						interactive = hasPrompt and "YES" or "no",
					}
				end
			end
		end
	end
	lines[#lines + 1] = string.format("── FRUITS ON THE GROUND (%d) ───────────────────────────────────", #fruitsFound)
	if #fruitsFound == 0 then
		lines[#lines + 1] = "  (no fruit detected at the moment)"
	else
		for _, f in ipairs(fruitsFound) do
			lines[#lines + 1] = string.format("  %-40s  [%s]  pos: %s", f.name, f.cls, f.pos)
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format("── _WorldOrigin / EVENT ITEMS (%d) ─────────────────────────────", #eventItems)
	if not (okWO and worldOrigin) then
		lines[#lines + 1] = "  (_WorldOrigin does not exist — seasonal event inactive or different game)"
	elseif #eventItems == 0 then
		lines[#lines + 1] = "  (_WorldOrigin exists but is empty)"
	else
		for _, item in ipairs(eventItems) do
			lines[#lines + 1] = string.format("  %-40s  [%s]  interactable: %s",
				item.name, item.cls, item.interactive)
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format("── CHESTS / INTERACTABLES AT ROOT (%d) ─────────────────────────", #chests)
	if #chests == 0 then
		lines[#lines + 1] = "  (none detected)"
	else
		for _, c in ipairs(chests) do
			lines[#lines + 1] = string.format("  %-40s  [%s]  type: %s", c.name, c.cls, c.type)
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.rep("═", 80)
	lines[#lines + 1] = string.format(
		"TOTAL: %d fruits | %d event items | %d chests/interactables",
		#fruitsFound, #eventItems, #chests
	)
	writeFileSafe(Paths.WorldItems, table.concat(lines, "\n"))
	writeLog(string.format("WORLD_ITEMS.txt saved (%d fruits, %d event items, %d chests).",
		#fruitsFound, #eventItems, #chests))
end
local GameModulePaths = {
	"Controllers",
	"Controllers/CombatController",
	"Controllers/BonusMomentsController",
	"Controllers/DialogueController",
	"Controllers/UI",
	"Controllers/UI/Inventory",
	"Controllers/UI/FruitShop",
	"Economy",
	"Economy/ItemId",
	"Modules",
	"Modules/Net",
	"Modules/CombatUtil",
	"Definitions",
	"Definitions/Map",
	"NPCManager",
	"NPCManager/NPCList",
	"Quests",
	"Raids",
	"JobsReplicated",
	"DialoguesList",
	"BonusMomentsGuide",
	"GuideModule",
	"FishReplicated",
	"FishReplicated/FishingClient",
	"FishReplicated/FishingClient/Config",
	"Util",
	"Util/CameraShaker",
	"Util/Trajectory",
	"Util/GetWaterHeightAtLocation",
}
local function generateGameModules()
	local rs = safeGetService("ReplicatedStorage")
	if not rs then
		writeLog("GAME_MODULES: ReplicatedStorage inaccessible.")
		return
	end
	local lines = {
		"GAME MODULES (ReplicatedStorage)",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: Structure of the ModuleScripts and main Folders of the game.",
		"Includes Controllers, Economy, Modules/Net, NPCManager, Quests, etc.",
		"No decompilation — only hierarchy, attributes and children.",
		string.rep("═", 80),
		"",
	}
	local function resolveByPath(root, pathStr)
		local obj = root
		for segment in pathStr:gmatch("[^/]+") do
			if not obj then return nil end
			local ok, child = pcall(function() return obj:FindFirstChild(segment) end)
			if not ok or not child then return nil end
			obj = child
		end
		return obj
	end
	local function describeObject(obj, indent)
		local pad = string.rep("  ", indent)
		local result = {}
		local okN, name = pcall(function() return obj.Name end)
		local okC, cls = pcall(function() return obj.ClassName end)
		local okP, fp = pcall(function() return obj:GetFullName() end)
		result[#result + 1] = pad .. "┌─ " .. (okN and name or "?") .. "  [" .. (okC and cls or "?") .. "]"
		result[#result + 1] = pad .. "│  Path: " .. (okP and fp or "?")
		local okA, attrs = pcall(function() return obj:GetAttributes() end)
		if okA and attrs and next(attrs) then
			local attrParts = {}
			for k, v in pairs(attrs) do
				attrParts[#attrParts + 1] = tostring(k) .. "=" .. tostring(v)
			end
			result[#result + 1] = pad .. "│  Attributes: " .. table.concat(attrParts, ", ")
		end
		local okCh, children = pcall(function() return obj:GetChildren() end)
		if okCh and children and #children > 0 then
			result[#result + 1] = pad .. "│  Children (" .. #children .. "):"
			local shown = 0
			for _, child in ipairs(children) do
				shown += 1
				if shown > 30 then
					result[#result + 1] = pad .. "│    ... (+" .. (#children - 30) .. " omitted)"
					break
				end
				local okCN, cn = pcall(function() return child.Name end)
				local okCC, cc = pcall(function() return child.ClassName end)
				result[#result + 1] = pad .. "│    - " .. (okCN and cn or "?") .. "  (" .. (okCC and cc or "?") .. ")"
			end
		end
		result[#result + 1] = pad .. "└" .. string.rep("─", 60)
		return result
	end
	local found, missing = 0, 0
	for _, pathStr in ipairs(GameModulePaths) do
		local obj = resolveByPath(rs, pathStr)
		if obj then
			found += 1
			local desc = describeObject(obj, 0)
			for _, l in ipairs(desc) do lines[#lines + 1] = l end
			lines[#lines + 1] = ""
		else
			missing += 1
			lines[#lines + 1] = "✗ NOT FOUND: ReplicatedStorage/" .. pathStr
		end
		task.wait()
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.rep("═", 80)
	lines[#lines + 1] = "DIRECT CHILDREN OF ReplicatedStorage (not listed above):"
	lines[#lines + 1] = ""
	local okRS, rsChildren = pcall(function() return rs:GetChildren() end)
	if okRS then
		local documented = {}
		for _, p in ipairs(GameModulePaths) do
			local first = p:match("^[^/]+")
			if first then documented[first] = true end
		end
		for _, child in ipairs(rsChildren) do
			local okN, name = pcall(function() return child.Name end)
			local okC, cls = pcall(function() return child.ClassName end)
			if okN and not documented[name] then
				lines[#lines + 1] = string.format("  %-40s  [%s]  (not documented above)",
					name, okC and cls or "?")
			end
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.rep("═", 80)
	lines[#lines + 1] = string.format(
		"RESULT: %d modules found | %d not found",
		found, missing
	)
	writeFileSafe(Paths.GameModules, table.concat(lines, "\n"))
	writeLog(string.format("GAME_MODULES.txt saved (%d/%d modules).", found, found + missing))
end
local function generateIndex()
	local lines = {
		"╔══════════════════════════════════════════════════════════════╗",
		"║  CENTRAL INDEX — DUMP SYSTEM + ROBLOX INTELLIGENCE           ║",
		"╚══════════════════════════════════════════════════════════════╝",
		"",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"PlaceId  : " .. tostring(game.PlaceId),
		"PlaceName: " .. tostring(game.Name),
		"",
		"━━━ QUICK GUIDE FOR AIs ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
		"",
		"READ FIRST:",
		"  UNC_COMPATIBILITY.txt ← Executor compatibility: functions, categories, diff.",
		"  GAME_CONTEXT.txt      ← Game identity, MAP (sea/phase), executor, services.",
		"  PLAYER_STATE.txt      ← Current player state: level, beli, items, backpack.",
		"  ENEMIES_CATALOG.txt   ← Mobs present, extracted levels, count, positions.",
		"",
		"REMOTES:",
		"  REMOTE_MAP.txt        ← All remotes with calls, args and callers.",
		"  DISPATCHER_ACTIONS.txt← Actions of CommF_-type remotes (server API).",
		"  NET_REMOTES.txt       ← Remotes of the Modules.Net system (RE/* e RF/*).",
		"  WORKSPACE_REMOTES.txt ← Remotes inside Workspace models (islands, boats).",
		"  HOOK_SCRIPTS/         ← Ready-made hook script for each remote.",
		"  SCRIPT_TO_REMOTE.txt  ← Which script calls which remote.",
		"  CALL_LOG.txt          ← Live log (soak). Real args + caller.",
		"",
		"STRUCTURE:",
		"  GAME_MODULES.txt      ← Controllers, Economy, NPCManager, Net, Quests, etc.",
		"  TOOLS_INVENTORY.txt   ← Game tools with scripts, modules and attributes.",
		"  WORLD_ITEMS.txt       ← Fruits on the ground, event items, interactable chests.",
		"  MODULE_DEPENDENCIES.txt← require() found in decompiled scripts.",
		"  Workspace Structure.txt / PlayerGui Structure.txt ← Visual tree.",
		"  ATTRIBUTES.txt        ← Attributes of all objects.",
		"",
		"DECOMPILED SCRIPTS:",
		"  " .. Config.MainFolder .. "/<Service>/  ← Naming: <Service> <Folder> <Script>.lua",
		"",
		"━━━ REMOTES (summary) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
		"",
	}
	local remoteCount = 0
	local sorted = {}
	for path, data in pairs(State.Remotes) do
		table.insert(sorted, { path = path, data = data })
		remoteCount += 1
	end
	table.sort(sorted, function(a, b)
		return (a.data.outCalls + a.data.inCalls) > (b.data.outCalls + b.data.inCalls)
	end)
	for _, entry in ipairs(sorted) do
		local d = entry.data
		local badge = d.outCalls > 0 and "[ACTIVE]" or "[SILENT]"
		table.insert(lines, string.format(
			"%s  %-55s  %s  OUT:%d IN:%d",
			badge, d.fullPath, d.className, d.outCalls, d.inCalls
		))
	end
	table.insert(lines, "")
	table.insert(lines, "Total remotes: " .. remoteCount)
	table.insert(lines, "")
	table.insert(lines, "━━━ DECOMPILED SCRIPTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	table.insert(lines, "")
	local statusBadges = {
		success = "[SOURCE  ]",
		closure_stub = "[CLOSURE ]",
		bytecode_ref = "[BYTECODE]",
		panicked = "[STUB    ]",
		failed = "[FAILED  ]",
		write_error = "[WRERR   ]",
	}
	local metaList = {}
	for _, meta in pairs(State.ObjectsMeta) do metaList[#metaList + 1] = meta end
	table.sort(metaList, function(a, b) return (a.fullName or "") < (b.fullName or "") end)
	for _, meta in ipairs(metaList) do
		local statusBadge = statusBadges[meta.status] or "[?      ]"
		local categoryTag = classifyScript(meta.fullName or "", meta.className or "")
		table.insert(lines, string.format(
			"%s %s  %-50s  (%s)  method:%s",
			statusBadge, categoryTag, meta.fullName, meta.className, tostring(meta.method or "—")
		))
	end
	table.insert(lines, "")
	table.insert(lines, "━━━ STATISTICS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	table.insert(lines, "")
	local elapsed = tick() - State.StartTime
	local pct = State.Total > 0 and math.floor((State.Success + State.Skipped) / State.Total * 100) or 100
	local lines2 = {
		string.format("Total objects    : %d", State.Total),
		string.format("Processed        : %d", State.Processed),
		string.format("Already existing : %d", State.Skipped),
		string.format("Success (source) : %d", State.Success),
		string.format("Panics (stub)    : %d", State.Panicked),
		string.format("Roblox ignored   : %d", State.RobloxSkipped),
		string.format("Failures         : %d", State.Failed),
		string.format("Progress         : %d%%", pct),
		string.format("Total time       : %02d:%02d", math.floor(elapsed/60), math.floor(elapsed%60)),
	}
	for _, l in ipairs(lines2) do table.insert(lines, l) end
	writeFileSafe(Paths.Index, table.concat(lines, "\n"))
	writeLog("INDEX.txt generated.")
end
local function finalReport()
	local elapsed = tick() - State.StartTime
	local pct = State.Total > 0 and math.floor((State.Success + State.Skipped) / State.Total * 100) or 100
	local remoteCount = 0
	for _ in pairs(State.Remotes) do remoteCount += 1 end
	local dispatcherRemotes, totalActions = 0, 0
	for _, bucket in pairs(State.DispatcherActions) do
		dispatcherRemotes += 1
		for _ in pairs(bucket) do totalActions += 1 end
	end
	local lines = {
		"╔══════════ DUMP COMPLETED ══════════╗",
		string.format("  Objects   : %d", State.Total),
		string.format("  Success   : %d  |  Panics: %d  |  Failed: %d", State.Success, State.Panicked, State.Failed),
		string.format("  Roblox    : %d scripts ignored", State.RobloxSkipped),
		string.format("  Progress : %d%%", pct),
		string.format("  Remotes   : %d mapped", remoteCount),
		string.format("  Dispatcher: %d remotes | %d actions (DISPATCHER_ACTIONS.txt)", dispatcherRemotes, totalActions),
		string.format("  Calls     : %d captured", #State.CallLog),
		string.format("  Time      : %02d:%02d", math.floor(elapsed/60), math.floor(elapsed%60)),
		"  Reports   : GAME_CONTEXT · PLAYER_STATE · ENEMIES_CATALOG",
		"              TOOLS_INVENTORY · DISPATCHER_ACTIONS · MODULE_DEPS",
		"              NET_REMOTES · WORKSPACE_REMOTES · WORLD_ITEMS · GAME_MODULES",
		"╚════════════════════════════════════╝",
	}
	for _, l in ipairs(lines) do print("[Dump] " .. l) end
	if State.Failed > 0 then
		print("[Dump] Failures in: " .. Paths.FailedLog)
	end
	print("[Dump] INDEX.txt — read this file first.")
end
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
local function structureSafe(fn, fallback)
	local ok, result = pcall(fn)
	if ok then return result end
	return fallback
end
local function structureClean(value)
	return tostring(value == nil and "" or value):gsub("[%c]", " ")
end
local function structureEncode(value, depth, seen)
	depth, seen = depth or 0, seen or {}
	local kind = typeof(value)
	if kind == "nil" then return {type="nil", value="nil"} end
	if kind == "Instance" then
		return {
			type = "Instance",
			name = structureSafe(function() return value.Name end, "?"),
			className = structureSafe(function() return value.ClassName end, "?"),
			path = structureSafe(function() return value:GetFullName() end, "?"),
		}
	end
	if kind == "string" or kind == "number" or kind == "boolean" then
		return {type=kind, value=value}
	end
	if kind == "Vector3" then
		return {type="Vector3", value=string.format("%.4f, %.4f, %.4f", value.X, value.Y, value.Z)}
	end
	if kind == "Vector2" then
		return {type="Vector2", value=string.format("%.4f, %.4f", value.X, value.Y)}
	end
	if kind == "CFrame" then
		return {
			type="CFrame",
			position=string.format("%.4f, %.4f, %.4f", value.X, value.Y, value.Z),
			lookVector=string.format("%.4f, %.4f, %.4f", value.LookVector.X, value.LookVector.Y, value.LookVector.Z),
			value=string.format("%.4f, %.4f, %.4f", value.X, value.Y, value.Z),
		}
	end
	if kind == "Color3" then
		return {type="Color3", value=string.format("%d, %d, %d",
			math.floor(value.R*255+0.5), math.floor(value.G*255+0.5), math.floor(value.B*255+0.5))}
	end
	if kind == "BrickColor" then
		return {type="BrickColor", value=value.Name, number=value.Number}
	end
	if kind == "UDim2" then
		return {type="UDim2", value=string.format("{%.4f, %d}, {%.4f, %d}",
			value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)}
	end
	if kind == "UDim" then
		return {type="UDim", value=string.format("%.4f, %d", value.Scale, value.Offset)}
	end
	if kind == "Rect" then
		return {type="Rect", value=string.format("%.2f, %.2f, %.2f, %.2f",
			value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)}
	end
	if kind == "NumberRange" then
		return {type="NumberRange", value=string.format("%.4f, %.4f", value.Min, value.Max)}
	end
	if kind == "NumberSequence" then
		local kps = {}
		for _, kp in ipairs(value.Keypoints) do
			kps[#kps+1] = string.format("t=%.3f v=%.3f e=%.3f", kp.Time, kp.Value, kp.Envelope)
		end
		return {type="NumberSequence", value=table.concat(kps, " | ")}
	end
	if kind == "ColorSequence" then
		local kps = {}
		for _, kp in ipairs(value.Keypoints) do
			local c = kp.Value
			kps[#kps+1] = string.format("t=%.3f rgb(%d,%d,%d)",
				kp.Time, math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
		end
		return {type="ColorSequence", value=table.concat(kps, " | ")}
	end
	if kind == "EnumItem" then
		return {type="Enum", value=tostring(value), numVal=value.Value, enumType=tostring(value.EnumType)}
	end
	if kind == "Ray" then
		local o, d = value.Origin, value.Direction
		return {type="Ray",
			origin=string.format("%.4f, %.4f, %.4f", o.X, o.Y, o.Z),
			direction=string.format("%.4f, %.4f, %.4f", d.X, d.Y, d.Z),
			value=string.format("origin(%.4f,%.4f,%.4f) dir(%.4f,%.4f,%.4f)", o.X, o.Y, o.Z, d.X, d.Y, d.Z)}
	end
	if kind == "Font" then
		return {type="Font", value=structureSafe(function() return tostring(value) end, "[Font]")}
	end
	if kind == "table" then
		if depth >= 5 then return {type="table", value="[depth limit]"} end
		if seen[value] then return {type="table", value="[circular reference]"} end
		seen[value] = true
		local result = {type="table", value={}}
		for k, v in pairs(value) do
			result.value[tostring(k)] = structureEncode(v, depth + 1, seen)
		end
		seen[value] = nil
		return result
	end
	return {type=kind, value=structureSafe(function() return tostring(value) end, "[unavailable]")}
end
local function structureReadable(value)
	local encoded = structureEncode(value)
	if encoded.type == "string" then return string.format("%q", encoded.value) end
	if encoded.type == "table" then return "[table]" end
	if encoded.type == "CFrame" then return "CFrame(" .. (encoded.position or encoded.value) .. ")" end
	if encoded.type == "Enum" then return encoded.value .. " (" .. tostring(encoded.numVal) .. ")" end
	if encoded.type == "BrickColor" then return encoded.value .. " #" .. tostring(encoded.number) end
	if encoded.type == "Instance" then return encoded.className .. " " .. encoded.name end
	return structureClean(encoded.value)
end
local function structureServiceName(instance)
	local current = instance
	while current and structureSafe(function() return current.Parent end, nil) ~= game do
		current = structureSafe(function() return current.Parent end, nil)
	end
	return current and structureSafe(function() return current.Name end, "Unavailable") or "Unavailable"
end
local function structureGetAttributes(instance)
	return structureSafe(function() return instance:GetAttributes() end, {})
end
local function structureGetTags(instance)
	if not StructureConfig.IncludeTags then return {} end
	local collection = safeGetService("CollectionService")
	return collection and structureSafe(function() return collection:GetTags(instance) end, {}) or {}
end
local function _buildPropertySets()
	local t = {}
	t.BasePart = {
		"Anchored","CanCollide","CanTouch","CanQuery","CastShadow",
		"Transparency","Reflectance","Size","Position","Orientation",
		"CFrame","Material","Color","BrickColor","AssemblyMass",
		"AssemblyLinearVelocity","AssemblyAngularVelocity","Massless",
		"CollisionGroupId","RootPriority","Locked","Archivable",
	}
	t.MeshPart = {"MeshId","TextureID","MeshSize","DoubleSided"}
	t.SpecialMesh = {"MeshId","TextureId","MeshType","Scale","Offset"}
	t.UnionOperation = {"UsePartColor"}
	t.Humanoid = {
		"Health","MaxHealth","WalkSpeed","JumpPower","JumpHeight",
		"HipHeight","RigType","DisplayName","NameDisplayDistance",
		"HealthDisplayDistance","AutoRotate","AutoJumpEnabled","Sit",
		"PlatformStand","DisplayDistanceType","NameOcclusion","RequiresNeck",
	}
	t.HumanoidDescription = {
		"BodyTypeScale","HeadScale","HeightScale","ProportionScale","WidthScale",
		"Face","Head","LeftArm","LeftLeg","RightArm","RightLeg","Torso",
		"BackAccessory","FaceAccessory","FrontAccessory","HairAccessory",
		"HatAccessory","NeckAccessory","ShouldersAccessory","WaistAccessory",
	}
	t.Model = {"PrimaryPart","WorldPivot","LevelOfDetail","ModelLod"}
	t.ScreenGui = {"Enabled","DisplayOrder","ZIndexBehavior","ResetOnSpawn","IgnoreGuiInset"}
	t.Frame = {"Size","Position","AnchorPoint","BackgroundColor3","BackgroundTransparency","Visible","ZIndex","BorderSizePixel"}
	t.TextLabel = {"Text","TextSize","TextColor3","Font","FontFace","TextTransparency","TextWrapped","TextScaled","Visible"}
	t.TextButton = {"Text","TextSize","TextColor3","Font","FontFace","TextTransparency","TextWrapped","Visible","Active"}
	t.TextBox = {"Text","PlaceholderText","TextSize","TextColor3","Font","Visible","MultiLine"}
	t.ImageLabel = {"Image","ImageColor3","ImageTransparency","ScaleType","Size","Position","Visible"}
	t.ImageButton = {"Image","ImageColor3","ImageTransparency","ScaleType","Visible","Active"}
	t.ProximityPrompt = {
		"ActionText","ObjectText","HoldDuration","KeyboardKeyCode",
		"MaxActivationDistance","RequiresLineOfSight","Enabled","Style",
	}
	t.ClickDetector = {"MaxActivationDistance","CursorIcon"}
	t.Tool = {"ToolTip","Enabled","RequiresHandle","ManualActivationOnly","GripForward","GripPos","GripRight","GripUp"}
	t.BackpackItem = {"TextureId"}
	t.LocalScript = {"Disabled","RunContext"}
	t.Script = {"Disabled","RunContext"}
	t.ModuleScript = {}
	t.Sound = {"SoundId","Volume","PlaybackSpeed","Looped","Playing","TimePosition","RollOffMaxDistance","RollOffMinDistance","RollOffMode"}
	t.SoundGroup = {"Volume"}
	t.EqualizerSoundEffect = {"HighGain","LowGain","MidGain"}
	t.ReverbSoundEffect = {"Density","Diffusion","DecayTime"}
	t.ParticleEmitter = {"Texture","Rate","Lifetime","Speed","Size","Color","Enabled","EmissionDirection","RotSpeed","Rotation"}
	t.Beam = {"Attachment0","Attachment1","Texture","Color","Width0","Width1","Transparency","Enabled","TextureSpeed"}
	t.Trail = {"Attachment0","Attachment1","Color","Lifetime","MinLength","Transparency","Enabled","WidthScale"}
	t.SelectionBox = {"Adornee","Color3","LineThickness","SurfaceTransparency","Visible"}
	t.BillboardGui = {"Adornee","Size","StudsOffset","AlwaysOnTop","Enabled"}
	t.SurfaceGui = {"Face","Adornee","Enabled","SizingMode","ZOffset"}
	t.PointLight = {"Brightness","Color","Range","Enabled","Shadows"}
	t.SpotLight = {"Brightness","Color","Range","Angle","Face","Enabled","Shadows"}
	t.SurfaceLight = {"Brightness","Color","Range","Angle","Face","Enabled","Shadows"}
	t.LinearVelocity = {"MaxForce","VelocityConstraintMode","PlaneVelocity","LineVelocity","LineDirection"}
	t.BodyVelocity = {"Velocity","MaxForce"}
	t.BodyPosition = {"Position","MaxForce","P","D"}
	t.BodyGyro = {"CFrame","MaxTorque","P","D"}
	t.HingeConstraint = {"LimitsEnabled","LowerAngle","UpperAngle","AngularSpeed","MotorMaxAcceleration"}
	t.IntValue = {"Value"}
	t.NumberValue = {"Value"}
	t.StringValue = {"Value"}
	t.BoolValue = {"Value"}
	t.ObjectValue = {"Value"}
	t.CFrameValue = {"Value"}
	t.Vector3Value = {"Value"}
	t.Color3Value = {"Value"}
	t.Lighting = {
		"Brightness","ClockTime","FogColor","FogEnd","FogStart",
		"GeographicLatitude","GlobalShadows","OutdoorAmbient","Ambient",
		"ShadowSoftness","Technology",
	}
	return t
end
local STRUCTURE_PROPERTY_SETS = _buildPropertySets()
local function _buildDefaultProps()
	local d = {}
	d.BasePart = {Anchored=false,CanCollide=true,CanTouch=true,CanQuery=true,Transparency=0,Reflectance=0,Massless=false,Locked=false,CastShadow=true,CollisionGroupId=0,RootPriority=0}
	d.Humanoid = {MaxHealth=100,WalkSpeed=16,JumpPower=50,JumpHeight=7.2,AutoRotate=true,AutoJumpEnabled=true,Sit=false,PlatformStand=false,HipHeight=0}
	d.Sound = {Volume=0.5,PlaybackSpeed=1,Looped=false,Playing=false,TimePosition=0}
	d.ParticleEmitter = {Rate=20,Enabled=true}
	d.Tool = {Enabled=true,RequiresHandle=true,ManualActivationOnly=false}
	d.ClickDetector = {MaxActivationDistance=32}
	d.ProximityPrompt = {HoldDuration=0,MaxActivationDistance=10,RequiresLineOfSight=true,Enabled=true}
	d.PointLight = {Brightness=1,Range=16,Enabled=true,Shadows=false}
	d.SpotLight = {Brightness=1,Range=16,Angle=45,Enabled=true,Shadows=false}
	d.SurfaceLight = {Brightness=1,Range=16,Angle=45,Enabled=true,Shadows=false}
	return d
end
local STRUCTURE_DEFAULT_PROPS = _buildDefaultProps()
local function structureProperties(instance)
	local output = {}
	if not StructureConfig.IncludeProperties then return output end
	local ignoreDefaults = StructureConfig.IgnoreDefaultProps
	local seen = {}
	for className, properties in pairs(STRUCTURE_PROPERTY_SETS) do
		if structureSafe(function() return instance:IsA(className) end, false) then
			local defaults = ignoreDefaults and STRUCTURE_DEFAULT_PROPS[className] or nil
			for _, property in ipairs(properties) do
				if not seen[property] then
					local ok, value = pcall(function() return instance[property] end)
					if ok and value ~= nil then
						local isDefault = false
						if defaults and defaults[property] ~= nil then
							local dv = defaults[property]
							local tv = typeof(value)
							if tv == "boolean" or tv == "number" or tv == "string" then
								isDefault = (value == dv)
							end
						end
						if not isDefault then
							output[property] = structureEncode(value)
							seen[property] = true
						end
					end
				end
			end
		end
	end
	return output
end
local function structurePrepareCounts(root)
	local descendants = structureSafe(function() return root:GetDescendants() end, {})
	for _, descendant in ipairs(descendants) do
		local current = structureSafe(function() return descendant.Parent end, nil)
		while current and current ~= root do
			StructureState.descendantCounts[current] = (StructureState.descendantCounts[current] or 0) + 1
			current = structureSafe(function() return current.Parent end, nil)
		end
	end
	StructureState.descendantCounts[root] = #descendants
end
local function structureAddObject(instance)
	local attrs, attrOutput = structureGetAttributes(instance), {}
	local fullName = structureSafe(function() return instance:GetFullName() end, tostring(instance))
	local name = structureSafe(function() return instance.Name end, "?")
	local className = structureSafe(function() return instance.ClassName end, "?")
	for attrName, value in pairs(attrs) do
		local encoded = structureEncode(value)
		attrOutput[attrName] = encoded
		StructureState.attributes[#StructureState.attributes + 1] = {
			name=attrName, value=encoded, object=name, className=className,
			service=structureServiceName(instance), path=fullName,
		}
	end
	local parent = structureSafe(function() return instance.Parent end, nil)
	local props = structureProperties(instance)
	local propNames = {}
	for k in pairs(props) do propNames[#propNames+1] = k end
	table.sort(propNames)
	local record = {
		name=name, className=className, fullName=fullName,
		parent=parent and structureSafe(function() return parent:GetFullName() end, "?") or "nil",
		service=structureServiceName(instance), attributes=attrOutput,
		tags=structureGetTags(instance),
		descendantCount=StructureState.descendantCounts[instance] or 0,
		properties=props,
		propCount=#propNames,
		propNames=propNames,
	}
	StructureState.objects[#StructureState.objects + 1] = record
	return record
end
local function structureServiceRoots()
	local names = {
		"Workspace","ReplicatedStorage","ReplicatedFirst","ServerStorage",
		"ServerScriptService","StarterGui","StarterPack","StarterPlayer",
		"Players","Lighting","SoundService","Teams","TextChatService",
		"Chat","CollectionService","PhysicsService","MaterialService",
	}
	local roots, seen = {}, {}
	for _, name in ipairs(names) do
		local service = safeGetService(name)
		if service and not seen[service] then
			seen[service] = true
			roots[#roots + 1] = service
		end
	end
	return roots
end
local function structureWrite(path, content)
	content = tostring(content or "")
	if #content > StructureConfig.MaxTextBytes then
		error("File exceeded the configured limit: " .. path)
	end
	if not writeFileSafe(path, content) then error("Failed to write: " .. path) end
end
local function structureJson(value)
	local ok, encoded = pcall(function() return HttpService:JSONEncode(value) end)
	return ok and encoded or "{}"
end
local function structureFormatAttributes(attrs)
	local lines, keys = {}, {}
	for name in pairs(attrs) do keys[#keys + 1] = name end
	table.sort(keys)
	for _, name in ipairs(keys) do
		local encoded = attrs[name]
		lines[#lines + 1] = string.format('GetAttribute(%q) -- %s: %s',
			name, encoded.type, structureReadable(encoded.value))
	end
	return lines
end
local function structureScanWorkspace()
	local ws = safeGetService("Workspace")
	if not ws then return end
	structurePrepareCounts(ws)
	local lines = {"WORKSPACE", "Generated at: " .. os.date("%Y-%m-%d %H:%M:%S"), ""}
	local function visit(parent, prefix)
		local children = structureSafe(function() return parent:GetChildren() end, {})
		table.sort(children, function(a, b)
			local an = structureSafe(function() return a.Name end, "")
			local bn = structureSafe(function() return b.Name end, "")
			if an == bn then
				return structureSafe(function() return a.ClassName end, "") <
					structureSafe(function() return b.ClassName end, "")
			end
			return an:lower() < bn:lower()
		end)
		for index, child in ipairs(children) do
			local last = index == #children
			local branch = last and "└── " or "├── "
			local continuation = last and "    " or "│   "
			local path = structureSafe(function() return child:GetFullName() end, "?")
			local attrs = structureGetAttributes(child)
			local tags = structureGetTags(child)
			lines[#lines + 1] = prefix .. branch ..
				structureSafe(function() return child.Name end, "?") ..
				"  [" .. structureSafe(function() return child.ClassName end, "?") .. "]" ..
				"  (" .. tostring(StructureState.descendantCounts[child] or 0) .. " descendants)"
			lines[#lines + 1] = prefix .. continuation .. "   Path: " .. path
			local par = structureSafe(function() return child.Parent end, nil)
			lines[#lines + 1] = prefix .. continuation .. "   Parent: " ..
				(par and structureSafe(function() return par:GetFullName() end, "?") or "Unavailable")
			if #tags > 0 then
				lines[#lines + 1] = prefix .. continuation .. "   Tags: " .. table.concat(tags, ", ")
			end
			if next(attrs) then
				lines[#lines + 1] = prefix .. continuation .. "   Attributes:"
				for _, line in ipairs(structureFormatAttributes((function()
					local out = {}
					for k,v in pairs(attrs) do out[k] = structureEncode(v) end
					return out
				end)())) do
					lines[#lines + 1] = prefix .. continuation .. "   │   " .. line
				end
			end
			if structureSafe(function() return child:IsA("Model") end, false) then
				local primary = structureSafe(function() return child.PrimaryPart end, nil)
				lines[#lines + 1] = prefix .. continuation .. "   PrimaryPart: " ..
					(primary and primary.Name or "nil / unavailable")
			end
			if structureSafe(function() return child:IsA("Humanoid") end, false) then
				lines[#lines + 1] = prefix .. continuation .. "   Health: " ..
					structureReadable(structureSafe(function() return child.Health end, "?")) ..
					" | MaxHealth: " .. structureReadable(structureSafe(function() return child.MaxHealth end, "?")) ..
					" | WalkSpeed: " .. structureReadable(structureSafe(function() return child.WalkSpeed end, "?"))
			end
			if structureSafe(function() return child:IsA("BasePart") end, false) then
				lines[#lines + 1] = prefix .. continuation .. "   Part: Size=" ..
					structureReadable(structureSafe(function() return child.Size end, "?")) ..
					" Position=" .. structureReadable(structureSafe(function() return child.Position end, "?")) ..
					" Anchored=" .. structureReadable(structureSafe(function() return child.Anchored end, "?")) ..
					" CanCollide=" .. structureReadable(structureSafe(function() return child.CanCollide end, "?"))
			end
			StructureState.processed += 1
			if StructureState.processed % StructureConfig.BatchSize == 0 then
				pcall(structureWrite, StructurePaths.Checkpoint, structureJson({
					phase="Workspace", processed=StructureState.processed,
					lastPath=path, timestamp=os.time(),
				}))
				if not Config.FastMode then task.wait(StructureConfig.YieldSeconds) end
			end
			visit(child, prefix .. continuation)
		end
	end
	visit(ws, "")
	structureWrite(StructurePaths.Workspace, table.concat(lines, "\n"))
end
local function structureScanObjectsAndRemotes()
	local roots = structureServiceRoots()
	local seen = {}
	for _, root in ipairs(roots) do structurePrepareCounts(root) end
	for _, root in ipairs(roots) do
		local descendants = structureSafe(function() return root:GetDescendants() end, {})
		for _, instance in ipairs(descendants) do
			if not seen[instance] then
				seen[instance] = true
				local ok, err = pcall(structureAddObject, instance)
				if not ok then
					StructureState.errors[#StructureState.errors + 1] =
						structureSafe(function() return instance:GetFullName() end, "?") .. " | " .. tostring(err)
				end
				local className = structureSafe(function() return instance.ClassName end, "")
				if RemoteClasses[className] then pcall(registerRemote, instance) end
				StructureState.processed += 1
				if StructureState.processed % StructureConfig.BatchSize == 0 then
					pcall(structureWrite, StructurePaths.Checkpoint, structureJson({
						phase="Objects", processed=StructureState.processed,
						lastPath=structureSafe(function() return instance:GetFullName() end, "?"),
						timestamp=os.time(),
					}))
					if not Config.FastMode then task.wait(StructureConfig.YieldSeconds) end
				end
			end
		end
		if not seen[root] then
			seen[root] = true
			pcall(structureAddObject, root)
		end
	end
end
local function structureWriteReports()
	table.sort(StructureState.attributes, function(a,b)
		if a.path == b.path then return a.name < b.name end
		return a.path < b.path
	end)
	local attrLines = {
		"GAME ATTRIBUTES",
		"Generated at: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"Total attributes: " .. #StructureState.attributes,
		string.rep("=", 80), "",
	}
	for _, item in ipairs(StructureState.attributes) do
		attrLines[#attrLines + 1] = "-- ATTRIBUTE FOUND"
		attrLines[#attrLines + 1] = "Object: " .. item.object
		attrLines[#attrLines + 1] = "Class: " .. item.className
		attrLines[#attrLines + 1] = "Service: " .. item.service
		attrLines[#attrLines + 1] = "Path: " .. item.path
		attrLines[#attrLines + 1] = string.format('GetAttribute(%q) -- %s: %s',
			item.name, item.value.type, structureReadable(item.value.value))
		attrLines[#attrLines + 1] = string.rep("-", 80)
	end
	structureWrite(StructurePaths.Attributes, table.concat(attrLines, "\n"))
	local eventLines, functionLines, unreliableLines = {"REMOTE EVENTS",""}, {"REMOTE FUNCTIONS",""}, {"UNRELIABLE REMOTE EVENTS",""}
	local indexLines = {"REMOTE INDEX","Passive inventory; discovery does not mean the call was executed.",""}
	local remoteRows = {}
	for path, data in pairs(State.Remotes) do
		remoteRows[#remoteRows + 1] = {
			name=structureSafe(function() return data.instance.Name end, "?"),
			className=data.className, path=data.fullPath,
			service=structureServiceName(data.instance),
			direction=(data.className == "BindableEvent" or data.className == "BindableFunction")
				and "Local communication" or "Client-server remote",
			observation="Found in scan; calls not monitored",
			outCalls=data.outCalls, inCalls=data.inCalls,
		}
	end
	table.sort(remoteRows, function(a,b) return a.path < b.path end)
	for _, remote in ipairs(remoteRows) do
		local target = eventLines
		if remote.className == "RemoteFunction" then target = functionLines
		elseif remote.className == "UnreliableRemoteEvent" then target = unreliableLines end
		target[#target + 1] = remote.name .. " [" .. remote.className .. "]"
		target[#target + 1] = "Service: " .. remote.service
		target[#target + 1] = "Path: " .. remote.path
		target[#target + 1] = "Status: found in scan; calls not monitored"
		target[#target + 1] = string.rep("-", 70)
		indexLines[#indexLines + 1] = string.format("%s | %s | %s | %s",
			remote.className, remote.name, remote.service, remote.path)
	end
	structureWrite(StructurePaths.RemoteEvents, table.concat(eventLines, "\n"))
	structureWrite(StructurePaths.RemoteFunctions, table.concat(functionLines, "\n"))
	structureWrite(StructurePaths.Unreliable, table.concat(unreliableLines, "\n"))
	structureWrite(StructurePaths.RemoteIndex, table.concat(indexLines, "\n"))
	structureWrite(StructurePaths.ObjectsJson, structureJson({
		generatedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
		count=#StructureState.objects, objects=StructureState.objects,
	}))
	structureWrite(StructurePaths.AttributesJson, structureJson({
		generatedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
		count=#StructureState.attributes, attributes=StructureState.attributes,
	}))
	structureWrite(StructurePaths.RemotesJson, structureJson({
		generatedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
		count=#remoteRows, remotes=remoteRows,
	}))
	structureWrite(StructurePaths.Errors,
		#StructureState.errors > 0 and table.concat(StructureState.errors, "\n") or "No errors recorded.")
	structureWrite(StructurePaths.Checkpoint, structureJson({
		phase="Completed", processed=StructureState.processed,
		objects=#StructureState.objects, attributes=#StructureState.attributes,
		remotes=#remoteRows, errors=#StructureState.errors, completedAt=os.time(),
	}))
end
local function runIntegratedStructureDump()
	createFolderRecursive(StructurePaths.RemoteFolder)
	local ok, err = pcall(function()
		if StructureConfig.IncludeWorkspaceTree then structureScanWorkspace() end
		structureScanObjectsAndRemotes()
		structureWriteReports()
	end)
	if not ok then
		StructureState.errors[#StructureState.errors + 1] = "General failure: " .. tostring(err)
		pcall(structureWrite, StructurePaths.Errors, table.concat(StructureState.errors, "\n"))
		writeLog("[WARN] Structural inventory: " .. tostring(err))
	else
		writeLog(string.format("Structural inventory completed | objects=%d | attributes=%d | errors=%d",
			#StructureState.objects, #StructureState.attributes, #StructureState.errors))
	end
end
local function main()
	if not has("writefile") or not has("isfile") then
		warn("[Dump] No writefile/isfile — aborting.")
		return
	end
	if not has("decompile") then
		local fb = {}
		if has("getscriptclosure")  then table.insert(fb, "getscriptclosure") end
		if has("getscriptbytecode") then table.insert(fb, "getscriptbytecode") end
		warn("[Dump] decompile() missing. Fallbacks: " .. (#fb > 0 and table.concat(fb, ", ") or "none"))
	end
	createAllFolders()
	loadCheckpoint()
	CrashGuard.load()
	writeLog("Dump started | PlaceId: " .. tostring(game.PlaceId) .. " | " .. tostring(game.Name))
	installHooks()
	if not Config.FastMode then task.wait(Config.SoakSeconds) end
	cancelPoint()
	local remoteCount = 0
	for _ in pairs(State.Remotes) do remoteCount += 1 end
	writeLog(string.format("Scan completed. Remotes: %d | LiveHooks: %s",
		remoteCount, tostring(Config.EnableLiveHooks)))
	for _, svcName in ipairs(Config.ServiceList) do
		cancelPoint()
		processService(svcName)
	end
	generateGameContext()
	generatePlayerState()
	generateGameModules()
	generateWorkspaceReport()
	generatePlayerGuiReport()
	generateEnemiesCatalog()
	generateToolsInventory()
	generateWorldItems()
	generateWorkspaceRemotes()
	generateNetRemotes()
	generateRakNetAnalysis()
	runIntegratedStructureDump()
	uninstallHooks()
	markDispatchersInState()
	generateRemoteMap()
	generateDispatcherMap()
	generateCallLog()
	generateScriptToRemote()
	generateHookScripts()
	generateModuleDependencies()
	flushLog()
	if #State.FailedList > 0 then
		pcall(Env.writefile, Paths.FailedLog, table.concat(State.FailedList, "\n"))
	end
	saveCheckpoint()
	saveMetadata()
	generateIndex()
	finalReport()
end
do
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local TITLE_H, STATUS_H, SIDEBAR_W = 40, 32, 52
local MAX_LOG = 300
local Lucide, lucideError, lucideSource
do
	local SOURCES = {
		"https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua",
		"https://github.com/latte-soft/lucide-roblox/releases/download/0.1.3/lucide-roblox.luau",
		"https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau",
	}
	local function fetch(url)
		local ok, body = pcall(function() return game:HttpGet(url, true) end)
		if ok and type(body) == "string" and #body > 0 then return body end
		local req = (syn and syn.request) or http_request or request
		if type(req) == "function" then
			local ok2, res = pcall(req, { Url = url, Method = "GET" })
			if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
				return res.Body
			end
		end
		return nil, tostring(body)
	end
	for _, url in ipairs(SOURCES) do
		for attempt = 1, 2 do
			local body, ferr = fetch(url)
			if body then
				local ok, lib = pcall(function() return loadstring(body)() end)
				if ok and type(lib) == "table" and type(lib.GetAsset) == "function" then
					Lucide = lib
					lucideSource = url
					break
				end
				lucideError = "loadstring/module error: " .. tostring(lib)
			else
				lucideError = "download failed: " .. tostring(ferr)
			end
			task.wait(0.3)
		end
		if Lucide then break end
	end
	if not Lucide then warn("[DumpExplorer] Lucide failed to load: " .. tostring(lucideError)) end
end
local C = {
	window = Color3.fromRGB(23, 23, 23),
	titlebar = Color3.fromRGB(36, 36, 36),
	sidebar = Color3.fromRGB(28, 28, 28),
	card = Color3.fromRGB(28, 28, 28),
	cardHover = Color3.fromRGB(32, 32, 32),
	input = Color3.fromRGB(21, 21, 21),
	border = Color3.fromRGB(36, 36, 36),
	borderHi = Color3.fromRGB(75, 75, 75),
	accent = Color3.fromRGB(78, 124, 214),
	accentHi = Color3.fromRGB(212, 212, 212),
	accentBg = Color3.fromRGB(34, 34, 34),
	green = Color3.fromRGB(86, 190, 140),
	greenBg = Color3.fromRGB(21, 40, 33),
	red = Color3.fromRGB(226, 105, 112),
	redBg = Color3.fromRGB(48, 25, 28),
	yellow = Color3.fromRGB(220, 176, 80),
	blue = Color3.fromRGB(104, 152, 240),
	gray = Color3.fromRGB(104, 104, 104),
	textHi = Color3.fromRGB(254, 254, 254),
	text = Color3.fromRGB(200, 200, 200),
	textDim = Color3.fromRGB(120, 120, 120),
	scroll = Color3.fromRGB(75, 75, 75),
	logInfo = Color3.fromRGB(140, 140, 140),
	logOk = Color3.fromRGB(86, 190, 140),
	logWarn = Color3.fromRGB(220, 176, 80),
	logErr = Color3.fromRGB(226, 105, 112),
}
local UIState = {
	activeTab = "services",
	running = false,
	finished = false,
	logLines = {},
	phase = "idle",
	pct = 0,
	pctLabel = "",
	svcToggles = {},
	refs = {},
	statusText = "Ready",
}
local ALL_SERVICES = {
	"ReplicatedFirst", "ReplicatedStorage", "Players",
	"Workspace", "PlayerGui", "Lighting", "SoundService",
	"StarterGui", "StarterPack", "StarterPlayer", "TextChatService", "Teams",
}
for _, s in ipairs(ALL_SERVICES) do
	UIState.svcToggles[s] = false
	for _, d in ipairs(Config.ServiceList) do
		if d == s then UIState.svcToggles[s] = true; break end
	end
end
local function inst(cls, props)
	local i = Instance.new(cls)
	pcall(function() i.AutoLocalize = false end)
	for k, v in pairs(props) do pcall(function() i[k] = v end) end
	return i
end
local function corner(p, r)
	return inst("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p })
end
local function pad(p, t, r, b, l)
	return inst("UIPadding", {
		PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0),
		Parent = p,
	})
end
local function stroke(p, col, th)
	return inst("UIStroke", {
		Color = col or C.border, Thickness = th or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p,
	})
end
local function vList(p, gap)
	return inst("UIListLayout", {
		Padding = UDim.new(0, gap or 6), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical, Parent = p,
	})
end
local function hList(p, gap)
	return inst("UIListLayout", {
		Padding = UDim.new(0, gap or 6), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = p,
	})
end
local function tween(o, props, t)
	pcall(function()
		TweenService:Create(o, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
	end)
end
local function label(parent, text, size, color, font, props)
	local l = inst("TextLabel", {
		Text = text, TextSize = size or 12, TextColor3 = color or C.text,
		Font = font or Enum.Font.Gotham, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, (size or 12) + 4), Parent = parent,
	})
	if props then for k, v in pairs(props) do pcall(function() l[k] = v end) end end
	return l
end
local function wrapLabel(parent, text, size, color, lo)
	return label(parent, text, size, color, nil, {
		TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), LayoutOrder = lo or 0,
	})
end
local function divider(parent, lo)
	return inst("Frame", {
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border,
		BorderSizePixel = 0, LayoutOrder = lo or 0, Parent = parent,
	})
end
local function mkCard(parent, height, lo)
	local c = inst("Frame", {
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = lo or 0, Parent = parent,
	})
	corner(c, 8); stroke(c, C.border)
	return c
end
local ICON_ALIASES = {
	["play-circle"]    = { "circle-play" },
	["check-circle"]   = { "circle-check" },
	["x-circle"]       = { "circle-x" },
	["bar-chart-2"]    = { "chart-column", "bar-chart" },
	["hook"]           = { "webhook", "anchor" },
	["index"]          = { "list-ordered", "book-open", "list" },
	["code-2"]         = { "code-xml", "code" },
	["layout"]         = { "layout-dashboard", "panels-top-left" },
	["layout-dashboard"] = { "layout", "panels-top-left" },
	["loader"]         = { "loader-circle", "loader-2" },
	["maximize"]       = { "maximize-2", "square" },
	["sword"]          = { "swords" },
	["terminal"]       = { "square-terminal" },
	["alert-triangle"] = { "triangle-alert" },
	["backpack"]       = { "package" },
	["monitor"]        = { "layout" },
	["download"]       = { "arrow-down-to-line", "arrow-down" },
	["copy"]           = { "clipboard" },
}
local GLYPHS = {
	["x"] = "×", ["minus"] = "–", ["maximize"] = "□", ["play"] = "▶",
	["play-circle"] = "▶", ["check"] = "✓", ["check-circle"] = "✓",
	["x-circle"] = "×", ["info"] = "i", ["hash"] = "#", ["trash-2"] = "×",
	["terminal"] = ">_", ["loader"] = "…", ["alert-triangle"] = "!",
}
local assetCache, missingIcons = {}, {}
local function resolveAsset(name)
	if not Lucide then return nil end
	local cached = assetCache[name]
	if cached ~= nil then return cached or nil end
	local candidates = { name }
	for _, a in ipairs(ICON_ALIASES[name] or {}) do candidates[#candidates + 1] = a end
	for _, cand in ipairs(candidates) do
		for _, sz in ipairs({ 48, 256, false }) do
			local ok, asset = pcall(function()
				if sz then return Lucide.GetAsset(cand, sz) end
				return Lucide.GetAsset(cand)
			end)
			if ok and type(asset) == "table" and asset.Url then
				assetCache[name] = asset
				return asset
			end
		end
	end
	assetCache[name] = false
	return nil
end
local function setIcon(img, iconName)
	local asset = resolveAsset(iconName)
	local glyph = img:FindFirstChild("Glyph")
	if asset then
		img.Image = asset.Url
		img.ImageRectSize = asset.ImageRectSize
		img.ImageRectOffset = asset.ImageRectOffset
		if glyph then glyph.Visible = false end
	else
		missingIcons[iconName] = true
		img.Image = ""
		if not glyph then
			glyph = inst("TextLabel", {
				Name = "Glyph", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
				Font = Enum.Font.GothamBold, TextScaled = true,
				TextColor3 = img.ImageColor3, Parent = img,
			})
			img:GetPropertyChangedSignal("ImageColor3"):Connect(function()
				glyph.TextColor3 = img.ImageColor3
			end)
		end
		glyph.Text = GLYPHS[iconName] or "•"
		glyph.Visible = true
	end
end
local function mkIcon(parent, iconName, size, color, props)
	local sz = size or 16
	local img = inst("ImageLabel", {
		Name = "Icon", Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1,
		ImageColor3 = color or C.textDim, ScaleType = Enum.ScaleType.Fit, Parent = parent,
	})
	setIcon(img, iconName)
	if props then for k, v in pairs(props) do pcall(function() img[k] = v end) end end
	return img
end
local function mkButton(parent, text, style, size, iconName, lo)
	local cols = {
		primary = { bg = C.accent, fg = C.textHi, st = C.accent },
		secondary = { bg = C.card,   fg = C.text,   st = C.border },
		danger = { bg = C.card,   fg = C.red,    st = C.border },
	}
	local c = cols[style or "secondary"]
	local b = inst("TextButton", {
		Text = "", Size = size or UDim2.new(1, 0, 0, 34), BackgroundColor3 = c.bg,
		AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = lo or 0, Parent = parent,
	})
	corner(b, 8)
	local st = stroke(b, c.st)
	local row = inst("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = b })
	local rl = hList(row, 7)
	rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local ic = iconName and mkIcon(row, iconName, 14, c.fg, { LayoutOrder = 0 }) or nil
	local lbl = label(row, text, 12, c.fg, Enum.Font.GothamSemibold, {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1,
	})
	local api = { button = b, label = lbl, icon = ic, base = c.bg }
	function api.setColors(bg, fg, strokeCol)
		api.base = bg
		b.BackgroundColor3 = bg; lbl.TextColor3 = fg; st.Color = strokeCol or st.Color
		if ic then ic.ImageColor3 = fg end
	end
	b.MouseEnter:Connect(function() b.BackgroundColor3 = api.base:Lerp(Color3.new(1, 1, 1), 0.08) end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = api.base end)
	return api
end
local function mkToggle(parent, initVal, onChange)
	local t = { value = initVal and true or false }
	local track = inst("TextButton", {
		Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		Size = UDim2.fromOffset(36, 20), Parent = parent,
	})
	corner(track, 10)
	local st = stroke(track, C.borderHi)
	local knob = inst("Frame", {
		Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0, Parent = track,
	})
	corner(knob, 7)
	local function paint(animate)
		local pos = t.value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local bg = t.value and C.accent or C.input
		local kc = t.value and C.textHi or C.textDim
		st.Color = t.value and C.accent or C.borderHi
		if animate then
			tween(knob, { Position = pos, BackgroundColor3 = kc })
			tween(track, { BackgroundColor3 = bg })
		else
			knob.Position = pos; knob.BackgroundColor3 = kc; track.BackgroundColor3 = bg
		end
	end
	function t.set(v, silent)
		v = v and true or false
		if t.value == v then return end
		t.value = v
		paint(true)
		if onChange and not silent then onChange(v) end
	end
	track.Activated:Connect(function() t.set(not t.value) end)
	t.track = track
	paint(false)
	return t
end
local function numBox(parent, initVal, minV, maxV, onChange)
	local cur = initVal
	local box = inst("TextBox", {
		Text = tostring(cur), TextSize = 12, TextColor3 = C.accentHi, Font = Enum.Font.Code,
		BackgroundColor3 = C.input, BorderSizePixel = 0, Size = UDim2.fromOffset(56, 26),
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		ClearTextOnFocus = false, Parent = parent,
	})
	corner(box, 6)
	local st = stroke(box, C.borderHi)
	box.Focused:Connect(function() st.Color = C.accent end)
	box.FocusLost:Connect(function()
		st.Color = C.borderHi
		local n = tonumber(box.Text)
		if n then
			cur = math.clamp(math.floor(n + 0.5), minV, maxV)
			onChange(cur)
		end
		box.Text = tostring(cur)
	end)
	return box
end
local logQueues = setmetatable({}, { __mode = "k" })
local logSeq = 0
local function pushLine(scroll, text, color)
	local q = logQueues[scroll]
	if not q then q = {}; logQueues[scroll] = q end
	logSeq += 1
	q[#q + 1] = inst("TextLabel", {
		Text = text, TextSize = 10, TextColor3 = color or C.logInfo, Font = Enum.Font.Code,
		BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None, LayoutOrder = logSeq, Parent = scroll,
	})
	if #q > MAX_LOG then table.remove(q, 1):Destroy() end
	task.defer(function()
		if not scroll.Parent then return end
		task.defer(function()
			if not scroll.Parent then return end
			local bottom = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y)
			scroll.CanvasPosition = Vector2.new(0, bottom)
		end)
	end)
end
local function uiLog(text, color)
	local line = text
	table.insert(UIState.logLines, { text = line, color = color or C.logInfo })
	if #UIState.logLines > MAX_LOG then table.remove(UIState.logLines, 1) end
	for _, ref in ipairs({ UIState.refs.liveScroll }) do
		if ref and ref.Parent then pushLine(ref, line, color) end
	end
end
local _wl = writeLog
writeLog = function(msg)
	_wl(msg)
	local m = tostring(msg):lower()
	local col = C.logInfo
	if m:find("error") or m:find("failed") then col = C.logErr
	elseif m:find("saved") or m:find("completed") or m:find("ok") then col = C.logOk
	elseif m:find("warn") or m:find("missing") or m:find("unavailable") or m:find("inaccessible") then col = C.logWarn end
	uiLog(msg, col)
end
local function setStatus(text, color)
	UIState.statusText = text
	if UIState.refs.statusLbl and UIState.refs.statusLbl.Parent then
		UIState.refs.statusLbl.Text = text
		UIState.refs.statusLbl.TextColor3 = color or C.text
	end
end
local function setProgress(pct, lbl)
	UIState.pct = math.clamp(pct, 0, 100); UIState.pctLabel = lbl or ""
end
local function fileExists(path)
	if not has("isfile") then return false end
	local ok, res = pcall(Env.isfile, path)
	return ok and res == true
end
local function posStore()
	local ok, env = pcall(getgenv)
	return (ok and type(env) == "table") and env or _G
end
local function buildUI()
	local LP = Players.LocalPlayer
	if not LP then return end
	local PGui = LP:WaitForChild("PlayerGui", 10)
	if not PGui then return end
	local prev = PGui:FindFirstChild("DumpExplorer")
	if prev then prev:Destroy() end
	local screen = inst("ScreenGui", {
		Name = "DumpExplorer", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = PGui,
	})
	local conns = {}
	local function track(c) conns[#conns + 1] = c; return c end
	screen.Destroying:Connect(function()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	end)
	Lifecycle.add(function() screen:Destroy() end)
	local ToastHolder = inst("Frame", {
		Name = "Toasts", BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 150,
		Parent = screen,
	})
	inst("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 9), Parent = ToastHolder,
	})
	local ToastSeq = 0
	local LOGO_IMAGE_TOAST = "rbxassetid://125839047186269"
	local function notify(title, text, duration)
		ToastSeq = ToastSeq + 1
		duration = math.clamp(tonumber(duration) or 5, 1, 15)
		local card = inst("Frame", {
			Name = "DumpNotification", Size = UDim2.new(1, 0, 0, 68),
			BackgroundColor3 = Color3.fromRGB(23, 23, 23), BackgroundTransparency = 0.02,
			BorderSizePixel = 0, LayoutOrder = ToastSeq, ZIndex = 150, ClipsDescendants = true,
			Parent = ToastHolder,
		})
		corner(card, 10)
		inst("UIStroke", { Color = Color3.fromRGB(36, 36, 36), Transparency = 0.22, Thickness = 1, Parent = card })
		local scale = inst("UIScale", { Scale = 0.92, Parent = card })
		local iconHolder = inst("Frame", {
			Name = "IconHolder", Size = UDim2.fromOffset(36, 36),
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(36, 36, 36),
			BorderSizePixel = 0, ZIndex = 151, Parent = card,
		})
		corner(iconHolder, 8)
		if LOGO_IMAGE_TOAST and LOGO_IMAGE_TOAST ~= "" then
			inst("ImageLabel", {
				Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1,
				Image = LOGO_IMAGE_TOAST, ScaleType = Enum.ScaleType.Fit,
				ZIndex = 152, Parent = iconHolder,
			})
		else
			inst("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "D",
				Font = Enum.Font.GothamBold, TextSize = 18,
				TextColor3 = Color3.fromRGB(240, 240, 240), ZIndex = 152, Parent = iconHolder,
			})
		end
		local titleLab = inst("TextLabel", {
			Text = tostring(title or "Dump Explorer"), TextSize = 12,
			TextColor3 = Color3.fromRGB(254, 254, 254), Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -88, 0, 16),
			ZIndex = 152, Parent = card,
		})
		local descLab = inst("TextLabel", {
			Text = tostring(text or ""), TextSize = 10,
			TextColor3 = Color3.fromRGB(180, 180, 180), Font = Enum.Font.Gotham,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(60, 28), Size = UDim2.new(1, -78, 0, 26),
			ZIndex = 152, Parent = card,
		})
		local closeBtn = inst("TextButton", {
			Name = "Close", Text = "×", Font = Enum.Font.GothamBold, TextSize = 16,
			TextColor3 = Color3.fromRGB(140, 140, 140), AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(21, 21, 21), BorderSizePixel = 0,
			Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -28, 0, 8),
			ZIndex = 154, Parent = card,
		})
		corner(closeBtn, 6)
		closeBtn.MouseEnter:Connect(function()
			tween(closeBtn, { TextColor3 = Color3.fromRGB(254, 254, 254), BackgroundColor3 = Color3.fromRGB(36, 36, 36) }, 0.12)
		end)
		closeBtn.MouseLeave:Connect(function()
			tween(closeBtn, { TextColor3 = Color3.fromRGB(140, 140, 140), BackgroundColor3 = Color3.fromRGB(21, 21, 21) }, 0.12)
		end)
		local progressBack = inst("Frame", {
			Size = UDim2.new(1, -28, 0, 2), Position = UDim2.new(0, 14, 1, -5),
			BackgroundColor3 = Color3.fromRGB(36, 36, 36), BorderSizePixel = 0, ZIndex = 153, Parent = card,
		})
		corner(progressBack, 2)
		local progress = inst("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(140, 140, 140),
			BorderSizePixel = 0, ZIndex = 154, Parent = progressBack,
		})
		corner(progress, 2)
		local removed = false
		local function dismiss()
			if removed or not card.Parent then return end
			removed = true
			tween(scale, { Scale = 0.92 }, 0.15)
			tween(card, { BackgroundTransparency = 1 }, 0.15)
			task.delay(0.17, function() if card and card.Parent then card:Destroy() end end)
		end
		closeBtn.Activated:Connect(dismiss)
		tween(scale, { Scale = 1 }, 0.18)
		tween(progress, { Size = UDim2.fromScale(0, 1) }, duration)
		task.delay(duration, dismiss)
		local kids = {}
		for _, c in ipairs(ToastHolder:GetChildren()) do
			if c:IsA("Frame") and c ~= card then kids[#kids + 1] = c end
		end
		table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		while #kids >= 3 do table.remove(kids, 1):Destroy() end
	end
	local root = inst("Frame", {
		Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromOffset(560, 400), Parent = screen,
	})
	local win = inst("Frame", {
		Name = "Window", Size = UDim2.fromOffset(560, 400), BackgroundColor3 = C.window,
		BorderSizePixel = 0, Active = true, Parent = root,
	})
	corner(win, 10)
	stroke(win, C.border, 1)
	local scaleObj = inst("UIScale", { Scale = 0.8, Parent = win })
	local LOGO_IMAGE = "rbxassetid://125839047186269"
	local curW, curH = 560, 400
	local posX, posY = 0, 0
	local function viewport()
		local v = screen.AbsoluteSize
		if v.X < 50 or v.Y < 50 then
			local cam = workspace.CurrentCamera
			if cam then v = cam.ViewportSize end
		end
		return v
	end
	local function applySize()
		local vs, s = viewport(), scaleObj.Scale
		curW = math.clamp(math.floor(vs.X / s) - 24, 280, 600)
		curH = math.clamp(math.floor(vs.Y / s) - 24, 240, 420)
		win.Size = UDim2.fromOffset(curW, curH)
		root.Size = UDim2.fromOffset(curW * s, curH * s)
	end
	local function place(x, y)
		local vs, s = viewport(), scaleObj.Scale
		local rw = curW * s
		local keep = math.min(96, rw)
		x = math.clamp(x, keep - rw, math.max(keep - rw, vs.X - keep))
		y = math.clamp(y, 0, math.max(0, vs.Y - TITLE_H * s))
		posX, posY = x, y
		root.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
		posStore().__DumpExplorerPos = { x = x, y = y }
	end
	local TB = inst("Frame", {
		Name = "TitleBar", Size = UDim2.new(1, 0, 0, TITLE_H),
		BackgroundColor3 = C.titlebar, BorderSizePixel = 0, Parent = win,
	})
	corner(TB, 10)
	local tbFill = inst("Frame", {
		Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = C.titlebar, BorderSizePixel = 0, Parent = TB,
	})
	inst("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = C.border, BorderSizePixel = 0, Parent = TB,
	})
	local dragArea = inst("Frame", {
		Name = "DragArea", Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1,
		Active = true, Parent = TB,
	})
	inst("ImageLabel", {
		Size = UDim2.fromOffset(28, 28),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		BackgroundTransparency = 1,
		Image = LOGO_IMAGE,
		ScaleType = Enum.ScaleType.Fit,
		Parent = TB,
	})
	label(TB, "Dump Explorer", 13, C.textHi, Enum.Font.GothamBold, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 220, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local ctrl = inst("Frame", {
		Size = UDim2.new(0, 38, 1, 0), AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0), BackgroundTransparency = 1, Parent = TB,
	})
	local ctrlList = hList(ctrl, 4)
	ctrlList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local function winBtn(iconName, hoverBg, lo)
		local b = inst("TextButton", {
			Text = "", Size = UDim2.fromOffset(30, 28), BackgroundColor3 = hoverBg,
			BackgroundTransparency = 1, AutoButtonColor = false, BorderSizePixel = 0,
			LayoutOrder = lo, Parent = ctrl,
		})
		corner(b, 6)
		local ic = mkIcon(b, iconName, 14, C.textDim, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		})
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0; ic.ImageColor3 = C.textHi end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1; ic.ImageColor3 = C.textDim end)
		return b, ic
	end
	local closeB = winBtn("x", C.redBg, 1)
	closeB.Activated:Connect(function() screen:Destroy() end)
	local body = inst("Frame", {
		Name = "Body", Size = UDim2.new(1, 0, 1, -(TITLE_H + STATUS_H)),
		Position = UDim2.fromOffset(0, TITLE_H), BackgroundTransparency = 1, Parent = win,
	})
	local sidebar = inst("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, SIDEBAR_W, 1, 0), ZIndex = 5,
		BackgroundColor3 = C.sidebar, BorderSizePixel = 0, Parent = body,
	})
	inst("Frame", {
		Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = C.border, BorderSizePixel = 0, Parent = sidebar,
	})
	local tabList = inst("Frame", {
		Size = UDim2.new(1, 0, 1, -16), Position = UDim2.fromOffset(0, 8),
		BackgroundTransparency = 1, Parent = sidebar,
	})
	local tl = vList(tabList, 4)
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local content = inst("Frame", {
		Name = "Content", Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
		Position = UDim2.fromOffset(SIDEBAR_W, 0), BackgroundTransparency = 1, Parent = body,
	})
	pad(content, 12, 14, 8, 14)
	local sbar = inst("Frame", {
		Name = "StatusBar", Size = UDim2.new(1, 0, 0, STATUS_H),
		Position = UDim2.new(0, 0, 1, -STATUS_H), BackgroundColor3 = C.titlebar,
		BorderSizePixel = 0, Parent = win,
	})
	corner(sbar, 10)
	inst("Frame", {
		Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = C.titlebar, BorderSizePixel = 0, Parent = sbar,
	})
	inst("Frame", {
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border, BorderSizePixel = 0, Parent = sbar,
	})
	local statusDot = mkIcon(sbar, "circle", 10, C.gray, {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
	})
	UIState.refs.statusLbl = label(sbar, "Ready", 11, C.text, Enum.Font.Gotham, {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 32, 0.5, 0),
		Size = UDim2.new(1, -228, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd,
	})
	UIState.refs.pPct = label(sbar, "0%", 11, C.textDim, Enum.Font.GothamSemibold, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(40, 14), TextXAlignment = Enum.TextXAlignment.Right,
	})
	local pTrack = inst("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
		Size = UDim2.fromOffset(120, 4), BackgroundColor3 = C.input, BorderSizePixel = 0, Parent = sbar,
	})
	corner(pTrack, 2)
	UIState.refs.pFill = inst("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = pTrack,
	})
	corner(UIState.refs.pFill, 2)
	local tabs = {}
	local function paintTab(t, state)
		if state == "active" then
			t.btn.BackgroundTransparency = 0; t.btn.BackgroundColor3 = C.accentBg
			t.icon.ImageColor3 = C.accentHi; t.ind.Visible = true
		elseif state == "hover" then
			t.btn.BackgroundTransparency = 0; t.btn.BackgroundColor3 = C.cardHover
			t.icon.ImageColor3 = C.text; t.ind.Visible = false
		else
			t.btn.BackgroundTransparency = 1
			t.icon.ImageColor3 = C.textDim; t.ind.Visible = false
		end
	end
	local function switchTab(id)
		local target = tabs[id]
		if not target then return end
		for _, t in pairs(tabs) do
			paintTab(t, "idle")
			t.frame.Visible = false
		end
		paintTab(target, "active")
		target.frame.Visible = true
		UIState.activeTab = id
	end
	local function newPage(id, iconName, title, subtitle, scrolling)
		local fr = inst("Frame", {
			Name = "Tab_" .. id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Visible = false, Parent = content,
		})
		local hdr = inst("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = fr })
		mkIcon(hdr, iconName, 18, C.accentHi, { Position = UDim2.fromOffset(0, 1) })
		label(hdr, title, 15, C.textHi, Enum.Font.GothamBold, {
			Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 0, 20),
		})
		if subtitle then
			label(hdr, subtitle, 11, C.textDim, Enum.Font.Gotham, {
				Position = UDim2.fromOffset(28, 21), Size = UDim2.new(1, -28, 0, 14),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
		end
		local pageBody
		if scrolling then
			pageBody = inst("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46),
				BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
				ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y, Parent = fr,
			})
			vList(pageBody, 8); pad(pageBody, 0, 8, 4, 0)
		else
			pageBody = inst("Frame", {
				Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46),
				BackgroundTransparency = 1, Parent = fr,
			})
		end
		return fr, pageBody
	end
	local function makeTab(id, iconName, tooltip, order, title, subtitle, scrolling)
		local b = inst("TextButton", {
			Text = "", Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1,
			BackgroundColor3 = C.cardHover, AutoButtonColor = false, BorderSizePixel = 0,
			LayoutOrder = order, Parent = tabList,
		})
		corner(b, 8)
		local ind = inst("Frame", {
			Size = UDim2.fromOffset(3, 16), AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -8, 0.5, 0), BackgroundColor3 = C.accent,
			BorderSizePixel = 0, Visible = false, Parent = b,
		})
		corner(ind, 2)
		local icon = mkIcon(b, iconName, 18, C.textDim, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		})
		local tip = inst("Frame", {
			Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(1, 12, 0.5, -13), BackgroundColor3 = C.card,
			BorderSizePixel = 0, Visible = false, ZIndex = 10, Parent = b,
		})
		corner(tip, 6); stroke(tip, C.borderHi); pad(tip, 0, 10, 0, 10)
		label(tip, tooltip, 11, C.text, Enum.Font.GothamSemibold, {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 10,
		})
		local fr, pageBody = newPage(id, iconName, title, subtitle, scrolling)
		local t = { btn = b, ind = ind, icon = icon, frame = fr }
		tabs[id] = t
		b.MouseEnter:Connect(function()
			tip.Visible = true
			if UIState.activeTab ~= id then paintTab(t, "hover") end
		end)
		b.MouseLeave:Connect(function()
			tip.Visible = false
			if UIState.activeTab ~= id then paintTab(t, "idle") end
		end)
		b.Activated:Connect(function() switchTab(id) end)
		return pageBody
	end
	local pServices = makeTab("services", "layers",      "Services", 1, "Service Selection", "Choose which Roblox services to include in the dump.", true)
	local pRun = makeTab("run",      "play-circle", "Run",      2, "Run Dump", "Start the scan and write all reports.", true)
	local pStatus = makeTab("status",   "activity",    "Status",   3, "Status", "", true)
	pStatus.Position = UDim2.fromOffset(0, 28)
	pStatus.Size = UDim2.new(1, 0, 1, -28)
	local pFiles = pStatus
	local pSettings = makeTab("settings", "settings",    "Settings", 4, "Settings", "", true)
	pSettings.Position = UDim2.fromOffset(0, 28)
	pSettings.Size = UDim2.new(1, 0, 1, -28)
	local sep = divider(tabList, 5); sep.Size = UDim2.fromOffset(24, 1)
	local pAbout = makeTab("about",    "info",        "About",    6, "About", "Universal Roblox analysis & dump system.", true)
	do
		local svcIcons = {
			ReplicatedFirst = "download", ReplicatedStorage = "database", Players = "users",
			Workspace = "globe", PlayerGui = "monitor", Lighting = "sun", SoundService = "volume-2",
			StarterGui = "layout-dashboard", StarterPack = "backpack", StarterPlayer = "user",
			TextChatService = "message-square", Teams = "flag",
		}
		local toggles = {}
		local countLbl
		local function updateCount()
			local n = 0
			for _, s in ipairs(ALL_SERVICES) do if UIState.svcToggles[s] then n += 1 end end
			if countLbl then countLbl.Text = n .. " / " .. #ALL_SERVICES .. " selected" end
		end
		local actions = inst("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 0, Parent = pServices })
		hList(actions, 6)
		local selAll = mkButton(actions, "Select All", "secondary", UDim2.fromOffset(94, 28), nil, 0)
		local clrAll = mkButton(actions, "Clear All",  "secondary", UDim2.fromOffset(84, 28), nil, 1)
		countLbl = label(actions, "", 11, C.textDim, Enum.Font.Gotham, {
			Size = UDim2.new(1, -190, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 2,
		})
		for i, svc in ipairs(ALL_SERVICES) do
			local row = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = i, Parent = pServices,
			})
			corner(row, 6); stroke(row, C.border)
			label(row, svc, 12, C.text, Enum.Font.Gotham, {
				Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -80, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(row, UIState.svcToggles[svc], function(v)
				UIState.svcToggles[svc] = v
				updateCount()
			end)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
			toggles[svc] = tg
		end
		local function setAll(v)
			for _, s in ipairs(ALL_SERVICES) do
				UIState.svcToggles[s] = v
				toggles[s].set(v, true)
			end
			updateCount()
		end
		selAll.button.Activated:Connect(function() setAll(true) end)
		clrAll.button.Activated:Connect(function() setAll(false) end)
		updateCount()
	end
	do
		label(pRun, tostring(Config.GameName), 13, C.textHi, Enum.Font.GothamSemibold, {
			Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		label(pRun, tostring(Config.MainFolder), 10, C.textDim, Enum.Font.Code, {
			Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local run = mkButton(pRun, "Start Dump", "primary", UDim2.new(1, 0, 0, 44), "play", 1)
		run.label.TextSize = 14
		local prog = mkCard(pRun, nil, 2)
		pad(prog, 10, 12, 12, 12); vList(prog, 8)
		local ph = inst("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 0, Parent = prog })
		label(ph, "Progress", 11, C.textDim, Enum.Font.GothamSemibold, { Size = UDim2.new(0.4, 0, 1, 0) })
		UIState.refs.runPct = label(ph, "0%", 11, C.text, Enum.Font.GothamSemibold, {
			Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.fromScale(0.4, 0),
			TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local pt = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = C.input, BorderSizePixel = 0, LayoutOrder = 1, Parent = prog,
		})
		corner(pt, 3)
		UIState.refs.runBar = inst("Frame", {
			Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = pt,
		})
		corner(UIState.refs.runBar, 3)
		UIState.refs.phaseLbl = label(prog, "", 10, C.textDim, Enum.Font.Gotham, { LayoutOrder = 2 })
		UIState.refs.lastRunLbl = label(prog, "", 10, C.textDim, Enum.Font.Gotham, { LayoutOrder = 3 })
		local function setRunState(state)
			if state == "running" then
				run.setColors(C.card, C.yellow, C.border)
				run.label.Text = "Running — please wait..."
				setIcon(run.icon, "loader")
			elseif state == "done" then
				run.setColors(C.greenBg, C.green, C.green)
				run.label.Text = "Dump Completed — run again"
				setIcon(run.icon, "check-circle")
			elseif state == "error" then
				run.setColors(C.redBg, C.red, C.red)
				run.label.Text = "Failed — click to retry"
				setIcon(run.icon, "x-circle")
			else
				run.setColors(C.accent, C.textHi, C.accent)
				run.label.Text = "Start Dump"
				setIcon(run.icon, "play")
			end
		end
		local FAST_LOGO = "rbxassetid://125839047186269"
		local function showFastScreen()
			local LP2 = Players.LocalPlayer
			if not LP2 then return end
			local pg2 = LP2:FindFirstChildOfClass("PlayerGui")
			if not pg2 then return end
			local fs = Instance.new("ScreenGui")
			fs.Name = "DumpFastModeScreen"
			pcall(function() fs.AutoLocalize = false end)
			fs.DisplayOrder = 9999
			fs.IgnoreGuiInset = true
			fs.ResetOnSpawn = false
			fs.ZIndexBehavior = Enum.ZIndexBehavior.Global
			local bg = Instance.new("Frame")
			bg.Size = UDim2.fromScale(1, 1)
			bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			bg.BackgroundTransparency = 0
			bg.BorderSizePixel = 0
			bg.ZIndex = 1
			bg.Parent = fs
			local center = Instance.new("Frame")
			center.Size = UDim2.fromOffset(260, 220)
			center.AnchorPoint = Vector2.new(0.5, 0.5)
			center.Position = UDim2.fromScale(0.5, 0.5)
			center.BackgroundTransparency = 1
			center.ZIndex = 2
			center.Parent = bg
			local centerList = Instance.new("UIListLayout")
			centerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
			centerList.VerticalAlignment = Enum.VerticalAlignment.Center
			centerList.Padding = UDim.new(0, 18)
			centerList.SortOrder = Enum.SortOrder.LayoutOrder
			centerList.Parent = center
			local logo = Instance.new("ImageLabel")
			logo.Size = UDim2.fromOffset(110, 110)
			logo.BackgroundTransparency = 1
			logo.Image = FAST_LOGO
			logo.ScaleType = Enum.ScaleType.Fit
			logo.ZIndex = 3
			logo.LayoutOrder = 1
			logo.Parent = center
			local waitLbl = Instance.new("TextLabel")
			waitLbl.Size = UDim2.new(1, 0, 0, 28)
			waitLbl.BackgroundTransparency = 1
			waitLbl.Text = "Please wait..."
			waitLbl.Font = Enum.Font.GothamBold
			waitLbl.TextSize = 20
			waitLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			waitLbl.TextXAlignment = Enum.TextXAlignment.Center
			waitLbl.ZIndex = 3
			waitLbl.LayoutOrder = 2
			pcall(function() waitLbl.AutoLocalize = false end)
			waitLbl.Parent = center
			local subLbl = Instance.new("TextLabel")
			subLbl.Size = UDim2.new(1, 0, 0, 18)
			subLbl.BackgroundTransparency = 1
			subLbl.Text = "Fast Mode — do not close the game"
			subLbl.Font = Enum.Font.Gotham
			subLbl.TextSize = 13
			subLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
			subLbl.TextXAlignment = Enum.TextXAlignment.Center
			subLbl.ZIndex = 3
			subLbl.LayoutOrder = 3
			pcall(function() subLbl.AutoLocalize = false end)
			subLbl.Parent = center
			fs.Parent = pg2
			UIState.fastModeScreen = fs
		end
		local function hideFastScreen()
			if UIState.fastModeScreen and UIState.fastModeScreen.Parent then
				UIState.fastModeScreen:Destroy()
			end
			UIState.fastModeScreen = nil
		end
		run.button.Activated:Connect(function()
			if UIState.running then return end
			UIState.running = true; UIState.finished = false
			setRunState("running")
			local sel = {}
			for _, s in ipairs(ALL_SERVICES) do
				if UIState.svcToggles[s] then sel[#sel + 1] = s end
			end
			Config.ServiceList = #sel > 0 and sel or { "ReplicatedStorage" }
			switchTab("status")
			if Config.FastMode then showFastScreen() end
			task.spawn(function()
				local ok, err = pcall(main)
				UIState.running = false
				if Config.FastMode then hideFastScreen() end
				if ok then
					UIState.finished = true
					setRunState("done")
					UIState.refs.lastRunLbl.Text = "Last run: " .. os.date("%H:%M:%S")
					setStatus("Done — " .. Config.MainFolder, C.green)
					setProgress(100, "Complete")
					task.wait(2)
					if UIState.activeTab == "status" then switchTab("files") end
				else
					UIState.finished = false
					setRunState("error")
					setStatus("Error: " .. tostring(err), C.red)
					uiLog("RUNTIME ERROR: " .. tostring(err), C.logErr)
				end
			end)
		end)
	end
	local statusLeft, statusRight
	do
		local workspace = inst("Frame", {
			Name = "StatusWorkspace", Size = UDim2.new(1, 0, 0, 630),
			BackgroundTransparency = 1, LayoutOrder = 1, Parent = pStatus,
		})
		statusLeft = inst("Frame", {
			Name = "StatusLeft", Size = UDim2.new(0.5, -5, 1, 0),
			BackgroundTransparency = 1, Parent = workspace,
		})
		statusRight = inst("Frame", {
			Name = "StatusFilesRight", Size = UDim2.new(0.5, -5, 1, 0),
			Position = UDim2.new(0.5, 5, 0, 0), BackgroundTransparency = 1, Parent = workspace,
		})
		vList(statusLeft, 8)
		vList(statusRight, 8)
		local grid = inst("Frame", { Size = UDim2.new(1, 0, 0, 96), BackgroundTransparency = 1, LayoutOrder = 1, Parent = statusLeft })
		inst("UIGridLayout", {
			CellSize = UDim2.new(0.5, -4, 0, 44), CellPadding = UDim2.fromOffset(8, 6),
			SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid,
		})
		local function statCard(text, refKey, lo)
			local c = inst("Frame", { BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = lo, Parent = grid })
			corner(c, 7); stroke(c, C.border)
			label(c, text, 10, C.textDim, Enum.Font.Gotham, { Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, 13) })
			UIState.refs[refKey] = label(c, "0", 15, C.textHi, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(10, 19), Size = UDim2.new(1, -20, 0, 19),
			})
		end
		statCard("Total", "mTotal", 1)
		statCard("Success", "mOk", 2)
		statCard("Failed", "mFail", 3)
		statCard("Remotes", "mRemotes", 4)
		local logCard = inst("Frame", { Size = UDim2.new(1, 0, 0, 154), BackgroundColor3 = C.input, BorderSizePixel = 0, LayoutOrder = 2, Parent = statusLeft })
		corner(logCard, 7); stroke(logCard, C.border); pad(logCard, 8, 8, 8, 8); vList(logCard, 6)
		label(logCard, "Activity", 11, C.textHi, Enum.Font.GothamSemibold, { Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 0 })
		local ls = inst("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -22), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = logCard,
		})
		pad(ls, 2, 2, 2, 2); vList(ls, 1)
		UIState.refs.liveScroll = ls
		for _, e in ipairs(UIState.logLines) do pushLine(ls, e.text, e.color) end
		local editor = inst("Frame", { Size = UDim2.new(1, 0, 0, 300), BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 3, Parent = statusLeft })
		corner(editor, 7); stroke(editor, C.border); pad(editor, 8, 8, 8, 8); vList(editor, 6)
		label(editor, "File editor", 12, C.textHi, Enum.Font.GothamSemibold, { Size = UDim2.new(1, 0, 0, 17), LayoutOrder = 0 })
		local pathBox = inst("TextBox", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.input, BorderSizePixel = 0,
			Text = "", PlaceholderText = "File name (inside dump folder)", TextColor3 = C.text,
			PlaceholderColor3 = C.textDim, Font = Enum.Font.Gotham, TextSize = 10,
			ClearTextOnFocus = false, LayoutOrder = 1, Parent = editor,
		})
		corner(pathBox, 5); pad(pathBox, 0, 8, 0, 8)
		local actions = inst("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 2, Parent = editor })
		hList(actions, 6)
		local loadBtn = mkButton(actions, "Load", "secondary", UDim2.fromOffset(76, 28), nil, 1)
		local saveBtn = mkButton(actions, "Save", "primary", UDim2.fromOffset(76, 28), nil, 2)
		local editorText = inst("TextBox", {
			Size = UDim2.new(1, 0, 0, 178), BackgroundColor3 = C.input, BorderSizePixel = 0,
			Text = "", PlaceholderText = "File contents...", TextColor3 = C.text,
			PlaceholderColor3 = C.textDim, Font = Enum.Font.Code, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = false, MultiLine = true, ClearTextOnFocus = false,
			LayoutOrder = 3, Parent = editor,
		})
		corner(editorText, 5); pad(editorText, 7, 7, 7, 7)
		local editorStatus = label(editor, "Choose a file from the dump folder, then Load to edit it.", 9, C.textDim, Enum.Font.Gotham, {
			Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 4, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local function resolveEditorPath()
			local name = tostring(pathBox.Text):gsub("^%s+", ""):gsub("%s+$", "")
			if name == "" then return nil end
			if name:find("[/\\]") then return name end
			return Config.MainFolder .. "/" .. name
		end
		loadBtn.button.Activated:Connect(function()
			local path = resolveEditorPath()
			if not path then editorStatus.Text = "Enter a file name first"; return end
			if not has("readfile") then editorStatus.Text = "readfile is unavailable"; return end
			local ok, content = pcall(Env.readfile, path)
			if not ok or type(content) ~= "string" then editorStatus.Text = "Could not read file"; return end
			editorText.Text = content
			editorStatus.Text = "Loaded " .. (path:match("([^/\\]+)$") or path)
		end)
		saveBtn.button.Activated:Connect(function()
			local path = resolveEditorPath()
			if not path then editorStatus.Text = "Enter a file name first"; return end
			if not has("writefile") then editorStatus.Text = "writefile is unavailable"; return end
			local ok = pcall(Env.writefile, path, editorText.Text)
			editorStatus.Text = ok and "Saved successfully" or "Could not save file"
		end)
	end
	do
		label(statusRight, "Downloaded files", 12, C.textHi, Enum.Font.GothamSemibold, {
			Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0,
		})
		local top = inst("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1, Parent = statusRight })
		hList(top, 6)
		local refreshBtn = mkButton(top, "Refresh", "secondary", UDim2.fromOffset(92, 28), "refresh-cw", 0)
		local countLbl = label(top, "0 files", 10, C.textDim, Enum.Font.Gotham, {
			Size = UDim2.new(1, -100, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 1,
		})
		local listPanel = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 112), BackgroundColor3 = C.input,
			BorderSizePixel = 0, LayoutOrder = 2, Parent = statusRight,
		})
		corner(listPanel, 8); stroke(listPanel, C.border)
		local fileScroll = inst("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = listPanel,
		})
		pad(fileScroll, 6, 6, 6, 6); vList(fileScroll, 3)
		local selectedPath, selectedName
		local previewCard = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 3, Parent = statusRight,
		})
		corner(previewCard, 8); stroke(previewCard, C.border); pad(previewCard, 8, 8, 8, 8); vList(previewCard, 6)
		local previewTitle = label(previewCard, "Select a file", 11, C.textHi, Enum.Font.GothamSemibold, {
			Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0,
		})
		local renameRow = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
			ClipsDescendants = true, LayoutOrder = 1, Parent = previewCard,
		})
		hList(renameRow, 5)
		local nameBox = inst("TextBox", {
			Size = UDim2.new(1, -96, 1, 0), BackgroundColor3 = C.input, BorderSizePixel = 0,
			ClipsDescendants = true, Text = "", PlaceholderText = "New file name",
			TextColor3 = C.text, PlaceholderColor3 = C.textDim,
			Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = false,
			ClearTextOnFocus = false, LayoutOrder = 0, Parent = renameRow,
		})
		corner(nameBox, 6); pad(nameBox, 0, 8, 0, 8)
		local renameBtn = mkButton(renameRow, "Rename", "secondary", UDim2.fromOffset(82, 30), "pencil", 1)
		local previewScroll = inst("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.input, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = previewCard,
		})
		corner(previewScroll, 6); pad(previewScroll, 8, 8, 8, 8)
		local codeLabel = inst("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Double-click a file to preview its contents.",
			TextColor3 = C.textDim, TextSize = 10, Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = false, RichText = true, Parent = previewScroll,
		})
		local function escapeRich(t)
			return tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
		end
		local function highlightLua(source)
			source = tostring(source or "")
			if #source > 60000 then source = source:sub(1, 60000) .. "\n\n-- preview truncated (60 KB limit)" end
			local out, i, n = {}, 1, #source
			local keywords = {
				["and"]=true, ["break"]=true, ["do"]=true, ["else"]=true, ["elseif"]=true,
				["end"]=true, ["false"]=true, ["for"]=true, ["function"]=true, ["if"]=true,
				["in"]=true, ["local"]=true, ["nil"]=true, ["not"]=true, ["or"]=true,
				["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true, ["until"]=true, ["while"]=true,
			}
			while i <= n do
				local c = source:sub(i, i)
				local chunk, color
				if source:sub(i, i + 1) == "--" then
					local e = source:find("\n", i, true) or (n + 1)
					chunk, color = source:sub(i, e - 1), "#6A9955"
					i = e
				elseif c == '"' or c == "'" then
					local q, j = c, i + 1
					while j <= n do
						local x = source:sub(j, j)
						if x == "\\" then j = j + 2
						elseif x == q then j = j + 1; break
						else j = j + 1 end
					end
					chunk, color = source:sub(i, j - 1), "#CE9178"; i = j
				elseif c:match("[%a_]") then
					local j = i + 1
					while j <= n and source:sub(j, j):match("[%w_]") do j = j + 1 end
					chunk = source:sub(i, j - 1)
					color = keywords[chunk] and "#569CD6" or "#DCDCAA"
					i = j
				elseif c:match("%d") then
					local j = i + 1
					while j <= n and source:sub(j, j):match("[%w%.]") do j = j + 1 end
					chunk, color = source:sub(i, j - 1), "#B5CEA8"; i = j
				else
					chunk, color = c, "#D4D4D4"; i = i + 1
				end
				out[#out + 1] = '<font color="' .. color .. '">' .. escapeRich(chunk) .. '</font>'
			end
			return table.concat(out)
		end
		local function showFile(path)
			if not has("readfile") then
				codeLabel.Text = "readfile is unavailable in this executor."
				return
			end
			local ok, content = pcall(Env.readfile, path)
			if not ok or type(content) ~= "string" then
				codeLabel.Text = "Unable to read this file."
				return
			end
			selectedPath = path
			selectedName = path:match("([^/\\]+)$") or path
			previewTitle.Text = selectedName .. "  ·  " .. tostring(#content) .. " bytes"
			nameBox.Text = selectedName
			local ext = selectedName:match("%.([^%.]+)$")
			if ext and (ext:lower() == "lua" or ext:lower() == "luau") then
				codeLabel.Text = highlightLua(content)
			else
				codeLabel.Text = escapeRich(content:sub(1, 60000))
			end
			codeLabel.Size = UDim2.new(1, 0, 0, 0)
			previewScroll.CanvasPosition = Vector2.new(0, 0)
		end
		local function refreshFiles()
			for _, child in ipairs(fileScroll:GetChildren()) do
				if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
			end
			local found = {}
			if has("listfiles") then
				local ok, paths = pcall(Env.listfiles, Config.MainFolder)
				if ok and type(paths) == "table" then
					for _, path in ipairs(paths) do
						if type(path) == "string" and path:sub(1, #Config.MainFolder) == Config.MainFolder then
							local isDir = false
							if has("isfolder") then pcall(function() isDir = Env.isfolder(path) end) end
							if not isDir then found[#found + 1] = path end
						end
					end
				end
			end
			table.sort(found, function(a, b) return a:lower() < b:lower() end)
			countLbl.Text = tostring(#found) .. " files"
			for i, path in ipairs(found) do
				local filename = path:match("([^/\\]+)$") or path
				local b = inst("TextButton", {
					Size = UDim2.new(1, -4, 0, 27), BackgroundColor3 = C.card,
					BorderSizePixel = 0, AutoButtonColor = false, Text = "",
					LayoutOrder = i, Parent = fileScroll,
				})
				corner(b, 5)
				label(b, filename, 10, C.text, Enum.Font.Code, {
					Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				})
				local lastClick = 0
				b.Activated:Connect(function()
					local now = os.clock()
					if now - lastClick <= 0.35 then
						showFile(path)
					else
						selectedPath = path
						selectedName = filename
						previewTitle.Text = filename .. "  ·  double-click to preview"
						nameBox.Text = filename
					end
					lastClick = now
				end)
			end
			if #found == 0 then
				label(fileScroll, has("listfiles") and "No files found yet." or "This executor does not provide listfiles.", 10, C.textDim, Enum.Font.Gotham, {
					Size = UDim2.new(1, -8, 0, 24), LayoutOrder = 1,
				})
			end
		end
		renameBtn.button.Activated:Connect(function()
			if not selectedPath or not selectedName then return end
			local newName = tostring(nameBox.Text):gsub("^%s+", ""):gsub("%s+$", "")
			newName = sanitizeName(newName)
			if newName == "" or newName == "_" then return end
			local folder = selectedPath:match("^(.*[/\\])") or (Config.MainFolder .. "/")
			local newPath = folder .. newName
			if newPath == selectedPath then return end
			if not has("readfile") or not has("writefile") or not has("delfile") then
				previewTitle.Text = "Rename unavailable: readfile, writefile and delfile are required"
				return
			end
			local okRead, content = pcall(Env.readfile, selectedPath)
			if not okRead then previewTitle.Text = "Could not read selected file"; return end
			if fileExists(newPath) then previewTitle.Text = "A file with that name already exists"; return end
			local okWrite = pcall(Env.writefile, newPath, content)
			if not okWrite then previewTitle.Text = "Could not save renamed file"; return end
			local okDelete = pcall(Env.delfile, selectedPath)
			if not okDelete then
				pcall(Env.delfile, newPath)
				previewTitle.Text = "Could not remove the original file; rename cancelled"
				return
			end
			selectedPath, selectedName = newPath, newName
			previewTitle.Text = newName .. "  ·  renamed"
			refreshFiles()
			showFile(newPath)
		end)
		refreshBtn.button.Activated:Connect(refreshFiles)
		refreshFiles()
	end
	do
		local order = 0
		local function settingRow(iconName, text)
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, text, 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -88, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			return r
		end
		local function toggleRow(iconName, text, initVal, onChange)
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, text, 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -88, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(r, initVal, onChange)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
			return r, tg
		end
		local function warnLabel(r, text, width)
			label(r, text, 9, Color3.fromRGB(220, 160, 60), Enum.Font.Gotham, {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0),
				Size = UDim2.new(0, width, 0, 12), TextXAlignment = Enum.TextXAlignment.Right,
			})
		end
		do
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, "Fast Mode", 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -88, 0, 18),
			})
			label(r, "Recommend this", 9, Color3.fromRGB(100, 200, 120), Enum.Font.Gotham, {
				Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -88, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(r, Config.FastMode or false, function(v)
				Config.FastMode = v
			end)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
		end
		do
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, "Fast Save", 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -88, 0, 18),
			})
			label(r, "Not Recommend", 9, Color3.fromRGB(220, 90, 90), Enum.Font.Gotham, {
				Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -88, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(r, false, function(v)
				Config.FastSave = v
			end)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
		end
		toggleRow("radio", "Enable Live Hooks", Config.EnableLiveHooks, function(v) Config.EnableLiveHooks = v end)
		do
			local inSupported = has("hookfunction") and has("getcallbackvalue")
			local r = toggleRow("arrow-down-left", "Incoming Hooks", Config.EnableIncomingHooks or false, function(v)
				if not inSupported and v then
					notify("Incoming Hooks", "hookfunction ou getcallbackvalue ausente. RemoteFunction não será capturada. Apenas RemoteEvent via Connect estará disponível.", 6)
				end
				Config.EnableIncomingHooks = v
			end)
			if not inSupported then warnLabel(r, "⚠ hookfunction missing — Events only", 180) end
		end
		do
			local raknetSupported = has("hookmetamethod") or has("hookfunction")
			local r, tg
			r, tg = toggleRow("wifi", "RakNet Analysis", false, function(v)
				if not raknetSupported and v then
					notify("RakNet Analysis", "Executor não suportado (hookmetamethod/hookfunction ausente). Analysis desativada.", 5)
					tg.set(false, true)
					return
				end
				Config.EnableRakNetAnalysis = v
			end)
			if not raknetSupported then warnLabel(r, "⚠ unsupported executor", 160) end
		end
		toggleRow("sliders", "Skip Optional Executor Checks",
			ExecutorSupport.GetSetting("DisableNonEssentialChecks", false) == true,
			function(v) ExecutorSupport.SetSetting("DisableNonEssentialChecks", v) end)
		numBox(settingRow("clock", "Soak Duration (s)"),
			Config.SoakSeconds, 0, 60, function(n) Config.SoakSeconds = n end)
		numBox(settingRow("repeat", "Max Decompile Retries"),
			Config.MaxRetries, 0, 10, function(n) Config.MaxRetries = n end)
		toggleRow("shield-off", "Skip Script Content",
			Config.SkipAllScriptContent or false, function(v) Config.SkipAllScriptContent = v end)
		toggleRow("shield", "Skip Roblox Scripts",
			false, function(v) Config.SkipRobloxScripts = v end)
		numBox(settingRow("move", "UI Scale (%)"), 80, 60, 130, function(n)
			scaleObj.Scale = n / 100
			applySize(); place(posX, posY)
		end)
	end
	do
		local creditRow = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 62),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			Parent = pAbout,
		})
		hList(creditRow, 8)
		local function mkCreditBtn(parent, mainLabel, subLabel, iconName, lo)
			local card = inst("TextButton", {
				Text = "", AutoButtonColor = false,
				Size = UDim2.new(0.5, -4, 0, 62),
				BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = lo, Parent = parent,
			})
			corner(card, 10)
			local st = stroke(card, C.border)
			mkIcon(card, iconName, 18, C.textDim, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 14, 0.5, 0),
			})
			label(card, mainLabel, 13, C.textHi, Enum.Font.GothamBold, {
				Position = UDim2.new(0, 42, 0, 13),
				Size = UDim2.new(1, -50, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			label(card, subLabel, 9, C.textDim, Enum.Font.Gotham, {
				Position = UDim2.new(0, 42, 0, 34),
				Size = UDim2.new(1, -50, 0, 13),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			card.MouseEnter:Connect(function()
				tween(card, { BackgroundColor3 = C.cardHover })
				tween(st, { Color = C.borderHi })
			end)
			card.MouseLeave:Connect(function()
				tween(card, { BackgroundColor3 = C.card })
				tween(st, { Color = C.border })
			end)
			return card
		end
		local _cobaltLoaded = false
		local _infiniteYieldLoaded = false
		local cobaltBtn = mkCreditBtn(creditRow, "Cobalt Spy", "Remote event inspector", "wifi", 0)
		cobaltBtn.Activated:Connect(function()
			if _cobaltLoaded then return end
			_cobaltLoaded = true
			task.spawn(function()
				local ok, err = pcall(function()
					loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))()
				end)
				if not ok then
					_cobaltLoaded = false
					warn("[DumpExplorer] Cobalt: erro ao executar —", tostring(err))
				end
			end)
		end)
		local iyBtn = mkCreditBtn(creditRow, "Infinity Yield", "Command console", "terminal", 1)
		iyBtn.Activated:Connect(function()
			if _infiniteYieldLoaded then return end
			_infiniteYieldLoaded = true
			task.spawn(function()
				local ok, err = pcall(function()
					loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
				end)
				if not ok then
					_infiniteYieldLoaded = false
					warn("[DumpExplorer] Infinite Yield: erro ao executar —", tostring(err))
				end
			end)
		end)
	end
	local dragging, dragInput, dragStart, startX, startY = false, nil, nil, 0, 0
	dragArea.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startX, startY = posX, posY
			if t == Enum.UserInputType.Touch then dragInput = input end
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if c then c:Disconnect() end
				end
			end)
		end
	end)
	dragArea.InputChanged:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then dragInput = input end
	end)
	track(UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			place(startX + d.X, startY + d.Y)
		end
	end))
	track(UIS.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then dragging = false end
	end))
	track(screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applySize(); place(posX, posY)
	end))
	applySize()
	do
		local vs, s = viewport(), scaleObj.Scale
		local saved = posStore().__DumpExplorerPos
		local centered = false
		if type(saved) == "table" and type(saved.x) == "number" and type(saved.y) == "number" then
			local minVisible = 60
			if saved.x + curW * s > minVisible and saved.x < vs.X - minVisible
				and saved.y >= 0 and saved.y < vs.Y - 20 then
				place(saved.x, saved.y)
				centered = true
			end
		end
		if not centered then
			place((vs.X - curW * s) / 2, (vs.Y - curH * s) / 2)
		end
	end
	switchTab("services")
	local FloatingToggle = inst("TextButton", {
		Name = "FloatingToggle", Text = "", AutoButtonColor = false,
		Size = UDim2.fromOffset(46, 46), AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0,
		ZIndex = 100, Visible = true, Parent = screen,
	})
	corner(FloatingToggle, 14)
	inst("UIStroke", { Color = Color3.fromRGB(48, 48, 48), Thickness = 1.2, Transparency = 0.12, Parent = FloatingToggle })
	if LOGO_IMAGE and LOGO_IMAGE ~= "" then
		inst("ImageLabel", {
			Name = "CenteredLogo", Size = UDim2.fromOffset(34, 34),
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1, Image = LOGO_IMAGE, ScaleType = Enum.ScaleType.Fit,
			ZIndex = 101, Parent = FloatingToggle,
		})
	else
		inst("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "D",
			Font = Enum.Font.GothamBold, TextSize = 22,
			TextColor3 = Color3.fromRGB(245, 245, 245), ZIndex = 101, Parent = FloatingToggle,
		})
	end
	FloatingToggle.Activated:Connect(function()
		win.Visible = not win.Visible
	end)
	FloatingToggle.MouseEnter:Connect(function()
		tween(FloatingToggle, { Size = UDim2.fromOffset(50, 50), BackgroundColor3 = Color3.fromRGB(12, 12, 12) }, 0.12)
	end)
	FloatingToggle.MouseLeave:Connect(function()
		tween(FloatingToggle, { Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.fromRGB(0, 0, 0) }, 0.12)
	end)
	task.spawn(function()
		local lastPct = -1
		while screen and screen.Parent and not State.Cancelled do
			local R = UIState.refs
			if R.mTotal then R.mTotal.Text = tostring(State.Total) end
			if R.mOk then R.mOk.Text = tostring(State.Success) end
			if R.mFail then R.mFail.Text = tostring(State.Failed) end
			local rc = 0
			for _ in pairs(State.Remotes) do rc += 1 end
			if R.mRemotes then R.mRemotes.Text = tostring(rc) end
			local pct = math.floor(UIState.pct)
			if pct ~= lastPct then
				lastPct = pct
				local size = UDim2.fromScale(pct / 100, 1)
				tween(R.pFill, { Size = size }, 0.18)
				tween(R.runBar, { Size = size }, 0.18)
				R.pPct.Text = pct .. "%"
				R.runPct.Text = pct .. "%" .. (UIState.pctLabel ~= "" and ("  ·  " .. UIState.pctLabel) or "")
			end
			if UIState.running and State.StartTime then
				local el = tick() - State.StartTime
				local mm = math.floor(el / 60)
				local ss = math.floor(el % 60)
				local timeStr = string.format("%02d:%02d", mm, ss)
				local queueStr = (Config.FastSave and WriteQueue.pending > 0)
					and ("  ·  queue:" .. WriteQueue.pending) or ""
				R.phaseLbl.Text = "Phase: " .. UIState.phase .. "  ·  " .. timeStr .. queueStr
			elseif UIState.finished and State.StartTime then
				local el = tick() - State.StartTime
				R.phaseLbl.Text = string.format("Done in %02d:%02d", math.floor(el/60), math.floor(el%60))
			else
				R.phaseLbl.Text = ""
			end
			statusDot.ImageColor3 = UIState.running and C.yellow or (UIState.finished and C.green or C.gray)
			task.wait(0.2)
		end
	end)
	uiLog("Dump Explorer ready. Select services and press Run.", C.logOk)
	if Lucide then
		uiLog("Lucide icons loaded from " .. (tostring(lucideSource):match("//([^/]+/[^/]+)") or "source"), C.logOk)
	else
		uiLog("Lucide icons unavailable (" .. tostring(lucideError) .. "). Using text fallback.", C.logWarn)
	end
	local missing = {}
	for name in pairs(missingIcons) do missing[#missing + 1] = name end
	if #missing > 0 then
		table.sort(missing)
		uiLog("Icons using text fallback: " .. table.concat(missing, ", "), C.logWarn)
	end
	return screen
end
local _origPS = processService
local _svcTotal = #Config.ServiceList
local _svcDone = 0
local _origPO = processObject
local _poCounter = 0
processObject = function(obj, serviceName, serviceRoot)
	_poCounter += 1
	if _poCounter % 15 == 0 then
		local basePct = math.floor((_svcDone / math.max(_svcTotal, 1)) * 65) + 10
		local nextPct = math.floor(((_svcDone + 1) / math.max(_svcTotal, 1)) * 65) + 10
		local slot = nextPct - basePct
		local svcTotal = State.Total > 0 and State.Total or 1
		local intraPct = math.min((_poCounter % 500) / math.max(slot * 7, 1), 1)
		setProgress(basePct + math.floor(intraPct * slot), serviceName)
	end
	return _origPO(obj, serviceName, serviceRoot)
end
processService = function(svcName)
	_svcDone += 1
	_poCounter = 0
	UIState.phase = "scan:" .. svcName
	setStatus("Scanning " .. svcName .. "...", C.yellow)
	setProgress(math.floor(((_svcDone - 1) / math.max(_svcTotal, 1)) * 65) + 10, svcName)
	_origPS(svcName)
	setProgress(math.floor((_svcDone / math.max(_svcTotal, 1)) * 65) + 10, svcName)
end
local _origMain = main
main = function()
	_svcTotal = #Config.ServiceList; _svcDone = 0
	UIState.phase = "unc"; setProgress(0, "UNC analysis")
	setStatus("Running UNC analysis...", C.yellow)
	_origMain()
	UIState.phase = "done"; setProgress(100, "Complete")
	setStatus("Done — " .. Config.MainFolder, C.green)
end
task.spawn(function()
	local stStore = Hook.defaultStore()
	if Config.SelfTest or (stStore and stStore.__DUMP_SELFTEST == true) then
		local okS, errS = pcall(SelfTest.run)
		if not okS then warn("[DumpExplorer] SelfTest failed to run: " .. tostring(errS)) end
	end
	local okL, errL = pcall(Lifecycle.boot)
	if not okL then warn("[DumpExplorer] Lifecycle.boot failed: " .. tostring(errL)) end
	local okF, errF = pcall(createAllFolders)
	if not okF then warn("[DumpExplorer] Failed to create folders: " .. tostring(errF)) end
	local okB, errB = pcall(buildUI)
	if not okB then warn("[DumpExplorer] UI failed to build: " .. tostring(errB)) end
end)
end
