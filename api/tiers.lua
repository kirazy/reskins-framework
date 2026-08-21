---@using data
---@using Reskins.SpriteUtils

---@namespace Reskins.Framework

local sprite_utils = {
	icons = require("__reskins-sprite-utils__.icons"),
	sprites = require("__reskins-sprite-utils__.sprites"),
}
local _settings = require("__reskins-framework__.api.settings")

---@alias Tier 0|1|2|3|4|5|6

--- Provides methods for working with tier labels and tints.
---
---### Examples
---```lua
---local _tiers = require("__reskins-framework__.api.tiers")
---```
---@class Tiers
local _tiers = {}

---
---Indicates whether tier labels should be added to icons or not.
---
---### Value
---`true` if tier labels should be added to icons; otherwise, `false`.
---@type boolean
_tiers.show_labels = _settings.get_value("reskins-framework-show-tier-labels") == true

---
---Indicates whether tier labels should be added to pipe-type entity icons or not.
---
---### Value
---`true` if tier labels should be added to pipe-type entity icons; otherwise, `false`.
---@type boolean
_tiers.show_labels_on_pipes = _settings.get_value("reskins-framework-show-tier-labels-on-pipes") == true

---@alias TierLabelStyle
---| "chevron" Chevrons.
---| "dots" Dots.
---| "half-circle" The upper-half of a circle.
---| "rectangle" A rectangle.
---| "rounded-half-circle" The upper-half of a circle, with rounded corners on the bottom.
---| "rounded-rectangle" A rectangle with rounded corners.
---| "teardrop" A teardrop.

---
---Gets the current style of tier labels to use.
---
---### Value
---The current style of tier labels to use.
---@type TierLabelStyle
_tiers.tier_label_style = _settings.get_value("reskins-framework-tier-label-style")

---
---Defines values for a given prototype's tier for either traditional or progression tier mapping.
---@class PrototypeTierValue
---@field tier integer # The traditional tier of the prototype.
---@field prog_tier integer? # The progression tier of the prototype.

local is_using_custom_tier_colors = _settings.get_value("reskins-framework-use-custom-tier-colors") == true

---@type table<Tier, Color>
local custom_tier_colors = {
	[0] = _settings.get_value("reskins-framework-custom-colors-tier-0") --[[@as Color]],
	[1] = _settings.get_value("reskins-framework-custom-colors-tier-1") --[[@as Color]],
	[2] = _settings.get_value("reskins-framework-custom-colors-tier-2") --[[@as Color]],
	[3] = _settings.get_value("reskins-framework-custom-colors-tier-3") --[[@as Color]],
	[4] = _settings.get_value("reskins-framework-custom-colors-tier-4") --[[@as Color]],
	[5] = _settings.get_value("reskins-framework-custom-colors-tier-5") --[[@as Color]],
	[6] = _settings.get_value("reskins-framework-custom-colors-tier-6") --[[@as Color]],
}

---@type table<Tier, Color>
local default_tier_colors = {
	[0] = _settings.get_value("reskins-framework-default-colors-tier-0") --[[@as Color]],
	[1] = _settings.get_value("reskins-framework-default-colors-tier-1") --[[@as Color]],
	[2] = _settings.get_value("reskins-framework-default-colors-tier-2") --[[@as Color]],
	[3] = _settings.get_value("reskins-framework-default-colors-tier-3") --[[@as Color]],
	[4] = _settings.get_value("reskins-framework-default-colors-tier-4") --[[@as Color]],
	[5] = _settings.get_value("reskins-framework-default-colors-tier-5") --[[@as Color]],
	[6] = _settings.get_value("reskins-framework-default-colors-tier-6") --[[@as Color]],
}

---
---Gets the color for the given `tier`.
---
---### Returns
---@return Color # The color for the given `tier`.
---
---### Parameters
---@param tier Tier # The tier to get a color for; must be between 0 and 6.
---
---### Exceptions
---*@throws* `string` — Thrown when `tier` is not an integer between 0 and 6.
function _tiers.get_tint(tier)
	assert(
		tier and tier >= 0 and tier <= 6 and tier % 1 == 0,
		"Invalid parameter: 'tier' must be an integer between 0 and 6."
	)

	if is_using_custom_tier_colors then
		return util.copy(custom_tier_colors[tier])
	else
		return util.copy(default_tier_colors[tier])
	end
end

