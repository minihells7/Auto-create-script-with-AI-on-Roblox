local function structureSafe(fn, fallback)
	local ok, result = pcall(fn)
	if ok then return result end
	return fallback
end
local function structureClean(value)
	return tostring(value == nil and "" or value):gsub("[%c]", " ")
end
local function structureEncode(value, depth, seen)
	depth, seen = depth or 0, seen or {}
	local kind = typeof(value)
	if kind == "nil" then return {type="nil", value="nil"} end
	if kind == "Instance" then
		return {
			type = "Instance",
			name = structureSafe(function() return value.Name end, "?"),
			className = structureSafe(function() return value.ClassName end, "?"),
			path = structureSafe(function() return value:GetFullName() end, "?"),
		}
	end
	if kind == "string" or kind == "number" or kind == "boolean" then
		return {type=kind, value=value}
	end
	if kind == "Vector3" then
		return {type="Vector3", value=string.format("%.4f, %.4f, %.4f", value.X, value.Y, value.Z)}
	end
	if kind == "Vector2" then
		return {type="Vector2", value=string.format("%.4f, %.4f", value.X, value.Y)}
	end
	if kind == "CFrame" then
		return {
			type="CFrame",
			position=string.format("%.4f, %.4f, %.4f", value.X, value.Y, value.Z),
			lookVector=string.format("%.4f, %.4f, %.4f", value.LookVector.X, value.LookVector.Y, value.LookVector.Z),
			value=string.format("%.4f, %.4f, %.4f", value.X, value.Y, value.Z),
		}
	end
	if kind == "Color3" then
		return {type="Color3", value=string.format("%d, %d, %d",
			math.floor(value.R*255+0.5), math.floor(value.G*255+0.5), math.floor(value.B*255+0.5))}
	end
	if kind == "BrickColor" then
		return {type="BrickColor", value=value.Name, number=value.Number}
	end
	if kind == "UDim2" then
		return {type="UDim2", value=string.format("{%.4f, %d}, {%.4f, %d}",
			value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)}
	end
	if kind == "UDim" then
		return {type="UDim", value=string.format("%.4f, %d", value.Scale, value.Offset)}
	end
	if kind == "Rect" then
		return {type="Rect", value=string.format("%.2f, %.2f, %.2f, %.2f",
			value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)}
	end
	if kind == "NumberRange" then
		return {type="NumberRange", value=string.format("%.4f, %.4f", value.Min, value.Max)}
	end
	if kind == "NumberSequence" then
		local kps = {}
		for _, kp in ipairs(value.Keypoints) do
			kps[#kps+1] = string.format("t=%.3f v=%.3f e=%.3f", kp.Time, kp.Value, kp.Envelope)
		end
		return {type="NumberSequence", value=table.concat(kps, " | ")}
	end
	if kind == "ColorSequence" then
		local kps = {}
		for _, kp in ipairs(value.Keypoints) do
			local c = kp.Value
			kps[#kps+1] = string.format("t=%.3f rgb(%d,%d,%d)",
				kp.Time, math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
		end
		return {type="ColorSequence", value=table.concat(kps, " | ")}
	end
	if kind == "EnumItem" then
		return {type="Enum", value=tostring(value), numVal=value.Value, enumType=tostring(value.EnumType)}
	end
	if kind == "Ray" then
		local o, d = value.Origin, value.Direction
		return {type="Ray",
			origin=string.format("%.4f, %.4f, %.4f", o.X, o.Y, o.Z),
			direction=string.format("%.4f, %.4f, %.4f", d.X, d.Y, d.Z),
			value=string.format("origin(%.4f,%.4f,%.4f) dir(%.4f,%.4f,%.4f)", o.X, o.Y, o.Z, d.X, d.Y, d.Z)}
	end
	if kind == "Font" then
		return {type="Font", value=structureSafe(function() return tostring(value) end, "[Font]")}
	end
	if kind == "table" then
		if depth >= 5 then return {type="table", value="[depth limit]"} end
		if seen[value] then return {type="table", value="[circular reference]"} end
		seen[value] = true
		local result = {type="table", value={}}
		for k, v in pairs(value) do
			result.value[tostring(k)] = structureEncode(v, depth + 1, seen)
		end
		seen[value] = nil
		return result
	end
	return {type=kind, value=structureSafe(function() return tostring(value) end, "[unavailable]")}
end
local function structureReadable(value)
	local encoded = structureEncode(value)
	if encoded.type == "string" then return string.format("%q", encoded.value) end
	if encoded.type == "table" then return "[table]" end
	if encoded.type == "CFrame" then return "CFrame(" .. (encoded.position or encoded.value) .. ")" end
	if encoded.type == "Enum" then return encoded.value .. " (" .. tostring(encoded.numVal) .. ")" end
	if encoded.type == "BrickColor" then return encoded.value .. " #" .. tostring(encoded.number) end
	if encoded.type == "Instance" then return encoded.className .. " " .. encoded.name end
	return structureClean(encoded.value)
end
local function structureServiceName(instance)
	local current = instance
	while current and structureSafe(function() return current.Parent end, nil) ~= game do
		current = structureSafe(function() return current.Parent end, nil)
	end
	return current and structureSafe(function() return current.Name end, "Unavailable") or "Unavailable"
end
local function structureGetAttributes(instance)
	return structureSafe(function() return instance:GetAttributes() end, {})
end
local function structureGetTags(instance)
	if not StructureConfig.IncludeTags then return {} end
	local collection = safeGetService("CollectionService")
	return collection and structureSafe(function() return collection:GetTags(instance) end, {}) or {}
end
