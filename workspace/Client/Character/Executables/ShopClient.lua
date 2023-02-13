local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local camera = workspace.CurrentCamera
local shopCamera = workspace.Shop.ShopCamera
local shopInteract = workspace.Shop.ShopInteract.Prompt

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local playerGui = player.PlayerGui

local shopUI = playerGui.Shop

local shopInteracted = ReplicatedStorage["Events"].ShopInteracted

local MenuClient = {}

function MenuClient:Run()
	shopInteracted.OnClientEvent:Connect(function()
		shopInteract.Enabled = false
		camera.CameraType = Enum.CameraType.Scriptable

		local cameraTween = TweenService:Create(camera, TweenInfo.new(0.75), { CFrame = shopCamera.CFrame })
		cameraTween:Play()
	end)
end

return MenuClient
