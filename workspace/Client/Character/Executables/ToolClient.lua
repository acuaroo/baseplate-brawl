local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid.Animator
local mouse = player:GetMouse()

local toolPrep = ReplicatedStorage["Events"].ToolPrep
local toolActivated = ReplicatedStorage["Events"].ToolActivated
local toolOffhand = ReplicatedStorage["Events"].ToolOffhand
local animRelay = ReplicatedStorage["Events"].AnimRelay
local animations = ReplicatedStorage["Animations"]

local activatedCon
local offhandCon
local offhandDiscon
local spearCon

local ToolClient = {}

local function cleanupConnections()
	if activatedCon then
		activatedCon:Disconnect()
		activatedCon = nil
	end

	if offhandCon then
		offhandCon:Disconnect()
		offhandCon = nil
	end

	if offhandDiscon then
		offhandDiscon:Disconnect()
		offhandDiscon = nil
	end
end

function ToolClient:Run()
	local functionality = {
		["throwSpear"] = function(char, _)
			if spearCon then
				spearCon:Disconnect()
				spearCon = nil
			end

			if workspace:FindFirstChild(char.Name .. "SpearVisual") then
				workspace[char.Name .. "SpearVisual"]:Destroy()
			end
		end,
	}

	local init = {
		["throwSpear"] = function(char, tool)
			functionality["throwSpear"](char)

			local spearPartA = ReplicatedStorage["Assets"].SpearPartA:Clone()
			local spearPartB = ReplicatedStorage["Assets"].SpearPartB:Clone()

			local cache = Instance.new("Folder")
			cache.Name = char.Name .. "SpearVisual"
			cache.Parent = workspace

			local beam = spearPartA.Attachment.Beam

			spearPartA.Parent = cache
			spearPartB.Parent = cache

			beam.Attachment0 = spearPartA.Attachment
			beam.Attachment1 = spearPartB.Attachment

			spearCon = RunService.RenderStepped:Connect(function()
				spearPartA.Position = tool.Handle.ThrowPoint.WorldCFrame.Position - Vector3.new(0, 3, 0)
				spearPartA.CFrame = (CFrame.new(spearPartA.Position) * char:GetPivot().Rotation)
					* CFrame.Angles(0, math.rad(180), math.rad(90))

				spearPartB.Position = (spearPartA.Position + spearPartA.CFrame.LookVector * -167)
					+ Vector3.new(0, 10, 0)
			end)
		end,
	}

	local function toolf(tool, config)
		activatedCon = tool.Activated:Connect(function()
			local valid = nil
			if config:GetAttribute("Ability") then
				local args = {
					mouse.Hit.Position,
				}

				valid = toolActivated:InvokeServer(tool, config, args)
			else
				valid = toolActivated:InvokeServer(tool, config)
			end

			if valid then
				if not config:GetAttribute("AnimationOn") then
					return
				end
				local swingDirection = config:GetAttribute("SwingDirection")
				local animationPause = config:GetAttribute("AnimationPause")
				local animationHeader = config:GetAttribute("AnimationHeader")
				local animationTail = config:GetAttribute("AnimationTail")
				local animation = animations:FindFirstChild(animationHeader .. swingDirection .. animationTail)

				if not animation then
					return
				end

				if animationPause then
					task.wait(animationPause)
				end

				animation = animator:LoadAnimation(animation)
				animation:Play()
			end
		end)

		offhandCon = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				local valid = toolOffhand:InvokeServer(tool, config, true)

				if valid then
					local subCall = config:GetAttribute("SubClass")

					if subCall and init[subCall] then
						init[subCall](character, tool)
					end
				end
			end
		end)

		offhandDiscon = UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				local subCall = config:GetAttribute("SubClass")

				if subCall and functionality[subCall] then
					functionality[subCall](character, tool)
				end

				toolOffhand:InvokeServer(tool, config, false)
			end
		end)

		tool.Unequipped:Connect(function()
			animRelay:FireServer(tool)
			local subClass = config:GetAttribute("SubClass")

			if subClass and functionality[subClass] then
				functionality[subClass](character, tool)
			end

			cleanupConnections()
		end)
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:FindFirstChild("Config") then
			local config = child.Config
			local tool = child

			toolPrep:FireServer(tool, config)

			toolf(tool, config)
		end
	end)
end

return ToolClient
