#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("bonfire_sale", "p7_zm_power_up_bonfire", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("bonfire_sale", undefined, undefined, undefined, maps\apex\_zm_powerups::func_should_never_drop);
	maps\apex\_zm_powerups::register_timed_powerup("bonfire_sale", false, "zom_icon_bonfire", "zombie_powerup_bonfire_sale_time", "zombie_powerup_bonfire_sale_on");
	maps\apex\_zm_powerups::register_timed_powerup_funcs("bonfire_sale", ::bonfire_sale_start, undefined, ::bonfire_sale_stop);
}

bonfire_sale_start()
{
	level notify("powerup bonfire sale");
	level notify("bonfire_sale_on");
	// mus_packapunch_special - looped on zombie_pentagon teleporters while bonfire active (clientscripts\zombie_pentagon_teleport.csc)

	if(isdefined(level.bonfire_init_func))
		single_thread(level, level.bonfire_init_func);
}

bonfire_sale_stop()
{
	level notify("bonfire_sale_off");
}