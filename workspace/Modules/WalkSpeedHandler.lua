local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local sprintTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local playerHooks = {}
local playerSpeedCache = {}
local WalkSpeedHandler = {}

local function checkValid(player)
	if not playerHooks[player] then
		return false
	end

	local humanoid = player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return false
	end

	return humanoid
end

function WalkSpeedHandler:HookPlayers()
	Players.PlayerAdded:Connect(function(player)
		playerHooks[player] = 16
		playerSpeedCache[player] = 16
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerHooks[player] = nil
		playerSpeedCache[player] = nil
	end)
end

function WalkSpeedHandler:TweenToSet(player, newSpeed)
	local humanoid = checkValid(player)
	if not humanoid then
		return
	end

	playerSpeedCache[player] = playerHooks[player]
	playerHooks[player] = newSpeed

	TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = newSpeed }):Play()
end

function WalkSpeedHandler:SetSpeed(player, newSpeed)
	local humanoid = checkValid(player)
	if not humanoid then
		return
	end

	playerSpeedCache[player] = playerHooks[player]
	playerHooks[player] = newSpeed

	humanoid.WalkSpeed = playerHooks[player]
end

function WalkSpeedHandler:TweenToAdjust(player, adjust)
	local humanoid = checkValid(player)
	if not humanoid then
		return
	end

	playerHooks[player] += adjust

	TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = playerHooks[player] }):Play()
end

function WalkSpeedHandler:AdjustSpeed(player, adjust)
	local humanoid = checkValid(player)
	if not humanoid then
		return
	end

	playerSpeedCache[player] = playerHooks[player]
	playerHooks[player] += adjust

	humanoid.WalkSpeed = playerHooks[player]
end

function WalkSpeedHandler:PrefixSpeed(player, adjust, prefix)
	local humanoid = checkValid(player)
	if not humanoid then
		return
	end

	playerHooks[player] = (prefix + adjust)

	humanoid.WalkSpeed = playerHooks[player]
end

function WalkSpeedHandler:ClampSpeed(player, adjust, clampMin, clampMax)
	print("clampseed")

	local humanoid = checkValid(player)
	if not humanoid then
		return
	end

	playerSpeedCache[player] = playerHooks[player]
	playerHooks[player] += adjust
	playerHooks[player] = math.clamp(playerHooks[player], clampMin, clampMax)

	humanoid.WalkSpeed = playerHooks[player]
end

function WalkSpeedHandler:ResetSpeed(player)
	local humanoid = checkValid(player)
	if not humanoid then
		return
	end

	playerSpeedCache[player] = playerHooks[player]
	playerHooks[player] = 16

	humanoid.WalkSpeed = playerHooks[player]
end

function WalkSpeedHandler:GetCachedSpeed(player)
	return playerSpeedCache[player]
end

return WalkSpeedHandler
