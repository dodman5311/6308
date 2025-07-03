local upgrades = {
	Combo_Tier = {
		{
			Name = "Tier 1",
			Description = "-1 combo hit penalty.",
			Price = 600,
		},
		{
			Name = "Tier 2",
			Description = "+1 Second to combo time.",
			Price = 2000,
		},
		{
			Name = "Tier 3",
			Description = "Combo reduces by 5 instead of clearing",
			Price = 5000,
		},
	},

	Souls_Tier = {
		{
			Name = "Tier 1",
			Description = "+ Soul Pickup distance",
			Price = 600,
		},
		{
			Name = "Tier 2",
			Description = "You will always be given at least one soul when ending a level.",
			Price = 2000,
		},
		{
			Name = "Tier 3",
			Description = "+ Soul Chance",
			Price = 5000,
		},
	},

	Movement_Tier = {
		{
			Name = "Tier 1",
			Description = "+ Movement Speed",
			Price = 600,
		},
		{
			Name = "Tier 2",
			Description = "You will always be given at least one soul when ending a level.",
			Price = 2000,
		},
		{
			Name = "Tier 3",
			Description = "+ Soul Chance",
			Price = 5000,
		},
	},
}

for upgradeName, _ in pairs(upgrades) do
	workspace:SetAttribute(upgradeName, 0)
end

return upgrades
