local function classifyScript(fullName, className)
	local fn = fullName:lower()
	if fn:find("playergui") or fn:find("screengui") then return "[UI      ]"
	elseif fn:find("effect") or fn:find("particle") or fn:find("vfx") then return "[EFFECT  ]"
	elseif fn:find("module") or className == "ModuleScript" then return "[MODULE  ]"
	elseif fn:find("remotes") or fn:find("remote") then return "[REMOTE  ]"
	elseif fn:find("starterpack") or fn:find("startergui") or fn:find("starterplayer") then return "[STARTER ]"
	elseif fn:find("serverscriptservice") or fn:find("serverscript") then return "[SERVER  ]"
	elseif fn:find("replicatedfirst") then return "[FIRST   ]"
	elseif fn:find("soundservice") or fn:find("sound") then return "[SOUND   ]"
	elseif fn:find("lighting") then return "[LIGHT   ]"
	elseif fn:find("workspace") then return "[WORLD   ]"
	elseif className == "LocalScript" then return "[LOCAL   ]"
	elseif className == "Script" then return "[SCRIPT  ]"
	else return "[?       ]" end
end
local function generateModuleDependencies()
	if not has("isfile") or not has("readfile") then
		writeLog("MODULE_DEPENDENCIES: readfile unavailable, skipping.")
		return
	end
	if not has("isfolder") then
		writeLog("MODULE_DEPENDENCIES: isfolder unavailable, skipping.")
		return
	end
	local folder = Config.MainFolder
	local okLF, files = pcall(function()
		if typeof(listfiles) == "function" then
			return listfiles(folder)
		end
		return nil
	end)
	local luaFiles = {}
	if okLF and files and type(files) == "table" then
		for _, f in ipairs(files) do
			if type(f) == "string" and f:sub(-4) == ".lua" then
				luaFiles[#luaFiles + 1] = f
			end
		end
	end
	if #luaFiles == 0 then
		writeLog("MODULE_DEPENDENCIES: listfiles unavailable or no .lua files saved yet — skipping.")
		return
	end
	local lines = {
		"MODULE DEPENDENCY GRAPH",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: require() calls found in the decompiled scripts.",
		"Makes it possible to understand which modules depend on which.",
		string.rep("═", 80),
		"",
	}
	local depGraph = {}
	local totalRequires = 0
	for _, filePath in ipairs(luaFiles) do
		local okR, content = pcall(Env.readfile, filePath)
		if okR and type(content) == "string" and #content > 0 then
			local deps = {}
			for reqArg in content:gmatch("require%s*%(([^%)]+)%)") do
				reqArg = reqArg:gsub("%s+", "")
				if reqArg ~= "" then
					deps[#deps + 1] = reqArg
					totalRequires += 1
				end
			end
			if #deps > 0 then
				local shortName = filePath:match("[^/]+$") or filePath
				depGraph[shortName] = deps
			end
		end
	end
	if next(depGraph) then
		local sortedScripts = {}
		for name in pairs(depGraph) do sortedScripts[#sortedScripts + 1] = name end
		table.sort(sortedScripts)
		for _, scriptName in ipairs(sortedScripts) do
			lines[#lines + 1] = "SCRIPT: " .. scriptName
			for _, dep in ipairs(depGraph[scriptName]) do
				lines[#lines + 1] = "  require(" .. dep .. ")"
			end
			lines[#lines + 1] = ""
		end
		lines[#lines + 1] = string.format("Total scripts with require: %d | Total calls: %d",
			#sortedScripts, totalRequires)
	else
		lines[#lines + 1] = "(No require() found in the saved scripts)"
	end
	writeFileSafe(Paths.ModuleDeps, table.concat(lines, "\n"))
	writeLog(string.format("MODULE_DEPENDENCIES.txt saved (%d requires).", totalRequires))
end
