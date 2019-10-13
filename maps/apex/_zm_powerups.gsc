#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	include_powerups();
	precache_powerups();
	init_powerups();
	level thread watch_for_drop();
}

init_powerups()
{
	flag_init("zombie_drop_powerups", true);

	if(!isdefined(level.active_powerups))
		level.active_powerups = [];

	level.zombie_powerup_array = get_valid_powerup_array();
	randomize_powerups();
	level.zombie_powerup_index = 0;
	level.powerup_drop_count = 0;
	level thread init_powerup_zombie_vars();
	level thread powerup_round_watcher();
}

include_powerups()
{
	if(!isdefined(level._zm_powerup_includes))
		level._zm_powerup_includes = ::default_include_powerups;

	set_zombie_var("zombie_point_scalar", 1); // TODO: Move to score script
	set_zombie_var("zombie_drop_item", false);
	set_zombie_var("zombie_powerup_drop_increment", 2000);
	set_zombie_var("zombie_powerup_drop_max_per_round", 4);
	set_zombie_var("zombie_powerup_active_time", 30);
	set_zombie_var("zombie_powerup_weapons_allow_cycling", true);

	run_function(level, level._zm_powerup_includes);
}

precache_powerups()
{
	level._effect["powerup_green_on"] = LoadFX("misc/fx_zombie_powerup_on");
	level._effect["powerup_green_grabbed"] = LoadFX("misc/fx_zombie_powerup_grab");
	level._effect["powerup_green_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_wave");
	level._effect["powerup_red_on"] = LoadFX("misc/fx_zombie_powerup_on_red");
	level._effect["powerup_red_grabbed"] = LoadFX("misc/fx_zombie_powerup_red_grab");
	level._effect["powerup_red_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_red_wave");
	level._effect["powerup_blue_on"] = LoadFX("misc/fx_zombie_powerup_solo_on");
	level._effect["powerup_blue_grabbed"] = LoadFX("misc/fx_zombie_powerup_solo_grab");
	level._effect["powerup_blue_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_solo_wave");
	level._effect["powerup_yellow_on"] = LoadFX("misc/fx_zombie_powerup_caution_on");
	level._effect["powerup_yellow_grabbed"] = LoadFX("misc/fx_zombie_powerup_caution_grab");
	level._effect["powerup_yellow_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_caution_wave");

	powerup_names = get_valid_powerup_array();

	for(i = 0; i < powerup_names.size; i++)
	{
		powerup_name = powerup_names[i];

		PrecacheModel(level.zombie_powerups[powerup_name].model);

		if(is_timed_powerup(powerup_name))
			PrecacheShader(level.zombie_powerups[powerup_name].client_field_name); // client_field_name is used to store the shader material
		if(is_weapon_powerup(powerup_name))
			PrecacheItem(level.zombie_powerup_weapon[powerup_name]);
	}
}

default_include_powerups()
{
	// T4
	maps\apex\powerups\_zm_powerup_full_ammo::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_insta_kill::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_double_points::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_carpenter::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_nuke::include_powerup_for_level();

	// T5
	maps\apex\powerups\_zm_powerup_fire_sale::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_minigun::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_bonfire_sale::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_tesla::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_bonus_points::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_free_perk::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_random_weapon::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_empty_clip::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_lose_perk::include_powerup_for_level();
	maps\apex\powerups\_zm_powerup_lose_points::include_powerup_for_level();
}

init_powerup_zombie_vars()
{
	flag_wait("all_players_connected");
	waittillframeend;
	players = GetPlayers();
	powerup_names = get_valid_powerup_array();
	timed_powerups = [];

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isdefined(player.has_specific_powerup_weapon))
			player.has_specific_powerup_weapon = [];
		if(!isdefined(player.zombie_vars))
			player.zombie_vars = [];

		for(j = 0; j < powerup_names.size; j++)
		{
			powerup_name = powerup_names[j];

			if(!is_timed_powerup(powerup_name))
				continue;

			time_name = level.zombie_powerups[powerup_name].time_name;
			on_name = level.zombie_powerups[powerup_name].on_name;

			if(is_true(level.zombie_powerups[powerup_name].hud_per_player))
			{
				player.zombie_vars[time_name] = 0;
				player.zombie_vars[on_name] = false;
			}
			else
			{
				if(!isdefined(level.zombie_vars[time_name]))
					set_zombie_var(time_name, 0);
				if(!isdefined(level.zombie_vars[on_name]))
					set_zombie_var(on_name, false);
			}

			if(!IsInArray(timed_powerups, powerup_name))
				timed_powerups[timed_powerups.size] = powerup_name;
		}
	}

	level thread powerup_hud_monitor(timed_powerups);
}

