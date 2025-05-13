local lib_signal = require("lua/signal")
local signal = lib_signal.signal
local computed = lib_signal.computed
local effect = lib_signal.effect

local count = signal(1)

effect(function()
	print("count ->", count)
end)

local double = computed(function()
	return 2 * count.value
end)

effect(function()
	print("double ->", double)
end)

-- local result = double.value

count.value = 4
-- result = double.value

count.value = 9
-- result = double.value
