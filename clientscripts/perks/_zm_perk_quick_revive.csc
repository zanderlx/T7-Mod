#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("revive", undefined, undefined, undefined, undefined);

	level._effect["revive_light"] = LoadFX("misc/fx_zombie_cola_revive_on");
	level._effect["revive_light_flicker"] = LoadFX("misc/fx_zombie_cola_revive_flicker");
	level.zombiemode_using_revive_perk = true;
}