powerup_round_watcher()
{
	level endon("end_game");

	for(;;)
	{
		level waittill("start_of_round");
		level.powerup_drop_count = 0;
	}
}

//============================================================================================
// Logic
//============================================================================================
specific_powerup_drop(powerup_name, origin, powerup_player, can_timeout)
{
	if(!is_powerup_valid(powerup_name))
		return undefined;

	powerup = spawn_model(level.zombie_powerups[powerup_name].model, origin, (0, 0, 0));
	powerup powerup_drop_setup(powerup_name, powerup_player, can_timeout);
	return powerup;
}

powerup_drop_setup(powerup_name, powerup_player, can_timeout)
{
	if(!isdefined(powerup_name))
		powerup_name = get_random_powerup_name();
	if(!isdefined(powerup_player))
		powerup_player = level;
	if(!isdefined(can_timeout))
		can_timeout = true;

	Assert(is_powerup_valid(powerup_name));

	self.powerup_name = powerup_name;
	self.powerup_player = powerup_player;

	self SetModel(level.zombie_powerups[powerup_name].model);

	if(isdefined(level.zombie_powerups[powerup_name].func_setup))
		run_function(self, level.zombie_powerups[powerup_name].func_setup);

	PlaySoundAtPosition("zmb_spawn_powerup", self.origin);
	self PlayLoopSound("zmb_spawn_powerup_loop");

	if(is_true(can_timeout))
		self thread powerup_timeout_think();

	self thread powerup_fx();
	self thread powerup_wobble();
	self thread powerup_grab_think();
	self thread powerup_cleanup();

	level notify("powerup_dropped", self);
	level.active_powerups[level.active_powerups.size] = self;
}

powerup_fx()
{
	self endon("death");

	if(isdefined(level.powerup_fx_func))
	{
		single_thread(self, level.powerup_fx_func);
		return;
	}

	powerup_fx = "powerup_green";

	if(isdefined(level.zombie_powerups[self.powerup_name].powerup_fx))
		powerup_fx = level.zombie_powerups[self.powerup_name].powerup_fx;

	PlayFXOnTag(level._effect[powerup_fx + "_on"], self, "tag_origin");
}

powerup_wobble()
{
	self endon("powerup_grabbed");
	self endon("powerup_timedout");
	self endon("powerup_cleanup");
	self endon("death");

	for(;;)
	{
		waittime = RandomFloatRange(2.5, 5);
		yaw = RandomInt(360);

		if(yaw > 300)
			yaw = 300;
		else if(yaw < 60)
			yaw = 60;

		yaw = self.angles[1] + yaw;
		new_angles = (-60 + RandomInt(120), yaw, -45 + RandomInt(90));
		self RotateTo(new_angles, waittime, waittime * .5, waittime * .5);
		wait RandomFloat(waittime - .1);
	}
}

powerup_fx_grabbed()
{
	powerup_fx = "powerup_green";

	if(isdefined(level.zombie_powerups[self.powerup_name].powerup_fx))
		powerup_fx = level.zombie_powerups[self.powerup_name].powerup_fx;

	PlayFX(level._effect[powerup_fx + "_grabbed"], self.origin);
	PlayFX(level._effect[powerup_fx + "_grabbed_wave"], self.origin);
}

