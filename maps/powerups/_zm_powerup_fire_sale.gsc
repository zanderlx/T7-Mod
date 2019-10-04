#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("fire_sale", "p7_zm_power_up_firesale");
	maps\_zm_powerups::register_powerup_fx("fire_sale", "powerup_green");
	maps\_zm_powerups::register_powerup_threads("fire_sale", ::func_should_drop_fire_sale, undefined, undefined, undefined);
	maps\_zm_powerups::register_powerup_ui("fire_sale", false, "uie_moto_powerup_fire_sale", "zombie_powerup_fire_sale_on", "zombie_powerup_fire_sale_time");
	maps\_zm_powerups::register_timed_powerup_threads("fire_sale", ::fire_sale_on, ::fire_sale_off, undefined);
}

fire_sale_on()
{
	level notify("powerup fire sale");
	maps\_zombiemode_audio::do_announcer_playvox(level.devil_vox["powerup"]["fire_sale_short"]);
	level.firesale_audio_playing = true;

	if(!isdefined(level.fire_sale_sound_ent))
	{
		level.fire_sale_sound_ent = Spawn("script_origin", (0, 0, 0));
		level.fire_sale_sound_ent PlayLoopSound("mus_fire_sale");
	}

	array_run(level.chests, ::add_temp_firesale_chest);
}

fire_sale_off()
{
	level.firesale_audio_playing = false;
	array_run(level.chests, ::remove_temp_firesale_chest);

	if(isdefined(level.fire_sale_sound_ent))
	{
		level.fire_sale_sound_ent StopLoopSound(2);
		level.fire_sale_sound_ent Delete();
		level.fire_sale_sound_ent = undefined;
	}
}

add_temp_firesale_chest()
{
	if(!self maps\_zm_magicbox::firesale_chest_valid())
		return;
	if(self == level.chests[level.chest_index])
		return;
	
	self.was_temp = true;
	self thread maps\_zm_magicbox::show_chest();
	wait_network_frame();
}

remove_temp_firesale_chest()
{
	if(!self maps\_zm_magicbox::firesale_chest_valid())
		return;
	if(self == level.chests[level.chest_index])
		return;
	if(!is_true(self.was_temp))
		return;
	
	self.was_temp = undefined;
	self thread remove_temp_chest();
	wait_network_frame();
}

remove_temp_chest()
{
	while(isdefined(self.chest_user) || is_true(self._box_open))
	{
		wait_network_frame();
	}

	if(maps\_zm_magicbox::firesale_active())
	{
		self.was_temp = true;
		return;
	}

	PlayFX(level._effect["poltergeist"], self.chest.origin);
	self.chest PlaySound("zmb_box_poof_land");
	self.chest PlaySound("zmb_couch_slam");
	self maps\_zm_magicbox::hide_chest();
}

func_should_drop_fire_sale()
{
	if(maps\_zm_magicbox::firesale_active())
		return false;
	if(level.chest_moves < 1)
		return false;
	return true;
}