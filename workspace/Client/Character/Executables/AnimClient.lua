--[[

	AnimClient:Run()
	-- starts up animclient
	
	animRelay.OnClientEvent(req, cancel, delTime, override)
	-- server can request client to play animation

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid.Animator

local animations = ReplicatedStorage["Animations"]
local animRelay = ReplicatedStorage["Events"].AnimRelay

ContentProvider:PreloadAsync(animations:GetChildren())

local playing = {}

local AnimClient = {}

local function checkPlaying(req)
	local animation = playing[req]

	return animation
end

local function stopAnimation(req)
	local animation = checkPlaying(req)

	if not animation then
		return
	end

	animation:Stop()
	playing[req] = nil
end

local function playAnimation(req, delTime, override)
	local animation = animations:FindFirstChild(req)

	if not animation then
		return
	end

	local animLoaded = animator:LoadAnimation(animation)

	repeat
		task.wait()
	until animLoaded.Length > 0

	animLoaded:Play()
	playing[req] = animLoaded

	if override then
		task.spawn(function()
			animLoaded.Stopped:Wait()
			stopAnimation(override)
		end)
	end

	if not delTime then
		return
	end

	task.delay(delTime, function()
		stopAnimation(req)
	end)
end

function AnimClient:Run()
	while character.Parent == nil do
		task.wait()
	end

	animRelay.OnClientEvent:Connect(function(req, cancel, delTime, override)
		if cancel then
			stopAnimation(req)
		else
			playAnimation(req, delTime, override)
		end
	end)
end

return AnimClient
