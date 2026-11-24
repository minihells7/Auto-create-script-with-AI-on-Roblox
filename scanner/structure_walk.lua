local function structureScanWorkspace()
	local ws = safeGetService("Workspace")
	if not ws then return end
	structurePrepareCounts(ws)
	local lines = {"WORKSPACE", "Generated at: " .. os.date("%Y-%m-%d %H:%M:%S"), ""}
	local function visit(parent, prefix)
		local children = structureSafe(function() return parent:GetChildren() end, {})
		table.sort(children, function(a, b)
			local an = structureSafe(function() return a.Name end, "")
			local bn = structureSafe(function() return b.Name end, "")
			if an == bn then
				return structureSafe(function() return a.ClassName end, "") <
					structureSafe(function() return b.ClassName end, "")
			end
			return an:lower() < bn:lower()
		end)
		for index, child in ipairs(children) do
			local last = index == #children
			local branch = last and "└── " or "├── "
			local continuation = last and "    " or "│   "
			local path = structureSafe(function() return child:GetFullName() end, "?")
			local attrs = structureGetAttributes(child)
			local tags = structureGetTags(child)
			lines[#lines + 1] = prefix .. branch ..
				structureSafe(function() return child.Name end, "?") ..
				"  [" .. structureSafe(function() return child.ClassName end, "?") .. "]" ..
				"  (" .. tostring(StructureState.descendantCounts[child] or 0) .. " descendants)"
			lines[#lines + 1] = prefix .. continuation .. "   Path: " .. path
			local par = structureSafe(function() return child.Parent end, nil)
			lines[#lines + 1] = prefix .. continuation .. "   Parent: " ..
				(par and structureSafe(function() return par:GetFullName() end, "?") or "Unavailable")
			if #tags > 0 then
				lines[#lines + 1] = prefix .. continuation .. "   Tags: " .. table.concat(tags, ", ")
			end
			if next(attrs) then
				lines[#lines + 1] = prefix .. continuation .. "   Attributes:"
				for _, line in ipairs(structureFormatAttributes((function()
					local out = {}
					for k,v in pairs(attrs) do out[k] = structureEncode(v) end
					return out
				end)())) do
					lines[#lines + 1] = prefix .. continuation .. "   │   " .. line
				end
			end
			if structureSafe(function() return child:IsA("Model") end, false) then
				local primary = structureSafe(function() return child.PrimaryPart end, nil)
				lines[#lines + 1] = prefix .. continuation .. "   PrimaryPart: " ..
					(primary and primary.Name or "nil / unavailable")
			end
			if structureSafe(function() return child:IsA("Humanoid") end, false) then
				lines[#lines + 1] = prefix .. continuation .. "   Health: " ..
					structureReadable(structureSafe(function() return child.Health end, "?")) ..
					" | MaxHealth: " .. structureReadable(structureSafe(function() return child.MaxHealth end, "?")) ..
					" | WalkSpeed: " .. structureReadable(structureSafe(function() return child.WalkSpeed end, "?"))
			end
			if structureSafe(function() return child:IsA("BasePart") end, false) then
				lines[#lines + 1] = prefix .. continuation .. "   Part: Size=" ..
					structureReadable(structureSafe(function() return child.Size end, "?")) ..
					" Position=" .. structureReadable(structureSafe(function() return child.Position end, "?")) ..
					" Anchored=" .. structureReadable(structureSafe(function() return child.Anchored end, "?")) ..
					" CanCollide=" .. structureReadable(structureSafe(function() return child.CanCollide end, "?"))
			end
			StructureState.processed += 1
			if StructureState.processed % StructureConfig.BatchSize == 0 then
				pcall(structureWrite, StructurePaths.Checkpoint, structureJson({
					phase="Workspace", processed=StructureState.processed,
					lastPath=path, timestamp=os.time(),
				}))
				if not Config.FastMode then task.wait(StructureConfig.YieldSeconds) end
			end
			visit(child, prefix .. continuation)
		end
	end
	visit(ws, "")
	structureWrite(StructurePaths.Workspace, table.concat(lines, "\n"))
end
local function structureScanObjectsAndRemotes()
	local roots = structureServiceRoots()
	local seen = {}
	for _, root in ipairs(roots) do structurePrepareCounts(root) end
	for _, root in ipairs(roots) do
		local descendants = structureSafe(function() return root:GetDescendants() end, {})
		for _, instance in ipairs(descendants) do
			if not seen[instance] then
				seen[instance] = true
				local ok, err = pcall(structureAddObject, instance)
				if not ok then
					StructureState.errors[#StructureState.errors + 1] =
						structureSafe(function() return instance:GetFullName() end, "?") .. " | " .. tostring(err)
				end
				local className = structureSafe(function() return instance.ClassName end, "")
				if RemoteClasses[className] then pcall(registerRemote, instance) end
				StructureState.processed += 1
				if StructureState.processed % StructureConfig.BatchSize == 0 then
					pcall(structureWrite, StructurePaths.Checkpoint, structureJson({
						phase="Objects", processed=StructureState.processed,
						lastPath=structureSafe(function() return instance:GetFullName() end, "?"),
						timestamp=os.time(),
					}))
					if not Config.FastMode then task.wait(StructureConfig.YieldSeconds) end
				end
			end
		end
		if not seen[root] then
			seen[root] = true
			pcall(structureAddObject, root)
		end
	end
end
