#include clientscripts\_utility;
#include clientscripts\apex\_utility;

//============================================================================================
// Utility Setup
//============================================================================================
init_utility()
{
	registerSystem("fake_client_systems", ::fake_client_system_monitor);
	client_side_fx_init();
	stance_watcher_init();
	visionset_init();
}

//============================================================================================
// Fake Client Systems - xSanchez78
//============================================================================================
fake_client_system_monitor(clientnum, state, oldState)
{
	tokens = StrTok(state, "|");
	system_info = StrTok(tokens[0], ",");
	str_player_id = string(get_player_id(clientnum));

	if(is_equal(system_info[0], "all") || is_equal(system_info[0], str_player_id))
	{
		system_name_and_state = GetSubStr(state, tokens[0].size + 1, state.size);
		system_name = GetSubStr(system_name_and_state, 0, Int(system_info[1]));
		system_state = GetSubStr(system_name_and_state, system_name.size, system_name_and_state.size);

		if(isdefined(level.fake_client_systems) && isdefined(level.fake_client_systems[system_name]))
			single_thread(level, level.fake_client_systems[system_name], clientnum, system_state);
	}
}

//============================================================================================
// Level Notify Callback System (Mainly for tthe "levelNotify" ClientSystem) - xSanchez78
//============================================================================================
levelNotify_callback_think(message, callback_func, arg1, arg2, arg3, arg4)
{
	for(;;)
	{
		level waittill(message, clientnum);
		player = GetLocalPlayer(clientnum);
		single_thread(player, callback_func, clientnum, arg1, arg2, arg3, arg4);
	}
}

//============================================================================================
// Client Side FX / Sounds - xSanchez78
//============================================================================================
client_side_fx_init()
{
	level.client_side_fx = [];
	level.client_side_sound = [];

	register_client_system("client_side_fx", ::client_side_fx_monitor);
}

client_side_fx_monitor(clientnum, state)
{
	tokens = StrTok(state, "|");
	if(tokens[0] == "fx")
	{
		if(tokens[1] == "looping")
		{
			if(tokens[2] == "start")
			{
				if(!isdefined(level.client_side_fx[clientnum]))
					level.client_side_fx[clientnum] = [];

				if(!isdefined(level.client_side_fx[clientnum][tokens[3]]))
				{
					origin = string_to_vector(tokens[5]);
					angles = string_to_vector(tokens[7]);
					level.client_side_fx[clientnum][tokens[3]] = PlayFX(clientnum, level._effect[tokens[4]], origin, AnglesToForward(angles), AnglesToUp(angles));
				}
			}
			else
			{
				if(isdefined(level.client_side_fx[clientnum]) && IsDefined(level.client_side_fx[clientnum][tokens[3]]))
				{
					DeleteFX(clientnum, level.client_side_fx[clientnum][tokens[3]], string_to_bool(tokens[4]));
					level.client_side_fx[clientnum][tokens[3]] = undefined;
				}
			}
		}
		else
		{
			origin = string_to_vector(tokens[3]);
			angles = string_to_vector(tokens[4]);
			PlayFX(clientnum, level._effect[tokens[2]], origin, AnglesToForward(angles), AnglesToUp(angles));
		}
	}
	else
	{
		if(tokens[1] == "looping")
		{
			if(tokens[2] == "start")
			{
				if(!isdefined(level.client_side_sound[clientnum]))
					level.client_side_sound[clientnum] = [];

				if(!isdefined(level.client_side_sound[clientnum][tokens[3]]))
				{
					origin = string_to_vector(tokens[5]);
					info = [];
					info["entId"] = SpawnFakeEnt(clientnum);
					SetFakeEntOrg(clientnum, info["entId"], origin);
					info["soundId"] = PlayLoopSound(clientnum, info["entId"], tokens[4], string_to_float(tokens[8]));
					level.client_side_sound[clientnum][tokens[3]] = info;
				}
			}
			else
			{
				if(isdefined(level.client_side_sound[clientnum]) && isdefined(level.client_side_sound[clientnum][tokens[3]]))
				{
					level.client_side_sound[clientnum][tokens[3]] thread stop_loop_sound(clientnum, string_to_float(tokens[4]));
					level.client_side_sound[clientnum][tokens[3]] = undefined;
				}
			}
		}
		else
		{
			origin = string_to_vector(tokens[3]);
			PlaySound(clientnum, tokens[2], origin);
		}
	}
}

