--[[
	-- inherited from melee
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tool = require(script.Parent.Tool)
local Trove = require(ServerStorage["Modules"].Trove)
--local ClientCast = require(ServerStorage["Modules"].ClientCast)
local DamageHandler = require(ServerStorage["Modules"].DamageHandler)
local StatusHandler = require(ServerStorage["Modules"].StatusHandler)
--local RockHandler = require(ServerStorage["Modules"].RockHandler)

local combatAssets = ServerStorage["Assets"].Combat
local meteor = combatAssets.Meteor
local warning = combatAssets.Warning
local warningSizeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local requestVisual = ReplicatedStorage["Events"].RequestVisual

local BASEY = workspace:WaitForChild("baseplate").BASEY.Position.Y

--local animRelay = ReplicatedStorage["Events"].AnimRelay

local activate = {
	["summonMeteor"] = function(self, playerData)
		local mousePosition = playerData[1]
		local character = self.Owner.Character
		local humanoidRP = character:FindFirstChild("HumanoidRootPart")
		local range = self._config:GetAttribute("Range")
		local lifeTime = self._config:GetAttribute("LifeTime")

		self._metaplayer:SetPrimary("SLOW")

		if not humanoidRP or not mousePosition then
			return
		end
		if (mousePosition - humanoidRP.Position).Magnitude > range then
			return
		end

		self:Debounce("DebounceTime")

		local meteorClone = self._trove:Add(meteor:Clone())
		meteorClone.Parent = workspace
		meteorClone.CFrame = CFrame.new(mousePosition) + Vector3.new(0, 50, 0)

		local humanoidList = {}
		local warningList = {}

		local warningClone: BasePart = self._trove:Add(warning:Clone())
		warningClone.Parent = workspace
		warningClone.Position = Vector3.new(meteorClone.Position.X, BASEY, meteorClone.Position.Z)
		warningClone.Orientation = Vector3.new(0, 0, 90)

		local warningCloneSize = warningClone.Size
		warningClone.Size = Vector3.new(0.75, 1, 1)

		local warningValid = false

		local warningTween = TweenService:Create(warningClone, warningSizeTweenInfo, { Size = warningCloneSize })
		warningTween:Play()

		meteorClone.Anchored = false

		local meteorConnection
		local warningConnection

		local function applyDamage(obj)
			local humanoid = obj.Parent:FindFirstChildOfClass("Humanoid")

			if humanoid and not warningList[humanoid] and warningValid then
				warningList[humanoid] = true

				StatusHandler:ApplyStatus(humanoid, 8, "BrokenBone")
			end
		end

		warningConnection = warningClone.Touched:Connect(function(obj)
			applyDamage(obj)
		end)

		meteorConnection = meteorClone.Touched:Connect(function(obj)
			local humanoid = obj.Parent:FindFirstChildOfClass("Humanoid")

			if humanoid and not humanoidList[humanoid] then
				humanoidList[humanoid] = true

				DamageHandler:Damage(
					self.Owner,
					humanoid,
					self._tool,
					self._config,
					true,
					humanoid.Parent:FindFirstChild("HumanoidRootPart")
				)

				StatusHandler:ApplyStatus(humanoid, 8, "BrokenBone")
			end

			if obj.Name == "MAINY" or obj.Position.Y <= (BASEY + 5) then
				warningValid = true
				meteorClone.Anchored = true

				meteorClone.Position = Vector3.new(meteorClone.Position.X, BASEY, meteorClone.Position.Z)

				requestVisual:FireAllClients("MeteorImpact", {
					warningClone.Position,
					meteorClone.Position + Vector3.new(0, 0, 0),
					meteorClone.CFrame + Vector3.new(0, 0, 0),
				})

				for _, touch in warningClone:GetTouchingParts() do
					applyDamage(touch)
				end

				meteorConnection:Disconnect()
				meteorConnection = nil
			end
		end)

		task.delay(lifeTime / 2, function()
			self._metaplayer:SetPrimary("NONE")

			task.wait(lifeTime / 2)

			if meteorConnection then
				meteorConnection:Disconnect()
				meteorConnection = nil
			end

			if warningConnection then
				warningConnection:Disconnect()
				warningConnection = nil
			end

			meteorClone:Destroy()
			warningClone:Destroy()
		end)
	end,
}

--local offhand = {}

local ability = {
	["meteorShower"] = function() end,
}

local Custom = {}
Custom.__index = Custom

setmetatable(Custom, Tool)

function Custom.new(player, tool, config, metaplayer)
	local self = setmetatable({}, Custom)

	self.Owner = player
	self.Class = config:GetAttribute("Class")
	self.Debouncing = false
	self.OffDebouncing = false
	self.AbilityDebouncing = false

	self._config = config
	self._tool = tool
	self._metaplayer = metaplayer
	self._trove = Trove.new()

	return self
end

function Custom:Debounce(address)
	local debounceTime = self._config:GetAttribute(address)
	self.Debouncing = true

	task.delay(debounceTime, function()
		self.Debouncing = false
	end)
end

function Custom:OffDebounce(address)
	local debounceTime = self._config:GetAttribute(address)
	self.OffDebouncing = true

	task.delay(debounceTime, function()
		self.OffDebouncing = false
	end)
end

function Custom:AbilityDebounce(address)
	local debounceTime = self._config:GetAttribute(address)
	self.AbilityDebouncing = true

	task.delay(debounceTime, function()
		self.AbilityDebouncing = false
	end)
end

function Custom:Activate(playerData)
	local call = self._config:GetAttribute("ActivateClass")

	if activate[call] then
		activate[call](self, playerData)
	end
end

function Custom:Offhand(enable, playerData)
	local call = self._config:GetAttribute("SubClass")

	if ability[call] then
		ability[call](self, enable, playerData)
	end
end

function Custom:Ability(playerData)
	local call = self._config:GetAttribute("AbilityClass")

	if ability[call] then
		ability[call](self, playerData)
	end
end

function Custom:Cleanup()
	self._trove:Destroy()
end

function Custom:Destroy() end

return Custom
