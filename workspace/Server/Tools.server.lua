-- [[ Tools.server.lua ]] --

--[[
    @ Connections @
        requestTool.OnServerInvoke = function()
            -> Returns validity and lifetime cycle
			-> Calls lifetime cycle for the server
]]
--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(script.Parent.Data)
local Lifetime = require(script.Parent.Lifetime)

local events = ReplicatedStorage:WaitForChild("Events")
local requestTool = events["RequestTool"]
local toolCall = events["ToolCall"]

local function lifetimeUpdate(cycle, tail, ...)
	if not tail then
		tail = ""
	end

	if not Lifetime[cycle.Name .. tail] then
		return
	end

	local serverFunctionName = cycle:GetAttribute("ServerCall")
	local serverFunction = Lifetime[cycle.Name .. tail][serverFunctionName]

	if serverFunction then
		return serverFunction(...)
	else
		return false, nil
	end
end

requestTool.OnServerInvoke = function(player, toolName)
	local hasTool = Data:CheckHotbar(player, toolName)
	local characterTool = player.Character:FindFirstChild(toolName)
	local backpackTool = player.Backpack:FindFirstChild(toolName)

	if hasTool then
		local character = player.Character

		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")

		if not humanoid then
			return
		end

		humanoid:UnequipTools()

		if characterTool then
			lifetimeUpdate(characterTool.Lifetime.Unequip, nil, player, characterTool)

			return true, characterTool.Lifetime.Unequip
		elseif backpackTool then
			humanoid:EquipTool(backpackTool)

			lifetimeUpdate(backpackTool.Lifetime.Equip, nil, player, backpackTool)

			return true, backpackTool.Lifetime.Equip
		end
	else
		return false, nil
	end
end

toolCall.OnServerInvoke = function(player, toolName, request)
	local split = string.split(request, "|")
	local requestMain = split[1]
	local requestTail = split[2]

	local hasTool = Data:CheckHotbar(player, toolName)
	local characterTool = player.Character:FindFirstChild(toolName)

	if hasTool and characterTool then
		local lifetimeFromRequest = characterTool.Lifetime:FindFirstChild(requestMain)

		if not lifetimeFromRequest then
			return false, nil
		end

		return lifetimeUpdate(lifetimeFromRequest, requestTail, player, characterTool)
	else
		return false, nil
	end
end
