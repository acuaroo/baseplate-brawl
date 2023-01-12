local Tool = {}
Tool.__index = Tool

function Tool.new(player, tool, config)
	local self = setmetatable({}, Tool)

	self.Owner = player
	self.Class = config:GetAttribute("Class")
	self.Debouncing = false
	self._config = config
	self._tool = tool

	return self
end

function Tool:_init() end

function Tool:Activate()
	print("[TOOL] Tool activated")
end

function Tool:Destroy() end

return Tool
