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
