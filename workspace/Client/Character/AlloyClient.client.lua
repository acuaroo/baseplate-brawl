for _, exe in pairs(script.Parent:WaitForChild("Executables"):GetChildren()) do
	require(exe):Run()
	print("[ALLOYC] " .. exe.Name .. " was loaded")
end
