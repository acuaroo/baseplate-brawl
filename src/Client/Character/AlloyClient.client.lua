local Alloy = {}

function Alloy:Boot()
	for _, exe in pairs(script.Parent.Executables:GetChildren()) do
		require(exe):Run()
		print("[ALLOYc] "..exe.Name.." was loaded")
	end
	print("[--------------------------------]")
end

return Alloy