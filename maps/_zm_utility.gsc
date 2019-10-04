#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

// Perks
can_player_purchase_perk()
{
	perk_limit = self get_player_perk_purchase_limit();

	if(self.num_perks >= perk_limit)
		return false;
	return true;
}

get_player_perk_purchase_limit()
{
	if(isdefined(level.get_player_perk_purchase_limit))
		return run_function(self, level.get_player_perk_purchase_limit);
	return level.zombie_vars["zombie_perk_limit"];
}

has_perk(perk)
{
	perk_state = self maps\_zm_perks::get_player_perk_state(perk);
	return perk_state == 1 || perk_state == 3; // 'Obtained' or 'Unpaused'
}

has_perk_paused(perk)
{
	return self maps\_zm_perks::get_player_perk_state(perk) == 2; // 'Paused'
}

get_perk_array()
{
	perk_array = [];
	perks = maps\_zm_perks::get_valid_perk_array();

	for(i = 0; i < perks.size; i++)
	{
		if(self has_perk(perks[i]))
			perk_array[perk_array.size] = perks[i];
	}
	return perk_array;
}

give_perk(perk, bought)
{
	self maps\_zm_perks::give_perk_core(perk, bought);
}

give_random_perk()
{
	perks = maps\_zm_perks::get_valid_perk_array();
	obtained_perks = self get_perk_array();
	perks = array_exclude(perks, obtained_perks);

	if(!isdefined(perks) || perks.size == 0)
		return undefined;

	perk = random(perks);

	if(!isdefined(perk))
		return undefined;

	self give_perk(perk, false);
	return perk;
}

take_perk(perk)
{
	self notify(perk + "_stop");
}

lose_random_perk()
{
	perks = maps\_zm_perks::get_valid_perk_array();

	if(!isdefined(perks) || perks.size == 0)
		return undefined;

	perks = array_randomize(perks);

	for(i = 0; i < perks.size; i++)
	{
		if(self has_perk(perks[i]) || self has_perk_paused(perks[i]))
		{
			self take_perk(perks[i]);
			return perks[i];
		}
	}
	return undefined;
}

pause_perk(perk)
{
	self maps\_zm_perks::pause_perk_core(perk);
}

unpause_perk(perk, bought)
{
	self maps\_zm_perks::unpause_perk_core(perk);
}

perk_abort_drinking(post_delay)
{
	if(self is_drinking())
	{
		self notify("perk_abort_drinking");
		self decrement_is_drinking();
		self enable_player_move_states();

		if(isdefined(post_delay))
			wait post_delay;
	}
}

// Health
register_player_health(func_qualifier, amount)
{
	if(!isdefined(level._zm_player_health_types))
		level._zm_player_health_types = [];

	struct = SpawnStruct();
	struct.func_qualifier = func_qualifier;
	struct.amount = amount;

	level._zm_player_health_types[level._zm_player_health_types.size] = struct;
}

set_player_max_health(set_preMaxHealth, clamp_health_to_max_health)
{
	n_total_health = level.zombie_vars["player_base_health"];

	if(isdefined(level._zm_player_health_types))
	{
		for(i = 0; i < level._zm_player_health_types.size; i++)
		{
			if(!isdefined(level._zm_player_health_types[i].amount))
				continue;

			can_apply = true;

			if(isdefined(level._zm_player_health_types[i].func_qualifier))
				can_apply = run_function(self, level._zm_player_health_types[i].func_qualifier);

			if(can_apply)
			{
				if(IsInt(level._zm_player_health_types[i].amount))
					n_total_health += level._zm_player_health_types[i].amount;
				else
					n_total_health += run_function(self, level._zm_player_health_types[i].amount);
			}
		}
	}

	n_total_health = Int(n_total_health); // health requires ints not floats

	if(is_true(set_preMaxHealth))
		self.preMaxHealth = self.maxhealth;

	self.maxhealth = n_total_health;
	self SetmaxHealth(n_total_health);

	if(is_true(clamp_health_to_max_health))
		self.health = Int(Min(self.health, n_total_health)); // .health only takes ints not floats
}

// Score
can_player_purchase(cost)
{
	if(self.score < cost)
		return false;
	return true;
}

player_can_score_from_zombies()
{
	if(is_true(self.inhibit_scoring_from_zombies))
		return false;
	return true;
}

