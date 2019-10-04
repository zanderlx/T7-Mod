#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	flag_init("zombie_drop_powerups", true);

	set_zombie_var("zombie_drop_item", false);
	set_zombie_var("zombie_powerup_drop_increment", 700);
	set_zombie_var("zombie_powerup_drop_max_per_round", 7);
	set_zombie_var("zombie_powerup_drop_time", 30);
	set_zombie_var("zombie_powerup_timed_powerups_extend_time", true); // if true, grabbing a timed powerup extends its lifetime if already active

	set_zombie_var("zombie_point_scalar", 1);

	level.zombie_powerups = [];
	level.zombie_powerup_array = [];
	level.active_powerups = [];
	level.zombie_powerup_index = 0;
	level.powerup_drop_count = 0;

	if(!isdefined(level._zm_powerup_include_func))
		level._zm_powerup_include_func = ::default_include_powerups;

	run_function(level, level._zm_powerup_include_func);
	maps\powerups\_zm_powerup_weapon::init(); // Power up weapon laststand functions
	precache_powerups();
	randomize_powerups();
	level thread watch_for_drop();
	level thread init_zombie_vars();
}

precache_powerups()
{
	level._effect["powerup_green_on"] = LoadFX("misc/fx_zombie_powerup_on");
	level._effect["powerup_green_grabbed"] = LoadFX("misc/fx_zombie_powerup_grab");
	level._effect["powerup_green_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_wave");
	level._effect["powerup_blue_on"] = LoadFX("misc/fx_zombie_powerup_solo_on");
	level._effect["powerup_blue_grabbed"] = LoadFX("misc/fx_zombie_powerup_solo_grab");
	level._effect["powerup_blue_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_solo_wave");
	// level._effect["powerup_on_caution"] = LoadFX("misc/fx_zombie_powerup_solo_on");
	// level._effect["powerup_grabbed_caution"] = LoadFX("misc/fx_zombie_powerup_solo_grab");
	// level._effect["powerup_grabbed_wave_caution"] = LoadFX("misc/fx_zombie_powerup_solo_wave");
	// level._effect["powerup_red_on"] = LoadFX("misc/fx_zombie_powerup_solo_on");
	// level._effect["powerup_red_grabbed"] = LoadFX("misc/fx_zombie_powerup_solo_grab");
	// level._effect["powerup_red_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_solo_wave");
}

default_include_powerups()
{
	// T4
	maps\powerups\_zm_powerup_full_ammo::include_powerup_for_level();
	maps\powerups\_zm_powerup_insta_kill::include_powerup_for_level();
	maps\powerups\_zm_powerup_nuke::include_powerup_for_level();
	maps\powerups\_zm_powerup_double_points::include_powerup_for_level();
	maps\powerups\_zm_powerup_carpenter::include_powerup_for_level();
	
	// T5
	maps\powerups\_zm_powerup_fire_sale::include_powerup_for_level();
	// maps\powerups\_zm_powerup_bonfire_sale::include_powerup_for_level();
	maps\powerups\_zm_powerup_minigun::include_powerup_for_level();
}

init_zombie_vars()
{
	flag_wait("all_players_connected");
	wait .1;
	waittillframeend;
	players = GetPlayers();
	keys = GetArrayKeys(level.zombie_powerups);

	for(i = 0; i < keys.size; i++)
	{
		powerup_name = keys[i];

		if(is_true(level.zombie_powerups[powerup_name].per_player))
		{
			for(j = 0; j < players.size; j++)
			{
				if(!isdefined(players[j].zombie_vars))
					players[j].zombie_vars = [];
				if(isdefined(level.zombie_powerups[powerup_name].time_name))
					players[j].zombie_vars[level.zombie_powerups[powerup_name].time_name] = level.zombie_vars["zombie_powerup_drop_time"];
				if(isdefined(level.zombie_powerups[powerup_name].on_name))
					players[j].zombie_vars[level.zombie_powerups[powerup_name].on_name] = false;
			}
		}
		else
		{
			if(isdefined(level.zombie_powerups[powerup_name].time_name))
				level.zombie_vars[level.zombie_powerups[powerup_name].time_name] = level.zombie_vars["zombie_powerup_drop_time"];
			if(isdefined(level.zombie_powerups[powerup_name].on_name))
				level.zombie_vars[level.zombie_powerups[powerup_name].on_name] = false;
		}
	}

	level thread powerup_hud_overlay();
}

