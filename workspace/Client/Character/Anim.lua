local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local animations = ReplicatedStorage:WaitForChild("Animations")
local events = ReplicatedStorage.Events

local animationRelay = events:WaitForChild("AnimationRelay")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

ContentProvider:PreloadAsync(animations:GetChildren())

local Anim = {}
Anim.CurrentAnimations = {}

function Anim:PlayAnimation(name, duration)
	if not humanoid then
		return
	end

	local animation = animations:FindFirstChild(name)

	if not animation then
		return
	end

	local animationTrack = animator:LoadAnimation(animation)
	animationTrack:Play()

	self.CurrentAnimations[name] = animationTrack

	if not duration then
		return
	end

	task.delay(duration, function()
		if not self.CurrentAnimations[name] then
			return
		end

		animationTrack:Stop()
		self.CurrentAnimations[name] = nil
	end)
end

function Anim:StopAnimation(name)
	local animationTrack = self.CurrentAnimations[name]

	if animationTrack then
		animationTrack:Stop()
		self.CurrentAnimations[name] = nil
	end
end

function Anim:GetCurrentAnimations()
	return self.CurrentAnimations
end

animationRelay.OnClientEvent:Connect(function(name, duration, action)
	if not action then
		action = "PLAY"
	end

	if action == "PLAY" then
		Anim:PlayAnimation(name, duration)
	elseif action == "STOP" then
		Anim:StopAnimation(name)
	end
end)

return Anim
