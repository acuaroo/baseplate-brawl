--[[

	Melee:CleanCast(&self&)
	-- cleans the cast connection for given melee

	Melee:CleanOff(&self&)
	-- cleans the offhand connection for given melee (typically shield)

	Melee:Debounce(&self&, address)
	-- debounces the given melee by the amount at self._config:GetAtt(address)

	Melee:OffDebounce(&self&, address)
	-- debounces the given melee's offhand by the amount at self._config:GetAtt(address)

	Melee:Activate(&self&)
	-- activates the given melee

	Melee:Offhand(&self&)
	-- activates the given melee

	Melee:Cleanup(&self&)
	-- cleans the given melee

	Melee:Shield(&self&, animationHeader, shield)
	-- creates/destroys a shield for the given melee
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Tool = require(script.Parent.Tool)
local Trove = require(ServerStorage["Modules"].Trove)
local ClientCast = require(ServerStorage["Modules"].ClientCast)
local DamageHandler = require(ServerStorage["Modules"].DamageHandler)

local combatAssets = ServerStorage["Assets"].Combat
local shieldAsset = combatAssets.Shield

local animRelay = ReplicatedStorage["Events"].AnimRelay
local animations = ReplicatedStorage["Animations"]
local requestVisual = ReplicatedStorage["Events"].RequestVisual

local meleehooks = {}

local Melee = {}
Melee.__index = Melee

setmetatable(Melee, Tool)

local function flip(animSide)
	if animSide == "L" then
		animSide = "R"
		return animSide
	end

	if animSide == "R" then
		animSide = "L"
		return animSide
	end
end

local function cleanShields(self, character, animationHeader)
	local shield = character:FindFirstChild("Shield")
	if not shield then
		return
	end

	animRelay:FireClient(self.Owner, animationHeader .. "Offhand", true)

	self._metaplayer:SetPrimary("NONE")

	shield:Destroy()
	self:OffDebounce("OffDebounceTime")
end

function Melee.new(player, tool, config, metaplayer)
	local self = setmetatable({}, Melee)

	self.Owner = player
	self.Class = config:GetAttribute("Class")
	self.Debouncing = false
	self.OffDebouncing = false

	self._config = config
	self._tool = tool
	self._meleeValid = true
	self._metaplayer = metaplayer
	self._trove = Trove.new()

	self:_init(player, tool)

	return self
end

function Melee:_init(player, tool)
	local rayParems = RaycastParams.new()
	rayParems.FilterDescendantsInstances = { player.Character }
	rayParems.FilterType = Enum.RaycastFilterType.Blacklist

	local caster = ClientCast.new(tool.Handle, rayParems)
	local id = 0

	repeat
		id += 1
	until meleehooks[player.Name .. tool.Name .. tostring(id)] == nil

	meleehooks[player.Name .. tool.Name .. tostring(id)] = self

	self._config:SetAttribute("HookID", id)
	self.Caster = caster
end

function Melee:CleanCast()
	if self._castConnection then
		self._castConnection:Disconnect()
		self._castConnection = nil
	end
end

function Melee:CleanOff()
	if self._offConnection then
		self._offConnection:Disconnect()
		self._offConnection = nil
	end
end

function Melee:Debounce(address)
	local debounceTime = self._config:GetAttribute(address)
	self.Debouncing = true

	task.delay(debounceTime, function()
		self.Debouncing = false
		self.quickDebounce = {}

		self:CleanCast()

		if self._metaplayer then
			self._metaplayer:SetPrimary("NONE")
		end
	end)
end

function Melee:OffDebounce(address)
	local debounceTime = self._config:GetAttribute(address)
	self.OffDebouncing = true
	self.Debouncing = false

	task.delay(debounceTime, function()
		self.OffDebouncing = false
		self.shieldDebounce = {}

		self:CleanOff()

		if self._metaplayer then
			self._metaplayer:SetPrimary("NONE")
		end
	end)
end

function Melee:Activate()
	self:Debounce("DebounceTime")
	self.Caster:Start()

	self.quickDebounce = {}
	self.shieldDebounce = {}

	if self._castConnection then
		self._castConnection:Disconnect()
		self._castConnection = nil
	end

	if self._offConnection then
		self._offConnection:Disconnect()
		self._offConnection = nil
	end

	local flippedDirection = flip(self._config:GetAttribute("SwingDirection"))
	local animationHeader = self._config:GetAttribute("AnimationHeader")
	local animationTail = "Hit"
	local address = animationHeader .. flippedDirection .. animationTail

	if not animations:FindFirstChild(address) then
		animationHeader = "Melee"
		address = animationHeader .. flippedDirection .. animationTail
	end

	self._metaplayer:SetPrimary("ATTACKING")

	self._castConnection = self.Caster.HumanoidCollided:Connect(function(ray, humanoid)
		if self.quickDebounce[humanoid] or not self._meleeValid then
			return
		end

		self.quickDebounce[humanoid] = true

		local shield = humanoid.Parent:FindFirstChild("Shield")

		if shield then
			local vectorDiff = humanoid.Parent.PrimaryPart.Position - self.Owner.Character.PrimaryPart.Position
			local direction = vectorDiff.Unit

			local angle = math.acos(humanoid.Parent.PrimaryPart.CFrame.LookVector:Dot(direction))

			if angle >= math.rad(90) then
				self:Shield(animationHeader, shield)
				return
			end
		end

		local playerEnemy = Players:GetPlayerFromCharacter(humanoid.Parent)

		if playerEnemy then
			animRelay:FireClient(playerEnemy, address, false)

			self._metaplayer:ImposePrimary("STUNLOCK", playerEnemy, 0.27)
		else
			local animLoaded = humanoid:LoadAnimation(animations[address])
			animLoaded:Play()
		end

		requestVisual:FireClient(self.Owner, "ScreenShake", {
			["Toggle"] = nil,
			["Magnitude"] = 1,
			["Roughness"] = 2,
			["FadeIn"] = 0.1,
			["FadeOut"] = 0.1,
			["PosInfluence"] = Vector3.new(0.15, 0.15, 0.15),
			["RotInfluence"] = Vector3.new(1, 1, 1),
		})

		DamageHandler:Damage(self.Owner, humanoid, self._tool, self._config, true, ray.Instance)

		self.Caster:Stop()
	end)

	self._offConnection = self.Caster.Collided:Connect(function(rayResult)
		if rayResult.Instance.Name == "Shield" or rayResult.Instance.Name == "Box" and self._meleeValid then
			self:Shield(animationHeader, rayResult.Instance)
		end
	end)

	self._config:SetAttribute("SwingDirection", flippedDirection)
end

function Melee:Shield(animationHeader, shield)
	self._meleeValid = false

	if not shield then
		return
	end
	if shield.Name == "Box" then
		shield = shield.Parent
	end

	if self.shieldDebounce[shield] then
		return
	end
	self.shieldDebounce[shield] = true

	local shieldHealth = shield:GetAttribute("Health")
	local knockPower = shield:GetAttribute("KnockPower")
	local knockDuration = shield:GetAttribute("KnockDuration")
	local platformDuration = shield:GetAttribute("PlatformDuration")

	local flippedDirection = flip(self._config:GetAttribute("SwingDirection"))
	local animHeaderOwner = self._config:GetAttribute("AnimationHeader")

	shieldHealth -= 1

	local character = self.Owner.Character
	local humanoidRP = character:FindFirstChild("HumanoidRootPart")

	if shieldHealth <= 0 then
		self._metaplayer:SetPrimary("STUN")

		local enemy = Players:GetPlayerFromCharacter(shield.Parent)

		if enemy then
			animRelay:FireClient(enemy, animationHeader .. "Offhand", true)
			self._metaplayer:ImposePrimary("NONE", enemy)

			local enemyWeapon = shield.Parent:FindFirstChildWhichIsA("Tool")

			if not enemyWeapon then
				return
			end
			local enemySelf = meleehooks[enemy.Name .. enemyWeapon.Name .. enemyWeapon.Config:GetAttribute("HookID")]

			if meleehooks[enemy.Name .. enemyWeapon.Name .. enemyWeapon.Config:GetAttribute("HookID")] then
				enemySelf:OffDebounce("OffDebounceTime")
			end
		end

		local box = shield.Box
		box.Parent = workspace
		box.Anchored = true

		for _, particle in box.ShieldBreak:GetChildren() do
			particle:Emit(3)
		end

		shield:Destroy()

		animRelay:FireClient(self.Owner, animHeaderOwner .. flippedDirection .. "Swing", true)
		animRelay:FireClient(self.Owner, "Stun")

		requestVisual:FireClient(self.Owner, "ScreenShake", {
			["Toggle"] = nil,
			["Magnitude"] = 3,
			["Roughness"] = 2,
			["FadeIn"] = 0.25,
			["FadeOut"] = 0.5,
			["PosInfluence"] = Vector3.new(0.15, 0.15, 0.15),
			["RotInfluence"] = Vector3.new(1, 1.5, 1),
		})

		local attachment = self._trove:Add(Instance.new("Attachment"))
		attachment.Parent = humanoidRP
		attachment.Name = "SHIELDATT"

		local knockback = self._trove:Add(Instance.new("LinearVelocity"))
		knockback.Attachment0 = attachment
		knockback.MaxForce = math.huge
		knockback.Parent = attachment
		knockback.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		knockback.VectorVelocity = humanoidRP.CFrame.LookVector * -knockPower

		task.delay(knockDuration, function()
			attachment:Destroy()

			task.wait(platformDuration)
			self._meleeValid = true
			animRelay:FireClient(self.Owner, "Stun", true)
			self._metaplayer:SetPrimary("NONE")
			box:Destroy()
		end)
	end
end

function Melee:Offhand(enable)
	self.Debouncing = enable

	local character = self.Owner.Character
	local humanoidRP = character:FindFirstChild("HumanoidRootPart")
	local animationHeader = self._config:GetAttribute("AnimationHeader")

	if enable then
		local pState = self._metaplayer.PrimaryState
		if
			self._metaplayer.MovementState == "RUNNING"
			or pState == "GRAB"
			or pState == "ATTACKING"
			or pState == "STUN"
			or pState == "SLOW"
		then
			return
		end

		local newShield = self._trove:Add(shieldAsset:Clone())
		newShield.Parent = character
		newShield.CFrame = (humanoidRP.CFrame * CFrame.new(0, 0, -2)) * CFrame.Angles(math.rad(90), 0, math.rad(180))

		local shieldWeld = self._trove:Add(Instance.new("WeldConstraint"))
		shieldWeld.Parent = newShield
		shieldWeld.Part0 = newShield
		shieldWeld.Part1 = humanoidRP

		self._metaplayer:SetPrimary("SLOW")

		animRelay:FireClient(self.Owner, animationHeader .. "Offhand")
	else
		local shield = character:FindFirstChild("Shield")
		if not shield then
			return
		end

		animRelay:FireClient(self.Owner, animationHeader .. "Offhand", true)

		self._metaplayer:SetPrimary("NONE")

		shield:Destroy()
		self:OffDebounce("OffDebounceTime")
	end
end

function Melee:Cleanup()
	local animationHeader = self._config:GetAttribute("AnimationHeader")
	local animationTail = self._config:GetAttribute("AnimationTail")

	animRelay:FireClient(self.Owner, animationHeader .. "Offhand", true)
	animRelay:FireClient(self.Owner, animationHeader .. "L" .. animationTail, true)
	animRelay:FireClient(self.Owner, animationHeader .. "R" .. animationTail, true)

	self:CleanCast()
	self:CleanOff()

	cleanShields(self, self.Owner.Character, animationHeader)
end

function Melee:Destroy()
	self._trove:Destroy()

	self:CleanCast()
	self:CleanOff()

	if self._metaplayer then
		self._metaplayer:SetPrimary("NONE")
	end
end

return Melee