powerup_hud_overlay()
{
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

	client_fields = [];
	powerup_keys = GetArrayKeys(level.zombie_powerups);

	for(i = 0; i < powerup_keys.size; i++)
	{
		powerup_name = powerup_keys[i];

		if(isdefined(level.zombie_powerups[powerup_name].client_field_name))
			client_fields[client_fields.size] = powerup_name;
	}

	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		player.solo_powerup_hud = [];

		for(j = 0; j < client_fields.size; j++)
		{
			powerup_name = client_fields[j];

			player.solo_powerup_hud[j] = maps\_hud_util::createIcon(level.zombie_powerups[powerup_name].client_field_name, 32, 32, player);
			player.solo_powerup_hud[j] maps\_hud_util::setPoint("BOTTOM", undefined, 0, -5);
			player.solo_powerup_hud[j].alpha = 0;
			player.solo_powerup_hud[j].previous_position = 0;
			player.solo_powerup_hud[j].previous_alpha = 0;
			player.solo_powerup_hud[j].powerup_name = powerup_name;
		}
	}

	for(;;)
	{
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			active_powerups = [];
			active_powerup_values = [];
			active_powerup_fade = [];

			for(j = 0; j < client_fields.size; j++)
			{
				powerup_name = client_fields[j];
				time_name = level.zombie_powerups[powerup_name].time_name;
				on_name = level.zombie_powerups[powerup_name].on_name;

				if(is_true(level.zombie_powerups[powerup_name].per_player))
				{
					powerup_timer = player.zombie_vars[time_name];
					powerup_on = player.zombie_vars[on_name];
				}
				else
				{
					powerup_timer = level.zombie_vars[time_name];
					powerup_on = level.zombie_vars[on_name];
				}

				if(is_true(powerup_on))
				{
					flashing_value = 1;
					flashing_fade = 0;

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

					powerup_hud = undefined;

					for(k = 0; k < player.solo_powerup_hud.size; k++)
					{
						if(player.solo_powerup_hud[k].powerup_name == powerup_name)
						{
							powerup_hud = player.solo_powerup_hud[k];
							break;
						}
					}

					index = active_powerups.size;
					active_powerups[index] = powerup_hud;
					active_powerup_values[index] = flashing_value;
					active_powerup_fade[index] = flashing_fade;
				}
			}

			for(j = 0; j < active_powerups.size; j++)
			{
				active_powerups[j].is_active = true;
				active_powerups[j] set_powerup_hud_position(j * 48 - (active_powerups.size - 1) * 24, .5);
				active_powerups[j] set_powerup_hud_alpha(active_powerup_values[j], active_powerup_fade[j]);
			}

			inactive_powerups = array_exclude(player.solo_powerup_hud, active_powerups);

			for(j = 0; j < inactive_powerups.size; j++)
			{
				if(is_true(inactive_powerups[j].is_active))
				{
					inactive_powerups[j] set_powerup_hud_alpha(0, .5, 1);
					inactive_powerups[j].is_active = false;
				}
			}
		}
		wait .05;
	}
}

set_powerup_hud_position(position, time)
{
	if(self.previous_position != position)
	{
		self maps\_hud_util::setPoint("BOTTOM", undefined, position, -5, 0);
		self.previous_position = position;
	}
}

set_powerup_hud_alpha(alpha, time, override_previous)
{
	if(is_true(override_previous))
	{
		self.alpha = override_previous;
		self.previous_alpha = override_previous;
	}

	if(self.previous_alpha != alpha)
	{
		// FadeOverTime does not like having a fade time <= 0
		// to fix this, just default to .1 fade time if we get 0
		// ******* Script runtime error *******
		// fade time 0 <= 0: (file 'maps/_zm_powerups.gsc', line 280)
  		// self FadeOverTime(time);
		if(time <= 0)
			time = .1;

		self FadeOverTime(time);
		self.alpha = alpha;
		self.previous_alpha = alpha;
	}
}

randomize_powerups()
{
	level.zombie_powerup_array = array_randomize(level.zombie_powerup_array);
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
	can_drop = false;
	powerup_name = undefined;

	while(!is_true(can_drop))
	{
		powerup_name = get_next_powerup();

		if(isdefined(level.zombie_powerups[powerup_name].func_can_drop))
			can_drop = run_function(level, level.zombie_powerups[powerup_name].func_can_drop);
		else
		{
			can_drop = true;

			if(isdefined(level._zm_powerup_can_drop))
				can_drop = run_function(level, level._zm_powerup_can_drop, powerup_name);
		}
	}

	return powerup_name;
}

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

