local RobloxScriptFilter = {}
do
	local cache = setmetatable({}, { __mode = "k" })
	local PLAYERSCRIPTS_PARENTS = { PlayerScripts = true, StarterPlayerScripts = true, StarterCharacterScripts = true }
	local PLAYERSCRIPTS_NAMES = {
		PlayerModule = true, RbxCharacterSounds = true, PlayerScriptsLoader = true,
		ChatScript = true, BubbleChat = true, ControlScript = true, CameraScript = true,
	}
	local CHAT_NAMES = {
		ChatScript = true, ChatModules = true, ChatServiceRunner = true,
		BubbleChat = true, ChatMain = true, ClientChatModules = true,
	}
	local roots = {}
	for _, name in ipairs({ "CoreGui", "CorePackages", "RobloxReplicatedStorage" }) do
		local svc = safeGetService(name)
		if svc then roots[#roots + 1] = svc end
	end
	local function prop(inst, key)
		local ok, v = pcall(function() return inst[key] end)
		if ok then return v end
		return nil
	end
	local function ownedNode(node, parent)
		local name = prop(node, "Name")
		if type(name) ~= "string" then return false end
		for _, extra in ipairs(Config.RobloxScriptExtraNames or {}) do
			if name == extra then return true end
		end
		local pcls = parent and prop(parent, "ClassName") or nil
		if PLAYERSCRIPTS_PARENTS[pcls] and (PLAYERSCRIPTS_NAMES[name] or name:sub(1, 3) == "Rbx") then
			return true
		end
		if pcls == "Chat" and CHAT_NAMES[name] then return true end
		if name == "Animate" and prop(node, "ClassName") == "LocalScript" then
			local emote = node:FindFirstChild("PlayEmote")
			if emote and emote:IsA("BindableFunction") then return true end
		end
		return false
	end
	function RobloxScriptFilter.isRoblox(obj)
		if not Config.SkipRobloxScripts then return false end
		local cached = cache[obj]
		if cached ~= nil then return cached end
		local result = false
		pcall(function()
			for _, root in ipairs(roots) do
				if obj:IsDescendantOf(root) then result = true; return end
			end
			local node, depth = obj, 0
			while node and node ~= game and depth < 64 do
				local parent = node.Parent
				if ownedNode(node, parent) then result = true; return end
				node = parent
				depth += 1
			end
		end)
		cache[obj] = result
		return result
	end
end
local function isRobloxScript(obj)
	return RobloxScriptFilter.isRoblox(obj)
end
