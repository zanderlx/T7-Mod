#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("widows", "specialty_widows_wine_zombies");
	maps\apex\_zm_perks::register_perk_bottle("widows", undefined, undefined, 34);
	maps\apex\_zm_perks::register_perk_machine("widows", false, &"ZOMBIE_PERK_WIDOWSWINE", 2000, "p7_zm_vending_widows_wine", "p7_zm_vending_widows_wine_on", "perk_light_red");
	maps\apex\_zm_perks::register_perk_threads("widows", ::give_widows, ::give_take);
	maps\apex\_zm_perks::register_perk_sounds("widows", "mus_perks_widows_sting", "mus_perks_widows_jingle", undefined);

	level.zombiemode_using_widows_perk = true;
}

give_widows()
{
}

give_take(reason)
{
}