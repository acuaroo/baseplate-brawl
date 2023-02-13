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

local toolEquip = ReplicatedStorage["Events"].ToolEquip
local notificationChannel = ReplicatedStorage["Events"].Notification

local notificationMain = statsFrame.NotificationMain
local notificationMainReset = UDim2.new(3, 0, 1.067, 0)
local notificationMainOut = UDim2.new(1.407, 0, 1.067, 0)

local notificationOpp = statsFrame.NotificationOpp
local notificationOppReset = UDim2.new(-3, 0, 1.067, 0)
local notificationOppOut = UDim2.new(-1.075, 0, 1.067, 0)

local totalHealth = statsFrame.Health.TotalHealth
local currentHealth = totalHealth.CurrentHealth

local soulCount = statsFrame.Souls.TextLabel
local souls = player:WaitForChild("leaderstats").souls

local statusFrame = statsFrame.Status
local statusTemplate = statusFrame.UIListLayout.Status

local tools = backpack:GetChildren()
-- local currentState = nil

local VISUAL_OFFSET = CFrame.new(Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 50))
local ROTATIONAL_OFFSET = CFrame.Angles(math.rad(-45), 0, math.rad(45))
local TOOL_RATIO = 6.24531601299

local RED_ARROW = Color3.fromRGB(255, 129, 131)
local GREEN_ARROW = Color3.fromRGB(178, 255, 174)

local validKeyCodes = {
	[Enum.KeyCode.One] = { 1, Enum.KeyCode.One },
	[Enum.KeyCode.Two] = { 2, Enum.KeyCode.Two },
	[Enum.KeyCode.Three] = { 3, Enum.KeyCode.Three },
	[Enum.KeyCode.Four] = { 4, Enum.KeyCode.Four },
	[Enum.KeyCode.Five] = { 5, Enum.KeyCode.Five },
	[Enum.KeyCode.Six] = { 6, Enum.KeyCode.Six },
}

local activeTool = nil
local activeStatuses = {}
local hotConnections = {}

local GuiClient = {}

local function tweenNotification(frame, method)
	frame:TweenPosition(method, Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.5)
end

local function renderStatus(stat)
	if not stat then
		return
	end

	local statEffect = stat:GetAttribute("Effect")
	local statArrow = stat.Arrow
	local hover = stat.Hover

	if statEffect < 0 then
		statArrow.Rotation = 180
		statArrow.ImageColor3 = RED_ARROW
	else
		statArrow.Rotation = 0
		statArrow.ImageColor3 = GREEN_ARROW
	end

	statArrow.Visible = true

	hover.Title.Text = stat:GetAttribute("Name")
	hover.Description.Text = tostring(math.floor(statEffect * 10))
		.. "x, "
		.. tostring(math.floor(stat:GetAttribute("Duration")))
		.. " sec"

	stat.MouseEnter:Connect(function()
		hover.Visible = true
	end)

	stat.MouseLeave:Connect(function()
		hover.Visible = false
	end)
end

local function delayStatus(status)
	task.delay(status["Duration"], function()
		local stat = activeStatuses[status["Name"]]
		if not stat then
			return
		end

		if (stat:GetAttribute("Override") or 0) >= 1 then
			stat:SetAttribute("Effect", (stat:GetAttribute("Effect") - status["Effect"]))
			stat:SetAttribute("Duration", (stat:GetAttribute("Duration") - status["Duration"]))

			renderStatus(stat)

			stat:SetAttribute("Override", stat:GetAttribute("Override") - 1)
			return
		end

		stat:Destroy()
		activeStatuses[status["Name"]] = nil
	end)
end

local function toolCheck(currentTool)
	if activeTool == currentTool then
		local valid = toolEquip:InvokeServer(currentTool, false)

		if valid then
			activeTool = nil
		end
	else
		local valid = toolEquip:InvokeServer(currentTool, true)

		if valid then
			activeTool = currentTool
		end
	end
end

