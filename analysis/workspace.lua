local function describeItem(obj)
	local lines = {}
	local okIsA, isPart = pcall(function() return obj:IsA("BasePart") end)
	table.insert(lines, string.format("    Item: %s (%s) Part=%s", obj.Name, obj.ClassName, tostring(okIsA and isPart)))
	local okCh, children = pcall(function() return obj:GetChildren() end)
	if okCh then
		for _, child in ipairs(children) do
			if child:IsA("LuaSourceContainer") or child:IsA("Tool") then
				table.insert(lines, string.format("      - %s (%s)", child.Name, child.ClassName))
			end
		end
	end
	local okA, attrs = pcall(function() return obj:GetAttributes() end)
	if okA and attrs then
		for k, v in pairs(attrs) do
			table.insert(lines, string.format("      attr %s = %s", k, tostring(v)))
		end
	end
	return lines
end
local function generateWorkspaceReport()
	local ok, ws = pcall(safeGetService, "Workspace")
	if not ok or not ws then return end
	local okCh, children = pcall(function() return ws:GetChildren() end)
	if not okCh then return end
	local lines = { "WORKSPACE:", "" }
	local counter = 0
	for _, child in ipairs(children) do
		if child:IsA("Folder") or child:IsA("Model") then
			table.insert(lines, child.Name .. ":")
			local okI, items = pcall(function() return child:GetChildren() end)
			if okI then
				for _, item in ipairs(items) do
					table.insert(lines, "  - " .. item.Name)
					for _, l in ipairs(describeItem(item)) do table.insert(lines, l) end
					counter += 1
					if counter % Config.YieldEvery == 0 then task.wait(); cancelPoint() end
				end
			end
			table.insert(lines, "")
		end
	end
	writeFileSafe(Config.MainFolder .. "/Workspace Structure.txt", table.concat(lines, "\n"))
	writeLog("Workspace structure saved.")
end
local GuiProps = {
	Common = { "Visible","Position","Size","BackgroundColor3","BackgroundTransparency","ZIndex","LayoutOrder" },
	TextLabel = { "Text","TextColor3","TextSize","Font","TextWrapped","RichText" },
	TextButton = { "Text","TextColor3","TextSize","Font" },
	ImageLabel = { "Image","ImageColor3","ImageTransparency" },
	ImageButton = { "Image","ImageColor3" },
	ScreenGui = { "Enabled","IgnoreGuiInset","DisplayOrder","ZIndexBehavior" },
}
local function readGuiProps(obj)
	local lines = {}
	local function readSet(set)
		for _, prop in ipairs(set) do
			local ok, v = pcall(function() return obj[prop] end)
			if ok then table.insert(lines, prop .. "=" .. tostring(v)) end
		end
	end
	readSet(GuiProps.Common)
	if GuiProps[obj.ClassName] then readSet(GuiProps[obj.ClassName]) end
	return lines
end
local walkGui
walkGui = function(obj, depth, lines, ys)
	local indent = string.rep("  ", depth)
	local isScript = obj:IsA("LuaSourceContainer")
	table.insert(lines, string.format("%s- %s (%s)", indent, obj.Name, obj.ClassName))
	if isScript then
		table.insert(lines, indent .. "    [Script — dump at " .. Config.MainFolder .. "/]")
		return
	end
	for _, l in ipairs(readGuiProps(obj)) do
		table.insert(lines, indent .. "    " .. l)
	end
	local ok, ch = pcall(function() return obj:GetChildren() end)
	if ok then
		for _, child in ipairs(ch) do
			walkGui(child, depth + 1, lines, ys)
			ys.n += 1
			if ys.n % Config.YieldEvery == 0 then task.wait(); cancelPoint() end
		end
	end
end
local function generatePlayerGuiReport()
	local root = resolveServiceRoot("PlayerGui")
	if not root then return end
	local ok, ch = pcall(function() return root:GetChildren() end)
	if not ok then return end
	local lines = { "PLAYERGUI:", "" }
	local ys = { n = 0 }
	for _, sg in ipairs(ch) do
		walkGui(sg, 0, lines, ys)
		table.insert(lines, "")
	end
	writeFileSafe(Config.MainFolder .. "/PlayerGui Structure.txt", table.concat(lines, "\n"))
	writeLog("PlayerGui structure saved.")
end
