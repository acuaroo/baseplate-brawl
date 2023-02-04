local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Tool = require(script.Tool)
local MetaPlayers = require(script.Parent.PlayerServer)

local ClassList = {
	["Melee"] = require(script.Melee),
	["Func"] = require(script.Func),
	["Custom"] = require(script.Custom),
}

local toolPrep = ReplicatedStorage["Events"].ToolPrep
local animRelay = ReplicatedStorage["Events"].AnimRelay
local toolActivated = ReplicatedStorage["Events"].ToolActivated
local toolOffhand = ReplicatedStorage["Events"].ToolOffhand
local toolAbility = ReplicatedStorage["Events"].ToolAbility
local toolEquip = ReplicatedStorage["Events"].ToolEquip
local notificationChannel = ReplicatedStorage["Events"].Notification

local toolPrepTable = {}
local ToolServer = {}

local function toolParse(metaplayer, blacklist)
	if blacklist[metaplayer.PrimaryState] then
		return true
	else
		return false
	end
end

function ToolServer:Run()
	local function toolCheck(player, toolobj)
		if not toolPrepTable[player][toolobj.Name] then
			return false
		end
		return toolPrepTable[player][toolobj.Name]
	end

	toolPrep.OnServerEvent:Connect(function(player, toolobj, config)
		if toolPrepTable[player][toolobj.Name] then
			local tool = toolPrepTable[player][toolobj.Name]
			tool:Cleanup()
			return
		end

		local class = config:GetAttribute("Class")
		local route = ClassList[class]

		if not class or not ClassList[class] then
			route = Tool
		end

		local tool = route.new(player, toolobj, config, MetaPlayers[player])
		toolPrepTable[player][toolobj.Name] = tool
	end)

	animRelay.OnServerEvent:Connect(function(player, toolobj)
		local tool = toolCheck(player, toolobj)
		if not tool then
			return false
		end

		MetaPlayers[player]:SetPrimary("NONE")
		tool:Cleanup()
	end)

	toolAbility.OnServerInvoke = function(player, toolobj, _, playerData)
		local tool = toolCheck(player, toolobj)

		if not tool then
			return false
		end

		if tool.AbilityDebouncing then
			return false
		end

		if toolParse(MetaPlayers[player], { "STUNLOCK", "STUN", "GRAB", "FUNCTIONAL", "NOMOVE" }) then
			return false
		end

		if not tool._config:GetAttribute("Ability") then
			return false
		end

		tool:Ability(playerData)

		return true
	end

	toolActivated.OnServerInvoke = function(player, toolobj, _, args)
		local tool = toolCheck(player, toolobj)

		if not tool then
			return false
		end
		if tool.Debouncing or tool.AbilityActive then
			return false
		end
		if toolParse(MetaPlayers[player], { "STUNLOCK", "STUN", "GRAB", "FUNCTIONAL", "NOMOVE" }) then
			return false
		end

		tool:Activate(args)

		return true
	end

	toolOffhand.OnServerInvoke = function(player, toolobj, _, enable)
		local tool = toolCheck(player, toolobj)

		if not tool then
			return false
		end
		if tool.OffDebouncing or tool.AbilityActive then
			return false
		end
		if toolParse(MetaPlayers[player], { "STUN", "RUNNING", "FUNCTIONAL", "GRAB", "NOMOVE" }) then
			return false
		end

		tool:Offhand(enable)

		return true
	end

	toolEquip.OnServerInvoke = function(player, toolobj, equip)
		if not player.Character:FindFirstChild("Humanoid") then
			return
		end

		if player.Character.Humanoid.Health <= 0 then
			return
		end

		if equip and toolobj then
			if toolobj.Parent ~= player.Backpack then
				return -- TODO: punish :)
			end

			if toolParse(MetaPlayers[player], { "STUNLOCK", "STUN", "GRAB", "FUNCTIONAL", "ATTACKING", "NOMOVE" }) then
				return false
			end

			local humanoid = player.Character:FindFirstChild("Humanoid")

			if not humanoid then
				return
			end

			humanoid:EquipTool(toolobj)

			notificationChannel:FireClient(player, {
				toolobj:GetAttribute("Title"),
				toolobj:GetAttribute("Description"),
				toolobj:GetAttribute("Image"),
				true,
			}, false)

			return true
		else
			if toolParse(MetaPlayers[player], { "STUNLOCK", "STUN", "GRAB", "FUNCTIONAL", "ATTACKING", "NOMOVE" }) then
				return false
			end

			local humanoid = player.Character:FindFirstChild("Humanoid")

			if not humanoid then
				return
			end

			humanoid:UnequipTools()

			notificationChannel:FireClient(player, {
				toolobj:GetAttribute("Title"),
				toolobj:GetAttribute("Description"),
				toolobj:GetAttribute("Image"),
				false,
			}, false)

			return true
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			toolPrepTable[player] = {}
		end)
	end)
end

return ToolServer
