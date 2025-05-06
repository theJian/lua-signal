# Lua Signal

A signals implementation for Neovim and should also works for any Lua code.

## Preview

```lua
local lib_signal = require "signal"
local signal = lib_signal.signal
local computed = lib_signal.computed
local effect = lib_signal.effect

local count = signal(1)

effect(function()
	print("count ->", count) --
end)

local double = computed(function()
	return 2 * count
end)
print(double.value)

count.value = 4
print(double.value)

count.value = 9
print(double.value)
```

## API

- `signal(initial_value)` creates a reactive signal with an initial value that can be read or updated by accessing its `.value` property, triggering updates in dependencies.
- `computed(fn)` defines a derived value computed from signals, automatically recalculating when dependent signals change.
- `effect(fn)` runs a side-effect function whenever its dependent signals change, a dispose function is returned.
- `batch(fn)` groups multiple signal updates into a single batch to optimize performance.
- `untracked(fn)` executes a function without tracking its signal dependencies.
