--!strict

--[=[
    @class BaggageService
]=]

------------------------------
-- SERVICES --
------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------
-- NETWORK --
------------------------------
local Network = require(ReplicatedStorage.Forge.Shared.Network)
local GameNet = Network.Game

------------------------------
-- DEPENDENCIES --
------------------------------
local Observers = require(ReplicatedStorage.Packages.Observers)

------------------------------
-- CONFIG --
------------------------------
local SharedConfig = ReplicatedStorage.Forge.Shared.Config
local ConveyorConfig = require(SharedConfig.ConveyorConfig)
local ColorIdMap = require(SharedConfig.ColorIdMap)
local MaterialIdMap = require(SharedConfig.MaterialIdMap)

------------------------------
-- TYPES --
------------------------------
local Container = require(game:GetService("ReplicatedStorage").Forge.Shared.Core.Container)

local BaggageService = {}
BaggageService.__index = BaggageService

export type BaggageService = typeof(setmetatable({}, BaggageService))

function BaggageService.create(): BaggageService
	return setmetatable({}, BaggageService)
end

function BaggageService.Init(self: BaggageService, container: Container.ContainerType)
	self._admin = nil :: Player?
	self._bagsPerSecond = 1
	self._unusedIds = {}

	for i = 1, 255 do
		table.insert(self._unusedIds, i)
	end
end

function BaggageService.Start(self: BaggageService)
	Observers.observePlayer(function(player)
		if not self._admin then
			self._admin = player
		end

		return function()
			self._admin = nil
		end
	end)

	GameNet.setSpawnRate.listen(function(data: number, player: Player?)
		if self._admin ~= player then
			return
		end
		self._bagsPerSecond = math.clamp(data, 1, ConveyorConfig.MaxSpawnRate)
	end)

	GameNet.viewBaggage.listen(function(data, player)
		if data < 1 or data > 255 then
			warn(`hmmmm sus`)
			return
		end
		if table.find(self._unusedIds, data) then
			warn(`Bag is already goneee`)
			return
		end
		print(data)
	end)

	--// dis is da spawn loop
	task.spawn(function()
		while task.wait(1 / self._bagsPerSecond) do
			local randomColorId = math.random(1, #ColorIdMap)
			local randomMaterialId = math.random(1, #MaterialIdMap)
			local randomId = self:_getId()
			if not randomId then
				warn(`WE RAN OUT OF IDS AAAAAAAAAAAAA!`)
				return
			end

			GameNet.spawnBaggage.sendToAll({
				id = randomId,
				colorId = randomColorId,
				materialId = randomMaterialId,
			})

			task.delay(ConveyorConfig.MoveDuration, function()
				self:_releaseId(randomId)
			end)
		end
	end)
end

function BaggageService._getId(self: BaggageService): number?
	local n = #self._unusedIds
	if n == 0 then
		return nil
	end

	local id = self._unusedIds[n]
	self._unusedIds[n] = nil
	return id
end

function BaggageService._releaseId(self: BaggageService, id: number)
	table.insert(self._unusedIds, id)
end

return BaggageService
