local function createAllFolders()
	local dirs = {
		Config.BaseFolder,
		Config.MainFolder,
		Config.MainFolder .. "/Metadata",
		Config.MainFolder .. "/Logs",
		Paths.HookScripts,
	}
	for _, d in ipairs(dirs) do createFolderRecursive(d) end
end
local function loadCheckpoint()
	if has("isfile") and Env.isfile(Paths.Progress) then
		local ok, c = pcall(Env.readfile, Paths.Progress)
		if ok and c and #c > 0 then
			local ok2, d = pcall(function() return HttpService:JSONDecode(c) end)
			if ok2 and type(d) == "table" then State.Checkpoint = d end
		end
	end
	if has("isfile") and Env.isfile(Paths.Metadata) then
		local ok, c = pcall(Env.readfile, Paths.Metadata)
		if ok and c and #c > 0 then
			local ok2, d = pcall(function() return HttpService:JSONDecode(c) end)
			if ok2 and type(d) == "table" then State.ObjectsMeta = d end
		end
	end
end
local function saveCheckpoint()
	pcall(function()
		Env.writefile(Paths.Progress, HttpService:JSONEncode(State.Checkpoint))
	end)
end
local function saveMetadata()
	pcall(function()
		if not Config.FastMode then
			local n = 0
			for _ in pairs(State.ObjectsMeta) do n += 1; if n > 300 then break end end
			if n > 300 then task.wait() end
		end
		Env.writefile(Paths.Metadata, HttpService:JSONEncode(State.ObjectsMeta))
	end)
end
