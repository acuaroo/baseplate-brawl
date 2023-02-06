local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local sprint = ReplicatedStorage["Events"].Sprint
local roll = ReplicatedStorage["Events"].Roll
local rollDebounce = ReplicatedStorage["Events"].RollDebounce

local sprintKey = Enum.KeyCode.LeftShift
local rollKey = Enum.KeyCode.E

local MovementClient = {}

local function handleSprintInput(_, actionState)
	if actionState == Enum.UserInputState.Begin and humanoid.MoveDirection.Magnitude >= 0 then
		sprint:FireServer(true)
	elseif actionState == Enum.UserInputState.End then
		sprint:FireServer(false)
	end
end

local function handleRollInput(_, actionState)
	if actionState == Enum.UserInputState.Begin and humanoid.MoveDirection.Magnitude >= 0 then
		local valid = roll:InvokeServer()

		if valid then
			rollDebounce:Fire()
		end
	end
end

function MovementClient:Run()
	ContextActionService:BindAction("Sprint", handleSprintInput, false, sprintKey)
	ContextActionService:BindAction("Roll", handleRollInput, false, rollKey)

	-- ContextActionService:SetImage("StartSprint", "rbxassetid://11684108736")
	-- ContextActionService:SetPosition("StartSprint", UDim2.new(0.45, 0, 0, 0))
end

return MovementClient
