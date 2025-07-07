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
		awaiting: { [thread]: boolean },
		getValue: (() -> T...)?,
	},
	FutureClass
))

-- Constructors

--[=[
	@within Future
	@tag Constructors

	Creates an uncompleted future.

	@return Future<T...>
]=]
function FutureStatic.new<T...>()
	local self = setmetatable({}, FutureClass) :: Future<T...>

	self.awaiting = {}
	self.getValue = nil

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
		local castedFuture = racingFuture :: Future<...any>
		if castedFuture:isCompleted() then
			future:complete(castedFuture:expect())
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

	@param futures { Future<T...> }
	@return Future<()>
]=]
function FutureStatic.all<T...>(futures: { Future<T...> })
	local allFuture = FutureStatic.new() :: Future<()>

	task.spawn(function()
		for _, future in futures do
			local castedFuture = future :: Future<...any>
			castedFuture:expect()
		end
		allFuture:complete()
	end)

	return allFuture
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
	return not not self.getValue
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
	assert(self.getValue == nil, "Cannot complete a future that is already completed")

	local packed = table.pack(...)
	self.getValue = function()
		return table.unpack(packed :: { any }, 1, packed.n)
	end

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
	if self.getValue then
		return self.getValue()
	end

	local thread = coroutine.running()
	self.awaiting[thread] = true
	return coroutine.yield()
end

--

return FutureStatic
