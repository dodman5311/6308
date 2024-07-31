local module = {
	Perks = {
		Scavenger = {
			Icon = "rbxassetid://15990088593",
			Catagories = { "Tactical" },
			Desc = "Enemies now have a chance to drop ammo, when killed with a picked up weapon. (15% chance)",
		},

		Deadshot = {
			Icon = "rbxassetid://15990088905",
			Catagories = { "Arsenal" },
			Desc = "Shots will now have a small chance of dealing +1 extra damage. (10% chance)",
		},

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
			Icon = "rbxassetid://15990088470",
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
			Desc = "Combo time is now increased (+1 seconds)",
		},

		Fast_Mags = {
			Icon = "rbxassetid://16235738334",
			Catagories = { "Arsenal" },
			Desc = "Reload speed is now increased. (+50%)",
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
			Desc = "After dealing damage, damage from a different source will now have more damage. (+1 damage)",
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
			Desc = "You will now deal more damage after 10 hits, without missing. (+1 damage)",
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
			Desc = "Any damage, not dealt by a weapon, now has a chance to set enemies of fire. (50% chance)",
		},
	},

	Upgrades = {

		War_Drums = {
			Icon = "rbxassetid://17590259313",
			Catagories = { "Tactical" },
			Desc = "Picked up guns now have more ammo. (+75%)",
		},

		Take_Two = {
			Icon = "rbxassetid://17655099111",
			Catagories = { "Luck" },
			Desc = "While at 1 HP, Luck Rolls are now rolled 1 additional time for a better outcome. (Kiosk rewards are excluded)",
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

		---

		["Paladin's_Faith"] = { -- done
			Icon = "rbxassetid://18671027019",
			Catagories = { "Soul" },
			Desc = "At the beginning of each level, you now start with a shield around you. (30 shield health)",
		},

		Aggressive_Forgery = { -- done
			Icon = "rbxassetid://18671287606",
			Catagories = { "Soul" },
			Desc = "When your combo is 5 or above, every kill now has a chance to drop armor (10% chance)",
		},

		Life_Steal = { -- done
			Icon = "rbxassetid://18671291054",
			Catagories = { "Soul" },
			Desc = "When at 0 Souls, hits now have a chance to heal you. (15% chance)",
		},

		Open_Wounds = { -- done
			Icon = "rbxassetid://18671290957",
			Catagories = { "Arsenal" },
			Desc = "Shooting an enemy now has a 10% chance to create a Weak point where you shot. (+2 damage on weak point hit)",
		},

		Tacticool = { -- done
			Icon = "rbxassetid://18715333039",
			Catagories = { "Tactical" },
			Desc = "Weapons can now be reloaded once. (reload time = 5% of the mag size)",
		},

		--

		Master_Scouting = {
			Icon = "rbxassetid://16274497711",
			Catagories = { "Tactical" },
			Desc = "Double jump is now unlocked. (Press space mid air to double jump)",
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
			Desc = "You can now absorb blood splotches. Every 25 splotches absorbed will heal 1 HP. (Walk over blood to obsorb)",
		},

		Set_Em_Up = {
			Icon = "rbxassetid://16235430594",
			Catagories = { "Luck" },
			Desc = "Your combo score is now linked to your Luck. (+1 Luck per combo score)",
		},

		Haven = {
			Icon = "rbxassetid://16235850238",
			Catagories = { "Soul" },
			Desc = "When hit, you now gain 1 second of invincibility.",
		},

		Ultra_Slayer = {
			Icon = "rbxassetid://16275507396",
			Catagories = { "Arsenal" },
			Desc = "You can now perform a parrying punch attack. (Right click to melee)",
		},

		Overcharge = {
			Icon = "rbxassetid://18415380600",
			Catagories = { "Arsenal" },
			Desc = "Every hit on an enemy, now adds to your <b>overcharge</b> meter. When <b>overcharge</b> is full, you are granted +50% firerate, and infinite ammo for 3 seconds. (30 hits for an <b>overcharge</b>)",
		},

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

		TactiAwesome = { -- done
			Icon = "rbxassetid://18715333039",
			Catagories = { "Tactical" },
			Desc = "Weapons can now be reloaded infinitely and will auto reload when ammo is depleted. (reload time = 5% of the mag size)",
		},

		Brick_Hook = {
			Icon = "rbxassetid://16465803959",
			Catagories = { "Tactical" },
			Desc = [[Grapple onto any surface and pull yourself towards it. Grappling an enemy will deal 1 damage and give you 1 second on invincibility. 1 second cooldown.
(Left Shift to grapple)]],
		},

		Righteous_Motion = {
			Icon = "rbxassetid://16873872103",
			Catagories = { "Tactical" },
			Desc = [[Quick dash in any direction. Dash has three charges. 
The more charges that are used, the longer it takes to refresh the charges.
(Left Shift to dash)]],
		},

		Spiked_Sabatons = {
			Icon = "rbxassetid://16873986562",
			Catagories = { "Tactical" },
			Desc = [[Run next to a wall while in the air to begin wallrunning. 
When jumping off a wall, you will be given another jump in the air.]],
		},
	},
}

return module