powerup_grab_think()
{
	self endon("powerup_timedout");
	self endon("powerup_cleanup");
	self endon("death");

	for(;;)
	{
		wait .1;

		if(isdefined(level.powerup_grab_get_players_override))
			players = run_function(level, level.powerup_grab_get_players_override);
		else
			players = GetPlayers();

		if(!isdefined(players) || players.size == 0)
			continue;

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isdefined(self.powerup_player) && IsPlayer(self.powerup_player) && self.powerup_player != player)
				continue;
			else if(isdefined(self.owner) && IsPlayer(self.owner) && self.owner != player)
				continue;

			// dont pickup if drinking and told not to
			if(player is_drinking() && is_true(level.zombie_powerups[self.powerup_name].prevent_pick_up_if_drinking))
				continue;
			// dont pickup if in laststand and told not to
			if(player maps\_laststand::player_is_in_laststand() && !is_true(level.zombie_powerups[self.powerup_name].can_pick_up_in_last_stand))
				continue;
			// dont pickup if either of the following and told not to pickup in revive triggers
			// in laststand (revive trigger spawned as your downed player)
			// revive trigger && UseButton pressed (attempting to revive downed player)
			if((player maps\_laststand::player_is_in_laststand() || (player UseButtonPressed() && player in_revive_trigger())) && !is_true(level.zombie_powerups[self.powerup_name].can_pick_up_in_revive_trigger))
				continue;
			// dont pickup if powerup is weapon type and player has powerup weapon
			if(is_weapon_powerup(self.powerup_name) && player has_powerup_weapon())
				continue;

			if(DistanceSquared(player.origin, self.origin) < 4096)
			{
				if(isdefined(level._powerup_grab_check))
				{
					result = run_function(self, level._powerup_grab_check, player);

					if(!is_true(result))
						continue;
				}

				if(isdefined(level.zombie_powerups[self.powerup_name].func_grabbed))
				{
					result = run_function(self, level.zombie_powerups[self.powerup_name].func_grabbed, player);

					if(is_true(result))
						continue;
				}
				else
				{
					if(isdefined(level._zombiemode_powerup_grab))
						single_thread(self, level._zombiemode_powerup_grab, self, player);
				}

				self powerup_fx_grabbed();

				if(isdefined(self.grabbed_level_notify))
					level notify(self.grabbed_level_notify, player);

				self.claimed = true;
				self.power_up_grab_player = player;
				player thread powerup_vo(self.powerup_name);

				if(is_timed_powerup(self.powerup_name))
					player thread timed_powerup_think(self.powerup_name);

				wait .1;
				PlaySoundAtPosition("zmb_powerup_grabbed", self.origin);
				self notify("powerup_grabbed");
			}
		}
	}
}

powerup_timeout_think()
{
	self endon("powerup_grabbed");
	self endon("powerup_cleanup");
	self endon("death");

	if(isdefined(level._powerup_timeout_override))
	{
		single_thread(self, level._powerup_timeout_override);
		return;
	}

	self powerup_show(true);
	wait_time = 15;

	if(isdefined(level._powerup_timeout_custom_time))
	{
		time = run_function(self, level._powerup_timeout_custom_time, self);

		if(isdefined(time))
		{
			if(time == 0)
				return;
			wait_time = time;
		}
	}

	wait wait_time;

	for(i = 0; i < 40; i++)
	{
		if(i % 2)
			self powerup_show(false);
		else
			self powerup_show(true);

		if(i < 15)
			wait .5;
		else if(i < 25)
			wait .25;
		else
			wait .1;
	}

	self notify("powerup_timedout");
}

powerup_cleanup()
{
	result = self waittill_any_return("powerup_grabbed", "powerup_timedout", "powerup_cleanup", "death");

	if(result != "powerup_cleanup")
		self notify("powerup_cleanup");

	if(isdefined(level.zombie_powerups[self.powerup_name].func_cleanup))
		run_function(self, level.zombie_powerups[self.powerup_name].func_cleanup);

	self StopLoopSound();

	if(result != "death") // already been deleted if death was result
	{
		if(result == "powerup_grabbed")
			self thread powerup_delete(.01);
		else
			self powerup_delete();
	}

	level.active_powerups = array_remove_nokeys(level.active_powerups, self);
	level.active_powerups = array_removeUndefined(level.active_powerups);
}

powerup_vo(powerup_name)
{
	self endon("death");
	self endon("disconnect");

	announcer_vox_type = powerup_name;

	if(isdefined(level.zombie_powerups[powerup_name].announcer_vox_type))
		announcer_vox_type = level.zombie_powerups[powerup_name].announcer_vox_type;
	if(isdefined(level.devil_vox["powerup"][announcer_vox_type]))
		level thread maps\_zombiemode_audio::do_announcer_playvox(level.devil_vox["powerup"][announcer_vox_type]);

	wait RandomFloatRange(4.5, 5.5);
	self maps\_zombiemode_audio::create_and_play_dialog("powerup", powerup_name);
}

