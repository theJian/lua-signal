# Lua Signal


A signals implementation for Neovim and should also works for any Lua code.

## Preview

https://github.com/theJian/lua-signal/blob/39ecd14c9f20999bfe8f76742b48b582dd52bd58/example.lua#L1-L24

## API

- `signal(initial_value)` creates a reactive signal with an initial value that can be read or updated by accessing its `.value` property, triggering updates in dependencies.
- `computed(fn)` defines a derived value computed from signals, automatically recalculating when dependent signals change.
- `effect(fn)` runs a side-effect function whenever its dependent signals change, a dispose function is returned.
- `batch(fn)` groups multiple signal updates into a single batch to optimize performance.
- `untracked(fn)` executes a function without tracking its signal dependencies.
