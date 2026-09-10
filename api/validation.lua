---@using data
---@using Reskins.SpriteUtils
---@using Reskins.SpriteUtils.Validation

---@namespace Reskins.Framework

local V = require("__reskins-sprite-utils__.validation")
local Common = require("__reskins-sprite-utils__.validation.common")

---Provides validators for the values used by this API.
---
---#### Examples
---```lua
---local V = require("__reskins-sprite-utils__.validation")
---local FrameworkCommon = require("__reskins-framework__.api.validation")
---
---local check_get_tint = V.signature("get_tint", {
---    { "tier", FrameworkCommon.tier },
---})
---```
---@class FrameworkCommon
local _common = {}

---A validator that checks that a value is a tier.
_common.tier = V.one_of({ 0, 1, 2, 3, 4, 5, 6 }):describe_as("a tier between 0 and 6")

---A validator that checks that a value is a tier with a label.
_common.labeled_tier = V.one_of({ 1, 2, 3, 4, 5, 6 }):describe_as("a tier between 1 and 6")

return _common
