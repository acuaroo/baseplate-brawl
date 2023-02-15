local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local camera = workspace.CurrentCamera
local shopCamera = workspace.Shop.ShopCamera
local shopInteract = workspace.Shop.ShopInteract.Prompt

local player = Players.LocalPlayer
--local character = player.Character or player.CharacterAdded:Wait()
local playerGui = player.PlayerGui

local shopUI = playerGui.Shop
local content = shopUI.Content
local options = shopUI.Options

local shopInteracted = ReplicatedStorage["Events"].ShopInteracted
local dataRequest = ReplicatedStorage["Events"].DataRequest

local currentFrame = nil
local hookBuy = nil

local clickCooldown = false
local shopLoaded = false

local VISUAL_OFFSET = CFrame.new(Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 50))
local ROTATIONAL_OFFSET = CFrame.Angles(math.rad(-45), 0, math.rad(45))
local TOOL_RATIO = 6.24531601299

local function tweenOutCurrentFrame()
	if currentFrame == nil then
		return
	end

	local frame = shopUI:FindFirstChild(currentFrame)

	if frame then
		frame:TweenPosition(UDim2.new(0.5, 0, -1.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 1.5)

		task.delay(0.6, function()
			frame.Position = UDim2.new(0.5, 0, 2, 0)
		end)
	end
end

local function tweenInFrame(frameName)
	tweenOutCurrentFrame()

	local frame = shopUI:FindFirstChild(frameName)

	if frame then
		--print(frame.Name)
		frame.Position = UDim2.new(0.5, 0, 2, 0)

		frame:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1.5)
		currentFrame = frameName

		return frame
	else
		return nil
	end
end

local function changeContent(contentFrame, item)
	contentFrame.Title.Text = string.lower(item.name)
	contentFrame.Description.Text = item.description
	contentFrame.SoulFrame.TextLabel.Text = item.price

	if hookBuy then
		hookBuy:Disconnect()
		hookBuy = nil
	end

	hookBuy = contentFrame.Buy.MouseButton1Down:Connect(function()
		local purchaseInfo = dataRequest:InvokeServer("Buy", item.name)

		if purchaseInfo then
			--{0.231, 0},{0.266, 0}
			contentFrame.ClipDec.Notification.Text = purchaseInfo
			contentFrame.ClipDec.Notification:TweenPosition(
				UDim2.new(0.231, 0, 0.266, 0),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quart,
				0.75
			)

			task.delay(2, function()
				contentFrame.ClipDec.Notification:TweenPosition(
					UDim2.new(0.231, 0, 1.5, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quart,
					0.75
				)
			end)

			print(purchaseInfo)
		end
	end)
end

local function unloadHotbar()
	local statsFrame = playerGui.Hotbar.StatsFrame
	statsFrame:TweenPosition(UDim2.new(0.5, 0, 2, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1)
end

local function loadHotbar()
	local statsFrame = playerGui.Hotbar.StatsFrame
	statsFrame:TweenPosition(UDim2.new(0.5, 0, 0.76, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1)
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

local loadedFunctions = {
	["Shop"] = function()
		local frame = tweenInFrame("Shop")

		if shopLoaded then
			return
		end

		local itemScroller = frame.ItemScroller
		local itemTemplate = itemScroller.UIGridLayout.ItemTemplate

		local shopItems = dataRequest:InvokeServer("ShopList")
		local shopHooks = {}

		for _, item in shopItems do
			local newTemplate = itemTemplate:Clone()
			newTemplate.Parent = itemScroller
			newTemplate.Title.Text = string.lower(item.name)

			local itemBuild = ReplicatedStorage["Assets"]["ToolBuilds"]:FindFirstChild(item.name):Clone()

			if itemBuild then
				viewPortize(itemBuild, newTemplate)
			end

			shopHooks[item.name] = newTemplate.Click.MouseButton1Down:Connect(function()
				changeContent(frame, item)
			end)
		end

		shopLoaded = true
	end,
	["Bag"] = function()
		local frame = tweenInFrame("Bag")

		--print(frame.Name .. " req")
	end,
}

local optionHooks = {}

local MenuClient = {}

function MenuClient:Run()
	shopInteracted.OnClientEvent:Connect(function()
		shopInteract.Enabled = false
		camera.CameraType = Enum.CameraType.Scriptable

		local cameraTween = TweenService:Create(camera, TweenInfo.new(0.75), { CFrame = shopCamera.CFrame })
		cameraTween:Play()

		clickCooldown = true

		content:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1)
		options:TweenPosition(UDim2.new(0.006, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1)
		unloadHotbar()

		loadedFunctions["Shop"]()

		task.delay(1, function()
			clickCooldown = false
		end)

		for _, option in options.Holder:GetChildren() do
			if option:IsA("UIListLayout") then
				continue
			end

			local frame = shopUI:FindFirstChild(option.Name)

			if not frame then
				continue
			end

			optionHooks[option.Name] = option.MouseButton1Down:Connect(function()
				if clickCooldown then
					return
				end

				print(currentFrame .. tostring(clickCooldown))

				if frame and currentFrame ~= option.Name then
					clickCooldown = true

					loadedFunctions[option.Name]()

					task.delay(1, function()
						clickCooldown = false
					end)
				end
			end)
		end
	end)
end

return MenuClient
