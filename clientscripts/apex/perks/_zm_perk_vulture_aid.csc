#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("vulture");
	clientscripts\apex\_zm_perks::register_perk_threads("vulture", ::give_vulture, ::take_vulture);

	level.zombiemode_using_vulture_perk = true;
}

give_vulture(clientnum)
{
}

take_vulture(clientnum)
{
}