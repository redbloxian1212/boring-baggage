--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bytenet = require(ReplicatedStorage.Packages.Bytenet)
local ByteNet = require(game:GetService("ReplicatedStorage").Packages.Bytenet)

return ByteNet.defineNamespace("Game", function()
	return {
		spawnBaggage = ByteNet.struct({
			value = {
				id = ByteNet.uint8,
				color = ByteNet.uint8,
				material = ByteNet.uint8,
			},
		}),

		removeBaggage = Bytenet.definePacket({
			value = ByteNet.uint8,
		}),
	}
end)
