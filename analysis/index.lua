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
