#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("deadshot");
	clientscripts\apex\_zm_perks::add_perk_specialty("deadshot", "specialty_deadshot");
	clientscripts\apex\_zm_perks::register_perk_threads("deadshot", ::give_deadshot, ::take_deadshot);

	level.zombiemode_using_deadshot_perk = true;
}

give_deadshot(clientnum)
{
}

take_deadshot(clientnum)
{
}