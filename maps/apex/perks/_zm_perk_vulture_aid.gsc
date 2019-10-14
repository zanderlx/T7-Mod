#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("vulture", "specialty_vulture_zombies");
	maps\apex\_zm_perks::register_perk_bottle("vulture", undefined, undefined, 32);
	maps\apex\_zm_perks::register_perk_machine("vulture", false, &"ZOMBIE_PERK_VULTURE", 2000, "p6_zm_vending_vultureaid", "p6_zm_vending_vultureaid_on", "perk_light_red");
	maps\apex\_zm_perks::register_perk_threads("vulture", ::give_vulture, ::take_vulture);
	maps\apex\_zm_perks::register_perk_sounds("vulture", "mus_perks_vulture_sting", "mus_perks_vulture_jingle", undefined);

	level._effect["vulture_perk_zombie_stink"] = LoadFX("sanchez/vulture_aid/vulture_smell_idle");
	level._effect["vulture_perk_zombie_stink_trail"] = LoadFX("sanchez/vulture_aid/vulture_smell_trail");
	level._effect["vulture_perk_bonus_drop"] = LoadFX("sanchez/vulture_aid/vulture_powerup_on");
	level._effect["vulture_drop_picked_up"] = LoadFX("misc/fx_zombie_powerup_grab");
	level._effect["vulture_perk_wallbuy_static"] = LoadFX("sanchez/vulture_aid/vulture_wallgun_glow");
	level._effect["vulture_perk_machine_glow_doubletap"] = LoadFX("sanchez/vulture_aid/vulture_dtap_glow");
	level._effect["vulture_perk_machine_glow_juggernog"] = LoadFX("sanchez/vulture_aid/vulture_jugg_glow");
	level._effect["vulture_perk_machine_glow_revive"] = LoadFX("sanchez/vulture_aid/vulture_revive_glow");
	level._effect["vulture_perk_machine_glow_speed"] = LoadFX("sanchez/vulture_aid/vulture_speed_glow");
	level._effect["vulture_perk_machine_glow_marathon"] = LoadFX("sanchez/vulture_aid/vulture_stamin_glow");
	level._effect["vulture_perk_machine_glow_mule_kick"] = LoadFX("sanchez/vulture_aid/vulture_mule_glow");
	level._effect["vulture_perk_machine_glow_pack_a_punch"] = LoadFX("sanchez/vulture_aid/vulture_pap_glow");
	level._effect["vulture_perk_machine_glow_vulture"] = LoadFX("sanchez/vulture_aid/vulture_aid_glow");
	level._effect["vulture_perk_machine_glow_electric_cherry"] = LoadFX("sanchez/vulture_aid/vulture_cherry_glow");
	level._effect["vulture_perk_machine_glow_wunderfizz"] = LoadFX("sanchez/vulture_aid/vulture_fizz_glow");
	level._effect["vulture_perk_machine_glow_phd_flopper"] = LoadFX("sanchez/vulture_aid/vulture_phd_glow");
	level._effect["vulture_perk_machine_glow_whos_who"] = LoadFX("sanchez/vulture_aid/vulture_whoswho_glow");
	level._effect["vulture_perk_machine_glow_widows_wine"] = LoadFX("sanchez/vulture_aid/vulture_widows_glow");
	level._effect["vulture_perk_mystery_box_glow"] = LoadFX("sanchez/vulture_aid/vulture_box_glow");
	level._effect["vulture_perk_powerup_drop"] = LoadFX("sanchez/vulture_aid/vulture_powerup_glow");
	level._effect["vulture_perk_zombie_eye_glow"] = LoadFX("misc/fx_zombie_eye_vulture");

	PrecacheModel("p6_zm_perk_vulture_ammo");
	PrecacheModel("p6_zm_perk_vulture_points");
	level.zombiemode_using_vulture_perk = true;

	init_vulture();
	OnPlayerConnect_Callback(::vulture_player_connect_callback);
}

vulture_player_connect_callback()
{
	self thread end_game_turn_off_vulture_overlay();
}

end_game_turn_off_vulture_overlay()
{
	self endon("disconnect");
	level waittill("end_game");
	self thread take_vulture("end_game");
}

