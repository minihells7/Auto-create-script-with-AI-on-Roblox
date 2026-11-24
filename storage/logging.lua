local flushLog
local function writeLog(msg)
	local line = string.format("[%s] %s", os.date("%H:%M:%S"), msg)
	print("[Dump] " .. line)
	table.insert(State.LogBuffer, line)
	if #State.LogBuffer >= Config.LogFlushEvery then
		flushLog()
	end
end
flushLog = function()
	if #State.LogBuffer == 0 then return end
	if has("writefile") then
		pcall(function()
			local chunk = table.concat(State.LogBuffer, "\n") .. "\n"
			if typeof(appendfile) == "function" and has("isfile") and Env.isfile(Paths.MainLog) then
				appendfile(Paths.MainLog, chunk)
			else
				local existing = ""
				if has("isfile") and Env.isfile(Paths.MainLog) then
					local ok, c = pcall(Env.readfile, Paths.MainLog)
					if ok and c then existing = c end
				end
				Env.writefile(Paths.MainLog, existing .. chunk)
			end
		end)
	end
	State.LogBuffer = {}
end
