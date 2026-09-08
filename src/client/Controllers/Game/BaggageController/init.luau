--!strict

--[=[
    @class BaggageController
]=]

------------------------------
-- SERVICES --
------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

------------------------------
-- LOCAL --
------------------------------
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

------------------------------
-- NETWORK --
------------------------------
local Network = require(ReplicatedStorage.Forge.Shared.Network)
local GameNet = Network.Game

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

local BaggageController = {}
BaggageController.__index = BaggageController

export type BaggageController = typeof(setmetatable({}, BaggageController))

function BaggageController.create(): BaggageController
	return setmetatable({}, BaggageController)
end

function BaggageController.Init(self: BaggageController, container: Container.ContainerType) end

function BaggageController.Start(self: BaggageController)
	--// Waypoint references
	local baggageWaypoints = workspace.WorldCore.BaggageWaypoints
	self._startWaypoint = baggageWaypoints:WaitForChild("Start")
	self._endWaypoint = baggageWaypoints:WaitForChild("End")

	--// Tween infos
	self._moveTweenInfo = TweenInfo.new(ConveyorConfig.MoveDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	self._popInTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	self._shrinkTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	GameNet.spawnBaggage.listen(function(data)
		self:_spawnBag(data)
	end)

	self:_hydrateUi()
end

function BaggageController._spawnBag(self: BaggageController, data)
	--// Asset reference
	local baggage = ReplicatedStorage.Assets.Baggage
	local originalSize = baggage.Size

	local baggageClone = baggage:Clone()
	baggageClone.BrickColor = ColorIdMap[data.colorId]
	baggageClone.Material = MaterialIdMap[data.materialId]
	baggageClone.Position = self._startWaypoint.Position
	baggageClone.Parent = workspace

	local clickDetector = baggageClone:WaitForChild("ClickDetector")
	clickDetector.MouseClick:Connect(function()
		GameNet.viewBaggage.send(data.id)
		print(data.id)
	end)

	--// start smol and add randomized y axis rot so it looks natural
	baggageClone.Size = Vector3.new(0.001, 0.001, 0.001)
	baggageClone.CFrame = baggageClone.CFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)

	local popInTween = TweenService:Create(baggageClone, self._popInTweenInfo, { Size = originalSize })
	local moveTween = TweenService:Create(baggageClone, self._moveTweenInfo, { Position = self._endWaypoint.Position })
	local shrinkTween =
		TweenService:Create(baggageClone, self._shrinkTweenInfo, { Size = Vector3.new(0.001, 0.001, 0.001) })

	popInTween.Completed:Once(function()
		moveTween:Play()
	end)

	moveTween.Completed:Once(function()
		shrinkTween:Play()
	end)

	shrinkTween.Completed:Once(function()
		baggageClone:Destroy()
	end)

	popInTween:Play()
end

function BaggageController._hydrateUi(self: BaggageController)
	local sixSevenGui = playerGui:WaitForChild("SixSeven")
	local contentFrame = sixSevenGui.content
	local spawnRateDisplay = contentFrame.SpawnRateDisplay
	local trackFrame = contentFrame.Track
	local sliderBtn = trackFrame.Slider

	self:_setupSlider(sliderBtn, trackFrame, spawnRateDisplay, ConveyorConfig.MaxSpawnRate)
end

function BaggageController._setupSlider(self: BaggageController, sliderBtn, trackFrame, spawnRateDisplay, maxValue)
	local dragging = false

	local function updateSliderFromInput(input: InputObject)
		local trackAbsPos = trackFrame.AbsolutePosition.X
		local trackAbsSize = trackFrame.AbsoluteSize.X

		--// clamp 0..1 based on mouse/touch x relative to track
		local relativeX = (input.Position.X - trackAbsPos) / trackAbsSize
		local alpha = math.clamp(relativeX, 0, 1)

		--// move the slider button
		sliderBtn.Position = UDim2.new(alpha, 0, sliderBtn.Position.Y.Scale, sliderBtn.Position.Y.Offset)

		local value = math.round(alpha * maxValue)
		return value
	end

	sliderBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSliderFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			local finalValue = updateSliderFromInput(input)
			local clampedValue = math.clamp(finalValue, 1, maxValue)
			spawnRateDisplay.Text = `Spawn Rate: {clampedValue}/s`

			GameNet.setSpawnRate.send(clampedValue)
		end
	end)
end

return BaggageController
