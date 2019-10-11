#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_powerup_for_level()
{
	clientscripts\apex\_zm_powerups::register_basic_powerup("bonus_points_player");
	clientscripts\apex\_zm_powerups::register_basic_powerup("bonus_points_team");
}