_register_undefined_powerup(powerup_name)
{
	if(isdefined(level.zombie_powerups[powerup_name]))
		return;
	
	struct = SpawnStruct();
	struct.powerup_fx = "powerup_green";
	struct.can_pickup_in_laststand = true;
	struct.can_pickup_if_drinking = true;

	level.zombie_powerups[powerup_name] = struct;
}

register_powerup(powerup_name, model_name)
{
	_register_undefined_powerup(powerup_name);
	
	level.zombie_powerups[powerup_name].model_name = model_name;

	PrecacheModel(model_name);

	if(!IsInArray(level.zombie_powerup_array, powerup_name))
		level.zombie_powerup_array[level.zombie_powerup_array.size] = powerup_name;
}

register_powerup_ui(powerup_name, per_player, client_field_name, time_name, on_name)
{
	_register_undefined_powerup(powerup_name);

	PrecacheShader(client_field_name);

	level.zombie_powerups[powerup_name].per_player = per_player;
	level.zombie_powerups[powerup_name].client_field_name = client_field_name;
	level.zombie_powerups[powerup_name].time_name = time_name;
	level.zombie_powerups[powerup_name].on_name = on_name;
}

register_powerup_fx(powerup_name, powerup_fx)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].powerup_fx = powerup_fx;
}

register_powerup_threads(powerup_name, func_can_drop, func_grabbed, thread_setup, func_cleanup)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].func_can_drop = func_can_drop;
	level.zombie_powerups[powerup_name].func_grabbed = func_grabbed;
	level.zombie_powerups[powerup_name].thread_setup = thread_setup;
	level.zombie_powerups[powerup_name].func_cleanup = func_cleanup;
}

set_powerup_can_pickup_in_laststand(powerup_name, can_pickup_in_laststand)
{
	_register_undefined_powerup(powerup_name);
	level.zombie_powerups[powerup_name].can_pickup_in_laststand = can_pickup_in_laststand;
}

set_powerup_can_pickup_if_drinking(powerup_name, can_pickup_if_drinking)
{
	_register_undefined_powerup(powerup_name);
	level.zombie_powerups[powerup_name].can_pickup_if_drinking = can_pickup_if_drinking;
}

remove_powerup_from_regular_drops(powerup_name)
{
	_register_undefined_powerup(powerup_name);
	level.zombie_powerups[powerup_name].func_can_drop = ::func_should_never_drop;
}

powerup_round_start()
{
	level.powerup_drop_count = 0;
}

powerup_drop(drop_point)
{
	if(level.powerup_drop_count >= level.zombie_vars["zombie_powerup_drop_max_per_round"])
		return undefined;
	if(!is_true(level.zombie_vars["zombie_drop_item"]))
		return undefined;
	if(!check_point_in_playable_area(drop_point + (0, 0, 40)))
		return undefined;

	level.powerup_drop_count++;
	level.zombie_vars["zombie_drop_item"] = false;
	powerup_name = get_valid_powerup();
	return specific_powerup_drop(powerup_name, drop_point, undefined, false);
}

specific_powerup_drop(powerup_name, drop_point, powerup_player, b_stay_forever)
{
	if(!isdefined(powerup_name))
		return undefined;

	powerup = maps\_zombiemode_net::network_safe_spawn("powerup", 1, "script_model", drop_point + (0, 0, 40));

	if(isdefined(powerup))
	{
		powerup.powerup_name = powerup_name;
		powerup.powerup_player = powerup_player;
		powerup SetModel(level.zombie_powerups[powerup_name].model_name);

		if(!is_true(b_stay_forever))
			powerup thread powerup_timeout();

		powerup thread powerup_wobble();
		powerup thread powerup_grab();
		powerup thread powerup_cleanup();

		if(isdefined(powerup_player))
		{
			num = powerup GetEntityNumber();
			play_oneshot_sound_to_player(powerup_player, "zmb_spawn_powerup", powerup.origin);
			powerup thread clientside_powerup_loop_sound_think(powerup_player, "powerup_loop_" + num);
		}
		else
		{
			PlaySoundAtPosition("zmb_spawn_powerup", powerup.origin);
			powerup PlayLoopSound("zmb_spawn_powerup_loop");
		}

		if(isdefined(level.zombie_powerups[powerup_name].thread_setup))
			single_thread(powerup, level.zombie_powerups[powerup_name].thread_setup);
		
		level notify("powerup_dropped", powerup);
		level.active_powerups[level.active_powerups.size] = powerup;
	}
	return powerup;
}

