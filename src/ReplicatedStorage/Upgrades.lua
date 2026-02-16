local upgrades = {
	Shotguns = {
		["DoubleShot_Tier"] = {
			{
				Name = "Double Shot: Tier 1",
				Description = [[+1 Pellet]],
				Price = 100,
			},
			{
				Name = "Double Shot: Tier 2",
				Description = [[+0.3 Speed]],
				Price = 250,
			},
			{
				Name = "Broad Shot",
				Description = [[+2 Pellets
				
Pellets now pierce through enemies and have a 10% chance to ricochet to a nearby enemy,
but they travel slower]],
				Price = 500,
			},
		},

		["DrillBite_Tier"] = {
			{
				Name = "Drill Bite: Tier 1",
				Description = [[+3 Ammo]],
				Price = 250,
			},
			{
				Name = "Drill Bite: Tier 2",
				Description = [[Pellets now have a 5% chance to light enemies on fire]],
				Price = 500,
			},
			{
				Name = "Wrath Guard",
				Description = [[Wrath Guard’s parry is a stunning punch]],
				Price = 750,
			},
		},

		["QuadShot_Tier"] = {
			{
				Name = "Quad Shot: Tier 1",
				Description = [[+1 Pellet]],
				Price = 250,
			},
			{
				Name = "Quad Shot: Tier 2",
				Description = [[+1 Pellet]],
				Price = 500,
			},
			{
				Name = "Mega Shot",
				Description = [[-2 Ammo
				
Every loaded shell is different. Mega shot fires 3 Explosive rounds, 3 Homing rounds, 3 Regular pellets, and 3 Flechettes with 3 damage]],
				Price = 750,
			},
		},
	},

	Rifles = {
		BORUS_Tier = {
			{
				Name = "BORUS: Tier 1",
				Description = [[+5 Ammo]],
				Price = 100,
			},
			{
				Name = "BORUS: Tier 2",
				Description = [[-1 Recoil]],
				Price = 250,
			},
			{
				Name = "HADES",
				Description = [[HADES has +1 Damage, -3 Speed, +10 Ammo]],
				Price = 500,
			},
		},

		["800M_Tier"] = {
			{
				Name = "800M: Tier 1",
				Description = [[+50% Projectile Speed]],
				Price = 250,
			},
			{
				Name = "800M: Tier 2",
				Description = [[+100% Splash Range]],
				Price = 500,
			},
			{
				Name = "Concussion",
				Description = [[Explosions from the Concussion have a 15% chance to stun]],
				Price = 750,
			},
		},

		Gratana_Tier = {
			{
				Name = "Gratana: Tier 1",
				Description = [[+1 Ammo]],
				Price = 250,
			},
			{
				Name = "Gratana: Tier 2",
				Description = [[+1 Ammo]],
				Price = 500,
			},
			{
				Name = "Dovus",
				Description = [[Can lock onto up to two targets. Can fire as fast as you pull the trigger.]],
				Price = 750,
			},
		},
	},

	Pistols = {
		["BullShot_Tier"] = {
			{
				Name = "Bull Shot: Tier 1",
				Description = [[+50% Splash Range]],
				Price = 250,
			},
			{
				Name = "Bull Shot: Tier 2",
				Description = [[+1 Pellets]],
				Price = 500,
			},
			{
				Name = "Dread Shot",
				Description = [[Hitting enemies douses them with bile, increasing damage taken by 1 for 2 seconds.
				
Rockets slightly seek enemies]],
				Price = 750,
			},
		},

		["CleanseAndRepent_Tier"] = {
			{
				Name = "Cleanse & Repent: Tier 1",
				Description = [[-1 Recoil]],
				Price = 250,
			},
			{
				Name = "Cleanse & Repent: Tier 2",
				Description = [[+10% Reload speed]],
				Price = 500,
			},
			{
				Name = "Forged Arms",
				Description = [[+50 crit chance when hitting headshots
				
+1 Speed]],
				Price = 750,
			},
		},

		["BoomCannon_Tier"] = {
			{
				Name = "Boom Cannon: Tier 1",
				Description = [[Shots now have a 10% chance to ricochet to a nearby enemy]],
				Price = 100,
			},
			{
				Name = "Boom Cannon: Tier 2",
				Description = [[+1 Damage]],
				Price = 250,
			},
			{
				Name = "50 Regret",
				Description = [[+1 Damage
+6 Recoil

x2 damage to weak points]],
				Price = 500,
			},
		},

		RIPP_Tier = {
			{
				Name = "RIPP: Tier 1",
				Description = [[+100% Splash Range]],
				Price = 250,
			},
			{
				Name = "RIPP: Tier 2",
				Description = [[+1 Splash Damage]],
				Price = 600,
			},
			{
				Name = "Lazerus",
				Description = [[-14 Ammo
-9 Speed
-75% projectile speed

+1 Damage
+100% Splash Range

Plasma bolts now create damaging tendrils around then that deal 1 Damage per 0.1 second to any nearby enemy.]],
				Price = 1250,
			},
		},

		["ISix_Tier"] = {
			{
				Name = "I-Six: Tier 1",
				Description = [[+65% lock on speed]],
				Price = 250,
			},
			{
				Name = "I-Six: Tier 2",
				Description = [[+1 Lock on amount]],
				Price = 500,
			},
			{
				Name = "I-Seven",
				Description = [[+1 Ammo
				
When beginning a lock on, a parrying shield is created until the weapon is discharged.
The shield can parry 7 attacks before dispersing.]],
				Price = 750,
			},
		},
	},

	Melee = {
		Katana_Tier = {
			{
				Name = "Katana: Tier 1",
				Description = [[+5 Range]],
				Price = 100,
			},
			{
				Name = "Katana: Tier 2",
				Description = [[A successful parry has a 15% chance to add ammo]],
				Price = 250,
			},
			{
				Name = "Shagan",
				Description = [[+5 Range
				
Attacking at least 0.5 second after parrying will launch the player forward]],
				Price = 500,
			},
		},

		Harpoons_Tier = {
			{
				Name = "Harpoons: Tier 1",
				Description = [[+50% Projectile Speed]],
				Price = 250,
			},
			{
				Name = "Harpoons: Tier 2",
				Description = [[+1 Piercing]],
				Price = 500,
			},
			{
				Name = "Trident",
				Description = [[+1 Damage
				
The trident seeks enemies and has infinite piercing.]],
				Price = 750,
			},
		},

		Cutter_Tier = {
			{
				Name = "Cutter: Tier 1",
				Description = [[+5 Range]],
				Price = 250,
			},
			{
				Name = "Cutter: Tier 2",
				Description = [[+50 Ammo]],
				Price = 500,
			},
			{
				Name = "Bloody Mary",
				Description = [[1 Damage x 3
50% Cooler

Successfully parrying an attack will convert said attack into three smart sawblades]],
				Price = 750,
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
				Price = 1000,
			},
			{
				Name = "Combo: Father's Mercy",
				Description = "Combo reduces by 5 instead of clearing",
				Price = 3250,
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
				Price = 750,
			},
			{
				Name = "Souls: Corporeal Mastery",
				Description = "+ Soul Chance",
				Price = 1000,
			},
		},
	},

	Stage_1_Perks = {
		["Master_Scouting"] = {
			{
				Name = "Master Scouting",
				Description = "One extra jump is added",
				Price = 100,
			},

			{
				Name = "Master Scouting: Opposing Force",
				Description = "Throwing a weapon while in the air boosts you upwards.",
				Price = 150,
			},

			{
				Name = "Master Scouting: Joy Ride",
				Description = "When in the air, bullets fired boost you in the opposite direction.",
				Price = 150,
			},
		},

		["Righteous_Motion"] = {
			{
				Name = "Righteous Motion: Tier 1",
				Description = "Finishing a reload, when out of ammo, refills dashes.",
				Price = 200,
			},

			{
				Name = "Righteous Motion: Tier 2",
				Description = "After using the third dash, a manual reload will be completed.",
				Price = 350,
			},

			{
				Name = "Righteous Motion: Tier 3",
				Description = "Weapons will not use ammo for 0.5 seconds after dashing",
				Price = 500,
			},
		},

		["Brick_Hook"] = {
			{
				Name = "BrickHook: Tier 1",
				Description = "Enemies have a 10% chance to be stunned after being hit with brick hook", -- holding shift swings you from a point.
				Price = 200,
			},
			{
				Name = "BrickHook: Tier 2",
				Description = "+10 crit chance for 2 seconds after using brick hook", -- holding shift while on the ground, activates a damaging slide.
				Price = 350,
			},
			{
				Name = "BrickHook: Tier 3",
				Description = "Hitting an enemy with Brick Hook adds +20% soul drop chance for 1 second", -- player is invincible while whip sliding
				Price = 500,
			},
		},

		["Spiked_Sabatons"] = {
			{
				Name = "Spiked Sabatons: Tier 1",
				Description = "+40% jump hight for the third jump.",
				Price = 200,
			},
			{
				Name = "Spiked Sabatons: Immortal Folley",
				Description = "When jumping off a wall, you gain 2 seconds of invincibility.",
				Price = 350,
			},
			{
				Name = "Spiked Sabatons: Flying Kick",
				Description = "After jumping off a wall, pressing shift will execute a <b>flying kick</b>. Flying kick damage scales with distance.",
				Price = 500,
			},
		},
	},

	Stage_2_Perks = {
		["Overcharge"] = {
			{
				Name = "Overcharge: Tier 1",
				Description = "Damage not dealt from picked up weapons adds to overcharge",
				Price = 150,
			},

			{
				Name = "Overcharge: AC/DC",
				Description = "Upon activation: no infinite ammo, +35 crit chance, crits add +1 ammo",
				Price = 200,
			},

			{
				Name = "Overcharge: Perpetual Motion",
				Description = "Dealing crit damage adds 2 points to overcharge, including while overcharge is active",
				Price = 200,
			},
		},

		["Mag_Launcher"] = {
			{
				Name = "Burning Souls: Tier 1",
				Description = "N/A", --"-1 Second cooldown", --@TODO
				Price = 0,
			},
			{
				Name = "Burning Souls: Tier 2",
				Description = "N/A", --"-1 Second cooldown", --@TODO
				Price = 0,
			},
			{
				Name = "Burning Souls: Tier 3",
				Description = "N/A", --"Launcher grenades are now sticky bombs. Sticky bombs explode after a certain time. They will explode early when shot (+1 Dmg, Splash distance) -- Place holder", --@TODO
				Price = 0,
			},
		},

		["Burning_Souls"] = {
			{
				Name = "Burning Souls: Tier 1",
				Description = "N/A", --"-1 Second cooldown", --@TODO
				Price = 0,
			},
			{
				Name = "Burning Souls: Tier 2",
				Description = "N/A", --"+1 Fire Range", --@TODO
				Price = 0,
			},
			{
				Name = "Burning Souls: Tier 3",
				Description = "N/A", --"Cooldown resets when losing a soul -- Place holder", --@TODO
				Price = 0,
			},
		},

		["Galvan_Gaze"] = {
			{
				Name = "Galvan Gaze: Tier 1",
				Description = "N/A", --"No longer requires half health", --@TODO
				Price = 0,
			},

			{
				Name = "Galvan Gaze: Tier 2",
				Description = "N/A", --"-1 Second cooldown", --@TODO
				Price = 0,
			},

			{
				Name = "Galvan Gaze: Tier 3",
				Description = "N/A", --"-5 Second cooldown when at 0 souls -- Place holder", --@TODO
				Price = 0,
			},
		},
	},

	Stage_3_Perks = {
		["Maidenless"] = {
			{
				Name = "Maidenless: Tier 1",
				Description = "N/A", --"+1 armor to maidens blade attack", --@TODO
				Price = 0,
			},

			{
				Name = "Tier A", -- Survival (soul)
				Description = "N/A", --"0.5 Second parry time, 1 second cooldown, enemies killed with the Maiden's Blade have a +20% soul chance.", --@TODO
				Price = 0,
			},

			{
				Name = "Tier B", -- damage (arsenal)
				Description = "N/A", --"2 second cooldown, no longer drops armor, damage dealt from Maiden's blade will always be a crit. Deals <b>soul</b> damage.", --@TODO
				Price = 0,
			},
		},
	},

	["None"] = {
		["None_Tier"] = {
			{
				Name = "???",
				Description = "COMING SOON!",
				Price = 0,
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
