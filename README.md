# Lua Signal

> ⚠️ Under development

A signals implementation for Neovim and should also works for any Lua code.

## Preview

```lua
local lib_signal = require "signal"
local signal = lib_signal.signal
local computed = lib_signal.computed
local effect = lib_signal.effect

-- Create a signal with initial value 1
local count = signal(1)

-- Logs: count -> 1, subscribing to count and re-run when count changes.
effect(function()
	print("count ->", count)
end)

-- Create a signal that subscribes to `count`.
local double = computed(function()
	return 2 * count
end)
-- Logs: 2
print(double.value)

-- Write to a signal, which triggers the effect above. Logs: count -> 9.
count.value = 9
-- Logs: 18
print(double.value)
```

## API

- `signal(initial_value)` creates a reactive signal with an initial value that can be read or updated by accessing its `.value` property, triggering updates in dependencies.
- `computed(fn)` defines a derived value computed from signals, automatically recalculating when dependent signals change.
- `effect(fn)` runs a side-effect function whenever its dependent signals change, a dispose function is returned.
- `batch(fn)` groups multiple signal updates into a single batch to optimize performance.
- `untracked(fn)` executes a function without tracking its signal dependencies.
