#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("vulture", "specialty_vulture_zombies");
	maps\apex\_zm_perks::register_perk_bottle("vulture", undefined, undefined, 32);
	maps\apex\_zm_perks::register_perk_machine("vulture", false, &"ZOMBIE_PERK_VULTURE", 2000, "p6_zm_vending_vultureaid", "p6_zm_vending_vultureaid_on", "perk_light_red");
	maps\apex\_zm_perks::register_perk_threads("vulture", ::give_vulture, ::take_vulture);
	maps\apex\_zm_perks::register_perk_sounds("vulture", "mus_perks_vulture_sting", "mus_perks_vulture_jingle", undefined);

	PrecacheModel("p6_zm_perk_vulture_ammo");
	PrecacheModel("p6_zm_perk_vulture_points");
	level.zombiemode_using_vulture_perk = true;
}

give_vulture()
{
}

take_vulture(reason)
{
}