#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("doubletap");
	clientscripts\apex\_zm_perks::add_perk_specialty("doubletap", "specialty_rof");
	clientscripts\apex\_zm_perks::register_perk_threads("doubletap", ::give_doubletap, ::take_doubletap);

	level.zombiemode_using_doubletap_perk = true;
}

give_doubletap(clientnum)
{
}

take_doubletap(clientnum)
{
}