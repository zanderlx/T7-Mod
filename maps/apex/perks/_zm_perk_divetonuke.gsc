#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("divetonuke", "specialty_divetonuke_zombies");
	maps\apex\_zm_perks::register_perk_bottle("divetonuke", undefined, undefined, 24);
	maps\apex\_zm_perks::register_perk_machine("divetonuke", &"ZOMBIE_PERK_DIVETONUKE", 2000, "p7_zm_vending_nuke", "p7_zm_vending_nuke_on", "perk_light_yellow");
	maps\apex\_zm_perks::register_perk_threads("divetonuke", ::give_divetonuke, ::take_divetonuke);
	maps\apex\_zm_perks::register_perk_sounds("divetonuke", "mus_perks_phd_sting", "mus_perks_phd_jingle", "zmb_hud_flash_phd");

	maps\apex\_zm_perks::add_perk_specialty("divetonuke", "specialty_flakjacket");
	level._effect["divetonuke_explode"] = LoadFX("apex/maps/zombie/fx_zmb_phdflopper_exp");

	level.zombiemode_divetonuke_perk_func = ::divetonuke_explode;
	level.zombiemode_using_divetonuke_perk = true;

	set_zombie_var("zombie_perk_divetonuke_radius", 300);
	set_zombie_var("zombie_perk_divetonuke_min_damage", 1000);
	set_zombie_var("zombie_perk_divetonuke_max_damage", 5000);
}

give_divetonuke()
{
}

take_divetonuke(reason)
{
}

divetonuke_explode(attacker, origin)
{
	RadiusDamage(origin, level.zombie_vars["zombie_perk_divetonuke_radius"], level.zombie_vars["zombie_perk_divetonuke_max_damage"], level.zombie_vars["zombie_perk_divetonuke_min_damage"], attacker, "MOD_GRENADE_SPLASH");
	PlayFX(level._effect["divetonuke_explode"], origin);
	attacker PlaySound("zmb_phdflop_explo");
	attacker visionset_activate("divetonuke_explode");
	wait_network_frame();
	wait_network_frame();
	attacker visionset_deactivate("divetonuke_explode");
}