#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_powerup_for_level()
{
	clientscripts\apex\_zm_powerups::register_basic_powerup("tesla");
	clientscripts\apex\_zm_powerups::register_timed_powerup("tesla");
	clientscripts\apex\_zm_powerups::register_powerup_weapon("tesla", "tesla_gun_zm");
}