---Gets the tier for the given `tier` and `prog_tier`.
---@param tier Tier # The tier to get a color for; must be between 0 and 6.
---@param prog_tier? Tier # The progression tier to get a color for; must be between 0 and 6.
---@return Tier # The tier appropriate for the current settings.
local function select_tier_for_current_mapping(tier, prog_tier)
	assert(
		tier and tier >= 0 and tier <= 6 and tier % 1 == 0,
		"Invalid parameter: 'tier' must be an integer between 0 and 6."
	)
	assert(
		not prog_tier or (prog_tier and prog_tier >= 0 and prog_tier <= 6 and prog_tier % 1 == 0),
		"Invalid parameter: 'prog_tier' must be an integer between 0 and 6."
	)

	if _settings.get_value("reskins-framework-tier-mapping") == "progression-map" then
		return prog_tier or tier
	end

	return tier
end

---Gets the tier from the given `tier_value` appropriate for the current settings.
---@param tier_value PrototypeTierValue
---@return integer # The tier appropriate for the current settings.
local function get_tier_from_value(tier_value)
	assert(tier_value.tier, "Invalid parameter: 'tier' field is a required field on PrototypeTierValue.")

	return select_tier_for_current_mapping(tier_value.tier, tier_value.prog_tier)
end

---
---Gets the tier appropriate for the current settings, for the provided `tier` and `prog_tier`.
---
---### Parameters
---@param tier Tier|PrototypeTierValue # The tier to get a color for; must be between 0 and 6, or a `PrototypeTierValue` object.
---@param prog_tier? Tier # The progression tier to get a color for; must be between 0 and 6. Ignored if `tier` is a `PrototypeTierValue`.
---
---### Returns
---@return Tier # The tier appropriate for the current settings.
---
---### Exceptions
---*@throws* `string` — Thrown when `tier` is a `PrototypeTierValue` object and does not have a `tier` field.\
---*@throws* `string` — Thrown when either of `tier` or `prog_tier` is not an integer between 0 and 6.
---@nodiscard
function _tiers.get_tier(tier, prog_tier)
	if type(tier) == "table" then
		return get_tier_from_value(tier)
	else
		return select_tier_for_current_mapping(tier, prog_tier)
	end
end


---@param icon_datum IconData
---@return boolean
---@nodiscard
local function is_tier_label_icon(icon_datum)
	return icon_datum and icon_datum.icon:find("__reskins%-framework__%/graphics%/icons%/tiers%/") ~= nil
end

---
---Indicates if the given `icon_data` is tier labeled.
---
---### Parameters
---@param icon_data IconData[] # An array of `IconData` objects.
---
---### Returns
---@return boolean # `true` if `icons` is tier labeled; otherwise `false`.
---
---### Examples
---```lua
----- Check if the assembling machine 3 icon is tier labeled, and perform a task if so.
---local icon_data = data.raw["assembling-machine"]["assembling-machine-3"].icons
---
---if _tiers.is_icons_tier_labeled(icon_data) then
---    -- Do something.
---end
---```
---@nodiscard
function _tiers.is_icons_tier_labeled(icon_data)
	-- A labeled icon will have minimum three layers.
	if icon_data and #icon_data >= 3 then
		for i = #icon_data, 1, -1 do
			if is_tier_label_icon(icon_data[i]) then
				return true
			end
		end
	end

	return false
end

---
---Gets the tier from the given `icon_data`, if it is tier labeled.
---
---`icon_data` is not modified.
---
---### Parameters
---@param icon_data IconData[] # An array of `IconData` objects.
---
---### Returns
---@return Tier|nil # The tier of the tier label, or `nil` if `icon_data` is not tier labeled.
---
---### Examples
---```lua
----- Get the current tier of the assembling-machine-3.
---local icon_data = data.raw["assembling-machine"]["assembling-machine-3"].icons
---
---if _tiers.get_tier_from_icons(icon_data) > 3 then
---    -- Progression tiering maybe?
---    -- Do something!
---end
---```
---@nodiscard
function _tiers.get_tier_from_icons(icon_data)
	if icon_data and #icon_data >= 3 then
		for i = #icon_data, 1, -1 do
			if is_tier_label_icon(icon_data[i]) then
				return tonumber(icon_data[i].icon:match("(%d+)%.png")) --[[@as Tier]]
			end
		end
	end

	return nil
end

