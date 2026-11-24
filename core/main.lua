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
