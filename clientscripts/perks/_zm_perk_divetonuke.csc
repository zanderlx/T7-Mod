#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("divetonuke", undefined, undefined, undefined, undefined);

	level._effect["divetonuke_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level._effect["divetonuke_groundhit"] = LoadFX("apex/maps/zombie/fx_zmb_phdflopper_exp");
	level.zombiemode_using_divetonuke_perk = true;

	add_level_notify_callback("divetonuke_vision", ::zombie_dive2nuke_visionset);
}

zombie_dive2nuke_visionset(clientnum)
{
	player = GetLocalPlayer(clientnum);
	player thread clientscripts\_zombiemode::zombie_vision_set_apply("zombie_cosmodrome_diveToNuke", 11, 0, clientnum);
	RealWait(.5);
	player thread clientscripts\_zombiemode::zombie_vision_set_remove("zombie_cosmodrome_diveToNuke", .5, clientnum);
}