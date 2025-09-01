local upgrades = {
	Shotguns = {
		["DoubleShot_Tier"] = {
			{
				Name = "Double Shot: Tier 1",
				Description = "+ Fire rate",
				Price = 250,
			},
			{
				Name = "Double Shot: Tier 2",
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
				Name = "Drill Bite: Tier 1",
				Description = "+3 Ammo",
				Price = 250,
			},
			{
				Name = "Drill Bite: Tier 2",
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
				Name = "Quad Shot: Tier 1",
				Description = "+1 Pellet",
				Price = 250,
			},
			{
				Name = "Quad Shot: Tier 2",
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
				Name = "BORUS: Tier 1",
				Description = "+5 Ammo",
				Price = 250,
			},
			{
				Name = "BORUS: Tier 2",
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
				Name = "800M: Tier 1",
				Description = "+ Projectile Speed",
				Price = 250,
			},
			{
				Name = "800M: Tier 2",
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
				Name = "Gratana: Tier 1",
				Description = "+1 Ammo",
				Price = 250,
			},
			{
				Name = "Gratana: Tier 2",
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
				Name = "Bull Shot: Tier 1",
				Description = "+1 Ammo",
				Price = 250,
			},
			{
				Name = "Bull Shot: Tier 2",
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
				Name = "Boom Cannon: Tier 1",
				Description = "+ Fire rate",
				Price = 250,
			},
			{
				Name = "Boom Cannon: Tier 2",
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
				Name = "RIPP: Tier 1",
				Description = "+2 Ammo",
				Price = 250,
			},
			{
				Name = "RIPP: Tier 2",
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
				Name = "I-Six: Tier 1",
				Description = "+ lock on speed",
				Price = 250,
			},
			{
				Name = "I-Six: Tier 2",
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
				Name = "Katana: Tier 1",
				Description = "+ Range",
				Price = 250,
			},
			{
				Name = "Katana: Tier 2",
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
				Name = "Harpoons: Tier 1",
				Description = "+ Projectile Speed",
				Price = 250,
			},
			{
				Name = "Harpoons: Tier 2",
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
				Name = "Cutter: Tier 1",
				Description = "+ Range",
				Price = 250,
			},
			{
				Name = "Cutter: Tier 2",
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

	Core = {
		Combo_Tier = {
			{
				Name = "Combo: Dead Trigger",
				Description = "-1 combo hit penalty.",
				Price = 500,
			},
			{
				Name = "Combo: Broken Clock",
				Description = "+1 Second to combo time.",
				Price = 2000,
			},
			{
				Name = "Combo: Father's Mercy",
				Description = "Combo reduces by 5 instead of clearing",
				Price = 5000,
			},
		},

		Souls_Tier = {
			{
				Name = "Souls: Life Juice",
				Description = "You will always be given at least one soul when ending a level.",
				Price = 500,
			},
			{
				Name = "Souls: Spectral Greed",
				Description = "+ Soul Pickup distance",
				Price = 1000,
			},
			{
				Name = "Souls: Corporeal Mastery",
				Description = "+ Soul Chance",
				Price = 2500,
			},
		},
	},

	Stage_1_Perks = {
		["MasterScouting_Tier"] = {
			{
				Name = "Master Scouting",
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
				Name = "Righteous Motion : Tier 1",
				Description = "Finishing a manual reload refills dashes.",
				Price = 750,
			},

			{
				Name = "Righteous Motion : Tier 2",
				Description = "After using the third dash, Cleanse and Repent ammo will be refilled.",
				Price = 750,
			},

			{
				Name = "Righteous Motion : Tier 3",
				Description = "While dashing, revivng does not require a soul.",
				Price = 750,
			},
		},

		["BrickHook_Tier"] = {
			{
				Name = "BrickHook : Tier 1",
				Description = "Enemies have a 10% chance to be stunned after being hit with brick hook",
				Price = 600,
			},
			{
				Name = "BrickHook : Tier 1",
				Description = "+15% Shotgun and melee crit chance for 2 second after using brick hook",
				Price = 600,
			},
			{
				Name = "BrickHook : Tier 3",
				Description = "Hitting an enemy with Brick Hook adds +15% soul drop chance for 1 second",
				Price = 600,
			},
		},

		["SpikedSabatons_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+10% pistol and rifle crit chance while on a wall",
				Price = 600,
			},
			{
				Name = "Tier 2",
				Description = "Dealing crit damage with a pistol or rifle increases soul drop chance by +10% for 1 second",
				Price = 600,
			},
			{
				Name = "Tier 3",
				Description = "A long dash can be used by pressing shift",
				Price = 600,
			},
			
		},
	},

	Stage_2_Perks = {
		["Overcharge_Tier"] = {
			{
				Name = "Overcharge : Tier 1",
				Description = "Damage not dealt from picked up weapons adds to overcharge",
				Price = 500,
			},

			{
				Name = "Overcharge : Tier A",
				Description = "Upon activation: no infinite ammo, +35% crit chance, crits add +1 ammo",
				Price = 500,
			},

			{
				Name = "Overcharge : Tier B",
				Description = "Dealing crit damage adds to overcharge, including while overcharge is active",
				Price = 500,
			},
		},

		["MagLauncher_Tier"] = {
			{
				Name = "Burning Souls : Tier 1",
				Description = "-1 Second cooldown",
				Price = 750,
			},
			{
				Name = "Burning Souls : Tier 2",
				Description = "-1 Second cooldown",
				Price = 750, 
			},
{
				Name = "Burning Souls : Tier 3",
				Description = "Launcher grenades are now sticky bombs. Sticky bombs explode after a certain time. They will explode early when shot (+1 Dmg, Splash distance) -- Place holder",
				Price = 750,
			}
		},

		["BurningSouls_Tier"] = {
			{
				Name = "Burning Souls : Tier 1",
				Description = "-1 Second cooldown",
				Price = 500,
			},
			{
				Name = "Burning Souls : Tier 2",
				Description = "+1 Fire Range",
				Price = 500,
			},
			{
				Name = "Burning Souls : Tier 3",
				Description = "Cooldown resets when losing a soul -- Place holder",
				Price = 500,
			},
		},

		["GalvanGaze_Tier"] = {
			{
				Name = "Galvan Gaze : Tier 1",
				Description = "No longer requires half health",
				Price = 500,
			},

			{
				Name = "Galvan Gaze : Tier 2",
				Description = "-1 Second cooldown",
				Price = 500,
			},

			{
				Name = "Galvan Gaze : Tier 3",
				Description = "-5 Second cooldown when at 0 souls -- Place holder",
				Price = 500,
			},
		},
	},

	Stage_3_Perks = {
		["Maidenless_Tier"] = {
			{
				Name = "Tier 1",
				Description = "+1 armor to maidens blade attack",
				Price = 500,
			},

			{
				Name = "Tier A", -- Survival (soul)
				Description = "0.5 Second parry time, 1 second cooldown, enemies killed with the Maiden's Blade have a +20% soul chance.",
				Price = 500,
			},

			{
				Name = "Tier B", -- damage (arsenal)
				Description = "2 second cooldown, no longer drops armor, damage dealt from Maiden's blade will always be a crit. Deals <b>soul</b> damage.",
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
