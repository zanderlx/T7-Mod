#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility_code;

//============================================================================================
// Perk Utility Functions
//============================================================================================
has_perk(perk)
{
	if(!maps\apex\_zm_perks::is_perk_valid(perk))
		return false;
	return IsInArray(self._obtained_perks, perk);
}

perk_abort_drinking(post_delay)
{
	if(isdefined(self.is_drinking) && self is_drinking())
	{
		self notify("perk_abort_drinking");
		self decrement_is_drinking();
		self enable_player_move_states();

		if(isdefined(post_delay) && post_delay > 0)
			wait post_delay;
	}
}

get_player_perk_purchase_limit()
{
	perk_limit = level.zombie_vars["zombie_perk_limit"];

	if(isdefined(self.get_player_perk_purchase_limit))
		return run_function(self, self.get_player_perk_purchase_limit);
	return perk_limit;
}

get_player_obtained_perks()
{
	return self._obtained_perks;
}

get_player_unobtained_perks()
{
	perks = maps\apex\_zm_perks::get_valid_perks_array();
	return array_exclude(perks, self get_player_obtained_perks());
}

//============================================================================================
// Weapon Utility Functions
//============================================================================================
get_player_weapon_limit()
{
	if(isdefined(self.get_player_weapon_limit))
		return run_function(self, self.get_player_weapon_limit);
	if(isdefined(level.get_player_weapon_limit))
		return run_function(level, level.get_player_weapon_limit);

	weapon_limit = 2;

	if(self has_perk("mule_kick"))
		weapon_limit = level.additionalprimaryweapon_limit;
	return weapon_limit;
}

//============================================================================================
// Common Utility Functions
//============================================================================================
increment_downed_stat()
{
	self.downs++;
	self.stats["downs"] = self.downs;
	SetDvar("player" + self GetEntityNumber() + "downs", self.downs);
}

get_round_enemy_array()
{
	a_ai_enemies = GetAITeamArray(level.zombie_team);
	a_ai_valid_enemies = [];

	for(i = 0; i < a_ai_enemies.size; i++)
	{
		if(is_true(a_ai_enemies[i].ignore_enemy_count))
			continue;
		a_ai_valid_enemies[a_ai_valid_enemies.size] = a_ai_enemies[i];
	}
	return a_ai_valid_enemies;
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

is_equal(a, b)
{
	if(!isdefined(a) && !isdefined(b))
		return true;
	if(!isdefined(a) || !isdefined(b))
		return false;
	return a == b;
}

// string(val) // Exists in maps\_utility

vector_to_string(vec)
{
	x = vec[0];
	y = vec[1];
	z = vec[2];

	return string(x) + "," + string(y) + "," + string(z);
}

bool_to_string(val)
{
	if(is_true(val))
		return "1";
	return "0";
}

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
	}

	return Int(str) > 0;
}

// string_to_float(str) // Exists in maps\_zombiemode_utility

levelNotify(message)
{
	if(isdefined(self) && IsPlayer(self))
		setClientSysState("levelNotify", message, self);
	else
		array_func(GetPlayers(), ::levelNotify, message);
}

run_function(entity, func, arg1, arg2, arg3, arg4, arg5) // the same as single_func() but returns value from the function
{
	if(!isdefined(func))
		return undefined;
	if(!isdefined(entity))
		entity = level;

	if(isdefined(arg5))
		return entity [[func]](arg1, arg2, arg3, arg4, arg5);
	else if(isdefined(arg4))
		return entity [[func]](arg1, arg2, arg3, arg4);
	else if(isdefined(arg3))
		return entity [[func]](arg1, arg2, arg3);
	else if(isdefined(arg2))
		return entity [[func]](arg1, arg2);
	else if(isdefined(arg1))
		return entity [[func]](arg1);
	else
		return entity [[func]]();
}

//============================================================================================
// Engine Functions / Wrappers
//============================================================================================
GetDvarString(dvar_name, default_value)
{
	val = GetDvar(dvar_name);

	if(isdefined(default_value))
	{
		if(!isdefined(val) || val == "")
			return default_value;
	}

	return val;
}

GetDvarBool(dvar_name, default_value)
{
	return string_to_bool(GetDvarString(dvar_name, default_value));
}

/#
GetDebugDvarString(dvar_name, default_value)
{
	val = GetDebugDvar(dvar_name);

	if(isdefined(default_value))
	{
		if(!isdefined(val) || val == "")
			return default_value;
	}

	return val;
}

