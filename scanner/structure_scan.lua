local function structurePrepareCounts(root)
	local descendants = structureSafe(function() return root:GetDescendants() end, {})
	for _, descendant in ipairs(descendants) do
		local current = structureSafe(function() return descendant.Parent end, nil)
		while current and current ~= root do
			StructureState.descendantCounts[current] = (StructureState.descendantCounts[current] or 0) + 1
			current = structureSafe(function() return current.Parent end, nil)
		end
	end
	StructureState.descendantCounts[root] = #descendants
end
local function structureAddObject(instance)
	local attrs, attrOutput = structureGetAttributes(instance), {}
	local fullName = structureSafe(function() return instance:GetFullName() end, tostring(instance))
	local name = structureSafe(function() return instance.Name end, "?")
	local className = structureSafe(function() return instance.ClassName end, "?")
	for attrName, value in pairs(attrs) do
		local encoded = structureEncode(value)
		attrOutput[attrName] = encoded
		StructureState.attributes[#StructureState.attributes + 1] = {
			name=attrName, value=encoded, object=name, className=className,
			service=structureServiceName(instance), path=fullName,
		}
	end
	local parent = structureSafe(function() return instance.Parent end, nil)
	local props = structureProperties(instance)
	local propNames = {}
	for k in pairs(props) do propNames[#propNames+1] = k end
	table.sort(propNames)
	local record = {
		name=name, className=className, fullName=fullName,
		parent=parent and structureSafe(function() return parent:GetFullName() end, "?") or "nil",
		service=structureServiceName(instance), attributes=attrOutput,
		tags=structureGetTags(instance),
		descendantCount=StructureState.descendantCounts[instance] or 0,
		properties=props,
		propCount=#propNames,
		propNames=propNames,
	}
	StructureState.objects[#StructureState.objects + 1] = record
	return record
end
local function structureServiceRoots()
	local names = {
		"Workspace","ReplicatedStorage","ReplicatedFirst","ServerStorage",
		"ServerScriptService","StarterGui","StarterPack","StarterPlayer",
		"Players","Lighting","SoundService","Teams","TextChatService",
		"Chat","CollectionService","PhysicsService","MaterialService",
	}
	local roots, seen = {}, {}
	for _, name in ipairs(names) do
		local service = safeGetService(name)
		if service and not seen[service] then
			seen[service] = true
			roots[#roots + 1] = service
		end
	end
	return roots
end
