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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ProfileService = require(ServerStorage["Modules"].ProfileService)

-- local shopList = ReplicatedStorage["Events"].ShopList
-- local purchase = ReplicatedStorage["Events"].Purchase
local toolFolder = ServerStorage["Assets"].Tools
local dataRequest = ReplicatedStorage["Events"].DataRequest

local currentHash = "G@D7&S"

local toolIndex = {
	["Starter Sword"] = {
		name = "Starter Sword",
		equipped = 0,
		description = toolFolder["Starter Sword"]:GetAttribute("Description"),
	},
	["Meteor Staff"] = {
		name = "Meteor Staff",
		equipped = 0,
		description = toolFolder["Meteor Staff"]:GetAttribute("Description"),
	},
	["Cursed Spear"] = {
		name = "Cursed Spear",
		equipped = 0,
		description = toolFolder["Cursed Spear"]:GetAttribute("Description"),
	},
	["Sword"] = { name = "Sword", equipped = 0, description = toolFolder["Sword"]:GetAttribute("Description") },
}

local defaultTemplate = {
	souls = 0,
	tools = {
		["Starter Sword"] = { name = "Starter Sword", equipped = 1 },
	},
	playerSettings = {
		["Music"] = true,
		["SoundEffects"] = true,
	},
}

local activeShopList = {
	["Sword"] = { name = "Sword", description = toolFolder["Sword"]:GetAttribute("Description"), price = 0 },
}

local ProfileStore = ProfileService.GetProfileStore("dev_" .. currentHash, defaultTemplate)

local Profiles = {}
local DataServer = {}

local function kick(player)
	player:Kick(
		"sorry, we're having some data issues! if the issue persists, contact us.\n UXH = "
			.. currentHash
			.. "|"
			.. player.UserId
	)
end

local requests = {
	["ShopList"] = function(_, _)
		return activeShopList
	end,
	["Inventory"] = function(player, _)
		local res = table.clone(DataServer:GetProfile(player).tools)

		for _, tool in res do
			tool.description = toolIndex[tool.name].description
		end

		return res
	end,
	["Buy"] = function(player, itemName)
		local validItem = activeShopList[itemName]

		if validItem then
			local profile = DataServer:GetProfile(player)

			if not profile then
				return kick(player)
			end

			if profile.souls >= validItem.price then
				if not profile.tools[itemName] then
					local toolConstructor = {
						name = validItem.name,
						equipped = 0,
					}

					DataServer:AddTool(player, toolConstructor)
					DataServer:IncrementSouls(player, -validItem.price)

					return "bought!"
				else
					return "you already own this, go to your bag to equip this!"
				end
			else
				return "not enough souls!"
			end
		else
			return "you shouldn't have known about that..."
		end
	end,
}

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

	local order = {}

	for _, tool in profile.Data.tools do
		if tool.equipped ~= 0 then
			order[tool.equipped] = tool
			--addTool(player, tool)
		end
	end

	for _, tool in ipairs(order) do
		addTool(player, tool)
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

	dataRequest.OnServerInvoke = function(player, request, args)
		local validRequest = requests[request]

		if validRequest then
			return validRequest(player, args)
		end
	end

	-- shopList.OnServerInvoke = function(_)
	-- 	return activeShopList
	-- end

	-- purchase.OnServerInvoke = function(player, itemInfo)
	-- 	local shopItem = activeShopList[itemInfo.name]

	-- 	if shopItem then
	-- 		local profile = DataServer:GetProfile(player)

	-- 		if not profile then
	-- 			warn("[DATA]: " .. player.Name .. " attempted to buy a tool without a valid data profile")
	-- 			return "datastore error, please rejoin if you see this!"
	-- 		end

	-- 		if profile.tools[shopItem.name] then
	-- 			return "you already own this..."
	-- 		end

	-- 		if profile.souls < shopItem.price then
	-- 			return "too poor :("
	-- 		end

	-- 		DataServer:IncrementSouls(player, -shopItem.price)
	-- 		DataServer:AddTool(player, toolIndex[shopItem.name])

	-- 		return "bought! go to your bag to equip"
	-- 	else
	-- 		return "datastore error, you requested something you shouldn't have known about..."
	-- 	end
	-- end
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

		if newTool.equipped ~= 0 then
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
