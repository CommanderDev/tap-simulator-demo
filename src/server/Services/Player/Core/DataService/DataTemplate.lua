local RunService = game:GetService("RunService")
local data = {
	Coins = 0,
	Strength = 100,
	ImpulseRadius = 30,
	Stats = {
		Clicks = 0,
		Rebirths = 0,
	},
	OwnedItems = {},
	ProgressionState = {},
	Essences = {
		Power = 0;
		Momentum = 1400;
		Chaos = 200;
		Precision = 100;
	}
}

local function GetPlayerDataTemplate()
	local formattedData = {}
	for key, value in data do
		if type(value) == "function" then
			formattedData[key] = value()
		else
			formattedData[key] = value
		end
	end
	return formattedData
end

return GetPlayerDataTemplate()
