--!strict

local DELAY_TIME = 0.1

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
			expect(f:expect()).to.equal("Hello", "world!", 123, true, arr)
			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("Hello", "world!", 123, true, arr)
		end)

		it("should complete / expect with multiple values with a delay.", function()
			local f = Future.new()
			local arr = { 1, 2, 3 }

			task.delay(DELAY_TIME, function()
				f:complete("Hello", "world!", 123, true, arr)
			end)

			expect(f:isCompleted()).to.equal(false)
			expect(f:expect()).to.equal("Hello", "world!", 123, true, arr)
			expect(f:isCompleted()).to.equal(true)
			expect(f:expect()).to.equal("Hello", "world!", 123, true, arr)
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
			expect(f:expect()).to.equal("Hello", "world!", 123, true, arr)
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
			expect(race:expect()).to.equal(2, false, "world!")
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
			expect(race:expect()).to.equal(1, true, "Hello")
			expect(race:isCompleted()).to.equal(true)
		end)
	end)
end