// Trigger Per Player
register_playertrigger(struct, trigger_func)
{
	if(!isdefined(level.trigger_per_player))
		level.trigger_per_player = [];

	struct.trigger_pool = [];
	struct.trigger_func = trigger_func;

	level.trigger_per_player[level.trigger_per_player.size] = struct;
}

unregister_playertrigger(struct)
{
	if(!isdefined(level.trigger_per_player))
		level.trigger_per_player = [];

	level.trigger_per_player = array_remove_nokeys(level.trigger_per_player, struct);

	if(isdefined(struct.trigger_pool))
	{
		keys = GetArrayKeys(struct.trigger_pool);

		for(i = 0; i < keys.size; i++)
		{
			if(isdefined(struct.trigger_pool[keys[i]]))
			{
				struct.trigger_pool[keys[i]] notify("kill_trigger");
				struct.trigger_pool[keys[i]] Delete();
			}
		}

		struct.trigger_pool = undefined;
	}
}

// Equipment
is_equipment_that_blocks_purchase(weapon)
{
	return is_equipment(weapon);
}

// Weapons
get_player_weapon_limit()
{
	limit = level.zombie_vars["zombie_weapons_base_limit"];

	if(self has_perk("additionalprimaryweapon"))
		limit += level.zombie_vars["zombie_perk_additionalprimaryweapon_count"];
	return limit;
}

is_alt_weapon(weapon)
{
	return isdefined(level._zm_alt_weapons) && IsInArray(level._zm_alt_weapons, weapon);
}

is_lh_weapon(weapon)
{
	return isdefined(level._zm_lh_weapons) && IsInArray(level._zm_lh_weapons, weapon);
}

is_ballistic_knife(weapon)
{
	stats = maps\_zm_weapons::get_weapon_stats(weapon);
	return is_true(stats.is_ballistic_knife);
}

is_flourish_weapon(weapon)
{
	return IsSubStr(weapon, "flourish");
}

// Riot Shield
is_weapon_riotshield(weapon_name)
{
	return false;
}

is_player_riotshield(weapon_name)
{
	return is_weapon_riotshield(weapon_name) && self.current_player_riot_shield == weapon_name;
}

set_player_riotshield(weapon_name)
{
	if(is_weapon_riotshield(weapon_name))
		self.current_player_riot_shield = weapon_name;
}

get_player_riotshield(weapon_name)
{
	return self.current_player_riot_shield;
}

// Hero Weapons
is_hero_weapon(weapon)
{
	return false;
}

set_player_hero_weapon(weapon_name)
{
	if(is_hero_weapon(weapon_name))
		self.current_player_hero_weapon = weapon_name;
}

get_player_hero_weapon()
{
	return self.current_player_hero_weapon;
}

is_player_hero_weapon(weapon_name)
{
	if(!is_hero_weapon(weapon_name))
		return false;
	return self.current_player_hero_weapon == weapon_name;
}

get_player_hero_weapon_power()
{
	return self.hero_weapon_power;
}

// Callbacks
_AddCallback(type, func)
{
	if(!isdefined(level._callbacks))
		level._callbacks = [];
	if(!isdefined(level._callbacks[type]))
		level._callbacks[type] = [];

	maps\_callbackglobal::AddCallback(type, func);
}

_RemoveCallback(type, func)
{
	if(isdefined(level._callbacks) && isdefined(level._callbacks[type]))
		maps\_callbackglobal::RemoveCallback(type, func);
}

_Callback(type)
{
	if(!isdefined(level._callbacks))
		return;
	if(!isdefined(level._callbacks[type]))
		return;
	if(level._callbacks[type].size == 0)
		return;

	self maps\_callbackglobal::Callback(type);
}

OnPlayerSpawned_Callback(func)
{
	_AddCallback("on_player_spawned", func);
}

OnPlayerSpawned_CallbackRemove(func)
{
	_RemoveCallback("on_player_spawned", func);
}

// Client Sound / FX
// Original Creator: xSanchez78
create_loop_fx_to_player(player, identifier, fx_var, origin, angles)
{
	str_origin = vector_to_string(origin);
	str_angles = vector_to_string(angles);
	str_clientstate = "fx:looping:start:" + identifier + ":" + fx_var + ":" + str_origin + ":" + str_angles;
	set_client_system_state("client_side_fx", str_clientstate, player);
}

destroy_loop_fx_to_player(player, identifier, delete_fx_immeditately)
{
	str_delete_fx_immeditately = bool_to_string(delete_fx_immeditately);
	str_clientstate = "fx:looping:stop:" + identifier + ":" + str_delete_fx_immeditately;
	set_client_system_state("client_side_fx", str_clientstate, player);
}