GetDebugDvarBool(dvar_name, default_value)
{
	return string_to_bool(GetDebugDvarString(dvar_name, default_value));
}
#/

Pow(n, k)
{
	newnum = n;

	for(i = 1; i < k; i++)
	{
		newnum *= n;
	}

	return newnum;

	// inf loop
	// if(n == 0)
	// 	return 1;
	// if(k == 1)
	// 	return n;

	// for(i = 0; i < (k - 1); k++)
	// {
	// 	n *= n;
	// }
	// return n;
}

PlaySoundToTeam(aliasname, teamname, ignoreplayer)
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		if(players[i].team != teamname)
			continue;
		if(isdefined(ignoreplayer) && players[i] == ignoreplayer)
			continue;

		players[i] PlayLocalSound(aliasname);
	}
}

SetInvisibleToAll()
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		self SetInvisibleToPlayer(players[i], true);
	}
}

SetVisibleToAllExceptTeam(team)
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		if(players[i].team == team)
			self SetInvisibleToPlayer(players[i]);
		else
			self SetVisibleToPlayer(players[i]);
	}
}

SetVisibleToTeam(team)
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		if(players[i].team == team)
			self SetVisibleToPlayer(players[i]);
		else
			self SetInvisibleToPlayer(players[i]);
	}
}

IsInArray(array, value)
{
	return is_in_array(array, value);
}

GetNodesInRadiusSorted(origin, max_radius, min_radius, max_height, node_type/*, max_nodes*/)
{
	nodes = GetAllNodes();
	valid_nodes = [];

	for(i = 0; i < nodes.size; i++)
	{
		if(isdefined(nodes[i].targetname))
			continue;
		if(DistanceSquared(origin, nodes[i].origin) < min_radius * min_radius)
			continue;
		if(DistanceSquared(origin, nodes[i].origin) > max_radius * max_radius)
			continue;
		if(Abs(origin[2] - nodes[i].origin[2]) > max_height)
			continue;

		valid_nodes[valid_nodes.size] = nodes[i];
	}

	if(!isdefined(valid_nodes) || valid_nodes.size == 0)
		return [];

	return get_array_of_closest(origin, valid_nodes);
}

GetAITeamArray(team)
{
	return GetAISpeciesArray(team, "all");
}

//============================================================================================
// Delay Thread / Notify - xSanchez78
//============================================================================================
delay_notify(str_notify, n_delay, str_endon)
{
	self thread _delay_notify_proc(str_notify, n_delay, str_endon);
}

delay_thread(time_or_notify, str_endon, func, arg1, arg2, arg3, arg4, arg5, arg6)
{
	self thread _delay_thread_proc(time_or_notify, str_endon, func, arg1, arg2, arg3, arg4, arg5, arg6);
}

//============================================================================================
// PlayerTrigger - xSanchez78
//============================================================================================
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
	keys = GetArrayKeys(struct.trigger_pool);

	for(i = 0; i < keys.size; i++)
	{
		if(isdefined(struct.trigger_pool[keys[i]]))
		{
			struct.trigger_pool[keys[i]] notify("kill_trigger");
			struct.trigger_pool[keys[i]] Delete();
			struct.trigger_pool[keys[i]] = undefined;
		}
	}
	struct.trigger_pool = [];
}

//============================================================================================
// Player Health
//============================================================================================
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

//============================================================================================
// Fake Client Systems - xSanchez78
//============================================================================================
set_client_system_state(system_name, system_state, player)
{
	if(isdefined(player) && IsPlayer(player))
		player_num = string(player GetEntityNumber());
	else
		player_num = "all";

	state = player_num + "," + string(system_name.size) + "|" + system_name + system_state;
	setClientSysState("fake_client_systems", state);
}

//============================================================================================
// VisionSet Manager - xSanchez78
//============================================================================================
visionset_activate(vision)
{
	self levelNotify("visionset_mgr_activate_" + vision);
}

visionset_deactivate(vision)
{
	self levelNotify("visionset_mgr_deactivate_" + vision);
}

//============================================================================================
// Callbacks
//============================================================================================
OnPlayerSpawned_Callback(func)
{
	maps\apex\_load::_AddCallback("on_player_spawned", func);
}

OnPlayerSpawned_CallbackRemove(func)
{
	maps\apex\_load::_RemoveCallback("on_player_spawned", func);
}