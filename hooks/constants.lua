local OutgoingMethods = {
	FireServer = { RemoteEvent = true, UnreliableRemoteEvent = true },
	fireServer = { RemoteEvent = true, UnreliableRemoteEvent = true },
	InvokeServer= { RemoteFunction = true },
	invokeServer= { RemoteFunction = true },
	Fire = { BindableEvent = true },
	fire = { BindableEvent = true },
	Invoke = { BindableFunction = true },
	invoke = { BindableFunction = true },
}
local IncomingMethod = {
	RemoteEvent = "OnClientEvent",
	RemoteFunction = "OnClientInvoke",
	UnreliableRemoteEvent = "OnClientEvent",
	BindableEvent = "Event",
	BindableFunction = "OnInvoke",
}
local RemoteClasses = {
	RemoteEvent = true,
	RemoteFunction = true,
	UnreliableRemoteEvent = true,
	BindableEvent = true,
	BindableFunction = true,
}