play_oneshot_fx_to_player(player, fx_var, origin, angles)
{
	str_origin = vector_to_string(origin);
	str_angles = vector_to_string(angles);
	str_clientstate = "fx:oneshot:" + fx_var + ":" + str_origin + ":" + str_angles;
	set_client_system_state("client_side_fx", str_clientstate, player);
}

create_loop_sound_to_player(player, identifier, alias, origin, fade_time)
{
	str_origin = vector_to_string(origin);
	str_fade_time = string(fade_time);
	str_clientstate = "sound:looping:start:" + identifier + ":" + alias + ":" + str_origin + ":" + str_fade_time;
	set_client_system_state("client_side_fx", str_clientstate, player);
}

destroy_loop_sound_to_player(player, identifier, fade_time)
{
	str_fade_time = string(fade_time);
	str_clientstate = "sound:looping:stop:" + identifier + ":" + str_fade_time;
	set_client_system_state("client_side_fx", str_clientstate, player);
}

play_oneshot_sound_to_player(player, alias, origin)
{
	str_origin = vector_to_string(origin);
	str_clientstate = "sound:oneshot:" + alias + ":" + str_origin;
	set_client_system_state("client_side_fx", str_clientstate, player);
}

// Visionset MGR
visionset_activate(visionset_name)
{
	set_client_system_state("_visionset_mgr", "activate:" + visionset_name, self);
}

visionset_activate_all_players(visionset_name)
{
	array_run(GetPlayers(), ::visionset_activate, visionset_name);
}

visionset_deactivate(visionset_name)
{
	set_client_system_state("_visionset_mgr", "deactivate:" + visionset_name, self);
}

visionset_deactivate_all_players(visionset_name)
{
	array_run(GetPlayers(), ::visionset_deactivate, visionset_name);
}

// Common
run_function(self_ent, func, arg1, arg2, arg3, arg4, arg5, arg6)
{
	if(!isdefined(func))
		return undefined;
	if(!isdefined(self_ent))
		self_ent = level;

	if(isdefined(arg6))
		return self_ent [[func]](arg1, arg2, arg3, arg4, arg5, arg6);
	else if(isdefined(arg5))
		return self_ent [[func]](arg1, arg2, arg3, arg4, arg5);
	else if(isdefined(arg4))
		return self_ent [[func]](arg1, arg2, arg3, arg4);
	else if(isdefined(arg3))
		return self_ent [[func]](arg1, arg2, arg3);
	else if(isdefined(arg2))
		return self_ent [[func]](arg1, arg2);
	else if(isdefined(arg1))
		return self_ent [[func]](arg1);
	else
		return self_ent [[func]]();
}

levelNotify(state, player)
{
	setClientSysState("levelNotify", state, player);
}

increment_downed_stat()
{
	self.downs++;
	self.stats["downs"] = self.downs;
	SetDvar("player" + self GetEntityNumber() + "downs", self.downs);
}

get_round_enemy_array()
{
	a_ai_enemies = GetAITeamArray("axis");
	a_ai_valid_enemies = [];

	for(i = 0; i < a_ai_enemies.size; i++)
	{
		if(is_true(a_ai_enemies[i].ignore_enemy_count))
			continue;
		a_ai_valid_enemies[a_ai_valid_enemies.size] = a_ai_enemies[i];
	}
	return a_ai_valid_enemies;
}

set_client_system_state(system, state, player)
{
	if(!isdefined(state))
		return;
	if(!isdefined(system))
		return;

	setClientSysState("apex_client_sys", system + "|" + state, player);
}

wait_network_frame_multi(n_count)
{
	if(!isdefined(n_count))
		n_count = 1;

	if(NumRemoteClients())
	{
		for(i = 0; i < n_count; i++)
		{
			snapshot_ids = GetSnapshotIndexArray();
			acked = undefined;

			while(!isdefined(acked))
			{
				level waittill("snapacknowledged");
				acked = SnapshotAcknowledged(snapshot_ids);
			}
		}
	}
	else
		wait .1 * n_count;
}

can_buy_weapon()
{
	if(self is_drinking())
		return false;
	if(self hacker_active())
		return false;

	weapon = self GetCurrentWeapon();

	if(weapon == "none" || weapon == "syerette_sp")
		return false;
	if(is_placeable_mine(weapon) || is_equipment_that_blocks_purchase(weapon))
		return false;
	if(self in_revive_trigger())
		return false;
	if(!is_player_valid(self))
		return false;
	return true;
}

