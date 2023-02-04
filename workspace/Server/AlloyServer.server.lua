for _, exe in pairs(script.Parent.Executables:GetChildren()) do
	if exe:IsA("ModuleScript") then
		require(exe):Run()
		print("[ALLOY]: " .. exe.Name .. " was loaded")
	end
end
