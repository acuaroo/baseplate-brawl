-- [[ State.client.lua ]] --

--[[
    @ Public @
        State:GetState()
        State:Connect(callback, name)

    @ Private @
        State:_changed(name)

    @ Connections @
        ReplicaController.ReplicaOfClassCreated(player.UserId .. "_replica", function(replica)
        replica:ListenToChange({ "STATENAME" }, function(new, _)
            
]]
--
local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaController = require(ReplicatedStorage.Shared["ReplicaController"])

local player = PlayerService.LocalPlayer

local connections = {}

local State = {}

State.replicaState = {}
State.loaded = false

function State:GetState()
	while not State.loaded do
		task.wait()
	end

	return State.replicaState
end

function State:_changed(name)
	if not connections[name] then
		return
	end

	for _, connection in connections[name] do
		connection()
	end
end

function State.Connect(callback, name)
	connections[name] = callback
end

ReplicaController.ReplicaOfClassCreated(player.UserId .. "_replica", function(replica)
	State.replicaState = replica.Data
	State.loaded = true

	replica:ListenToChange({ "Rapid" }, function(new, _)
		State.replicaState.Rapid = new
		State:_changed("Rapid")
	end)

	replica:ListenToChange({ "Hotbar" }, function(new, _)
		State.replicaState.Hotbar = new
		State:_changed("Hotbar")
	end)

	replica:ListenToChange({ "Inventory" }, function(new, _)
		State.replicaState.Inventory = new
		State:_changed("Inventory")
	end)

	replica:ListenToChange({ "ActiveTool" }, function(new, _)
		State.replicaState.ActiveTool = new
		State:_changed("ActiveTool")
	end)

	replica:ListenToChange({ "Debounces" }, function(new, _)
		State.replicaState.Debounces = new
		State:_changed("Debounces")
	end)

	replica:ListenToChange({ "Movement" }, function(new, _)
		State.replicaState.Debounces = new
		State:_changed("Movement")
	end)
end)

ReplicaController.RequestData()

return State
