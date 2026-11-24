local ExecutorSupport = (function()
	local Module = { Name = "Unknown" }
	do
		local ok, name = pcall(identifyexecutor)
		if ok and type(name) == "string" and name ~= "" then Module.Name = name end
	end
	local SETTINGS_PATH = Config.BaseFolder .. "/Settings.json"
	local function ReadSettings()
		if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return {} end
		local ok, data = pcall(function()
			if not isfile(SETTINGS_PATH) then return {} end
			return HttpService:JSONDecode(readfile(SETTINGS_PATH))
		end)
		return (ok and type(data) == "table") and data or {}
	end
	function Module.SetSetting(key, value)
		if typeof(writefile) ~= "function" then return false end
		local data = ReadSettings()
		data[key] = value
		return pcall(function()
			if typeof(isfolder) == "function" and typeof(makefolder) == "function"
				and not isfolder(Config.BaseFolder) then
				makefolder(Config.BaseFolder)
			end
			writefile(SETTINGS_PATH, HttpService:JSONEncode(data))
		end)
	end
	function Module.GetSetting(key, default)
		local v = ReadSettings()[key]
		if v == nil then return default end
		return v
	end
	function Module.GetSupport() return "N/A" end
	return Module
end)()
