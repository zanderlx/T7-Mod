#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("speed_cola");
	clientscripts\apex\_zm_perks::add_perk_specialty("speed_cola", "specialty_fastreload");
	clientscripts\apex\_zm_perks::register_perk_threads("speed_cola", ::give_speed, ::take_speed);

	level.zombiemode_using_sleightofhand_perk = true;
}

give_speed(clientnum)
{
}

take_speed(clientnum)
{
}