//============================================================================================
// Utils
//============================================================================================
get_valid_powerup_array()
{
	if(isdefined(level._zm_valid_powerup_names_cache) && level._zm_valid_powerup_names_cache.size > 0)
		return level._zm_valid_powerup_names_cache;
	else
	{
		powerup_names = GetArrayKeys(level.zombie_powerups);
		result = [];

		for(i = 0; i < powerup_names.size; i++)
		{
			if(is_powerup_valid(powerup_names[i]))
				result[result.size] = powerup_names[i];
		}

		level._zm_valid_powerup_names_cache = result;
		return result;
	}
}

get_powerups(origin, radius)
{
	if(isdefined(origin) && isdefined(radius))
	{
		result = [];

		for(i = 0; i < level.active_powerups.size; i++)
		{
			if(!isdefined(level.active_powerups[i]))
				continue;
			if(DistanceSquared(origin, level.active_powerups[i].origin) < radius * radius)
				result[result.size] = level.active_powerups[i];
		}
		return result;
	}
	return level.active_powerups;
}

randomize_powerups()
{
	level.zombie_powerup_array = array_randomize(level.zombie_powerup_array);
}

should_drop_with_regular_powerups(powerup_name)
{
	if(!is_powerup_valid(powerup_name))
		return false;

	if(isdefined(level.zombie_powerups[powerup_name].func_should_drop_with_regular_powerups))
	{
		result = run_function(level, level.zombie_powerups[powerup_name].func_should_drop_with_regular_powerups);
		return is_true(result);
	}
	return true;
}

get_next_powerup()
{
	powerup = level.zombie_powerup_array[level.zombie_powerup_index];
	level.zombie_powerup_index++;

	if(level.zombie_powerup_index >= level.zombie_powerup_array.size)
	{
		level.zombie_powerup_index = 0;
		randomize_powerups();
	}
	return powerup;
}

get_valid_powerup()
{
	powerup_name = get_next_powerup();

	for(;;)
	{
		if(should_drop_with_regular_powerups(powerup_name))
			return powerup_name;

		powerup_name = get_next_powerup();
	}
}

get_random_powerup_name()
{
	return random(get_valid_powerup_array());
}

get_regular_random_powerup_name()
{
	powerup_names = array_randomize(get_valid_powerup_array());

	for(i = 0; i < powerup_names.size; i++)
	{
		if(should_drop_with_regular_powerups(powerup_names[i]))
			return powerup_names[i];
	}
	return powerup_names[0];
}

powerup_show(show_hide)
{
	if(is_true(show_hide))
	{
		self Show();

		if(isdefined(self.powerup_player) && IsPlayer(self.powerup_player))
		{
			self SetInvisibleToAll();
			self SetVisibleToPlayer(self.powerup_player);
		}
	}
	else
		self Hide();
}

powerup_delete(delay)
{
	if(isdefined(delay) && delay > 0)
		wait delay;

	self Delete();
}

//============================================================================================
// Powerup Type Wrappers
//============================================================================================
set_weapon_ignore_max_ammo(weapon)
{
	if(!isdefined(level.zombie_weapons_no_max_ammo))
		level.zombie_weapons_no_max_ammo = [];
	if(!IsInArray(level.zombie_weapons_no_max_ammo, weapon))
		level.zombie_weapons_no_max_ammo[level.zombie_weapons_no_max_ammo.size] = weapon;
}

check_for_instakill(player, mod, hit_location)
{
	if(isdefined(player) && IsPlayer(player) && (is_true(level.zombie_vars["zombie_insta_kill"] || is_true(player.personal_instakill))))
	{
		if(is_magic_bullet_shield_enabled(self))
			return;

		if(isdefined(self.instakill_func))
		{
			single_thread(self, self.instakill_func);
			return;
		}

		if(player.use_weapon_type == "MOD_MELEE")
			player.last_kill_method = "MOD_MELEE";
		else
			player.last_kill_method = "MOD_UNKNOWN";

		modName = remove_mod_from_methodofdeath(mod);

		if(!flag("dog_round") && !is_true(self.no_gib))
			self maps\_zombiemode_spawner::zombie_head_gib();

		self DoDamage(self.health * 10, self.origin, undefined, modName, hit_location);
		player notify("zombie_killed");
	}
}

