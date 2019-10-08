#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("jugg", "specialty_juggernaut_zombies");
	maps\apex\_zm_perks::register_perk_bottle("jugg", undefined, undefined, 20);
	maps\apex\_zm_perks::register_perk_machine("jugg", false, &"ZOMBIE_PERK_JUGGERNAUT", 2500, "p7_zm_vending_jugg", "p7_zm_vending_jugg_on", "perk_light_red");
	maps\apex\_zm_perks::register_perk_threads("jugg", ::give_jugg, ::take_jugg);
	maps\apex\_zm_perks::register_perk_sounds("jugg", "mus_perks_jugganog_sting", "mus_perks_jugganog_jingle", "zmb_hud_flash_jugga");

	maps\apex\_zm_perks::add_perk_specialty("jugg", "specialty_armorvest");

	set_zombie_var("zombie_perk_juggernaut_health", 160);
	set_zombie_var("zombie_perk_juggernaut_health_upgrade", 190);

	level.zombiemode_using_juggernaut_perk = true;
}

give_jugg()
{
}

take_jugg(reason)
{
}