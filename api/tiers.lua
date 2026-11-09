---@using data
---@using Reskins.SpriteUtils
---@using Reskins.SpriteUtils.Validation

---@namespace Reskins.Framework

local _sprite_utils = {
	icons = require("__reskins-sprite-utils__.icons"),
	sprites = require("__reskins-sprite-utils__.sprites"),
}
local IconComposition = require("__reskins-sprite-utils__.icon-composition")
local _settings = require("__reskins-framework__.api.settings")

local V = require("__reskins-sprite-utils__.validation")
local Common = require("__reskins-sprite-utils__.validation.common")
local _result = require("__reskins-sprite-utils__.validation.result")
local FrameworkCommon = require("__reskins-framework__.api.validation")

---@alias Tier 0|1|2|3|4|5|6

---Provides methods for working with tier labels and tints.
---
---#### Examples
---```lua
---local _tiers = require("__reskins-framework__.api.tiers")
---```
---@class Tiers
local _tiers = {}

---Indicates whether tier labels are added to icons.
_tiers.show_labels = _settings.get_value("reskins-framework-show-tier-labels") == true

---Indicates whether tier labels are added to item-on-ground icons.
_tiers.show_labels_in_world = _tiers.show_labels
	and _settings.get_value("reskins-framework-show-tier-labels-in-world") == true

---Indicates whether tier labels are added to pipe-type entity icons.
_tiers.show_labels_on_pipes = _tiers.show_labels
	and _settings.get_value("reskins-framework-show-tier-labels-on-pipes") == true

---Indicates whether tier labels are added to the icons of transport belts and the entities that connect to them.
_tiers.show_labels_on_belts = _tiers.show_labels
	and _settings.get_value("reskins-framework-show-tier-labels-on-belts") == true

---@alias TierLabelStyle
---| "chevron" Chevrons.
---| "dots" Dots.
---| "half-circle" The upper-half of a circle.
---| "rectangle" A rectangle.
---| "rounded-half-circle" The upper-half of a circle, with rounded corners on the bottom.
---| "rounded-rectangle" A rectangle with rounded corners.
---| "teardrop" A teardrop.

---The current style of tier labels.
---@type TierLabelStyle
_tiers.tier_label_style = _settings.get_value("reskins-framework-tier-label-style")

---Indicates whether tier labels use progression tier mapping where applicable.
_tiers.use_progression = _settings.get_value("reskins-framework-tier-mapping") == "progression-map"

---Represents the tier of a prototype under traditional and progression tier mapping.
---@class PrototypeTierValue
---The traditional tier of the prototype.
---@field tier Tier
---The progression tier of the prototype.
---@field prog_tier? Tier

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

local check_get_tint = V.signature("get_tint", {
	{ "tier", FrameworkCommon.tier },
})

---Gets the color for the given `tier`.
---@param tier Tier The tier. An integer between 0 and 6.
---@return Color # The color for the given `tier`.
---@throws When `tier` is not an integer between 0 and 6.
function _tiers.get_tint(tier)
	check_get_tint(tier)

	if is_using_custom_tier_colors then
		return util.copy(custom_tier_colors[tier])
	else
		return util.copy(default_tier_colors[tier])
	end
end

---Gets the tier for the given `tier` and `prog_tier`.
---@param tier Tier The traditional tier.
---@param prog_tier? Tier The progression tier, if any.
---@return Tier # The tier appropriate for the current settings.
local function select_tier_for_current_mapping(tier, prog_tier)
	return _tiers.use_progression and prog_tier or tier
end

local check_get_tier = V.signature("get_tier", {
	{
		"tier",
		V.any_of(
			FrameworkCommon.tier,
			V.struct({
				tier = FrameworkCommon.tier,
				prog_tier = FrameworkCommon.tier:optional(),
			}):describe_as("a PrototypeTierValue")
		),
	},
	{ "prog_tier", FrameworkCommon.tier:optional() },
})