//============================================================================================
// Score / Zombie Dropping
//============================================================================================
watch_for_drop()
{
	flag_wait("begin_spawning");
	players = GetPlayers();
	score_to_drop = (players.size * level.zombie_vars["zombie_score_start_" + players.size + "p"]) + level.zombie_vars["zombie_powerup_drop_increment"];

	for(;;)
	{
		flag_wait("zombie_drop_powerups");
		players = GetPlayers();
		curr_total_score = 0;

		for(i = 0; i < players.size; i++)
		{
			curr_total_score += players[i].score_total;
		}

		if(curr_total_score > score_to_drop)
		{
			level.zombie_vars["zombie_powerup_drop_increment"] *= 1.14;
			score_to_drop = curr_total_score + level.zombie_vars["zombie_powerup_drop_increment"];
			level.zombie_vars["zombie_drop_item"] = true;
		}
		wait .5;
	}
}

powerup_drop(drop_point)
{
	if(isdefined(level.custom_zombie_powerup_drop))
	{
		result = run_function(level, level.custom_zombie_powerup_drop, drop_point);

		if(is_true(result))
			return;
	}

	if(level.powerup_drop_count >= level.zombie_vars["zombie_powerup_drop_max_per_round"])
		return;

	if(RandomInt(100) > 2)
	{
		if(!is_true(level.zombie_vars["zombie_drop_item"]))
			return;
	}

	origin = drop_point + (0, 0, 40);

	if(!check_point_in_playable_area(origin))
		return;

	powerup_name = get_valid_powerup();
	powerup = maps\_zombiemode_net::network_safe_spawn("powerup", 1, "script_model", origin);
	level.powerup_drop_count++;
	powerup powerup_drop_setup(powerup_name);
	level.zombie_vars["zombie_drop_item"] = false;
}

//============================================================================================
// Hud
//============================================================================================
powerup_hud_monitor(powerup_names)
{
	players = GetPlayers();
	flashing_timers = [];
	flashing_values = [];
	flashing_timer = 10;
	flashing_is_on = false;

	while(flashing_timer >= .15)
	{
		if(flashing_timer < 5)
			flashing_delta_time = .1;
		else
			flashing_delta_time = .2;

		if(flashing_is_on)
		{
			flashing_timer = flashing_timer - flashing_delta_time - .05;
			flashing_value = 1;
		}
		else
		{
			flashing_timer -= flashing_delta_time;
			flashing_value = .2;
		}

		flashing_timers[flashing_timers.size] = flashing_timer;
		flashing_values[flashing_values.size] = flashing_value;
		flashing_is_on = !flashing_is_on;
	}

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player.solo_powerup_hud = [];

		for(j = 0; j < powerup_names.size; j++)
		{
			powerup_name = powerup_names[j];
			hud = maps\_hud_util::createIcon(level.zombie_powerups[powerup_name].client_field_name, 32, 32, player);
			hud maps\_hud_util::setPoint("BOTTOM", undefined, 0, -5);
			hud.alpha = 0;
			hud.previous_position = 0;
			hud.previous_alpha = 0;
			hud.is_active = false;
			hud.powerup_name = powerup_name;
			player.solo_powerup_hud[player.solo_powerup_hud.size] = hud;
		}
	}

	for(;;)
	{
		wait .05;
		waittillframeend;
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			active_powerups = [];
			active_powerup_fade = [];
			active_powerup_values = [];

			for(j = 0; j < powerup_names.size; j++)
			{
				powerup_name = powerup_names[j];

				if(isdefined(level.powerup_player_valid))
				{
					result = run_function(player, level.powerup_player_valid, player);

					if(!is_true(result))
						continue;
				}

				time_name = level.zombie_powerups[powerup_name].time_name;
				on_name = level.zombie_powerups[powerup_name].on_name;
				powerup_timer = undefined;
				powerup_on = undefined;

				if(is_true(level.zombie_powerups[powerup_name].hud_per_player))
				{
					powerup_timer = player.zombie_vars[time_name];
					powerup_on = player.zombie_vars[on_name];
				}
				else
				{
					powerup_timer = level.zombie_vars[time_name];
					powerup_on = level.zombie_vars[on_name];
				}

				if(isdefined(powerup_timer) && isdefined(powerup_on))
				{
					if(is_true(powerup_on))
					{
						flashing_value = 1;
						flashing_fade = .01;

						if(powerup_timer < 10)
						{
							for(k = flashing_timers.size - 1; k > 0; k--)
							{
								if(powerup_timer < flashing_timers[k])
								{
									flashing_value = flashing_values[k];
									break;
								}
							}

							if(powerup_timer < 5)
								flashing_fade = .1;
							else
								flashing_fade = .2;
						}

						index = active_powerups.size;
						powerup_hud = undefined;

						for(k = 0; k < player.solo_powerup_hud.size; k++)
						{
							if(player.solo_powerup_hud[k].powerup_name == powerup_name)
							{
								powerup_hud = player.solo_powerup_hud[k];
								break;
							}
						}

						Assert(isdefined(powerup_hud));
						active_powerups[index] = powerup_hud;
						active_powerup_values[index] = flashing_value;
						active_powerup_fade[index] = flashing_fade;
					}
				}
			}

			for(j = 0; j < active_powerups.size; j++)
			{
				active_powerup = active_powerups[j];
				active_powerup.is_active = true;
				active_powerup set_powerup_hud_position(j * 48 - (active_powerups.size - 1) * 24, .5);
				active_powerup set_powerup_hud_alpha(active_powerup_values[j], active_powerup_fade[j]);
			}

			inactive_powerups = array_exclude(player.solo_powerup_hud, active_powerups);

			for(j = 0; j < inactive_powerups.size; j++)
			{
				inactive_powerup = inactive_powerups[j];

				if(is_true(inactive_powerup.is_active))
				{
					inactive_powerup set_powerup_hud_alpha(0, .5, 1);
					inactive_powerup.is_active = false;
				}
			}
		}
	}
}

