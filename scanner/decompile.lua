local PANIC_MARKERS = {
	"-- decompilation panicked",
	"decompilation panicked",
	"paniced",
	"panicked",
}
local function isPanicString(s)
	if type(s) ~= "string" then return false end
	local sl = s:lower()
	for _, m in ipairs(PANIC_MARKERS) do
		if sl:find(m, 1, true) then return true end
	end
	return false
end
local function buildHeader(obj, fullName, serviceName, method)
	return table.concat({
		"--[[",
		"    DUMP: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"    Service  : " .. serviceName,
		"    Path     : " .. fullName,
		"    Class    : " .. obj.ClassName,
		"    Method   : " .. tostring(method),
		"    PlaceId  : " .. tostring(game.PlaceId),
		"]]", "",
	}, "\n")
end
local function buildStub(obj, fullName, serviceName)
	local lines = {
		"--[[",
		"    STUB — decompilation unavailable",
		"    Service  : " .. serviceName,
		"    Path     : " .. fullName,
		"    Class    : " .. obj.ClassName,
		"    PlaceId  : " .. tostring(game.PlaceId),
		"    Date     : " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
		"    ANCESTRY:",
	}
	local cur = obj
	local depth = 0
	while cur and depth < 15 do
		local okN, n = pcall(function() return cur.Name end)
		local okC, c = pcall(function() return cur.ClassName end)
		table.insert(lines, "    " .. string.rep("  ", depth) .. "- " .. tostring(okN and n or "?") .. " (" .. tostring(okC and c or "?") .. ")")
		local okP, p = pcall(function() return cur.Parent end)
		if not okP or not p or p == game then break end
		cur = p
		depth += 1
	end
	local okA, attrs = pcall(function() return obj:GetAttributes() end)
	if okA and attrs and next(attrs) then
		table.insert(lines, "")
		table.insert(lines, "    ATTRIBUTES:")
		for k, v in pairs(attrs) do
			table.insert(lines, "    " .. tostring(k) .. " = " .. tostring(v))
		end
	end
	local okCh, children = pcall(function() return obj:GetChildren() end)
	if okCh and children and #children > 0 then
		table.insert(lines, "")
		table.insert(lines, "    DIRECT CHILDREN:")
		for _, child in ipairs(children) do
			local okCN, cn = pcall(function() return child.Name end)
			local okCC, cc = pcall(function() return child.ClassName end)
			table.insert(lines, "    - " .. tostring(okCN and cn or "?") .. " (" .. tostring(okCC and cc or "?") .. ")")
		end
	end
	table.insert(lines, "]]")
	return table.concat(lines, "\n")
end
local function tryClosure(obj)
	if not has("getscriptclosure") then return nil end
	local ok, cl = pcall(Env.getscriptclosure, obj)
	if not ok or type(cl) ~= "function" then return nil end
	local lines = {
		"-- SOURCE: getscriptclosure",
		"-- Executor did not decompile but exposed the closure.",
		"",
	}
	pcall(function()
		local info = debug.getinfo(cl) or {}
		if info.what then
			table.insert(lines, string.format(
				"-- what=%s | nups=%s | numparams=%s",
				info.what, tostring(info.nups), tostring(info.numparams)
			))
		end
		for i = 1, (info.nups or 0) do
			local n, v = debug.getupvalue(cl, i)
			if n then
				table.insert(lines, string.format("-- upvalue[%d] %s : %s", i, n, type(v)))
			end
		end
	end)
	return table.concat(lines, "\n")
end
local function tryBytecodeRef(obj)
	if not has("getscriptbytecode") then return nil end
	local ok, bc = pcall(Env.getscriptbytecode, obj)
	if not ok or type(bc) ~= "string" or #bc == 0 then return nil end
	return string.format(
		"-- SOURCE: getscriptbytecode\n-- Bytecode available (%d bytes) — use an external decompiler.\n",
		#bc
	)
end
local function checkBytecodeAccessible(obj)
	if not has("getscriptbytecode") then
		return nil, 0
	end
	local ok, bc = pcall(Env.getscriptbytecode, obj)
	if not ok or type(bc) ~= "string" then
		return false, 0
	end
	if #bc == 0 then
		return false, 0
	end
	return true, #bc