init_vulture()
{
	set_zombie_var("zombies_perk_vulture_pickup_time", 12);
	set_zombie_var("zombies_perk_vulture_pickup_time_stink", 16);
	set_zombie_var("zombies_perk_vulture_drop_chance", 65);
	set_zombie_var("zombies_perk_vulture_ammo_chance", 33);
	set_zombie_var("zombies_perk_vulture_points_chance", 33);
	set_zombie_var("zombies_perk_vulture_stink_chance", 33);
	set_zombie_var("zombies_perk_vulture_drops_max", 20);
	set_zombie_var("zombies_perk_vulture_network_drops_max", 5);
	set_zombie_var("zombies_perk_vulture_network_time_frame", 250);
	set_zombie_var("zombies_perk_vulture_spawn_stink_zombie_cooldown", 12);
	set_zombie_var("zombies_perk_vulture_max_stink_zombies", 4);

	level.perk_vulture = SpawnStruct();
	level.perk_vulture.zombie_stink_array = [];
	level.perk_vulture.drop_time_last = 0;
	level.perk_vulture.drop_slots_for_network = 0;
	level.perk_vulture.last_stink_zombie_spawned = 0;
	level.perk_vulture.use_exit_behavior = false;

	level._ZOMBIE_SCRIPTMOVER_VULTURE_STINK_FX = 0;
	level._ZOMBIE_SCRIPTMOVER_VULTURE_DROP_FX = 1;
	level._ZOMBIE_SCRIPTMOVER_VULTURE_DROP_PICKUP = 2;
	level._ZOMBIE_SCRIPTMOVER_VULTURE_POWERUP_DROP = 3;
	level._ZOMBIE_SCRIPTMOVER_VULTURE_MYSTERY_BOX = 4;
	level._ZOMBIE_ACTOR_VULTURE_STINK_TRAIL_FX = 0;
	level._ZOMBIE_ACTOR_VULTURE_EYE_GLOW = 1;

	maps\_zombiemode_spawner::add_cusom_zombie_spawn_logic(::vulture_zombie_spawn_func);
	maps\_zombiemode_spawner::register_zombie_death_event_callback(::zombies_drop_stink_on_death);

	level thread vulture_perk_watch_mystery_box();
	level thread vulture_perk_watch_fire_sale();
	level thread vulture_perk_watch_powerup_drops();
	level thread vulture_handle_solo_quick_revive();

	level.exit_level_func = ::vulture_zombies_find_exit_point;
	level.perk_vulture.invalid_bonus_ammo_weapons = array("time_bomb_zm", "time_bomb_detonator_zm");

	if(!isdefined(level.perk_vulture.func_zombies_find_valid_exit_locations))
		level.perk_vulture.func_zombies_find_valid_exit_locations = ::get_valid_exit_points_for_zombie;

	initialize_bonus_entity_pool();
	initialize_stink_entity_pool();
}

add_additional_stink_locations_for_zone(str_zone, a_zones)
{
	if(!isdefined(level.perk_vulture.zones_for_extra_stink_locations))
		level.perk_vulture.zones_for_extra_stink_locations = [];
	level.perk_vulture.zones_for_extra_stink_locations[str_zone] = a_zones;
}

give_vulture()
{
	if(!isdefined(self.perk_vulture))
		self.perk_vulture = SpawnStruct();

	self.perk_vulture.active = true;
	set_client_system_state("vulture_perk_active", "1", self);
	self thread _vulture_perk_think();
}

take_vulture(reason)
{
	if(isdefined(self.perk_vulture) && isdefined(self.perk_vulture.active) && self.perk_vulture.active)
	{
		self.perk_vulture.active = false;

		if(!self maps\_laststand::player_is_in_laststand())
			self.ignoreme = false;

		set_client_system_state("vulture_perk_active", "0", self);
		self set_vulture_overlay(0);
		self.vulture_stink_value = 0;
		set_client_system_state("vulture_perk_disease_meter", "0", self);
		self notify("vulture_perk_lost");
	}
}

vulture_perk_add_invalid_bonus_ammo_weapon(str_weapon)
{
	level.perk_vulture.invalid_bonus_ammo_weapons[level.perk_vulture.invalid_bonus_ammo_weapons.size] = str_weapon;
}

do_vulture_death(player)
{
	if(isdefined(self))
		self thread _do_vulture_death(player);
}

_do_vulture_death(player)
{
	if(should_do_vulture_drop(self.origin))
	{
		str_bonus = get_vulture_drop_type();
		str_identifier = "_" + self GetEntityNumber() + "_" + GetTime();
		v_drop_origin = BulletTrace(self.origin + (0, 0, 50), self.origin - (0, 0, 100), false, self)["position"];
		self thread vulture_drop_funcs(self.origin, player, str_identifier, str_bonus);
	}
}

vulture_drop_funcs(v_origin, player, str_identifier, str_bonus)
{
	vulture_drop_count_increment();
	switch(str_bonus)
	{
		case "ammo":
			e_temp = player _vulture_drop_model(str_identifier, "p6_zm_perk_vulture_ammo", v_origin, (0, 0, 15));
			self thread check_vulture_drop_pickup(e_temp, player, str_identifier, str_bonus);
			break;

		case "points":
			e_temp = player _vulture_drop_model(str_identifier, "p6_zm_perk_vulture_points", v_origin, (0, 0, 15));
			self thread check_vulture_drop_pickup(e_temp, player, str_identifier, str_bonus);
			break;

		case "stink":
			self _drop_zombie_stink(player, str_identifier, str_bonus);
			break;
	}
}

_drop_zombie_stink(player, str_identifier, str_bonus)
{
	self clear_zombie_stink_fx();
	e_temp = player zombie_drops_stink(self, str_identifier);
	e_temp = player _vulture_spawn_fx(str_identifier, self.origin, str_bonus, e_temp);
	clean_up_stink(e_temp);
}