set_powerup_hud_position(position, time)
{
	if(self.previous_position != position)
	{
		self MoveOverTime(time);
		self maps\_hud_util::setPoint("BOTTOM", undefined, position, -5, 0);
		self.previous_position = position;
	}
}

set_powerup_hud_alpha(alpha, time, override_previous)
{
	if(isdefined(override_previous))
	{
		self.alpha = override_previous;
		self.previous_alpha = override_previous;
	}

	if(self.previous_alpha != alpha)
	{
		self FadeOverTime(time);
		self.alpha = alpha;
		self.previous_alpha = alpha;
	}
}

//============================================================================================
// Timed Powerups
//============================================================================================
timed_powerup_think(powerup_name)
{
	self endon("disconnect");

	if(!is_timed_powerup(powerup_name))
		return;

	time_name = level.zombie_powerups[powerup_name].time_name;
	on_name = level.zombie_powerups[powerup_name].on_name;
	str_sound_loop = "zmb_" + powerup_name + "_loop";
	str_sound_off = "zmb_" + powerup_name + "_loop_off";

	if(is_weapon_powerup(powerup_name))
		self thread weapon_powerup(powerup_name);

	if(is_true(level.zombie_powerups[powerup_name].hud_per_player))
		self timed_powerup_player_think(powerup_name, time_name, on_name, str_sound_loop, str_sound_off);
	else
		self timed_powerup_level_think(powerup_name, time_name, on_name, str_sound_loop, str_sound_off);

	if(is_weapon_powerup(powerup_name))
		self thread weapon_powerup_remove(powerup_name, true);
}

timed_powerup_player_think(powerup_name, time_name, on_name, str_sound_loop, str_sound_off)
{
	if(is_true(self.zombie_vars[on_name]))
	{
		self.zombie_vars[time_name] += level.zombie_vars["zombie_powerup_active_time"];
		return;
	}

	ent = Spawn("script_origin", (0, 0, 0));
	ent PlayLoopSound(str_sound_loop);

	self.zombie_vars[on_name] = true;
	self.zombie_vars[time_name] = level.zombie_vars["zombie_powerup_active_time"];

	if(isdefined(level.zombie_powerups[powerup_name].func_timed_start))
		run_function(self, level.zombie_powerups[powerup_name].func_timed_start);

	while(self.zombie_vars[time_name] >= 0)
	{
		wait .05;
		self.zombie_vars[time_name] -= .05;

		if(isdefined(level.zombie_powerups[powerup_name].func_timed_loop))
			run_function(self, level.zombie_powerups[powerup_name].func_timed_loop);
	}

	if(isdefined(level.zombie_powerups[powerup_name].func_timed_stop))
		run_function(self, level.zombie_powerups[powerup_name].func_timed_stop);

	self.zombie_vars[time_name] = 0;
	self.zombie_vars[on_name] = false;
	self PlaySound(str_sound_off);
	ent StopLoopSound();
	ent Delete();
}

