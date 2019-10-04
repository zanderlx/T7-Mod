#include clientscripts\_utility;
#include clientscripts\_zm_utility;

init()
{
	level.client_side_fx = [];
	level.client_side_sound = [];

	registerSystem("apex_client_sys", ::system_monitor);
	register_client_system("client_side_fx", ::handle_client_side_fx);
	
	clientscripts\_zm_perks::init();
	clientscripts\_zm_magicbox::init();
	clientscripts\_zm_weapons::init();
}

system_monitor(clientnum, state, oldState)
{
	tokens = StrTok(state, "|");
	system = tokens[0];
	message = tokens[1];

	if(isdefined(level._apex_client_systems) && isdefined(level._apex_client_systems[system]))
	{
		old_message = "";

		if(isdefined(level._apex_client_systems[system].old_message))
			old_message = level._apex_client_systems[system].old_message;
		
		if(isdefined(level._apex_client_systems[system].func))
			single_thread(level, level._apex_client_systems[system].func, clientnum, message, old_message);
		
		level._apex_client_systems[system].old_message = message;
	}
}

level_notify_callback_think(message, callback_func, arg1, arg2, arg3, arg4)
{
	for(;;)
	{
		level waittill(message, clientnum);
		single_thread(level, callback_func, clientnum, arg1, arg2, arg3, arg4);
	}
}

handle_client_side_fx(clientnum, state, oldState)
{
	tokens = StrTok(state, ":");

	if(tokens[0] == "fx")
	{
		if(tokens[1] == "looping")
		{
			// 0  1       2     3          4      5      6
			// fx:looping:start:identifier:fx_var:origin:angles
			if(tokens[2] == "start")
			{
				identifier = tokens[3];
				fx_var = tokens[4];
				origin = string_to_vector(tokens[5]);
				angles = string_to_vector(tokens[6]);

				if(!isdefined(level.client_side_fx[clientnum]))
					level.client_side_fx[clientnum] = [];
				if(!isdefined(level.client_side_fx[clientnum][identifier]))
					level.client_side_fx[clientnum][identifier] = PlayFX(clientnum, level._effect[fx_var], origin, AnglesToForward(angles), AnglesToUp(angles));
			}
			else
			{
				// 0  1       2    3          4
				// fx:looping:stop:identifier:delete_fx_immeditately
				identifier = tokens[3];
				delete_fx_immeditately = string_to_bool(tokens[4]);

				if(isdefined(level.client_side_fx[clientnum]) && isdefined(level.client_side_fx[clientnum][identifier]))
				{
					DeleteFX(clientnum, level.client_side_fx[clientnum][identifier], delete_fx_immeditately);
					level.client_side_fx[clientnum][identifier] = undefined;
				}
			}
		}
		else
		{
			// 0  1       2      3      4
			// fx:oneshot:fx_var:origin:angles
			fx_var = tokens[2];
			origin = string_to_vector(tokens[3]);
			angles = string_to_vector(tokens[4]);
			PlayFX(clientnum, level._effect[fx_var], origin, AnglesToForward(angles), AnglesToUp(angles));
		}
	}
	else
	{
		if(tokens[1] == "looping")
		{
			if(tokens[2] == "start")
			{
				// 0     1       2     3          4     5      6
				// sound:looping:start:identifier:alias:origin:fade_time
				identifier = tokens[3];
				alias = tokens[4];
				origin = string_to_vector(tokens[5]);
				fade_time = string_to_vector(tokens[6]);

				if(!isdefined(level.client_side_sound[clientnum]))
					level.client_side_sound[clientnum] = [];
				
				if(!isdefined(level.client_side_sound[clientnum][identifier]))
				{
					info = [];
					info["entId"] = SpawnFakeEnt(clientnum);
					SetFakeEntOrg(clientnum, info["entId"], origin);
					info["soundId"] = PlayLoopSound(clientnum, info["entId"], alias, fade_time);
					level.client_side_sound[clientnum][identifier] = info;
				}
			}
			else
			{
				// 0     1       2    3          4
				// sound:looping:stop:identifier:fade_time
				identifier = tokens[3];
				fade_time = string_to_float(tokens[4]);

				if(isdefined(level.client_side_sound[clientnum]) && isdefined(level.client_side_sound[clientnum][identifier]))
				{
					level thread stop_loop_sound(clientnum, level.client_side_sound[clientnum][identifier], fade_time);
					level.client_side_sound[clientnum][identifier] = undefined;
				}
			}
		}
		else
		{
			// 0     1       2     3
			// sound:oneshot:alias:origin
			alias = tokens[2];
			origin = string_to_vector(tokens[3]);
			PlaySound(clientnum, alias, origin);
		}
	}
}

stop_loop_sound(clientnum, info, fade_time)
{
	StopLoopSound(clientnum, info["entId"], fade_time);
	clientscripts\_audio::soundwait(info["soundId"]);
	DeleteFakeEnt(clientnum, info["entId"]);
}