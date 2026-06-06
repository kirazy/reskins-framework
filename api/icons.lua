-- Copyright (c) 2024 Kirazy
-- Part of Artisanal Reskins: Library
--
-- See LICENSE.md in the project directory for license information.

if ... ~= "__reskins-framework__.api.icons" then
	return require("__reskins-framework__.api.icons")
end

--- Provides methods for manipulating icons.
---
---### Examples
---```lua
---local _icons = require("__reskins-framework__.api.icons")
---```
---@class Reskins.Api.Icons
local _icons = {}

---
---Checks if the given `icon_datum` is using images from Artisanal Reskins.
---
---### Returns
---@return boolean # `true` if the icon is using images from Artisanal Reskins.
---
---### Parameters
---@param icon_datum data.IconData # An `IconData` object.
local function is_icon_using_reskins_images(icon_datum)
	return icon_datum and icon_datum.icon:find("__reskins%-") ~= nil
end

---
---Checks if the given `icon_data` is using images from Artisanal Reskins.
---
---### Returns
---@return boolean # `true` if any of the icons in `icon_data` are using images from Artisanal Reskins.
---
---### Parameters
---@param icon_data data.IconData[] # An icon represented by an array of `IconData` objects.
function _icons.is_icons_using_reskins_images(icon_data)
	if icon_data then
		for i = #icon_data, 1, -1 do
			if is_icon_using_reskins_images(icon_data[i]) then
				return true
			end
		end
	end

	return false
end

return _icons