zombie_drops_stink(ai_zombie, str_identifier)
{
	e_temp = ai_zombie.stink_ent;

	if(isdefined(e_temp))
	{
		e_temp thread delay_showing_vulture_ent(self, ai_zombie.origin);
		level.perk_vulture.zombie_stink_array[level.perk_vulture.zombie_stink_array.size] = e_temp;
		self delay_notify(str_identifier, level.zombie_vars["zombies_perk_vulture_pickup_time_stink"]);
	}
	return e_temp;
}

delay_showing_vulture_ent(player, v_moveto_pos, str_model, func)
{
	self.drop_time = GetTime();
	wait_network_frame();
	wait_network_frame();
	self.origin = v_moveto_pos;
	wait_network_frame();

	if(isdefined(str_model))
		self SetModel(str_model);

	self Show();

	if(IsPlayer(player))
	{
		self SetInvisibleToAll();
		self SetVisibleToPlayer(player);
	}

	if(isdefined(func))
		run_function(self, func);
}

clean_up_stink(e_temp)
{
	e_temp ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_STINK_FX);
	level.perk_vulture.zombie_stink_array = array_remove_nokeys(level.perk_vulture.zombie_stink_array, e_temp);
	wait 4;
	e_temp clear_stink_ent();
}

_delete_vulture_ent(n_delay)
{
	if(!isdefined(n_delay))
		n_delay = 0;

	if(n_delay > 0)
	{
		self Hide();
		wait n_delay;
	}

	self clear_bonus_ent();
}

_vulture_drop_model(str_identifier, str_model, v_model_origin, v_offset)
{
	if(!isdefined(v_offset))
		v_offset = (0, 0, 1);
	if(!isdefined(self.perk_vulture_models))
		self.perk_vulture_models = [];

	e_temp = get_unused_bonus_ent();

	if(!isdefined(e_temp))
	{
		self notify(str_identifier);
		return;
	}

	e_temp thread delay_showing_vulture_ent(self, v_model_origin + v_offset, str_model, ::set_vulture_drop_fx);
	self.perk_vulture_models[self.perk_vulture_models.size] = e_temp;
	e_temp SetInvisibleToAll();
	e_temp SetVisibleToPlayer(self);
	e_temp thread _vulture_drop_model_thread(str_identifier, self);
	return e_temp;
}

set_vulture_drop_fx()
{
	self SetClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_DROP_FX);
}

_vulture_drop_model_thread(str_identifier, player)
{
	self thread _vulture_model_blink_timeout(player);
	player waittill_any(str_identifier, "death", "disconnect", "vulture_perk_lost");
	self ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_DROP_FX);
	n_delete_delay = .1;

	if(isdefined(self.picked_up) && self.picked_up)
	{
		self _play_vulture_drop_pickup_fx();
		n_delete_delay = 1;
	}

	if(isdefined(player.perk_vulture_models))
	{
		player.perk_vulture_models = array_remove_nokeys(player.perk_vulture_models, self);
		player.perk_vulture_models = array_removeUndefined(player.perk_vulture_models);
	}

	self _delete_vulture_ent(n_delete_delay);
}

_vulture_model_blink_timeout(player)
{
	self endon("death");
	player endon("death");
	player endon("disconnect");
	self endon("stop_vulture_behavior");
	n_time_total = level.zombie_vars["zombies_perk_vulture_pickup_time"];
	n_frames = n_time_total * 20;
	n_section = Int(n_frames / 6);
	n_flash_slow = n_section * 3;
	n_flash_medium = n_section * 4;
	n_flash_fast = n_section * 5;
	b_show = true;

	for(i = 0; i < n_frames;)
	{
		if(i < n_flash_slow)
			n_multiplier = n_flash_slow;
		else if(i < n_flash_medium)
			n_multiplier = 10;
		else if(i < n_flash_fast)
			n_multiplier = 5;
		else
			n_multiplier = 2;

		if(b_show)
		{
			self Show();
			self SetInvisibleToAll();
			self SetVisibleToPlayer(player);
		}
		else
			self Hide();

		b_show = !b_show;
		i += n_multiplier;
		wait .05 * n_multiplier;
	}
}

_vulture_spawn_fx(str_identifier, v_fx_origin, str_bonus, e_temp)
{
	b_delete = false;

	if(!isdefined(e_temp))
	{
		e_temp = get_unused_bonus_ent();

		if(!isdefined(e_temp))
		{
			self notify(str_identifier);
			return;
		}

		b_delete = true;
	}

	e_temp thread delay_showing_vulture_ent(self, v_fx_origin, "tag_origin", ::clientfield_set_vulture_stink_enabled);

	if(IsPlayer(self))
		self waittill_any(str_identifier, "disconnect", "vulture_perk_lost");
	else
		self waittill(str_identifier);

	if(b_delete)
		e_temp _delete_vulture_ent();
	return e_temp;
}

clientfield_set_vulture_stink_enabled()
{
	self SetClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_STINK_FX);
}

