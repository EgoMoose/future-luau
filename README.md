# future-luau

A simple future class for luau.

Typically futures are used as an abstraction for defining eventual values that result from asynchronous computations. This makes them a great candidate for simplifying complex concurrency tasks.

## Examples

Waiting for a button to be pressed:

```lua
local buttonPressed = Future.new()

local conn1 = button1.Activated:Connect(function()
	buttonPressed:complete("Button1")
end)

local conn2 = button2.Activated:Connect(function()
	buttonPressed:complete("Button2")
end)

-- will yield until the future has been completed
local result = buttonPressedFuture:expect() -- "Button1" or "Button2"
conn1:Disconnect()
conn2:Disconnect()
```

Immediate completion futures:

```lua
local f = Future.resolve(1, 2, 3)
local a, b, c = f:expect()
print(a, b, c) -- 1, 2, 3
```

Racing between futures:

```lua
local f1 = Future.delay(2, true)
local f2 = Future.delay(1, false)
local result = Future.race({ f1, f2 }):expect() -- false, b/c f2 will resolve first
```