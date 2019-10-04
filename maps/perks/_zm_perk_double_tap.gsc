#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("doubletap", "uie_moto_perk_double_tap", "zombie_perk_bottle_doubletap_t7");
	maps\_zm_perks::register_perk_specialty("doubletap", "specialty_rof");
	maps\_zm_perks::register_perk_machine("doubletap", 2000, &"ZOMBIE_PERK_DOUBLETAP", "p7_zm_vending_doubletap2", "p7_zm_vending_doubletap2_on", "doubletap_light", "mus_perks_doubletap_sting", "mus_perks_doubletap_jingle");
	maps\_zm_perks::register_perk_threads("doubletap", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("doubletap", undefined);

	level._effect["doubletap_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level.zombiemode_using_doubletap_perk = true;
	OnPlayerConnect_Callback(::player_connect);
}

player_connect()
{
	self SetClientDvar("perk_weapRateEnhanced", 1);
}