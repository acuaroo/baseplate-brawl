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
local PlayerCache = {}
Players.__index = Players

function Players:UpdateState(state, value, duration, reset)
	local currentState = table.clone(self._playerReplica[state])

	if typeof(currentState) == "table" then
		self._playerReplica:SetValue({ state }, table.insert(currentState, value))
		local position = table.find(currentState, value)

		task.delay(duration, function()
			self._playerReplica:SetValue({ state }, table.remove(currentState, position))

			--</ Cleanup for the table.clone state?
			currentState = nil
		end)
	else
		self._playerReplica:SetValue({ state }, value)

		task.delay(duration, function()
			self._playerReplica:SetValue({ state }, reset)

			--</ Cleanup for the table.clone state?
			currentState = nil
		end)
	end
end

function Players:GetMetaplayer(player)
	local metaplayer = nil

	for _, mplayer in Players do
		if mplayer._playerObject == player then
			metaplayer = mplayer
			break
		end
	end

	return metaplayer
end

PlayerService.PlayerAdded:Connect(function(player)
	local playerProfile = Data:ProfilePlayer(player)
	local self = setmetatable({}, Players)

	self._playerObject = player
	self._playerProfile = playerProfile

	self.State = {
		Game = "GAME",
		Movement = "WALKING",
		Rapid = {},
		Debounces = {},
		CombatTagged = 0,
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

return Players
