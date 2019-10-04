#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("jugg", undefined, undefined, undefined, undefined);

	level._effect["jugger_light"] = LoadFX("misc/fx_zombie_cola_jugg_on");
	level.zombiemode_using_juggernaut_perk = true;
}