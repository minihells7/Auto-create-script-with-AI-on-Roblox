local Hook = { SCHEMA = 1, reg = nil }
function Hook.defaultStore()
	if typeof(getgenv) ~= "function" then return nil end
	local ok, g = pcall(getgenv)
	if ok and type(g) == "table" then return g end
	return nil
end
function Hook.newOwner()
	return tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
end
local function hookNewReg(owner)
	return {
		schema = Hook.SCHEMA, target = "game.__namecall",
		original = nil, observer = nil, owner = owner, state = "installing",
		installs = 0, swaps = 0, errors = 0,
		earlyCalls = 0, tamperCalls = 0,
		methodErrors = 0, observerErrors = 0, restoreErrors = 0, consecRestoreErrors = 0,
		tripped = false, reason = nil, hasSetMethod = false,
		maxObserverErrors = 100,
		canaryOk = false, canarySeq = 0,
		canaryExpected = nil, canaryConfirmed = nil, canaryTarget = nil,
	}
end
local function hookInstrument(REG, obs, getm, setm, self, ...)
	local okM, m = pcall(getm)
	if not (okM and type(m) == "string") then
		REG.methodErrors = REG.methodErrors + 1
		REG.errors = REG.errors + 1
		return
	end
	local okO, did = pcall(obs, self, m, ...)
	if not okO then
		REG.observerErrors = REG.observerErrors + 1
		REG.errors = REG.errors + 1
		if REG.observerErrors > REG.maxObserverErrors then
			REG.observer = nil
			REG.tripped = true
			REG.reason = "observer_errors"
		end
	end
	if setm and ((not okO) or did) then
		if pcall(setm, m) then
			REG.consecRestoreErrors = 0
		else
			REG.restoreErrors = REG.restoreErrors + 1
			REG.consecRestoreErrors = REG.consecRestoreErrors + 1
			REG.errors = REG.errors + 1
			if REG.consecRestoreErrors >= 3 then
				REG.observer = nil
				REG.tripped = true
				REG.reason = "restore_errors"
			end
		end
	end
end
local function hookCountMissing(REG)
	if REG.state == "installing" then
		REG.earlyCalls = REG.earlyCalls + 1
	else
		REG.tamperCalls = REG.tamperCalls + 1
	end
end
function Hook.makeTrampoline(REG, getm, setm)
	return function(self, ...)
		local orig = REG.original
		if orig == nil then
			pcall(hookCountMissing, REG)
			return
		end
		local obs = REG.observer
		if obs then
			pcall(hookInstrument, REG, obs, getm, setm, self, ...)
		end
		return orig(self, ...)
	end
end
function Hook.makeObserver(REG, ring, outgoing)
	local function getClass(o) return o.ClassName end
	local function getName(o) return o.Name end
	local function findCaller()
		local own = debug.info(1, "s")
		for level = 2, 10 do
			local s = debug.info(level, "s")
			if s == nil then break end
			if s ~= "[C]" and s ~= own then return s end
		end
		return nil
	end
	return function(self, m, ...)
		if REG.canaryExpected ~= nil and m == "Fire" and self == REG.canaryTarget then
			local okN, nm = pcall(getName, self)
			if okN and nm == REG.canaryExpected then REG.canaryConfirmed = nm end
			return true
		end
		local byClass = outgoing[m]
		if not byClass then return end
		local okC, cn = pcall(getClass, self)
		if not (okC and cn and byClass[cn]) then return end
		local caller = "?"
		local okF, src = pcall(findCaller)
		if okF and type(src) == "string" then caller = src end
		Ring.push(ring, { instance = self, caller = caller, args = table.pack(...) })
		return true
	end
end
local function hookCanaryFail(REG, myOwner, obs, id, reason)
	if REG.canaryExpected == id then
		REG.canaryExpected = nil
		REG.canaryTarget = nil
	end
	if REG.owner ~= myOwner then
		return false, reason .. " (superseded)"
	end
	REG.observer = nil
	REG.canaryOk = false
	REG.state = "failed"
	REG.reason = reason
	return false, reason
end
local function hookCanaryInner(REG, obs, o)
	local timeout = o.canaryTimeout or Config.CanaryTimeoutSeconds
	local waitf = o.wait or task.wait
	local newTarget = o.newCanaryTarget or function(id)
		local t = Instance.new("BindableEvent")
		t.Name = id
		return t
	end
	local fire = o.fireCanary or function(t, id) t:Fire(id) end
	local myOwner = REG.owner
	REG.canarySeq = REG.canarySeq + 1
	local id = tostring(myOwner) .. ":" .. tostring(REG.canarySeq)
	REG.canaryConfirmed = nil
	REG.canaryExpected = id
	local okT, target = pcall(newTarget, id)
	if not okT or target == nil then
		return hookCanaryFail(REG, myOwner, obs, id, "canary_failed (target)")
	end
	REG.canaryTarget = target
	REG.observer = obs
	pcall(fire, target, id)
	local t0 = os.clock()
	while REG.canaryConfirmed ~= id and (os.clock() - t0) < timeout do
		waitf()
	end
	local confirmed = (REG.canaryConfirmed == id)
	if REG.canaryExpected == id then
		REG.canaryExpected = nil
		REG.canaryTarget = nil
	end
	pcall(function() target:Destroy() end)
	if confirmed then
		REG.canaryOk = true
		return true
	end
	return hookCanaryFail(REG, myOwner, obs, id, "canary_failed")
