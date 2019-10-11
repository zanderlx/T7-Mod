#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_powerup_for_level()
{
	clientscripts\apex\_zm_powerups::register_basic_powerup("bonfire_sale");
	clientscripts\apex\_zm_powerups::register_timed_powerup("bonfire_sale");
}