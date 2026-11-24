local function structureWriteReports()
	table.sort(StructureState.attributes, function(a,b)
		if a.path == b.path then return a.name < b.name end
		return a.path < b.path
	end)
	local attrLines = {
		"GAME ATTRIBUTES",
		"Generated at: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"Total attributes: " .. #StructureState.attributes,
		string.rep("=", 80), "",
	}
	for _, item in ipairs(StructureState.attributes) do
		attrLines[#attrLines + 1] = "-- ATTRIBUTE FOUND"
		attrLines[#attrLines + 1] = "Object: " .. item.object
		attrLines[#attrLines + 1] = "Class: " .. item.className
		attrLines[#attrLines + 1] = "Service: " .. item.service
		attrLines[#attrLines + 1] = "Path: " .. item.path
		attrLines[#attrLines + 1] = string.format('GetAttribute(%q) -- %s: %s',
			item.name, item.value.type, structureReadable(item.value.value))
		attrLines[#attrLines + 1] = string.rep("-", 80)
	end
	structureWrite(StructurePaths.Attributes, table.concat(attrLines, "\n"))
	local eventLines, functionLines, unreliableLines = {"REMOTE EVENTS",""}, {"REMOTE FUNCTIONS",""}, {"UNRELIABLE REMOTE EVENTS",""}
	local indexLines = {"REMOTE INDEX","Passive inventory; discovery does not mean the call was executed.",""}
	local remoteRows = {}
	for path, data in pairs(State.Remotes) do
		remoteRows[#remoteRows + 1] = {
			name=structureSafe(function() return data.instance.Name end, "?"),
			className=data.className, path=data.fullPath,
			service=structureServiceName(data.instance),
			direction=(data.className == "BindableEvent" or data.className == "BindableFunction")
				and "Local communication" or "Client-server remote",
			observation="Found in scan; calls not monitored",
			outCalls=data.outCalls, inCalls=data.inCalls,
		}
	end
	table.sort(remoteRows, function(a,b) return a.path < b.path end)
	for _, remote in ipairs(remoteRows) do
		local target = eventLines
		if remote.className == "RemoteFunction" then target = functionLines
		elseif remote.className == "UnreliableRemoteEvent" then target = unreliableLines end
		target[#target + 1] = remote.name .. " [" .. remote.className .. "]"
		target[#target + 1] = "Service: " .. remote.service
		target[#target + 1] = "Path: " .. remote.path
		target[#target + 1] = "Status: found in scan; calls not monitored"
		target[#target + 1] = string.rep("-", 70)
		indexLines[#indexLines + 1] = string.format("%s | %s | %s | %s",
			remote.className, remote.name, remote.service, remote.path)
	end
	structureWrite(StructurePaths.RemoteEvents, table.concat(eventLines, "\n"))
	structureWrite(StructurePaths.RemoteFunctions, table.concat(functionLines, "\n"))
	structureWrite(StructurePaths.Unreliable, table.concat(unreliableLines, "\n"))
	structureWrite(StructurePaths.RemoteIndex, table.concat(indexLines, "\n"))
	structureWrite(StructurePaths.ObjectsJson, structureJson({
		generatedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
		count=#StructureState.objects, objects=StructureState.objects,
	}))
	structureWrite(StructurePaths.AttributesJson, structureJson({
		generatedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
		count=#StructureState.attributes, attributes=StructureState.attributes,
	}))
	structureWrite(StructurePaths.RemotesJson, structureJson({
		generatedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
		count=#remoteRows, remotes=remoteRows,
	}))
	structureWrite(StructurePaths.Errors,
		#StructureState.errors > 0 and table.concat(StructureState.errors, "\n") or "No errors recorded.")
	structureWrite(StructurePaths.Checkpoint, structureJson({
		phase="Completed", processed=StructureState.processed,
		objects=#StructureState.objects, attributes=#StructureState.attributes,
		remotes=#remoteRows, errors=#StructureState.errors, completedAt=os.time(),
	}))
end
