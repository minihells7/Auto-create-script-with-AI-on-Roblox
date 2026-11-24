if _G.DUMP_EXPLORER_LOADED and not _G.DUMP_EXPLORER_DEBUG then
	return
end
pcall(function() getgenv().DUMP_EXPLORER_LOADED = true end)

if not game:IsLoaded() then game.Loaded:Wait() end

