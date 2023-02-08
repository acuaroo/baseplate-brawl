local UserInputService = game:GetService("UserInputService")

local keyboard = Enum.UserInputType.Keyboard
local mouse = Enum.UserInputType.MouseMovement
local mobile = Enum.UserInputType.Touch
local accel = Enum.UserInputType.Accelerometer
local gyro = Enum.UserInputType.Gyro

local Spool = {}

function Spool:GetPlayerDevice()
	--get the players device
	local mobileChance = 0
	local computerChance = 0
	local recentInput = UserInputService:GetLastInputType()

	if UserInputService.KeyboardEnabled then
		computerChance += 1
	end

	if UserInputService.TouchEnabled then
		mobileChance += 1
	end

	if recentInput == keyboard or recentInput == mouse then
		computerChance += 1
	end

	if recentInput == mobile then
		mobileChance += 1
	end

	if recentInput == gyro or recentInput == accel then
		mobileChance += 1
	end

	if computerChance > mobileChance then
		return "Computer"
	elseif mobileChance > computerChance then
		return "Mobile"
	end

	return "Computer"
end

return Spool
