--!strict

--[=[
	@class Future

	A simple future class used as an abstraction for defining eventual values that result from asynchronous computations.
]=]

local FutureStatic = {}

local FutureClass = {}
FutureClass.__index = FutureClass
FutureClass.ClassName = "Future"

export type Future<T...> = typeof(setmetatable(
	{} :: {
		status: "pending" | "completed",
		awaiting: { [thread]: boolean },
		getValue: () -> T...,
	},
	FutureClass
))

-- Constructors

--[=[
	@within Future
	@tag Constructors

	Creates a pending future.

	@return Future<T...>
]=]
function FutureStatic.new<T...>()
	local self = setmetatable({}, FutureClass) :: Future<T...>

	self.status = "pending"
	self.awaiting = {}
	self.getValue = function() end

	return self
end

--[=[
	@within Future
	@tag Constructors

	Creates a completed future.

	@param ... T... -- The completed values.
	@return Future<T...>
]=]
function FutureStatic.completed<T...>(...: T...)
	local future = FutureStatic.new() :: Future<T...>
	future:complete(...)
	return future
end

--[=[
	@within Future
	@tag Constructors

	Creates a future and completes with the provided values after `sec` seconds.

	@param sec number -- How long to delay until the future completes.
	@param ... T... -- The completed values.
	@return Future<T...>
]=]
function FutureStatic.delay<T...>(sec: number, ...: T...)
	local future = FutureStatic.new() :: Future<T...>
	task.delay(sec, FutureClass.complete, future, ...)
	return future
end

type Signal<T...> = {
	Connect: (Signal<T...>, (T...) -> ()) -> any | { Disconnect: (any) -> () }, -- Unable to get typechecker to work with disconnect atm...
}

--[=[
	@within Future
	@tag Constructors

	Creates a new future that completes when the provided signal fires and when the predicate (if provided) passes.

	```lua
	Future.fromSignal(game:GetService("Players").PlayerAdded, function(player)
		return player.UserId == 1 -- only complete when player w/ UserId == 1 joins the game!
	end)
	```

	@param signal Signal<T...> -- Something with similar connect method structure to RbxScriptSignal<T...>
	@param predicate ((T...) -> boolean)?
	@return Future<T...>
]=]
function FutureStatic.fromSignal<T...>(signal: Signal<T...>, predicate: ((T...) -> boolean)?)
	local future = FutureStatic.new() :: Future<T...>

	local connection
	connection = signal:Connect(function(...)
		if not future:isCompleted() then
			if not predicate or predicate(...) then
				future:complete(...)
			else
				return
			end
		end

		if connection.Disconnect then
			connection:Disconnect()
		end
	end)

	return future
end

--[=[
	@within Future
	@tag Constructors

	Creates a new future that completes with the values from the first future to complete in the provided array.

	@param futures { Future<T...> }
	@return Future<T...>
]=]
function FutureStatic.race<T...>(futures: { Future<T...> })
	local future = FutureStatic.new() :: Future<T...>

	for _, racingFuture in futures do
		if racingFuture.status == "completed" then
			future:complete(racingFuture.getValue())
		end
	end

	if not future:isCompleted() then
		task.spawn(function()
			local thread = coroutine.running()
			for _, racingFuture in futures do
				racingFuture.awaiting[thread] = true
			end

			local packed = table.pack(coroutine.yield())
			for _, racingFuture in futures do
				racingFuture.awaiting[thread] = nil
			end

			future:complete(table.unpack(packed :: { any }, 1, packed.n))
		end)
	end

	return future
end

--[=[
	@within Future
	@tag Constructors

	Creates a new future that completes when all the provided futures have completed.

	The completed value is an array containing the input futures in the order they completed.

	```lua
	local f1 = Future.delay(1, "foo")
	local f2 = Future.completed("bar")
	Future.all({ f1, f2 }):expect() -- { f2, f1 }
	```

	@param futures { Future<T...> }
	@return Future<{ Future<T...> }>
]=]
function FutureStatic.all<T...>(futures: { Future<T...> })
	local allFuture = FutureStatic.new() :: Future<{ Future<T...> }>

	local resolved = {}
	local function markCompleted(future: Future<T...>)
		table.insert(resolved, future)
		if #resolved == #futures then
			allFuture:complete(resolved)
		end
	end

	for _, future in futures do
		local castedFuture = future :: Future<...any>
		if castedFuture.status == "completed" then
			markCompleted(castedFuture)
		else
			task.spawn(function()
				castedFuture:expect()
				markCompleted(castedFuture)
			end)
		end
	end

	return allFuture
end

-- Static Methods

--[=[
	@within Future
	@tag Static Methods

	Packs a list of values into a callback that returns the values when called.

	```lua
	local unpackCallback = Future.packAsCallback(1, "foo", true)
	local a, b, c = unpackCallback() -- number, string, boolean
	```

	@param ... T... -- The completed values.
	@return () -> (T...)
]=]
function FutureStatic.packAsCallback<T...>(...: T...)
	local future = FutureStatic.completed(...)
	return function()
		return future:expect()
	end
end

-- Public Methods

--[=[
	@within Future
	@tag Methods
	@method isCompleted

	Returns whether the future has been completed or not.

	@return boolean
]=]
function FutureClass.isCompleted<T...>(self: Future<T...>)
	return self.status == "completed"
end

--[=[
	@within Future
	@tag Methods
	@method complete

	Completes the future with the provided values.
	
	This method will error if the future has already been completed.

	@param ... T... -- The completed values.
]=]
function FutureClass.complete<T...>(self: Future<T...>, ...: T...)
	assert(self.status ~= "completed", "Cannot complete a future that is already completed")

	local packed = table.pack(...)
	self.getValue = function()
		return table.unpack(packed :: { any }, 1, packed.n)
	end

	self.status = "completed"

	local awaiting = self.awaiting
	self.awaiting = {}
	for thread, _ in awaiting do
		task.spawn(thread, ...)
	end
end

--[=[
	@within Future
	@tag Methods
	@method expect

	Yields until the future is complete and returns the completed values.

	@return T... -- The completed values.
]=]
function FutureClass.expect<T...>(self: Future<T...>): T...
	if self.status == "completed" then
		return self.getValue()
	end

	local thread = coroutine.running()
	self.awaiting[thread] = true
	return coroutine.yield()
end

--

return FutureStatic
