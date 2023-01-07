for _, exe in pairs(script.Parent.Executables:GetChildren()) do
	require(exe):Run()
	print("[ALLOYC] " .. exe.Name .. " was loaded")
end
