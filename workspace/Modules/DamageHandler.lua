local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local combatAssets = ServerStorage["Assets"].Combat
local critIndicator = combatAssets.CritInd
local hitIndicator = combatAssets.HitInd

local hitSpark = combatAssets.ParticleHolder.HitSpark
local hitCenter = combatAssets.ParticleHolder.HitCenter

local DamageHandler = {}

local function indicatorTween(indicator)
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
end

function DamageHandler:Tag(player, enemyHumanoid, tagLength)
	local enemyPlayer = Players:GetPlayerFromCharacter(enemyHumanoid.Parent)

	if not enemyPlayer then
		return
	end

	local existingTag = enemyPlayer:FindFirstChildOfClass("ObjectValue")
	local combatTag

	if existingTag then
		combatTag = existingTag
	else
		combatTag = Instance.new("ObjectValue")
	end

	combatTag.Name = tostring(os.time())
	combatTag.Value = player
	combatTag.Parent = enemyPlayer

	task.spawn(function()
		task.wait(tagLength)

		if combatTag and combatTag.Value == player then
			combatTag:Destroy()
		end
	end)
end

function DamageHandler:FindTag(player)
	local existingTag = player:FindFirstChildOfClass("ObjectValue")

	if existingTag then
		return existingTag.Value
	end

	return nil
end

function DamageHandler:Indicate(hitLocus, damage, isCrit)
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

	task.spawn(indicatorTween, indicator)

	Debris:AddItem(newSpark, 4)
	Debris:AddItem(newCenter, 4)
end

function DamageHandler:Damage(player, enemyHumanoid, _, config, indicate, hitLocus)
	local tagLength = config:GetAttribute("TagLength") or 30
	local baseDamage = config:GetAttribute("BaseDamage")
	local critChance = config:GetAttribute("CritChance")
	local critMult = config:GetAttribute("CritMult")
	local playerHumanoid = player.Character:FindFirstChild("Humanoid")

	local damage = baseDamage
	local isCrit = false

	if critChance then
		if math.random(1, critChance.Y) <= critChance.X then
			damage *= critMult
			isCrit = not isCrit
		end
	end

	local damageIntakeModifier = enemyHumanoid:GetAttribute("DamageIntake")

	if enemyHumanoid:GetAttribute("DamageIntake") then
		damage += (damage * damageIntakeModifier)
	end

	if playerHumanoid then
		local damageOutputModifier = playerHumanoid:GetAttribute("DamageOutput")

		if damageOutputModifier then
			damage += (damage * damageOutputModifier)
		end
	end

	DamageHandler:Tag(player, enemyHumanoid, tagLength)

	damage = math.floor(damage)
	enemyHumanoid:TakeDamage(damage)

	if indicate then
		return DamageHandler:Indicate(hitLocus, damage, isCrit)
	else
		return damage, isCrit
	end
end

return DamageHandler