end
function Hook.runCanary(REG, obs, o)
	local myOwner = REG.owner
	local ok, res, why = pcall(hookCanaryInner, REG, obs, o)
	if ok then return res, why end
	REG.canaryExpected = nil
	REG.canaryTarget = nil
	if REG.owner == myOwner then
		REG.observer = nil
		REG.canaryOk = false
		REG.state = "failed"
		REG.reason = "canary_error: " .. tostring(res)
	end
	return false, "canary_error: " .. tostring(res)
end
function Hook.engage(opts)
	local o = opts or {}
	local store
	if o.store == false then store = nil
	elseif o.store then store = o.store
	else store = Hook.defaultStore() end
	if not store then return false, "no_persistent_store" end
	local hookmeta = o.hookmeta or Env.hookmetamethod
	local getm = o.getm or Env.getnamecallmethod
	local setm
	if o.setm == false then setm = nil
	elseif o.setm then setm = o.setm
	elseif typeof(Env.setnamecallmethod) == "function" then setm = Env.setnamecallmethod end
	if typeof(hookmeta) ~= "function" or typeof(getm) ~= "function" then
		return false, "hookmetamethod/getnamecallmethod unavailable"
	end
	if not o.ring then return false, "no_ring" end
	local owner = o.owner or Hook.newOwner()
	local outgoing = o.outgoing or OutgoingMethods
	local target = o.target or game
	local REG = store.__DUMP_HOOK
	local mode
	if REG == nil then
		REG = hookNewReg(owner)
		REG.maxObserverErrors = o.maxObserverErrors or Config.HookMaxObserverErrors
		REG.hasSetMethod = (setm ~= nil)
		store.__DUMP_HOOK = REG
		Hook.reg = REG
		local tramp = Hook.makeTrampoline(REG, getm, setm)
		local ok, res = pcall(hookmeta, target, "__namecall", tramp)
		if ok and typeof(res) == "function" then
			REG.original = res
			REG.state = "ready"
			REG.installs = 1
		else
			REG.state = "failed"
			REG.reason = ok and "hookmetamethod_returned_non_function"
				or ("hookmetamethod_failed: " .. tostring(res))
			if ok then
				pcall(writeLog, "[ERROR] hookmetamethod returned a non-function: __namecall may be left without an original until rejoin. Do not use Live Hooks with this executor.")
			end
			return false, REG.reason
		end
		mode = "installed"
	else
		if type(REG) ~= "table" then return false, "invalid_registry" end
		if REG.schema ~= Hook.SCHEMA then
			return false, "schema_mismatch (registry=" .. tostring(REG.schema)
				.. " expected=" .. tostring(Hook.SCHEMA) .. ") - rejoin required"
		end
		if REG.state ~= "ready" then
			return false, "registry_state_" .. tostring(REG.state) .. " - rejoin required"
		end
		if REG.original == nil then return false, "invalid_registry (original missing)" end
		Hook.reg = REG
		REG.swaps = REG.swaps + 1
		REG.observerErrors = 0
		REG.consecRestoreErrors = 0
		REG.tripped = false
		REG.reason = nil
		REG.maxObserverErrors = o.maxObserverErrors or Config.HookMaxObserverErrors
		mode = "swapped"
	end
	REG.owner = owner
	local obs = Hook.makeObserver(REG, o.ring, outgoing)
	local okCan, why = Hook.runCanary(REG, obs, o)
	if not okCan then return false, why end
	return true, mode
end
function Hook.detach(owner)
	local REG = Hook.reg
	if not REG then return false end
	if owner ~= nil and REG.owner ~= owner then return false end
	REG.observer = nil
	return true
end
function Hook.statsLine(ring)
	local R = Hook.reg
	local q = ring or { count = 0, pushed = 0, dropped = 0, popped = 0, cleared = 0 }
	return string.format(
		"count=%d pushed=%d dropped=%d popped=%d cleared=%d | earlyCalls=%d tamperCalls=%d swaps=%d installs=%d errors=%d tripped=%s",
		q.count, q.pushed, q.dropped, q.popped, q.cleared,
		R and R.earlyCalls or 0, R and R.tamperCalls or 0, R and R.swaps or 0,
		R and R.installs or 0, R and R.errors or 0, tostring(R and R.tripped or false))
end
