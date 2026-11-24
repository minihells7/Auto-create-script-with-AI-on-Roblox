local function markDispatchersInState()
	for path in pairs(State.DispatcherActions) do
		if State.Remotes[path] then
			State.Remotes[path].isDispatcher = true
			local count = 0
			for _ in pairs(State.DispatcherActions[path]) do count += 1 end
			State.Remotes[path].dispatcherActionCount = count
		end
	end
end
local function generatePlayerState()
	local LP = Players.LocalPlayer
	if not LP then
		writeLog("PLAYER_STATE: LocalPlayer inaccessible.")
		return
	end
	local lines = {
		"LOCAL PLAYER STATE",
		"Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | PlaceId: " .. tostring(game.PlaceId),
		"",
		"DESCRIPTION: Snapshot of the LocalPlayer state at the time of the dump.",
		"Includes leaderstats, ValueObjects, attributes and character state.",
		string.rep("═", 80),
		"",
	}
	local okN, lpName = pcall(function() return LP.Name end)
	local okID, lpId = pcall(function() return LP.UserId end)
	local okTm, team = pcall(function() return LP.Team and LP.Team.Name or "none" end)
	lines[#lines + 1] = "── IDENTIFICATION ────────────────────────────────────────────"
	lines[#lines + 1] = "  Name   : " .. (okN and lpName or "?")
	lines[#lines + 1] = "  UserId : " .. (okID and tostring(lpId) or "?")
	lines[#lines + 1] = "  Team   : " .. (okTm and tostring(team) or "?")
	lines[#lines + 1] = ""
	local okLS, ls = pcall(function() return LP:FindFirstChild("leaderstats") end)
	if okLS and ls then
		lines[#lines + 1] = "── LEADERSTATS ───────────────────────────────────────────────"
		local okLSC, lsChildren = pcall(function() return ls:GetChildren() end)
		if okLSC then
			for _, stat in ipairs(lsChildren) do
				local okSN, sn = pcall(function() return stat.Name end)
				local okSV, sv = pcall(function() return stat.Value end)
				local okSC, sc = pcall(function() return stat.ClassName end)
				lines[#lines + 1] = string.format("  %-20s = %-20s  (%s)",
					okSN and sn or "?", okSV and tostring(sv) or "?", okSC and sc or "?")
			end
		end
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = "── PLAYER VALUE OBJECTS ──────────────────────────────────────"
	local okLPC, lpChildren = pcall(function() return LP:GetChildren() end)
	if okLPC then
		for _, child in ipairs(lpChildren) do
			local okCC, cc = pcall(function() return child.ClassName end)
			local okCN, cn = pcall(function() return child.Name end)
			if okCC and cc:find("Value$") then
				local okV, val = pcall(function() return child.Value end)
				lines[#lines + 1] = string.format("  %-25s = %-20s  (%s)",
					okCN and cn or "?", okV and tostring(val) or "?", cc)
			end
		end
	end
	lines[#lines + 1] = ""
	local okAtt, attrs = pcall(function() return LP:GetAttributes() end)
	if okAtt and attrs and next(attrs) then
		lines[#lines + 1] = "── PLAYER ATTRIBUTES ─────────────────────────────────────────"
		for k, v in pairs(attrs) do
			lines[#lines + 1] = string.format("  %-25s = %s", tostring(k), tostring(v))
		end
		lines[#lines + 1] = ""
	end
	local okChar, char = pcall(function() return LP.Character end)
	if okChar and char then
		lines[#lines + 1] = "── CHARACTER ─────────────────────────────────────────────────"
		local okHum, hum = pcall(function() return char:FindFirstChildOfClass("Humanoid") end)
		if okHum and hum then
			local okH, hp = pcall(function() return hum.Health end)
			local okMH, mh = pcall(function() return hum.MaxHealth end)
			local okWS, ws = pcall(function() return hum.WalkSpeed end)
			local okDN, dn = pcall(function() return hum.DisplayName end)
			lines[#lines + 1] = string.format("  Health    : %s / %s",
				okH and tostring(hp) or "?", okMH and tostring(mh) or "?")
			lines[#lines + 1] = "  WalkSpeed : " .. (okWS and tostring(ws) or "?")
			if okDN and dn and dn ~= "" then
				lines[#lines + 1] = "  Display   : " .. dn
			end
		end
		local okCA, cAttrs = pcall(function() return char:GetAttributes() end)
		if okCA and cAttrs and next(cAttrs) then
			lines[#lines + 1] = "  Character Attributes:"
			for k, v in pairs(cAttrs) do
				lines[#lines + 1] = string.format("    %-20s = %s", tostring(k), tostring(v))
			end
		end
		local okCCh, cChildren = pcall(function() return char:GetChildren() end)
		if okCCh then
			local equipped = {}
			for _, item in ipairs(cChildren) do
				local okIC, ic = pcall(function() return item.ClassName end)
				if okIC and ic == "Tool" then
					local okIN, iname = pcall(function() return item.Name end)
					equipped[#equipped + 1] = okIN and iname or "?"
				end
			end
			if #equipped > 0 then
				lines[#lines + 1] = "  Equipped Tools: " .. table.concat(equipped, ", ")
			end
		end
		lines[#lines + 1] = ""
	end
	local okBP, bp = pcall(function() return LP:FindFirstChildOfClass("Backpack") end)
	if okBP and bp then
		lines[#lines + 1] = "── BACKPACK ──────────────────────────────────────────────────"
		local okBPC, bpChildren = pcall(function() return bp:GetChildren() end)
		if okBPC then
			if #bpChildren == 0 then
				lines[#lines + 1] = "  (empty)"
			else
				for _, item in ipairs(bpChildren) do
					local okIN, iname = pcall(function() return item.Name end)
					local okIC, ic = pcall(function() return item.ClassName end)
					lines[#lines + 1] = string.format("  - %s (%s)", okIN and iname or "?", okIC and ic or "?")
				end
			end
		end
		lines[#lines + 1] = ""
	end
	writeFileSafe(Paths.PlayerState, table.concat(lines, "\n"))
	writeLog("PLAYER_STATE.txt saved.")
end
