local upgrades = {
	Shotguns = {
		["DoubleShot_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+ Fire rate",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+1 Pellet",
				Price = 400,
			},
			{
				Name = "Broad Shot",
				Description = "Pellets now pierce through enemies",
				Price = 500,
			},
		},

		["DrillBite_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+3 Ammo",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "Pellets now have a 5% chance to light enemies on fire",
				Price = 500,
			},
			{
				Name = "Wrath Guard",
				Description = "Wrath Guard’s parry is a stunning punch",
				Price = 1000,
			},
		},

		["QuadShot_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+1 Pellet",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+1 Pellet",
				Price = 500,
			},
			{
				Name = "Mega Shot",
				Description = "Every loaded shell is different. Mega shot fires 3 Explosive rounds, 3 Homing rounds, 3 Regular pellets, and 1 Slug with 3 damage",
				Price = 1000,
			},
		},
	},

	Rifles = {
		BORUS_Tier = {
			{
				Name = "Tier 1",
				Description = "+5 Ammo",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "- Recoil",
				Price = 500,
			},
			{
				Name = "HADES",
				Description = "HADES has +1 Damage, -3 Speed, +10 Ammo",
				Price = 1000,
			},
		},

		["800M_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+ Projectile Speed",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+ Splash Range",
				Price = 500,
			},
			{
				Name = "Concussion",
				Description = "Explosions from the Concussion have a 15% chance to stun",
				Price = 1000,
			},
		},

		Gratana_Tier = {
			{
				Name = "Tier 1",
				Description = "+1 Ammo",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+1 Ammo",
				Price = 500,
			},
			{
				Name = "Dovus",
				Description = "Can lock onto up to two targets. Can fire as fast as you pull the trigger.",
				Price = 1000,
			},
		},
	},

	Pistols = {
		["BullShot_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+1 Ammo",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+ Projectile speed",
				Price = 500,
			},
			{
				Name = "Dread Shot",
				Description = "Rockets slightly seek enemies",
				Price = 1000,
			},
		},

		["BoomCannon_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+ Fire rate",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "Shots now have a 5% chance to ricochet to a nearby enemy",
				Price = 500,
			},
			{
				Name = "50 Regret",
				Description = "x2 damage to weak points",
				Price = 1000,
			},
		},

		RIPP_Tier = {
			{
				Name = "Tier 1",
				Description = "+2 Ammo",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+ Splash Range",
				Price = 500,
			},
			{
				Name = "Experiment 05",
				Description = "Shots have a 5% chance to electrify enemies",
				Price = 1000,
			},
		},

		["ISix_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+ lock on speed",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+1 Lock on amount",
				Price = 500,
			},
			{
				Name = "I-Seven",
				Description = "When beginning a lock on, a parrying shield is created for 0.5 seconds",
				Price = 1000,
			},
		},
	},

	Melee = {
		Katana_Tier = {
			{
				Name = "Tier 1",
				Description = "+ Range",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "A successful parry has a 5% to add ammo",
				Price = 500,
			},
			{
				Name = "Shagan",
				Description = "Attacking at least 3 second after a successful parry will launch the player forward",
				Price = 1000,
			},
		},

		Harpoons_Tier = {
			{
				Name = "Tier 1",
				Description = "+ Projectile Speed",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "Harpoons have a 10% chance to stun enemies",
				Price = 500,
			},
			{
				Name = "Trident",
				Description = "Hitting stunned enemies will deal 3 damage",
				Price = 1000,
			},
		},

		Cutter_Tier = {
			{
				Name = "Tier 1",
				Description = "+ Range",
				Price = 250,
			},
			{
				Name = "Tier 2",
				Description = "+ Range",
				Price = 500,
			},
			{
				Name = "Bloody Mary",
				Description = "Successfully parrying an attack will convert said attack into a smart sawblade",
				Price = 1000,
			},
		},
	},

	Souls = {
		Combo_Tier = {
			{
				Name = "Tier 1",
				Description = "-1 combo hit penalty.",
				Price = 500,
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
				Description = "You will always be given at least one soul when ending a level.",
				Price = 500,
			},
			{
				Name = "Tier 2",
				Description = "+ Soul Pickup distance",
				Price = 1000,
			},
			{
				Name = "Tier 3",
				Description = "+ Soul Chance",
				Price = 2500,
			},
		},
	},

	Perks = {
		["MasterScouting_Tier"] = {
			{
				Name = "Tier 1",
				Description = "One extra jump is added",
				Price = 500,
			},

			{
				Name = "Tier A",
				Description = "Throwing a weapon while in the air boosts you upwards.",
				Price = 500,
			},

			{
				Name = "Tier B",
				Description = "When in the air, bullets fired boost you in the opposite direction.",
				Price = 500,
			},
		},

		["RighteousMotion_Tier"] = {
			{
				Name = "Tier 1",
				Description = "Extra dash",
				Price = 750,
			},
		},

		["BrickHook_Tier"] = {
			{
				Name = "Tier 1",
				Description = "A dash can be used when on cooldown",
				Price = 600,
			},
		},

		["SpikedSabatons_Tier"] = {
			{
				Name = "Tier 1",
				Description = "A long dash can be used by pressing shift",
				Price = 600,
			},
		},

		["Overcharge_Tier"] = {
			{
				Name = "Tier 1",
				Description = "Damage not dealt from picked up weapons adds to overcharge",
				Price = 500,
			},

			{
				Name = "Tier A",
				Description = "Upon activation: no infinite ammo, faster firate, +35% crit chance, and crits add ammo.",
				Price = 500,
			},

			{
				Name = "Tier B",
				Description = "Overcharge charges faster. Even more charge when dealing crit damage.",
				Price = 500,
			},
		},

		["MagLauncher_Tier"] = {
			{
				Name = "Tier 1",
				Description = "-2 Second cooldown",
				Price = 750,
			},
		},

		["BurningSouls_Tier"] = {
			{
				Name = "Tier 1",
				Description = "-1 Second cooldown",
				Price = 500,
			},
		},

		["GalvanGaze_Tier"] = {
			{
				Name = "Tier 1",
				Description = "-1 Second cooldown",
				Price = 500,
			},
		},

		["Maidenless_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+1 armor to maidens blade attack",
				Price = 500,
			},

			{
				Name = "Tier A",
				Description = "0.5 Second parry time, 1 second cooldown. No longer drops armor. Deals <b>soul</b> damage.",
				Price = 500,
			},

			{
				Name = "Tier B",
				Description = "2 second cooldown. +2 damage. Enemies killed with the Maiden's Blade have a +20% soul chance.",
				Price = 500,
			},
		},
	},
}
for _, category in pairs(upgrades) do
	for upgradeName, _ in pairs(category) do
		if workspace:GetAttribute(upgradeName) then
			continue
		end
		workspace:SetAttribute(upgradeName, 0)
	end
end

return upgrades
