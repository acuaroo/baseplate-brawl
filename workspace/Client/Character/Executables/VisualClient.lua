local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ScreenShake = require(script.Parent["Modules"].ScreenShake)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local requestVisual = ReplicatedStorage["Events"].RequestVisual
local particleHolder = ReplicatedStorage["Assets"].ParticleHolder
local sprintParticle = particleHolder.SprintParticle

local visualFunctions = {
	["SprintEffect"] = function(_)
		if not character:FindFirstChild("Humanoid") then
			return
		end

		local humanoidRP = character:FindFirstChild("HumanoidRootPart")

		local sprintLeft = sprintParticle:Clone()
		local sprintRight = sprintParticle:Clone()

		sprintLeft.Name = "SprintLeft"
		sprintRight.Name = "SprintRight"

		sprintLeft.Parent = humanoidRP
		sprintRight.Parent = humanoidRP
		sprintRight.Position = Vector3.new(1.5, -1, 0.5)
	end,
	["ScreenShake"] = function(args)
		local camera = workspace.CurrentCamera

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
}

local visualCleanup = {
	["SprintEffect"] = function(_)
		if not character:FindFirstChild("Humanoid") then
			return
		end

		local humanoidRP = character:FindFirstChild("HumanoidRootPart")

		if humanoidRP:FindFirstChild("SprintLeft") then
			humanoidRP.SprintLeft:Destroy()
		end

		if humanoidRP:FindFirstChild("SprintRight") then
			humanoidRP.SprintRight:Destroy()
		end
	end,
}

local VisualClient = {}

function VisualClient:Run()
	requestVisual.OnClientEvent:Connect(function(name, args)
		local toggle = args["Toggle"]

		if toggle ~= nil and toggle == "CLEAN" then
			if visualCleanup[name] then
				visualCleanup[name](args)
			end

			return
		end

		if visualFunctions[name] then
			visualFunctions[name](args)
		end
	end)
end

return VisualClient
