#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	if(is_solo_game())
	{
		cost = 500;
		hint = &"ZOMBIE_PERK_QUICKREVIVE_SOLO";
	}
	else
	{
		cost = 1500;
		hint = &"ZOMBIE_PERK_QUICKREVIVE";
	}

	maps\apex\_zm_perks::register_perk("revive", "specialty_quickrevive_zombies");
	maps\apex\_zm_perks::register_perk_bottle("revive", undefined, undefined, 22);
	maps\apex\_zm_perks::register_perk_machine("revive", hint, cost, "p7_zm_vending_revive", "p7_zm_vending_revive_on", "perk_light_blue");
	maps\apex\_zm_perks::register_perk_threads("revive", ::give_revive, ::take_revive);
	maps\apex\_zm_perks::register_perk_sounds("revive", "mus_perks_revive_sting", "mus_perks_revive_jingle", "zmb_hud_flash_revive");

	maps\apex\_zm_perks::add_perk_specialty("revive", "specialty_quickrevive");

	level.zombiemode_using_revive_perk = true;
}

give_revive()
{
}

take_revive(reason)
{
}