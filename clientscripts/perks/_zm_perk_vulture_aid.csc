#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("vulture", undefined, undefined, undefined, undefined);

	level._effect["vulture_light"] = LoadFX("misc/fx_zombie_cola_jugg_on");
	level.zombiemode_using_vulture_perk = true;
}