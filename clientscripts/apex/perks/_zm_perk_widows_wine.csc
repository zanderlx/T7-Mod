#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("widows");
	clientscripts\apex\_zm_perks::register_perk_threads("widows", ::give_widows, ::take_widows);

	level.zombiemode_using_widows_perk = true;
}

give_widows(clientnum)
{
}

take_widows(clientnum)
{
}