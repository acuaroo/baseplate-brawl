local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local neonChannel = ReplicatedStorage["Events"].Neon
local neonUI = ServerStorage["UI"].Neon

local validAdmins = { 3251858224, 1749410580, 1471250069, 167648170 }

local NeonServer = {}

function NeonServer:Run()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(_)
			print(player.UserId)
			if table.find(validAdmins, player.UserId) then
				task.wait(3)
				neonUI:Clone().Parent = player.PlayerGui
			end
		end)
	end)

	neonChannel.OnServerEvent:Connect(function(player, commandText) end)
end

return NeonServer
