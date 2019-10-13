#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("mule_kick", "specialty_extraprimaryweapon_zombies");
	maps\apex\_zm_perks::register_perk_bottle("mule_kick", undefined, undefined, 28);
	maps\apex\_zm_perks::register_perk_machine("mule_kick", false, &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON", 4000, "p7_zm_vending_three_gun", "p7_zm_vending_three_gun_on", "perk_light_mule_kick");
	maps\apex\_zm_perks::register_perk_threads("mule_kick", ::give_mule_kick, ::take_mule_kick);
	maps\apex\_zm_perks::register_perk_sounds("mule_kick", "mus_perks_mulekick_sting", "mus_perks_mulekick_jingle", "zmb_hud_flash_additionalprimaryweapon");

	maps\apex\_zm_perks::add_perk_specialty("mule_kick", "specialty_additionalprimaryweapon");
	level._effect["perk_light_mule_kick"] = LoadFX("apex/misc/fx_zombie_cola_arsenal_on");
	level.additionalprimaryweapon_limit = 3;
	level.zombiemode_using_additionalprimaryweapon_perk = true;
	generate_additionalprimaryweapon_spawn_struct();
}

generate_additionalprimaryweapon_spawn_struct()
{
	origin = undefined;
	angles = undefined;

	switch(get_mapname())
	{
		case "zombie_theater":
			origin = (1172.4, -359.7, 320);
			angles = (0, 90, 0);
			break;

		case "zombie_pentagon":
			origin = (-1081.4, 1496.9, -512);
			angles = (0, 162.2, 0);
			break;

		case "zombie_cosmodrome":
			origin = (420.8, 1359.1, 55);
			angles = (0, 270, 0);
			break;

		case "zombie_coast":
			origin = (2424.4, -2884.3, 314);
			angles = (0, 231.6, 0);
			break;

		case "zombie_temple":
			origin = (-1352.9, -1437.2, -485);
			angles = (0, 297.8, 0);
			break;

		case "zombie_moon":
			origin = (1480.8, 3450, -65);
			angles = (0, 180, 0);
			break;

		case "zombie_cod5_prototype":
			origin = (-160, -528, 1);
			angles = (0, 0, 0);
			break;

		case "zombie_cod5_asylum":
			origin = (-91, 540, 64);
			angles = (0, 90, 0);
			break;

		case "zombie_cod5_sumpf":
			origin = (9565, 327, -529);
			angles = (0, 90, 0);
			break;

		case "zombie_cod5_factory":
			origin = (-1089, -1366, 67);
			angles = (0, 90, 0);
			break;
	}

	if(isdefined(origin))
	{
		if(isdefined(angles))
			angles -= (0, 90, 0);

		maps\apex\_zm_perks::generate_perk_spawn_struct("mule_kick", origin, angles);
	}
}

give_mule_kick()
{
}

take_mule_kick(reason)
{
}