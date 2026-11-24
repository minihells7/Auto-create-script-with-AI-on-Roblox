local function getFullPath(instance)
	local ok, path = pcall(function() return instance:GetFullName() end)
	return ok and path or tostring(instance)
end
local function serializeArgType(v)
	local t = typeof(v)
	if t == "Instance" then
		local ok, cn = pcall(function() return v.ClassName end)
		local ok2, nm = pcall(function() return v.Name end)
		return "Instance(" .. (ok and cn or "?") .. ":" .. (ok2 and nm or "?") .. ")"
	elseif t == "table" then
		local keys = 0
		for _ in pairs(v) do keys += 1 end
		return "table{" .. keys .. " keys}"
	elseif t == "function" then
		return "function"
	elseif t == "string" then
		local s = tostring(v)
		s = s:gsub("[%c]", "?")
		if #s > 40 then s = s:sub(1,37) .. "..." end
		return 'string("' .. s .. '")'
	elseif t == "buffer" then
		local length = "unknown"
		if type(buffer) == "table" and type(buffer.len) == "function" then
			local ok, n = pcall(buffer.len, v)
			if ok and type(n) == "number" then length = tostring(n) end
		end
		return "buffer(len=" .. length .. ")"
	elseif t == "number" or t == "boolean" then
		return t .. "(" .. tostring(v) .. ")"
	else
		return t
	end
end
local function serializeArgs(args)
	local parts = {}
	local n = args.n or #args
	for i = 1, math.min(n, 6) do
		parts[i] = serializeArgType(args[i])
	end
	if n > 6 then parts[#parts + 1] = "...+" .. (n - 6) end
	return "{" .. table.concat(parts, ", ") .. "}"
end
