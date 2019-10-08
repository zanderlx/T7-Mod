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

	level.zombiemode_using_additionalprimaryweapon_perk = true;
}

give_mule_kick()
{
}

take_mule_kick(reason)
{
}