local module = {
	Perks = {
		Hoarder = {
			Icon = "rbxassetid://15990088745",
			Catagories = { "Tactical" },
			Desc = "Picked up guns now have more ammo. (+25%)",
		},

		SpeedRunner = {
			Icon = "rbxassetid://15990088470",
			Catagories = { "Tactical" },
			Desc = "Walking speed is now increased. (+10%)",
		},

		Speed_Demon = {
			Icon = "rbxassetid://107482721361244",
			Catagories = { "Tactical" },
			Desc = "Walking speed is now increased. (+20%)",
		},

		Rabbits_Foot = {
			Icon = "rbxassetid://16205885746",
			Catagories = { "Luck" },
			Desc = "You now permanently have more Luck. (+5 Luck)",
		},

		Kill_Chain = {
			Icon = "rbxassetid://16206090283",
			Catagories = { "Tactical", "Soul" },
			Desc = "Combo time is now increased (+0.5 seconds)",
		},

		Fast_Mags = {
			Icon = "rbxassetid://16235738334",
			Catagories = { "Tactical", "Arsenal" },
			Desc = "Reload speed is now increased. (+25%)",
		},

		Martial_Grace = {
			Icon = "rbxassetid://16275162524",
			Catagories = { "Soul" },
			Desc = "A successful melee parry now has a chance to heal you. (30% chance)",
		},

		["1994"] = {
			Icon = "rbxassetid://16441395151",
			Catagories = { "Arsenal" },
			Desc = "Break action shotguns now shoot more pellets. (+2 Pellets)",
		},

		Double_Shot = {
			Icon = "rbxassetid://16442072158",
			Catagories = { "Arsenal" },
			Desc = "Shots will now have a small chance of firing an additional bullet. (5% chance)",
		},

		Switch_It_Up = {
			Icon = "rbxassetid://16442958701",
			Catagories = { "Arsenal" },
			Desc = "After dealing damage, your first damage with a different source have +1 damage.",
		},

		Tough_Shell = {
			Icon = "rbxassetid://16466911929",
			Catagories = { "Soul" },
			Desc = "Armor now has more resistance. (+100% Armor Resistance)",
		},

		Steel_Souls = {
			Icon = "rbxassetid://16466990226",
			Catagories = { "Soul" },
			Desc = "Souls now have a chance to give armor upon pickup. (20% chance)",
		},

		Boring_Bullets = {
			Icon = "rbxassetid://16442971842",
			Catagories = { "Arsenal" },
			Desc = "You will now deal +1 damage after 10 hits, without missing.",
		},

		Tough_Luck = {
			Icon = "rbxassetid://17590259521",
			Catagories = { "Luck" },
			Desc = "Your health is now bound to Luck. The less health you have, the more Luck you have. (+2 Luck per lost HP)",
		},

		Heavenly_Fortune = {
			Icon = "rbxassetid://17590259189",
			Catagories = { "Luck" },
			Desc = "You now have more Luck while in the air (+5 Luck)",
		},

		Unearthly_Metal = {
			Icon = "rbxassetid://17590259063",
			Catagories = { "Soul" },
			Desc = "Armor now has more resistance. (+200% Armor Resistance)",
		},

		Burn_Hell = {
			Icon = "rbxassetid://18731039717",
			Catagories = { "Arsenal", "Soul" },
			Desc = "Any hits, not from a weapon, now has a chance to deal 1 point of fire damage - lighting the said enemy on fire. (50% chance)",
		},

		-- Freeze_Heaven = { -- unfinished
		-- 	Icon = "rbxassetid://18731039717",
		-- 	Catagories = { "Soul", "Tactical" },
		-- 	Desc = "When inflicting an element, you now have a chance to freeze the enemy (25% chance)",
		-- },

		-- Before_The_Storm = { -- unfinished
		-- 	Icon = "rbxassetid://18731039717",
		-- 	Catagories = { "Tactical" },
		-- 	Desc = "When entering an ambush or arena, combo and ammo will now be refreshed.",
		-- },

		-- Bye_2_Get_1 = { -- unfinished
		-- 	Icon = "rbxassetid://18731039717",
		-- 	Catagories = { "Tactical" },
		-- 	Desc = "Every 2 rolls at the kiosk, the next roll now has a 50% chance to be free.",
		-- },

		-- ["20_Sided_Die"] = { -- unfinished
		-- 	Icon = "rbxassetid://18731039717",
		-- 	Catagories = { "Luck" },
		-- 	Desc = "Thrown weapons now have +20 luck when hitting an enemy.",
		-- },

		-- Returned_Change = { -- unfinished
		-- 	Icon = "rbxassetid://18731039717",
		-- 	Catagories = { "Soul" },
		-- 	Desc = "Vending machines now have a chance to drop a soul upon being destroyed. (10% chance)",
		-- },
	},

	Upgrades = {

		Deadshot = {
			Icon = "rbxassetid://15990088905",
			Catagories = { "Arsenal" },
			Desc = "Shots will now have a small chance of dealing +1 extra damage. (10% chance)",
		},

		Scavenger = {
			Icon = "rbxassetid://15990088593",
			Catagories = { "Tactical" },
			Desc = "Enemies now have a chance to drop ammo, when killed with a picked up weapon. (10% chance)",
		},

		War_Drums = {
			Icon = "rbxassetid://17590259313",
			Catagories = { "Tactical" },
			Desc = "Picked up guns now have more ammo. (+75%)",
		},

		Take_Two = {
			Icon = "rbxassetid://17655099111",
			Catagories = { "Luck" },
			Desc = "You now have a health bound chance for Luck Rolls to be rolled 1 additional time. (+15% chance per health point)",
		},

		["Gambler's_Fallacy"] = {
			Icon = "rbxassetid://17655098782",
			Catagories = { "Luck" },
			Desc = "Every hit on an enemy now increases your Luck by 1. Luck added by this perk is removed on a successful Luck Roll. (Can be stacked 20 times)",
		},

		Echoed_Souls = {
			Icon = "rbxassetid://17655098963",
			Catagories = { "Soul" },
			Desc = "There is now a chance for an enemy to drop two souls upon death. The second soul disappears in 5 seconds. (20% chance)",
		},

		Aggressive_Forgery = {
			Icon = "rbxassetid://18671287606",
			Catagories = { "Soul" },
			Desc = "When your combo is 5 or above, every kill now has a chance to drop armor (10% chance)",
		},

		Life_Steal = {
			Icon = "rbxassetid://18671291054",
			Catagories = { "Soul" },
			Desc = "When at 1 Soul or less, crits will now heal you.",
		},

		Open_Wounds = {
			Icon = "rbxassetid://18671290957",
			Catagories = { "Arsenal" },
			Desc = "Shooting an enemy now has a 10% chance to create a Weak point where you shot. (+2 damage on weak point hit)",
		},

		Tacticool = {
			Icon = "rbxassetid://18715333039",
			Catagories = { "Tactical" },
			Desc = "Weapons can now be reloaded once. (reload time = 5% of the mag size)",
		},

		Iron_Will = {
			Icon = "rbxassetid://16442066458",
			Catagories = { "Soul" },
			Desc = "Reviving now has a chance to not require a soul. (20% chance, unaffected by Luck)",
		},

		Unending_Fortress = {
			Icon = "rbxassetid://17664803510",
			Catagories = { "Soul" },
			Desc = "Upon reviving you now have a chance to be completely armored. (25% chance)",
		},

		["“Do you like hurting?”"] = {
			Icon = "rbxassetid://16339224468",
			Catagories = { "Arsenal" },
			Desc = "Every enemy now has reduced health. (-1 Health)",
		},

		Ricoshot = {
			Icon = "rbxassetid://16050196959",
			Catagories = { "Arsenal" },
			Desc = "Shooting a thrown weapon mid air will now ricochet shots to the nearest enemy with increased damage. (+4 Damage)",
		},

		Mule_Bags = {
			Icon = "rbxassetid://16053616222",
			Catagories = { "Tactical" },
			Desc = "You now have an extra holster for weapons. (Press Q to switch weapons slots)",
		},

		Wax_On = {
			Icon = "rbxassetid://16172646820",
			Catagories = { "Tactical" },
			Desc = "Sliding is now unlocked. (press C or ctrl to slide)",
		},

		Sauce_Is_Fuel = {
			Icon = "rbxassetid://16234651850",
			Catagories = { "Soul" },
			Desc = "You can now absorb blood splotches. Every 20 splotches absorbed will heal 1 HP. (Walk over blood to obsorb)",
		},

		Set_Em_Up = {
			Icon = "rbxassetid://16235430594",
			Catagories = { "Luck" },
			Desc = "Your combo score is now linked to your Luck. (+1 Luck per combo score, Max 20)",
		},

		-- Haven = {
		-- 	Icon = "rbxassetid://16235850238",
		-- 	Catagories = { "Soul" },
		-- 	Desc = "When hit, you now gain 1 second of invincibility.",
		-- },

		Sierra_6308 = {
			Icon = "rbxassetid://16442104214",
			Catagories = { "Tactical", "Soul" },
			Desc = "Enemies will now hesitate to shoot out of fear. (15% chance to cancel a shot)",
		},

		Stuff_Hook = {
			Icon = "rbxassetid://16465804087",
			Catagories = { "Tactical" },
			Desc = "You can now grapple onto any pickups closer than 100 studs and collect it. (E to grapple)",
		},
	},

	Specials = {
		Drav_Is_Dead = {
			Icon = "rbxassetid://16875811404",
			Catagories = {},
			Desc = "Drav has starved to death. (You've killed your friend)",
		},

		TactiAwesome = {
			Icon = "rbxassetid://18715333039",
			Catagories = { "Tactical" },
			Desc = "Weapons can now be reloaded infinitely and will auto reload when ammo is depleted. (reload time = 5% of the mag size)",
		},

		Brick_Hook = {
			Icon = "rbxassetid://16465803959",
			Catagories = { "Tactical" },
			Desc = [[Grapple onto any surface and pull yourself towards it. 

Hitting an enemy with a grapple will give you 1 seconds of invincibility. 

(Left Shift to grapple)]],
		},

		Righteous_Motion = {
			Icon = "rbxassetid://16873872103",
			Catagories = { "Tactical" },
			Desc = [[Quick dash in any direction. Dash has three charges.

The more charges that are used, the longer it takes to recharge.
(Left Shift to dash)]],
		},

		Spiked_Sabatons = {
			Icon = "rbxassetid://16873986562",
			Catagories = { "Tactical" },
			Desc = [[Run next to a wall while in the air to begin wallrunning. 
When jumping off a wall, you will jump in the direction you are looking, 
and will be given extra jump in the air.

+50% movement speed while wallrunning.]],
		},

		["Paladin's_Faith"] = {
			Icon = "rbxassetid://18671027019",
			Catagories = { "Soul" },
			Desc = "At the beginning of each level, you now start with a shield around you. (30 shield health)",
		},

		["Coming_Soon!"] = {
			Icon = "rbxassetid://16422611114",
			Catagories = { "Soul", "Tactical", "Arsenal", "Luck" },
			Desc = "Perk coming soon! (Still planning it out)",
		},

		Mag_Launcher = {
			Icon = "rbxassetid://109605656215662",
			Catagories = { "Arsenal" },
			Desc = [[Fire a magnetic impact grenade that seeks out targets.
Hold down the fire key to lock onto up to 3 enemies.
Each lock reduces the impact damage by 4.

Splash damage: 8
Impact damage: 8

20 second cooldown
(G to fire grenade)]],
		},

		Burning_Souls = {
			Icon = "rbxassetid://80428909931402",
			Catagories = { "Arsenal" },
			Desc = [[Fire a burst of super heated <b>soul fire</b>. 
Any enemy caught in this burst will take 1 damage and be inflicted with <b>soul fire</b>.
When inflicted with <b>soul fire</b>, enemies will take x2 damage.

15 second cooldown
(G to fire <b>soul fire</b>)]],
		},

		Galvan_Gaze = {
			Icon = "rbxassetid://102900540660710",
			Catagories = { "Arsenal" },
			Desc = [[Turn an enemy, below half health, into an iron statue. 
When shooting an iron statue, it will ricoshot to the nearest enemy up to 8 times. 
Each ricochet deals +4 damage.

20 second cooldown
(G to turn an enemy)]],
		},

		Master_Scouting = {
			Icon = "rbxassetid://16274497711",
			Catagories = { "Tactical" },
			Desc = "Double jump is now unlocked. (Press space mid air to double jump)",
		},

		Overcharge = {
			Icon = "rbxassetid://120254924259541",
			Catagories = { "Arsenal" },
			Desc = [[Damage from pistols and the <b>Maiden's Blade</b> now adds to <b>overcharge</b>.
Other weapon damage activates <b>overcharge</b>.
When active, you gain +50% firerate, and infinite ammo for 3 seconds. (20 hits for an <b>overcharge</b>)]],
		},

		Maidenless = {
			Icon = "rbxassetid://16275507396",
			Catagories = { "Arsenal", "Soul" },
			Desc = [[You can now press F to use the <b>Maiden's blade</b>.
If there are no enemies within range, you will perform a parrying block.
If there are enemies, you will perform a parrying attack dealing 1 damage.

Damaging an enemy with the <b>Maiden's blade</b> will drop 1 - 2 armor.
If an enemy is inflicted with an element, 3 - 4 armor will drop.
(1 second parry time, 1.5 second cooldown)
			]],
		},

		Ultra_Slayer = {
			Icon = "rbxassetid://16275507396",
			Catagories = { "Arsenal" },
			Desc = "You can now perform a parrying punch attack. (Right click to melee)",
		},
	},
}

return module
