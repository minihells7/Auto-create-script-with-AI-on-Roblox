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
