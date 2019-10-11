#include clientscripts\_utility;
#include clientscripts\apex\_utility;

main()
{
	clientscripts\apex\_utility_code::init_utility();

	clientscripts\apex\_zm_magicbox::init();
	clientscripts\apex\_zm_powerups::init();
	clientscripts\apex\_zm_power::init();
	clientscripts\apex\_zm_perks::init();
	clientscripts\apex\_zm_packapunch::init();
}