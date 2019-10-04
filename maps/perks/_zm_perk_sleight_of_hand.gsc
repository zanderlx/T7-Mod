#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("sleight", "uie_moto_perk_sleight_of_hand", "zombie_perk_bottle_sleight_t7");
	maps\_zm_perks::register_perk_specialty("sleight", "specialty_fastreload");
	maps\_zm_perks::register_perk_machine("sleight", 3000, &"ZOMBIE_PERK_FASTRELOAD", "p7_zm_vending_sleight", "p7_zm_vending_sleight_on", "sleight_light", "mus_perks_speed_sting", "mus_perks_speed_jingle");
	maps\_zm_perks::register_perk_threads("sleight", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("sleight", "zmb_hud_flash_speed");

	level._effect["sleight_light"] = LoadFX("misc/fx_zombie_cola_on");
	level.zombiemode_using_sleightofhand_perk = true;
}