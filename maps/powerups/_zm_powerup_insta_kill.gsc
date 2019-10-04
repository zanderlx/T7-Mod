#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("insta_kill", "p7_zm_power_up_insta_kill");
	maps\_zm_powerups::register_powerup_fx("insta_kill", "powerup_green");
	maps\_zm_powerups::register_powerup_threads("insta_kill", undefined, undefined, undefined, undefined);
	maps\_zm_powerups::register_powerup_ui("insta_kill", false, "uie_moto_powerup_insta_kill", "zombie_powerup_insta_kill_on", "zombie_powerup_insta_kill_time");
	maps\_zm_powerups::register_timed_powerup_threads("insta_kill", ::insta_kill_on, ::insta_kill_off);

	set_zombie_var("zombie_insta_kill", false);

	level._zm_check_for_instakill_func = ::check_for_insta_kill;
}

insta_kill_on()
{
	level notify("powerup instakill");
	level.zombie_vars["zombie_insta_kill"] = true;

	if(!isdefined(level.insta_kill_sound_ent))
	{
		level.insta_kill_sound_ent = Spawn("script_origin", (0, 0, 0));
		level.insta_kill_sound_ent PlayLoopSound("zmb_insta_kill_loop");
	}
}

insta_kill_off()
{
	level.zombie_vars["zombie_insta_kill"] = false;
	PlaySoundAtPosition("zmb_insta_kill", (0, 0, 0));

	if(isdefined(level.insta_kill_sound_ent))
	{
		level.insta_kill_sound_ent StopLoopSound(2);
		level.insta_kill_sound_ent Delete();
		level.insta_kill_sound_ent = undefined;
	}
}

check_for_insta_kill(player, mod, hit_location)
{
	if(isdefined(player) && IsPlayer(player) && IsAlive(player))
	{
		if(!player player_has_insta_kill())
			return;
		if(is_magic_bullet_shield_enabled(self))
			return;
		
		if(isdefined(self.instakill_func))
		{
			single_thread(self, self.instakill_func);
			return;
		}

		modname = remove_mod_from_methodofdeath(mod);

		if(!is_true(self.no_gib) && !is_true(self.isdog))
			self maps\_zombiemode_spawner::zombie_head_gib();
		
		self DoDamage(self.health * 10, self.origin, player, undefined, modname, hit_location);
		player notify("zombie_killed");
	}
}

player_has_insta_kill()
{
	if(is_true(level.zombie_vars["zombie_insta_kill"]))
		return true;
	if(is_true(self.personal_insta_kill))
		return true;
	return false;
}