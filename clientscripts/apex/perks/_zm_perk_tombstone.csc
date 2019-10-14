#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("tombstone");
	clientscripts\apex\_zm_perks::register_perk_threads("tombstone", ::give_tombstone, ::take_tombstone);

	clientscripts\apex\_zm_powerups::register_basic_powerup("tombstone");

	level.zombiemode_using_tombstone_perk = true;
}

give_tombstone(clientnum)
{
}

take_tombstone(clientnum)
{
}