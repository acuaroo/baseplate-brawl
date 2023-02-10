local systems = script.Parent.Systems:GetChildren()
--local bundles = script.Parent.Bundles:GetChildren()

local systemCache = {}

for _, system in pairs(systems) do
	local systemLoaded = require(system)
	systemLoaded:Start()

	systemCache[system.Name] = systemLoaded
end
