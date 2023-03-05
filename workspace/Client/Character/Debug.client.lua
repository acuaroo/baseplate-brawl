local PlayerService = game:GetService("Players")
local State = require(script.Parent:WaitForChild("State"))

local player = PlayerService.LocalPlayer
local _character = player.Character or player.CharacterAdded:Wait()
local playerGui = player.PlayerGui

local debugGui = playerGui.Debug
local debugFrame = debugGui.DebugFrame
local template = debugFrame.UIListLayout.Template

local function rapid()
	local rapidState = State:GetState().Rapid

	local rapidLabel = debugFrame:FindFirstChild("Rapid") or template:Clone()
	rapidLabel.Parent = debugFrame
	rapidLabel.Name = "Rapid"

	rapidLabel.Text = "RAPID: { " .. table.concat(rapidState, ", ") .. " }"
end

local function hotbar()
	local hotbarState = State:GetState().Hotbar

	local hotbarLabel = debugFrame:FindFirstChild("Hotbar") or template:Clone()
	hotbarLabel.Parent = debugFrame
	hotbarLabel.Name = "Hotbar"

	hotbarLabel.Text = "HOTBAR: { " .. table.concat(hotbarState, ", ") .. " }"
end

local function activeTool()
	local activeToolState = State:GetState().ActiveTool

	local activeToolLabel = debugFrame:FindFirstChild("ActiveTool") or template:Clone()
	activeToolLabel.Parent = debugFrame
	activeToolLabel.Name = "ActiveTool"

	activeToolLabel.Text = "ACTIVE TOOL: " .. activeToolState
end

local function debounces()
	local debouncesState = State:GetState().Debounces

	local debouncesLabel = debugFrame:FindFirstChild("Debounces") or template:Clone()
	debouncesLabel.Parent = debugFrame
	debouncesLabel.Name = "Debounces"

	debouncesLabel.Text = "DEBOUNCES: { " .. table.concat(debouncesState, ", ") .. " }"
end

local function movement()
	local movementState = State:GetState().Movement

	local movementLabel = debugFrame:FindFirstChild("Movement") or template:Clone()
	movementLabel.Parent = debugFrame
	movementLabel.Name = "Movement"

	movementLabel.Text = "MOVEMENT: " .. movementState
end

State.Connect(rapid, "Rapid")
State.Connect(hotbar, "Hotbar")
State.Connect(activeTool, "ActiveTool")
State.Connect(debounces, "Debounces")
State.Connect(movement, "Movement")
