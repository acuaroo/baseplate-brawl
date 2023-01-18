local ReplicatedStorage = game:GetService("ReplicatedStorage")

local neonChannel = ReplicatedStorage["Events"].Neon

local validAdmins = {}

local NeonServer = {}

function NeonServer:Run()
	neonChannel.OnServerEvent:Connect(function(player, commandText) end)
end

return NeonServer
