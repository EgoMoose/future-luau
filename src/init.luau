--!strict

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

function FutureStatic.new<T...>()
	local self = setmetatable({}, FutureClass) :: Future<T...>

	self.awaiting = {}
	self.getValue = nil

	return self
end

function FutureStatic.completed<T...>(...: T...)
	local future = FutureStatic.new() :: Future<T...>
	future:complete(...)
	return future
end

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

-- Public Methods

function FutureClass.isCompleted<T...>(self: Future<T...>)
	return not not self.getValue
end

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

function FutureClass.expect<T>(self: Future<T>): T
	if self.getValue then
		return self.getValue()
	end

	local thread = coroutine.running()
	self.awaiting[thread] = true
	return coroutine.yield()
end

--

return FutureStatic