should_do_vulture_drop(v_death_origin)
{
	b_is_inside_playable_area = check_point_in_active_zone(v_death_origin);
	b_ents_are_available = get_unused_bonus_ent_count() > 0;
	b_network_slots_available = level.perk_vulture.drop_slots_for_network < level.zombie_vars["zombies_perk_vulture_network_drops_max"];
	n_roll = RandomInt(100);
	b_passed_roll = n_roll > (100 - level.zombie_vars["zombies_perk_vulture_drop_chance"]);
	b_is_stink_zombie = false;

	if(isdefined(self.is_stink_zombie))
		b_is_stink_zombie = self.is_stink_zombie;

	b_should_drop = true;

	if(!b_is_stink_zombie)
	{
		b_should_drop = false;

		if(b_is_inside_playable_area && b_ents_are_available && b_network_slots_available)
			b_should_drop = b_passed_roll;
	}

	return b_should_drop;
}

get_vulture_drop_type()
{
	n_chance_ammo = level.zombie_vars["zombies_perk_vulture_ammo_chance"];
	n_chance_points = level.zombie_vars["zombies_perk_vulture_points_chance"];
	n_chance_stink = level.zombie_vars["zombies_perk_vulture_stink_chance"];
	n_total_weight = n_chance_ammo + n_chance_points;
	n_cutoff_ammo = n_chance_ammo;
	n_cutoff_points = n_chance_ammo + n_chance_points;
	n_roll = RandomInt(n_total_weight);

	if(n_roll < n_cutoff_ammo)
		str_bonus = "ammo";
	else
		str_bonus = "points";

	if(isdefined(self.is_stink_zombie) && self.is_stink_zombie)
		str_bonus = "stink";

	return str_bonus;
}

get_vulture_drop_duration(str_bonus)
{
	str_dvar = "zombies_perk_vulture_pickup_time";

	if(str_bonus == "stink")
		str_dvar = "zombies_perk_vulture_pickup_time_stink";

	n_duration = level.zombie_vars[str_dvar];
	return n_duration;
}

check_vulture_drop_pickup(e_temp, player, str_identifier, str_bonus)
{
	if(!isdefined(e_temp))
		return;

	player endon("death");
	player endon("disconnect");
	e_temp endon("death");
	e_temp endon("stop_vulture_behavior");
	wait_network_frame();
	n_times_to_check = Int(get_vulture_drop_duration(str_bonus) / .15);
	b_player_inside_radius = false;

	for(i = 0; i < n_times_to_check; i++)
	{
		b_player_inside_radius = DistanceSquared(e_temp.origin, player.origin) < 1024;

		if(b_player_inside_radius)
		{
			e_temp.picked_up = true;
			break;
		}
		else
			wait .15;
	}

	player notify(str_identifier);

	if(b_player_inside_radius)
		player give_vulture_bonus(str_bonus);
}

_handle_zombie_stink(b_player_inside_radius)
{
	if(!isdefined(self.perk_vulture.is_in_zombie_stink))
		self.perk_vulture.is_in_zombie_stink = false;

	b_in_stink_last_check = self.perk_vulture.is_in_zombie_stink;
	self.perk_vulture.is_in_zombie_stink = b_player_inside_radius;

	if(self.perk_vulture.is_in_zombie_stink)
	{
		n_current_time = GetTime();

		if(!b_in_stink_last_check)
		{
			self.perk_vulture.stink_time_entered = n_current_time;
			self toggle_stink_overlay(true);
			self thread stink_react_vo();
		}

		b_should_ignore_player = false;

		if(isdefined(self.perk_vulture.stink_time_entered))
			b_should_ignore_player = ((n_current_time - self.perk_vulture.stink_time_entered) * .001) >= 0;
		if(b_should_ignore_player)
			self.ignoreme = true;

		if(get_targetable_player_count() == 0 || !self are_any_players_in_adjacent_zone())
		{
			if(b_should_ignore_player && !level.perk_vulture.use_exit_behavior)
			{
				level.perk_vulture.use_exit_behavior = true;
				level.default_find_exit_position_override = ::vulture_perk_should_zombies_resume_find_flesh;
				self thread vulture_zombies_find_exit_point();
			}
		}
	}
	else
	{
		if(b_in_stink_last_check)
		{
			self.perk_vulture.stink_time_exit = GetTime();
			self thread _zombies_reacquire_player_after_leaving_stink();
		}
	}
}

stink_react_vo()
{
	self endon("death");
	self endon("disconnect");

	wait 1;

	if(25 > RandomIntRange(1, 100))
		self maps\_zombiemode_audio::create_and_play_dialog("general", "vulture_stink");
}

get_targetable_player_count()
{
	n_targetable_player_count = 0;
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isdefined(player.ignoreme) || !player.ignoreme)
			n_targetable_player_count++;
	}

	return n_targetable_player_count;
}

are_any_players_in_adjacent_zone()
{
	b_players_in_adjacent_zone = false;
	str_zone = self get_current_zone();
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player != self)
		{
			str_zone_compare = player get_current_zone();
			if(IsInArray(level.zones[str_zone].adjacent_zones, str_zone_compare) && is_true(level.zones[str_zone].adjacent_zones[str_zone_compare].is_connected))
			{
				b_players_in_adjacent_zone = true;
				break;
			}
		}
	}

	return b_players_in_adjacent_zone;
}

