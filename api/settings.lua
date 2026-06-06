--- Provides methods for retrieving and validating startup settings.
---
---### Examples
---```lua
---local _settings = require("__reskins-framework__.api.settings")
---```
---@class Reskins.Api.Settings
local _settings = {}

---
---Gets the value of the startup setting with the given `name`.
---
---### Returns
---@return boolean|string|Color|double|int|nil # The value of the startup setting, if it exists; otherwise, `nil`.
---
---### Examples
---```lua
----- Check if the user has enabled custom furnace variants.
------@type boolean
---local value = _settings.get_value("reskins-bobs-do-custom-furnace-variants")
---
----- Get the color of the standard furnace variant.
------@type data.Color
---local color = _settings.get_value("reskins-bobs-standard-furnace-color")
---```
---
---### Parameters
---@param name string # The name of a startup setting.
function _settings.get_value(name)
	local value = nil
	if settings.startup[name] then
		value = settings.startup[name].value
	end

	return value
end

return _settings
