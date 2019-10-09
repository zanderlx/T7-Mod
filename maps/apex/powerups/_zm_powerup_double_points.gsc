#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("double_points", "zombie_x2_icon", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("double_points", undefined, undefined, undefined, maps\apex\_zm_powerups::func_should_always_drop);
	maps\apex\_zm_powerups::register_timed_powerup("double_points", false, "specialty_2x_zombies", "zombie_powerup_double_points_time", "zombie_powerup_double_points_on");
	maps\apex\_zm_powerups::register_timed_powerup_funcs("double_points", ::double_points_start, undefined, ::double_points_stop);
}

double_points_start()
{
	level.zombie_vars["zombie_point_scalar"] = 2;
}

double_points_stop()
{
	level.zombie_vars["zombie_point_scalar"] = 1;
}