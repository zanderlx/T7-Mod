#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("marathon", undefined, undefined, undefined, undefined);

	level._effect["marathon_light"] = LoadFX("apex/maps/zombie/fx_zmb_cola_staminup_on");
	level.zombiemode_using_marathon_perk = true;
}