toggle_stink_overlay(b_show_overlay)
{
	if(!isdefined(self.vulture_stink_value))
		self.vulture_stink_value = 0;

	if(b_show_overlay)
		self thread _ramp_up_stink_overlay();
	else
		self thread _ramp_down_stink_overlay();
}

_ramp_up_stink_overlay()
{
	self notify("vulture_perk_stink_ramp_up_done");
	self endon("vulture_perk_stink_ramp_up_done");
	self endon("death");
	self endon("disconnect");
	self endon("vulture_perk_lost");
	set_client_system_state("sndVultureStink", "1", self);

	if(!isdefined(level.perk_vulture.stink_change_increment))
		level.perk_vulture.stink_change_increment = (Pow(2, 5) * .25) / 8;

	while(self.perk_vulture.is_in_zombie_stink)
	{
		self.vulture_stink_value += level.perk_vulture.stink_change_increment;

		if(self.vulture_stink_value > (Pow(2, 5) - 1))
			self.vulture_stink_value = Pow(2, 5) - 1;

		fraction = self _get_disease_meter_fraction();
		set_client_system_state("vulture_perk_disease_meter", fraction, self);
		self set_vulture_overlay(fraction);
		wait .25;
	}
}

set_vulture_overlay(fraction)
{
	/*state = level.vsmgr["overlay"].info["vulture_stink_overlay"].state;
	if(fraction > 0)
	{
		state maps/mp/_visionset_mgr::vsmgr_set_state_active(self, 1 - fraction);
	}
	else
	{
		state maps/mp/_visionset_mgr::vsmgr_set_state_inactive(self);
	}*/
}

_get_disease_meter_fraction()
{
	return self.vulture_stink_value / (Pow(2, 5) - 1);
}

_ramp_down_stink_overlay()
{
	self notify("vulture_perk_stink_ramp_down_done");
	self endon("vulture_perk_stink_ramp_down_done");
	self endon("death");
	self endon("disconnect");
	self endon("vulture_perk_lost");
	set_client_system_state("sndVultureStink", "0", self);

	if(!isdefined(level.perk_vulture.stink_change_decrement))
		level.perk_vulture.stink_change_decrement = (Pow(2, 5) * .25) / 4;

	while(!self.perk_vulture.is_in_zombie_stink && self.vulture_stink_value > 0)
	{
		self.vulture_stink_value -= level.perk_vulture.stink_change_decrement;

		if(self.vulture_stink_value < 0)
			self.vulture_stink_value = 0;

		fraction = self _get_disease_meter_fraction();
		self set_vulture_overlay(fraction);
		set_client_system_state("vulture_perk_disease_meter", fraction, self);
		wait .25;
	}
}

_zombies_reacquire_player_after_leaving_stink()
{
	self endon("death");
	self endon("disconnect");
	self notify("vulture_perk_stop_zombie_reacquire_player");
	self endon("vulture_perk_stop_zombie_reacquire_player");
	self toggle_stink_overlay(false);

	while(self.vulture_stink_value > 0)
	{
		wait .25;
	}

	self.ignoreme = false;
	level.perk_vulture.use_exit_behavior = false;
}

vulture_perk_should_zombies_resume_find_flesh()
{
	b_should_find_flesh = !is_player_in_zombie_stink();
	return b_should_find_flesh;
}

is_player_in_zombie_stink()
{
	a_players = GetPlayers();
	b_player_in_zombie_stink = false;

	for(i = 0; i < a_players.size; i++)
	{
		if(is_true(a_players[i].is_in_zombie_stink))
		{
			b_player_in_zombie_stink = true;
			break;
		}
	}

	return b_player_in_zombie_stink;
}

give_vulture_bonus(str_bonus)
{
	switch(str_bonus)
	{
		case "ammo":
			self give_bonus_ammo();
			break;

		case "points":
			self give_bonus_points();
			break;

		case "stink":
			self give_bonus_stink();
			break;
	}
}

give_bonus_ammo()
{
	str_weapon_current = self GetCurrentWeapon();

	if(str_weapon_current != "none")
	{
		if(is_valid_ammo_bonus_weapon(str_weapon_current))
		{
			n_ammo_count_current = self GetWeaponAmmoStock(str_weapon_current);
			n_ammo_count_max = WeaponMaxAmmo(str_weapon_current);
			n_ammo_refunded = clamp(Int(n_ammo_count_max * RandomFloatRange(0, .025)), 1, n_ammo_count_max);
			b_is_custom_weapon = self handle_custom_weapon_refunds(str_weapon_current);

			if(!b_is_custom_weapon)
				self SetWeaponAmmoStock(str_weapon_current, n_ammo_count_current + n_ammo_refunded);
		}

		self PlaySoundToPlayer("zmb_perks_vulture_pickup", self);

		if(15 > RandomIntRange(1, 100))
			self thread maps\_zombiemode_audio::create_and_play_dialog("general", "vulture_ammo_drop");
	}
}

is_valid_ammo_bonus_weapon(str_weapon)
{
	if(!is_placeable_mine(str_weapon))
		return !IsInArray(level.perk_vulture.invalid_bonus_ammo_weapons, str_weapon);
	return false;
}

