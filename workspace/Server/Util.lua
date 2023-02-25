-- [[ Util.lua ]] --

--[[
	@ Structure @
		Util {
			["Function"] = function(args, ...) 
				--<::>--
			end,
		}
]]
--
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

local assets = ServerStorage["Assets"]
local visuals = assets.Visuals
local critIndicator = visuals.CritInd
local hitIndicator = visuals.HitInd

local hitSpark = visuals.ParticleHolder.HitSpark
local hitCenter = visuals.ParticleHolder.HitCenter

local Util = {}

Util = {
	["IndicatorTween"] = function(indicator)
		local function cleanup()
			indicator:Destroy()
		end

		local function tween()
			indicator.Damage:TweenSize(
				UDim2.new(0, 0, 0, 0),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Quint,
				0.4,
				true,
				cleanup
			)
		end

		indicator.Damage:TweenSize(
			UDim2.new(1.1, 0, 1.35, 0),
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Quint,
			0.3,
			true,
			tween
		)
	end,
	["Indicate"] = function(hitLocus, damage, isCrit)
		local indicator = nil
		local newSpark = hitSpark:Clone()
		local newCenter = hitCenter:Clone()

		if isCrit then
			indicator = critIndicator:Clone()
		else
			indicator = hitIndicator:Clone()
		end

		indicator.Parent = hitLocus
		indicator.Adornee = hitLocus
		indicator.Damage.Text = "-" .. damage

		local offsetX = math.random(-10, 10) / 10
		local offsetY = math.random(-10, 10) / 10
		local offsetZ = math.random(-10, 10) / 10

		indicator.StudsOffset = Vector3.new(offsetX, offsetY, offsetZ)

		newSpark.Parent = hitLocus
		newCenter.Parent = hitLocus

		local part = math.ceil(damage / 10) + 3
		local particleAmount = math.clamp(part, 3, 10)

		newSpark:Emit(particleAmount)
		newCenter:Emit(1)

		task.spawn(Util["IndicatorTween"], indicator)

		Debris:AddItem(newSpark, 4)
		Debris:AddItem(newCenter, 4)
	end,
	["Damage"] = function(_, enemyHumanoid, config, hitLocus)
		local baseDamage = config:GetAttribute("BaseDamage")
		local critChance = config:GetAttribute("CritChance")
		local critMult = config:GetAttribute("CritMult")

		local damage = baseDamage
		local isCrit = false

		if critChance then
			if math.random(1, critChance.Y) <= critChance.X then
				damage *= critMult
				isCrit = not isCrit
			end
		end

		--DamageHandler:Tag(player, enemyHumanoid, tagLength)

		damage = math.floor(damage)
		enemyHumanoid:TakeDamage(damage)

		if hitLocus then
			return Util["Indicate"](hitLocus, damage, isCrit)
		else
			return damage, isCrit
		end
	end,
}

return Util