---
---Removes any tier labels from a copy of the given `icon_data`.
---
---### Parameters
---@param icon_data IconData[] # An array of `IconData` objects.
---
---### Returns
---@return IconData[] icon_data A copy of `icon_data` without any tier labels.
---@return IconData[] tier_labels A copy of the removed tier labels.
---
---### Examples
---```lua
----- Remove the tier labels from the assembling-machine-3.
---local icon_data = data.raw["assembling-machine"]["assembling-machine-3"].icons
---local icon_without_tier_labels = _tiers.remove_tier_labels_from_icons(icon_data)
---
----- Remove the tier labels from the assembling-machine-3 and keep a copy of the removed tier labels.
---local icon_without_tier_labels, removed_tier_labels = _tiers.remove_tier_labels_from_icons(icon_data)
---```
---@nodiscard
function _tiers.remove_tier_labels_from_icons(icon_data)
	assert(icon_data, "Invalid parameter: 'icon_data' must not be nil.")

	local icon_data_copy = util.copy(icon_data)

	---@type IconData[]
	local removed_layers = {}

	if #icon_data >= 2 then
		for i = #icon_data_copy, 1, -1 do
			if is_tier_label_icon(icon_data_copy[i]) then
				table.insert(removed_layers, 1, table.remove(icon_data_copy, i))
			end
		end
	end

	return icon_data_copy, removed_layers
end

---
---Adds tier labels representing the given `tier` to a copy of the given `icon_data`.
---
---### Remarks
---- If tier labeling is disabled, an unmodified copy of `icon_data` is returned.
---- Missing icon fields are set to default values as appropriate.
---- `icon_data` is assumed to be an entity, item, fluid, or recipe icon. Technology icons are not supported.
---- `icon_data` is not modified.
---
---### Parameters
---@param tier integer # The tier of the added labels. An integer value from 0 to 6.
---@param icon_data IconData[] # An icon represented by an array of `IconData` objects to add tier labels to.
---
---### Returns
---@return IconData[] # An array of `IconData` objects representing a copy of `icon_data` with added tier labels.
---
---### Examples
---```lua
------@type IconData[]
---local icon_data = {
---    {
---        icon = "__base__/graphics/icons/iron-plate.png",
---        icon_size = 64,
---        scale = 0.5,
---    },
---    {
---        icon = "__base__/graphics/icons/copper-wire.png",
---        icon_size = 64,
---        scale = 0.25,
---        shift = { -16, -16 }
---    },
---}
---
---local labeled_icon = _tiers.add_tier_labels_to_icons(1, icon_data)
---```
---
---### Exceptions
---*@throws* `string` — Thrown when `tier` is not an integer between 0 and 6.\
---*@throws* `string` — Thrown when `icon_data` is `nil`.\
---*@throws* `string` — Thrown when `icon_data[n].icon` is not an absolute file path with a valid extension.\
---*@throws* `string` — Thrown when `icon_data[n].icon_size` is not a positive integer.
---@nodiscard
function _tiers.add_tier_labels_to_icons(tier, icon_data)
	assert(
		tier and tier >= 0 and tier <= 6 and tier % 1 == 0,
		"Invalid parameter: 'tier' must be an integer between 0 and 6."
	)
	assert(icon_data, "Invalid parameter: 'icon_data' must not be nil.")

	if not _tiers.show_labels then
		return util.copy(icon_data)
	end

	local icon_data_copy = sprite_utils.icons.add_missing_icons_defaults(icon_data, "standard")

	-- There is not a 0th tier pip.
	if tier > 0 then
		local labeling_style = _tiers.tier_label_style
		local icon_file_name = "__reskins-framework__/graphics/icons/tiers/" .. labeling_style .. "/" .. tier .. ".png"

		icon_data_copy = sprite_utils.icons.compose_icons("standard", icon_data, {
			icon = icon_file_name,
			icon_size = 64,
		}, {
			icon = icon_file_name,
			icon_size = 64,
			---@diagnostic disable-next-line: param-type-mismatch
			tint = util.get_color_with_alpha(_tiers.get_tint(tier), 0.75),
		})
	end

	return icon_data_copy
end

