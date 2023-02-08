local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = { workspace.Debris }
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

local rockTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut)
local rockTweenOutInfo = TweenInfo.new(1)

local UP_VECTOR = Vector3.yAxis
local RESET_VECTOR = Vector3.zero
local DOWN_VECTOR = UP_VECTOR * -5
local CFRAME_OFFSET = CFrame.new(5, 0, 0)
local SIZE_DIFF = 0.5

local Rocks = {}

local function positionPart(part, lifeTime)
	part.Orientation = Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
	part.Parent = workspace.Debris

	TweenService:Create(part, rockTweenInfo, { Position = part.Position + UP_VECTOR }):Play()

	task.delay(lifeTime - 1, function()
		TweenService:Create(part, rockTweenOutInfo, { Transparency = 1, Position = part.Position + DOWN_VECTOR }):Play()
	end)
end

function Rocks:RockRing(centerCFrame, partSize, amountOfRocks, diameter, rockAsset, rotationDegrees, lifeTime)
	local angle = 0

	for _ = 1, amountOfRocks do
		local part = rockAsset:Clone()

		part.Anchored = true
		part.CanCollide = false

		part.Size = Vector3.new(
			math.random(partSize - SIZE_DIFF, partSize + SIZE_DIFF),
			math.random(partSize - SIZE_DIFF, partSize + SIZE_DIFF),
			math.random(partSize - SIZE_DIFF, partSize + SIZE_DIFF)
		)

		part.CFrame = centerCFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(angle), 0) * CFRAME_OFFSET
		part.Orientation = RESET_VECTOR

		Debris:AddItem(part, lifeTime)

		local circleRay = workspace:Raycast(part.CFrame.Position, part.CFrame.UpVector * -diameter, rayParams)

		if circleRay then
			positionPart(part, lifeTime)
		end

		angle += rotationDegrees
	end
end

return Rocks
