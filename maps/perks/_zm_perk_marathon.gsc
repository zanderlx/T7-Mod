#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("marathon", "uie_moto_perk_marathon", "zombie_perk_bottle_marathon_t7");
	maps\_zm_perks::register_perk_specialty("marathon", "specialty_longersprint");
	maps\_zm_perks::register_perk_machine("marathon", 2000, &"ZOMBIE_PERK_MARATHON", "p7_zm_vending_marathon", "p7_zm_vending_marathon_on", "marathon_light", "mus_perks_stamin_sting", "mus_perks_stamin_jingle");
	maps\_zm_perks::register_perk_threads("marathon", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("marathon", "zmb_hud_flash_stamina");

	level._effect["marathon_light"] = LoadFX("apex/maps/zombie/fx_zmb_cola_staminup_on");
	level.zombiemode_using_marathon_perk = true;
}