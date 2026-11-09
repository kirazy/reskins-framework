---@namespace Reskins.Framework

local V = require("__reskins-sprite-utils__.validation")
local Common = require("__reskins-sprite-utils__.validation.common")
local FrameworkCommon = require("__reskins-framework__.api.validation")

---@class SettingsUtils
local _settings_utils = {}

local check_set_default_tier_color = V.signature("set_default_tier_color", {
	{ "tier", FrameworkCommon.tier },
	{ "color", Common.color },
})

---Forces the specified `tier` to use the specified `color` in the default color mode. This does not change the colors
---used when a user enables custom colors.
---
---Modifies the default value for the both the hidden `reskins-framework-default-colors-tier-#` settings, as well as for
---the `reskins-framework-custom-colors-tier-#` settings.
---@param tier Tier
---@param color data.Color
---@throws When `tier` is not an integer between 0 and 6.
---@throws When `color` is not a `Color`.
function _settings_utils.set_default_tier_color(tier, color)
	check_set_default_tier_color(tier, color)

	data.raw["color-setting"]["reskins-framework-custom-colors-tier-" .. tier].default_value = color
	---@diagnostic disable-next-line: inject-field
	data.raw["color-setting"]["reskins-framework-default-colors-tier-" .. tier].forced_value = color
end

return _settings_utils
