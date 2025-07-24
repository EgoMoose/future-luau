--!strict

local DELAY_TIME = 0.1

type Packed<T> = { [number]: T, n: number }

local function isArrEqual(arr1: Packed<any>, arr2: Packed<any>)
	if arr1.n ~= arr2.n then
		return false
	end
	for i = 1, arr1.n do
		if arr1[i] ~= arr2[i] then
			return false
		end
	end
	return true
end

return function()
	local Future = require(script.Parent)

	describe(".new()", function()
		it("should complete / expect with single values.", function()
			local f = Future.new()

			expect(f:isCompleted()).to.equal(false)
			f:complete("Hello world!")
			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("Hello world!")
			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("Hello world!")
		end)

		it("should complete / expect with single value with a delay.", function()
			local f = Future.new()

			task.delay(DELAY_TIME, function()
				f:complete("Hello world!")
			end)

			expect(f:isCompleted()).to.equal(false)
			expect(f:expect()).to.equal("Hello world!")
			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("Hello world!")
		end)

		it("should complete / expect with multiple values.", function()
			local f = Future.new()
			local arr = { 1, 2, 3 }

			expect(f:isCompleted()).to.equal(false)
			f:complete("Hello", "world!", 123, true, arr)
			expect(f:isCompleted()).to.equal(true)
			expect(isArrEqual(table.pack(f:expect()), table.pack("Hello", "world!", 123, true, arr))).to.equal(true)
			expect(f:isCompleted()).to.equal(true)
			expect(isArrEqual(table.pack(f:expect()), table.pack("Hello", "world!", 123, true, arr))).to.equal(true)
		end)

		it("should complete / expect with multiple values with a delay.", function()
			local f = Future.new()
			local arr = { 1, 2, 3 }

			task.delay(DELAY_TIME, function()
				f:complete("Hello", "world!", 123, true, arr)
			end)

			expect(f:isCompleted()).to.equal(false)
			expect(isArrEqual(table.pack(f:expect()), table.pack("Hello", "world!", 123, true, arr))).to.equal(true)
			expect(f:isCompleted()).to.equal(true)
			expect(isArrEqual(table.pack(f:expect()), table.pack("Hello", "world!", 123, true, arr))).to.equal(true)
		end)
	end)

	describe(".completed()", function()
		it("should be completed with single values.", function()
			local f = Future.completed("Hello world!")
			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("Hello world!")
		end)

		it("should be completed with multiple values.", function()
			local arr = { 1, 2, 3 }
			local f = Future.completed("Hello", "world!", 123, true, arr)

			expect(f:isCompleted()).to.equal(true)
			expect(isArrEqual(table.pack(f:expect()), table.pack("Hello", "world!", 123, true, arr))).to.equal(true)
		end)
	end)

	describe(".delay()", function()
		it("should be completed with single values.", function()
			local f = Future.delay(DELAY_TIME, "Hello world!")
			expect(f:isCompleted()).to.equal(false)
			expect(f:expect()).to.equal("Hello world!")
			expect(f:isCompleted()).to.equal(true)
		end)

		it("should be completed with multiple values.", function()
			local arr = { 1, 2, 3 }
			local f = Future.delay(DELAY_TIME, "Hello", "world!", 123, true, arr)

			expect(f:isCompleted()).to.equal(false)
			expect(isArrEqual(table.pack(f:expect()), table.pack("Hello", "world!", 123, true, arr))).to.equal(true)
			expect(f:isCompleted()).to.equal(true)
		end)
	end)

	describe(".race()", function()
		it("should be race with single values.", function()
			local f1 = Future.new()
			local f2 = Future.new()
			local race = Future.race({ f1, f2 })

			task.delay(DELAY_TIME, function()
				f1:complete("Hello")
			end)

			expect(race:isCompleted()).to.equal(false)
			f2:complete("world!")
			expect(race:isCompleted()).to.equal(true)
			expect(race:expect()).to.equal("world!")
		end)

		it("should be race with single values with delay.", function()
			local f1 = Future.new()
			local f2 = Future.new()
			local race = Future.race({ f1, f2 })

			task.delay(DELAY_TIME, function()
				f1:complete("Hello")
			end)

			task.delay(DELAY_TIME * 2, function()
				f2:complete("world!")
			end)

			expect(race:isCompleted()).to.equal(false)
			expect(race:expect()).to.equal("Hello")
			expect(race:isCompleted()).to.equal(true)
		end)

		it("should be race with multiple values.", function()
			local f1 = Future.new()
			local f2 = Future.new()
			local race = Future.race({ f1, f2 })

			task.delay(DELAY_TIME, function()
				f1:complete(1, true, "Hello")
			end)

			expect(race:isCompleted()).to.equal(false)
			f2:complete(2, false, "world!")
			expect(race:isCompleted()).to.equal(true)
			expect(isArrEqual(table.pack(race:expect()), table.pack(2, false, "world!"))).to.equal(true)
		end)

		it("should be race with multiple values with delay.", function()
			local f1 = Future.new()
			local f2 = Future.new()
			local race = Future.race({ f1, f2 })

			task.delay(DELAY_TIME, function()
				f1:complete(1, true, "Hello")
			end)

			task.delay(DELAY_TIME * 2, function()
				f2:complete(2, false, "world!")
			end)

			expect(race:isCompleted()).to.equal(false)
			expect(isArrEqual(table.pack(race:expect()), table.pack(1, true, "Hello"))).to.equal(true)
			expect(race:isCompleted()).to.equal(true)
		end)
	end)

	describe(".all()", function()
		it("should resolve with single values.", function()
			local f1 = Future.delay(DELAY_TIME, "Hello")
			local f2 = Future.completed("world!")
			local all = Future.all({ f1, f2 })

			expect(all:isCompleted()).to.equal(false)

			local ordered = all:expect()
			expect(ordered[1]).to.equal(f2)
			expect(ordered[2]).to.equal(f1)

			expect(all:isCompleted()).to.equal(true)
		end)

		it("should resolve with multiple values.", function()
			local f1 = Future.delay(DELAY_TIME, 1, "Hello", true)
			local f2 = Future.completed(2, "world!", false)
			local all = Future.all({ f1, f2 })

			expect(all:isCompleted()).to.equal(false)

			local ordered = all:expect()
			expect(ordered[1]).to.equal(f2)
			expect(ordered[2]).to.equal(f1)

			expect(all:isCompleted()).to.equal(true)
		end)

		it("should resolve with instant values.", function()
			local f1 = Future.completed(1)
			local f2 = Future.completed(2)
			local all = Future.all({ f1, f2 })

			expect(all:isCompleted()).to.equal(true)

			local ordered = all:expect()
			expect(ordered[1]).to.equal(f1)
			expect(ordered[2]).to.equal(f2)
		end)
	end)

	describe(".fromSignal()", function()
		local Signal = require(game.ReplicatedStorage.DevPackages.Signal)
		local RunService = game:GetService("RunService") :: RunService

		it("should work without a predicate", function()
			local f = Future.fromSignal(RunService.Heartbeat)

			expect(f:expect() > 0).to.equal(true)
			expect(f:isCompleted()).to.equal(true)
		end)

		it("should work with a predicate", function()
			local s = Signal.new() :: Signal.Signal<any>
			local f = Future.fromSignal(s, function(x)
				return x == "foo"
			end)

			s:Fire(1)
			s:Fire(false)
			s:Fire("foo")

			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("foo")
		end)

		it("should work with a predicate and post fires", function()
			local s = Signal.new() :: Signal.Signal<any>
			local f = Future.fromSignal(s, function(x)
				return x == "foo"
			end)

			s:Fire(1)
			s:Fire(false)
			s:Fire("foo")
			s:Fire({})

			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("foo")
		end)
	end)
end
