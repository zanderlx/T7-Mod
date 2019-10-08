#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("speed_cola", "specialty_fastreload_zombies");
	maps\apex\_zm_perks::register_perk_bottle("speed_cola", undefined, undefined, 21);
	maps\apex\_zm_perks::register_perk_machine("speed_cola", false, &"ZOMBIE_PERK_FASTRELOAD", 3000, "p7_zm_vending_sleight", "p7_zm_vending_sleight_on", "perk_light_green");
	maps\apex\_zm_perks::register_perk_threads("speed_cola", ::give_speed, ::take_speed);
	maps\apex\_zm_perks::register_perk_sounds("speed_cola", "mus_perks_speed_sting", "mus_perks_speed_jingle", "zmb_hud_flash_speed");

	maps\apex\_zm_perks::add_perk_specialty("speed_cola", "specialty_fastreload");

	level.zombiemode_using_sleightofhand_perk = true;
}

give_speed()
{
}

take_speed(reason)
{
}