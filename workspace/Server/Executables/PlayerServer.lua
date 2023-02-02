--[[

	PlayerServer.PlayerAdded -> metaplayer

	metaplayer:SetPrimary(value)
	-- sets the primary state of the player to [value]

	metaplayer:SprintRequest(player)
	-- requests the player to sprint

	metaplayer:ImposePrimary(status, enemy, duration (seconds))
	-- sets the primary state of [enemy] to [status] for [duration]

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Trove = require(ServerStorage["Modules"].Trove)
local WalkSpeedHandler = require(ServerStorage["Modules"].WalkSpeedHandler)

local sprint = ReplicatedStorage["Events"].Sprint
local animRelay = ReplicatedStorage["Events"].AnimRelay
local requestVisual = ReplicatedStorage["Events"].RequestVisual

local antiSprint = {
	"SLOW",
	"STUN",
	"STUNLOCK",
	"GRAB",
	"ATTACKING",
	"FUNCTIONAL",
}

local DEFAULT_SPEED = 0
local DEFAULT_REGEN = 100

local PlayerServer = {}

-- local function emitParticles(player, particles, amount)
-- 	local head = player.Character:FindFirstChild("Head")
-- 	particles = particles:Clone()
-- 	particles.Parent = head

-- 	for _, part in pairs(particles:GetChildren()) do
-- 		part:Emit(amount)
-- 	end
-- end

WalkSpeedHandler:HookPlayers()

Players.PlayerAdded:Connect(function(player)
	local playerTrace = {}
	playerTrace.PrimaryState = "NONE"
	playerTrace.SecondaryState = "NONE"
	playerTrace.PreviousPrimary = "NONE"
	playerTrace.MovementState = "WALKING"

	playerTrace._trove = Trove.new()
	playerTrace._player = player

	function playerTrace:SetPrimary(value)
		self.PreviousPrimary = self.PrimaryState
		self.PrimaryState = value
		self:_changed()
	end

	function playerTrace:_changed()
		if table.find(antiSprint, self.PrimaryState) then
			self:StopSprint()
		end

		if self.PrimaryState == "SLOW" or self.PrimaryState == "STUNLOCK" then
			WalkSpeedHandler:AdjustSpeed(player, -8)
		elseif self.PrimaryState == "NONE" and self.PreviousPrimary == "SLOW" or self.PreviousPrimary == "STUNLOCK" then
			WalkSpeedHandler:SetSpeed(player, WalkSpeedHandler:GetCachedSpeed(player))
		elseif self.PrimaryState == "STUN" then
			WalkSpeedHandler:AdjustSpeed(player, -10)
			--humanoid:UnequipTools()
			self.MovementState = "WALKING"
		elseif self.PrimaryState == "NOMOVE" then
			WalkSpeedHandler:SetSpeed(player, 0)
		end
	end

	function playerTrace:Sprint()
		self.MovementState = "RUNNING"
		animRelay:FireClient(player, "Run")

		requestVisual:FireClient(player, "SprintEffect", { ["Toggle"] = nil })
		WalkSpeedHandler:TweenToAdjust(player, 9)
	end

	function playerTrace:StopSprint()
		requestVisual:FireClient(player, "SprintEffect", {
			["Toggle"] = "CLEAN",
		})

		animRelay:FireClient(player, "Run", true)
		self.MovementState = "WALKING"
		WalkSpeedHandler:SetSpeed(player, 16)
	end

	function playerTrace:SprintRequest()
		if table.find(antiSprint, self.PrimaryState) then
			return
		end

		local humanoid = player.Character:FindFirstChild("Humanoid")

		if not humanoid then
			return
		end

		if humanoid.MoveDirection.Magnitude > 0.1 then
			self.MovementState = "RUNNING"
			self:Sprint()
		end
	end

	function playerTrace:ImposePrimary(status, enemy, duration)
		if not PlayerServer[enemy] then
			return
		end
		PlayerServer[enemy]:SetPrimary(status)

		if not duration then
			return
		end

		task.delay(duration, function()
			if PlayerServer[enemy] then
				PlayerServer[enemy]:SetPrimary("NONE")
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid:SetAttribute("Speed", DEFAULT_SPEED)
		humanoid:SetAttribute("Regeneration", DEFAULT_REGEN)

		humanoid:GetAttributeChangedSignal("Speed"):Connect(function()
			if humanoid:GetAttribute("Speed") == 0 then
				WalkSpeedHandler:SetSpeed(player, 16)
			else
				print(tostring(16 + (16 * humanoid:GetAttribute("Speed"))))

				WalkSpeedHandler:PrefixSpeed(player, (16 * humanoid:GetAttribute("Speed")), 16)
			end
		end)
	end)

	PlayerServer[player] = playerTrace
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerServer[player]._trove:Destroy()
	PlayerServer[player] = nil
end)

function PlayerServer:Run()
	sprint.OnServerEvent:Connect(function(player, on)
		local metaplayer = PlayerServer[player]
		if not metaplayer then
			return
		end

		if on then
			metaplayer:SprintRequest()
		else
			metaplayer:StopSprint()
		end
	end)
end

return PlayerServer
