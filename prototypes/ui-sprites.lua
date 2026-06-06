local function create_label_sprite(label)
	data:extend({
		{
			type = "sprite",
			name = "reskins-framework-" .. label .. "-tier-label",
			filename = "__reskins-framework__/graphics/ui-sprites/tiers/icon-" .. label .. ".png",
			flags = { "gui-icon" },
			size = 40,
			mipmap_count = 2,
		},
	})
end

local icons = {
	"chevron",
	"dots",
	"half-circle",
	"rectangle",
	"rounded-half-circle",
	"rounded-rectangle",
	"teardrop",
}

for _, v in pairs(icons) do
	create_label_sprite(v)
end
