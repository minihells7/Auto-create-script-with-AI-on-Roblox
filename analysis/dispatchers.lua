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
