#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("doubletap", undefined, undefined, undefined, undefined);

	level._effect["doubletap_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level.zombiemode_using_doubletap_perk = true;

	// perk_weapRateEnhanced - game_mod dvar to enable double tap 2
}