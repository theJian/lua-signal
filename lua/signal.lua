local current = nil
local create = function(block)
	local dependencies = {}
	local cleanups = {}
	local fx = {}
	fx.callback = function()
		local prev = current
		current = fx
		local ok, result = pcall(block)
		current = prev
		if ok then
			return result
		else
			error(result)
		end
	end
	fx.add_dependency = function(signal)
		signal.subscribe(fx)
		dependencies[signal] = true
	end
	fx.defer = function(fn)
		if type(fn) == "function" then
			table.insert(cleanups, fn)
		end
	end
	fx.dispose = function()
		for signal in pairs(dependencies) do
			signal.unsubscribe(fx)
		end

		for _, cleanup in ipairs(cleanups) do
			cleanup()
		end

		dependencies = {}
		cleanups = {}
	end
	return fx
end

local batches = nil
local batch = function(fn)
	local root = not batches
	if root then
		batches = {}
	end
	pcall(fn)
	if root then
		local effects = batches
		batches = nil
		for fx in pairs(effects) do
			fx()
		end
	end
end

local signal = function(initial)
	local value = initial
	local effects = {}
	local ref = {}

	local get = function()
		if current and not effects[current] then
			current.add_dependency(ref)
		end
		return value
	end

	local set = function(next_value)
		value = next_value
		local root = not batches
		local prev = effects
		effects = {}
		for fx in pairs(prev) do
			if root then
				fx.callback()
			else
				batches[fx] = true
			end
		end
	end

	setmetatable(ref, {
		__index = function(t, key)
			if key == "value" then
				return get()
			end
			return rawget(t, key)
		end,

		__newindex = function(t, key, new_value)
			if key == "value" then
				if value ~= new_value then
					set(new_value)
				end
			else
				rawset(t, key, new_value)
			end
		end,

		__tostring = function(_)
			return tostring(get())
		end,

		__mul = function(a, b)
			local value_a = type(a) == "number" and a or a.value
			local value_b = type(b) == "number" and b or b.value
			return value_a * value_b
		end,

		__div = function(a, b)
			local value_a = type(a) == "number" and a or a.value
			local value_b = type(b) == "number" and b or b.value
			return value_a / value_b
		end,

		__sub = function(a, b)
			local value_a = type(a) == "number" and a or a.value
			local value_b = type(b) == "number" and b or b.value
			return value_a - value_b
		end,

		__add = function(a, b)
			local value_a = type(a) == "number" and a or a.value
			local value_b = type(b) == "number" and b or b.value
			return value_a + value_b
		end,
	})

	function ref.peek()
		return value
	end

	function ref.subscribe(fx)
		effects[fx] = true
	end

	function ref.unsubscribe(fx)
		effects[fx] = nil
	end

	return ref
end

local effect = function(fn)
	local teardown
	local fx = create(function()
		if type(teardown) == "function" then
			teardown()
		end
		teardown = fn()
	end)
	if current then
		current.defer(fx.dispose)
	end
	fx.callback()
	fx.defer(function()
		if type(teardown) == "function" then
			teardown()
		end
	end)
	return fx.dispose
end

local computed = function(fn)
	local ref = signal()
	local orig_mt = getmetatable(ref)
	local orig__index = orig_mt.__index
	local orig__newindex = orig_mt.__newindex
	local fx

	local get = function()
		if not fx then
			fx = create(function()
				orig__newindex(ref, "value", fn())
			end)
			fx.callback()
		end
		return orig__index(ref, "value")
	end

	setmetatable(ref, {
		__index = function(t, key)
			if key == "value" then
				return get()
			end
			return rawget(t, key)
		end,
	})

	return ref
end

local untrack = function(fn)
	local prev = current
	current = nil
	local result = fn()
	current = prev
	return result
end

return {
	signal = signal,
	computed = computed,
	effect = effect,
	untrack = untrack,
	batch = batch,
}
