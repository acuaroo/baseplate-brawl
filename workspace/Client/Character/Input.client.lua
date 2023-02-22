-- [[ Input.client.lua ]] --

--[[
    @ Connections @
        UserInputService.InputBegan()
            -> Maps key to inputFunction
			-> Calls inputFunction
]]
--

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lifetime = require(script.Parent:WaitForChild("Lifetime"))

local events = ReplicatedStorage:WaitForChild("Events")
local getKeyTool = events["GetKeyTool"]
local requestTool = events["RequestTool"]

local inputFunctions = {
	["CheckToolKey"] = function(key)
		local tool = getKeyTool:Invoke(key)

		if tool then
			local toolName = tool["name"]
			local valid, cycle = requestTool:InvokeServer(toolName)

			if not valid or not cycle then
				return
			end

			if not Lifetime[cycle.Name] then
				return
			end

			local clientFunctionName = cycle:GetAttribute("ClientCall")
			local clientFunction = Lifetime[cycle.Name][clientFunctionName]

			if clientFunction then
				clientFunction()
			end
		end
	end,
	["Activate"] = function(key) end,
}

local inputMapper = {
	["KeyCode"] = {
		[Enum.KeyCode.One] = { ["Call"] = "CheckToolKey", ["Args"] = 1 },
		[Enum.KeyCode.Two] = { ["Call"] = "CheckToolKey", ["Args"] = 2 },
		[Enum.KeyCode.Three] = { ["Call"] = "CheckToolKey", ["Args"] = 3 },
		[Enum.KeyCode.Four] = { ["Call"] = "CheckToolKey", ["Args"] = 4 },
		[Enum.KeyCode.Five] = { ["Call"] = "CheckToolKey", ["Args"] = 5 },
		[Enum.KeyCode.Six] = { ["Call"] = "CheckToolKey", ["Args"] = 6 },
	},
}

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	local inputType = input.UserInputType

	if inputType == Enum.UserInputType.Keyboard then
		local keyCode = input.KeyCode
		local inputMap = inputMapper["KeyCode"][keyCode]

		if inputMap then
			local inputCall = inputMap["Call"]
			local inputArgs = inputMap["Args"]

			inputFunctions[inputCall](inputArgs)
		end
	elseif inputType == Enum.UserInputType.MouseButton1 then
	end
end)
