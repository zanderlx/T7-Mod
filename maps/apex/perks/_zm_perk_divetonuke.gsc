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

	level.zombiemode_using_divetonuke_perk = true;
}

give_divetonuke()
{
}

take_divetonuke(reason)
{
}