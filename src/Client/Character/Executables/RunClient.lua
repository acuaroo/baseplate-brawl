local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local sprint = ReplicatedStorage["Events"].Sprint

local RunClient = {}

function RunClient:Run()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if humanoid.MoveDirection.Magnitude >= 0 then
			if input.KeyCode == Enum.KeyCode.LeftShift then
				sprint:FireServer(true)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprint:FireServer(false)
		end
	end)
end

return RunClient
