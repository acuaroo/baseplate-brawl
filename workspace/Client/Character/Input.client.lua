-- [[ Input.client.lua ]] --

--[[
    @ Connections @
        UserInputService.InputBegan(inputObject, gameProcessedEvent)
		UserInputService.InputEnded(inputObject, gameProcessedEvent)
		
	@ Structure @
		inputFunctions {
			["Function"] = function(args, ...)
				--<::>--
			end,
		}

		inputMapper {
			["InputType"] = {
				[Enum.InputType.Specfic] = { ["Call"] = "Function", ["Args"] = {} }
			}
		}
]]
--

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lifetime = require(script.Parent:WaitForChild("Lifetime"))
local Anim = require(script.Parent:WaitForChild("Anim"))

local events = ReplicatedStorage:WaitForChild("Events")
local getKeyTool = events["GetKeyTool"]
local requestTool = events["RequestTool"]

local getActiveTool = events["GetActiveTool"]
local toolCall = events["ToolCall"]
local movementCall = events["MovementCall"]

local operatorState = 1

local function clientCycle(cycle, endCycle)
	if not Lifetime[cycle.Name] then
		return
	end

	local clientFunctionName = cycle:GetAttribute("ClientCall")
	local clientFunction = Lifetime[cycle.Name][clientFunctionName]

	if clientFunction then
		clientFunction()
	end

	if endCycle then
		local clientAnimationEnd = cycle:GetAttribute("AnimationEnd")
		local parse = string.split(clientAnimationEnd, "|")

		if parse[1] == "STOP" then
			Anim:StopAnimation(parse[2])
		elseif parse[1] == "PLAY" then
			Anim:PlayAnimation(parse[2])
		end

		return
	else
		local clientAnimationStart = cycle:GetAttribute("AnimationStart")

		if not clientAnimationStart then
			return
		end

		local operator = cycle:GetAttribute("Operator")
		local animationName = clientAnimationStart

		if operator then
			local splitOperator = string.split(operator, "|")

			animationName = string.gsub(animationName, "@", splitOperator[operatorState])

			if operatorState == 1 then
				operatorState += 1
			else
				operatorState -= 1
			end
		end

		Anim:PlayAnimation(animationName)

		return
	end
end

local inputFunctions = {
	["CheckToolKey"] = function(key)
		local tool = getKeyTool:Invoke(key)

		if tool then
			local toolName = tool["name"]
			local valid, cycle = requestTool:InvokeServer(toolName)

			if not valid or not cycle then
				return
			end

			clientCycle(cycle, false)
		end
	end,
	["Activate"] = function()
		local activeTool = getActiveTool:Invoke()

		if activeTool and activeTool.Lifetime:FindFirstChild("Activate") then
			local toolName = activeTool.Name
			local valid, cycle = toolCall:InvokeServer(toolName, "Activate")

			if not valid or not cycle then
				return
			end

			clientCycle(cycle, false)
		end
	end,
	["SprintStart"] = function()
		local valid = movementCall:InvokeServer(true)

		if valid then
			Anim:PlayAnimation("Sprint")
		end
	end,
	["SprintEnd"] = function()
		local valid = movementCall:InvokeServer(false)

		if valid then
			Anim:StopAnimation("Sprint")
		end
	end,
	["OffhandStart"] = function()
		local activeTool = getActiveTool:Invoke()

		if activeTool and activeTool.Lifetime:FindFirstChild("Offhand") then
			local toolName = activeTool.Name
			local valid, cycle = toolCall:InvokeServer(toolName, "Offhand|Start")

			if not valid or not cycle then
				return
			end

			clientCycle(cycle, false)
		end
	end,
	["OffhandEnd"] = function()
		local activeTool = getActiveTool:Invoke()

		if activeTool and activeTool.Lifetime:FindFirstChild("Offhand") then
			local toolName = activeTool.Name
			local valid, cycle = toolCall:InvokeServer(toolName, "Offhand|End")

			if not valid or not cycle then
				return
			end

			clientCycle(cycle, true)
		end
	end,
}

local inputMapper = {
	["KeyCode"] = {
		[Enum.KeyCode.One] = { ["Call"] = "CheckToolKey", ["Args"] = 1 },
		[Enum.KeyCode.Two] = { ["Call"] = "CheckToolKey", ["Args"] = 2 },
		[Enum.KeyCode.Three] = { ["Call"] = "CheckToolKey", ["Args"] = 3 },
		[Enum.KeyCode.Four] = { ["Call"] = "CheckToolKey", ["Args"] = 4 },
		[Enum.KeyCode.Five] = { ["Call"] = "CheckToolKey", ["Args"] = 5 },
		[Enum.KeyCode.Six] = { ["Call"] = "CheckToolKey", ["Args"] = 6 },
		[Enum.KeyCode.LeftShift] = { ["Call"] = "SprintStart", ["Args"] = nil },
		[Enum.KeyCode.F] = { ["Call"] = "OffhandStart", ["Args"] = nil },
	},
	["KeyCodeEnded"] = {
		[Enum.KeyCode.LeftShift] = { ["Call"] = "SprintEnd", ["Args"] = nil },
		[Enum.KeyCode.F] = { ["Call"] = "OffhandEnd", ["Args"] = nil },
	},
	["MouseButton"] = {
		[Enum.UserInputType.MouseButton1] = { ["Call"] = "Activate", ["Args"] = nil },
	},
}

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	local inputType = input.UserInputType
	local inputMap

	if inputType == Enum.UserInputType.Keyboard then
		local keyCode = input.KeyCode
		inputMap = inputMapper["KeyCode"][keyCode]
	elseif inputType == Enum.UserInputType.MouseButton1 then
		inputMap = inputMapper["MouseButton"][Enum.UserInputType.MouseButton1]
	end

	if inputMap then
		local inputCall = inputMap["Call"]
		local inputArgs = inputMap["Args"]

		task.spawn(inputFunctions[inputCall], inputArgs)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	local inputType = input.UserInputType
	local inputMap

	if inputType == Enum.UserInputType.Keyboard then
		local keyCode = input.KeyCode
		inputMap = inputMapper["KeyCodeEnded"][keyCode]
	end

	if inputMap then
		local inputCall = inputMap["Call"]
		local inputArgs = inputMap["Args"]

		task.spawn(inputFunctions[inputCall], inputArgs)
	end
end)
