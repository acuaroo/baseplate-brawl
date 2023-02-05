local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Spool = require(script.Parent.Modules.Spool)
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid.Animator
local mouse = player:GetMouse()

local playerGui = player.PlayerGui
local hotbarGui = playerGui.Hotbar
local statsFrame = hotbarGui.StatsFrame

local computerFolder = statsFrame.Computer
local mobileFolder = statsFrame.Mobile

local toolPrep = ReplicatedStorage["Events"].ToolPrep
local toolActivated = ReplicatedStorage["Events"].ToolActivated
local toolOffhand = ReplicatedStorage["Events"].ToolOffhand
local toolAbility = ReplicatedStorage["Events"].ToolAbility
local animRelay = ReplicatedStorage["Events"].AnimRelay
local animations = ReplicatedStorage["Animations"]

local activatedCon
local spearCon

local ToolClient = {}

local function cleanupConnections()
	if activatedCon then
		activatedCon:Disconnect()
		activatedCon = nil
	end

	ContextActionService:UnbindAction("OffhandInput")
end

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

		local spearPartA = ReplicatedStorage["Assets"]["Combat"].SpearPartA:Clone()
		local spearPartB = ReplicatedStorage["Assets"]["Combat"].SpearPartB:Clone()

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

			spearPartB.Position = (spearPartA.Position + spearPartA.CFrame.LookVector * -167) + Vector3.new(0, 10, 0)
		end)
	end,
}

local function setMobileUI() end

local function setComputerUI()
	for _, ui in mobileFolder:GetChildren() do
		ui.Visible = false
	end

	computerFolder.Roll.Visible = true
end

local function setOffhandUI(set)
	local playerDevice = Spool:GetPlayerDevice()

	if playerDevice == "Mobile" then
		print("mobile offhand")
	else
		computerFolder.Offhand.Visible = set
	end
end

local function setAbilityUI(set)
	local playerDevice = Spool:GetPlayerDevice()

	if playerDevice == "Mobile" then
		print("mobile ability")
	else
		computerFolder.Ability.Visible = set
	end
end

local function startActivate(name)
	local playerDevice = Spool:GetPlayerDevice()
	local ui = nil

	if playerDevice == "Mobile" then
		ui = mobileFolder:FindFirstChild(name)
	elseif playerDevice == "Computer" then
		ui = computerFolder:FindFirstChild(name)
	end

	if not ui then
		return
	end

	ui.BackgroundColor3 = Color3.fromRGB(255, 213, 85)
	ui.BackgroundTransparency = 0.7
end

local function stopActivate(name)
	local playerDevice = Spool:GetPlayerDevice()
	local ui = nil

	if playerDevice == "Mobile" then
		ui = mobileFolder:FindFirstChild(name)
	elseif playerDevice == "Computer" then
		ui = computerFolder:FindFirstChild(name)
	end

	if not ui then
		return
	end

	ui.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ui.BackgroundTransparency = 0.8
end

local function startDebounce(name, cooldown)
	local playerDevice = Spool:GetPlayerDevice()
	local ui = nil

	if playerDevice == "Mobile" then
		ui = mobileFolder:FindFirstChild(name)
	elseif playerDevice == "Computer" then
		ui = computerFolder:FindFirstChild(name)
	end

	if not ui then
		return
	end

	task.spawn(function()
		local cooldownUi = ui.Cooldown
		cooldownUi.Size = UDim2.new(1, 0, 0, 0)
		cooldownUi.Visible = true

		local cooldownTweenInfo = TweenInfo.new(cooldown, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local cooldownUiTween = TweenService:Create(cooldownUi, cooldownTweenInfo, { Size = UDim2.new(1, 0, 1.006, 0) })
		cooldownUiTween:Play()

		cooldownUiTween.Completed:Wait()

		cooldownUi.Size = UDim2.new(1, 0, 0, 0)
		cooldownUi.Visible = false
	end)
end

local function toolf(tool, config)
	if config:GetAttribute("OffDebounceTime") then
		setOffhandUI(true)
	end

	if config:GetAttribute("Ability") == true then
		setAbilityUI(true)
	end

	local function handleOffhandInput(_, actionState)
		if not config:GetAttribute("OffDebounceTime") then
			return
		end

		if actionState == Enum.UserInputState.Begin then
			local valid = toolOffhand:InvokeServer(tool, config, true)

			if valid then
				local subCall = config:GetAttribute("SubClass")
				startActivate("Offhand")

				if subCall and init[subCall] then
					init[subCall](character, tool)
				end
			end
		elseif actionState == Enum.UserInputState.End then
			local subCall = config:GetAttribute("SubClass")

			if subCall and functionality[subCall] then
				functionality[subCall](character, tool)
			end

			stopActivate("Offhand")
			startDebounce("Offhand", config:GetAttribute("OffDebounceTime"))
			toolOffhand:InvokeServer(tool, config, false)
		end
	end

	local function handleAbilityInput(_, actionState)
		if actionState == Enum.UserInputState.Begin then
			if config:GetAttribute("Ability") == true then
				local valid = toolAbility:InvokeServer(tool, config, false)

				if valid then
					startActivate("Ability")
					startDebounce("Ability", config:GetAttribute("AbilityDebounce") - 0.75)

					task.delay(0.3, function()
						stopActivate("Ability")
					end)
				end
			end
		end
	end

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

	ContextActionService:BindAction("OffhandInput", handleOffhandInput, false, Enum.KeyCode.F)
	--ContextActionService:SetImage("OffhandInput", "http://www.roblox.com/asset/?id=11554338960")

	ContextActionService:BindAction("AbilityInput", handleAbilityInput, false, Enum.KeyCode.Q)
	--ContextActionService:SetImage("AbilityInput", "http://www.roblox.com/asset/?id=11884485716")

	tool.Unequipped:Connect(function()
		animRelay:FireServer(tool)
		local subClass = config:GetAttribute("SubClass")

		if subClass and functionality[subClass] then
			functionality[subClass](character, tool)
		end

		setOffhandUI(false)
		setAbilityUI(false)

		cleanupConnections()
	end)
end

function ToolClient:Run()
	local playerDevice = Spool:GetPlayerDevice()

	if playerDevice == "Mobile" then
		setMobileUI()
	elseif playerDevice == "Computer" then
		setComputerUI()
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
