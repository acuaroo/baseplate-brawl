--[[
	-- inherited from melee
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Melee = require(script.Parent.Melee)
local Trove = require(ServerStorage["Modules"].Trove)
local ClientCast = require(ServerStorage["Modules"].ClientCast)
local DamageHandler = require(ServerStorage["Modules"].DamageHandler)
local FastCast = require(ServerStorage["Modules"].FastCastRedux)
local StatusHandler = require(ServerStorage["Modules"].StatusHandler)

local animRelay = ReplicatedStorage["Events"].AnimRelay

local Func = {}
Func.__index = Func

setmetatable(Func, Melee)

local init = {
	["throwSpear"] = function(self)
		local degravity = Vector3.new(0, -workspace.Gravity / 3, 0)

		self.ThrowCaster = FastCast.new()

		self.ThrowCastParams = RaycastParams.new()
		self.ThrowCastParams.FilterType = Enum.RaycastFilterType.Blacklist
		self.ThrowCastParams.FilterDescendantsInstances = { self.Owner.Character, workspace.ProjectileFolder }
		self.ThrowCastParams.IgnoreWater = true

		self.ThrowCastBehavior = FastCast.newBehavior()
		self.ThrowCastBehavior.RaycastParams = self.ThrowCastParams
		self.ThrowCastBehavior.AutoIgnoreContainer = false
		self.ThrowCastBehavior.Acceleration = degravity
		self.ThrowCastBehavior.CosmeticBulletContainer = workspace.ProjectileFolder
		self.ThrowCastBehavior.CosmeticBulletTemplate = ServerStorage["Assets"].Combat.Spear
	end,
}

local functionality = {
	["throwSpear"] = function(enable, self)
		if not enable then
			local humanoidRP = self.Owner.Character:FindFirstChild("HumanoidRootPart")

			if not humanoidRP then
				return
			end
			self._metaplayer:SetPrimary("NOMOVE")

			local config = self._config

			local function cleanup(rayConnection, lenConnection, spear)
				if rayConnection then
					rayConnection:Disconnect()
					rayConnection = nil
				end

				if lenConnection then
					lenConnection:Disconnect()
					lenConnection = nil
				end

				if spear then
					task.delay(config:GetAttribute("SpearReturnTime"), function()
						spear:Destroy()
					end)
				end
			end

			local lenConnection
			local rayConnection

			local origin = self._tool.Handle.Position
			local direction = humanoidRP.CFrame.LookVector
			local throwDebounce = {}
			local animationDelay = config:GetAttribute("AnimationDelay")
			local animationHeader = config:GetAttribute("AnimationHeader")
			local cleaned = false

			self:OffDebounce("OffDebounce")

			--animRelay:FireClient(self.Owner, animationHeader.."Idle", true)
			animRelay:FireClient(self.Owner, animationHeader .. "Throw", nil, nil, animationHeader .. "Idle")

			task.wait(animationDelay)
			self._metaplayer:SetPrimary("NONE")

			self.ThrowCaster:Fire(origin, direction, config:GetAttribute("ThrowPower"), self.ThrowCastBehavior)

			lenConnection = self.ThrowCaster.LengthChanged:Connect(function(_, lastPoint, dir, length, _, spear)
				if spear then
					local spearLength = spear.Size.Z / 2
					local offset = CFrame.new(0, 0, -(length - spearLength * 2))

					spear.CFrame = (CFrame.lookAt(lastPoint, lastPoint + dir):ToWorldSpace(offset))
						* CFrame.Angles(math.rad(90), 0, math.rad(180))
				end
			end)

			rayConnection = self.ThrowCaster.RayHit:Connect(function(_, result, _, spear)
				local hit = result.Instance
				local echaracter = hit.Parent

				if not echaracter:FindFirstChild("Humanoid") then
					pcall(function()
						echaracter = echaracter.Parent
					end)
				end

				if echaracter and echaracter:FindFirstChild("Humanoid") then
					if throwDebounce[echaracter] then
						return
					end
					throwDebounce[echaracter] = true
					spear.Anchored = true

					StatusHandler:ApplyStatus(echaracter.Humanoid, 8, "Curse")
					DamageHandler:Damage(
						self.Owner,
						echaracter.Humanoid,
						self._tool,
						self._config,
						true,
						result.Instance
					)
				end

				cleaned = true
				cleanup(rayConnection, lenConnection, spear)
			end)

			task.delay(config:GetAttribute("SpearReturnTime"), function()
				if not cleaned then
					cleanup(rayConnection, lenConnection)
				end

				self._metaplayer:SetPrimary("NONE")
			end)
		else
			local config = self._config
			local animationHeader = config:GetAttribute("AnimationHeader")

			self._metaplayer:SetPrimary("SLOW")

			animRelay:FireClient(self.Owner, animationHeader .. "Idle")
		end
	end,
}

function Func.new(player, tool, config, metaplayer)
	local self = setmetatable({}, Func)

	self.Owner = player
	self.Class = config:GetAttribute("Class")
	self.SubClass = config:GetAttribute("SubClass")
	self.OffDebouncing = false

	self._config = config
	self._tool = tool
	self._meleeValid = true
	self._metaplayer = metaplayer
	self._trove = Trove.new()

	self:_init(player, tool)

	return self
end

function Func:_init(player, tool)
	local rayParems = RaycastParams.new()
	rayParems.FilterDescendantsInstances = { player.Character }
	rayParems.FilterType = Enum.RaycastFilterType.Blacklist

	if init[self.SubClass] then
		init[self.SubClass](self)
	end

	local caster = ClientCast.new(tool.Handle, rayParems)
	self.Caster = caster
end

function Func:OffDebounce(address)
	local debounceTime = self._config:GetAttribute(address)
	self.OffDebouncing = true

	task.delay(debounceTime, function()
		self.OffDebouncing = false
	end)
end

function Func:Offhand(enable)
	if self._metaplayer.PrimaryState == "ATTACKING" then
		return
	end

	local subClass = self.SubClass

	if functionality[subClass] and not self.OffDebouncing then
		functionality[subClass](enable, self)
		self._metaplayer:SetPrimary("FUNCTIONAL")
	end
end

function Func:Cleanup()
	local animationHeader = self._config:GetAttribute("AnimationHeader")
	local animationTail = self._config:GetAttribute("AnimationTail")
	local offAnimationTail = self._config:GetAttribute("OffAnimationTail")

	animRelay:FireClient(self.Owner, animationHeader .. offAnimationTail, true)
	animRelay:FireClient(self.Owner, animationHeader .. "Idle", true)
	animRelay:FireClient(self.Owner, "Melee" .. "Offhand", true)

	animRelay:FireClient(self.Owner, animationHeader .. "L" .. animationTail, true)
	animRelay:FireClient(self.Owner, animationHeader .. "R" .. animationTail, true)
end

function Func:Destroy()
	self._trove:Destroy()
end

return Func
