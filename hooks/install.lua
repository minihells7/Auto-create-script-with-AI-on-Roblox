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
