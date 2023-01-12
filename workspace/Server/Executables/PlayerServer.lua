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
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local Trove = require(ServerStorage["Modules"].Trove)

local sprint = ReplicatedStorage["Events"].Sprint
local animRelay = ReplicatedStorage["Events"].AnimRelay
local particleHolder = ServerStorage["Assets"].Combat.ParticleHolder
local stunParticles = particleHolder.StunParticles

local sprintTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local antiSprint = {
	"SLOW",
	"STUN",
	"STUNLOCK",
	"GRAB",
}

local DEFAULT_SPEED = 0
local DEFAULT_STAMINA = 1
local DEFAULT_REGEN = 100
local STAMINA_CUTOFF = 50
local STAMINA_DEPLEAT = 1

local PlayerServer = {}

local function adjustSpeed(player, new)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = new
end

local function emitParticles(player, particles, amount)
	local head = player.Character:FindFirstChild("Head")
	particles = particles:Clone()
	particles.Parent = head

	for _, part in pairs(particles:GetChildren()) do
		part:Emit(amount)
	end
end

Players.PlayerAdded:Connect(function(player)
	local playerTrace = {}
	playerTrace.PrimaryState = "NONE"
	playerTrace.SecondaryState = "NONE"
	playerTrace.MovementState = "WALKING"

	playerTrace.Stamina = 200
	playerTrace.StaminaRegen = 1

	playerTrace._trove = Trove.new()
	playerTrace._player = player
	playerTrace._restam = false

	local replFolder = playerTrace._trove:Add(Instance.new("Folder"))
	replFolder.Parent = player
	replFolder.Name = "REPLICATEVALS"

	local staminaReplicate = playerTrace._trove:Add(Instance.new("NumberValue"))
	staminaReplicate.Name = "STAMINA"
	staminaReplicate.Value = playerTrace.Stamina
	staminaReplicate.Parent = replFolder

	function playerTrace:SetPrimary(value)
		playerTrace.PrimaryState = value
		playerTrace:_changed()
	end

	function playerTrace:_changed()
		if self.PrimaryState == "SLOW" or self.PrimaryState == "STUNLOCK" then
			adjustSpeed(player, 7)
		elseif self.PrimaryState == "NONE" then
			adjustSpeed(player, 16)
		elseif self.PrimaryState == "STUN" then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			adjustSpeed(player, 5)

			humanoid:UnequipTools()
			self.MovementState = "WALKING"

			emitParticles(player, stunParticles, 3)
		elseif self.PrimaryState == "NOMOVE" then
			adjustSpeed(player, 0)
		end
	end

	function playerTrace:_sprint()
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		if self.Stamina < STAMINA_CUTOFF then
			self:_restamina()
			return
		end

		self.MovementState = "RUNNING"
		animRelay:FireClient(player, "Run")
		TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = 25 }):Play()

		repeat
			self.Stamina -= STAMINA_DEPLEAT
			staminaReplicate.Value = self.Stamina
			task.wait(0.05)
		until self.Stamina <= 0 or self.MovementState == "WALKING" or humanoid.MoveDirection.Magnitude == 0

		animRelay:FireClient(player, "Run", true)
		self:_restamina()
	end

	function playerTrace:_restamina()
		if playerTrace._restam then
			return
		end
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		self.MovementState = "WALKING"
		TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = 16 }):Play()
		playerTrace._restam = true

		repeat
			self.Stamina += self.StaminaRegen
			staminaReplicate.Value = self.Stamina
			task.wait(0.05)
		until self.Stamina >= 200 or self.MovementState == "RUNNING"

		-- prevent odd StaminaRegen values from creating inf regen
		self.Stamina = math.clamp(self.Stamina, 0, 200)

		playerTrace._restam = false

		if self.MovementState ~= "RUNNING" then
			animRelay:FireClient(player, "Run", true)
			return
		end
	end

	function playerTrace:SprintRequest()
		if table.find(antiSprint, self.PrimaryState) then
			return
		end

		local humanoid = player.Character:FindFirstChild("Humanoid")

		if not humanoid or self.MovementState == "WALKING" then
			return
		end

		if humanoid.MoveDirection.Magnitude > 0.1 then
			self:_sprint()
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

	local changeCache = nil
	local changeCacheStam = nil

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid:SetAttribute("Speed", DEFAULT_SPEED)
		humanoid:SetAttribute("Regeneration", DEFAULT_REGEN)
		humanoid:SetAttribute("Stamina", DEFAULT_STAMINA)

		humanoid:GetAttributeChangedSignal("Speed"):Connect(function()
			if humanoid:GetAttribute("Speed") == 0 and changeCache then
				humanoid.WalkSpeed -= changeCache
			else
				changeCache = (humanoid.WalkSpeed * humanoid:GetAttribute("Speed"))
				humanoid.WalkSpeed += changeCache
			end
		end)

		humanoid:GetAttributeChangedSignal("Stamina"):Connect(function()
			if humanoid:GetAttribute("Stamina") == 0 and changeCacheStam then
				playerTrace.StaminaRegen -= changeCacheStam
			else
				changeCacheStam = (playerTrace.StaminaRegen * humanoid:GetAttribute("Stamina"))
				playerTrace.StaminaRegen += changeCacheStam
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
			metaplayer.MovementState = "RUNNING"
			metaplayer:SprintRequest()
		else
			metaplayer.MovementState = "WALKING"
		end
	end)
end

return PlayerServer
