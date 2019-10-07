#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("jugg");
	clientscripts\apex\_zm_perks::add_perk_specialty("jugg", "specialty_armorvest");
	clientscripts\apex\_zm_perks::register_perk_threads("jugg", ::give_jugg, ::take_jugg);

	level.zombiemode_using_juggernog_perk = true;
}

give_jugg(clientnum)
{
}

take_jugg(clientnum)
{
}