#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("divetonuke", undefined, undefined, undefined, undefined);

	level._effect["divetonuke_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level._effect["divetonuke_groundhit"] = LoadFX("apex/maps/zombie/fx_zmb_phdflopper_exp");
	level.zombiemode_using_divetonuke_perk = true;

	add_level_notify_callback("divetonuke_vision", ::zombie_dive2nuke_visionset);
	clientscripts\_visionset_mgr::visionset_register("zombie_cosmodrome_diveToNuke", 11, .5);
}

zombie_dive2nuke_visionset(clientnum)
{
	clientscripts\_visionset_mgr::visionset_apply(clientnum, "zombie_cosmodrome_diveToNuke");
	RealWait(.5);
	clientscripts\_visionset_mgr::visionset_remove(clientnum, "zombie_cosmodrome_diveToNuke");
}