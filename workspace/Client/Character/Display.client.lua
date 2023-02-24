-- [[ Display.client.lua ]] --

--[[
    @ Connections @
        State.Connect(_, ...)
            -> Loads the hotbar
            -> Updates the hotbar
            
]]
--

local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local State = require(script.Parent:WaitForChild("State"))
local Util = require(script.Parent:WaitForChild("Util"))

local events = ReplicatedStorage:WaitForChild("Events")
local getKeyTool = events["GetKeyTool"]
local getActiveTool = events["GetActiveTool"]

local player = PlayerService.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local playerGui = player.PlayerGui

local hotbarGui = playerGui.Hotbar
local statsFrame = hotbarGui.StatsFrame
local hotbarFrame = statsFrame.HotbarFrame

local toolBuilds = ReplicatedStorage:WaitForChild("ToolBuilds")
local hotbarTools

local function loadHotbar()
	hotbarTools = State:GetState().Hotbar

	for _, slot in pairs(hotbarFrame:GetChildren()) do
		if slot:IsA("TextButton") then
			local slotViewport = slot:WaitForChild("ImageViewport")
			slotViewport:ClearAllChildren()
		end
	end

	for index, tool in hotbarTools do
		local toolBuild = toolBuilds:FindFirstChild(tool["name"])

		if toolBuild then
			toolBuild = toolBuild:Clone()

			local slot = hotbarFrame:WaitForChild("Slot" .. tostring(index))
			local slotViewport = slot:WaitForChild("ImageViewport")

			Util["ViewportModel"](toolBuild, slotViewport)
		end
	end
end

loadHotbar()

State.Connect(loadHotbar, "Hotbar")

getKeyTool.OnInvoke = function(key)
	return hotbarTools[key]
end

getActiveTool.OnInvoke = function()
	local activeTool = State:GetState().ActiveTool

	return character:FindFirstChild(activeTool)
end
