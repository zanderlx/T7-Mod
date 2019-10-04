#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("tombstone", undefined, undefined, undefined, undefined);

	level._effect["tombstone_light"] = LoadFX("misc/fx_zombie_cola_on");
	level.zombiemode_using_tombstone_perk = true;
}