local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local sprint = ReplicatedStorage["Events"].Sprint
local sprintKey = Enum.KeyCode.LeftShift

local RunClient = {}

function RunClient:Run()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if humanoid.MoveDirection.Magnitude >= 0 and input.KeyCode == sprintKey then
			sprint:FireServer(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == sprintKey then
			sprint:FireServer(false)
		end
	end)
end

return RunClient
