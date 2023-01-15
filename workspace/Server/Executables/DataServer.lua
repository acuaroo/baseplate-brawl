--[[

	DataServer:GetProfile(player)
	-- returns the profile of the player

	DataServer:IncrementSouls(player, amt (+/-))
	-- increments the souls of the player

	DataServer:AddTool(player, tool { name = String, equipped = Boolean })
	-- adds a tool to the player's inventory

	DataServer:RemoveTool(player, toolName)
	-- removes a tool from the player's inventory

	DataServer:EquipSetTool(player, tool, equipped)
	-- set the equipped status of a tool

]]

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ProfileService = require(ServerStorage["Modules"].ProfileService)

local toolFolder = ServerStorage["Assets"].Tools

local currentHash = "G@D7SZ"
local defaultTemplate = {
	souls = 0,
	tools = {
		["Sword"] = { name = "Sword", equipped = true },
		["Meteor Staff"] = { name = "Meteor Staff", equipped = true },
		["Cursed Spear"] = { name = "Cursed Spear", equipped = true },
	},
	playerSettings = {
		["Music"] = true,
		["SoundEffects"] = true,
	},
}

local ProfileStore = ProfileService.GetProfileStore("dev_" .. currentHash, defaultTemplate)

local Profiles = {}
local DataServer = {}

local function kick(player)
	player:Kick(
		"sorry, we're having some data issues. if the issue persists, contact us.\n UXH = "
			.. currentHash
			.. "|"
			.. player.UserId
	)
end

local function addTool(player, tool)
	local folderTool = toolFolder:FindFirstChild(tool.name)

	if folderTool then
		folderTool:Clone().Parent = player.Backpack
		folderTool:Clone().Parent = player.StarterGear
	end
end

local function removeTool(player, tool)
	if player.Backpack:FindFirstChild(tool) then
		player.Backpack[tool]:Destroy()
	end

	if player.Character:FindFirstChild(tool) then
		player.Character[tool]:Destroy()
	end

	if player.StarterGear:FindFirstChild(tool) then
		player.StarterGear[tool]:Destroy()
	end
end

local function addLeaderstats(player)
	local profile = Profiles[player]

	if not profile then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local souls = Instance.new("IntValue")
	souls.Name = "souls"
	souls.Parent = leaderstats
	souls.Value = profile.Data.souls

	for _, tool in profile.Data.tools do
		if tool.equipped then
			addTool(player, tool)
		end
	end
end

local function playerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("player_" .. player.UserId, "ForceLoad")
	if profile == nil then
		kick(player)
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile:ListenToRelease(function()
		Profiles[player] = nil
		kick(player)
	end)

	if player:IsDescendantOf(Players) then
		Profiles[player] = profile
		addLeaderstats(player)
	else
		profile:Release()
	end
end

function DataServer:Run()
	Players.PlayerAdded:Connect(playerAdded)

	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]

		if profile then
			profile:Release()
		end
	end)
end

function DataServer:GetProfile(player)
	if Profiles[player] then
		return Profiles[player].Data
	end
end

function DataServer:IncrementSouls(player, amount)
	if Profiles[player] then
		Profiles[player].Data.souls += amount
		player.leaderstats.souls.Value = Profiles[player].Data.souls
	end
end

function DataServer:AddTool(player, newTool)
	if Profiles[player] then
		Profiles[player].Data.tools[newTool.name] = newTool

		if newTool.equipped then
			addTool(player, newTool)
		end
	end
end

function DataServer:RemoveTool(player, tool)
	if Profiles[player] then
		local profileTool = Profiles[player].Data.tools[tool]
		if not profileTool then
			warn("[DATA]: " .. player.Name .. " tried to remove a nil tool :", tool)
			return
		end

		profileTool = nil

		removeTool(player, tool)
	end
end

function DataServer:EquipSetTool(player, tool, equipped)
	if Profiles[player] then
		local profileTool = Profiles[player].Data.tools[tool]

		if not profileTool then
			warn("[DATA]: " .. player.Name .. " tried to remove a nil tool :", tool)
			return
		end

		profileTool.equipped = equipped

		if profileTool.equipped then
			addTool(player, profileTool)
		end
	end
end

return DataServer
