local Alloy = {}

function Alloy:Boot()
	for _, exe in pairs(script.Executables:GetChildren()) do
		require(exe):Run()
		print("[ALLOY] "..exe.Name.." was loaded")
	end
	print("[--------------------------------]")
end

return Alloy