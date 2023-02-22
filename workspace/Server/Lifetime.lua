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
local ServerStorage = game:GetService("ServerStorage")
local ClientCast = require(ServerStorage["Modules"].ClientCast)
local Players = require(script.Parent.Players)

local preppedTools = {}

local function prep(player, tool)
	if not preppedTools[player.Name] then
		preppedTools[player.Name] = {}
	end

	local _tool = preppedTools[player.Name][tool.Name]

	if _tool then
		return nil
	end

	_tool = { ["ToolObject"] = tool }

	return _tool
end

local function get(player, tool)
	return preppedTools[player.Name][tool.Name]
end

local Actions = {}
Actions.__index = Actions

function Actions:Swing()
	self.Caster:Start()

	self._hitDebounce = {}

	if self._castConnection then
		self._castConnection:Disconnect()
		self._castConnection = nil
	end

	self.Metaplayer:UpdateState("Rapid", "ACTIVATE", 0.96, nil)
	print("ACTOVATE")
end

local Lifetime = {
	["Equip"] = {
		["meleePrep"] = function(player, tool)
			local _tool = prep(player, tool)

			if not _tool then
				return
			end

			setmetatable(_tool, Actions)

			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { player.Character }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local caster = ClientCast.new(tool.Handle, rayParams)
			_tool.Caster = caster
			_tool.Metaplayer = Players:GetMetaplayer(player)
		end,
	},
	["Activate"] = {
		["meleeSwing"] = function(player, tool)
			local _tool = get(player, tool)

			if not _tool then
				return
			end

			_tool:Swing()
		end,
	},
	["Offhand"] = {},
	["Ability"] = {},
	["Unequip"] = {
		["meleeUneq"] = function(player, tool)
			local _tool = get(player, tool)
			_tool:Cleanup()
		end,
	},
}

return Lifetime
