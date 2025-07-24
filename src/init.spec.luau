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
end
