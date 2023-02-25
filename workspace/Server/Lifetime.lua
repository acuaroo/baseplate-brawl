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

	self._hitDebounce = {}

	if self._castConnection then
		self._castConnection:Disconnect()
		self._castConnection = nil
	end

	self.Metaplayer:UpdateState("Rapid", "ACTIVATE", 0.76, nil)
	self.Metaplayer:UpdateState("Debounces", "MELEE_ACTIVATE", 0.76, nil)

	self._castConnection = self.Caster.HumanoidCollided:Connect(function(ray, humanoid)
		if self._hitDebounce[humanoid] then
			return
		end

		self._hitDebounce[humanoid] = true

		local enemy = PlayerService:GetPlayerFromCharacter(humanoid.Parent)
		local metaenemy = Players:GetMetaplayer(enemy)

		local operator = string.split("L|R", "|")[math.random(1, 2)]
		local animationName = "Melee@Hit"

		animationName = string.gsub(animationName, "@", operator)

		if enemy then
			animationRelay:FireClient(enemy, animationName, "PLAY")
			metaenemy:UpdateState("Rapid", "STUN", 0.96, nil)
		else
			local animationTrack = humanoid:LoadAnimation(ReplicatedStorage.Animations[animationName])
			animationTrack:Play()
		end

		Util["Damage"](self.Metaplayer, humanoid, self._config, ray.Instance)

		self.Caster:Stop()
	end)
end

function Actions:Shield()
	print("shielding!")
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

			if table.find(rapidState, "ACTIVATE") then
				return false, nil
			end

			if table.find(rapidState, "STUN") then
				return false, nil
			end

			print("start")
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

			print("stop")

			return true, tool.Lifetime.Offhand
		end,
	},
	["Ability"] = {},
	["Unequip"] = {
		["meleeUneq"] = function(player, tool)
			local _tool = get(player, tool)

			_tool.Metaplayer:UpdateState("ActiveTool", "NONE", nil, nil)

			return true, tool.Lifetime.Unequip
			--_tool:Cleanup()
		end,
	},
}

return Lifetime
