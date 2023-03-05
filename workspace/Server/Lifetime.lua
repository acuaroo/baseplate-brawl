-- [[ Lifetime.lua ]] --

--[[
	@ Structure @
		Lifetime = {
			["Category"] = {
				["Function"] = function(args, ...) 
					--<::>--
				end,
			},
		}
]]
--
local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ClientCast = require(ServerStorage["Modules"].ClientCast)
local Players = require(script.Parent.Players)
local Util = require(script.Parent.Util)

local events = ReplicatedStorage.Events
local animationRelay = events:WaitForChild("AnimationRelay")

local assets = ServerStorage.Assets
local visuals = assets.Visuals
local shield = visuals.Shield

local preppedTools = {}

local Actions = {}
Actions.__index = Actions

local function prep(player, tool)
	if not preppedTools[player.Name] then
		preppedTools[player.Name] = {}
	end

	local _tool = preppedTools[player.Name][tool.Name]

	if _tool then
		_tool.ToolObject = tool
		_tool.Metaplayer = Players:GetMetaplayer(player)
		_tool.Metaplayer:UpdateState("ActiveTool", tool.Name, nil, nil)

		_tool._config = tool:FindFirstChild("Config")

		return nil
	else
		_tool = { ["ToolObject"] = tool }
		_tool.Metaplayer = Players:GetMetaplayer(player)
		_tool.Metaplayer:UpdateState("ActiveTool", tool.Name, nil, nil)

		_tool._config = tool:FindFirstChild("Config")

		setmetatable(_tool, Actions)

		preppedTools[player.Name][tool.Name] = _tool

		return _tool
	end
end

local function get(player, tool)
	return preppedTools[player.Name][tool.Name]
end

function Actions:Swing()
	self.Caster:Start()
	self.Metaplayer:UpdateSpeed(-4, "DURATION", "MELEE_ACTIVATE", 0.76)

	self._hitDebounce = {}
	self._shieldHitDebounce = {}

	if self._castConnection then
		self._castConnection:Disconnect()
		self._castConnection = nil
	end

	if self._shieldConnection then
		self._shieldConnection:Disconnect()
		self._shieldConnection = nil
	end

	self.Metaplayer:UpdateState("Rapid", "ACTIVATE", 0.76)
	self.Metaplayer:UpdateState("Debounces", "MELEE_ACTIVATE", 0.76)

	self.interject = false

	self._castConnection = self.Caster.HumanoidCollided:Connect(function(ray, humanoid)
		if self._hitDebounce[humanoid] or self.interject then
			return
		end

		self._hitDebounce[humanoid] = true

		local rayShield = humanoid.Parent:FindFirstChild("Shield")

		if rayShield then
			local vectorDiff = humanoid.Parent.HumanoidRootPart.Position
				- self.PlayerCharacter.HumanoidRootPart.Position
			local vectorDir = vectorDiff.Unit

			local angle = math.acos(humanoid.Parent.HumanoidRootPart.CFrame.LookVector:Dot(vectorDir))

			if angle >= math.rad(90) then
				self:_shieldHitProcess({ Instance = rayShield })
				return
			end
		end

		local enemy = PlayerService:GetPlayerFromCharacter(humanoid.Parent)
		local metaenemy = Players:GetMetaplayer(enemy)

		local operator = string.split("L|R", "|")[math.random(1, 2)]
		local animationName = "Melee@Hit"

		animationName = string.gsub(animationName, "@", operator)

		if enemy then
			animationRelay:FireClient(enemy, animationName, nil, "PLAY")
			metaenemy:UpdateState("Rapid", "STUN", 0.96)
		else
			local animationTrack = humanoid:LoadAnimation(ReplicatedStorage.Animations[animationName])
			animationTrack:Play()
		end

		Util["Damage"](self.Metaplayer, humanoid, self._config, ray.Instance)

		self.Caster:Stop()
	end)

	self._shieldConnection = self.Caster.Collided:Connect(function(ray)
		if ray.Instance.Name == "Shield" then
			self:_shieldHitProcess(ray)
		end
	end)
end

function Actions:Shield()
	self.Metaplayer:UpdateState("Rapid", "SHIELD")
	self.Metaplayer:UpdateSpeed(-8, "DEFAULT", "SHIELD")

	local character = self.PlayerCharacter
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	self._shield = shield:Clone()
	self._shield.Parent = character

	self._shield.CFrame = (humanoidRootPart.CFrame * CFrame.new(0, 0, -2))
		* CFrame.Angles(math.rad(90), 0, math.rad(180))

	self._shieldWeld = Instance.new("WeldConstraint")
	self._shieldWeld.Parent = self._shield
	self._shieldWeld.Part0 = self._shield
	self._shieldWeld.Part1 = humanoidRootPart
end

function Actions:ShieldStop()
	self.Metaplayer:RemoveState("Rapid", "SHIELD")
	self.Metaplayer:UpdateSpeed(8, "RETURN", "SHIELD")

	if self._shield then
		self._shield:Destroy()
		self._shield = nil
	end

	if self._shieldWeld then
		self._shieldWeld:Destroy()
		self._shieldWeld = nil
	end

	self.Metaplayer:UpdateState("Debounces", "SHIELD_ACTIVATE", 1.25)
end

