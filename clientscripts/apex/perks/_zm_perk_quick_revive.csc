#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("revive");
	clientscripts\apex\_zm_perks::add_perk_specialty("revive", "specialty_quickrevive");
	clientscripts\apex\_zm_perks::register_perk_threads("revive", ::give_revive, ::take_revive);

	level.zombiemode_using_revive_perk = true;
}

give_revive(clientnum)
{
}

take_revive(clientnum)
{
}