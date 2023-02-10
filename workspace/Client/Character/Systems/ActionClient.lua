local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local network = ReplicatedStorage["Network"]

local combatRequest = network:WaitForChild("CombatRequest")
-- local movementRequest = network:WaitForChild("MovementRequest")
-- local renderRequest = network:WaitForChild("RenderRequest")

local ActionClient = {}

local function handleEquipping()
	combatRequest:FireServer()
end

local inputTable = {
	["KeyCode"] = {
		[Enum.KeyCode.One] = handleEquipping,
		[Enum.KeyCode.Two] = handleEquipping,
		[Enum.KeyCode.Three] = handleEquipping,
		[Enum.KeyCode.Four] = handleEquipping,
		[Enum.KeyCode.Five] = handleEquipping,
		[Enum.KeyCode.Six] = handleEquipping,
	},
}

function ActionClient:Start()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		local validKeyCode = inputTable["KeyCode"][input.KeyCode]

		if validKeyCode then
			validKeyCode()
		end
	end)
end

return ActionClient
