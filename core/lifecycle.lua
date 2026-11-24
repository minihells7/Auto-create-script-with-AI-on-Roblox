local Lifecycle = {}
function Lifecycle.add(fn)
	if type(fn) == "function" then State.Cleanups[#State.Cleanups + 1] = fn end
end
function Lifecycle.shutdown(reason)
	if State.ShuttingDown then return end
	State.ShuttingDown = true
	State.Cancelled = true
	for i = #State.Cleanups, 1, -1 do pcall(State.Cleanups[i]) end
	State.Cleanups = {}
	if State.HooksInstalled or State.RunId then pcall(uninstallHooks) end
	if _DescConn then pcall(function() _DescConn:Disconnect() end); _DescConn = nil end
	local store = Hook.defaultStore()
	if store and store.__DumpExplorerCleanup == Lifecycle.handle then store.__DumpExplorerCleanup = nil end
	if store and store.__DumpExplorerState == State then store.__DumpExplorerState = nil end
	pcall(writeLog, "Session cleaned (" .. tostring(reason or "?") .. ")")
end
function Lifecycle.boot()
	local store = Hook.defaultStore()
	if not store then return end
	local prev = store.__DumpExplorerCleanup
	if type(prev) == "function" then pcall(prev, "reexecution") end
	Lifecycle.handle = function(reason) Lifecycle.shutdown(reason or "external") end
	store.__DumpExplorerCleanup = Lifecycle.handle
	if Config.ExposeDebugHandle then store.__DumpExplorerState = State end
end
local function cancelPoint()
	if State.Cancelled then error("DumpExplorer cancelled", 0) end
end
