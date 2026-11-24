local function structureWrite(path, content)
	content = tostring(content or "")
	if #content > StructureConfig.MaxTextBytes then
		error("File exceeded the configured limit: " .. path)
	end
	if not writeFileSafe(path, content) then error("Failed to write: " .. path) end
end
