#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility_code;

//============================================================================================
// Common Utility Functions
//============================================================================================
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
IsInArray(array, value)
{
	return is_in_array(array, value);
}

GetNodesInRadiusSorted(origin, max_radius, min_radius, max_height/*, node_type, max_nodes*/)
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