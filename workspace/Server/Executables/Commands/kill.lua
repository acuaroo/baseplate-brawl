local kill = {}

local function killRun(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	humanoid.Health = 0
end

function kill:Run(args, _)
	if args[2] == "all" then
		for _, player in pairs(game.Players:GetPlayers()) do
			killRun(player)
		end
		return
	end

	local player = game.Players:FindFirstChild(args[2])

	if not player then
		return
	end

	killRun(player)
end

return kill
