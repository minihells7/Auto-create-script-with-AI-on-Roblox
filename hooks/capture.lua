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
