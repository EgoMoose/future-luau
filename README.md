# future-luau

A simple future class for luau. Typically used as an abstraction for defining eventual values computed by asynchronous computations.

## Examples

Waiting for a button to be pressed:

```luau
local buttonPressed = Future.new()

local conn1 = button1.Activated:Connect(function()
	buttonPressed:complete("Button1")
end)

local conn2 = button2.Activated:Connect(function()
	buttonPressed:complete("Button2")
end)

-- will yield until the future has been completed
local result = buttonPressedFuture:expect()
conn1:Disconnect()
conn2:Disconnect()
```

Immediate completion futures:

```luau
local f = Future.resolve(1, 2, 3)
local a, b, c = f:expect()
print(a, b, c) -- 1, 2, 3
```

Racing between futures:

```luau
local f1 = Future.delay(1, true)
local f2 = Future.delay(2, false)
local result = Future.race({ f1, f2 }):expect() -- true
```