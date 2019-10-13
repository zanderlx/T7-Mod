#include clientscripts\_utility;
#include clientscripts\apex\_utility_code;

//============================================================================================
// Perk Utility Functions
//============================================================================================
has_perk(clientnum, perk)
{
	if(!clientscripts\apex\_zm_perks::is_perk_valid(perk))
		return false;
	return IsInArray(level._client_perks[clientnum], perk);
}

//============================================================================================
// Common Utility Functions
//============================================================================================
spawn_model(clientnum, model, origin, angles)
{
	ent = Spawn(clientnum, origin, "script_model");
	ent SetModel(model);
	ent.angles = angles;
	return ent;
}

get_player_id(clientnum)
{
	player = GetLocalPlayer(clientnum);
	return player GetEntityNumber();
}

is_true(val)
{
	return isdefined(val) && val;
}

is_equal(a, b)
{
	if(!isdefined(a) && !isdefined(b))
		return true;
	if(!isdefined(a) || !isdefined(b))
		return false;
	return a == b;
}

string(val)
{
	return "" + val;
}

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

string_to_float(str)
{
	tokens = StrTok(str, ".");
	whole = Int(tokens[0]);

	if(tokens.size == 1)
		return whole;

	decimal = 0;
	str_decimal = tokens[1];

	for(i = str_decimal.size - 1; i >= 0; i--)
	{
		decimal = decimal / 10 + Int(str_decimal[i]) / 10;
	}

	if(whole >= 0)
		return whole + decimal;
	else
		return whole - decimal;
}

linear_map(num, min_a, max_a, min_b, max_b)
{
	return clamp(((num - min_a) / (max_a - min_a) * (max_b - min_b) + min_b), min_b, max_b);
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

waittillend(msg)
{
	self waittillmatch(msg, "end");
}

//============================================================================================
// Engine Functions / Wrappers
//============================================================================================
GetStance(clientnum)
{
	return level.stance_watcher[clientnum];
}

IsInArray(array, value)
{
	return is_in_array(array, value);
}

Pow(num, raise)
{
	newnum = num;

	for(i = 1; i < raise; i++)
	{
		newnum *= num;
	}

	return newnum;
}

Distance2DSquared(origin, origin2)
{
	return (Abs(origin2[0] - origin[0]) * Abs(origin2[0] - origin[0])) + (Abs(origin2[1] - origin[1]) * Abs(origin2[1] - origin[1]));
}

//============================================================================================
// Weapon Engine Functions
//============================================================================================
WeaponInventoryType(weapon_name)
{
	if(clientscripts\apex\_zm_weapons::is_weapon_included(weapon_name) && isdefined(level.zombie_weapons[weapon_name].inventory_type))
		return level.zombie_weapons[weapon_name].inventory_type;
	return "primary"; // default?!?
}

WeaponDualWieldWeaponName(weapon_name)
{
	if(clientscripts\apex\_zm_weapons::is_weapon_included(weapon_name) && isdefined(level.zombie_weapons[weapon_name].lh_name))
		return level.zombie_weapons[weapon_name].lh_name;
	return "none";
}

WeaponAltWeaponName(weapon_name)
{
	if(clientscripts\apex\_zm_weapons::is_weapon_included(weapon_name) && isdefined(level.zombie_weapons[weapon_name].alt_name))
		return level.zombie_weapons[weapon_name].alt_name;
	return "none";
}

//============================================================================================
// Fake Client Systems - xSanchez78
//============================================================================================
register_client_system(system_name, callback_func)
{
	if(!isdefined(level.fake_client_systems))
		level.fake_client_systems = [];
	if(!isdefined(level.fake_client_systems[system_name]))
		level.fake_client_systems[system_name] = callback_func;
}

//============================================================================================
// Level Notify Callback System (Mainly for tthe "levelNotify" ClientSystem) - xSanchez78
//============================================================================================
add_level_notify_callback(message, callback_func, arg1, arg2, arg3, arg4)
{
	level thread levelNotify_callback_think(message, callback_func, arg1, arg2, arg3, arg4);
}

//============================================================================================
// VisionSet Manager - xSanchez78
//============================================================================================
visionset_register_info(identifier, vision, priority, trans_in, trans_out, always_on)
{
	if(!isdefined(level.vision_list))
		level.vision_list = [];
	if(isdefined(level.vision_list[identifier]))
		return;

	struct = SpawnStruct();
	struct.identifier = identifier;
	struct.vision = vision;
	struct.priority = priority;
	struct.trans_in = trans_in;
	struct.trans_out = trans_out;
	struct.always_on = always_on;

	level.vision_list[identifier] = struct;
}

visionset_activate(clientnum, vision)
{
	level.active_visionsets[clientnum][vision] = true;
	active_visionsets = get_active_vision_array(level.active_visionsets[clientnum]);
	highest_vision = get_highest_priorirty_vision(active_visionsets);

	if(is_equal(highest_vision, vision))
	{
		trans_time = level.vision_list[highest_vision].trans_in;
		VisionSetNaked(clientnum, level.vision_list[highest_vision].vision, trans_time);
		level.current_visionset[clientnum] = highest_vision;
	}
}

visionset_deactivate(clientnum, vision)
{
	level.active_visionsets[clientnum][vision] = false;
	active_visionsets = get_active_vision_array(level.active_visionsets[clientnum]);
	highest_vision = get_highest_priorirty_vision(active_visionsets);

	// This should never happen
	// Only happens if you disable MAPNAME / always_on visions
	/*
	if(!isdefined(highest_vision))
		return;
	*/

	if(is_equal(level.current_visionset[clientnum], vision))
	{
		trans_time = level.vision_list[vision].trans_in;
		VisionSetNaked(clientnum, level.vision_list[highest_vision].vision, trans_time);
		level.current_visionset[clientnum] = highest_vision;
	}
}

//============================================================================================
// Flags
//============================================================================================
flag_init(message, val)
{
	if(!isdefined(self.flag))
		self.flag = [];

	if(is_true(val))
		self.flag[message] = true;
	else
		self.flag[message] = false;
}

flag(message)
{
	if(self flag_exists(message))
		return is_true(self.flag[message]);
	return false;
}

flag_set(message)
{
	if(!self flag_exists(message))
		self flag_init(message, false);

	self.flag[message] = true;
	self notify(message);
}

flag_toggle(message)
{
	if(self flag(message))
		self flag_clear(message);
	else
		self flag_set(message);
}

flag_wait(message)
{
	if(self != level)
		self endon("death");

	while(!self flag(message))
	{
		self waittill(message);
	}
}

flag_clear(message)
{
	if(!self flag_exists(message))
		self flag_init(message, true);

	self.flag[message] = false;
	self notify(message);
}

flag_waitopen(message)
{
	if(self != level)
		self endon("death");

	while(self flag(message))
	{
		self waittill(message);
	}
}

flag_exists(message)
{
	if(!isdefined(self.flag))
		return false;
	if(!isdefined(self.flag[message]))
		return false;
	return true;
}