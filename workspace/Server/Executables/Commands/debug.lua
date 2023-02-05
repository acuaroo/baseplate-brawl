local debug = {}
local debugUi = game:GetService("ServerStorage").UI.Debug
local debugChannel = game:GetService("ReplicatedStorage").Events.Debug

function debug:Run(args, runner)
	local toggle = args[2]

	if not toggle then
		return
	end

	if toggle == "on" then
		debugUi:Clone().Parent = runner.PlayerGui
	elseif toggle == "off" then
		debugChannel:FireClient(runner, nil, nil, true)
		task.wait(0.75)

		if runner.PlayerGui:FindFirstChild("Debug") then
			runner.PlayerGui.Debug:Destroy()
		end
	end
end

return debug
