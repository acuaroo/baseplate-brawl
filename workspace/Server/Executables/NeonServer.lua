local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local neonChannel = ReplicatedStorage["Events"].Neon
local neonUI = ServerStorage["UI"].Neon

local validAdmins = { [3251858224] = true, [1749410580] = true, [1471250069] = true, [167648170] = true }
local commands = script.Parent.Commands

local NeonServer = {}

local function parse(commandText)
	local splitCommand = string.lower(string.split(commandText, " "))
	local specialArgs = {
		["Name"] = splitCommand[1],
	}
	return splitCommand, specialArgs
end

function NeonServer:Run()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(_)
			if validAdmins[player.UserId] then
				print("[NEON]: Stalling for 5 seconds...")
				task.wait(5)
				neonUI:Clone().Parent = player.PlayerGui
			end
		end)
	end)

	neonChannel.OnServerEvent:Connect(function(player, commandText)
		if not validAdmins[player.UserId] then
			return
		end

		local args, extraArgs = parse(commandText)

		if not extraArgs["Name"] then
			return
		end

		if not commands[extraArgs["Name"]] then
			return
		end

		require(commands[extraArgs["Name"]]):Run(args)
	end)
end

return NeonServer
