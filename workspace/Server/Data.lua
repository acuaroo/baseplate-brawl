-- [[ Data.lua ]] --

--[[
    @ Public @
        Data:ProfilePlayer(player)
        Data:ReleasePlayer(player)
        Data:GetProfile(player)
        Data:IncrementSouls(player, increment)

    @ Private @
        Data:_leaderstats(profile, player)
]]
--

local ServerStorage = game:GetService("ServerStorage")
local PlayerService = game:GetService("Players")
local ProfileService = require(ServerStorage.Modules["ProfileService"])

local tools = ServerStorage.Tools

local Data = {}
local Profiles = {}

local currentHash = "G8%3&2"

local toolIndex = {
	["Sword"] = { name = "Sword" },
}

local defaultDataTemplate = {
	souls = 0,
	hotbar = {
		[1] = toolIndex["Sword"],
		[2] = nil,
		[3] = nil,
	},
	inventory = { toolIndex["Sword"] },
}

local ProfileStore = ProfileService.GetProfileStore(currentHash, defaultDataTemplate)

function Data:_leaderstats(profile, player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local souls = Instance.new("NumberValue")
	souls.Name = "souls"
	souls.Parent = leaderstats
	souls.Value = profile.Data.souls

	return leaderstats
end

function Data:_loadhotbar(profile, player)
	local backpack = player.Backpack
	local starterGear = player.StarterGear

	for _, tool in profile.Data.hotbar do
		local toolAsset = tools:FindFirstChild(tool["name"])

		if toolAsset then
			toolAsset = toolAsset:Clone()
			toolAsset.Parent = backpack

			toolAsset = toolAsset:Clone()
			toolAsset.Parent = starterGear
		end
	end
end

function Data:ProfilePlayer(player)
	local profile = ProfileStore:LoadProfileAsync("player_" .. player.UserId, "ForceLoad")

	if profile == nil then
		warn("[DATA]: " .. player .. "'s data failed to load | CIH: " .. currentHash)
		return player:Kick(
			"we're currently having issues loading data, contact us if this persists | CIH: " .. currentHash
		)
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile:ListenToRelease(function()
		Profiles[player] = nil
		player:Kick("safe release | [if you were leaving the game, this is normal]")
	end)

	if player:IsDescendantOf(PlayerService) then
		Profiles[player] = profile
		self:_leaderstats(profile, player)
		self:_loadhotbar(profile, player)
		return profile
	else
		profile:Release()
		warn("[DATA]: Dumped profile for " .. player.Name .. " | CIH: " .. currentHash)
		return nil
	end
end

function Data:GetProfile(player)
	return Profiles[player]
end

function Data:ReleasePlayer(player)
	local profile = Profiles[player]

	if profile then
		profile:Release()
	end
end

function Data:IncrementSouls(player, increment)
	local profile = self:GetProfile(player)

	profile.Data.souls += increment

	if player:FindFirstChild("leaderstats") then
		player.leaderstats.souls.Value += increment
	end
end

function Data:CheckHotbar(player, toolName)
	local profile = self:GetProfile(player)

	if profile then
		for _, tool in profile.Data.hotbar do
			if tool.name == toolName then
				return true
			end
		end
	end

	return false
end

return Data
