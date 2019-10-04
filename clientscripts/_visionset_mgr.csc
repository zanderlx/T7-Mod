#include clientscripts\_utility;
#include clientscripts\_zm_utility;

init()
{
	level.active_visionsets = [];
	level.current_visionset = [];

	register_client_system("_visionset_mgr", ::visionset_system_monitor);
	OnPlayerConnect_Callback(::visionset_onplayerconnect);
}

visionset_onplayerconnect(clientnum)
{
	level.active_visionsets[clientnum] = [];
	keys = GetArrayKeys(level.vision_list);

	for(i = 0; i < keys.size; i++)
	{
		if(is_true(level.vision_list[keys[i]].always_on))
			visionset_activate(clientnum, keys[i]);
	}
}

visionset_system_monitor(clientnum, state, oldState)
{
	tokens = StrTok(state, ":");

	switch(tokens[0])
	{
		default:
			break;

		case "activate":
			visionset_activate(clientnum, tokens[1]);
			break;

		case "deactivate":
			visionset_deactivate(clientnum, tokens[1]);
			break;
	}
}

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
	highest_vision = get_highest_prority_vision(active_visionsets);

	if(highest_vision == vision)
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
	highest_vision = get_highest_prority_vision(active_visionsets);

	if(isdefined(level.current_visionset[clientnum]) && level.current_visionset[clientnum] == vision)
	{
		trans_time = level.vision_list[vision].trans_out;
		VisionSetNaked(clientnum, level.vision_list[highest_vision].vision, trans_time);
		level.current_visionset[clientnum] = highest_vision;
	}
}

get_active_vision_array(active_visionsets)
{
	result = [];
	keys = GetArrayKeys(active_visionsets);

	for(i = 0; i < keys.size; i++)
	{
		if(is_true(active_visionsets[keys[i]]))
		{
			if(isdefined(level.vision_list) && isdefined(level.vision_list[keys[i]]))
				result[result.size] = keys[i];
		}
	}
	return result;
}

get_highest_prority_vision(active_visionsets)
{
	highest_vision = active_visionsets[0];

	for(i = 1; i < active_visionsets.size; i++)
	{
		if(level.vision_list[active_visionsets[i]].priority > level.vision_list[highest_vision].priority)
			highest_vision = active_visionsets[i];
	}
	return highest_vision;
}