---
---Adds tier labels representing the given `tier` to a copy of the given `icon_datum`.
---
---### Remarks
---- If tier labeling is disabled, an unmodified copy of `icon_datum` is returned, packaged as an
---  array of `IconData` objects with one element.
---- Missing icon fields are set to default values as appropriate.
---- `icon_datum` is assumed to be an entity, item, fluid, or recipe icon. Technology icons are not supported.<br>
---- `icon_datum` is not modified.
---
---### Parameters
---@param tier integer # The tier of the added labels.
---@param icon_datum IconData # An icon represented by an `IconData` object to add tier labels to.
---
---### Returns
---@return IconData[] # An array of `IconData` objects representing a copy of `icon_datum` with added tier labels.
---
---### Examples
---```lua
------@type IconData
---local icon_datum = {
---    icon = "__base__/graphics/icons/assembling-machine-1.png",
---    icon_size = 64,
---    scale = 0.5,
---}
---
---local labeled_icon = _tiers.add_tier_labels_to_icon(1, icon_datum)
---```
---
---### Exceptions
---*@throws* `string` — Thrown when `tier` is not an integer between 0 and 6.\
---*@throws* `string` — Thrown when `icon_datum` is `nil`.\
---*@throws* `string` — Thrown when `icon_datum.icon` is not an absolute file path with a valid extension.\
---*@throws* `string` — Thrown when `icon_datum.icon_size` is not a positive integer.
---@nodiscard
function _tiers.add_tier_labels_to_icon(tier, icon_datum)
	return _tiers.add_tier_labels_to_icons(tier, { icon_datum })
end

---
---Adds tier labels representing the given `tier` to an icon created from the given parameters.
---
---### Remarks
---- The parameters are assumed to be for an entity, item, fluid, or recipe icon. Technology icons are not supported.
---- Missing icon fields are set to default values as appropriate.
---
---### Parameters
---@param tier integer # The tier of the added labels.
---@param icon FileName # The file name of the icon to use.
---@param icon_size SpriteSizeType # The size of the icon.
---@param scale? double # The scale of the icon. Default `32 / icon_size`.
---@param shift? Vector # The shift of the icon. Default `nil`.
---@param tint? Color # The tint of the icon. Default `nil`.
---
---### Returns
---@return IconData[] # An array of `IconData` objects representing the created icon with added tier labels.
---
---### Examples
---```
---local labeled_icon = _tiers.create_icon_with_tier_labels(1, "__base__/graphics/icons/assembling-machine-1.png", 64, 4, 0.5)
---```
---
---### Exceptions
---*@throws* `string` — Thrown when `tier` is not an integer between 0 and 6.\
---*@throws* `string` — Thrown when `icon` is not an absolute file path with a valid extension.\
---*@throws* `string` — Thrown when `icon_size` is not a positive integer.
---@nodiscard
function _tiers.create_icon_with_tier_labels(tier, icon, icon_size, scale, shift, tint)
	return _tiers.add_tier_labels_to_icon(tier, sprite_utils.icons.create_icon(icon, icon_size, scale, shift, tint))
end

---
---Adds tier labels for the given `tier` to the icon of the given `prototype`, and packages
---the resulting data as a `DeferrableIcon` object.
---
---### Returns
---@return DeferrableIconData # The prototype and icon data packaged as a `DeferrableIcon` object enabling deferred assignment.
---
---### Remarks
---- Creates a `Sprite` object for the `pictures` field without tier labels for display in the world.
---- Missing icon fields are set to default values as appropriate.
---- `prototype` is not modified.
---
---### Examples
---```
----- Get a deferrable icon with tier labels for a tier 1 tank.
---local deferrable_icon = tiers.get_deferrable_icon_for_prototype_with_added_tier_labels(1, data.raw.car["tank"])
---```
---
---### Parameters
---@param tier integer # The tier of the added labels.
---@param prototype data.EntityPrototype|data.ItemPrototype|data.RecipePrototype # The prototype to add tier labels to.
---
---### Exceptions
---*@throws* `string` — Thrown when `tier` is not an integer between 0 and 6.<br/>
---*@throws* `string` — Thrown when `prototype` has no defined field `icon` or `icons`.<br/>
---*@throws* `string` — Thrown when `prototype` has no defined field `icon_size` at the root, or at the root of the first element in `icons`.<br/>
---*@throws* `string` — Thrown when `prototype` has an icon with field `icon` that is not an absolute file path with a valid extension.<br/>
---*@throws* `string` — Thrown when `prototype` has an icon with field `icon_size` that is not a positive integer.<br/>
function _tiers.get_deferrable_icon_for_prototype_with_added_tier_labels(tier, prototype)
	assert(
		tier and tier >= 0 and tier <= 6 and tier % 1 == 0,
		"Invalid parameter: 'tier' must be an integer between 0 and 6."
	)

	local source_icon_data = sprite_utils.icons.get_icon_from_prototype(prototype)

	-- A list of types that should not have their pictures field set.
	local filtered_types = {
		["corpse"] = true, -- Not a droppable prototype.
		["explosion"] = true, -- Not a droppable prototype.
		["item-with-entity-data"] = true, -- pictures field is non-functional on this type.
		["recipe"] = true, -- Not a droppable prototype.
		["technology"] = true, -- Not a droppable prototype.
	}

	---@type DeferrableIconData
	local deferrable_icon = {
		name = prototype.name,
		type_name = prototype.type,
		icon_data = _tiers.add_tier_labels_to_icons(tier, source_icon_data),
		pictures = not filtered_types[prototype.type]
				and sprite_utils.sprites.create_sprite_from_icons(source_icon_data, 1.0)
			or nil,
	}

	return deferrable_icon
