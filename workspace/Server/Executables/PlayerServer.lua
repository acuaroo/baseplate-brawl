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

local PlayerServer = {}

Players.PlayerAdded:Connect(function(player)
	local playerTrace = {}
	playerTrace.PrimaryState = "NONE"
	playerTrace.SecondaryState = "NONE"
	playerTrace.MovementState = "WALKING"
	playerTrace.Stamina = 200
	playerTrace._player = player
	playerTrace._trove = Trove.new()
	playerTrace._restam = false
	playerTrace.StaminaRegen = 1

	local replFolder = playerTrace._trove:Add(Instance.new("Folder"))
	replFolder.Parent = player
	replFolder.Name = "REPLICATEVALS"

	local staminaReplicate = playerTrace._trove:Add(Instance.new("NumberValue"))
	staminaReplicate.Name = "STAMINA"
	staminaReplicate.Value = playerTrace.Stamina
	staminaReplicate.Parent = replFolder

	function playerTrace:Changed()
		if self.PrimaryState == "SLOW" then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end

			humanoid.WalkSpeed = 7
		elseif self.PrimaryState == "NONE" then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if not humanoid or self.MovementState == "RUNNING" then
				return
			end

			humanoid.WalkSpeed = 16
		elseif self.PrimaryState == "STUN" then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local head = player.Character:FindFirstChild("Head")

			if not humanoid or not head then
				return
			end

			local particles = stunParticles:Clone()
			particles.Parent = head
			humanoid.WalkSpeed = 5
			humanoid:UnequipTools()
			self.MovementState = "WALKING"

			for _, part in pairs(particles:GetChildren()) do
				part:Emit(3)
			end
		elseif self.PrimaryState == "NOMOVE" then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end

			self.MovementState = "WALKING"
			humanoid.WalkSpeed = 0
		elseif self.PrimaryState == "STUNLOCK" then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end

			self.MovementState = "WALKING"
			humanoid.WalkSpeed = 7
		end
	end

	function playerTrace:_sprint()
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		if self.Stamina < 50 then
			self:_restamina()
			return
		end

		self.MovementState = "RUNNING"
		animRelay:FireClient(player, "Run")
		TweenService:Create(humanoid, sprintTweenInfo, { WalkSpeed = 25 }):Play()

		repeat
			self.Stamina -= 1
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
		until self.Stamina == 200 or self.MovementState == "RUNNING"
		playerTrace._restam = false

		if self.MovementState ~= "RUNNING" then
			animRelay:FireClient(player, "Run", true)
			return
		end
	end

	function playerTrace:Sprint()
		if self.PrimaryState == "SLOW" then
			return
		end
		if self.PrimaryState == "STUN" then
			return
		end
		if self.PrimaryState == "GRAB" then
			return
		end
		if self.PrimaryState == "STUNLOCK" then
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
		PlayerServer[enemy].PrimaryState = status
		PlayerServer[enemy]:Changed()

		if not duration then
			return
		end

		task.delay(duration, function()
			if PlayerServer[enemy] then
				PlayerServer[enemy].PrimaryState = "NONE"
				PlayerServer[enemy]:Changed()
			end
		end)
	end

	local changeCache = nil
	local changeCacheStam = nil

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid:SetAttribute("Speed", 0)
		humanoid:SetAttribute("Regeneration", 100)
		humanoid:SetAttribute("Stamina", 1)

		humanoid:GetAttributeChangedSignal("Speed"):Connect(function()
			if humanoid:GetAttribute("Speed") == 0 and changeCache then
				humanoid.WalkSpeed -= changeCache
			else
				changeCache = (humanoid.WalkSpeed * humanoid:GetAttribute("Speed"))
				humanoid.WalkSpeed += changeCache
			end
		end)

		humanoid:GetAttributeChangedSignal("Stamina"):Connect(function()
			if humanoid:GetAttribute("Stamina") == 0 and changeCache then
				playerTrace.StaminaRegen -= changeCache
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
			metaplayer:Sprint()
		else
			metaplayer.MovementState = "WALKING"
		end
	end)
end

return PlayerServer
