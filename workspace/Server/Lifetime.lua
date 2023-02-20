-- [[ Lifetime.lua ]] --

--[[
	@ Structure @
		Lifetime = {
			["Category"] = {
				["Function"] = function(args, ...) 
					--<::>--
				end,
			},
		}
]]
--

local Lifetime = {
	["Equip"] = {
		["prep"] = function()
			print("prepping!")
		end,
	},
	["Activate"] = {},
	["Offhand"] = {},
	["Ability"] = {},
	["Unequip"] = {
		["uneq"] = function()
			print("unequipping!")
		end,
	},
}

return Lifetime
