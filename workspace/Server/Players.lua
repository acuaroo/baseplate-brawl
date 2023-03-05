-- [[ Players.server.lua ]] --

--[[
    @ Connections @
        PlayerService.PlayerAdded(player)
		movementCall.OnServerInvoke = function(player, enable)

	@ Public @
		Players:UpdateState(state, value, duration, reset)
		Players:GetState(state)		
		Players:GetMetaplayer(player)
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
local animationRelay = events:WaitForChild("AnimationRelay")

local sprintTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

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

function Players:RemoveState(state, value)
	local dummyState = self._playerReplica.Data[state]

	if typeof(dummyState) == "table" then
		dummyState = table.clone(dummyState)

		if #dummyState > 0 then
			local position = table.find(dummyState, value)

			if not position then
				return
			end

			table.remove(dummyState, position)
			self._playerReplica:SetValue({ state }, dummyState)
		end
	else
		self._playerReplica:SetValue({ state }, nil)
	end
end

function Players:UpdateSpeed(speed, returnHandler, id, duration, humanoidReflect)
	if returnHandler == "DEFAULT" then
		self.Speed += speed

		if humanoidReflect ~= "STOP" then
			self._playerObject.Character.Humanoid.WalkSpeed = self.Speed
		end

		self._speedList = self._speedList or {}

		table.insert(self._speedList, { ["ID"] = id, ["Speed"] = speed, ["Return"] = returnHandler })
	elseif returnHandler == "RETURN" then
		if not self._speedList then
			return
		end

		for locus, speedData in self._speedList do
			if speedData.ID ~= id then
				continue
			end

			self.Speed -= speedData.Speed
			self._playerObject.Character.Humanoid.WalkSpeed = self.Speed

			table.remove(self._speedList, locus)
			break
		end
	elseif returnHandler == "DURATION" then
		self.Speed += speed

		if humanoidReflect ~= "STOP" then
			self._playerObject.Character.Humanoid.WalkSpeed = self.Speed
		end

		self._speedList = self._speedList or {}
		local position = table.insert(self._speedList, { ["ID"] = id, ["Speed"] = speed, ["Return"] = returnHandler })

		task.delay(duration, function()
			self.Speed -= speed
			self._playerObject.Character.Humanoid.WalkSpeed = self.Speed

			table.remove(self._speedList, position)
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

function Players:GetMetaplayerFromCharacter(character)
	local metaplayer = nil

	for _, mplayer in PlayerCache do
		if mplayer._playerObject.Character == character then
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
		CombatTagged = false,
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

	if humanoid.MoveDirection.Magnitude < 0.1 then
		return false
	end

	local rapidState = metaplayer:GetState("Rapid")

	if table.find(rapidState, "STUN") or table.find(rapidState, "ACTIVATE") or table.find(rapidState, "SHIELD") then
		return
	end

	if enable and movementState == "WALKING" then
		metaplayer.Speed = 26

		local sprintTween = TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = metaplayer.Speed })
		sprintTween:Play()

		metaplayer:UpdateState("Movement", "RUNNING", nil, nil)

		task.spawn(function()
			while task.wait() do
				if humanoid.MoveDirection.Magnitude >= 0.1 then
					continue
				end

				metaplayer.Speed = 16

				sprintTween = TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = metaplayer.Speed })
				sprintTween:Play()

				animationRelay:FireClient(player, "Sprint", nil, "STOP")
				metaplayer:UpdateState("Movement", "WALKING", nil, nil)
				break
			end
		end)
	elseif not enable and movementState == "RUNNING" then
		metaplayer.Speed = 16

		local sprintTween = TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = metaplayer.Speed })
		sprintTween:Play()

		metaplayer:UpdateState("Movement", "WALKING", nil, nil)

		task.delay(0.1, function()
			--<: make sure it actually stopped
			animationRelay:FireClient(player, "Sprint", nil, "STOP")
		end)
	end

	return true
end
return Players