_play_vulture_drop_pickup_fx()
{
	self SetClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_DROP_PICKUP);
}

give_bonus_points(v_fx_origin)
{
	n_multiplier = RandomIntRange(1, 5);
	self maps\_zombiemode_score::player_add_points("thundergun_fling", 5 * n_multiplier);
	self PlaySoundToPlayer("zmb_perks_vulture_money", self);

	if(15 > RandomIntRange(1, 100))
		self thread maps\_zombiemode_audio::create_and_play_dialog("general", "vulture_money_drop");
}

give_bonus_stink(v_drop_origin)
{
	self _handle_zombie_stink(false);
}

_vulture_perk_think()
{
	self endon("death");
	self endon("disconnect");
	self endon("vulture_perk_lost");

	while(true)
	{
		b_player_in_zombie_stink = false;
		if(!isdefined(level.perk_vulture.zombie_stink_array))
			level.perk_vulture.zombie_stink_array = [];

		if(level.perk_vulture.zombie_stink_array.size > 0)
		{
			a_close_points = get_array_of_closest(self.origin, level.perk_vulture.zombie_stink_array, undefined, undefined, 300);
			if(a_close_points.size > 0)
				b_player_in_zombie_stink = self _is_player_in_zombie_stink(a_close_points);
		}

		self _handle_zombie_stink(b_player_in_zombie_stink);
		wait RandomFloatRange(.25, .5);
	}
}

_is_player_in_zombie_stink(a_points)
{
	b_is_in_stink = false;

	for(i = 0; i < a_points.size; i++)
	{
		if(DistanceSquared(a_points[i].origin, self.origin) < 4900)
		{
			b_is_in_stink = true;
			break;
		}
	}

	return b_is_in_stink;
}

vulture_drop_count_increment()
{
	level.perk_vulture.drop_slots_for_network++;
	level thread _decrement_network_slots_after_time();
}

_decrement_network_slots_after_time()
{
	wait level.zombie_vars["zombies_perk_vulture_network_time_frame"] * .001;
	level.perk_vulture.drop_slots_for_network --;
}

vulture_zombie_spawn_func()
{
	self endon("death");
	self thread add_zombie_eye_glow();
	self waittill("completed_emerging_into_playable_area");

	if(self should_zombie_have_stink())
		self stink_zombie_array_add();
}

add_zombie_eye_glow()
{
	self endon("death");
	self waittill("risen");
	self SetClientFlag(level._ZOMBIE_ACTOR_VULTURE_EYE_GLOW);
}

zombies_drop_stink_on_death()
{
	self ClearClientFlag(level._ZOMBIE_ACTOR_VULTURE_EYE_GLOW);

	if(isdefined(self.attacker) && IsPlayer(self.attacker) && self.attacker has_perk("vulture"))
		self thread do_vulture_death(self.attacker);
	else
	{
		if(is_true(self.is_stink_zombie) && isdefined(self.stink_ent))
		{
			str_identifier = "_" + self GetEntityNumber() + "_" + GetTime();
			self thread _drop_zombie_stink(level, str_identifier, "stink");
		}
	}
}

clear_zombie_stink_fx()
{
	self ClearClientFlag(level._ZOMBIE_ACTOR_VULTURE_STINK_TRAIL_FX);
}

stink_zombie_array_add()
{
	if(get_unused_stink_ent_count() > 0)
	{
		self.stink_ent = get_unused_stink_ent();

		if(isdefined(self.stink_ent))
		{
			self.stink_ent.owner = self;
			wait_network_frame();
			wait_network_frame();
			self SetClientFlag(level._ZOMBIE_ACTOR_VULTURE_STINK_TRAIL_FX);
			level.perk_vulture.last_stink_zombie_spawned = GetTime();
			self.is_stink_zombie = true;
		}
	}
	else
		self.is_stink_zombie = false;
}

should_zombie_have_stink()
{
	b_is_zombie = false;

	if(isdefined(self.animname))
		b_is_zombie = self.animname == "zombie";

	b_cooldown_up = (GetTime() - level.perk_vulture.last_stink_zombie_spawned) > (level.zombie_vars["zombies_perk_vulture_spawn_stink_zombie_cooldown"] * 1000);
	b_roll_passed = (100 - RandomInt(100)) > 50;
	b_stink_ent_available = get_unused_stink_ent_count() > 0;
	b_should_have_stink = false;

	if(b_is_zombie && b_roll_passed && b_cooldown_up)
		b_should_have_stink = b_stink_ent_available;
	return b_should_have_stink;
}

vulture_perk_watch_mystery_box()
{
	flag_wait("all_players_connected");
	wait_network_frame();

	while(isdefined(level.chests) && level.chests.size > 0 && isdefined(level.chest_index))
	{
		level.chests[level.chest_index] vulture_perk_shows_mystery_box(true);
		flag_wait("moving_chest_now");
		level.chests[level.chest_index] vulture_perk_shows_mystery_box(false);
		flag_waitopen("moving_chest_now");
	}
}

