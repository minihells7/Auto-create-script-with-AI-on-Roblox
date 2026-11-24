do
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local TITLE_H, STATUS_H, SIDEBAR_W = 40, 32, 52
local MAX_LOG = 300
local Lucide, lucideError, lucideSource
do
	local SOURCES = {
		"https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua",
		"https://github.com/latte-soft/lucide-roblox/releases/download/0.1.3/lucide-roblox.luau",
		"https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau",
	}
	local function fetch(url)
		local ok, body = pcall(function() return game:HttpGet(url, true) end)
		if ok and type(body) == "string" and #body > 0 then return body end
		local req = (syn and syn.request) or http_request or request
		if type(req) == "function" then
			local ok2, res = pcall(req, { Url = url, Method = "GET" })
			if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
				return res.Body
			end
		end
		return nil, tostring(body)
	end
	for _, url in ipairs(SOURCES) do
		for attempt = 1, 2 do
			local body, ferr = fetch(url)
			if body then
				local ok, lib = pcall(function() return loadstring(body)() end)
				if ok and type(lib) == "table" and type(lib.GetAsset) == "function" then
					Lucide = lib
					lucideSource = url
					break
				end
				lucideError = "loadstring/module error: " .. tostring(lib)
			else
				lucideError = "download failed: " .. tostring(ferr)
			end
			task.wait(0.3)
		end
		if Lucide then break end
	end
	if not Lucide then warn("[DumpExplorer] Lucide failed to load: " .. tostring(lucideError)) end
end
local C = {
	window = Color3.fromRGB(23, 23, 23),
	titlebar = Color3.fromRGB(36, 36, 36),
	sidebar = Color3.fromRGB(28, 28, 28),
	card = Color3.fromRGB(28, 28, 28),
	cardHover = Color3.fromRGB(32, 32, 32),
	input = Color3.fromRGB(21, 21, 21),
	border = Color3.fromRGB(36, 36, 36),
	borderHi = Color3.fromRGB(75, 75, 75),
	accent = Color3.fromRGB(78, 124, 214),
	accentHi = Color3.fromRGB(212, 212, 212),
	accentBg = Color3.fromRGB(34, 34, 34),
	green = Color3.fromRGB(86, 190, 140),
	greenBg = Color3.fromRGB(21, 40, 33),
	red = Color3.fromRGB(226, 105, 112),
	redBg = Color3.fromRGB(48, 25, 28),
	yellow = Color3.fromRGB(220, 176, 80),
	blue = Color3.fromRGB(104, 152, 240),
	gray = Color3.fromRGB(104, 104, 104),
	textHi = Color3.fromRGB(254, 254, 254),
	text = Color3.fromRGB(200, 200, 200),
	textDim = Color3.fromRGB(120, 120, 120),
	scroll = Color3.fromRGB(75, 75, 75),
	logInfo = Color3.fromRGB(140, 140, 140),
	logOk = Color3.fromRGB(86, 190, 140),
	logWarn = Color3.fromRGB(220, 176, 80),
	logErr = Color3.fromRGB(226, 105, 112),
}
local UIState = {
	activeTab = "services",
	running = false,
	finished = false,
	logLines = {},
	phase = "idle",
	pct = 0,
	pctLabel = "",
	svcToggles = {},
	refs = {},
	statusText = "Ready",
}
local ALL_SERVICES = {
	"ReplicatedFirst", "ReplicatedStorage", "Players",
	"Workspace", "PlayerGui", "Lighting", "SoundService",
	"StarterGui", "StarterPack", "StarterPlayer", "TextChatService", "Teams",
}
for _, s in ipairs(ALL_SERVICES) do
	UIState.svcToggles[s] = false
	for _, d in ipairs(Config.ServiceList) do
		if d == s then UIState.svcToggles[s] = true; break end
	end
end
local function inst(cls, props)
	local i = Instance.new(cls)
	pcall(function() i.AutoLocalize = false end)
	for k, v in pairs(props) do pcall(function() i[k] = v end) end
	return i
end
local function corner(p, r)
	return inst("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p })
end
local function pad(p, t, r, b, l)
	return inst("UIPadding", {
		PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0),
		Parent = p,
	})
end
local function stroke(p, col, th)
	return inst("UIStroke", {
		Color = col or C.border, Thickness = th or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p,
	})
end
local function vList(p, gap)
	return inst("UIListLayout", {
		Padding = UDim.new(0, gap or 6), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical, Parent = p,
	})
end
local function hList(p, gap)
	return inst("UIListLayout", {
		Padding = UDim.new(0, gap or 6), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = p,
	})
end
local function tween(o, props, t)
	pcall(function()
		TweenService:Create(o, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
	end)
end
local function label(parent, text, size, color, font, props)
	local l = inst("TextLabel", {
		Text = text, TextSize = size or 12, TextColor3 = color or C.text,
		Font = font or Enum.Font.Gotham, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, (size or 12) + 4), Parent = parent,
	})
	if props then for k, v in pairs(props) do pcall(function() l[k] = v end) end end
	return l
end
local function wrapLabel(parent, text, size, color, lo)
	return label(parent, text, size, color, nil, {
		TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), LayoutOrder = lo or 0,
	})
end
local function divider(parent, lo)
	return inst("Frame", {
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border,
		BorderSizePixel = 0, LayoutOrder = lo or 0, Parent = parent,
	})
end
local function mkCard(parent, height, lo)
	local c = inst("Frame", {
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = lo or 0, Parent = parent,
	})
	corner(c, 8); stroke(c, C.border)
	return c