timed_powerup_level_think(powerup_name, time_name, on_name, str_sound_loop, str_sound_off)
{
	if(is_true(level.zombie_vars[on_name]))
	{
		level.zombie_vars[time_name] += level.zombie_vars["zombie_powerup_active_time"];
		return;
	}

	ent = Spawn("script_origin", (0, 0, 0));
	ent PlayLoopSound(str_sound_loop);

	level.zombie_vars[on_name] = true;
	level.zombie_vars[time_name] = level.zombie_vars["zombie_powerup_active_time"];

	if(isdefined(level.zombie_powerups[powerup_name].func_timed_start))
		run_function(self, level.zombie_powerups[powerup_name].func_timed_start);

	while(level.zombie_vars[time_name] >= 0)
	{
		wait .05;
		level.zombie_vars[time_name] -= .05;

		if(isdefined(level.zombie_powerups[powerup_name].func_timed_loop))
			run_function(self, level.zombie_powerups[powerup_name].func_timed_loop);
	}

	if(isdefined(level.zombie_powerups[powerup_name].func_timed_stop))
		run_function(self, level.zombie_powerups[powerup_name].func_timed_stop);

	level.zombie_vars[time_name] = 0;
	level.zombie_vars[on_name] = false;
	self PlaySound(str_sound_off);
	ent StopLoopSound();
	ent Delete();
}

//============================================================================================
// Weapon Powerups
//============================================================================================
register_powerup_weapon(powerup_name, weapon_name)
{
	if(!isdefined(level.zombie_powerup_weapon))
		level.zombie_powerup_weapon = [];
	if(!isdefined(level.zombie_powerup_weapon[powerup_name]))
		level.zombie_powerup_weapon[powerup_name] = weapon_name;
}

is_weapon_powerup(powerup_name)
{
	if(!is_powerup_valid(powerup_name))
		return false;
	if(!is_timed_powerup(powerup_name))
		return false;
	if(!isdefined(level.zombie_powerup_weapon))
		return false;
	if(!isdefined(level.zombie_powerup_weapon[powerup_name]))
		return false;
	return level.zombie_powerup_weapon[powerup_name] != "none";
}

is_powerup_weapon(weapon_name)
{
	if(isdefined(level.zombie_powerup_weapon))
	{
		keys = GetArrayKeys(level.zombie_powerup_weapon);

		for(i = 0; i < keys.size; i++)
		{
			if(level.zombie_powerup_weapon[keys[i]] == weapon_name)
				return true;
		}
	}
	return false;
}

weapon_powerup(powerup_name)
{
	self notify("replace_weapon_powerup");
	self.has_specific_powerup_weapon[powerup_name] = true;
	self.has_powerup_weapon = true;
	self increment_is_drinking();

	if(is_true(level.zombie_vars["zombie_powerup_weapons_allow_cycling"]))
		self EnableWeaponCycling();

	self._zombie_weapon_before_powerup[powerup_name] = self GetCurrentWeapon();
	self maps\apex\_zm_weapons::give_weapon(level.zombie_powerup_weapon[powerup_name]);
	self SwitchToWeapon(level.zombie_powerup_weapon[powerup_name]);
	self thread weapon_powerup_replace(powerup_name);
	self thread weapon_powerup_change(powerup_name);
}

weapon_powerup_change(powerup_name)
{
	self endon("death");
	self endon("disconnect");
	self endon("player_downed");
	self endon("replace_weapon_powerup");
	self endon(powerup_name + "_time_over");

	for(;;)
	{
		self waittill("weapon_change", newWeapon, oldWeapon);

		if(newWeapon != "none" && newWeapon != level.zombie_powerup_weapon[powerup_name])
			break;
	}

	self thread weapon_powerup_remove(powerup_name, false);
}

weapon_powerup_replace(powerup_name)
{
	self endon("death");
	self endon("disconnect");
	self endon("player_downed");
	self endon(powerup_name + "_time_over");
	self waittill("replace_weapon_powerup");
	self thread weapon_powerup_remove(powerup_name, false);
}