vulture_perk_shows_mystery_box(b_show)
{
	if(b_show)
		self.chest SetClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_MYSTERY_BOX);
	else
		self.chest ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_MYSTERY_BOX);
}

vulture_perk_watch_fire_sale()
{
	wait_network_frame();

	while(isdefined(level.chests) && level.chests.size > 0)
	{
		level waittill("powerup fire sale");

		for(i = 0; i < level.chests.size; i++)
		{
			if(i != level.chest_index)
				level.chests[i] thread vulture_fire_sale_box_fx_enable();
		}

		level waittill("fire_sale_off");

		for(i = 0; i < level.chests.size; i++)
		{
			if(i != level.chest_index)
				level.chests[i] thread vulture_fire_sale_box_fx_disable();
		}
	}
}

vulture_fire_sale_box_fx_enable()
{
	/*if(self.zbarrier.state == "arriving")
	{
		self.zbarrier waittill("arrived");
	}*/
	self.chest SetClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_MYSTERY_BOX);
}

vulture_fire_sale_box_fx_disable()
{
	self.chest ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_MYSTERY_BOX);
}

vulture_perk_watch_powerup_drops()
{
	while(true)
	{
		level waittill("powerup_dropped", m_powerup);
		m_powerup thread _powerup_drop_think();
	}
}

_powerup_drop_think()
{
	e_temp = spawn_model("tag_origin", self.origin, self.angles);
	e_temp SetClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_POWERUP_DROP);
	self waittill_any("powerup_timedout", "powerup_grabbed", "death");
	e_temp ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_POWERUP_DROP);
	wait_network_frame();
	wait_network_frame();
	wait_network_frame();
	e_temp Delete();
}

vulture_zombies_find_exit_point()
{
	array_thread(get_round_enemy_array(), ::zombie_goes_to_exit_location);
}

zombie_goes_to_exit_location()
{
	self endon("death");

	if(self.ignoreme)
	{
		while(true)
		{
			b_passed_override = true;

			if(isdefined(level.default_find_exit_position_override))
				b_passed_override = run_function(self, level.default_find_exit_position_override);

			if(!flag("wait_and_revive") && b_passed_override)
				return;
			if(!self.ignoreme)
				break;

			wait_network_frame();
		}
	}

	s_goal = _get_zombie_exit_point();
	self notify("stop_find_flesh");
	self notify("zombie_acquire_enemy");

	if(isdefined(s_goal))
		self SetGoalPos(s_goal.origin);

	while(true)
	{
		b_passed_override = true;

		if(isdefined(level.default_find_exit_position_override))
				b_passed_override = run_function(self, level.default_find_exit_position_override);

		if(!flag("wait_and_revive") && b_passed_override)
			break;
		else
			wait .1;
	}

	self thread maps\_zombiemode_spawner::find_flesh();
}

_get_zombie_exit_point()
{
	player = getHostPlayer();
	n_dot_best = 9999999;
	a_exit_points = run_function(self, level.perk_vulture.func_zombies_find_valid_exit_locations);
	nd_best = undefined;

	for(i = 0; i < a_exit_points.size; i++)
	{
		v_to_player = VectorNormalize(player.origin - self.origin);
		v_to_goal = a_exit_points[i].origin - self.origin;
		n_dot = VectorDot(v_to_player, v_to_goal);

		if(n_dot < n_dot_best && DistanceSquared(player.origin, a_exit_points[i].origin) > 360000)
		{
			nd_best = a_exit_points[i];
			n_dot_best = n_dot;
		}
	}

	return nd_best;
}

get_valid_exit_points_for_zombie()
{
	a_exit_points = level.enemy_dog_locations;

	if(isdefined(level.perk_vulture.zones_for_extra_stink_locations) && level.perk_vulture.zones_for_extra_stink_locations.size > 0)
	{
		a_zones_with_extra_stink_locations = GetArrayKeys(level.perk_vulture.zones_for_extra_stink_locations);

		for(j = 0; j < level.active_zone_names.size; j++)
		{
			zone = level.active_zone_names.size[j];

			if(IsInArray(a_zones_with_extra_stink_locations, zone))
			{
				a_zones_temp = level.perk_vulture.zones_for_extra_stink_locations[zone];

				for(i = 0; i < a_zones_temp.size; i++)
				{
					a_exit_points = array_combine(a_exit_points, get_zone_dog_locations(a_zones_temp[i]));
				}
			}
		}
	}
	return a_exit_points;
}

get_zone_dog_locations(str_zone)
{
	a_dog_locations = [];

	if(isdefined(level.zones[str_zone]) && isdefined(level.zones[str_zone].dog_locations))
		a_dog_locations = level.zones[str_zone].dog_locations;

	return a_dog_locations;
}

vulture_handle_solo_quick_revive()
{
	flag_wait("all_players_connected");

	if(flag("solo_game"))
	{
		flag_wait("solo_revive");
		set_client_system_state("vulture_perk_disable_solo_quick_revive_glow", "1");
	}
}

