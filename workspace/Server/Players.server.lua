-- [[ Players.server.lua ]] --

--[[
    @ Connections @
        PlayerService.PlayerAdded() 
            -> Creates the metaplayer
            -> Creates the player replica
            -> Creates the player profile
]]
--

local PlayerService = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicaService = require(ServerStorage.Modules["ReplicaService"])
local Data = require(script.Parent.Data)

local Players = {}
Players.__index = Players

PlayerService.PlayerAdded:Connect(function(player)
	local playerProfile = Data:ProfilePlayer(player)
	local self = setmetatable({}, Players)

	self._playerObject = player
	self._playerProfile = playerProfile

	self.State = {
		Main = {
			Game = "GAME",
			Movement = "WALKING",
			Rapid = {},
			Debounces = {},
			CombatTagged = 0,
		},
		Hotbar = self._playerProfile.Data.hotbar,
		Inventory = self._playerProfile.Data.inventory,
	}

	self._playerReplica = ReplicaService.NewReplica({
		ClassToken = ReplicaService.NewClassToken(tostring(player.UserId .. "_replica")),
		Data = self.State,
		Replication = player,
	})

	return self
end)
