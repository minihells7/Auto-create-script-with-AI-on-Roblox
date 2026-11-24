local function createFolderRecursive(path)
	if not has("makefolder") or not has("isfolder") then return end
	local accum = ""
	for part in path:gmatch("[^/]+") do
		accum = (accum == "") and part or (accum .. "/" .. part)
		pcall(function()
			if not Env.isfolder(accum) then Env.makefolder(accum) end
		end)
	end
end
local function writeFileSafe(path, content)
	if not has("writefile") then return false end
	return pcall(Env.writefile, path, content)
end
local WriteQueue = {
	queue = {},
	running = false,
	pending = 0,
	done = 0,
	errors = 0,
}
local function writeQueuePush(path, content)
	if not has("writefile") then return false, "no_writefile" end
	local ok, err
	local resolved = false
	local co = coroutine.running()
	WriteQueue.pending += 1
	table.insert(WriteQueue.queue, {
		path = path,
		content = content,
		resolve = function(rok, rerr)
			ok, err = rok, rerr
			resolved = true
			if co then
				task.spawn(co)
			end
		end,
	})
	if not WriteQueue.running then
		WriteQueue.running = true
		task.spawn(function()
			local baseBudget = (Config.FastSaveBudgetMs or 14) / 1000
			while #WriteQueue.queue > 0 do
				local depth = #WriteQueue.queue
				local budgetSec = baseBudget * math.min(1 + depth / 200, 1.75)
				local frameStart = os.clock()
				while #WriteQueue.queue > 0 do
					local item = table.remove(WriteQueue.queue, 1)
					local wok, werr = pcall(Env.writefile, item.path, item.content)
					WriteQueue.done += 1
					WriteQueue.pending -= 1
					if not wok then WriteQueue.errors += 1 end
					item.resolve(wok, werr)
					if os.clock() - frameStart >= budgetSec then
						task.wait()
						frameStart = os.clock()
						depth = #WriteQueue.queue
						budgetSec = baseBudget * math.min(1 + depth / 200, 1.75)
					end
				end
				task.wait()
			end
			WriteQueue.running = false
		end)
	end
	if not resolved then
		coroutine.yield()
	end
	return ok, err
end
local _writeFileSafeBase = writeFileSafe
writeFileSafe = function(path, content)
	if Config.FastMode then
		if not has("writefile") then return false, "no_writefile" end
		local ok, err = pcall(Env.writefile, path, content)
		return ok, err
	elseif Config.FastSave then
		return writeQueuePush(path, content)
	else
		return _writeFileSafeBase(path, content)
	end
end
