local function generateToolsInventory()
	local lines = {
		"TOOLS INVENTORY",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: All Tools found in the game with their child scripts,",
		"attributes and internal structure. 'Data' ModuleScripts contain ability tables.",
		string.rep("═", 90),
		"",
	}
	local toolCount = 0
	local seen = {}
	local function scanForTools(root, rootName)
		if not root then return end
		local ok, descendants = pcall(function() return root:GetDescendants() end)
		if not ok then return end
		for _, obj in ipairs(descendants) do
			if not seen[obj] then
				local okC, cls = pcall(function() return obj.ClassName end)
				if okC and cls == "Tool" then
					seen[obj] = true
					toolCount += 1
					local okP, fullPath = pcall(function() return obj:GetFullName() end)
					local okN, name = pcall(function() return obj.Name end)
					local okTT, tooltip = pcall(function() return obj.ToolTip end)
					lines[#lines + 1] = "TOOL    : " .. (okN and name or "?")
					lines[#lines + 1] = "PATH    : " .. (okP and fullPath or "?")
					lines[#lines + 1] = "SERVICE : " .. rootName
					if okTT and tooltip and tooltip ~= "" then
						lines[#lines + 1] = "TOOLTIP : " .. tostring(tooltip)
					end
					local okA, attrs = pcall(function() return obj:GetAttributes() end)
					if okA and attrs and next(attrs) then
						lines[#lines + 1] = "ATTRIBS :"
						for k, v in pairs(attrs) do
							lines[#lines + 1] = string.format("  %s = %s", tostring(k), tostring(v))
						end
					end
					local okCh, children = pcall(function() return obj:GetChildren() end)
					if okCh and children then
						local scripts, modules, parts, values, outros = {}, {}, {}, {}, {}
						for _, child in ipairs(children) do
							local okCC, cc = pcall(function() return child.ClassName end)
							local okCN, cn = pcall(function() return child.Name end)
							if okCC then
								local entry = string.format("%s (%s)", okCN and cn or "?", cc)
								if cc == "LocalScript" or cc == "Script" then
									scripts[#scripts + 1] = entry
								elseif cc == "ModuleScript" then
									modules[#modules + 1] = entry
									if cn == "Data" or cn == "Config" then
										lines[#lines + 1] = "  [ModuleScript '" .. cn .. "' — contains data/abilities table of the tool]"
									end
								elseif cc == "Part" or cc == "MeshPart" or cc == "SpecialMesh" then
									parts[#parts + 1] = entry
								elseif cc:find("Value$") then
									local okV, val = pcall(function() return child.Value end)
									values[#values + 1] = entry .. (okV and (" = " .. tostring(val)) or "")
								else
									outros[#outros + 1] = entry
								end
							end
						end
						if #scripts  > 0 then lines[#lines + 1] = "SCRIPTS : " .. table.concat(scripts, ", ") end
						if #modules  > 0 then lines[#lines + 1] = "MODULES : " .. table.concat(modules, ", ") end
						if #parts    > 0 then lines[#lines + 1] = "PARTS   : " .. table.concat(parts, ", ") end
						if #values   > 0 then lines[#lines + 1] = "VALUES  : " .. table.concat(values, ", ") end
						if #outros   > 0 then lines[#lines + 1] = "OTHERS  : " .. table.concat(outros, ", ") end
					end
					lines[#lines + 1] = string.rep("─", 70)
					lines[#lines + 1] = ""
				end
			end
		end
	end
	local servicesToScan = {
		{ "ReplicatedStorage", safeGetService("ReplicatedStorage") },
		{ "Workspace",         safeGetService("Workspace")         },
		{ "StarterPack",       safeGetService("StarterPack")       },
		{ "StarterGui",        safeGetService("StarterGui")        },
		{ "Players",           safeGetService("Players")           },
	}
	for _, pair in ipairs(servicesToScan) do
		scanForTools(pair[2], pair[1])
		task.wait()
	end
	lines[#lines + 1] = string.format("TOTAL TOOLS FOUND: %d", toolCount)
	writeFileSafe(Paths.ToolsInventory, table.concat(lines, "\n"))
	writeLog(string.format("TOOLS_INVENTORY.txt saved (%d tools).", toolCount))
end
