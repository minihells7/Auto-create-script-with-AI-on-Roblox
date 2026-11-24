local function runIntegratedStructureDump()
	createFolderRecursive(StructurePaths.RemoteFolder)
	local ok, err = pcall(function()
		if StructureConfig.IncludeWorkspaceTree then structureScanWorkspace() end
		structureScanObjectsAndRemotes()
		structureWriteReports()
	end)
	if not ok then
		StructureState.errors[#StructureState.errors + 1] = "General failure: " .. tostring(err)
		pcall(structureWrite, StructurePaths.Errors, table.concat(StructureState.errors, "\n"))
		writeLog("[WARN] Structural inventory: " .. tostring(err))
	else
		writeLog(string.format("Structural inventory completed | objects=%d | attributes=%d | errors=%d",
			#StructureState.objects, #StructureState.attributes, #StructureState.errors))
	end
end