clientside_powerup_loop_sound_think(player, identifier)
{
	create_loop_sound_to_player(player, identifier, "zmb_spawn_powerup_loop", self.origin);
	self waittill_any("powerup_timedout", "powerup_grabbed", "death");
	destroy_loop_sound_to_player(player, identifier, 0);
}

powerup_cleanup()
{
	result = self waittill_any_return("powerup_grabbed", "powerup_timedout", "powerup_cleanup", "death");

	wait_network_frame();

	if(result != "powerup_cleanup")
		self notify("powerup_cleanup");
	
	if(isdefined(level.zombie_powerups[self.powerup_name].func_cleanup))
		single_thread(self, level.zombie_powerups[self.powerup_name].func_cleanup);

	self powerup_delete();
}

powerup_grab()
{
	self endon("death");
	self endon("powerup_timedout");
	self endon("powerup_cleanup");

	for(;;)
	{
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			if(isdefined(self.powerup_player) && players[i] != self.powerup_player)
				continue;
			if(DistanceSquared(players[i].origin, self.origin) > 4096)
				continue;
			if(players[i] is_drinking() && !is_true(level.zombie_powerups[self.powerup_name].can_pickup_if_drinking))
				continue;
			if(players[i] maps\_laststand::player_is_in_laststand() && !is_true(level.zombie_powerups[self.powerup_name].can_pickup_in_laststand))
				continue;
			
			if(isdefined(level.zombie_powerups[self.powerup_name].func_grabbed))
				can_grab = run_function(self, level.zombie_powerups[self.powerup_name].func_grabbed, players[i]);
			else
			{
				if(isdefined(level._zombiemode_powerup_grab))
					single_thread(level, level._zombiemode_powerup_grab, self);
				
				can_grab = true;
			}

			if(!is_true(can_grab))
				continue;
			
			powerup_fx = level.zombie_powerups[self.powerup_name].powerup_fx;

			if(!isdefined(powerup_fx))
				powerup_fx = "powerup_green";
			
			if(isdefined(self.powerup_player))
			{
				play_oneshot_fx_to_player(self.powerup_player, powerup_fx + "_grabbed", self.origin, (0, 0, 0));
				play_oneshot_fx_to_player(self.powerup_player, powerup_fx + "_grabbed_wave", self.origin, (0, 0, 0));
				play_oneshot_sound_to_player(self.powerup_player, "zmb_powerup_grabbed", self.origin);
			}
			else
			{
				PlayFX(level._effect[powerup_fx + "_grabbed"], self.origin);
				PlayFX(level._effect[powerup_fx + "_grabbed_wave"], self.origin);
				PlaySoundAtPosition("zmb_powerup_grabbed", self.origin);
				self StopLoopSound();
			}

			if(isdefined(level.zombie_powerups[self.powerup_name].time_name) && isdefined(level.zombie_powerups[self.powerup_name].on_name))
				players[i] thread timed_powerup_grabbed(self.powerup_name);

			self.claimed = true;
			self.power_up_grab_player = players[i];
			players[i] thread powerup_vo(self.powerup_name);
			wait .1;
			self notify("powerup_grabbed");
		}
		wait .1;
	}
}

powerup_vo(powerup_name)
{
	self endon("disconnect");
	wait RandomFloatRange(4.5, 5.5);
	self maps\_zombiemode_audio::create_and_play_dialog("powerup", powerup_name);
}

powerup_wobble()
{
	self endon("death");
	self endon("powerup_grabbed");
	self endon("powerup_timedout");
	self endon("powerup_cleanup");

	powerup_fx = level.zombie_powerups[self.powerup_name].powerup_fx;

	if(!isdefined(powerup_fx))
		powerup_fx = "powerup_green";

	PlayFXOnTag(level._effect[powerup_fx + "_on"], self, "tag_origin");
	
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
		self RotateTo(new_angles, waittime, waittime * .5, waittime *.5);
		wait RandomFloat(waittime - .1);
	}
}

powerup_show(visible)
{
	if(is_true(visible))
	{
		self Show();

		if(isdefined(self.powerup_player))
		{
			self SetInvisibleToAll();
			self SetVisibleToPlayer(self.powerup_player);
		}
	}
	else
		self Hide();
}

