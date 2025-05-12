local current

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

			local q = { dependents }
			local i = 1
			while i <= #q do
				for cp in pairs(q[i]) do
					if not cp.is_dirty and cp.dependencies[t] then
						cp.dependencies = {}
						cp.is_dirty = true

						-- TODO effects

						local next = cp.get_dependents()
						if next then
							table.insert(q, next)
						end
					end
				end

				i = i + 1
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

	--- If the state is dirty, in another word, should be updated
	t.is_dirty = true

	-- List of related signal or computed
	t.dependencies = {}

	--- Get value without subscribing to updates
	t.peek = function()
		return signal.peek()
	end

	t.get_dependents = function()
		return signal.get_dependents()
	end

	local mt = {}

	mt.__index = function(tbl, key)
		if key == "value" then
			if t.is_dirty then
				local prev
				prev, current = current, t
				local ok, result = pcall(function()
					signal.value = fn()
				end)
				current = prev
				t.is_dirty = false
				if not ok then
					error(result)
				end
			end
			return signal.value
		end
		return rawget(tbl, key)
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

local effect = function(fn) end

return {
	signal = signal,
	computed = computed,
	effect = effect,
}
