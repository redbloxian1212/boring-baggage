--[=[
    @class BaggageService
]=]

local Container = require(game:GetService("ReplicatedStorage").Forge.Shared.Core.Container)

local BaggageService = {}
BaggageService.__index = BaggageService

export type BaggageService = typeof(setmetatable({}, BaggageService))

function BaggageService.create(): BaggageService
	return setmetatable({}, BaggageService)
end

function BaggageService.Init(self: BaggageService, container: Container.ContainerType)
	self._dataService = container:Resolve(require("../Core/DataService"))
	self._latestPlayer = nil :: Player?
end

function BaggageService.Start(self: BaggageService) end

return BaggageService
