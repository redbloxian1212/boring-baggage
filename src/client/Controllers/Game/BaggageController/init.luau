--[=[
    @class BaggageController
]=]

local Container = require(game:GetService("ReplicatedStorage").Forge.Shared.Core.Container)

local BaggageController = {}
BaggageController.__index = BaggageController

export type BaggageController = typeof(setmetatable({}, BaggageController))

function BaggageController.create(): BaggageController
	return setmetatable({}, BaggageController)
end

function BaggageController.Init(self: BaggageController, container: Container.ContainerType) end

function BaggageController.Start(self: BaggageController) end

return BaggageController
