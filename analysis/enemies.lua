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
