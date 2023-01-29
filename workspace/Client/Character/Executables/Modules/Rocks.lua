local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Rocks = {}

function Rocks:RockRing(centerCFrame, partSize, amountOfRocks, diameter, rockAsset, rotationDegrees, lifeTime)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { workspace.Debris }
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	local angle = 0

	for _ = 1, amountOfRocks do
		local part = rockAsset:Clone()

		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(
			math.random(partSize - 0.5, partSize + 0.5),
			math.random(partSize - 0.5, partSize + 0.5),
			math.random(partSize - 0.5, partSize + 0.5)
		)

		part.CFrame = centerCFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(angle), 0) * CFrame.new(5, 0, 0)
		part.Orientation = Vector3.new(0, 0, 0)

		Debris:AddItem(part, lifeTime)

		local RayCast = workspace:Raycast(part.CFrame.p, part.CFrame.UpVector * -diameter, rayParams)

		if RayCast then
			part.Orientation = Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
			part.Parent = workspace.Debris

			TweenService:Create(
				part,
				TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut),
				{ Position = part.Position + Vector3.new(0, 1, 0) }
			):Play()

			task.delay(lifeTime - 1, function()
				TweenService
					:Create(
						part,
						TweenInfo.new(1),
						{ Transparency = 1, Position = part.Position + Vector3.new(0, -5, 0) }
					)
					:Play()
			end)
		end

		angle += rotationDegrees
	end
end

return Rocks
