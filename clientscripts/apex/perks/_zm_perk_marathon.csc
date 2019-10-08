#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("marathon");
	clientscripts\apex\_zm_perks::add_perk_specialty("marathon", "specialty_longersprint");
	clientscripts\apex\_zm_perks::register_perk_threads("marathon", ::give_marathon, ::take_marathon);
	level._effect["perk_light_marathon"] = LoadFX("apex/maps/zombie/fx_zmb_cola_staminup_on");
	level.zombiemode_using_marathon_perk = true;
}

give_marathon(clientnum)
{
}

take_marathon(clientnum)
{
}