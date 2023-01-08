local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local backpack = player.Backpack
local playerGui = player.PlayerGui
local hotbarGui = playerGui.Hotbar
local statsFrame = hotbarGui.StatsFrame
local hotbarFrame = statsFrame.HotbarFrame

local notificationChannel = ReplicatedStorage["Events"].Notification

local notifications = playerGui.Notifications
local notificationMain = notifications.NotificationMain
local notificationOpp = notifications.NotificationOpp

local totalHealth = statsFrame.Health.TotalHealth
local currentHealth = totalHealth.CurrentHealth

local totalStamina = statsFrame.Stamina.TotalStamina
local currentStamina = totalStamina.CurrentStamina
local lowStamina = Color3.fromRGB(255, 116, 118)
local normalStamina = Color3.fromRGB(162, 220, 162)

local staminaReplicate = player:WaitForChild("REPLICATEVALS").STAMINA

local tools = backpack:GetChildren()
local visualOffset = CFrame.new(Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 50))
local rotationalOffset = CFrame.Angles(math.rad(-45), 0, math.rad(45))
local toolSizeRatio = 6.24531601299

local validKeyCodes = {
	[Enum.KeyCode.One] = { 1, Enum.KeyCode.One },
	[Enum.KeyCode.Two] = { 2, Enum.KeyCode.Two },
	[Enum.KeyCode.Three] = { 3, Enum.KeyCode.Three },
	[Enum.KeyCode.Four] = { 4, Enum.KeyCode.Four },
	[Enum.KeyCode.Five] = { 5, Enum.KeyCode.Five },
	[Enum.KeyCode.Six] = { 6, Enum.KeyCode.Six },
}

local activeTool = nil

local GuiClient = {}

function GuiClient:Run()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	local function sortBackpack()
		for index, tool in pairs(tools) do
			local hotbarSlot = hotbarFrame["Slot" .. index]
			if not hotbarSlot then
				continue
			end

			local viewport = hotbarSlot.ImageViewport
			viewport.Visible = true
			viewport:ClearAllChildren()

			local toolVisual = tool:FindFirstChild("Build")
			if not toolVisual then
				continue
			end

			toolVisual = toolVisual:Clone()

			if not toolVisual.PrimaryPart then
				continue
			end
			toolVisual:SetPrimaryPartCFrame(visualOffset)

			local toolSettings = toolVisual:FindFirstChild("Settings")

			if toolSettings:GetAttribute("VisualCFrame") then
				local customVisualCFrame = toolSettings:GetAttribute("VisualCFrame")
				toolVisual:SetPrimaryPartCFrame(customVisualCFrame)
			end

			toolVisual.Parent = viewport

			local viewportCamera = Instance.new("Camera")
			viewportCamera.Parent = viewport
			viewport.CurrentCamera = viewportCamera

			if toolSettings:GetAttribute("CameraCFrame") then
				local customCameraCFrame = toolSettings:GetAttribute("CameraCFrame")
				viewportCamera.CFrame = customCameraCFrame
			else
				viewportCamera.CFrame = CFrame.new(
					Vector3.new(0, 25.2, (toolVisual.PrimaryPart.Size.Z * toolSizeRatio))
				) * rotationalOffset
			end

			viewportCamera.DiagonalFieldOfView = 0.7
			viewportCamera.FieldOfView = toolSettings:GetAttribute("FOV")
		end
	end

	backpack.ChildAdded:Connect(function(obj)
		if obj:IsA("Tool") and not table.find(tools, obj) then
			table.insert(tools, obj)
			sortBackpack()
		end
	end)

	character.ChildAdded:Connect(function(obj)
		if obj:IsA("Tool") and not table.find(tools, obj) then
			table.insert(tools, obj)
			sortBackpack()
		end
	end)

	character.ChildRemoved:Connect(function(obj)
		if obj:IsA("Tool") and not table.find(tools, obj) then
			local count = 0

			for _, tool in pairs(tools) do
				count += 1
				if tool == obj then
					table.remove(tools, count)
					sortBackpack()
					break
				end
			end
		end
	end)

	sortBackpack()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if validKeyCodes[input.KeyCode] then
			local currentTool = tools[validKeyCodes[input.KeyCode][1]]

			if activeTool == currentTool then
				activeTool = nil
				humanoid:UnequipTools()
			else
				activeTool = currentTool
				humanoid:UnequipTools()
				humanoid:EquipTool(currentTool)
			end
		end
	end)

	staminaReplicate.Changed:Connect(function()
		local newPos = staminaReplicate.Value / 200
		currentStamina.BackgroundColor3 = normalStamina

		if newPos < 0.25 then
			currentStamina.BackgroundColor3 = lowStamina
		end

		currentStamina:TweenSize(UDim2.new(newPos, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.1)
	end)

	humanoid.HealthChanged:Connect(function()
		local maxHealth = humanoid.MaxHealth
		local newPos = math.clamp((humanoid.Health / maxHealth), 0, maxHealth)

		currentHealth:TweenSize(UDim2.new(newPos, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.1)
	end)

	notificationChannel.OnClientEvent:Connect(function(args, opp)
		if not opp then
			local frame = notificationMain.Notification
			frame.Title.Text = args[1]
			frame.Description.Text = args[2]
			frame.Icon.Image = args[3]

			frame.Position = UDim2.new(3, 0, 0.05, 0)
			frame:TweenPosition(
				UDim2.new(0.18, 0, 0.05, 0),
				Enum.EasingDirection.In,
				Enum.EasingStyle.Linear,
				0.5,
				true
			)

			task.delay(args[4], function()
				frame:TweenPosition(
					UDim2.new(3, 0, 0.05, 0),
					Enum.EasingDirection.In,
					Enum.EasingStyle.Linear,
					0.5,
					true
				)
			end)
		else
			local frame = notificationOpp.Notification
			frame.Title.Text = args[1]
			frame.Description.Text = args[2]
			frame.Icon.Image = args[3]

			frame.Position = UDim2.new(-3, 0, 0.05, 0)
			frame:TweenPosition(
				UDim2.new(0.03, 0, 0.05, 0),
				Enum.EasingDirection.In,
				Enum.EasingStyle.Linear,
				0.5,
				true
			)

			task.delay(args[4], function()
				frame:TweenPosition(
					UDim2.new(-3, 0, 0.05, 0),
					Enum.EasingDirection.In,
					Enum.EasingStyle.Linear,
					0.5,
					true
				)
			end)
		end
	end)
end

return GuiClient
