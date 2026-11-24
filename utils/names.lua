local function resolveServiceRoot(name)
	if name == "PlayerGui" then
		if not LocalPlayer then return nil end
		local ok, pg = pcall(function()
			return LocalPlayer:WaitForChild("PlayerGui", 5)
		end)
		return ok and pg or nil
	end
	local ok, svc = pcall(function() return Services[name] end)
	return ok and svc or nil
end
local function sanitizeName(name)
	name = tostring(name)
	name = name:gsub('[<>:"/\\|?*%c]', "_")
	name = name:gsub("%s+", " ")
	name = name:gsub("^%s+", "")
	name = name:gsub("%.+$", "")
	name = name:gsub("%s+$", "")
	return name == "" and "_" or name
end
local function resolveGameName()
	local name
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		name = info.Name
	end
	if not name or name == "" then
		local okN, gn = pcall(function() return game.Name end)
		if okN and type(gn) == "string" and gn ~= "" and gn ~= "Game" and gn ~= "Place" then
			name = gn
		end
	end
	name = sanitizeName(name or "")
	if name == "_" or name == "" then
		name = "Place " .. tostring(game.PlaceId)
	end
	return name
end
