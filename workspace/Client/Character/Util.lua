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

local VISUAL_OFFSET = CFrame.new(Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 50))
local ROTATIONAL_OFFSET = CFrame.Angles(math.rad(-45), 0, math.rad(45))
local BUILD_RATIO = 6.24531601299

local Util = {
	["ViewportModel"] = function(model, viewport)
		model:SetPrimaryPartCFrame(VISUAL_OFFSET)

		local toolSettings = model:FindFirstChild("Settings")

		if toolSettings:GetAttribute("VisualCFrame") then
			local customVisualCFrame = toolSettings:GetAttribute("VisualCFrame")
			model:SetPrimaryPartCFrame(customVisualCFrame)
		end

		model.Parent = viewport

		local viewportCamera = Instance.new("Camera")
		viewportCamera.Parent = viewport
		viewport.CurrentCamera = viewportCamera

		if toolSettings:GetAttribute("CameraCFrame") then
			local customCameraCFrame = toolSettings:GetAttribute("CameraCFrame")
			viewportCamera.CFrame = customCameraCFrame
		else
			viewportCamera.CFrame = CFrame.new(Vector3.new(0, 25.2, (model.PrimaryPart.Size.Z * BUILD_RATIO)))
				* ROTATIONAL_OFFSET
		end

		viewportCamera.DiagonalFieldOfView = 0.7
		viewportCamera.FieldOfView = toolSettings:GetAttribute("FOV")
	end,
}

return Util