end
local ICON_ALIASES = {
	["play-circle"]    = { "circle-play" },
	["check-circle"]   = { "circle-check" },
	["x-circle"]       = { "circle-x" },
	["bar-chart-2"]    = { "chart-column", "bar-chart" },
	["hook"]           = { "webhook", "anchor" },
	["index"]          = { "list-ordered", "book-open", "list" },
	["code-2"]         = { "code-xml", "code" },
	["layout"]         = { "layout-dashboard", "panels-top-left" },
	["layout-dashboard"] = { "layout", "panels-top-left" },
	["loader"]         = { "loader-circle", "loader-2" },
	["maximize"]       = { "maximize-2", "square" },
	["sword"]          = { "swords" },
	["terminal"]       = { "square-terminal" },
	["alert-triangle"] = { "triangle-alert" },
	["backpack"]       = { "package" },
	["monitor"]        = { "layout" },
	["download"]       = { "arrow-down-to-line", "arrow-down" },
	["copy"]           = { "clipboard" },
}
local GLYPHS = {
	["x"] = "×", ["minus"] = "–", ["maximize"] = "□", ["play"] = "▶",
	["play-circle"] = "▶", ["check"] = "✓", ["check-circle"] = "✓",
	["x-circle"] = "×", ["info"] = "i", ["hash"] = "#", ["trash-2"] = "×",
	["terminal"] = ">_", ["loader"] = "…", ["alert-triangle"] = "!",
}
local assetCache, missingIcons = {}, {}
local function resolveAsset(name)
	if not Lucide then return nil end
	local cached = assetCache[name]
	if cached ~= nil then return cached or nil end
	local candidates = { name }
	for _, a in ipairs(ICON_ALIASES[name] or {}) do candidates[#candidates + 1] = a end
	for _, cand in ipairs(candidates) do
		for _, sz in ipairs({ 48, 256, false }) do
			local ok, asset = pcall(function()
				if sz then return Lucide.GetAsset(cand, sz) end
				return Lucide.GetAsset(cand)
			end)
			if ok and type(asset) == "table" and asset.Url then
				assetCache[name] = asset
				return asset
			end
		end
	end
	assetCache[name] = false
	return nil
end
local function setIcon(img, iconName)
	local asset = resolveAsset(iconName)
	local glyph = img:FindFirstChild("Glyph")
	if asset then
		img.Image = asset.Url
		img.ImageRectSize = asset.ImageRectSize
		img.ImageRectOffset = asset.ImageRectOffset
		if glyph then glyph.Visible = false end
	else
		missingIcons[iconName] = true
		img.Image = ""
		if not glyph then
			glyph = inst("TextLabel", {
				Name = "Glyph", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
				Font = Enum.Font.GothamBold, TextScaled = true,
				TextColor3 = img.ImageColor3, Parent = img,
			})
			img:GetPropertyChangedSignal("ImageColor3"):Connect(function()
				glyph.TextColor3 = img.ImageColor3
			end)
		end
		glyph.Text = GLYPHS[iconName] or "•"
		glyph.Visible = true
	end
end
local function mkIcon(parent, iconName, size, color, props)
	local sz = size or 16
	local img = inst("ImageLabel", {
		Name = "Icon", Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1,
		ImageColor3 = color or C.textDim, ScaleType = Enum.ScaleType.Fit, Parent = parent,
	})
	setIcon(img, iconName)
	if props then for k, v in pairs(props) do pcall(function() img[k] = v end) end end
	return img
end
local function mkButton(parent, text, style, size, iconName, lo)
	local cols = {
		primary = { bg = C.accent, fg = C.textHi, st = C.accent },
		secondary = { bg = C.card,   fg = C.text,   st = C.border },
		danger = { bg = C.card,   fg = C.red,    st = C.border },
	}
	local c = cols[style or "secondary"]
	local b = inst("TextButton", {
		Text = "", Size = size or UDim2.new(1, 0, 0, 34), BackgroundColor3 = c.bg,
		AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = lo or 0, Parent = parent,
	})
	corner(b, 8)
	local st = stroke(b, c.st)
	local row = inst("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = b })
	local rl = hList(row, 7)
	rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local ic = iconName and mkIcon(row, iconName, 14, c.fg, { LayoutOrder = 0 }) or nil
	local lbl = label(row, text, 12, c.fg, Enum.Font.GothamSemibold, {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1,
	})
	local api = { button = b, label = lbl, icon = ic, base = c.bg }
	function api.setColors(bg, fg, strokeCol)
		api.base = bg
		b.BackgroundColor3 = bg; lbl.TextColor3 = fg; st.Color = strokeCol or st.Color
		if ic then ic.ImageColor3 = fg end
	end
	b.MouseEnter:Connect(function() b.BackgroundColor3 = api.base:Lerp(Color3.new(1, 1, 1), 0.08) end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = api.base end)
	return api
end
local function mkToggle(parent, initVal, onChange)
	local t = { value = initVal and true or false }
	local track = inst("TextButton", {
		Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		Size = UDim2.fromOffset(36, 20), Parent = parent,
	})
	corner(track, 10)
	local st = stroke(track, C.borderHi)
	local knob = inst("Frame", {
		Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0, Parent = track,
	})
	corner(knob, 7)
	local function paint(animate)
		local pos = t.value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local bg = t.value and C.accent or C.input
		local kc = t.value and C.textHi or C.textDim
		st.Color = t.value and C.accent or C.borderHi
		if animate then
			tween(knob, { Position = pos, BackgroundColor3 = kc })
			tween(track, { BackgroundColor3 = bg })
		else
			knob.Position = pos; knob.BackgroundColor3 = kc; track.BackgroundColor3 = bg
		end
	end
	function t.set(v, silent)
		v = v and true or false
		if t.value == v then return end
		t.value = v
		paint(true)
		if onChange and not silent then onChange(v) end
	end
	track.Activated:Connect(function() t.set(not t.value) end)
	t.track = track
	paint(false)
	return t
end
local function numBox(parent, initVal, minV, maxV, onChange)
	local cur = initVal
	local box = inst("TextBox", {
		Text = tostring(cur), TextSize = 12, TextColor3 = C.accentHi, Font = Enum.Font.Code,
		BackgroundColor3 = C.input, BorderSizePixel = 0, Size = UDim2.fromOffset(56, 26),
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		ClearTextOnFocus = false, Parent = parent,
	})
	corner(box, 6)
	local st = stroke(box, C.borderHi)
	box.Focused:Connect(function() st.Color = C.accent end)
	box.FocusLost:Connect(function()
		st.Color = C.borderHi
		local n = tonumber(box.Text)
		if n then
			cur = math.clamp(math.floor(n + 0.5), minV, maxV)
			onChange(cur)
		end
		box.Text = tostring(cur)
	end)
	return box
end
local logQueues = setmetatable({}, { __mode = "k" })
local logSeq = 0
local function pushLine(scroll, text, color)
	local q = logQueues[scroll]
	if not q then q = {}; logQueues[scroll] = q end
	logSeq += 1
	q[#q + 1] = inst("TextLabel", {
		Text = text, TextSize = 10, TextColor3 = color or C.logInfo, Font = Enum.Font.Code,
		BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None, LayoutOrder = logSeq, Parent = scroll,
	})
	if #q > MAX_LOG then table.remove(q, 1):Destroy() end
	task.defer(function()
		if not scroll.Parent then return end
		task.defer(function()
			if not scroll.Parent then return end
			local bottom = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y)
			scroll.CanvasPosition = Vector2.new(0, bottom)
		end)
	end)
end
local function uiLog(text, color)
	local line = text
	table.insert(UIState.logLines, { text = line, color = color or C.logInfo })
	if #UIState.logLines > MAX_LOG then table.remove(UIState.logLines, 1) end
	for _, ref in ipairs({ UIState.refs.liveScroll }) do
		if ref and ref.Parent then pushLine(ref, line, color) end
	end
end
local _wl = writeLog
writeLog = function(msg)
	_wl(msg)
	local m = tostring(msg):lower()
	local col = C.logInfo
	if m:find("error") or m:find("failed") then col = C.logErr
	elseif m:find("saved") or m:find("completed") or m:find("ok") then col = C.logOk
	elseif m:find("warn") or m:find("missing") or m:find("unavailable") or m:find("inaccessible") then col = C.logWarn end
	uiLog(msg, col)
end
local function setStatus(text, color)
	UIState.statusText = text
	if UIState.refs.statusLbl and UIState.refs.statusLbl.Parent then
		UIState.refs.statusLbl.Text = text
		UIState.refs.statusLbl.TextColor3 = color or C.text
	end
end
local function setProgress(pct, lbl)
	UIState.pct = math.clamp(pct, 0, 100); UIState.pctLabel = lbl or ""
end
local function fileExists(path)
	if not has("isfile") then return false end
	local ok, res = pcall(Env.isfile, path)
	return ok and res == true
end
local function posStore()
	local ok, env = pcall(getgenv)
	return (ok and type(env) == "table") and env or _G
