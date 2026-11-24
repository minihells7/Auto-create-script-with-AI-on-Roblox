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