weapon_powerup_remove(powerup_name, switch_back_weapon)
{
	self endon("death");
	self endon("player_downed");

	if(!self has_powerup_weapon() || !is_true(self.has_specific_powerup_weapon[powerup_name]))
		return;

	self maps\apex\_zm_weapons::weapon_take(level.zombie_powerup_weapon[powerup_name]);
	self.has_specific_powerup_weapon[powerup_name] = false;
	self.has_powerup_weapon = false;
	self notify(powerup_name + "_time_over");
	self decrement_is_drinking();

	time_name = level.zombie_powerups[powerup_name].time_name;

	if(is_true(level.zombie_powerups[powerup_name].hud_per_player))
		self.zombie_vars[time_name] = -1;
	else
		level.zombie_vars[time_name] = -1;

	if(is_true(switch_back_weapon))
		self SwitchToWeapon(self._zombie_weapon_before_powerup[powerup_name]);
}

//============================================================================================
// Can Power Up Drop Functions
//============================================================================================
func_should_never_drop()
{
	return false;
}

func_should_always_drop()
{
	return true;
}

//============================================================================================
// Registry
//============================================================================================
is_powerup_valid(powerup_name)
{
	if(!isdefined(level.zombie_powerups))
		return false;
	if(!isdefined(level.zombie_powerups[powerup_name]))
		return false;
	return is_true(level.zombie_powerups[powerup_name].valid);
}

is_timed_powerup(powerup_name)
{
	if(!is_powerup_valid(powerup_name))
		return false;
	return is_true(level.zombie_powerups[powerup_name].is_timed_powerup);
}

powerup_set_can_pick_up_in_revive_trigger(powerup_name, b_can_pick_up)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].can_pick_up_in_revive_trigger = b_can_pick_up;
}

powerup_set_can_pick_up_in_last_stand(powerup_name, b_can_pick_up)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].can_pick_up_in_last_stand = b_can_pick_up;
}

powerup_set_prevent_pick_up_if_drinking(powerup_name, b_prevent_pick_up)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].prevent_pick_up_if_drinking = b_prevent_pick_up;
}

powerup_set_announcer_vox_type(powerup_name, announcer_vox_type)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].announcer_vox_type = announcer_vox_type;
}

powerup_remove_from_regular_drops(powerup_name)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].func_should_drop_with_regular_powerups = ::func_should_never_drop;
}

_register_undefined_powerup(powerup_name)
{
	if(!isdefined(level.zombie_powerups))
		level.zombie_powerups = [];
	if(isdefined(level.zombie_powerups[powerup_name]))
		return;

	level.zombie_powerups[powerup_name] = SpawnStruct();
	level.zombie_powerups[powerup_name].valid = false;
	level.zombie_powerups[powerup_name].is_timed_powerup = false;
	level.zombie_powerups[powerup_name].can_pick_up_in_last_stand = true;
	level.zombie_powerups[powerup_name].prevent_pick_up_if_drinking = false;
	level.zombie_powerups[powerup_name].can_pick_up_in_revive_trigger = true;
	level.zombie_powerups[powerup_name].announcer_vox_type = powerup_name;
}

register_basic_powerup(powerup_name, model, powerup_fx)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].valid = true;
	level.zombie_powerups[powerup_name].model = model;
	level.zombie_powerups[powerup_name].powerup_fx = powerup_fx;
}

register_timed_powerup(powerup_name, hud_per_player, client_field_name, time_name, on_name)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].is_timed_powerup = true;
	level.zombie_powerups[powerup_name].hud_per_player = hud_per_player;
	level.zombie_powerups[powerup_name].client_field_name = client_field_name;
	level.zombie_powerups[powerup_name].time_name = time_name;
	level.zombie_powerups[powerup_name].on_name = on_name;
}

register_powerup_funcs(powerup_name, func_setup, func_grabbed, func_cleanup, func_should_drop_with_regular_powerups)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].func_setup = func_setup;
	level.zombie_powerups[powerup_name].func_grabbed = func_grabbed;
	level.zombie_powerups[powerup_name].func_cleanup = func_cleanup;
	level.zombie_powerups[powerup_name].func_should_drop_with_regular_powerups = func_should_drop_with_regular_powerups;
}

register_timed_powerup_funcs(powerup_name, func_timed_start, func_timed_loop, func_timed_stop)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].func_timed_start = func_timed_start;
	level.zombie_powerups[powerup_name].func_timed_loop = func_timed_loop;
	level.zombie_powerups[powerup_name].func_timed_stop = func_timed_stop;
}