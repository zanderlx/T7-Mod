#include clientscripts\_utility;
#include clientscripts\_zm_utility;

init()
{
	register_client_system("_visionset_mgr", ::visionset_system_monitor);
}

visionset_system_monitor(clientnum, state, oldState)
{
	if(state == "apply_highest")
		visionset_apply_highest(clientnum);
	else
	{
		tokens = StrTok(state, ":");

		switch(tokens[0])
		{
			case "apply_highest":
			default:
				visionset_apply_highest(clientnum);
				break;

			case "apply":
				visionset_apply(clientnum, tokens[1]);
				break;

			case "remove":
				visionset_remove(clientnum, tokens[1]);
				break;
		}
	}
}

visionset_register(visionset_name, priority, transition_time)
{
	if(!isdefined(level._visionset_mgr))
		level._visionset_mgr = [];
	if(isdefined(level._visionset_mgr[visionset_name]))
		return;

	struct = SpawnStruct();
	struct.visionset_name = visionset_name;
	struct.priority = priority;
	struct.transition_time = transition_time;

	level._visionset_mgr[visionset_name] = struct;
}

visionset_apply(clientnum, visionset_name)
{
	player = GetLocalPlayer(clientnum);

	if(!isdefined(visionset_name) || visionset_name == "")
		return;
	if(!isdefined(level._visionset_mgr) || !isdefined(level._visionset_mgr[visionset_name]))
		return;
	if(!isdefined(player._visionset_list))
		player._visionset_list = [];
	if(!IsInArray(player._visionset_list, visionset_name))
		player._visionset_list[player._visionset_list.size] = visionset_name;

	visionset_apply_highest(clientnum);
}

visionset_apply_highest(clientnum)
{
	visionset_name = visionset_find_highest(clientnum);
	VisionSetNaked(clientnum, visionset_name, level._visionset_mgr[visionset_name].transition_time);
}

visionset_remove(clientnum, visionset_name)
{
	player = GetLocalPlayer(clientnum);

	if(!isdefined(visionset_name) || visionset_name == "")
		return;
	if(!isdefined(level._visionset_mgr) || !isdefined(level._visionset_mgr[visionset_name]))
		return;
	if(!isdefined(player._visionset_list))
		player._visionset_list = [];

	if(IsInArray(player._visionset_list, visionset_name))
	{
		player._visionset_list = array_remove(player._visionset_list, visionset_name);
		visionset_apply_highest(clientnum);
	}
}

visionset_find_highest(clientnum)
{
	player = GetLocalPlayer(clientnum);

	if(!isdefined(player._visionset_list))
		player._visionset_list = [];

	visionset_name = undefined;

	for(i = 0; i < player._visionset_list.size; i++)
	{
		new_visionset_name = player._visionset_list[i];

		if(isdefined(visionset_name))
		{
			if(level._visionset_mgr[new_visionset_name].priority > level._visionset_mgr[visionset_name].priority)
				visionset_name = new_visionset_name;
		}
		else
			visionset_name = new_visionset_name;
	}

	return visionset_name;
}