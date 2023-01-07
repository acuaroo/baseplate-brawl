local ServerStorage = game:GetService("ServerStorage")

local particleHolder = ServerStorage["Assets"].Particles.ParticleHolder

local subEffects = {
	["normalEffect"] = function(humanoid, duration, name, power)
		local attribute = humanoid:GetAttribute(name)

		if attribute then
			humanoid:SetAttribute(name, attribute + power)
		else
			humanoid:SetAttribute(name, power)
		end

		task.delay(duration, function()
			if attribute then
				humanoid:SetAttribute(name, attribute)
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
		subEffects["normalEffect"](humanoid, duration, "DamageIntake", 0.1)
		subEffects["normalEffect"](humanoid, duration, "DamageOutput", -0.2)
		subEffects["normalEffect"](humanoid, duration, "Regeneration", -0.5)
		subEffects["normalEffect"](humanoid, duration, "Speed", -0.1)

		subEffects["particleEffect"](humanoid, duration, "Curse")
	end,
}

local StatusHandler = {}

function StatusHandler:ApplyStatus(humanoid, duration, name)
	if statusEffects[name] then
		statusEffects[name](humanoid, duration)
	else
		warn("[STATUS] Invalid statusEffect name")
	end
end

function StatusHandler:ApplySub(humanoid, duration, name, power)
	if subEffects[name] then
		subEffects[name](humanoid, duration, name, power)
	else
		warn("[STATUS] Invalid subEffect name")
	end
end

return StatusHandler
