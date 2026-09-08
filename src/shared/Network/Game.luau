--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bytenet = require(ReplicatedStorage.Packages.Bytenet)
local ByteNet = require(game:GetService("ReplicatedStorage").Packages.Bytenet)

return ByteNet.defineNamespace("Game", function()
	return {
		spawnBaggage = ByteNet.definePacket({
			value = Bytenet.struct({
				id = ByteNet.uint8,
				colorId = ByteNet.uint8,
				materialId = ByteNet.uint8,
			}),
		}),

		setSpawnRate = ByteNet.definePacket({
			value = Bytenet.uint8,
		}),
	}
end)
