local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Spool = require(script.Parent.Modules.Spool)

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
local rollDebounce = ReplicatedStorage["Events"].RollDebounce

local activatedCon
local spearCon

<<<<<<< HEAD
local SPEAR_OFFSET = Vector3.new(0, 3, 0)
local SPEAR_PART_OFFSET = Vector3.new(0, 10, 0)
local SPEAR_ANGLE = CFrame.Angles(0, math.rad(180), math.rad(90))
local SPEAR_DISTANCE = 167

local UI_BLACK = Color3.fromRGB(0, 0, 0)
local UI_YELLOW = Color3.fromRGB(255, 213, 85)
local UI_MIN = UDim2.new(1, 0, 0, 0)
local UI_MAX = UDim2.new(1, 0, 1.006, 0)

=======
local touchConnections = {}
local hooks = {}
>>>>>>> c671428e3835c3bd57a7eedb21563d0073318977
local ToolClient = {}

local function cleanupConnections()
	if activatedCon then
		activatedCon:Disconnect()
		activatedCon = nil
	end

	if spearCon then
		spearCon:Disconnect()
		spearCon = nil
	end

	ContextActionService:UnbindAction("OffhandInput")
	ContextActionService:UnbindAction("AbilityInput")
end

local functionality = {
	["throwSpear"] = function(char, _)
		if spearCon then
			spearCon:Disconnect()
			spearCon = nil
		end

		local spearVisual = workspace.Debris:FindFirstChild(char.Name .. "SpearVisual")

		if spearVisual then
			spearVisual:Destroy()
		end
	end,
}

local init = {
	["throwSpear"] = function(char, tool)
		functionality["throwSpear"](char)

		local spearPartA = ReplicatedStorage["Assets"]["Combat"].SpearPartA:Clone()
		local spearPartB = ReplicatedStorage["Assets"]["Combat"].SpearPartB:Clone()
		local beam = spearPartA.Attachment.Beam

		local cache = Instance.new("Folder")
		cache.Name = char.Name .. "SpearVisual"
		cache.Parent = workspace.Debris

		spearPartA.Parent = cache
		spearPartB.Parent = cache

		beam.Attachment0 = spearPartA.Attachment
		beam.Attachment1 = spearPartB.Attachment

		spearCon = RunService.RenderStepped:Connect(function()
			spearPartA.Position = tool.Handle.ThrowPoint.WorldCFrame.Position - SPEAR_OFFSET
			spearPartA.CFrame = (CFrame.new(spearPartA.Position) * char:GetPivot().Rotation) * SPEAR_ANGLE

			spearPartB.Position = (spearPartA.Position + spearPartA.CFrame.LookVector * -SPEAR_DISTANCE)
				+ SPEAR_PART_OFFSET
		end)
	end,
}

local function hookAction(button)
	touchConnections[button.Name .. "B"] = button.MouseButton1Down:Connect(function()
		print(button.Name)

		hooks[button.Name](nil, Enum.UserInputState.Begin)
	end)

	touchConnections[button.Name .. "E"] = button.MouseButton1Up:Connect(function()
		hooks[button.Name](nil, Enum.UserInputState.End)
	end)
end

local function setMobileUI()
	for _, ui in computerFolder:GetChildren() do
		ui.Visible = false
	end

	mobileFolder.Roll.Visible = true
	hookAction(mobileFolder.Roll)
end

local function setComputerUI()
	for _, ui in mobileFolder:GetChildren() do
		ui.Visible = false
	end

	computerFolder.Roll.Visible = true
	hookAction(computerFolder.Roll)
end

local function setOffhandUI(set)
	local playerDevice = Spool:GetPlayerDevice()

	if playerDevice == "Mobile" then
		mobileFolder.Offhand.Visible = set
	else
		computerFolder.Offhand.Visible = set
	end
end

local function setAbilityUI(set)
	local playerDevice = Spool:GetPlayerDevice()

	if playerDevice == "Mobile" then
		mobileFolder.Ability.Visible = set
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

	local uiColorTweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local uiColorTween = TweenService:Create(ui, uiColorTweenInfo, { BackgroundColor3 = UI_YELLOW })
	uiColorTween:Play()

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

	ui.BackgroundColor3 = UI_BLACK
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
		cooldownUi.Size = UI_MIN
		cooldownUi.Visible = true

		local cooldownTweenInfo = TweenInfo.new(tonumber(cooldown), Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local cooldownUiTween = TweenService:Create(cooldownUi, cooldownTweenInfo, { Size = UI_MAX })
		cooldownUiTween:Play()

		cooldownUiTween.Completed:Wait()

		cooldownUi.Size = UI_MIN
		cooldownUi.Visible = false
	end)
end

local function toolf(tool, config)
	local offhandUIValid = config:GetAttribute("OffDebounceTime") ~= nil
	local abilityUIValid = config:GetAttribute("Ability") == true

	setOffhandUI(offhandUIValid)
	setAbilityUI(abilityUIValid)

<<<<<<< HEAD
	local function handleOffhandInput(_, actionState)
		if not offhandUIValid then
=======
	hooks["Offhand"] = function(_, actionState)
		if not config:GetAttribute("OffDebounceTime") then
>>>>>>> c671428e3835c3bd57a7eedb21563d0073318977
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

<<<<<<< HEAD
	local function handleAbilityInput(_, actionState)
		if not (actionState == Enum.UserInputState.Begin) then
			return
		end
=======
	hooks["Ability"] = function(_, actionState)
		if actionState == Enum.UserInputState.Begin then
			if config:GetAttribute("Ability") == true then
				local valid = toolAbility:InvokeServer(tool, config, false)
>>>>>>> c671428e3835c3bd57a7eedb21563d0073318977

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

	ContextActionService:BindAction("OffhandInput", hooks["Offhand"], false, Enum.KeyCode.F)
	--ContextActionService:SetImage("OffhandInput", "http://www.roblox.com/asset/?id=11554338960")

	ContextActionService:BindAction("AbilityInput", hooks["Ability"], false, Enum.KeyCode.Q)
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
	rollDebounce.Event:Connect(function(info)
		if info then
			hooks["Roll"] = info
			return
		end

		startActivate("Roll")
		startDebounce("Roll", 3)

		task.delay(3, function()
			stopActivate("Roll")
		end)
	end)

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
