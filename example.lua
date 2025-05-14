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

count.value = 4

count.value = 9
