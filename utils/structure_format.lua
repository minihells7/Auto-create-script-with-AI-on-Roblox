local function structureJson(value)
	local ok, encoded = pcall(function() return HttpService:JSONEncode(value) end)
	return ok and encoded or "{}"
end
local function structureFormatAttributes(attrs)
	local lines, keys = {}, {}
	for name in pairs(attrs) do keys[#keys + 1] = name end
	table.sort(keys)
	for _, name in ipairs(keys) do
		local encoded = attrs[name]
		lines[#lines + 1] = string.format('GetAttribute(%q) -- %s: %s',
			name, encoded.type, structureReadable(encoded.value))
	end
	return lines
end
