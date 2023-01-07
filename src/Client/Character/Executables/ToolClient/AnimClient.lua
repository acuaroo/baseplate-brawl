local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid.Animator

local animations = ReplicatedStorage["Animations"]
local animRelay = ReplicatedStorage["Events"].AnimRelay

local playing = {}

animRelay.OnClientEvent:Connect(function(req, cancel, delTime, override)
	if not cancel then
		local animation = animations:FindFirstChild(req)
		
		if not animation then return end
		while character.Parent == nil do task.wait(); end
		
		local animLoaded = animator:LoadAnimation(animation)
		
		repeat task.wait() until animLoaded.Length > 0
		
		if override then
			animLoaded:Play()
			
			task.spawn(function()
				animLoaded.Stopped:Wait()
				
				if playing[override] then
					playing[override]:Stop()
				end
			end)
		else
			animLoaded:Play()
		end
		
		playing[req] = animLoaded
		
		if delTime then
			task.delay(delTime, function()
				if animLoaded then 
					animLoaded:Stop() 
					playing[animation] = nil
				end
			end)
		end
	else
		local animation = playing[req]
		if not animation then return end
		
		animation:Stop()
		playing[req] = nil
	end
end)

return playing