end
local function buildUI()
	local LP = Players.LocalPlayer
	if not LP then return end
	local PGui = LP:WaitForChild("PlayerGui", 10)
	if not PGui then return end
	local prev = PGui:FindFirstChild("DumpExplorer")
	if prev then prev:Destroy() end
	local screen = inst("ScreenGui", {
		Name = "DumpExplorer", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = PGui,
	})
	local conns = {}
	local function track(c) conns[#conns + 1] = c; return c end
	screen.Destroying:Connect(function()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	end)
	Lifecycle.add(function() screen:Destroy() end)
	local ToastHolder = inst("Frame", {
		Name = "Toasts", BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 150,
		Parent = screen,
	})
	inst("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 9), Parent = ToastHolder,
	})
	local ToastSeq = 0
	local LOGO_IMAGE_TOAST = "rbxassetid://125839047186269"
	local function notify(title, text, duration)
		ToastSeq = ToastSeq + 1
		duration = math.clamp(tonumber(duration) or 5, 1, 15)
		local card = inst("Frame", {
			Name = "DumpNotification", Size = UDim2.new(1, 0, 0, 68),
			BackgroundColor3 = Color3.fromRGB(23, 23, 23), BackgroundTransparency = 0.02,
			BorderSizePixel = 0, LayoutOrder = ToastSeq, ZIndex = 150, ClipsDescendants = true,
			Parent = ToastHolder,
		})
		corner(card, 10)
		inst("UIStroke", { Color = Color3.fromRGB(36, 36, 36), Transparency = 0.22, Thickness = 1, Parent = card })
		local scale = inst("UIScale", { Scale = 0.92, Parent = card })
		local iconHolder = inst("Frame", {
			Name = "IconHolder", Size = UDim2.fromOffset(36, 36),
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(36, 36, 36),
			BorderSizePixel = 0, ZIndex = 151, Parent = card,
		})
		corner(iconHolder, 8)
		if LOGO_IMAGE_TOAST and LOGO_IMAGE_TOAST ~= "" then
			inst("ImageLabel", {
				Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1,
				Image = LOGO_IMAGE_TOAST, ScaleType = Enum.ScaleType.Fit,
				ZIndex = 152, Parent = iconHolder,
			})
		else
			inst("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "D",
				Font = Enum.Font.GothamBold, TextSize = 18,
				TextColor3 = Color3.fromRGB(240, 240, 240), ZIndex = 152, Parent = iconHolder,
			})
		end
		local titleLab = inst("TextLabel", {
			Text = tostring(title or "Dump Explorer"), TextSize = 12,
			TextColor3 = Color3.fromRGB(254, 254, 254), Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -88, 0, 16),
			ZIndex = 152, Parent = card,
		})
		local descLab = inst("TextLabel", {
			Text = tostring(text or ""), TextSize = 10,
			TextColor3 = Color3.fromRGB(180, 180, 180), Font = Enum.Font.Gotham,
			BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(60, 28), Size = UDim2.new(1, -78, 0, 26),
			ZIndex = 152, Parent = card,
		})
		local closeBtn = inst("TextButton", {
			Name = "Close", Text = "×", Font = Enum.Font.GothamBold, TextSize = 16,
			TextColor3 = Color3.fromRGB(140, 140, 140), AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(21, 21, 21), BorderSizePixel = 0,
			Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -28, 0, 8),
			ZIndex = 154, Parent = card,
		})
		corner(closeBtn, 6)
		closeBtn.MouseEnter:Connect(function()
			tween(closeBtn, { TextColor3 = Color3.fromRGB(254, 254, 254), BackgroundColor3 = Color3.fromRGB(36, 36, 36) }, 0.12)
		end)
		closeBtn.MouseLeave:Connect(function()
			tween(closeBtn, { TextColor3 = Color3.fromRGB(140, 140, 140), BackgroundColor3 = Color3.fromRGB(21, 21, 21) }, 0.12)
		end)
		local progressBack = inst("Frame", {
			Size = UDim2.new(1, -28, 0, 2), Position = UDim2.new(0, 14, 1, -5),
			BackgroundColor3 = Color3.fromRGB(36, 36, 36), BorderSizePixel = 0, ZIndex = 153, Parent = card,
		})
		corner(progressBack, 2)
		local progress = inst("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(140, 140, 140),
			BorderSizePixel = 0, ZIndex = 154, Parent = progressBack,
		})
		corner(progress, 2)
		local removed = false
		local function dismiss()
			if removed or not card.Parent then return end
			removed = true
			tween(scale, { Scale = 0.92 }, 0.15)
			tween(card, { BackgroundTransparency = 1 }, 0.15)
			task.delay(0.17, function() if card and card.Parent then card:Destroy() end end)
		end
		closeBtn.Activated:Connect(dismiss)
		tween(scale, { Scale = 1 }, 0.18)
		tween(progress, { Size = UDim2.fromScale(0, 1) }, duration)
		task.delay(duration, dismiss)
		local kids = {}
		for _, c in ipairs(ToastHolder:GetChildren()) do
			if c:IsA("Frame") and c ~= card then kids[#kids + 1] = c end
		end
		table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		while #kids >= 3 do table.remove(kids, 1):Destroy() end
	end
	local root = inst("Frame", {
		Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromOffset(560, 400), Parent = screen,
	})
	local win = inst("Frame", {
		Name = "Window", Size = UDim2.fromOffset(560, 400), BackgroundColor3 = C.window,
		BorderSizePixel = 0, Active = true, Parent = root,
	})
	corner(win, 10)
	stroke(win, C.border, 1)
	local scaleObj = inst("UIScale", { Scale = 0.8, Parent = win })
	local LOGO_IMAGE = "rbxassetid://125839047186269"
	local curW, curH = 560, 400
	local posX, posY = 0, 0
	local function viewport()
		local v = screen.AbsoluteSize
		if v.X < 50 or v.Y < 50 then
			local cam = workspace.CurrentCamera
			if cam then v = cam.ViewportSize end
		end
		return v
	end
	local function applySize()
		local vs, s = viewport(), scaleObj.Scale
		curW = math.clamp(math.floor(vs.X / s) - 24, 280, 600)
		curH = math.clamp(math.floor(vs.Y / s) - 24, 240, 420)
		win.Size = UDim2.fromOffset(curW, curH)
		root.Size = UDim2.fromOffset(curW * s, curH * s)
	end
	local function place(x, y)
		local vs, s = viewport(), scaleObj.Scale
		local rw = curW * s
		local keep = math.min(96, rw)
		x = math.clamp(x, keep - rw, math.max(keep - rw, vs.X - keep))
		y = math.clamp(y, 0, math.max(0, vs.Y - TITLE_H * s))
		posX, posY = x, y
		root.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
		posStore().__DumpExplorerPos = { x = x, y = y }
	end
	local TB = inst("Frame", {
		Name = "TitleBar", Size = UDim2.new(1, 0, 0, TITLE_H),
		BackgroundColor3 = C.titlebar, BorderSizePixel = 0, Parent = win,
	})
	corner(TB, 10)
	local tbFill = inst("Frame", {
		Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = C.titlebar, BorderSizePixel = 0, Parent = TB,
	})
	inst("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = C.border, BorderSizePixel = 0, Parent = TB,
	})
	local dragArea = inst("Frame", {
		Name = "DragArea", Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1,
		Active = true, Parent = TB,
	})
	inst("ImageLabel", {
		Size = UDim2.fromOffset(28, 28),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		BackgroundTransparency = 1,
		Image = LOGO_IMAGE,
		ScaleType = Enum.ScaleType.Fit,
		Parent = TB,
	})
	label(TB, "Dump Explorer", 13, C.textHi, Enum.Font.GothamBold, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 220, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local ctrl = inst("Frame", {
		Size = UDim2.new(0, 38, 1, 0), AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0), BackgroundTransparency = 1, Parent = TB,
	})
	local ctrlList = hList(ctrl, 4)
	ctrlList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local function winBtn(iconName, hoverBg, lo)
		local b = inst("TextButton", {
			Text = "", Size = UDim2.fromOffset(30, 28), BackgroundColor3 = hoverBg,
			BackgroundTransparency = 1, AutoButtonColor = false, BorderSizePixel = 0,
			LayoutOrder = lo, Parent = ctrl,
		})
		corner(b, 6)
		local ic = mkIcon(b, iconName, 14, C.textDim, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		})
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0; ic.ImageColor3 = C.textHi end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1; ic.ImageColor3 = C.textDim end)
		return b, ic
	end
	local closeB = winBtn("x", C.redBg, 1)
	closeB.Activated:Connect(function() screen:Destroy() end)
	local body = inst("Frame", {
		Name = "Body", Size = UDim2.new(1, 0, 1, -(TITLE_H + STATUS_H)),
		Position = UDim2.fromOffset(0, TITLE_H), BackgroundTransparency = 1, Parent = win,
	})
	local sidebar = inst("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, SIDEBAR_W, 1, 0), ZIndex = 5,
		BackgroundColor3 = C.sidebar, BorderSizePixel = 0, Parent = body,
	})
	inst("Frame", {
		Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = C.border, BorderSizePixel = 0, Parent = sidebar,
	})
	local tabList = inst("Frame", {
		Size = UDim2.new(1, 0, 1, -16), Position = UDim2.fromOffset(0, 8),
		BackgroundTransparency = 1, Parent = sidebar,
	})
	local tl = vList(tabList, 4)
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local content = inst("Frame", {
		Name = "Content", Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
		Position = UDim2.fromOffset(SIDEBAR_W, 0), BackgroundTransparency = 1, Parent = body,
	})
	pad(content, 12, 14, 8, 14)
	local sbar = inst("Frame", {
		Name = "StatusBar", Size = UDim2.new(1, 0, 0, STATUS_H),
		Position = UDim2.new(0, 0, 1, -STATUS_H), BackgroundColor3 = C.titlebar,
		BorderSizePixel = 0, Parent = win,
	})
	corner(sbar, 10)
	inst("Frame", {
		Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = C.titlebar, BorderSizePixel = 0, Parent = sbar,
	})
	inst("Frame", {
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border, BorderSizePixel = 0, Parent = sbar,
	})
	local statusDot = mkIcon(sbar, "circle", 10, C.gray, {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
	})
	UIState.refs.statusLbl = label(sbar, "Ready", 11, C.text, Enum.Font.Gotham, {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 32, 0.5, 0),
		Size = UDim2.new(1, -228, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd,
	})
	UIState.refs.pPct = label(sbar, "0%", 11, C.textDim, Enum.Font.GothamSemibold, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(40, 14), TextXAlignment = Enum.TextXAlignment.Right,
	})
	local pTrack = inst("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
		Size = UDim2.fromOffset(120, 4), BackgroundColor3 = C.input, BorderSizePixel = 0, Parent = sbar,
	})
	corner(pTrack, 2)
	UIState.refs.pFill = inst("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = pTrack,
	})
	corner(UIState.refs.pFill, 2)
	local tabs = {}
	local function paintTab(t, state)
		if state == "active" then
			t.btn.BackgroundTransparency = 0; t.btn.BackgroundColor3 = C.accentBg
			t.icon.ImageColor3 = C.accentHi; t.ind.Visible = true
		elseif state == "hover" then
			t.btn.BackgroundTransparency = 0; t.btn.BackgroundColor3 = C.cardHover
			t.icon.ImageColor3 = C.text; t.ind.Visible = false
		else
			t.btn.BackgroundTransparency = 1
			t.icon.ImageColor3 = C.textDim; t.ind.Visible = false
		end
	end
	local function switchTab(id)
		local target = tabs[id]
		if not target then return end
		for _, t in pairs(tabs) do
			paintTab(t, "idle")
			t.frame.Visible = false
		end
		paintTab(target, "active")
		target.frame.Visible = true
		UIState.activeTab = id
	end
	local function newPage(id, iconName, title, subtitle, scrolling)
		local fr = inst("Frame", {
			Name = "Tab_" .. id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Visible = false, Parent = content,
		})
		local hdr = inst("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = fr })
		mkIcon(hdr, iconName, 18, C.accentHi, { Position = UDim2.fromOffset(0, 1) })
		label(hdr, title, 15, C.textHi, Enum.Font.GothamBold, {
			Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 0, 20),
		})
		if subtitle then
			label(hdr, subtitle, 11, C.textDim, Enum.Font.Gotham, {
				Position = UDim2.fromOffset(28, 21), Size = UDim2.new(1, -28, 0, 14),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
		end
		local pageBody
		if scrolling then
			pageBody = inst("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46),
				BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
				ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y, Parent = fr,
			})
			vList(pageBody, 8); pad(pageBody, 0, 8, 4, 0)
		else
			pageBody = inst("Frame", {
				Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46),
				BackgroundTransparency = 1, Parent = fr,
			})
		end
		return fr, pageBody
	end
	local function makeTab(id, iconName, tooltip, order, title, subtitle, scrolling)
		local b = inst("TextButton", {
			Text = "", Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1,
			BackgroundColor3 = C.cardHover, AutoButtonColor = false, BorderSizePixel = 0,
			LayoutOrder = order, Parent = tabList,
		})
		corner(b, 8)
		local ind = inst("Frame", {
			Size = UDim2.fromOffset(3, 16), AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -8, 0.5, 0), BackgroundColor3 = C.accent,
			BorderSizePixel = 0, Visible = false, Parent = b,
		})
		corner(ind, 2)
		local icon = mkIcon(b, iconName, 18, C.textDim, {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		})
		local tip = inst("Frame", {
			Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(1, 12, 0.5, -13), BackgroundColor3 = C.card,
			BorderSizePixel = 0, Visible = false, ZIndex = 10, Parent = b,
		})
		corner(tip, 6); stroke(tip, C.borderHi); pad(tip, 0, 10, 0, 10)
		label(tip, tooltip, 11, C.text, Enum.Font.GothamSemibold, {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 10,
		})
		local fr, pageBody = newPage(id, iconName, title, subtitle, scrolling)
		local t = { btn = b, ind = ind, icon = icon, frame = fr }
		tabs[id] = t
		b.MouseEnter:Connect(function()
			tip.Visible = true
			if UIState.activeTab ~= id then paintTab(t, "hover") end
		end)
		b.MouseLeave:Connect(function()
			tip.Visible = false
			if UIState.activeTab ~= id then paintTab(t, "idle") end
		end)
		b.Activated:Connect(function() switchTab(id) end)
		return pageBody
	end
	local pServices = makeTab("services", "layers",      "Services", 1, "Service Selection", "Choose which Roblox services to include in the dump.", true)
	local pRun = makeTab("run",      "play-circle", "Run",      2, "Run Dump", "Start the scan and write all reports.", true)
	local pStatus = makeTab("status",   "activity",    "Status",   3, "Status", "", true)
	pStatus.Position = UDim2.fromOffset(0, 28)
	pStatus.Size = UDim2.new(1, 0, 1, -28)
	local pFiles = pStatus
	local pSettings = makeTab("settings", "settings",    "Settings", 4, "Settings", "", true)
	pSettings.Position = UDim2.fromOffset(0, 28)
	pSettings.Size = UDim2.new(1, 0, 1, -28)
	local sep = divider(tabList, 5); sep.Size = UDim2.fromOffset(24, 1)
	local pAbout = makeTab("about",    "info",        "About",    6, "About", "Universal Roblox analysis & dump system.", true)
	do
		local svcIcons = {
			ReplicatedFirst = "download", ReplicatedStorage = "database", Players = "users",
			Workspace = "globe", PlayerGui = "monitor", Lighting = "sun", SoundService = "volume-2",
			StarterGui = "layout-dashboard", StarterPack = "backpack", StarterPlayer = "user",
			TextChatService = "message-square", Teams = "flag",
		}
		local toggles = {}
		local countLbl
		local function updateCount()
			local n = 0
			for _, s in ipairs(ALL_SERVICES) do if UIState.svcToggles[s] then n += 1 end end
			if countLbl then countLbl.Text = n .. " / " .. #ALL_SERVICES .. " selected" end
		end
		local actions = inst("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 0, Parent = pServices })
		hList(actions, 6)
		local selAll = mkButton(actions, "Select All", "secondary", UDim2.fromOffset(94, 28), nil, 0)
		local clrAll = mkButton(actions, "Clear All",  "secondary", UDim2.fromOffset(84, 28), nil, 1)
		countLbl = label(actions, "", 11, C.textDim, Enum.Font.Gotham, {
			Size = UDim2.new(1, -190, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 2,
		})
		for i, svc in ipairs(ALL_SERVICES) do
			local row = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = i, Parent = pServices,
			})
			corner(row, 6); stroke(row, C.border)
			label(row, svc, 12, C.text, Enum.Font.Gotham, {
				Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -80, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(row, UIState.svcToggles[svc], function(v)
				UIState.svcToggles[svc] = v
				updateCount()
			end)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
			toggles[svc] = tg
		end
		local function setAll(v)
			for _, s in ipairs(ALL_SERVICES) do
				UIState.svcToggles[s] = v
				toggles[s].set(v, true)
			end
			updateCount()
		end
		selAll.button.Activated:Connect(function() setAll(true) end)
		clrAll.button.Activated:Connect(function() setAll(false) end)
		updateCount()
	end
	do
		label(pRun, tostring(Config.GameName), 13, C.textHi, Enum.Font.GothamSemibold, {
			Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		label(pRun, tostring(Config.MainFolder), 10, C.textDim, Enum.Font.Code, {
			Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 0,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local run = mkButton(pRun, "Start Dump", "primary", UDim2.new(1, 0, 0, 44), "play", 1)
		run.label.TextSize = 14
		local prog = mkCard(pRun, nil, 2)
		pad(prog, 10, 12, 12, 12); vList(prog, 8)
		local ph = inst("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 0, Parent = prog })
		label(ph, "Progress", 11, C.textDim, Enum.Font.GothamSemibold, { Size = UDim2.new(0.4, 0, 1, 0) })
		UIState.refs.runPct = label(ph, "0%", 11, C.text, Enum.Font.GothamSemibold, {
			Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.fromScale(0.4, 0),
			TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local pt = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = C.input, BorderSizePixel = 0, LayoutOrder = 1, Parent = prog,
		})
		corner(pt, 3)
		UIState.refs.runBar = inst("Frame", {
			Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = pt,
		})
		corner(UIState.refs.runBar, 3)
		UIState.refs.phaseLbl = label(prog, "", 10, C.textDim, Enum.Font.Gotham, { LayoutOrder = 2 })
		UIState.refs.lastRunLbl = label(prog, "", 10, C.textDim, Enum.Font.Gotham, { LayoutOrder = 3 })
		local function setRunState(state)
			if state == "running" then
				run.setColors(C.card, C.yellow, C.border)
				run.label.Text = "Running — please wait..."
				setIcon(run.icon, "loader")
			elseif state == "done" then
				run.setColors(C.greenBg, C.green, C.green)
				run.label.Text = "Dump Completed — run again"
				setIcon(run.icon, "check-circle")
			elseif state == "error" then
				run.setColors(C.redBg, C.red, C.red)
				run.label.Text = "Failed — click to retry"
				setIcon(run.icon, "x-circle")
			else
				run.setColors(C.accent, C.textHi, C.accent)
				run.label.Text = "Start Dump"
				setIcon(run.icon, "play")
			end
		end
		local FAST_LOGO = "rbxassetid://125839047186269"
		local function showFastScreen()
			local LP2 = Players.LocalPlayer
			if not LP2 then return end
			local pg2 = LP2:FindFirstChildOfClass("PlayerGui")
			if not pg2 then return end
			local fs = Instance.new("ScreenGui")
			fs.Name = "DumpFastModeScreen"
			pcall(function() fs.AutoLocalize = false end)
			fs.DisplayOrder = 9999
			fs.IgnoreGuiInset = true
			fs.ResetOnSpawn = false
			fs.ZIndexBehavior = Enum.ZIndexBehavior.Global
			local bg = Instance.new("Frame")
			bg.Size = UDim2.fromScale(1, 1)
			bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			bg.BackgroundTransparency = 0
			bg.BorderSizePixel = 0
			bg.ZIndex = 1
			bg.Parent = fs
			local center = Instance.new("Frame")
			center.Size = UDim2.fromOffset(260, 220)
			center.AnchorPoint = Vector2.new(0.5, 0.5)
			center.Position = UDim2.fromScale(0.5, 0.5)
			center.BackgroundTransparency = 1
			center.ZIndex = 2
			center.Parent = bg
			local centerList = Instance.new("UIListLayout")
			centerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
			centerList.VerticalAlignment = Enum.VerticalAlignment.Center
			centerList.Padding = UDim.new(0, 18)
			centerList.SortOrder = Enum.SortOrder.LayoutOrder
			centerList.Parent = center
			local logo = Instance.new("ImageLabel")
			logo.Size = UDim2.fromOffset(110, 110)
			logo.BackgroundTransparency = 1
			logo.Image = FAST_LOGO
			logo.ScaleType = Enum.ScaleType.Fit
			logo.ZIndex = 3
			logo.LayoutOrder = 1
			logo.Parent = center
			local waitLbl = Instance.new("TextLabel")
			waitLbl.Size = UDim2.new(1, 0, 0, 28)
			waitLbl.BackgroundTransparency = 1
			waitLbl.Text = "Please wait..."
			waitLbl.Font = Enum.Font.GothamBold
			waitLbl.TextSize = 20
			waitLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			waitLbl.TextXAlignment = Enum.TextXAlignment.Center
			waitLbl.ZIndex = 3
			waitLbl.LayoutOrder = 2
			pcall(function() waitLbl.AutoLocalize = false end)
			waitLbl.Parent = center
			local subLbl = Instance.new("TextLabel")
			subLbl.Size = UDim2.new(1, 0, 0, 18)
			subLbl.BackgroundTransparency = 1
			subLbl.Text = "Fast Mode — do not close the game"
			subLbl.Font = Enum.Font.Gotham
			subLbl.TextSize = 13
			subLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
			subLbl.TextXAlignment = Enum.TextXAlignment.Center
			subLbl.ZIndex = 3
			subLbl.LayoutOrder = 3
			pcall(function() subLbl.AutoLocalize = false end)
			subLbl.Parent = center
			fs.Parent = pg2
			UIState.fastModeScreen = fs
		end
		local function hideFastScreen()
			if UIState.fastModeScreen and UIState.fastModeScreen.Parent then
				UIState.fastModeScreen:Destroy()
			end
			UIState.fastModeScreen = nil
		end
		run.button.Activated:Connect(function()
			if UIState.running then return end
			UIState.running = true; UIState.finished = false
			setRunState("running")
			local sel = {}
			for _, s in ipairs(ALL_SERVICES) do
				if UIState.svcToggles[s] then sel[#sel + 1] = s end
			end
			Config.ServiceList = #sel > 0 and sel or { "ReplicatedStorage" }
			switchTab("status")
			if Config.FastMode then showFastScreen() end
			task.spawn(function()
				local ok, err = pcall(main)
				UIState.running = false
				if Config.FastMode then hideFastScreen() end
				if ok then
					UIState.finished = true
					setRunState("done")
					UIState.refs.lastRunLbl.Text = "Last run: " .. os.date("%H:%M:%S")
					setStatus("Done — " .. Config.MainFolder, C.green)
					setProgress(100, "Complete")
					task.wait(2)
					if UIState.activeTab == "status" then switchTab("files") end
				else
					UIState.finished = false
					setRunState("error")
					setStatus("Error: " .. tostring(err), C.red)
					uiLog("RUNTIME ERROR: " .. tostring(err), C.logErr)
				end
			end)
		end)
	end
	local statusLeft, statusRight
	do
		local workspace = inst("Frame", {
			Name = "StatusWorkspace", Size = UDim2.new(1, 0, 0, 630),
			BackgroundTransparency = 1, LayoutOrder = 1, Parent = pStatus,
		})
		statusLeft = inst("Frame", {
			Name = "StatusLeft", Size = UDim2.new(0.5, -5, 1, 0),
			BackgroundTransparency = 1, Parent = workspace,
		})
		statusRight = inst("Frame", {
			Name = "StatusFilesRight", Size = UDim2.new(0.5, -5, 1, 0),
			Position = UDim2.new(0.5, 5, 0, 0), BackgroundTransparency = 1, Parent = workspace,
		})
		vList(statusLeft, 8)
		vList(statusRight, 8)
		local grid = inst("Frame", { Size = UDim2.new(1, 0, 0, 96), BackgroundTransparency = 1, LayoutOrder = 1, Parent = statusLeft })
		inst("UIGridLayout", {
			CellSize = UDim2.new(0.5, -4, 0, 44), CellPadding = UDim2.fromOffset(8, 6),
			SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid,
		})
		local function statCard(text, refKey, lo)
			local c = inst("Frame", { BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = lo, Parent = grid })
			corner(c, 7); stroke(c, C.border)
			label(c, text, 10, C.textDim, Enum.Font.Gotham, { Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, 13) })
			UIState.refs[refKey] = label(c, "0", 15, C.textHi, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(10, 19), Size = UDim2.new(1, -20, 0, 19),
			})
		end
		statCard("Total", "mTotal", 1)
		statCard("Success", "mOk", 2)
		statCard("Failed", "mFail", 3)
		statCard("Remotes", "mRemotes", 4)
		local logCard = inst("Frame", { Size = UDim2.new(1, 0, 0, 154), BackgroundColor3 = C.input, BorderSizePixel = 0, LayoutOrder = 2, Parent = statusLeft })
		corner(logCard, 7); stroke(logCard, C.border); pad(logCard, 8, 8, 8, 8); vList(logCard, 6)
		label(logCard, "Activity", 11, C.textHi, Enum.Font.GothamSemibold, { Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 0 })
		local ls = inst("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -22), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = logCard,
		})
		pad(ls, 2, 2, 2, 2); vList(ls, 1)
		UIState.refs.liveScroll = ls
		for _, e in ipairs(UIState.logLines) do pushLine(ls, e.text, e.color) end
		local editor = inst("Frame", { Size = UDim2.new(1, 0, 0, 300), BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 3, Parent = statusLeft })
		corner(editor, 7); stroke(editor, C.border); pad(editor, 8, 8, 8, 8); vList(editor, 6)
		label(editor, "File editor", 12, C.textHi, Enum.Font.GothamSemibold, { Size = UDim2.new(1, 0, 0, 17), LayoutOrder = 0 })
		local pathBox = inst("TextBox", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.input, BorderSizePixel = 0,
			Text = "", PlaceholderText = "File name (inside dump folder)", TextColor3 = C.text,
			PlaceholderColor3 = C.textDim, Font = Enum.Font.Gotham, TextSize = 10,
			ClearTextOnFocus = false, LayoutOrder = 1, Parent = editor,
		})
		corner(pathBox, 5); pad(pathBox, 0, 8, 0, 8)
		local actions = inst("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 2, Parent = editor })
		hList(actions, 6)
		local loadBtn = mkButton(actions, "Load", "secondary", UDim2.fromOffset(76, 28), nil, 1)
		local saveBtn = mkButton(actions, "Save", "primary", UDim2.fromOffset(76, 28), nil, 2)
		local editorText = inst("TextBox", {
			Size = UDim2.new(1, 0, 0, 178), BackgroundColor3 = C.input, BorderSizePixel = 0,
			Text = "", PlaceholderText = "File contents...", TextColor3 = C.text,
			PlaceholderColor3 = C.textDim, Font = Enum.Font.Code, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = false, MultiLine = true, ClearTextOnFocus = false,
			LayoutOrder = 3, Parent = editor,
		})
		corner(editorText, 5); pad(editorText, 7, 7, 7, 7)
		local editorStatus = label(editor, "Choose a file from the dump folder, then Load to edit it.", 9, C.textDim, Enum.Font.Gotham, {
			Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 4, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local function resolveEditorPath()
			local name = tostring(pathBox.Text):gsub("^%s+", ""):gsub("%s+$", "")
			if name == "" then return nil end
			if name:find("[/\\]") then return name end
			return Config.MainFolder .. "/" .. name
		end
		loadBtn.button.Activated:Connect(function()
			local path = resolveEditorPath()
			if not path then editorStatus.Text = "Enter a file name first"; return end
			if not has("readfile") then editorStatus.Text = "readfile is unavailable"; return end
			local ok, content = pcall(Env.readfile, path)
			if not ok or type(content) ~= "string" then editorStatus.Text = "Could not read file"; return end
			editorText.Text = content
			editorStatus.Text = "Loaded " .. (path:match("([^/\\]+)$") or path)
		end)
		saveBtn.button.Activated:Connect(function()
			local path = resolveEditorPath()
			if not path then editorStatus.Text = "Enter a file name first"; return end
			if not has("writefile") then editorStatus.Text = "writefile is unavailable"; return end
			local ok = pcall(Env.writefile, path, editorText.Text)
			editorStatus.Text = ok and "Saved successfully" or "Could not save file"
		end)
	end
	do
		label(statusRight, "Downloaded files", 12, C.textHi, Enum.Font.GothamSemibold, {
			Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0,
		})
		local top = inst("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1, Parent = statusRight })
		hList(top, 6)
		local refreshBtn = mkButton(top, "Refresh", "secondary", UDim2.fromOffset(92, 28), "refresh-cw", 0)
		local countLbl = label(top, "0 files", 10, C.textDim, Enum.Font.Gotham, {
			Size = UDim2.new(1, -100, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 1,
		})
		local listPanel = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 112), BackgroundColor3 = C.input,
			BorderSizePixel = 0, LayoutOrder = 2, Parent = statusRight,
		})
		corner(listPanel, 8); stroke(listPanel, C.border)
		local fileScroll = inst("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = listPanel,
		})
		pad(fileScroll, 6, 6, 6, 6); vList(fileScroll, 3)
		local selectedPath, selectedName
		local previewCard = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 3, Parent = statusRight,
		})
		corner(previewCard, 8); stroke(previewCard, C.border); pad(previewCard, 8, 8, 8, 8); vList(previewCard, 6)
		local previewTitle = label(previewCard, "Select a file", 11, C.textHi, Enum.Font.GothamSemibold, {
			Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0,
		})
		local renameRow = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
			ClipsDescendants = true, LayoutOrder = 1, Parent = previewCard,
		})
		hList(renameRow, 5)
		local nameBox = inst("TextBox", {
			Size = UDim2.new(1, -96, 1, 0), BackgroundColor3 = C.input, BorderSizePixel = 0,
			ClipsDescendants = true, Text = "", PlaceholderText = "New file name",
			TextColor3 = C.text, PlaceholderColor3 = C.textDim,
			Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = false,
			ClearTextOnFocus = false, LayoutOrder = 0, Parent = renameRow,
		})
		corner(nameBox, 6); pad(nameBox, 0, 8, 0, 8)
		local renameBtn = mkButton(renameRow, "Rename", "secondary", UDim2.fromOffset(82, 30), "pencil", 1)
		local previewScroll = inst("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.input, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = C.scroll, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = previewCard,
		})
		corner(previewScroll, 6); pad(previewScroll, 8, 8, 8, 8)
		local codeLabel = inst("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Double-click a file to preview its contents.",
			TextColor3 = C.textDim, TextSize = 10, Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = false, RichText = true, Parent = previewScroll,
		})
		local function escapeRich(t)
			return tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
		end
		local function highlightLua(source)
			source = tostring(source or "")
			if #source > 60000 then source = source:sub(1, 60000) .. "\n\n-- preview truncated (60 KB limit)" end
			local out, i, n = {}, 1, #source
			local keywords = {
				["and"]=true, ["break"]=true, ["do"]=true, ["else"]=true, ["elseif"]=true,
				["end"]=true, ["false"]=true, ["for"]=true, ["function"]=true, ["if"]=true,
				["in"]=true, ["local"]=true, ["nil"]=true, ["not"]=true, ["or"]=true,
				["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true, ["until"]=true, ["while"]=true,
			}
			while i <= n do
				local c = source:sub(i, i)
				local chunk, color
				if source:sub(i, i + 1) == "--" then
					local e = source:find("\n", i, true) or (n + 1)
					chunk, color = source:sub(i, e - 1), "#6A9955"
					i = e
				elseif c == '"' or c == "'" then
					local q, j = c, i + 1
					while j <= n do
						local x = source:sub(j, j)
						if x == "\\" then j = j + 2
						elseif x == q then j = j + 1; break
						else j = j + 1 end
					end
					chunk, color = source:sub(i, j - 1), "#CE9178"; i = j
				elseif c:match("[%a_]") then
					local j = i + 1
					while j <= n and source:sub(j, j):match("[%w_]") do j = j + 1 end
					chunk = source:sub(i, j - 1)
					color = keywords[chunk] and "#569CD6" or "#DCDCAA"
					i = j
				elseif c:match("%d") then
					local j = i + 1
					while j <= n and source:sub(j, j):match("[%w%.]") do j = j + 1 end
					chunk, color = source:sub(i, j - 1), "#B5CEA8"; i = j
				else
					chunk, color = c, "#D4D4D4"; i = i + 1
				end
				out[#out + 1] = '<font color="' .. color .. '">' .. escapeRich(chunk) .. '</font>'
			end
			return table.concat(out)
		end
		local function showFile(path)
			if not has("readfile") then
				codeLabel.Text = "readfile is unavailable in this executor."
				return
			end
			local ok, content = pcall(Env.readfile, path)
			if not ok or type(content) ~= "string" then
				codeLabel.Text = "Unable to read this file."
				return
			end
			selectedPath = path
			selectedName = path:match("([^/\\]+)$") or path
			previewTitle.Text = selectedName .. "  ·  " .. tostring(#content) .. " bytes"
			nameBox.Text = selectedName
			local ext = selectedName:match("%.([^%.]+)$")
			if ext and (ext:lower() == "lua" or ext:lower() == "luau") then
				codeLabel.Text = highlightLua(content)
			else
				codeLabel.Text = escapeRich(content:sub(1, 60000))
			end
			codeLabel.Size = UDim2.new(1, 0, 0, 0)
			previewScroll.CanvasPosition = Vector2.new(0, 0)
		end
		local function refreshFiles()
			for _, child in ipairs(fileScroll:GetChildren()) do
				if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
			end
			local found = {}
			if has("listfiles") then
				local ok, paths = pcall(Env.listfiles, Config.MainFolder)
				if ok and type(paths) == "table" then
					for _, path in ipairs(paths) do
						if type(path) == "string" and path:sub(1, #Config.MainFolder) == Config.MainFolder then
							local isDir = false
							if has("isfolder") then pcall(function() isDir = Env.isfolder(path) end) end
							if not isDir then found[#found + 1] = path end
						end
					end
				end
			end
			table.sort(found, function(a, b) return a:lower() < b:lower() end)
			countLbl.Text = tostring(#found) .. " files"
			for i, path in ipairs(found) do
				local filename = path:match("([^/\\]+)$") or path
				local b = inst("TextButton", {
					Size = UDim2.new(1, -4, 0, 27), BackgroundColor3 = C.card,
					BorderSizePixel = 0, AutoButtonColor = false, Text = "",
					LayoutOrder = i, Parent = fileScroll,
				})
				corner(b, 5)
				label(b, filename, 10, C.text, Enum.Font.Code, {
					Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				})
				local lastClick = 0
				b.Activated:Connect(function()
					local now = os.clock()
					if now - lastClick <= 0.35 then
						showFile(path)
					else
						selectedPath = path
						selectedName = filename
						previewTitle.Text = filename .. "  ·  double-click to preview"
						nameBox.Text = filename
					end
					lastClick = now
				end)
			end
			if #found == 0 then
				label(fileScroll, has("listfiles") and "No files found yet." or "This executor does not provide listfiles.", 10, C.textDim, Enum.Font.Gotham, {
					Size = UDim2.new(1, -8, 0, 24), LayoutOrder = 1,
				})
			end
		end
		renameBtn.button.Activated:Connect(function()
			if not selectedPath or not selectedName then return end
			local newName = tostring(nameBox.Text):gsub("^%s+", ""):gsub("%s+$", "")
			newName = sanitizeName(newName)
			if newName == "" or newName == "_" then return end
			local folder = selectedPath:match("^(.*[/\\])") or (Config.MainFolder .. "/")
			local newPath = folder .. newName
			if newPath == selectedPath then return end
			if not has("readfile") or not has("writefile") or not has("delfile") then
				previewTitle.Text = "Rename unavailable: readfile, writefile and delfile are required"
				return
			end
			local okRead, content = pcall(Env.readfile, selectedPath)
			if not okRead then previewTitle.Text = "Could not read selected file"; return end
			if fileExists(newPath) then previewTitle.Text = "A file with that name already exists"; return end
			local okWrite = pcall(Env.writefile, newPath, content)
			if not okWrite then previewTitle.Text = "Could not save renamed file"; return end
			local okDelete = pcall(Env.delfile, selectedPath)
			if not okDelete then
				pcall(Env.delfile, newPath)
				previewTitle.Text = "Could not remove the original file; rename cancelled"
				return
			end
			selectedPath, selectedName = newPath, newName
			previewTitle.Text = newName .. "  ·  renamed"
			refreshFiles()
			showFile(newPath)
		end)
		refreshBtn.button.Activated:Connect(refreshFiles)
		refreshFiles()
	end
	do
		local order = 0
		local function settingRow(iconName, text)
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, text, 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -88, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			return r
		end
		local function toggleRow(iconName, text, initVal, onChange)
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, text, 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -88, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(r, initVal, onChange)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
			return r, tg
		end
		local function warnLabel(r, text, width)
			label(r, text, 9, Color3.fromRGB(220, 160, 60), Enum.Font.Gotham, {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0),
				Size = UDim2.new(0, width, 0, 12), TextXAlignment = Enum.TextXAlignment.Right,
			})
		end
		do
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, "Fast Mode", 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -88, 0, 18),
			})
			label(r, "Recommend this", 9, Color3.fromRGB(100, 200, 120), Enum.Font.Gotham, {
				Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -88, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(r, Config.FastMode or false, function(v)
				Config.FastMode = v
			end)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
		end
		do
			order += 1
			local r = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = order, Parent = pSettings,
			})
			corner(r, 8); stroke(r, C.border)
			label(r, "Fast Save", 14, C.text, Enum.Font.GothamSemibold, {
				Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -88, 0, 18),
			})
			label(r, "Not Recommend", 9, Color3.fromRGB(220, 90, 90), Enum.Font.Gotham, {
				Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -88, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local tg = mkToggle(r, false, function(v)
				Config.FastSave = v
			end)
			tg.track.AnchorPoint = Vector2.new(1, 0.5)
			tg.track.Position = UDim2.new(1, -12, 0.5, 0)
		end
		toggleRow("radio", "Enable Live Hooks", Config.EnableLiveHooks, function(v) Config.EnableLiveHooks = v end)
		do
			local inSupported = has("hookfunction") and has("getcallbackvalue")
			local r = toggleRow("arrow-down-left", "Incoming Hooks", Config.EnableIncomingHooks or false, function(v)
				if not inSupported and v then
					notify("Incoming Hooks", "hookfunction ou getcallbackvalue ausente. RemoteFunction não será capturada. Apenas RemoteEvent via Connect estará disponível.", 6)
				end
				Config.EnableIncomingHooks = v
			end)
			if not inSupported then warnLabel(r, "⚠ hookfunction missing — Events only", 180) end
		end
		do
			local raknetSupported = has("hookmetamethod") or has("hookfunction")
			local r, tg
			r, tg = toggleRow("wifi", "RakNet Analysis", false, function(v)
				if not raknetSupported and v then
					notify("RakNet Analysis", "Executor não suportado (hookmetamethod/hookfunction ausente). Analysis desativada.", 5)
					tg.set(false, true)
					return
				end
				Config.EnableRakNetAnalysis = v
			end)
			if not raknetSupported then warnLabel(r, "⚠ unsupported executor", 160) end
		end
		toggleRow("sliders", "Skip Optional Executor Checks",
			ExecutorSupport.GetSetting("DisableNonEssentialChecks", false) == true,
			function(v) ExecutorSupport.SetSetting("DisableNonEssentialChecks", v) end)
		numBox(settingRow("clock", "Soak Duration (s)"),
			Config.SoakSeconds, 0, 60, function(n) Config.SoakSeconds = n end)
		numBox(settingRow("repeat", "Max Decompile Retries"),
			Config.MaxRetries, 0, 10, function(n) Config.MaxRetries = n end)
		toggleRow("shield-off", "Skip Script Content",
			Config.SkipAllScriptContent or false, function(v) Config.SkipAllScriptContent = v end)
		toggleRow("shield", "Skip Roblox Scripts",
			false, function(v) Config.SkipRobloxScripts = v end)
		numBox(settingRow("move", "UI Scale (%)"), 80, 60, 130, function(n)
			scaleObj.Scale = n / 100
			applySize(); place(posX, posY)
		end)
	end
	do
		local creditRow = inst("Frame", {
			Size = UDim2.new(1, 0, 0, 62),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			Parent = pAbout,
		})
		hList(creditRow, 8)
		local function mkCreditBtn(parent, mainLabel, subLabel, iconName, lo)
			local card = inst("TextButton", {
				Text = "", AutoButtonColor = false,
				Size = UDim2.new(0.5, -4, 0, 62),
				BackgroundColor3 = C.card,
				BorderSizePixel = 0, LayoutOrder = lo, Parent = parent,
			})
			corner(card, 10)
			local st = stroke(card, C.border)
			mkIcon(card, iconName, 18, C.textDim, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 14, 0.5, 0),
			})
			label(card, mainLabel, 13, C.textHi, Enum.Font.GothamBold, {
				Position = UDim2.new(0, 42, 0, 13),
				Size = UDim2.new(1, -50, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			label(card, subLabel, 9, C.textDim, Enum.Font.Gotham, {
				Position = UDim2.new(0, 42, 0, 34),
				Size = UDim2.new(1, -50, 0, 13),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			card.MouseEnter:Connect(function()
				tween(card, { BackgroundColor3 = C.cardHover })
				tween(st, { Color = C.borderHi })
			end)
			card.MouseLeave:Connect(function()
				tween(card, { BackgroundColor3 = C.card })
				tween(st, { Color = C.border })
			end)
			return card
		end
		local _cobaltLoaded = false
		local _infiniteYieldLoaded = false
		local cobaltBtn = mkCreditBtn(creditRow, "Cobalt Spy", "Remote event inspector", "wifi", 0)
		cobaltBtn.Activated:Connect(function()
			if _cobaltLoaded then return end
			_cobaltLoaded = true
			task.spawn(function()
				local ok, err = pcall(function()
					loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))()
				end)
				if not ok then
					_cobaltLoaded = false
					warn("[DumpExplorer] Cobalt: erro ao executar —", tostring(err))
				end
			end)
		end)
		local iyBtn = mkCreditBtn(creditRow, "Infinity Yield", "Command console", "terminal", 1)
		iyBtn.Activated:Connect(function()
			if _infiniteYieldLoaded then return end
			_infiniteYieldLoaded = true
			task.spawn(function()
				local ok, err = pcall(function()
					loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
				end)
				if not ok then
					_infiniteYieldLoaded = false
					warn("[DumpExplorer] Infinite Yield: erro ao executar —", tostring(err))
				end
			end)
		end)
	end
	local dragging, dragInput, dragStart, startX, startY = false, nil, nil, 0, 0
	dragArea.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startX, startY = posX, posY
			if t == Enum.UserInputType.Touch then dragInput = input end
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if c then c:Disconnect() end
				end
			end)
		end
	end)
	dragArea.InputChanged:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then dragInput = input end
	end)
	track(UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			place(startX + d.X, startY + d.Y)
		end
	end))
	track(UIS.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then dragging = false end
	end))
	track(screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applySize(); place(posX, posY)
	end))
	applySize()
	do
		local vs, s = viewport(), scaleObj.Scale
		local saved = posStore().__DumpExplorerPos
		local centered = false
		if type(saved) == "table" and type(saved.x) == "number" and type(saved.y) == "number" then
			local minVisible = 60
			if saved.x + curW * s > minVisible and saved.x < vs.X - minVisible
				and saved.y >= 0 and saved.y < vs.Y - 20 then
				place(saved.x, saved.y)
				centered = true
			end
		end
		if not centered then
			place((vs.X - curW * s) / 2, (vs.Y - curH * s) / 2)
		end
	end
	switchTab("services")
	local FloatingToggle = inst("TextButton", {
		Name = "FloatingToggle", Text = "", AutoButtonColor = false,
		Size = UDim2.fromOffset(46, 46), AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0,
		ZIndex = 100, Visible = true, Parent = screen,
	})
	corner(FloatingToggle, 14)
	inst("UIStroke", { Color = Color3.fromRGB(48, 48, 48), Thickness = 1.2, Transparency = 0.12, Parent = FloatingToggle })
	if LOGO_IMAGE and LOGO_IMAGE ~= "" then
		inst("ImageLabel", {
			Name = "CenteredLogo", Size = UDim2.fromOffset(34, 34),
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1, Image = LOGO_IMAGE, ScaleType = Enum.ScaleType.Fit,
			ZIndex = 101, Parent = FloatingToggle,
		})
	else
		inst("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "D",
			Font = Enum.Font.GothamBold, TextSize = 22,
			TextColor3 = Color3.fromRGB(245, 245, 245), ZIndex = 101, Parent = FloatingToggle,
		})
	end
	FloatingToggle.Activated:Connect(function()
		win.Visible = not win.Visible
	end)
	FloatingToggle.MouseEnter:Connect(function()
		tween(FloatingToggle, { Size = UDim2.fromOffset(50, 50), BackgroundColor3 = Color3.fromRGB(12, 12, 12) }, 0.12)
	end)
	FloatingToggle.MouseLeave:Connect(function()
		tween(FloatingToggle, { Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.fromRGB(0, 0, 0) }, 0.12)
	end)
	task.spawn(function()
		local lastPct = -1
		while screen and screen.Parent and not State.Cancelled do
			local R = UIState.refs
			if R.mTotal then R.mTotal.Text = tostring(State.Total) end
			if R.mOk then R.mOk.Text = tostring(State.Success) end
			if R.mFail then R.mFail.Text = tostring(State.Failed) end
			local rc = 0
			for _ in pairs(State.Remotes) do rc += 1 end
			if R.mRemotes then R.mRemotes.Text = tostring(rc) end
			local pct = math.floor(UIState.pct)
			if pct ~= lastPct then
				lastPct = pct
				local size = UDim2.fromScale(pct / 100, 1)
				tween(R.pFill, { Size = size }, 0.18)
				tween(R.runBar, { Size = size }, 0.18)
				R.pPct.Text = pct .. "%"
				R.runPct.Text = pct .. "%" .. (UIState.pctLabel ~= "" and ("  ·  " .. UIState.pctLabel) or "")
			end
			if UIState.running and State.StartTime then
				local el = tick() - State.StartTime
				local mm = math.floor(el / 60)
				local ss = math.floor(el % 60)
				local timeStr = string.format("%02d:%02d", mm, ss)
				local queueStr = (Config.FastSave and WriteQueue.pending > 0)
					and ("  ·  queue:" .. WriteQueue.pending) or ""
				R.phaseLbl.Text = "Phase: " .. UIState.phase .. "  ·  " .. timeStr .. queueStr
			elseif UIState.finished and State.StartTime then
				local el = tick() - State.StartTime
				R.phaseLbl.Text = string.format("Done in %02d:%02d", math.floor(el/60), math.floor(el%60))
			else
				R.phaseLbl.Text = ""
			end
			statusDot.ImageColor3 = UIState.running and C.yellow or (UIState.finished and C.green or C.gray)
			task.wait(0.2)
		end
	end)
	uiLog("Dump Explorer ready. Select services and press Run.", C.logOk)
	if Lucide then
		uiLog("Lucide icons loaded from " .. (tostring(lucideSource):match("//([^/]+/[^/]+)") or "source"), C.logOk)
	else
		uiLog("Lucide icons unavailable (" .. tostring(lucideError) .. "). Using text fallback.", C.logWarn)
	end
	local missing = {}
	for name in pairs(missingIcons) do missing[#missing + 1] = name end
	if #missing > 0 then
		table.sort(missing)
		uiLog("Icons using text fallback: " .. table.concat(missing, ", "), C.logWarn)
	end
	return screen
end
local _origPS = processService
local _svcTotal = #Config.ServiceList
local _svcDone = 0
local _origPO = processObject
local _poCounter = 0
processObject = function(obj, serviceName, serviceRoot)
	_poCounter += 1
	if _poCounter % 15 == 0 then
		local basePct = math.floor((_svcDone / math.max(_svcTotal, 1)) * 65) + 10
		local nextPct = math.floor(((_svcDone + 1) / math.max(_svcTotal, 1)) * 65) + 10
		local slot = nextPct - basePct
		local svcTotal = State.Total > 0 and State.Total or 1
		local intraPct = math.min((_poCounter % 500) / math.max(slot * 7, 1), 1)
		setProgress(basePct + math.floor(intraPct * slot), serviceName)
	end
	return _origPO(obj, serviceName, serviceRoot)
end
processService = function(svcName)
	_svcDone += 1
	_poCounter = 0
	UIState.phase = "scan:" .. svcName
	setStatus("Scanning " .. svcName .. "...", C.yellow)
	setProgress(math.floor(((_svcDone - 1) / math.max(_svcTotal, 1)) * 65) + 10, svcName)
	_origPS(svcName)
	setProgress(math.floor((_svcDone / math.max(_svcTotal, 1)) * 65) + 10, svcName)
end
local _origMain = main
main = function()
	_svcTotal = #Config.ServiceList; _svcDone = 0
	UIState.phase = "unc"; setProgress(0, "UNC analysis")
	setStatus("Running UNC analysis...", C.yellow)
	_origMain()
	UIState.phase = "done"; setProgress(100, "Complete")
	setStatus("Done — " .. Config.MainFolder, C.green)
end
task.spawn(function()
	local stStore = Hook.defaultStore()
	if Config.SelfTest or (stStore and stStore.__DUMP_SELFTEST == true) then
		local okS, errS = pcall(SelfTest.run)
		if not okS then warn("[DumpExplorer] SelfTest failed to run: " .. tostring(errS)) end
	end
	local okL, errL = pcall(Lifecycle.boot)
	if not okL then warn("[DumpExplorer] Lifecycle.boot failed: " .. tostring(errL)) end
	local okF, errF = pcall(createAllFolders)
	if not okF then warn("[DumpExplorer] Failed to create folders: " .. tostring(errF)) end
	local okB, errB = pcall(buildUI)
	if not okB then warn("[DumpExplorer] UI failed to build: " .. tostring(errB)) end
end)
end
