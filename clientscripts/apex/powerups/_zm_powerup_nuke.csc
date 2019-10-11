#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_powerup_for_level()
{
	clientscripts\apex\_zm_powerups::register_basic_powerup("nuke");
	level._effect["powerup_nuke_explosion"] = LoadFX("misc/fx_zombie_mini_nuke");
}