end

---
---Adds tier labels for the given `tier` to the icon of the given `prototype` and related prototypes
---that follow standard naming conventions, such as item, explosion and remnant prototypes.
---
---Missing icon fields are set to default values as appropriate.
---
---### Examples
---```lua
----- Add tier labels to the tank prototype and related prototypes.
---tiers.add_tier_labels_to_prototype_by_reference(1, data.raw.car["tank"])
---```
---
---### Parameters
---@param tier integer # The tier of the added labels.
---@param prototype PrototypeWithIcons # The prototype to add tier labels to.
---
---### Exceptions
---*@throws* `string` — Thrown when `tier` is not an integer between `0` and `6`.\
---*@throws* `string` — Thrown when `prototype` has no defined field `icon` or `icons`.\
---*@throws* `string` — Thrown when `prototype` has an icon with field `icon` that is not an absolute file path with a valid extension.\
---*@throws* `string` — Thrown when `prototype` has an icon with field `icon_size` that is not a positive integer.
function _tiers.add_tier_labels_to_prototype(tier, prototype)
	local deferrable_icon = _tiers.get_deferrable_icon_for_prototype_with_added_tier_labels(tier, prototype)

	-- Prototype doesn't exist, or tier was 0.
	if not deferrable_icon then
		return
	end

	sprite_utils.icons.assign_icons_to_prototype_and_related_prototypes(
		deferrable_icon.name,
		deferrable_icon.type_name,
		deferrable_icon.icon_data,
		deferrable_icon.pictures
	)
end

---
---Adds tier labels for the given `tier` to the icon of the prototype with the given `name` and
---`type_name` and related prototypes that follow standard naming conventions, such as item,
---explosion and remnant prototypes.
---
---### Remarks
---- If `tier` is `0` or the prototype does not exist, no action is taken.
---- Missing icon fields are set to default values as appropriate.
---
---### Parameters
---@param tier Tier # The tier of the added labels.
---@param name string # The name of the prototype to add tier labels to.
---@param type_name string # The type name of the prototype to add tier labels to.
---
---### Examples
---```lua
----- Add tier labels to the tank prototype and related prototypes.
---tiers.add_tier_labels_to_prototype_by_name(1, "tank", "car")
---```
---
---### Exceptions
---*@throws* `string` — Thrown when `name` is `nil` or an empty string.\
---*@throws* `string` — Thrown when `type_name` is `nil` or an empty string.\
---*@throws* `string` — Thrown when `tier` is not an integer between 0 and 6.\
---*@throws* `string` — Thrown when the prototype has no defined field `icon` or `icons`.\
---*@throws* `string` — Thrown when the prototype icon has an with field `icon` that is not an absolute file path with a valid extension.\
---*@throws* `string` — Thrown when the prototype icon has an with field `icon_size` that is not a positive integer.
function _tiers.add_tier_labels_to_named_prototype(tier, name, type_name)
	assert(name and name ~= "", "Invalid parameter: 'name' must not be nil or an empty string.")
	assert(type_name and type_name ~= "", "Invalid parameter: 'type_name' must not be nil or an empty string.")

	_tiers.add_tier_labels_to_prototype(tier, data.raw[type_name][name])
end

return _tiers
