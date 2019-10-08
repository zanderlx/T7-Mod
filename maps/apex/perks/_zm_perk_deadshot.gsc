#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("deadshot", "specialty_ads_zombies");
	maps\apex\_zm_perks::register_perk_bottle("deadshot", undefined, undefined, 27);
	maps\apex\_zm_perks::register_perk_machine("deadshot", false, &"ZOMBIE_PERK_DEADSHOT", 1500, "p7_zm_vending_deadshot", "p7_zm_vending_deadshot_on", "perk_light_yellow");
	maps\apex\_zm_perks::register_perk_threads("deadshot", ::give_deadshot, ::take_deadshot);
	maps\apex\_zm_perks::register_perk_sounds("deadshot", "mus_perks_deadshot_sting", "mus_perks_deadshot_jingle", "zmb_hud_flash_deadshot");

	maps\apex\_zm_perks::add_perk_specialty("deadshot", "specialty_deadshot");

	level.zombiemode_using_deadshot_perk = true;
}

give_deadshot()
{
}

take_deadshot(reason)
{
}