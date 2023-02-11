local teleport = {}

function teleport:Run(args, _)
	local player = game.Players:FindFirstChild(args[2])
	local target = game.Players:FindFirstChild(args[3])

	if not player or not target then
		return
	end

	local character = player.Character
	local targetCharacter = target.Character

	if not character or not targetCharacter then
		return
	end

	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

	if not humanoidRoot or not targetRoot then
		return
	end

	humanoidRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 5, 0)
end

return teleport