---Gets the tier appropriate for the current settings, for the given `tier` and `prog_tier`.
---
---#### Parameters
---@param tier Tier|PrototypeTierValue The traditional tier, an integer between 0 and 6, or a `PrototypeTierValue`.
---@param prog_tier? Tier The progression tier, an integer between 0 and 6. The value is ignored if `tier` is a `PrototypeTierValue`.
---
---#### Returns
---@return Tier # The tier appropriate for the current settings.
---@throws When `tier` is a `PrototypeTierValue` and does not have a `tier` field.
---@throws When either of `tier` or `prog_tier` is not an integer between 0 and 6.
---@nodiscard
function _tiers.get_tier(tier, prog_tier)
	check_get_tier(tier, prog_tier)

	if type(tier) == "table" then
		return select_tier_for_current_mapping(tier.tier, tier.prog_tier)
	else
		return select_tier_for_current_mapping(tier, prog_tier)
	end
end

---Indicates whether the given `icon_datum` is a layer of a tier label.
---@param icon_datum IconData
---@return boolean
---@nodiscard
local function is_tier_label_icon(icon_datum)
	return icon_datum and icon_datum.icon:find("__reskins%-framework__%/graphics%/icons%/tiers%/") ~= nil
end

---Indicates whether the given `icon_data` is tier labeled.
---@param icon_data IconData[] An array of `IconData` objects.
---@return boolean # `true` if `icons` is tier labeled; otherwise `false`.
---
---#### Examples
---```lua
----- Check if the assembling machine 3 icon is tier labeled, and perform a task if so.
---local icon_data = data.raw["assembling-machine"]["assembling-machine-3"].icons
---
---if _tiers.is_icons_tier_labeled(icon_data) then
---    -- Do something.
---end
---```
---@throws When `icon_data` is not an array of `IconData` objects.
---@nodiscard
function _tiers.is_icons_tier_labeled(icon_data)
	Common.icon_data:assert(icon_data, "icon_data", "is_icons_tier_labeled")

	for _, icon_datum in pairs(icon_data) do
		if is_tier_label_icon(icon_datum) then
			return true
		end
	end

	return false
end

---Gets the tier from the given `icon_data`, if it is tier labeled.
---
---`icon_data` is not modified.
---
---#### Parameters
---@param icon_data IconData[] An array of `IconData` objects.
---
---#### Returns
---@return Tier|nil # The tier of the tier label, or `nil` if `icon_data` is not tier labeled.
---
---#### Examples
---```lua
----- Get the current tier of the assembling-machine-3.
---local icon_data = data.raw["assembling-machine"]["assembling-machine-3"].icons
---
---if _tiers.get_tier_from_icons(icon_data) > 3 then
---    -- Do something.
---end
---```
---@throws When `icon_data` is not an array of `IconData` objects.
---@nodiscard
function _tiers.get_tier_from_icons(icon_data)
	Common.icon_data:assert(icon_data, "icon_data", "get_tier_from_icons")

	for _, icon_datum in pairs(icon_data) do
		if is_tier_label_icon(icon_datum) then
			return tonumber(icon_datum.icon:match("(%d+)%.png")) --[[@as Tier]]
		end
	end

	return nil
end

