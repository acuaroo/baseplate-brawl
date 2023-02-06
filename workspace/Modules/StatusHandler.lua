local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--local WalkSpeedHandler = require(ServerStorage["Modules"].WalkSpeedHandler)

local notificationChannel = ReplicatedStorage["Events"].Notification
local particleHolder = ServerStorage["Assets"].Particles.ParticleHolder

local effectDescriptions = {
	["Regeneration"] = {
		["Name"] = "regeneration",
		["Effect"] = 0,
		["Duration"] = 0,
		["Image"] = "rbxassetid://11684788740",
	},
	["Speed"] = {
		["Name"] = "speed",
		["Effect"] = 0,
		["Duration"] = 0,
		["Image"] = "rbxassetid://11684108736",
	},
	["DamageIntake"] = {
		["Name"] = "damage intake",
		["Effect"] = 0,
		["Duration"] = 0,
		["Image"] = "http://www.roblox.com/asset/?id=11884485716",
	},
	["DamageOutput"] = {
		["Name"] = "damage output",
		["Effect"] = 0,
		["Duration"] = 0,
		["Image"] = "http://www.roblox.com/asset/?id=11884552728",
	},
}

local function fetchEffect(name, duration, val)
	local effect = effectDescriptions[name]

	if not effect then
		return
	end

	effect = table.clone(effect)
	effect["Duration"] = duration
	effect["Effect"] = val

	return effect
end

local subEffects = {
	["normalEffect"] = function(humanoid, duration, name, power)
		local attribute = humanoid:GetAttribute(name)

		if attribute then
			humanoid:SetAttribute(name, attribute + power)
		else
			humanoid:SetAttribute(name, power)
		end

		task.delay(duration, function()
			attribute = humanoid:GetAttribute(name)

			if attribute then
				--(humanoid.WalkSpeed * humanoid:GetAttribute("Speed")
				humanoid:SetAttribute(name, attribute - power)
			else
				humanoid:SetAttribute(name, nil)
			end
		end)
	end,
	["particleEffect"] = function(humanoid, duration, particle)
		local part = particleHolder:FindFirstChild(particle)
		local humanoidRP = humanoid.Parent:FindFirstChild("HumanoidRootPart")

		if not humanoidRP then
			return
		end
		if not part then
			return
		end

		part = part:Clone()
		part.Parent = humanoidRP

		task.delay(duration, function()
			part:Destroy()
		end)
	end,
}

local statusEffects = {
	["Curse"] = function(humanoid, duration)
		subEffects["normalEffect"](humanoid, duration, "DamageIntake", 0.25)
		subEffects["normalEffect"](humanoid, duration, "DamageOutput", -0.2)
		subEffects["normalEffect"](humanoid, duration, "Regeneration", -0.5)
		subEffects["normalEffect"](humanoid, duration, "Speed", -0.1)

		subEffects["particleEffect"](humanoid, duration, "Curse")

		local player = Players:GetPlayerFromCharacter(humanoid.Parent)

		if player then
			notificationChannel:FireClient(
				player,
				{
					"cursed!",
					"you've been cursed, you feel weaker and more vulnerable",
					"rbxassetid://10590477428",
					4,
				},
				true,
				{
					fetchEffect("DamageIntake", duration, 0.1),
					fetchEffect("DamageOutput", duration, -0.2),
					fetchEffect("Regeneration", duration, -0.5),
					fetchEffect("Speed", duration, -0.1),
				}
			)
		end
	end,
	["BrokenBone"] = function(humanoid, duration)
		subEffects["normalEffect"](humanoid, duration, "Regeneration", -0.5)
		subEffects["normalEffect"](humanoid, duration, "Speed", -0.3)

		local player = Players:GetPlayerFromCharacter(humanoid.Parent)

		if player then
			notificationChannel:FireClient(
				player,
				{
					"ouch!",
					"you've broken a bone, you feel slower and more vulnerable",
					"rbxassetid://10590477428",
					4,
				},
				true,
				{
					fetchEffect("Regeneration", duration, -0.5),
					fetchEffect("Speed", duration, -0.3),
				}
			)
		end
	end,
}

local StatusHandler = {}

function StatusHandler:ApplyStatus(humanoid, duration, name)
	if statusEffects[name] then
		statusEffects[name](humanoid, duration)
	else
		warn("[STATUS]: Invalid statusEffect name")
	end
end

function StatusHandler:ApplySub(humanoid, duration, name, power)
	if subEffects[name] then
		subEffects[name](humanoid, duration, name, power)
	else
		warn("[STATUS]: Invalid subEffect name")
	end
end

return StatusHandler
