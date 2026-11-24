local Env = {
	isfolder = isfolder,
	makefolder = makefolder,
	isfile = isfile,
	readfile = waxreadfile,
	writefile = waxwritefile,
	delfile = missing("function", delfile),
	listfiles = missing("function", listfiles),
	decompile = missing("function", decompile),
	getscriptclosure = missing("function", getscriptclosure),
	getscriptbytecode = missing("function", getscriptbytecode),
	hookmetamethod = hookmetamethod,
	hookfunction = hookfunction,
	getconnections = getconnections,
	getnamecallmethod = getnamecallmethod,
	setnamecallmethod = missing("function", setnamecallmethod),
	checkcaller = checkcaller,
	getcallingscript = missing("function", getcallingscript),
	isexecutorclosure = missing("function", isexecutorclosure),
	getfenv = missing("function", getfenv),
	restorefunction = missing("function", restorefunction),
}
local function has(name)
	return typeof(Env[name]) == "function"
end
