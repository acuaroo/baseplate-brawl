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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ReplicaService = require(ServerStorage.Modules["ReplicaService"])
local Data = require(script.Parent.Data)

local events = ReplicatedStorage:WaitForChild("Events")
local movementCall = events["MovementCall"]

local sprintTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

local Players = {}
local PlayerCache = {}
Players.__index = Players

function Players:UpdateState(state, value, duration, reset)
	-- print(self._playerReplica)
	-- print(self._playerReplica.Data)
	-- print(state)
	local dummyState = self._playerReplica.Data[state]

	if typeof(dummyState) == "table" then
		dummyState = table.clone(dummyState)

		if #dummyState > 0 then
			table.insert(dummyState, value)
			self._playerReplica:SetValue({ state }, dummyState)
		else
			self._playerReplica:SetValue({ state }, { value })
		end

		if not duration then
			return
		end

		task.delay(duration, function()
			dummyState = nil
			dummyState = table.clone(self._playerReplica.Data[state])

			local position = table.find(dummyState, value)

			if not position then
				return
			end

			table.remove(dummyState, position)
			self._playerReplica:SetValue({ state }, dummyState)
		end)
	else
		self._playerReplica:SetValue({ state }, value)

		if not duration then
			return
		end

		task.delay(duration, function()
			self._playerReplica:SetValue({ state }, reset)
		end)
	end
end

function Players:GetState(state)
	return self._playerReplica.Data[state]
end

function Players:GetMetaplayer(player)
	local metaplayer = nil

	for _, mplayer in PlayerCache do
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
	self.Speed = 16

	self.State = {
		Game = "GAME",
		Movement = "WALKING",
		Rapid = {},
		Debounces = {},
		ActiveTool = "NONE",
		CombatTagged = 0,
		Hotbar = self._playerProfile.Data.hotbar,
		Inventory = self._playerProfile.Data.inventory,
	}

	self._playerReplica = ReplicaService.NewReplica({
		ClassToken = ReplicaService.NewClassToken(tostring(player.UserId .. "_replica")),
		Data = self.State,
		Replication = player,
	})

	table.insert(PlayerCache, self)

	return self
end)

movementCall.OnServerInvoke = function(player, enable)
	local metaplayer = Players:GetMetaplayer(player)

	if not metaplayer then
		return false
	end

	local movementState = metaplayer._playerReplica.Data.Movement
	local character = player.Character

	if not character then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")

	if not humanoid then
		return false
	end

	local rapidState = metaplayer:GetState("Rapid")

	if table.find(rapidState, "STUN") then
		return
	end

	if enable and movementState == "WALKING" then
		metaplayer.Speed = 26

		local sprintTween = TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = metaplayer.Speed })
		sprintTween:Play()

		metaplayer:UpdateState("Movement", "RUNNING", nil, nil)
	elseif not enable and movementState == "RUNNING" then
		metaplayer.Speed = 16

		local sprintTween = TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = metaplayer.Speed })
		sprintTween:Play()

		metaplayer:UpdateState("Movement", "WALKING", nil, nil)
	end

	return true
end
return Players