enable_player_move_states()
{
	self AllowCrouch(true);
	self AllowLean(true);
	self AllowAds(true);
	self AllowSprint(true);
	self AllowProne(true);
	self AllowMelee(true);
}

disable_player_move_states(forceStanceChange)
{
	self AllowCrouch(true);
	self AllowLean(false);
	self AllowAds(false);
	self AllowSprint(false);
	self AllowProne(false);
	self AllowMelee(false);

	if(is_true(forceStanceChange))
	{
		if(self GetStance() == "prone")
			self SetStance("crouch");
	}
}

is_internal_map()
{
	switch(get_mapname())
	{
		case "zombie_theater":
		case "zombie_pentagon":
		case "zombie_cosmodrome":
		case "zombie_coast":
		case "zombie_temple":
		case "zombie_moon":
		case "zombie_cod5_prototype":
		case "zombie_cod5_asylum":
		case "zombie_cod5_sumpf":
		case "zombie_cod5_factory":
			return true;

		default:
			return false;
	}
}

is_custom_map()
{
	return !is_internal_map();
}

is_solo_game()
{
	if(flag_exists("all_players_connected") && flag("all_players_connected"))
		return GetPlayers().size < 2;
	else
		return GetNumExpectedPlayers() < 2;
}

get_mapname()
{
	if(isdefined(level.script))
		return level.script;
	else
		return ToLower(GetDvarString(#"mapname"));
}

getHostPlayer()
{
	return get_host();
}

play_crazi_sound()
{
	array_thread(GetPlayers(), ::_play_crazi_sound);
}

_play_crazi_sound()
{
	self PlayLocalSound("zmb_laugh_child");
}

// Array
array_run(a_ents, func, arg1, arg2, arg3, arg4, arg5, arg6)
{
	if(!isdefined(func))
		return;
	if(!isdefined(a_ents) || a_ents.size == 0)
		return;

	keys = GetArrayKeys(a_ents);

	for(i = 0; i < keys.size; i++)
	{
		run_function(a_ents[keys[i]], func, arg1, arg2, arg3, arg4, arg5, arg6);
	}
}

// String
string_to_vector(str)
{
	tokens = StrTok(str, ",");
	x = string_to_float(tokens[0]);
	y = string_to_float(tokens[1]);
	z = string_to_float(tokens[2]);
	return (x, y, z);
}

string_to_bool(str)
{
	switch(ToLower(str))
	{
		case "true": return true;
		case "false": return false;
		default: break;
	}
	return Int(str) >= 1;
}

vector_to_string(vec)
{
	x = vec[0];
	y = vec[1];
	z = vec[2];
	return x + "," + y + "," + z;
}

bool_to_string(bool)
{
	if(is_true(bool))
		return "TRUE";
	return "FALSE";
}

// Engine
GetDvarString(dvar, default_value)
{
	val = GetDvar(dvar);

	if(!isdefined(val) || val == "")
	{
		// SetDvar(val, default_value);
		val = default_value;
	}
	return val;
}

SetInvisibleToAll()
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		self SetInvisibleToPlayer(players[i], true);
	}
}

GetNodesInRadiusSorted(origin, max_radius, min_radius, max_height, node_type, max_nodes)
{
	nodes = GetAllNodes();
	valid_nodes = [];

	for(i = 0; i < nodes.size; i++)
	{
		if(isdefined(nodes[i].targetname))
			continue;
		if(DistanceSquared(origin, nodes[i].origin) < (min_radius * min_radius))
			continue;
		if(DistanceSquared(origin, nodes[i].origin) > (max_radius * max_radius))
			continue;
		if(Abs(origin[2] - nodes[i].origin[2]) > max_height)
			continue;
		valid_nodes[valid_nodes.size] = nodes[i];
	}

	if(!isdefined(valid_nodes) || valid_nodes.size == 0)
		return [];

	return get_array_of_closest(origin, valid_nodes);
}

PlaySoundWithNotify(aliasname, notification_string)
{
	self PlaySound(aliasname, notification_string);
}

// Mostly wrappers - old utility to newer engine
IsInArray(array, val)
{
	return is_in_array(array, val);
}

ArrayRemoveValue(array, value, preserve_keys)
{
	return array_remove(array, value, preserve_keys);
}

GetAITeamArray(team)
{
	return GetAISpeciesArray(team, "all");
}