---Removes any tier labels from a copy of the given `icon_data`.
---
---#### Parameters
---@param icon_data IconData[] An array of `IconData` objects.
---
---#### Returns
---@return IconData[] icon_data A copy of `icon_data` without any tier labels.
---@return IconData[]? tier_labels A copy of the removed tier labels, if any.
---
---#### Examples
---```lua
----- Remove the tier labels from the assembling-machine-3.
---local icon_data = data.raw["assembling-machine"]["assembling-machine-3"].icons
---local icon_without_tier_labels = _tiers.remove_tier_labels_from_icons(icon_data)
---
----- Remove the tier labels from the assembling-machine-3 and keep a copy of the removed tier labels.
---local icon_without_tier_labels, removed_tier_labels = _tiers.remove_tier_labels_from_icons(icon_data)
---```
---@throws When `icon_data` is not an array of `IconData` objects.
---@nodiscard
function _tiers.remove_tier_labels_from_icons(icon_data)
	Common.icon_data:assert(icon_data, "icon_data", "remove_tier_labels_from_icons")

	---@type IconData[]
	local stripped_icon_data = {}

	---@type IconData[]
	local removed_layers = {}

	for _, icon_datum in pairs(util.copy(icon_data)) do
		if is_tier_label_icon(icon_datum) then
			removed_layers[#removed_layers + 1] = icon_datum
		else
			stripped_icon_data[#stripped_icon_data + 1] = icon_datum
		end
	end

	return stripped_icon_data, #removed_layers > 0 and removed_layers or nil
end

local check_add_tier_labels_to_icons = V.signature("add_tier_labels_to_icons", {
	{ "tier", FrameworkCommon.tier },
	{ "icon_data", Common.icon_data },
})

---Adds tier labels representing the given `tier` to a copy of the given `icon_data`.
---
---- If tier labeling is disabled, a copy of `icon_data` is returned without labels.
---- Missing icon fields are set to default values as appropriate.
---- `icon_data` is assumed to be an entity, item, fluid, or recipe icon. Technology icons are not supported.
---- `icon_data` is not modified.
---
---#### Parameters
---@param tier Tier The tier of the added labels. An integer between 0 and 6.
---@param icon_data IconData[] The icon to which tier labels are added, as an array of `IconData` objects.
---
---#### Returns
---@return IconData[] # An array of `IconData` objects representing a copy of `icon_data` with added tier labels.
---
---#### Examples
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
---@throws When `tier` is not an integer between 0 and 6.
---@throws When `icon_data` is not an array of `IconData` objects.
---@nodiscard
function _tiers.add_tier_labels_to_icons(tier, icon_data)
	check_add_tier_labels_to_icons(tier, icon_data)

	if not _tiers.show_labels then
		return util.copy(icon_data)
	end

	local icon_data_copy = _sprite_utils.icons.add_missing_icons_defaults(icon_data, "standard")

	-- There is not a 0th tier pip.
	if tier > 0 then
		icon_data_copy = _sprite_utils.icons.compose_icons("standard", icon_data, _tiers.get_tier_label(tier))
	end

	return icon_data_copy
end

local check_add_tier_labels_to_icon = V.signature("add_tier_labels_to_icon", {
	{ "tier", FrameworkCommon.tier },
	{ "icon_datum", Common.icon_datum },
})

---Adds tier labels representing the given `tier` to a copy of the given `icon_datum`.
---
---- If tier labeling is disabled, a copy of `icon_datum` is returned without labels, packaged as an array of `IconData`
---  objects with one element.
---- Missing icon fields are set to default values as appropriate.
---- `icon_datum` is assumed to be an entity, item, fluid, or recipe icon. Technology icons are not supported.<br>
---- `icon_datum` is not modified.
---
---#### Parameters
---@param tier integer The tier of the added labels.
---@param icon_datum IconData The icon to which tier labels are added, as an `IconData` object.
---
---#### Returns
---@return IconData[] # An array of `IconData` objects representing a copy of `icon_datum` with added tier labels.
---
---#### Examples
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
---@throws When `tier` is not an integer between 0 and 6.
---@throws When `icon_datum` is not an `IconData`.
---@nodiscard
function _tiers.add_tier_labels_to_icon(tier, icon_datum)
	check_add_tier_labels_to_icon(tier, icon_datum)

	return _tiers.add_tier_labels_to_icons(tier, { icon_datum })
end

local check_create_icon_with_tier_labels = V.signature("create_icon_with_tier_labels", {
	{ "tier", FrameworkCommon.tier },
	{ "icon", Common.mod_file_path },
	{ "icon_size", Common.sprite_size:optional() },
	{ "scale", Common.positive_number:optional() },
	{ "shift", Common.vector:optional() },
	{ "tint", Common.color:optional() },
})

---Adds tier labels representing the given `tier` to an icon created from the given parameters.
---
---- The parameters are assumed to be for an entity, item, fluid, or recipe icon. Technology icons are not supported.
---- Missing icon fields are set to default values as appropriate.
---
---#### Parameters
---@param tier integer The tier of the added labels.
---@param icon FileName The file name of the icon to use.
---@param icon_size SpriteSizeType The size of the icon.
---@param scale? double The scale of the icon. Default `32 / icon_size`.
---@param shift? Vector The shift of the icon. Default `nil`.
---@param tint? Color The tint of the icon. Default `nil`.
---
---#### Returns
---@return IconData[] # An array of `IconData` objects representing the created icon with added tier labels.
---
---#### Examples
---```lua
---local labeled_icon = _tiers.create_icon_with_tier_labels(1, "__base__/graphics/icons/assembling-machine-1.png", 64, 4, 0.5)
---```
---@throws When `tier` is not an integer between 0 and 6.
---@throws When `icon` is not an absolute file path with a valid extension.
---@throws When `icon_size` is not a sprite size in pixels.
---@throws When `scale` is not a positive number, `shift` is not a `Vector`, or `tint` is not a `Color`.
---@nodiscard
function _tiers.create_icon_with_tier_labels(tier, icon, icon_size, scale, shift, tint)
	check_create_icon_with_tier_labels(tier, icon, icon_size, scale, shift, tint)

	return _tiers.add_tier_labels_to_icon(tier, _sprite_utils.icons.create_icon(icon, icon_size, scale, shift, tint))
end

---Defines the icon of a prototype with the tier of its tier label, for `assign_icons_with_tier_labels` and
---`icon_assignment_with_tier_labels`. Exactly one of `icon_datum`, `icon_data`, `composition`, and `sources` supplies
---the icon.
---@class TieredIconDefinition : IconDefinition
---The tier of the label. An integer between 0 and 6. Default `0`.
---@field tier? Tier

---Defines the parameters of `icon_assignment_with_tier_labels`. Exactly one of `icon_datum`, `icon_data`,
---`composition`, and `sources` supplies the icon.
---@class IconAssignmentWithTierLabelsParams : TieredIconDefinition
---The name of the prototype to which the icon is assigned.
---@field name string
---The type name of the prototype to which the icon is assigned.
---@field type_name string

local hide_tier_label_for_type = {
	["technology"] = true,
	["pipe"] = not _tiers.show_labels_on_pipes,
	["pipe-to-ground"] = not _tiers.show_labels_on_pipes,
	["heat-pipe"] = not _tiers.show_labels_on_pipes,
	["transport-belt"] = not _tiers.show_labels_on_belts,
	["underground-belt"] = not _tiers.show_labels_on_belts,
	["splitter"] = not _tiers.show_labels_on_belts,
	["lane-splitter"] = not _tiers.show_labels_on_belts,
	["linked-belt"] = not _tiers.show_labels_on_belts,
	["loader"] = not _tiers.show_labels_on_belts,
	["loader-1x1"] = not _tiers.show_labels_on_belts,
}

---The group definition for tier labels in an icon composition.
---
---- The group is a `label` group: its content is positioned relative to the finished icon, is not scaled or shifted
---  with the artwork, and is not included when the composition is embedded in another composition.
---- `tintable` is `false`; `set_tint` and `blend_tint` are not applied to the label.
---- `unique` is `true`; adding a label replaces the existing label.
---- The group is included in the `pictures` projection only when "Show tier labels in world" is enabled.
---@type IconCompositionGroup
_tiers.tier_label_group = {
	name = "tier-label",
	stratum = "label",
	tintable = false,
	unique = true,
	projections = _tiers.show_labels_in_world and { pictures = {} } or nil,
}

---Gets the layers of the tier label for the given `tier`. The layers are the label artwork in the current style and a
---copy of it tinted with the color of the tier.
---
---- The label is sized for entity, item, fluid, and recipe icons. Technology icons are not supported.
---- There is no label for tier 0.
---
---#### Parameters
---@param tier Tier The tier of the label. An integer between 1 and 6.
---
---#### Returns
---@return SafeIconData[] # The two layers of the label.
---@throws When `tier` is not an integer between 1 and 6.
---@nodiscard
function _tiers.get_tier_label(tier)
	FrameworkCommon.labeled_tier:assert(tier, "tier", "get_tier_label")

	local icon_file_name = "__reskins-framework__/graphics/icons/tiers/"
		.. _tiers.tier_label_style
		.. "/"
		.. tier
		.. ".png"

	---@type IconData[]
	local icon_data = {
		{ icon = icon_file_name },
		---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
		{ icon = icon_file_name, tint = util.get_color_with_alpha(_tiers.get_tint(tier), 0.75) },
	}

	return _sprite_utils.icons.add_missing_icons_defaults(icon_data, "default")
end

---Indicates whether tier labels are drawn on prototypes of `type_name` under the current settings.
---
---- Returns `false` when "Show tier labels" is disabled, and for `pipe`, `pipe-to-ground`, and `heat-pipe` prototypes
---  when "Show tier labels on pipes" is disabled.
---- Returns `false` for `transport-belt`, `underground-belt`, `splitter`, `lane-splitter`, `linked-belt`, `loader`, and
---  `loader-1x1` prototypes when "Show tier labels on belts" is disabled.
---- Returns `false` for `technology` prototypes.
---
---#### Parameters
---@param type_name string The type name of the prototype.
---
---#### Returns
---@return boolean # `true` if tier labels are shown; otherwise, `false`.
---@throws When `type_name` is `nil` or an empty string.
---@nodiscard
function _tiers.are_tier_labels_shown_for(type_name)
	Common.prototype_type_name:assert(type_name, "type_name", "are_tier_labels_shown_for")

	return _tiers.show_labels and hide_tier_label_for_type[type_name] ~= true
end

---Gets the group of the given `icon_datum` for the classification of an icon, `tiers.tier_label_group` for a layer of a
---tier label and the canvas group for any other layer.
---@param icon_datum IconData The layer.
---@return IconCompositionGroup
---@nodiscard
local function classify_tier_label_layers(icon_datum)
	return is_tier_label_icon(icon_datum) and _tiers.tier_label_group or IconComposition.canvas_group
end

---Gets the composition of the given `definition` with the tier label of its tier, as the current settings allow,
---without validating the tier.
---@param definition TieredIconDefinition The definition.
---@param type_name string The type name of the prototype to which the icon is assigned.
---@param name string The name of the prototype to which the icon is assigned.
---@param excluded table<string, boolean> The fields of `definition` that are not fields of an `IconDefinition`.
---@return IconComposition
---@nodiscard
local function get_tier_labeled_composition(definition, type_name, name, excluded)
	---@type IconDefinition
	local icon_definition = {}
	for field, value in pairs(definition) do
		if not excluded[field] then
			---@diagnostic disable-next-line: assign-type-mismatch
			icon_definition[field] = value
		end
	end

	local composition = _sprite_utils.icons.get_icon_composition(
		icon_definition,
		type_name,
		{ classify = classify_tier_label_layers, name = name }
	)

	local tier = definition.tier or 0
	if tier == 0 or not _tiers.are_tier_labels_shown_for(type_name) then
		return composition:remove(_tiers.tier_label_group.name)
	end

	return composition:add(_tiers.tier_label_group, _tiers.get_tier_label(tier))
end

---The fields of `IconAssignmentWithTierLabelsParams` that are not fields of an `IconDefinition`.
local ASSIGNMENT_PARAMS_FIELDS = { tier = true, name = true, type_name = true }

---The field of `TieredIconDefinition` that is not a field of an `IconDefinition`.
local TIERED_DEFINITION_FIELDS = { tier = true }

local check_icon_assignment_with_tier_labels = V.signature("icon_assignment_with_tier_labels", {
	{
		"params",
		V.struct({
			tier = FrameworkCommon.tier:optional(),
			name = Common.prototype_name,
			type_name = Common.prototype_type_name,
			icon_datum = Common.icon_datum:optional(),
			icon_data = Common.icon_data:optional(),
			composition = Common.icon_composition:optional(),
			sources = V.array(V.table()):not_empty():optional(),
			label = Common.icon_data:optional(),
			options = Common.icon_assignment_options:optional(),
		})
			:strict()
			:where(function(value)
				local defined = 0
				for _, field in pairs({ "icon_datum", "icon_data", "composition", "sources" }) do
					if value[field] ~= nil then
						defined = defined + 1
					end
				end

				return defined == 1
			end, "must define exactly one of the 'icon_datum', 'icon_data', 'composition', and 'sources' fields")
			:describe_as("an IconAssignmentWithTierLabelsParams"),
	},
})

---Gets an icon assignment with the tier label for the given `tier` added, as the current settings allow.
---
---- The icon is resolved as by `icons.get_icon_composition` of Artisanal Reskins: Sprite Utils, in the icon defaults
---  type of `params.type_name`. Tier label layers in an icon given as an array or a single layer are put in
---  `tiers.tier_label_group`, and tier label layers in the icon of a source are left out. A composition given as
---  `params.composition` is used as it is. Tier label layers in its content are not removed.
---- The label for `tier` is placed in `tiers.tier_label_group`, replacing any label the composition has there. When
---  `tier` is 0, or the settings hide tier labels for prototypes of `type_name`, the group is removed.
---- The icon is built with `to` set to `params.type_name`.
---- `pictures` is set when the pictures differ from the icon: the label is hidden in world, or the composition contains
---  a light or other content that is drawn only in the pictures.
---
---#### Parameters
---@param params IconAssignmentWithTierLabelsParams The tier, the prototype to be assigned the icon, and the icon.
---
---#### Returns
---@return IconDataAssignment # The labeled icon, ready for `icons.apply_icon_assignment`.
---
---#### Examples
---```lua
---local icon_assignment = _tiers.icon_assignment_with_tier_labels({
---    tier = tier,
---    name = name,
---    type_name = "assembling-machine",
---    composition = get_icon_composition({ tint = tint }):add_light(sprites_api.get_sprite_light_layer(_defines.light.fuel, tint)),
---})
---_sprite_utils.icons.apply_icon_assignment(icon_assignment)
---```
---@throws When `params.tier` is not an integer between 0 and 6.
---@throws When `params.name` or `params.type_name` is `nil` or an empty string.
---@throws When `params` does not define exactly one of `icon_datum`, `icon_data`, `composition`, and `sources`.
---@throws When a field of `params` is not valid for an `IconAssignmentWithTierLabelsParams`, or is not one of its fields.
---@see Tiers.assign_icons_with_tier_labels
---@see Tiers.remove_tier_labels_from_icons
---@see Tiers.tier_label_group
---@nodiscard
function _tiers.icon_assignment_with_tier_labels(params)
	check_icon_assignment_with_tier_labels(params)

	local name, type_name = params.name, params.type_name
	local composition = get_tier_labeled_composition(params, type_name, name, ASSIGNMENT_PARAMS_FIELDS)
	local labeled_icon_data, pictures = composition:build({ to = type_name })

	return {
		name = name,
		type_name = type_name,
		icon_data = labeled_icon_data,
		pictures = pictures,
		options = params.options,
	}
end

---A validator that checks that a value is `nil` or a tier between 0 and 6.
local optional_tier = FrameworkCommon.tier:optional()

local check_assign_icons_with_tier_labels = V.signature("assign_icons_with_tier_labels", {
	{ "type_name", Common.prototypes.is_registered_type },
	{ "definitions", V.map(Common.prototype_name, V.table()) },
})

---Assigns the icon that each of the given `definitions` gives, with the tier label of its tier as the current settings
---allow, to the prototype of the given `type_name` with its name.
---
---- The definitions are assigned in the order of their names. A definition for a prototype that does not exist is
---  skipped, and is not validated.
---- Each definition is resolved and labeled as by `icon_assignment_with_tier_labels`, and is assigned as by
---  `icons.apply_icon_assignment` of Artisanal Reskins: Sprite Utils.
---
---#### Parameters
---@param type_name string The type name of the prototypes.
---@param definitions table<string, TieredIconDefinition> The definitions, under the name of the prototype to which each is assigned.
---
---#### Examples
---```lua
----- Assign the icons of the plates, and the icons of the recipes that read them.
---local corner = _sprite_utils.defines.icon_transforms.compass.northwest
---local plate = IconComposition:from_icon({ icon = "__my-mod__/graphics/icons/aluminium-plate.png", icon_size = 64 })
---
---_tiers.assign_icons_with_tier_labels("item", {
---    ["angels-plate-aluminium"] = { composition = plate, tier = 1 },
---    ["bob-aluminium-plate"] = { composition = plate, tier = 1 },
---})
---
---_tiers.assign_icons_with_tier_labels("recipe", {
---    ["angels-plate-aluminium"] = {
---        sources = {
---            { names = { "bob-aluminium-plate", "angels-plate-aluminium" }, type_name = "item" },
---            { name = "angels-liquid-molten-aluminium", type_name = "fluid", transform = corner },
---        },
---    },
---})
----- The plates have the tier label of tier 1. The recipe shows the plate that it makes, without a tier label.
---```
---@throws When `type_name` is not a registered prototype type name.
---@throws When `definitions` is not a table of tables keyed by prototype names.
---@throws When a definition for a prototype that exists has a `tier` that is not an integer between 0 and 6, or is not a valid `IconDefinition` otherwise.
---@see Tiers.icon_assignment_with_tier_labels
function _tiers.assign_icons_with_tier_labels(type_name, definitions)
	check_assign_icons_with_tier_labels(type_name, definitions)

	local names = {}
	for name in pairs(definitions) do
		names[#names + 1] = name
	end
	table.sort(names)

	for _, name in pairs(names) do
		if data.raw[type_name][name] then
			local definition = definitions[name]
			optional_tier:assert(
				definition.tier,
				_result.child_path("definitions", name) .. ".tier",
				"assign_icons_with_tier_labels"
			)

			local composition = get_tier_labeled_composition(definition, type_name, name, TIERED_DEFINITION_FIELDS)
			local icon_data, pictures = composition:build({ to = type_name })

			_sprite_utils.icons.assign_icons_to_prototype_and_related_prototypes(
				name,
				type_name,
				icon_data,
				pictures,
				definition.options
			)
		end
	end
end

local check_add_tier_labels_to_prototype = V.signature("add_tier_labels_to_prototype", {
	{ "tier", FrameworkCommon.tier },
	{ "prototype", Common.prototype_with_icons },
})

---Adds tier labels for the given `tier` to the icon of the given `prototype` and related prototypes that follow
---standard naming conventions, such as item, explosion and remnant prototypes.
---
---Missing icon fields are set to default values as appropriate.
---@param tier integer The tier of the added labels.
---@param prototype PrototypeWithIcons The prototype to which tier labels are added.
---
---#### Examples
---```lua
----- Add tier labels to the tank prototype and related prototypes.
---_tiers.add_tier_labels_to_prototype(1, data.raw.car["tank"])
---```
---@throws When `tier` is not an integer between 0 and 6.
---@throws When `prototype` does not define an icon through the `icon` or `icons` field.
---@throws When the icon of `prototype` is not an `IconData` or an array of them.
function _tiers.add_tier_labels_to_prototype(tier, prototype)
	check_add_tier_labels_to_prototype(tier, prototype)

	local icon_assignment = _tiers.icon_assignment_with_tier_labels({
		tier = tier,
		name = prototype.name,
		type_name = prototype.type,
		icon_data = _sprite_utils.icons.get_icon_from_prototype(prototype),
	})

	_sprite_utils.icons.apply_icon_assignment(icon_assignment)
end

local check_add_tier_labels_to_named_prototype = V.signature("add_tier_labels_to_named_prototype", {
	{ "tier", FrameworkCommon.tier },
	{ "name", Common.prototype_name },
	{ "type_name", Common.prototypes.is_registered_type },
}, { Common.prototypes.names_an_existing_prototype() })

---Adds tier labels for the given `tier` to the icon of the prototype with the given `name` and `type_name` and related
---prototypes that follow standard naming conventions, such as item, explosion and remnant prototypes.
---
---- If `tier` is 0, no action is taken.
---- Missing icon fields are set to default values as appropriate.
---
---#### Parameters
---@param tier Tier The tier of the added labels.
---@param name string The name of the prototype to which tier labels are added.
---@param type_name string The type name of the prototype to which tier labels are added.
---
---#### Examples
---```lua
----- Add tier labels to the tank prototype and related prototypes.
---_tiers.add_tier_labels_to_named_prototype(1, "tank", "car")
---```
---@throws When `tier` is not an integer between 0 and 6.
---@throws When `name` is `nil` or an empty string.
---@throws When `type_name` is not a registered prototype type name.
---@throws When no prototype of type `type_name` has the given `name`.
---@throws When the prototype does not define an icon through the `icon` or `icons` field.
---@throws When the icon of the prototype is not an `IconData` or an array of them.
function _tiers.add_tier_labels_to_named_prototype(tier, name, type_name)
	check_add_tier_labels_to_named_prototype(tier, name, type_name)

	_tiers.add_tier_labels_to_prototype(tier, data.raw[type_name][name] --[[@as PrototypeBase]])
end

return _tiers
