local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local sprint = ReplicatedStorage["Events"].Sprint
local sprintKey = Enum.KeyCode.LeftShift

local RunClient = {}

local function handleSprintInput(_, actionState)
	if actionState == Enum.UserInputState.Begin and humanoid.MoveDirection.Magnitude >= 0 then
		sprint:FireServer(true)
	else
		sprint:FireServer(false)
	end
end

function RunClient:Run()
	ContextActionService:BindAction("StartSprint", handleSprintInput, true, sprintKey)
	ContextActionService:SetImage("StartSprint", "rbxassetid://11684108736")
	ContextActionService:SetPosition("StartSprint", UDim2.new(0.45, 0, 0, 0))
end

return RunClient
