#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("divetonuke", undefined, undefined, undefined, undefined);

	level._effect["divetonuke_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level._effect["divetonuke_groundhit"] = LoadFX("apex/maps/zombie/fx_zmb_phdflopper_exp");
	level.zombiemode_using_divetonuke_perk = true;

	clientscripts\_visionset_mgr::visionset_register_info("divetonuke_vision", "zombie_cosmodrome_diveToNuke", 4, 0, .5, false);
}