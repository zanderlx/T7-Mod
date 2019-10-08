#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("divetonuke");
	clientscripts\apex\_zm_perks::add_perk_specialty("divetonuke", "specialty_flakjacket");
	clientscripts\apex\_zm_perks::register_perk_threads("divetonuke", ::give_divetonuke, ::take_divetonuke);
	level._effect["divetonuke_explode"] = LoadFX("apex/maps/zombie/fx_zmb_phdflopper_exp");
	level.zombiemode_using_divetonuke_perk = true;
	visionset_register_info("divetonuke_explode", "zombie_cosmodrome_diveToNuke", 10, 0, .5, false);
}

give_divetonuke(clientnum)
{
}

take_divetonuke(clientnum)
{
}