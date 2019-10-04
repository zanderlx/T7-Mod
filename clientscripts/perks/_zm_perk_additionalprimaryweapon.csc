#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("additionalprimaryweapon", undefined, undefined, undefined, undefined);

	level._effect["additionalprimaryweapon_light"] = LoadFX("apex/misc/fx_zombie_cola_arsenal_on");
	level.zombiemode_using_additionalprimaryweapon_perk = true;
}