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
local roll = ReplicatedStorage["Events"].Roll
local animRelay = ReplicatedStorage["Events"].AnimRelay
local requestVisual = ReplicatedStorage["Events"].RequestVisual
local debug = ReplicatedStorage["Events"].Debug
-- local gameState = ReplicatedStorage["Events"].GetGameState
local shopInteracted = ReplicatedStorage["Events"].ShopInteracted

local shop = workspace:WaitForChild("Shop")
local shopInteract = shop:WaitForChild("ShopInteract")

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
	playerTrace.GameState = "GAME"
	playerTrace.Immune = false

	playerTrace._trove = Trove.new()
	playerTrace._player = player

	function playerTrace:SetPrimary(value)
		self.PreviousPrimary = self.PrimaryState
		self.PrimaryState = value
		self:_changed()

		if self.Debug then
			debug:FireClient(player, "PrimaryState", value)
		end
	end

	function playerTrace:_changed()
		if table.find(antiSprint, self.PrimaryState) then
			self:StopSprint()
		end

		if self.PrimaryState == "SLOW" or self.PrimaryState == "STUNLOCK" then
			WalkSpeedHandler:AdjustSpeed(player, -8)
		elseif
			self.PrimaryState == "NONE"
			and (
				self.PreviousPrimary == "SLOW"
				or self.PreviousPrimary == "STUNLOCK"
				or self.PreviousPrimary == "NOMOVE"
			)
		then
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

		if self.Debug then
			debug:FireClient(player, "MovementState", "RUNNING")
		end

		requestVisual:FireClient(player, "SprintEffect", { ["Toggle"] = nil })
		WalkSpeedHandler:TweenToAdjust(player, 9)
	end

	function playerTrace:Roll()
		self.MovementState = "ROLLING"

		if self.Debug then
			debug:FireClient(player, "MovementState", "ROLLING")
		end

		local humanoidRP = player.Character.HumanoidRootPart
		local humanoid = player.Character.Humanoid
		local humanoidState = humanoid:GetState()

		local rollAttachment: Attachment = Instance.new("Attachment")
		rollAttachment.Parent = humanoidRP

		local newVector: VectorForce = self._trove:Add(Instance.new("VectorForce"))
		newVector.Parent = humanoidRP
		newVector.Attachment0 = rollAttachment

		--newVector.Attachment1 = rollAttachment
		local mult = 9

		if humanoidState == Enum.HumanoidStateType.Freefall then
			mult = 3.5
		end

		if humanoidState == Enum.HumanoidStateType.Flying then
			mult = 3.5
		end

		if humanoidState == Enum.HumanoidStateType.Jumping then
			mult = 3.5
		end
		newVector.Force = Vector3.new(0, 0, -1) * (1000 * mult)
		-- newVector.Force = Vector3.new(0, 0, -1) * (1000 * mult)
		self.RollDebounce = true

		animRelay:FireClient(player, "Roll")

		task.delay(0.4, function()
			newVector:Destroy()
			self.MovementState = "WALKING"

			task.wait(2.6)

			self.RollDebounce = false
		end)
	end

	function playerTrace:StopSprint()
		requestVisual:FireClient(player, "SprintEffect", {
			["Toggle"] = "CLEAN",
		})

		animRelay:FireClient(player, "Run", true)
		self.MovementState = "WALKING"

		if self.Debug then
			debug:FireClient(player, "MovementState", "WALKING")
		end

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

	function playerTrace:RollRequest()
		if table.find(antiSprint, self.PrimaryState) or self.MovementState == "ROLLING" then
			return false
		end

		if self.RollDebounce then
			return false
		end

		local humanoid = player.Character:FindFirstChild("Humanoid")

		if not humanoid then
			return false
		end

		if humanoid.MoveDirection.Magnitude > 0.1 then
			self.MovementState = "ROLLING"
			self:Roll()

			return true
		end

		return false
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

	function playerTrace:SetImmune(set)
		local humanoid = player.Character:FindFirstChild("Humanoid")

		if not humanoid then
			return false
		end

		humanoid:SetAttribute("Immune", set)
		self.Immune = set
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		humanoid:SetAttribute("Speed", DEFAULT_SPEED)
		humanoid:SetAttribute("Regeneration", DEFAULT_REGEN)

		humanoid:GetAttributeChangedSignal("Speed"):Connect(function()
			if humanoid:GetAttribute("Speed") == 0 then
				WalkSpeedHandler:SetSpeed(player, 16)
			else
				WalkSpeedHandler:PrefixSpeed(player, (16 * humanoid:GetAttribute("Speed")), 16)
			end
		end)
	end)

	debug.OnServerEvent:Connect(function(playerobj, on)
		if playerobj == player then
			playerTrace.Debug = on
		end
	end)

	PlayerServer[player] = playerTrace
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerServer[player]._trove:Destroy()
	PlayerServer[player] = nil
end)

local function setForcefield(character)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.Material = Enum.Material.ForceField
		end
	end
end

local function undoForcefield(character)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.Material = Enum.Material.Plastic
		end
	end
end

function PlayerServer:Run()
	sprint.OnServerEvent:Connect(function(player, on)
		local metaplayer = PlayerServer[player]
		if not metaplayer then
			return
		end

		--using literal on == false, because it might be nil

		if on then
			metaplayer:SprintRequest()
		elseif on == false then
			metaplayer:StopSprint()
		else
			return
		end
	end)

	roll.OnServerInvoke = function(player)
		local metaplayer = PlayerServer[player]

		if not metaplayer then
			return false
		end

		local validRequest = metaplayer:RollRequest()

		return validRequest
	end

	-- gameState.OnServerEvent:Connect(function(player)
	-- 	local metaplayer = PlayerServer[player]

	-- 	if not metaplayer then
	-- 		return false
	-- 	end

	-- 	print(metaplayer.GameState)
	-- 	return metaplayer.GameState
	-- end)

	shopInteract.Prompt.Triggered:Connect(function(player)
		local metaplayer = PlayerServer[player]

		if not metaplayer then
			return false
		end

		metaplayer:SetPrimary("NOMOVE")
		metaplayer:SetImmune(true)
		metaplayer.GameState = "SHOP"

		setForcefield(player.Character)

		shopInteracted:FireClient(player, true)
	end)

	shopInteracted.OnServerEvent:Connect(function(player)
		local metaplayer = PlayerServer[player]

		if not metaplayer then
			return false
		end

		if not metaplayer.GameState == "GAME" then
			return
		end

		metaplayer:SetPrimary("NONE")
		metaplayer:SetImmune(false)
		metaplayer.GameState = "GAME"

		undoForcefield(player.Character)

		shopInteracted:FireClient(player, false)
	end)
end

return PlayerServer