powerup_timeout()
{
	self endon("death");
	self endon("powerup_grabbed");
	self endon("powerup_cleanup");

	self powerup_show(true);
	wait 15;

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

powerup_delete()
{
	level.active_powerups = array_remove_nokeys(level.active_powerups, self);
	level.active_powerups = array_removeUndefined(level.active_powerups);
	self Delete();
}

func_should_never_drop()
{
	return false;
}

func_should_always_drop()
{
	return true;
}

get_powerups(origin, radius)
{
	if(isdefined(origin) && isdefined(radius))
	{
		result = [];

		for(i = 0; i < level.active_powerups.size; i++)
		{
			if(DistanceSquared(origin, level.active_powerups[i].origin) < radius * radius)
				result[result.size] = level.active_powerups[i];
		}
		return result;
	}
	return level.active_powerups;
}

// Timed Power Ups
timed_powerup_grabbed(powerup_name)
{
	if(is_true(level.zombie_powerups[powerup_name].per_player))
		self thread timed_powerup_per_player(powerup_name);
	else
		self thread timed_powerup_global(powerup_name);
}

timed_powerup_per_player(powerup_name)
{
	time_name = level.zombie_powerups[powerup_name].time_name;
	on_name = level.zombie_powerups[powerup_name].on_name;

	if(is_true(self.zombie_vars[on_name]))
	{
		if(is_true(level.zombie_vars["zombie_powerup_timed_powerups_extend_time"]))
			self.zombie_vars[time_name] += level.zombie_vars["zombie_powerup_drop_time"];
		if(isdefined(level.zombie_powerups[powerup_name].timed_powerup_thread_restart))
			single_thread(self, level.zombie_powerups[powerup_name].timed_powerup_thread_restart);
		return;
	}

	self.zombie_vars[time_name] = level.zombie_vars["zombie_powerup_drop_time"];
	self.zombie_vars[on_name] = true;
	self notify(powerup_name + "_on");
	level notify(powerup_name + "_on");

	if(isdefined(level.zombie_powerups[powerup_name].timed_powerup_thread_on))
		single_thread(self, level.zombie_powerups[powerup_name].timed_powerup_thread_on);

	while(self.zombie_vars[time_name] > 0)
	{
		wait .1;
		self.zombie_vars[time_name] -= .1;
	}

	if(isdefined(level.zombie_powerups[powerup_name].timed_powerup_thread_off))
		single_thread(self, level.zombie_powerups[powerup_name].timed_powerup_thread_off);

	self.zombie_vars[time_name] = 0;
	self.zombie_vars[on_name] = false;
	self notify(powerup_name + "_off");
	level notify(powerup_name + "_off");
}

timed_powerup_global(powerup_name)
{
	time_name = level.zombie_powerups[powerup_name].time_name;
	on_name = level.zombie_powerups[powerup_name].on_name;

	if(is_true(level.zombie_vars[on_name]))
	{
		if(is_true(level.zombie_vars["zombie_powerup_timed_powerups_extend_time"]))
			level.zombie_vars[time_name] += level.zombie_vars["zombie_powerup_drop_time"];
		if(isdefined(level.zombie_powerups[powerup_name].timed_powerup_thread_restart))
			single_thread(self, level.zombie_powerups[powerup_name].timed_powerup_thread_restart);
		return;
	}

	level.zombie_vars[time_name] = level.zombie_vars["zombie_powerup_drop_time"];
	level.zombie_vars[on_name] = true;
	level notify(powerup_name + "_on");

	if(isdefined(level.zombie_powerups[powerup_name].timed_powerup_thread_on))
		single_thread(self, level.zombie_powerups[powerup_name].timed_powerup_thread_on);

	while(level.zombie_vars[time_name] > 0)
	{
		wait .1;
		level.zombie_vars[time_name] -= .1;
	}

	if(isdefined(level.zombie_powerups[powerup_name].timed_powerup_thread_off))
		single_thread(self, level.zombie_powerups[powerup_name].timed_powerup_thread_off);

	level.zombie_vars[time_name] = 0;
	level.zombie_vars[on_name] = false;
	level notify(powerup_name + "_off");
}

register_timed_powerup_threads(powerup_name, thread_on, thread_off, thread_restart)
{
	_register_undefined_powerup(powerup_name);

	level.zombie_powerups[powerup_name].timed_powerup_thread_on = thread_on;
	level.zombie_powerups[powerup_name].timed_powerup_thread_off = thread_off;
	level.zombie_powerups[powerup_name].timed_powerup_thread_restart = thread_restart;
}

// Max Ammo Helper
set_weapon_ignore_max_ammo(weapon)
{
	if(!isdefined(level.zombie_weapons_no_max_ammo))
		level.zombie_weapons_no_max_ammo = [];
	level.zombie_weapons_no_max_ammo[level.zombie_weapons_no_max_ammo.size] = weapon;
}