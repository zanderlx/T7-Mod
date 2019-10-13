#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("tesla", "p7_zm_power_up_minigun", "powerup_blue");
	maps\apex\_zm_powerups::register_powerup_funcs("tesla", undefined, undefined, undefined, maps\apex\_zm_powerups::func_should_never_drop);
	maps\apex\_zm_powerups::register_timed_powerup("tesla", true, "zom_icon_minigun", "zombie_powerup_tesla_time", "zombie_powerup_tesla_on");
	maps\apex\_zm_powerups::register_timed_powerup_funcs("tesla", undefined, undefined, undefined);
	maps\apex\_zm_powerups::register_powerup_weapon("tesla", "tesla_gun_zm");
}