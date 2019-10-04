#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("vulture", "uie_moto_perk_vulture", "zombie_perk_bottle_vultureaid_t7");
	maps\_zm_perks::register_perk_machine("vulture", 2000, &"ZOMBIE_PERK_VULTURE", "p6_zm_vending_vultureaid", "p6_zm_vending_vultureaid_on", "vulture_light", "mus_perks_vulture_sting", "mus_perks_vulture_jingle");
	maps\_zm_perks::register_perk_threads("vulture", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("vulture", undefined);

	level._effect["vulture_light"] = LoadFX("misc/fx_zombie_cola_jugg_on");
	level.zombiemode_using_vulture_perk = true;
}