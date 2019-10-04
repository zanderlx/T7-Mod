#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("deadshot", "uie_moto_perk_deadshot", "zombie_perk_bottle_deadshot_t7");
	maps\_zm_perks::register_perk_specialty("deadshot", "specialty_deadshot");
	maps\_zm_perks::register_perk_machine("deadshot", 1500, &"ZOMBIE_PERK_DEADSHOT", "p7_zm_vending_deadshot", "p7_zm_vending_deadshot_on", "deadshot_light", "mus_perks_deadshot_sting", "mus_perks_deadshot_jingle");
	maps\_zm_perks::register_perk_threads("deadshot", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("deadshot", "zmb_hud_flash_deadshot");

	level._effect["deadshot_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level.zombiemode_using_deadshot_perk = true;
}