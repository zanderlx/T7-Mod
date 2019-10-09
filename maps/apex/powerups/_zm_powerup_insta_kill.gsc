#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("insta_kill", "zombie_skull", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("insta_kill", undefined, undefined, undefined, maps\apex\_zm_powerups::func_should_always_drop);
	maps\apex\_zm_powerups::register_timed_powerup("insta_kill", false, "specialty_instakill_zombies", "zombie_powerup_insta_kill_time", "zombie_powerup_insta_kill_on");
	maps\apex\_zm_powerups::register_timed_powerup_funcs("insta_kill", ::insta_kill_start, undefined, ::insta_kill_stop);

	set_zombie_var("zombie_insta_kill", false);
}

insta_kill_start()
{
	level.zombie_vars["zombie_insta_kill"] = true;
}

insta_kill_stop()
{
	level.zombie_vars["zombie_insta_kill"] = false;
}