function Actions:MeleeCleanup()
	if self._castConnection then
		self._castConnection:Disconnect()
		self._castConnection = nil
	end

	if self._shieldConnection then
		self._shieldConnection:Disconnect()
		self._shieldConnection = nil
	end

	self._hitDebounce = {}
	self._shieldHitDebounce = {}

	self:ShieldStop()

	animationRelay:FireClient(self.Player, "MeleeLSwing", nil, "STOP")
	animationRelay:FireClient(self.Player, "MeleeRSwing", nil, "STOP")
	animationRelay:FireClient(self.Player, "MeleeOffhand", nil, "STOP")
end

function Actions:_shieldHitProcess(ray)
	local rayShield = ray.Instance
	local enemy = rayShield.Parent

	--local metaenemy = Players:GetMetaplayerFromCharacter(enemy)
	local enemyObj = PlayerService:GetPlayerFromCharacter(enemy)

	self.interject = true

	if self._shieldHitDebounce[ray.Instance] then
		return
	end

	self._shieldHitDebounce[ray.Instance] = true

	local shieldHealth = rayShield:GetAttribute("Health")
	local knockPower = rayShield:GetAttribute("KnockPower")
	local knockDuration = rayShield:GetAttribute("KnockDuration")
	local platformDuration = rayShield:GetAttribute("PlatformDuration")

	local character = self.PlayerCharacter
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	rayShield:SetAttribute("Health", shieldHealth - 1)
	self.Metaplayer:UpdateState("Rapid", "STUN", knockDuration)

	self._knockbackAttachment = Instance.new("Attachment")
	self._knockbackAttachment.Parent = humanoidRootPart
	self._knockbackAttachment.Name = "KNOCKATTACHMENT"

	self._linearKnockback = Instance.new("LinearVelocity")
	self._linearKnockback.Attachment0 = self._knockbackAttachment
	self._linearKnockback.Parent = self._knockbackAttachment

	self._linearKnockback.MaxForce = math.huge

	self._linearKnockback.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	self._linearKnockback.VectorVelocity = humanoidRootPart.CFrame.LookVector * -knockPower

	if shieldHealth <= 0 then
		rayShield:Destroy()

		animationRelay:FireClient(self.Player, "Stun", knockDuration, "PLAY")
		animationRelay:FireClient(enemyObj, "MeleeOffhand", nil, "STOP")
	end

	task.delay(knockDuration, function()
		if self._knockbackAttachment then
			self._knockbackAttachment:Destroy()
			self._knockbackAttachment = nil
		end

		if self._linearKnockback then
			self._linearKnockback:Destroy()
			self._linearKnockback = nil
		end

		task.wait(platformDuration)
		self.interject = false

		self.Metaplayer:RemoveState("Rapid", "STUN")
	end)
end

local Lifetime = {
	["Equip"] = {
		["meleePrep"] = function(player, tool)
			local _tool = prep(player, tool)

			if not _tool then
				return true, tool.Lifetime.Equip
			end

			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { player.Character }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local caster = ClientCast.new(tool.Handle, rayParams)
			_tool.Caster = caster
			_tool.PlayerCharacter = player.Character
			_tool.Player = player

			return true, tool.Lifetime.Equip
		end,
	},
	["Activate"] = {
		["meleeSwing"] = function(player, tool)
			local _tool = get(player, tool)

			if not _tool then
				return false, nil
			end

			local debounceState = _tool.Metaplayer:GetState("Debounces")
			local movementState = _tool.Metaplayer:GetState("Movement")
			local rapidState = _tool.Metaplayer:GetState("Rapid")

			if table.find(debounceState, "MELEE_ACTIVATE") then
				return false, nil
			end

			if movementState == "RUNNING" then
				return false, nil
			end

			if table.find(rapidState, "SHIELD") or table.find(rapidState, "STUN") then
				return false, nil
			end

			_tool:Swing()

			return true, tool.Lifetime.Activate
		end,
	},
	["OffhandStart"] = {
		["meleeOffhand"] = function(player, tool)
			local _tool = get(player, tool)

			if not _tool then
				return false, nil
			end

			local rapidState = _tool.Metaplayer:GetState("Rapid")
			local movementState = _tool.Metaplayer:GetState("Movement")

			if table.find(rapidState, "ACTIVATE") then
				return false, nil
			end

			if table.find(rapidState, "STUN") then
				return false, nil
			end

			if movementState == "RUNNING" or movementState == "ROLLING" then
				return false, nil
			end

			_tool:Shield()

			return true, tool.Lifetime.Offhand
		end,
	},
	["OffhandEnd"] = {
		["meleeOffhand"] = function(player, tool)
			local _tool = get(player, tool)

			if not _tool then
				return false, nil
			end

			_tool:ShieldStop(player)

			return true, tool.Lifetime.Offhand
		end,
	},
	["Ability"] = {},
	["Unequip"] = {
		["meleeUneq"] = function(player, tool)
			local _tool = get(player, tool)

			if not _tool then
				return false, nil
			end

			local rapidState = _tool.Metaplayer:GetState("Rapid")

			if
				table.find(rapidState, "STUN")
				or table.find(rapidState, "ACTIVATE")
				or table.find(rapidState, "SHIELD")
			then
				return false, nil
			end

			_tool.Metaplayer:UpdateState("ActiveTool", "NONE", nil, nil)
			_tool:MeleeCleanup()

			return true, tool.Lifetime.Unequip
		end,
	},
}

return Lifetime