stop_loop_sound(clientnum, fade_time)
{
	StopLoopSound(clientnum, self["entId"], fade_time);
	clientscripts\_audio::soundwait(self["soundId"]);
	DeleteFX(clientnum, self["entId"]);
}

//============================================================================================
// Client Stance - xSanchez78
//============================================================================================
stance_watcher_init()
{
	level.stance_watcher = [];
	OnPlayerConnect_Callback(::stance_watcher);
}

stance_watcher(clientnum)
{
	level.stance_watcher[clientnum] = "stand";
	last_view_height = 0;

	for(;;)
	{
		view_height = GetLocalClientEyePos(clientnum)[2] - GetLocalClientPos(clientnum)[2];

		if(last_view_height != view_height)
		{
			old_stance = level.stance_watcher[clientnum];

			if(view_height < last_view_height)
			{
				if(view_height >= 60)
					new_stance = "stand";
				else if(view_height >= 40)
					new_stance = "crouch";
				else
					new_stance = "prone";
			}
			else
			{
				if(view_height <= 11)
					new_stance = "prone";
				else if(view_height <= 40)
					new_stance = "crouch";
				else
					new_stance = "stand";
			}

			if(new_stance != old_stance)
			{
				level.stance_watcher[clientnum] = new_stance;
				level notify("stance_change", clientnum, old_stance, new_stance);
			}
			last_view_height = view_height;
		}
		wait 1/60;
	}
}

//============================================================================================
// VisionSet Manager - xSanchez78
//============================================================================================
visionset_init()
{
	level.current_visionsets = [];
	level.active_visionsets = [];

	// Register Common VisionSets
	// 						identifier					vision								priority	trans_in	trans_out	always_on
	visionset_register_info("default_vision",			"default",							2, 			0,			0,			false);
	visionset_register_info("bw_aftereffect",			"cheat_bw_invert_contrast",			3, 			.4,			1,			false);
	visionset_register_info("red_aftereffect",			"zombie_turned",					3, 			.4,			1,			false);
	visionset_register_info("flashy_aftereffect_1",		"cheat_bw_invert_contrast",			3, 			.1,			.1,			false);
	visionset_register_info("flashy_aftereffect_2",		"cheat_bw_contrast",				3, 			.1,			.1,			false);
	visionset_register_info("flashy_aftereffect_3",		"cheat_invert_contrast",			3, 			.1,			.1,			false);
	visionset_register_info("flashy_aftereffect_4",		"cheat_contrast",					3, 			.1,			5,			false);
	visionset_register_info("flare_aftereffect",		"flare",							3, 			.4,			1,			false);
	// 						identifier					vision								priority	trans_in	trans_out	always_on

	if(isdefined(level._custom_visionset_registration))
		run_function(level, level._custom_visionset_registration);

	OnPlayerConnect_Callback(::visionset_player_init);
	level thread visionset_post_init();
}

visionset_post_init()
{
	waitforallclients();
	wait 1/60;
	keys = GetArrayKeys(level.vision_list);

	for(i = 0; i < keys.size; i++)
	{
		add_level_notify_callback("visionset_mgr_activate_" + keys[i], ::visionset_activate, keys[i]);
		add_level_notify_callback("visionset_mgr_deactivate_" + keys[i], ::visionset_deactivate, keys[i]);
	}
}

visionset_player_init(clientnum)
{
	level.active_visionsets[clientnum] = [];
	keys = GetArrayKeys(level.vision_list);

	for(i = 0; i < keys.size; i++)
	{
		if(is_true(level.vision_list[keys[i]].always_on))
			visionset_activate(clientnum, keys[i]);
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

get_highest_priorirty_vision(active_visionsets)
{
	highest_vision = active_visionsets[0];

	for(i = 1; i < active_visionsets.size; i++)
	{
		if(level.vision_list[active_visionsets[i]].priority > level.vision_list[highest_vision].priority)
			highest_vision = active_visionsets[i];
	}
	return highest_vision;
}