local function viewPortize(toolVisual, viewport)
	toolVisual:SetPrimaryPartCFrame(VISUAL_OFFSET)

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
		viewportCamera.CFrame = CFrame.new(Vector3.new(0, 25.2, (toolVisual.PrimaryPart.Size.Z * TOOL_RATIO)))
			* ROTATIONAL_OFFSET
	end

	viewportCamera.DiagonalFieldOfView = 0.7
	viewportCamera.FieldOfView = toolSettings:GetAttribute("FOV")
end

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
			warn("[GUI]: No BuildModel for " .. tool.Name)
			continue
		end

		toolVisual = toolVisual:Clone()

		if not toolVisual.PrimaryPart then
			warn("[GUI]: No PrimaryPart for " .. tool.Name)
			continue
		end

		viewPortize(toolVisual, viewport)

		hotConnections[index] = hotbarSlot.MouseButton1Down:Connect(function()
			local currentTool = tools[index]

			toolCheck(currentTool)
		end)
	end
end

local function statusLoop(statusArgs)
	for _, status in statusArgs do
		if activeStatuses[status["Name"]] then
			local stat = activeStatuses[status["Name"]]

			stat:SetAttribute("Duration", stat:GetAttribute("Duration") + status["Duration"])
			stat:SetAttribute("Effect", stat:GetAttribute("Effect") + status["Effect"])

			local oldOverride = stat:GetAttribute("Override") or 0
			stat:SetAttribute("Override", oldOverride + 1)

			renderStatus(stat)
			delayStatus(status)
			continue
		end

		local stat = statusTemplate:Clone()
		stat.Parent = statusFrame

		stat.Image = status["Image"]

		stat:SetAttribute("Duration", status["Duration"])
		stat:SetAttribute("Name", status["Name"])
		stat:SetAttribute("Effect", status["Effect"])

		renderStatus(stat)

		activeStatuses[status["Name"]] = stat

		delayStatus(status)
	end
end

local function notification(frame, resetPosition, outPosition, args)
	frame.Title.Text = args[1]
	frame.Description.Text = args[2]
	frame.Icon.Image = args[3]

	frame.Parent.Position = resetPosition
	tweenNotification(frame.Parent, outPosition)

	if args[4] == true then
		return
	end

	task.delay(args[4], function()
		tweenNotification(frame.Parent, resetPosition)
	end)
end

local function loopRemoved(obj)
	for index, tool in pairs(tools) do
		if not (tool == obj) then
			continue
		end

		table.remove(tools, index)

		if hotConnections[index] then
			hotConnections[index]:Disconnect()
			hotConnections[index] = nil
		end

		sortBackpack()
		break
	end
end

local function initializeBackpack()
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
			loopRemoved(obj)
		end
	end)

	sortBackpack()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if validKeyCodes[input.KeyCode] then
			local currentTool = tools[validKeyCodes[input.KeyCode][1]]

			toolCheck(currentTool)
		end
	end)
end

local function intializeHealth()
	humanoid.HealthChanged:Connect(function()
		local maxHealth = humanoid.MaxHealth
		local newPos = math.clamp((humanoid.Health / maxHealth), 0, maxHealth)

		currentHealth:TweenSize(UDim2.new(newPos, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.1)
	end)
end

local function intializeSouls()
	soulCount.Text = souls.Value

	souls.Changed:Connect(function()
		soulCount.Text = souls.Value
	end)
end

local function listenToNotifications()
	notificationChannel.OnClientEvent:Connect(function(args, opp, statusArgs)
		-- args[4] is cancel value
		if args[4] == false then
			tweenNotification(notificationMain, notificationMainReset)
			return
		end

		if statusArgs then
			statusLoop(statusArgs)
		end

		if not opp then
			notification(notificationMain.Notification, notificationMainReset, notificationMainOut, args)
		else
			notification(notificationOpp.Notification, notificationOppReset, notificationOppOut, args)
		end
	end)
end

function GuiClient:Run()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	task.spawn(initializeBackpack)
	task.spawn(intializeHealth)
	task.spawn(intializeSouls)
	task.spawn(listenToNotifications)
end

return GuiClient
