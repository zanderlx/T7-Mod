#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_powerup_for_level()
{
	clientscripts\apex\_zm_powerups::register_basic_powerup("lose_points_team");
	clientscripts\apex\_zm_powerups::register_basic_powerup("lose_points_player"); // TODO: powerup_<>? bad powerup that affects grabber, what color to use?
}