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

local function lifetimeUpdate(cycle)
	if not Lifetime[cycle.Name] then
		return
	end

	local serverFunctionName = cycle:GetAttribute("ServerCall")
	local serverFunction = Lifetime[cycle.Name][serverFunctionName]

	if serverFunction then
		serverFunction()
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

		if characterTool then
			humanoid:UnequipTools()
			lifetimeUpdate(characterTool.Lifetime.Unequip)
			return true, characterTool.Lifetime.Unequip
		elseif backpackTool then
			humanoid:UnequipTools()
			humanoid:EquipTool(backpackTool)
			lifetimeUpdate(backpackTool.Lifetime.Equip)
			return true, backpackTool.Lifetime.Equip
		end
	else
		return false, nil
	end
end