initialize_bonus_entity_pool()
{
	n_ent_pool_size = level.zombie_vars["zombies_perk_vulture_drops_max"];
	level.perk_vulture.bonus_drop_ent_pool = [];

	for(i = 0; i < n_ent_pool_size; i++)
	{
		e_temp = spawn_model("tag_origin", (0, 0, 1), (0, 0, 0));
		e_temp.targetname = "vulture_perk_bonus_pool_ent";
		e_temp.in_use = false;
		level.perk_vulture.bonus_drop_ent_pool[level.perk_vulture.bonus_drop_ent_pool.size] = e_temp;
	}
}

get_unused_bonus_ent()
{
	e_found = undefined;

	for(i = 0; i < level.perk_vulture.bonus_drop_ent_pool.size; i++)
	{
		if(!level.perk_vulture.bonus_drop_ent_pool[i].in_use)
		{
			e_found = level.perk_vulture.bonus_drop_ent_pool[i];
			e_found.in_use = true;
			break;
		}
	}

	return e_found;
}

get_unused_bonus_ent_count()
{
	n_found = 0;

	for(i = 0; i < level.perk_vulture.bonus_drop_ent_pool.size; i++)
	{
		if(!level.perk_vulture.bonus_drop_ent_pool[i].in_use)
			n_found++;
	}
	return n_found;
}

clear_bonus_ent()
{
	self notify("stop_vulture_behavior");
	self ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_DROP_FX);
	self.in_use = false;
	self SetModel("tag_origin");
	self Hide();
}

initialize_stink_entity_pool()
{
	n_ent_pool_size = level.zombie_vars["zombies_perk_vulture_max_stink_zombies"];
	level.perk_vulture.stink_ent_pool = [];

	for(i = 0; i < n_ent_pool_size; i++)
	{
		e_temp = spawn_model("tag_origin", (0, 0, 1), (0, 0, 0));
		e_temp.targetname = "vulture_perk_bonus_pool_ent";
		e_temp.in_use = false;
		level.perk_vulture.stink_ent_pool[level.perk_vulture.stink_ent_pool.size] = e_temp;
	}
}

get_unused_stink_ent_count()
{
	n_found = 0;

	for(i = 0; i < level.perk_vulture.stink_ent_pool.size; i++)
	{
		if(!level.perk_vulture.stink_ent_pool[i].in_use)
		{
			n_found++;
			continue;
		}
		else
		{
			if(!isdefined(level.perk_vulture.stink_ent_pool[i].owner) && !isdefined(level.perk_vulture.stink_ent_pool[i].drop_time))
			{
				level.perk_vulture.stink_ent_pool[i] clear_stink_ent();
				n_found++;
			}
		}
	}

	return n_found;
}

get_unused_stink_ent()
{
	e_found = undefined;

	for(i = 0; i < level.perk_vulture.stink_ent_pool.size; i++)
	{
		if(!level.perk_vulture.stink_ent_pool[i].in_use)
		{
			e_found = level.perk_vulture.stink_ent_pool[i];
			e_found.in_use = true;
			break;
		}
	}

	return e_found;
}

clear_stink_ent()
{
	self ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_VULTURE_STINK_FX);
	self notify("stop_vulture_behavior");
	self.in_use = false;
	self.drop_time = undefined;
	self.owner = undefined;
	self SetModel("tag_origin");
	self Hide();
}

handle_custom_weapon_refunds(str_weapon)
{
	b_is_custom_weapon = false;

	if(maps\apex\_zm_melee_weapon::is_ballistic_knife(str_weapon))
	{
		self _refund_oldest_ballistic_knife(str_weapon);
		b_is_custom_weapon = true;
	}

	return b_is_custom_weapon;
}

_refund_oldest_ballistic_knife(str_weapon)
{
	self endon("death");
	self endon("disconnect");
	self endon("vulture_perk_lost");

	if(isdefined(self.weaponobjectwatcherarray) && self.weaponobjectwatcherarray.size > 0)
	{
		s_found = undefined;

		for(i = 0; i < self.weaponobjectwatcherarray.size; i++)
		{
			if(isdefined(self.weaponobjectwatcherarray[i].weapon) && self.weaponobjectwatcherarray[i].weapon == str_weapon)
			{
				s_found = self.weaponobjectwatcherarray[i];
				break;
			}
		}

		if(isdefined(s_found))
		{
			if(isdefined(s_found.objectarray) && s_found.objectarray.size > 0)
			{
				e_oldest = undefined;

				for(i = 0; i < s_found.objectarray.size; i++)
				{
					if(isdefined(s_found.objectarray[i]))
					{
						if((isdefined(s_found.objectarray[i].retrievabletrigger) && isdefined(s_found.objectarray[i].retrievabletrigger.owner) && s_found.objectarray[i].retrievabletrigger.owner != self) || !isdefined(s_found.objectarray[i].birthtime))
							continue;
						else
						{
							if(!isdefined(e_oldest))
								e_oldest = s_found.objectarray[i];
							if(s_found.objectarray[i].birthtime < e_oldest.birthtime)
								e_oldest = s_found.objectarray[i];
						}
					}
				}

				if(isdefined(e_oldest))
					self thread maps\_ballistic_knife::pick_up(str_weapon, e_oldest, e_oldest.retrievabletrigger);
			}
		}
	}
}