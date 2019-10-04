#include clientscripts\_utility;

// Level Notify
add_level_notify_callback(message, callback_func, arg1, arg2, arg3, arg4)
{
	level thread clientscripts\_zm_setup::level_notify_callback_think(message, callback_func, arg1, arg2, arg3, arg4);
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

thread_func(self_ent, func, arg1, arg2, arg3, arg4, arg5, arg6)
{
	if(!isdefined(func))
		return;
	if(!isdefined(self_ent))
		self_ent = level;
	
	if(isdefined(arg6))
		self_ent thread [[func]](arg1, arg2, arg3, arg4, arg5, arg6);
	else if(isdefined(arg5))
		self_ent thread [[func]](arg1, arg2, arg3, arg4, arg5);
	else if(isdefined(arg4))
		self_ent thread [[func]](arg1, arg2, arg3, arg4);
	else if(isdefined(arg3))
		self_ent thread [[func]](arg1, arg2, arg3);
	else if(isdefined(arg2))
		self_ent thread [[func]](arg1, arg2);
	else if(isdefined(arg1))
		self_ent thread [[func]](arg1);
	else
		self_ent thread [[func]]();
}

register_client_system(system, func)
{
	if(!isdefined(level._apex_client_systems))
		level._apex_client_systems = [];
	if(isdefined(level._apex_client_systems[system]))
		return;
	
	struct = SpawnStruct();
	struct.old_message = "";
	struct.func = func;

	level._apex_client_systems[system] = struct;
}

spawn_model(clientnum, model, origin, angles)
{
	ent = Spawn(clientnum, origin, "script_model");
	ent SetModel(model);
	ent.angles = angles;
	return ent;
}

is_true(val)
{
	return isdefined(val) && val;
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

get_mapname()
{
	if(isdefined(level.script))
		return level.script;
	else
		return ToLower(GetDvarString(#"mapname"));
}

// Dvar
GetDvarString(dvar, default_val)
{
	val = GetDvar(dvar);

	if(!isdefined(val) || val == "")
	{
		if(isdefined(default_val))
			return default_val;
	}
	return val;
}

// Array
array_run_function(a_ents, func, arg1, arg2, arg3, arg4, arg5, arg6)
{
	if(!isdefined(func))
		return;
	if(!isdefined(a_ents) || a_ents.size == 0)
		return;
	
	keys = GetArrayKeys(a_ents);

	for(i = 0; i < keys.size; i++)
	{
		ent = a_ents[keys[i]];
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

string_to_float(str)
{
	tokens = StrTok(str, ".");
	whole = Int(tokens[0]);

	if(tokens.size == 1)
		return whole;

	str_decimal = tokens[1];
	decimal = 0;

	for(i = str_decimal.size - 1; i >= 0; i--)
	{
		decimal = decimal / 10 + Int(str_decimal[i]) / 10;
	}

	if(whole >= 0)
		return whole + decimal;
	else
		return whole - decimal;
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
// Mostly wrappers - old utility to newer engine
IsInArray(array, val)
{
	return is_in_array(array, val);
}

ArrayRemoveValue(array, value, preserve_keys)
{
	return array_remove(array, value, preserve_keys);
}