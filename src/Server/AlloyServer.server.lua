local Alloy = {}

for _, exe in pairs(script.Parent.Executables:GetChildren()) do
    require(exe):Run()
    print("[ALLOY] "..exe.Name.." was loaded")
end

return Alloy