local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local sprintTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local playerHooks = {}
local WalkSpeedHandler = {}

function WalkSpeedHandler:HookPlayers()
	Players.PlayerAdded:Connect(function(player)
		playerHooks[player] = 16
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerHooks[player] = nil
	end)
end

function WalkSpeedHandler:TweenToSet(player, newSpeed)
	if not playerHooks[player] then
		return
	end

	playerHooks[player] = newSpeed

	local humanoid = player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = newSpeed }):Play()
end

function WalkSpeedHandler:SetSpeed(player, newSpeed)
	if not playerHooks[player] then
		return
	end

	playerHooks[player] = newSpeed

	if not player.Character then
		return
	end

	local humanoid = player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	humanoid.WalkSpeed = playerHooks[player]
end

function WalkSpeedHandler:TweenToAdjust(player, adjust)
	if not playerHooks[player] then
		return
	end

	playerHooks[player] += adjust

	if not player.Character then
		return
	end

	local humanoid = player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = playerHooks[player] }):Play()
end

function WalkSpeedHandler:AdjustSpeed(player, adjust)
	if not playerHooks[player] then
		return
	end

	playerHooks[player] += adjust

	if not player.Character then
		return
	end

	local humanoid = player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	humanoid.WalkSpeed = playerHooks[player]
end

function WalkSpeedHandler:ResetSpeed(player)
	if not playerHooks[player] then
		return
	end

	playerHooks[player] = 16

	if not player.Character then
		return
	end

	local humanoid = player.Character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	humanoid.WalkSpeed = playerHooks[player]
end

return WalkSpeedHandler
