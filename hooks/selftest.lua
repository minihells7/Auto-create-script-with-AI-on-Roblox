local SelfTest = { results = {}, failed = 0, passed = 0 }
local function stCheck(name, cond, detail)
	if cond then
		SelfTest.passed = SelfTest.passed + 1
		SelfTest.results[#SelfTest.results + 1] = "PASS " .. name
	else
		SelfTest.failed = SelfTest.failed + 1
		SelfTest.results[#SelfTest.results + 1] = "FAIL " .. name .. (detail and (" | " .. tostring(detail)) or "")
	end
end
function SelfTest.ring()
	local r = Ring.new(4)
	stCheck("ST-05.new: invariante", Ring.invariantOk(r) and r.count == 0)
	for i = 1, 4 do Ring.push(r, i); stCheck("ST-05.fill " .. i .. ": invariante", Ring.invariantOk(r)) end
	stCheck("ST-05.capacidade: count==cap", r.count == 4 and r.dropped == 0)
	for i = 5, 7 do
		local acc = Ring.push(r, i)
		stCheck("ST-05.overflow " .. i .. ": rejeita (descarta o novo)", acc == false and Ring.invariantOk(r))
	end
	stCheck("ST-05.overflow: pushed=7 dropped=3 count=4", r.pushed == 7 and r.dropped == 3 and r.count == 4)
	local a, b = Ring.pop(r), Ring.pop(r)
	stCheck("ST-05.FIFO: 1,2", a == 1 and b == 2 and r.popped == 2 and Ring.invariantOk(r))
	Ring.push(r, 8); Ring.push(r, 9)
	stCheck("ST-05.wrap-around: invariante", Ring.invariantOk(r) and r.count == 4)
	local seq = {}
	while true do local x = Ring.pop(r); if x == nil then break end; seq[#seq + 1] = x end
	stCheck("ST-05.wrap-around: ordem 3,4,8,9", table.concat(seq, ",") == "3,4,8,9", table.concat(seq, ","))
	stCheck("ST-05.vazia: pop devolve nil", Ring.pop(r) == nil and Ring.invariantOk(r))
	local c = Ring.new(5)
	for i = 1, 8 do Ring.push(c, i) end
	Ring.pop(c)
	local pBefore, dBefore = c.pushed, c.dropped
	Ring.clear(c)
	stCheck("ST-05.clear: count=0, cleared=4", c.count == 0 and c.cleared == 4, c.cleared)
	stCheck("ST-05.clear: pushed/dropped preservados", c.pushed == pBefore and c.dropped == dBefore)
	stCheck("ST-05.clear: invariante", Ring.invariantOk(c))
	Ring.push(c, 100)
	stCheck("ST-05.pos-clear: aceita e devolve", c.count == 1 and Ring.pop(c) == 100 and Ring.invariantOk(c))
	Ring.clear(c)
	stCheck("ST-05.clear vazia: sem efeito", c.cleared == 4 and Ring.invariantOk(c))
	local one = Ring.new(1)
	Ring.push(one, "a"); local acc = Ring.push(one, "b")
	stCheck("ST-05.cap1: rejeita segundo", acc == false and Ring.pop(one) == "a" and Ring.invariantOk(one))
	local seed = 12345
	local function rnd(n) seed = (seed * 16807) % 2147483647; return seed % n end
	local q, model, ok = Ring.new(7), {}, true
	local mPushed, mDropped, mPopped, mCleared = 0, 0, 0, 0
	for step = 1, 2000 do
		local op = rnd(10)
		if op < 5 then
			mPushed = mPushed + 1
			if #model >= 7 then mDropped = mDropped + 1; Ring.push(q, step)
			else model[#model + 1] = step; Ring.push(q, step) end
		elseif op < 9 then
			local got = Ring.pop(q)
			local want = table.remove(model, 1)
			if want ~= nil then mPopped = mPopped + 1 end
			if got ~= want then ok = false end
		else
			mCleared = mCleared + #model; model = {}; Ring.clear(q)
		end
		if not Ring.invariantOk(q) or q.count ~= #model then ok = false end
	end
	stCheck("ST-05.modelo (2000 passos, semente fixa): FIFO, contadores e invariante",
		ok and q.pushed == mPushed and q.dropped == mDropped and q.popped == mPopped and q.cleared == mCleared)
end
local function stNewSim()
	local sim = { st = { method = nil }, calls = {}, getmCalls = 0, setmCalls = 0, hookCalls = 0 }
	sim.target = {
		__namecall = function(self, ...)
			sim.calls[#sim.calls + 1] = { self = self, method = sim.st.method, n = select("#", ...), args = table.pack(...) }
			return "r1", nil, "r3"
		end,
	}
	sim.hookmeta = function(tgt, name, fn)
		sim.hookCalls = sim.hookCalls + 1
		local orig = tgt[name]
		tgt[name] = fn
		return orig
	end
	sim.getm = function() sim.getmCalls = sim.getmCalls + 1; return sim.st.method end
	sim.setm = function(m) sim.setmCalls = sim.setmCalls + 1; sim.st.method = m end
	function sim.dispatch(self, method, ...)
		sim.st.method = method
		return sim.target.__namecall(self, ...)
	end
	sim.newCanaryTarget = function(id) return { ClassName = "BindableEvent", Name = id } end
	sim.fireCanary = function(t, id) sim.dispatch(t, "Fire", id) end
	return sim
end
local function stOpts(sim, store, ring, extra)
	local o = { store = store, hookmeta = sim.hookmeta, getm = sim.getm, setm = sim.setm,
				target = sim.target, ring = ring, outgoing = { Fire = { BindableEvent = true } },
				newCanaryTarget = sim.newCanaryTarget, fireCanary = sim.fireCanary,
				wait = function() end, canaryTimeout = 0.05, maxObserverErrors = 3 }
	if extra then for k, v in pairs(extra) do o[k] = v end end
	return o
end
local function stInst() return { ClassName = "BindableEvent", Name = "x" } end
function SelfTest.hook()
	local sim, store, ring = stNewSim(), {}, Ring.new(50)
	local ok, mode = Hook.engage(stOpts(sim, store, ring, { owner = "A" }))
	local R = store.__DUMP_HOOK
	stCheck("ST-07.1a primeira instalação: ok/installed", ok == true and mode == "installed", tostring(mode))
	stCheck("ST-07.1b estado ready, installs=1, hookmetamethod chamado 1x", R and R.state == "ready" and R.installs == 1 and sim.hookCalls == 1)
	stCheck("ST-07.1c canário confirmado com o id correto", R and R.canaryOk == true and R.canarySeq == 1 and R.canaryExpected == nil and R.canaryTarget == nil)
	stCheck("ST-07.1d earlyCalls==0", R and R.earlyCalls == 0)
	stCheck("ST-07.1e canário NÃO entrou na fila", ring.count == 0 and #sim.calls == 1, "calls=" .. #sim.calls)
	local callsBefore = #sim.calls
	local inst = stInst()
	local a, b, c, d = sim.dispatch(inst, "Fire", 1, nil, 3)
	stCheck("ST-07.2a original chamado exatamente 1x", #sim.calls == callsBefore + 1)
	local last = sim.calls[#sim.calls]
	stCheck("ST-07.2b args com nil preservados no original (n==3, [2]==nil)", last.n == 3 and last.args[1] == 1 and last.args[2] == nil and last.args[3] == 3)
	stCheck("ST-07.2c múltiplos retornos preservados (r1,nil,r3)", a == "r1" and b == nil and c == "r3" and d == nil)
	stCheck("ST-07.2d método de namecall preservado no original", last.method == "Fire")
	stCheck("ST-07.2e fila recebeu 1 item com args.n==3 e args[2]==nil", ring.count == 1)
	local item = Ring.pop(ring)
	stCheck("ST-07.2f item: instance/args.n/nil no meio", item and item.instance == inst and item.args.n == 3 and item.args[2] == nil)
	sim.dispatch(inst, "GetFullName")
	stCheck("ST-07.3 método fora da tabela: encaminha 1x, não enfileira", ring.count == 0 and sim.calls[#sim.calls].method == "GetFullName")
	local rings, ids = { ring }, { R.canarySeq }
	for i = 1, 3 do
		local nr = Ring.new(50)
		local ok2, mode2 = Hook.engage(stOpts(sim, store, nr, { owner = "B" .. i }))
		rings[#rings + 1] = nr
		ids[#ids + 1] = R.canarySeq
		stCheck("ST-07.4." .. i .. "a reexecução: swapped", ok2 == true and mode2 == "swapped", tostring(mode2))
	end
	stCheck("ST-07.4b installs continua 1; hookmetamethod ainda 1x; swaps==3", R.installs == 1 and sim.hookCalls == 1 and R.swaps == 3)
	stCheck("ST-07.4c ids de canário distintos e crescentes", ids[1] < ids[2] and ids[2] < ids[3] and ids[3] < ids[4])
	local cb = #sim.calls
	sim.dispatch(stInst(), "Fire", "x")
	stCheck("ST-07.4d após 3 trocas: original 1x, SÓ o anel novo recebe (sem empilhar)",
		#sim.calls == cb + 1 and rings[4].count == 1 and rings[3].count == 0 and rings[2].count == 0 and rings[1].count == 0)
	stCheck("ST-07.4e owner atualizado", R.owner == "B3")
	do
		local sm0 = sim.setmCalls
		sim.dispatch(inst, "GetFullName")
		local filteredCalls = sim.setmCalls - sm0
		sim.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.3b restauração só quando o observer fez trabalho (filtrado 0x, casado 1x)", filteredCalls == 0 and sim.setmCalls - sm0 == 1, filteredCalls .. "/" .. (sim.setmCalls - sm0))
	end
	stCheck("ST-07.5a detach de owner antigo é ignorado", Hook.detach("A") == false and R.observer ~= nil)
	stCheck("ST-07.5b detach do owner atual deixa inerte", Hook.detach("B3") == true and R.observer == nil)
	local gm, rc = sim.getmCalls, rings[4].count
	local cb2 = #sim.calls
	local x1, x2, x3 = sim.dispatch(stInst(), "Fire", 9)
	stCheck("ST-07.5c inerte: getnamecallmethod chamado 0x, nada enfileirado, original 1x, retornos intactos",
		sim.getmCalls == gm and rings[4].count == rc and #sim.calls == cb2 + 1 and x1 == "r1" and x2 == nil and x3 == "r3")
	local sim6 = stNewSim()
	local ok6, why6 = Hook.engage(stOpts(sim6, false, Ring.new(5)))
	stCheck("ST-07.6 sem getgenv: fail-closed, nada instalado", ok6 == false and why6 == "no_persistent_store" and sim6.hookCalls == 0)
	local sim7 = stNewSim()
	local ok7, why7 = Hook.engage(stOpts(sim7, { __DUMP_HOOK = { schema = 999, state = "ready", original = function() end } }, Ring.new(5)))
	stCheck("ST-07.7a schema incompatível: fail-closed", ok7 == false and tostring(why7):find("schema_mismatch", 1, true) ~= nil and sim7.hookCalls == 0, tostring(why7))
	local ok7b, why7b = Hook.engage(stOpts(sim7, { __DUMP_HOOK = { schema = Hook.SCHEMA, state = "installing" } }, Ring.new(5)))
	stCheck("ST-07.7b 'installing' órfão: fail-closed", ok7b == false and tostring(why7b):find("installing", 1, true) ~= nil and sim7.hookCalls == 0)
	local ok7c, why7c = Hook.engage(stOpts(sim7, { __DUMP_HOOK = { schema = Hook.SCHEMA, state = "failed" } }, Ring.new(5)))
	stCheck("ST-07.7c 'failed': fail-closed, sem retry", ok7c == false and tostring(why7c):find("failed", 1, true) ~= nil and sim7.hookCalls == 0)
	local ok7d = Hook.engage(stOpts(sim7, { __DUMP_HOOK = "lixo" }, Ring.new(5)))
	stCheck("ST-07.7d registro inválido: fail-closed", ok7d == false and sim7.hookCalls == 0)
	local sim8 = stNewSim(); sim8.hookmeta = function() error("boom") end
	local st8 = {}
	local ok8, why8 = Hook.engage(stOpts(sim8, st8, Ring.new(5)))
	stCheck("ST-07.8a hookmetamethod com erro: failed", ok8 == false and st8.__DUMP_HOOK.state == "failed" and tostring(why8):find("hookmetamethod_failed", 1, true) ~= nil)
	local sim8b = stNewSim(); sim8b.hookmeta = function() return nil end
	local st8b = {}
	local ok8b = Hook.engage(stOpts(sim8b, st8b, Ring.new(5)))
	stCheck("ST-07.8b hookmetamethod sem retorno: failed", ok8b == false and st8b.__DUMP_HOOK.state == "failed")
	do
		local s8, st8c = stNewSim(), {}
		s8.hookmeta = function(tgt, name, fn) s8.hookCalls = s8.hookCalls + 1; tgt[name] = fn; return nil end
		Hook.engage(stOpts(s8, st8c, Ring.new(5)))
		local R8 = st8c.__DUMP_HOOK
		local r1 = s8.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.8c LIMITAÇÃO documentada: hook aplicado sem original => chamadas NÃO encaminhadas e contadas (tamperCalls)",
			R8.state == "failed" and R8.tamperCalls == 1 and #s8.calls == 0 and r1 == nil)
	end
	local variants = {
		{ "ausente (nil)",   function() return nil end },
		{ "com erro",        function() error("falha") end },
		{ "não-string",      function() return 42 end },
	}
	for _, v in ipairs(variants) do
		local s9b, st9b, r9b = stNewSim(), {}, Ring.new(10)
		s9b.getm = v[2]
		local okc = Hook.engage(stOpts(s9b, st9b, r9b, { fireCanary = function(t, id) st9b.__DUMP_HOOK.canaryConfirmed = id end }))
		local R9b = st9b.__DUMP_HOOK
		local cb9 = #s9b.calls
		local y1, y2, y3 = s9b.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.9 getnamecallmethod " .. v[1] .. ": original 1x, retornos intactos, nada enfileirado, methodErrors++",
			okc == true and #s9b.calls == cb9 + 1 and y1 == "r1" and y3 == "r3" and r9b.count == 0 and R9b.methodErrors == 1,
			"methodErrors=" .. tostring(R9b and R9b.methodErrors))
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s, st, r, { setm = false }))
		local R2 = st.__DUMP_HOOK
		local cb10 = #s.calls
		s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.10a setnamecallmethod ausente: encaminha 1x, enfileira, sem restauração",
			#s.calls == cb10 + 1 and r.count == 1 and R2.hasSetMethod == false and s.setmCalls == 0)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		local failNext = 0
		s.setm = function(m) s.setmCalls = s.setmCalls + 1; if failNext > 0 then failNext = failNext - 1; error("setm falhou") end; s.st.method = m end
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		local function callOnce() local cb = #s.calls; local a1, a2, a3 = s.dispatch(stInst(), "Fire", 1); return (#s.calls == cb + 1) and a1 == "r1" and a3 == "r3" end
		failNext = 2
		local c1, c2 = callOnce(), callOnce()
		stCheck("ST-07.10b duas falhas seguidas: continua encaminhando 1x, não dispara o disjuntor",
			c1 and c2 and R2.restoreErrors == 2 and R2.consecRestoreErrors == 2 and R2.observer ~= nil and R2.tripped == false)
		failNext = 0
		callOnce()
		stCheck("ST-07.10c um sucesso zera as consecutivas", R2.consecRestoreErrors == 0 and R2.restoreErrors == 2)
		failNext = 3
		local c3, c4, c5 = callOnce(), callOnce(), callOnce()
		stCheck("ST-07.10d três falhas seguidas: disjuntor desativa o observer (restore_errors), ainda encaminha",
			c3 and c4 and c5 and R2.tripped == true and R2.observer == nil and R2.reason == "restore_errors")
		local gm2, cnt = s.getmCalls, r.count
		local c6 = callOnce()
		stCheck("ST-07.10e após o disparo: inerte (getnamecallmethod 0x) e continua encaminhando", c6 and s.getmCalls == gm2 and r.count == cnt)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		R2.observer = function() error("observer quebrado") end
		local okAll = true
		for i = 1, 3 do
			local cb = #s.calls
			local a1, a2, a3 = s.dispatch(stInst(), "Fire", i)
			if not (#s.calls == cb + 1 and a1 == "r1" and a3 == "r3") then okAll = false end
		end
		stCheck("ST-07.11a observer com erro: sempre encaminha 1x, retornos intactos", okAll and R2.observerErrors == 3 and R2.observer ~= nil)
		s.dispatch(stInst(), "Fire", 4)
		stCheck("ST-07.11b erros além do limite: disjuntor (observer_errors)", R2.tripped == true and R2.observer == nil and R2.reason == "observer_errors", tostring(R2.reason))
		local s2, st2, r2 = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s2, st2, r2))
		st2.__DUMP_HOOK.observer = function() return "ignorado", 1, 2 end
		local cb = #s2.calls
		local z1, z2, z3, z4 = s2.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.11c observer devolve valores: ignorados, retornos do original intactos", #s2.calls == cb + 1 and z1 == "r1" and z2 == nil and z3 == "r3" and z4 == nil)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(20)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		R2.errors, R2.observerErrors, R2.methodErrors, R2.restoreErrors, R2.consecRestoreErrors, R2.maxObserverErrors = nil, nil, nil, nil, nil, nil
		s.getm = function() error("x") end
		local okAll = true
		for i = 1, 2 do
			local cb = #s.calls
			local a1, a2, a3 = s.dispatch(stInst(), "Fire", i)
			if not (#s.calls == cb + 1 and a1 == "r1" and a3 == "r3") then okAll = false end
		end
		stCheck("ST-07.11d REG adulterado (campos nil): ainda encaminha 1x com retornos intactos", okAll)
	end
	do
		local called = 0
		local Rd = { state = "installing", original = nil, observer = nil, earlyCalls = 0, tamperCalls = 0, maxObserverErrors = 3 }
		local t = Hook.makeTrampoline(Rd, function() return "Fire" end, nil)
		local ret = t({}, 1)
		stCheck("ST-07.12a D1 (installing): conta earlyCalls e NÃO encaminha", Rd.earlyCalls == 1 and Rd.tamperCalls == 0 and ret == nil)
		Rd.state = "ready"
		local obsCalled = false
		Rd.observer = function() obsCalled = true end
		t({}, 1)
		stCheck("ST-07.12c D1 com observer ligado: o observer NÃO é chamado", obsCalled == false)
		stCheck("ST-07.12b original nil fora de 'installing': conta tamperCalls", Rd.earlyCalls == 1 and Rd.tamperCalls == 1)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local okc, whyc = Hook.engage(stOpts(s, st, r, { fireCanary = function() end }))
		local R2 = st.__DUMP_HOOK
		stCheck("ST-07.13a canário descartado: timeout, observer desativado, failed",
			okc == false and whyc == "canary_failed" and R2.observer == nil and R2.state == "failed" and R2.canaryOk == false and R2.canaryExpected == nil)
		local cb = #s.calls
		local q1, q2, q3 = s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.13b após falha do canário: continua encaminhando 1x", #s.calls == cb + 1 and q1 == "r1" and q3 == "r3" and r.count == 0)
		local ok2, why2 = Hook.engage(stOpts(s, st, Ring.new(5)))
		stCheck("ST-07.13c nova execução: fail-closed (registry_state_failed), sem novo hook", ok2 == false and tostring(why2):find("registry_state_failed", 1, true) ~= nil and s.hookCalls == 1)
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		local resetSeen = nil
		local ok2 = Hook.engage(stOpts(s, st, Ring.new(5), { owner = "N", fireCanary = function(t, id)
			resetSeen = (R2.canaryConfirmed == nil)
			R2.canaryConfirmed = "id-velho"
		end }))
		stCheck("ST-07.13d reset antes da troca e confirmação de id errado NÃO vale", resetSeen == true and ok2 == false and R2.state == "failed")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local ok = Hook.engage(stOpts(s, st, r, { newCanaryTarget = function() error("sem Instance") end }))
		stCheck("ST-07.13e alvo do canário falha: fail-closed", ok == false and st.__DUMP_HOOK.observer == nil and st.__DUMP_HOOK.state == "failed")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local ok = Hook.engage(stOpts(s, st, r, { fireCanary = function(t, id)
			s.dispatch({ ClassName = "BindableEvent", Name = id }, "Fire", id)
		end }))
		stCheck("ST-07.13f objeto diferente com o mesmo Name não confirma o canário", ok == false and st.__DUMP_HOOK.state == "failed")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		s.getm = function() error("getnamecallmethod quebrado") end
		local ok, why = Hook.engage(stOpts(s, st, r))
		local cb = #s.calls
		local q = s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.13g getnamecallmethod quebrado: canário falha e o jogo continua sendo encaminhado",
			ok == false and why == "canary_failed" and st.__DUMP_HOOK.observer == nil and #s.calls == cb + 1 and q == "r1")
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		local ok, why = Hook.engage(stOpts(s, st, r, { fireCanary = function() end, wait = function() error("sem task.wait") end }))
		local R2 = st.__DUMP_HOOK
		stCheck("ST-07.13h erro dentro do canário: observer nil, failed, canaryExpected limpo",
			ok == false and R2.observer == nil and R2.state == "failed" and R2.canaryExpected == nil and tostring(why):find("canary_error", 1, true) ~= nil, tostring(why))
	end
	do
		local s, st, r = stNewSim(), {}, Ring.new(5)
		Hook.engage(stOpts(s, st, r))
		local R2 = st.__DUMP_HOOK
		local otherObs = function() end
		local ok, why = Hook.engage(stOpts(s, st, Ring.new(5), { owner = "ANTIGA", fireCanary = function()
			R2.owner = "NOVA"; R2.observer = otherObs
		end }))
		stCheck("ST-07.13i execução superada: não derruba o observer da nova, estado intacto",
			ok == false and tostring(why):find("superseded", 1, true) ~= nil and R2.observer == otherObs and R2.state == "ready")
	end
	do
		local s, st, r1 = stNewSim(), {}, Ring.new(5)
		Hook.engage(stOpts(s, st, r1))
		st.__DUMP_HOOK = nil
		local r2 = Ring.new(5)
		Hook.engage(stOpts(s, st, r2))
		local cb, b1, b2 = #s.calls, r1.count, r2.count
		s.dispatch(stInst(), "Fire", 1)
		stCheck("ST-07.14 LIMITAÇÃO documentada (simulação): sem registro, a 2ª instalação empilha (2 camadas, as duas observam a mesma chamada) e o original ainda roda 1x",
			s.hookCalls == 2 and r1.count == b1 + 1 and r2.count == b2 + 1 and #s.calls == cb + 1)
	end
end
function SelfTest.run()
	local savedReg = Hook.reg
	SelfTest.results, SelfTest.failed, SelfTest.passed = {}, 0, 0
	local okR, errR = pcall(SelfTest.ring)
	if not okR then stCheck("ST-05 abortou", false, errR) end
	local okH, errH = pcall(SelfTest.hook)
	if not okH then stCheck("ST-07 abortou", false, errH) end
	local lines = {
		"TESTES DE LOGICA EM SIMULACAO (ST-05, ST-07) - NAO SAO TESTES DO EXECUTOR REAL",
		"Nenhum hook real foi instalado em `game`. Resultado deste file NAO prova o comportamento no Roblox.",
		string.format("PASS=%d FAIL=%d", SelfTest.passed, SelfTest.failed), "",
	}
	for _, l in ipairs(SelfTest.results) do lines[#lines + 1] = l end
	Hook.reg = savedReg
	local text = table.concat(lines, "\n")
	pcall(function()
		if has("writefile") then
			local dir = Config.BaseFolder .. "/_selftest"
			createFolderRecursive(dir)
			Env.writefile(dir .. "/selftest_" .. tostring(os.time()) .. ".txt", text)
		end
	end)
	pcall(print, "[DumpExplorer][selftest] PASS=" .. SelfTest.passed .. " FAIL=" .. SelfTest.failed .. " (simulação de lógica, não é teste do executor real)")
	return text
end
