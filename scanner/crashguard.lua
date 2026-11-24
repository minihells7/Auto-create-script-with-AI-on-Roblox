local CrashGuard = { quarantine = {} }
local function crashGuardRead(path)
	if not has("isfile") or not has("readfile") then return nil end
	local okF, exists = pcall(Env.isfile, path)
	if not okF or not exists then return nil end
	local ok, c = pcall(Env.readfile, path)
	if not ok or type(c) ~= "string" or #c == 0 then return nil end
	local ok2, d = pcall(function() return HttpService:JSONDecode(c) end)
	if ok2 and type(d) == "table" then return d end
	return nil
end
function CrashGuard.persist()
	if not has("writefile") then return end
	pcall(Env.writefile, Paths.Quarantine, HttpService:JSONEncode(CrashGuard.quarantine))
end
function CrashGuard.load()
	if not Config.CrashGuard then return end
	local q = crashGuardRead(Paths.Quarantine)
	if q then CrashGuard.quarantine = q end
	local marker = crashGuardRead(Paths.CrashGuard)
	if marker and marker.status == "running" and type(marker.id) == "string" then
		CrashGuard.quarantine[marker.id] = tostring(marker.fullName or marker.id)
		CrashGuard.persist()
		writeLog("[CRASH-GUARD] A execução anterior terminou enquanto lia: " .. tostring(marker.fullName)
			.. " (" .. tostring(marker.className) .. "). Esse script será pulado.")
		if has("writefile") then
			pcall(Env.writefile, Paths.CrashGuard, HttpService:JSONEncode({ status = "idle" }))
		end
	end
end
function CrashGuard.begin(id, fullName, className)
	if not Config.CrashGuard or not has("writefile") then return end
	local ok = pcall(Env.writefile, Paths.CrashGuard, HttpService:JSONEncode({
		status = "running", id = id, fullName = fullName, className = className, time = os.time(),
	}))
end
function CrashGuard.finish()
	if not Config.CrashGuard or not has("writefile") then return end
	pcall(Env.writefile, Paths.CrashGuard, HttpService:JSONEncode({ status = "idle" }))
end
