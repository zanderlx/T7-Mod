#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("fire_sale", "p7_zm_power_up_firesale", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("fire_sale", undefined, undefined, undefined, ::func_should_drop_fire_sale);
	maps\apex\_zm_powerups::register_timed_powerup("fire_sale", false, "specialty_firesale_zombies", "zombie_powerup_fire_sale_time", "zombie_powerup_fire_sale_on");
	maps\apex\_zm_powerups::register_timed_powerup_funcs("fire_sale", ::fire_sale_start, undefined, ::fire_sale_stop);
	maps\apex\_zm_powerups::powerup_set_announcer_vox_type("fire_sale", "fire_sale_short");

	set_zombie_var("zombie_powerup_fire_sale_chest_cost", 10);
}

fire_sale_start()
{
	level notify("powerup fire sale");
	enable_fire_sale_chests();
	level notify("fire_sale_on");
}

fire_sale_stop()
{
	level notify("fire_sale_off");
	disable_fire_sale_chests();
}

enable_fire_sale_chests()
{
	for(i = 0; i < level.chests.size; i++)
	{
		show_firesale_box = run_function(level.chests[i], level._zombiemode_check_firesale_loc_valid_func);

		if(is_true(show_firesale_box))
		{
			level.chests[i].zombie_cost = level.zombie_vars["zombie_powerup_fire_sale_chest_cost"];

			if(level.chest_index != i)
			{
				level.chests[i].was_temp = true;
				level.chests[i] thread maps\apex\_zm_magicbox::show_chest(false);
				wait_network_frame();
			}

			if(!isdefined(level.chests[i].fire_sale_snd_ent))
			{
				level.chests[i].fire_sale_snd_ent = Spawn("script_origin", level.chests[i].origin + (0, 0, 100));
				level.chests[i].fire_sale_snd_ent PlayLoopSound("mus_fire_sale", 1);
			}
		}
	}
}

disable_fire_sale_chests()
{
	for(i = 0; i < level.chests.size; i++)
	{
		show_firesale_box = run_function(level.chests[i], level._zombiemode_check_firesale_loc_valid_func);

		if(is_true(show_firesale_box))
		{
			if(level.chest_index != i && is_true(level.chests[i].was_temp))
			{
				level.chests[i].was_temp = undefined;
				level.chests[i] thread remove_temp_chest();
			}

			level.chests[i].zombie_cost = level.chests[i].old_cost;

			if(isdefined(level.chests[i].fire_sale_snd_ent))
			{
				level.chests[i].fire_sale_snd_ent StopLoopSound();
				level.chests[i].fire_sale_snd_ent Delete();
				level.chests[i].fire_sale_snd_ent = undefined;
			}
		}
	}
}

remove_temp_chest()
{
	while(isdefined(self.chest_user) || is_true(self._box_open))
	{
		wait_network_frame();
	}

	self maps\apex\_zm_magicbox::hide_chest(true);
}

func_should_drop_fire_sale()
{
	if(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) || level.chest_moves < 1 || is_true(level.disable_firesale_drop))
		return false;
	return true;
}