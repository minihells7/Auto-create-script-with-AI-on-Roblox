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
