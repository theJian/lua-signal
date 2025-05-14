local current
local enter = function(ctx)
	local prev
	return function(fn)
		prev, current = current, ctx
		local ok, result = pcall(fn)
		current = prev
		if not ok then
			error(result)
		end
	end
end

local batches = nil
local batch = function(fn)
	local root = not batches
	batches = batches or {}
	pcall(fn)
	if root then
		local effects = batches
		batches = nil
		for _, fx in ipairs(effects) do
			fx()
		end
	end
end

---Extend a value to support string conversion, arithmetic operations, etc.
---
---@param t table The table to extend, must contain a `value` field
---
---@return table
local create_value = function(t)
	local mt = getmetatable(t)
	mt.__tostring = function()
		return tostring(t.value)
	end
	mt.__mul = function(a, b)
		error("todo")
	end
	mt.__div = function(a, b)
		error("todo")
	end
	mt.__sub = function(a, b)
		error("todo")
	end
	mt.__add = function(a, b)
		error("todo")
	end
	setmetatable(t, mt)
	return t
end

---Create a signal with initial value
--
---@param initial any The initial value for the signal
--
---@return table
local create_signal = function(initial)
	local value = initial
	local dependents = {}
	local t = {}

	--- Get value without subscribing to updates
	t.peek = function()
		return value
	end

	t.get_dependents = function()
		return dependents
	end

	local mt = {}

	mt.__index = function(tbl, key)
		if key == "value" then
			if current then
				dependents[current] = true
				current.dependencies[t] = true
			end
			return value
		end
		return rawget(tbl, key)
	end

	mt.__newindex = function(tbl, key, new_value)
		if key == "value" then
			if value == new_value then
				return
			end

			value = new_value

			local effects = {}
			local q = { t }
			local i = 1
			while i <= #q do
				local it = q[i]
				local deps = it.get_dependents()
				for dep in pairs(deps) do
					if not dep.is_dirty and dep.dependencies[it] then
						dep.dependencies = {}
						dep.is_dirty = true
						if dep.type == "effect" then
							table.insert(effects, dep)
						else
							table.insert(q, dep.s)
						end
					end
				end

				i = i + 1
			end

			for _, fx in ipairs(effects) do
				if batches then
					table.insert(fx)
				else
					fx()
				end
			end

			return
		end
		rawset(tbl, key, new_value)
	end

	setmetatable(t, mt)
	return t
end

---Create a read-only signal that is tracking the update of signals it relies on.
---
---@param fn function Callback that's returning the value for this signal.
---
---@return table
local create_computed = function(fn)
	local signal = create_signal()

	local t = {}

	t.s = signal

	t.type = "computed"

	--- If the state is dirty, in another word, should be updated
	t.is_dirty = true

	-- Related signal or computed
	t.dependencies = {}

	--- Get value without subscribing to updates
	t.peek = function()
		return signal.peek()
	end

	local mt = {}

	mt.__index = function(tbl, key)
		if key == "value" then
			if t.is_dirty then
				enter(t)(function()
					signal.value = fn()
				end)
				t.is_dirty = false
			end
			return signal.value
		end
		return rawget(tbl, key)
	end

	setmetatable(t, mt)
	return t
end

---Create a effect that runs when any of its dependencies change, return a dispose function
---
---@param fn function Side-effect function
---
---@return table
local create_effect = function(fn)
	local teardown
	local t = {}

	t.type = "effect"

	--- If the state is dirty, in another word, should be updated
	t.is_dirty = true

	-- Related signal or computed
	t.dependencies = {}

	t.dispose = function()
		t.dependencies = {}
		if type(teardown) == "function" then
			teardown()
		end
	end

	local mt = {}

	mt.__call = function()
		if type(teardown) == "function" then
			teardown()
		end

		t.is_dirty = false
		enter(t)(function()
			teardown = fn()
		end)
	end

	setmetatable(t, mt)

	return t
end

local signal = function(initial)
	return create_value(create_signal(initial))
end

local computed = function(fn)
	return create_value(create_computed(fn))
end

local effect = function(fn)
	local fx = create_effect(fn)
	fx()
	return fx.dispose
end

return {
	signal = signal,
	computed = computed,
	effect = effect,
	batch = batch,
}
