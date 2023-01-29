local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ScreenShake = require(script.Parent["Modules"].ScreenShake)
local Rocks = require(script.Parent["Modules"].Rocks)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera

local requestVisual = ReplicatedStorage["Events"].RequestVisual
local particleHolder = ReplicatedStorage["Assets"]["Particles"].ParticleHolder
local shockwave = ReplicatedStorage["Assets"]["Combat"].Shockwave
local rock = ReplicatedStorage["Assets"]["Combat"].Rock

local backSprint = particleHolder.BackSprint
local frontSprint = particleHolder.FrontSprint

local sprintTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false)
local shockTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false)

local sprintFovIn = TweenService:Create(camera, sprintTweenInfo, { FieldOfView = 80 })
local sprintFovOut = TweenService:Create(camera, sprintTweenInfo, { FieldOfView = 70 })

local visualFunctions = {
	["SprintEffect"] = function(_, _)
		local humanoid = character:FindFirstChild("Humanoid")

		if not humanoid then
			return
		end

		local leftArm = character:FindFirstChild("Left Arm")
		local rightArm = character:FindFirstChild("Right Arm")

		local sprintLB = backSprint:Clone()
		local sprintLF = frontSprint:Clone()

		sprintLB.Parent = leftArm
		sprintLF.Parent = leftArm

		sprintLB.Trail.Attachment0 = sprintLB
		sprintLB.Trail.Attachment1 = sprintLF

		local sprintRB = backSprint:Clone()
		local sprintRF = frontSprint:Clone()

		sprintRB.Parent = rightArm
		sprintRF.Parent = rightArm

		sprintRB.Trail.Attachment0 = sprintRB
		sprintRB.Trail.Attachment1 = sprintRF

		sprintFovIn:Play()
	end,
	["ScreenShake"] = function(args, _)
		local function ShakeCamera(shakeCf)
			camera.CFrame = camera.CFrame * shakeCf
		end

		local renderPriority = Enum.RenderPriority.Camera.Value + 1
		local screen = ScreenShake.new(renderPriority, ShakeCamera)

		screen:Start()

		screen:ShakeOnce(
			args["Magnitude"],
			args["Roughness"],
			args["FadeIn"],
			args["FadeOut"],
			args["PosInfluence"],
			args["RotInfluence"]
		)
	end,
	["CharacterTilt"] = function(_, _)
		local rotFrontBack = 0.1
		local rotLeftRight = 0.1
		local rotSpeed = 0.1
		local humanoidRP = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")

		if not humanoidRP or not humanoid then
			return
		end

		local originalC0 = humanoidRP.RootJoint.C0

		RunService.RenderStepped:Connect(function(_)
			if not humanoidRP or not humanoid or not humanoidRP:FindFirstChild("RootJoint") then
				return
			end

			local dotFrontBack = humanoidRP.CFrame.LookVector:Dot(humanoid.MoveDirection)
			local dotLeftRight = humanoidRP.CFrame.RightVector:Dot(humanoid.MoveDirection)

			humanoidRP.RootJoint.C0 = humanoidRP.RootJoint.C0:Lerp(
				originalC0 * CFrame.Angles(dotFrontBack * rotFrontBack, -dotLeftRight * rotLeftRight, 0),
				rotSpeed
			)
		end)
	end,
	["MeteorImpact"] = function(args, self)
		local humanoidRP = character:FindFirstChild("HumanoidRootPart")
		local screenShakeCalc = (humanoidRP.Position - args[2]).Magnitude
		print(screenShakeCalc)

		Rocks:RockRing(args[3] - Vector3.new(0, 11, 0), 3, 12, 30, rock, 30, 2.5)

		if screenShakeCalc <= 20 then
			self["ScreenShake"]({
				["Magnitude"] = 50 / screenShakeCalc,
				["Roughness"] = 100 / screenShakeCalc,
				["FadeIn"] = 0,
				["FadeOut"] = 1.5,
				["PosInfluence"] = Vector3.new(0.25, 0.25, 0.25),
				["RotInfluence"] = Vector3.new(4, 1, 1),
			})
		end

		local newShock = shockwave:Clone()
		newShock.Parent = workspace.Debris
		newShock.Position = args[1]

		local newShockTween = TweenService:Create(newShock, shockTweenInfo, { Size = Vector3.new(25, 3, 25) })
		newShockTween:Play()
		newShockTween.Completed:Wait()

		local newShockFade = TweenService:Create(newShock, shockTweenInfo, { Transparency = 1 })
		newShockFade:Play()
		newShockFade.Completed:Wait()

		newShock:Destroy()
	end,
}

local visualCleanup = {
	["SprintEffect"] = function(_)
		if not character:FindFirstChild("Humanoid") then
			return
		end

		local leftArm = character:FindFirstChild("Left Arm")
		local rightArm = character:FindFirstChild("Right Arm")

		if leftArm:FindFirstChild("BackSprint") then
			leftArm.BackSprint:Destroy()
			leftArm.FrontSprint:Destroy()
		end

		if rightArm:FindFirstChild("BackSprint") then
			rightArm.BackSprint:Destroy()
			rightArm.FrontSprint:Destroy()
		end

		sprintFovOut:Play()
	end,
}

local VisualClient = {}

function VisualClient:Run()
	visualFunctions["CharacterTilt"]()

	requestVisual.OnClientEvent:Connect(function(name, args)
		local toggle = args["Toggle"]

		if toggle ~= nil and toggle == "CLEAN" then
			if visualCleanup[name] then
				visualCleanup[name](args)
			end

			return
		end

		if visualFunctions[name] then
			visualFunctions[name](args, visualFunctions)
		end
	end)
end

return VisualClient
