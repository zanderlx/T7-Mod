#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("marathon", "specialty_marathon_zombies");
	maps\apex\_zm_perks::register_perk_bottle("marathon", undefined, undefined, 25);
	maps\apex\_zm_perks::register_perk_machine("marathon", &"ZOMBIE_PERK_MARATHON", 2000, "p7_zm_vending_marathon", "p7_zm_vending_marathon_on", "perk_light_marathon");
	maps\apex\_zm_perks::register_perk_threads("marathon", ::give_marathon, ::take_marathon);
	maps\apex\_zm_perks::register_perk_sounds("marathon", "mus_perks_stamin_sting", "mus_perks_stamin_jingle", "zmb_hud_flash_stamina");

	maps\apex\_zm_perks::add_perk_specialty("marathon", "specialty_longersprint");
	level._effect["perk_light_marathon"] = LoadFX("apex/maps/zombie/fx_zmb_cola_staminup_on");

	level.zombiemode_using_marathon_perk = true;
}

give_marathon()
{
}

take_marathon(reason)
{
}