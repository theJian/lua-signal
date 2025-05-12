local lib_signal = require("lua/signal")
local signal = lib_signal.signal
local computed = lib_signal.computed
local effect = lib_signal.effect

local count = signal(1)

effect(function()
	print("count ->", count)
end)

local double = computed(function()
	print("> compute double")
	return 2 * count.value
end)
print(double.value)

count.value = 4
print(double.value)

count.value = 9
print(double.value)
