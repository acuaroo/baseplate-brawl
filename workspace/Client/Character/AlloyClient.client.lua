for _, exe in pairs(script.Parent:WaitForChild("Executables"):GetChildren()) do
	if exe:IsA("ModuleScript") then
		require(exe):Run()
		print("[ALLOYC]: " .. exe.Name .. " was loaded")
	end
end
