#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("double_points", "p7_zm_power_up_double_points");
	maps\_zm_powerups::register_powerup_fx("double_points", "powerup_green");
	maps\_zm_powerups::register_powerup_threads("double_points", undefined, undefined, undefined, undefined);
	maps\_zm_powerups::register_powerup_ui("double_points", false, "uie_moto_powerup_double_points", "zombie_powerup_point_doubler_on", "zombie_powerup_point_doubler_time");
	maps\_zm_powerups::register_timed_powerup_threads("double_points", ::double_points_on, ::double_points_off, undefined);

	set_zombie_var("zombie_point_scalar", 1);
}

double_points_on()
{
	level notify("powerup points scaled");
	level.zombie_vars["zombie_point_scalar"] = 2;

	if(!isdefined(level.double_points_sound_ent))
	{
		level.double_points_sound_ent = Spawn("script_origin", (0, 0, 0));
		level.double_points_sound_ent PlayLoopSound("zmb_double_point_loop");
	}
}

double_points_off()
{
	PlaySoundAtPosition("zmb_points_loop_off", (0, 0, 0));
	level.zombie_vars["zombie_point_scalar"] = 1;

	if(isdefined(level.double_points_sound_ent))
	{
		level.double_points_sound_ent StopLoopSound(2);
		level.double_points_sound_ent Delete();
		level.double_points_sound_ent = undefined;
	}
}