end
local function tryDecompile(obj, fullName, serviceName)
	if Config.SkipAllScriptContent then
		return true, buildStub(obj, fullName, serviceName), "stub_skipped", 0, "panicked"
	end
	local bytecodeOk, bytecodeSize = checkBytecodeAccessible(obj)
	if bytecodeOk == false then
		writeLog("  [SKIP] no bytecode: " .. fullName)
		if Config.WriteStubForPanics then
			return true, buildStub(obj, fullName, serviceName), "stub_no_bytecode", 1, "no_bytecode"
		end
		return false, nil, "no accessible bytecode", 0, "failed"
	end
	local maxBytes = tonumber(Config.MaxDecompileBytes) or 400000
	if bytecodeOk == true and bytecodeSize > maxBytes then
		writeLog(string.format(
			"  [SKIP] script pesado (%d bytes; limite %d): %s",
			bytecodeSize, maxBytes, fullName
		))
		local ref = string.format(
			"-- SOURCE: bytecode_ref (too large: %d bytes, skip decompile)\n",
			bytecodeSize
		)
		return true,
			buildHeader(obj, fullName, serviceName, "getscriptbytecode") .. ref,
			"getscriptbytecode", 1, "bytecode_ref"
	end
	if bytecodeOk == true and bytecodeSize > 100000 then
		local yieldMs = tonumber(Config.HeavyScriptYieldMs) or 50
		task.wait(math.max(0, yieldMs) / 1000)
	end
	local delay = Config.RetryBaseDelay
	if has("decompile") then
		for attempt = 1, Config.MaxRetries do
			local ok, source = pcall(Env.decompile, obj)
			if ok and type(source) == "string" and #source > 0 and not isPanicString(source) then
				return true, buildHeader(obj, fullName, serviceName, "decompile") .. source, "decompile", attempt, "success"
			end
			local panic = (ok and isPanicString(source)) or (not ok and isPanicString(tostring(source or "")))
			if panic then
				writeLog("  [PANIC] " .. fullName)
				break
			end
			if attempt < Config.MaxRetries then
				task.wait(delay)
				delay = delay * Config.RetryBackoffFactor
			end
		end
	end
	local cl = tryClosure(obj)
	if cl then
		return true, buildHeader(obj, fullName, serviceName, "getscriptclosure") .. cl, "getscriptclosure", 1, "closure_stub"
	end
	if bytecodeOk == true then
		local bcRef = string.format(
			"-- SOURCE: getscriptbytecode\n-- Bytecode accessible (%d bytes) — decompile failed but data exists.\n-- Use an external decompiler (luau-decompile).\n",
			bytecodeSize
		)
		return true, buildHeader(obj, fullName, serviceName, "getscriptbytecode") .. bcRef, "getscriptbytecode", 1, "bytecode_ref"
	end
	local bc = tryBytecodeRef(obj)
	if bc then
		return true, buildHeader(obj, fullName, serviceName, "getscriptbytecode") .. bc, "getscriptbytecode", 1, "bytecode_ref"
	end
	if Config.WriteStubForPanics then
		return true, buildStub(obj, fullName, serviceName), "stub", 1, "panicked"
	end
	return false, nil, "all methods failed", Config.MaxRetries, "failed"
end
local function getRelativeParts(obj, serviceRoot)
	local parts = {}
	local cur = obj
	while cur and cur ~= serviceRoot do
		table.insert(parts, 1, sanitizeName(cur.Name))
		local ok, p = pcall(function() return cur.Parent end)
		if not ok then break end
		cur = p
	end
	return parts
end
local function getOutputPath(obj, serviceName, serviceRoot)
	local parts = getRelativeParts(obj, serviceRoot)
	local nameParts = { serviceName }
	for _, p in ipairs(parts) do table.insert(nameParts, p) end
	local fileName = table.concat(nameParts, Config.NameSeparator) .. ".lua"
	local dir = Config.MainFolder
	return dir, dir .. "/" .. fileName
end
local function validateExisting(path, id)
	if not has("isfile") or not Env.isfile(path) then return false end
	local ok, c = pcall(Env.readfile, path)
	if not ok or not c or #c == 0 then return false end
	local meta = State.ObjectsMeta[id]
	if meta then
		return meta.status == "success" or meta.status == "closure_stub"
			or meta.status == "bytecode_ref" or meta.status == "panicked"
			or meta.status == "no_bytecode"
	end
	return true
end
