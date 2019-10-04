#include clientscripts\_utility;
#include clientscripts\_music;

main()
{
	level._uses_crossbow = true;
	register_visionset_types();
	clientscripts\_zombiemode::main();
	clientscripts\zombie_theater_teleporter::main();
	clientscripts\zombie_theater_fx::main();
	thread clientscripts\zombie_theater_amb::main();
	level._custom_box_monitor = ::theater_box_monitor;
	level._box_locations = array("start_chest_loc", "foyer_chest_loc", "crematorium_chest_loc", "alleyway_chest_loc", "control_chest_loc", "stage_chest_loc", "dressing_chest_loc", "dining_chest_loc", "theater_chest_loc");
	thread waitforclient(0);
	level._power_on = false;
	level thread theatre_ZPO_listener();
	array_thread(GetEntArray(0, "trigger_eeroom_visionset", "targetname"), ::theater_player_in_eeroom);
	register_zombie_types();
	OnPlayerConnect_Callback(::on_player_connect);
}

register_zombie_types()
{
	character\clientscripts\c_ger_honorguard_zt::register_gibs();
	character\clientscripts\c_zom_quad::register_gibs();
}

register_visionset_types()
{
	// clientscripts\_visionset_mgr::visionset_register(visionset_name, priority, transition_time);
	clientscripts\_visionset_mgr::visionset_register("zombie_theater", 1, 0);
	clientscripts\_visionset_mgr::visionset_register("zombie_theater_eroom_asylum", 100, 0);
	clientscripts\_visionset_mgr::visionset_register("zombie_theater_erooms_pentagon", 100, 0);
	clientscripts\_visionset_mgr::visionset_register("zombie_theater_eroom_girlnew", 100, 0);
	clientscripts\_visionset_mgr::visionset_register("zombie_theater_eroom_girlold", 100, 0);
}

on_player_connect(clientnum)
{
	self endon("disconnect");
	init_board_lights(clientnum);

	while(!ClientHasSnapshot(clientnum))
	{
		wait 1/60;
	}

	if(clientnum != 0)
		return;

	players = GetLocalPlayers();

	for(i = 0; i < players.size; i++)
	{
		clientscripts\_visionset_mgr::visionset_apply(i, "zombie_theater");
	}
}

theatre_ZPO_listener()
{
	for(;;)
	{
		level waittill("ZPO");
		level._power_on = true;

		if(level._box_indicator != level._BOX_INDICATOR_NO_LIGHTS)
		{
			for(i = 0; i < GetLocalPlayers().size; i++)
			{
				theater_box_monitor(i, level._box_indicator);
			}
		}

		level notify("pl1");
		level thread theater_light_model_swap();
	}
}

theater_light_model_swap()
{
	players = GetLocalPlayers();

	for(i = 0; i < players.size; i++)
	{
		models = GetEntArray(i, "model_lights_on", "targetname");

		for(j = 0; j < models.size; j++)
		{
			if(models[j].model == "lights_hang_single")
				models[j] SetModel("lights_hang_single_on_nonflkr");
			else if(models[j].model == "zombie_zapper_cagelight")
				models[j] SetModel("zombie_zapper_cagelight_on");
		}
	}
}

// MagicBox Lights
init_board_lights(clientnum)
{
	structs = GetStructArray("magic_box_loc_light", "targetname");

	for(i = 0; i < structs.size; i++)
	{
		if(!isdefined(structs[i].lights))
			structs[i].lights = [];

		if(isdefined(structs[i].lights[clientnum]))
		{
			if(isdefined(structs[i].lights[clientnum].fx))
			{
				structs[i].lights[clientnum].fx Delete();
				structs[i].lights[clientnum].fx = undefined;
			}

			structs[i].lights[clientnum] Delete();
			structs[i].lights[clientnum] = undefined;
		}

		structs[i].lights[clientnum] = clientscripts\_zm_utility::spawn_model(clientnum, "zombie_zapper_cagelight", structs[i].origin, structs[i].angles);
	}
}

get_lights(clientnum, name)
{
	structs = GetStructArray(name, "script_noteworthy");
	lights = [];

	for(i = 0; i < structs.size; i++)
	{
		lights[lights.size] = structs[i].lights[clientnum];
	}

	return lights;
}

turn_off_all_box_lights(clientnum)
{
	level notify("kill_box_light_threads_" + clientnum);

	for(i = 0; i < level._box_locations.size; i++)
	{
		turn_off_light(clientnum, i);
	}
}

flash_lights(clientnum, period)
{
	level notify("kill_box_light_threads_" + clientnum);
	level endon("kill_box_light_threads_" + clientnum);

	for(;;)
	{
		RealWait(period);

		for(i = 0; i < level._box_locations.size; i++)
		{
			turn_light_green(clientnum, i);
		}

		RealWait(period);

		for(i = 0; i < level._box_locations.size; i++)
		{
			turn_off_light(clientnum, i, true);
		}
	}
}

turn_light_green(clientnum, light_num, play_fx)
{
	if(light_num == level._BOX_INDICATOR_NO_LIGHTS)
		return;

	name = level._box_locations[light_num];
	lights = get_lights(clientnum, name);

	for(i = 0; i < lights.size; i++)
	{
		if(isdefined(lights[i].fx))
		{
			lights[i].fx Delete();
			lights[i].fx = undefined;
		}

		if(clientscripts\_zm_utility::is_true(play_fx))
		{
			lights[i] SetModel("zombie_zapper_cagelight_green");
			lights[i].fx = clientscripts\_zm_utility::spawn_model(clientnum, "tag_origin", lights[i].origin - (0, 0, 10), lights[i].angles);
			PlayFXOnTag(clientnum, level._effect["boxlight_light_ready"], lights[i].fx, "tag_origin");
		}
		else
			lights[i] SetModel("zombie_zapper_cagelight_green");
	}
}

turn_off_light(clientnum, light_num, dont_kill_threads)
{
	if(!clientscripts\_zm_utility::is_true(dont_kill_threads))
		level notify("kill_box_light_threads_" + clientnum);
	if(light_num == level._BOX_INDICATOR_NO_LIGHTS)
		return;

	name = level._box_locations[light_num];
	lights = get_lights(clientnum, name);

	for(i = 0; i < lights.size; i++)
	{
		if(isdefined(lights[i].fx))
		{
			lights[i].fx Delete();
			lights[i].fx = undefined;
		}
		lights[i] SetModel("zombie_zapper_cagelight");
	}
}

theater_box_monitor(clientnum, state, oldState)
{
	s = Int(state);

	if(s == level._BOX_INDICATOR_NO_LIGHTS)
		turn_off_all_box_lights(clientnum);
	else if(s == level._BOX_INDICATOR_FLASH_LIGHTS_MOVING)
		level thread flash_lights(clientnum, .25);
	else if(s == level._BOX_INDICATOR_FLASH_LIGHTS_FIRE_SALE)
		level thread flash_lights(clientnum, .3);
	else
	{
		if(s < 0 || s > level._box_locations.size)
			return;

		level notify("kill_box_light_threads_" + clientnum);
		turn_off_all_box_lights(clientnum);
		level._box_indicator = s;

		if(clientscripts\_zm_utility::is_true(level._power_on))
			turn_light_green(clientnum, level._box_indicator, true);
	}
}

// EasterEgg Rooms
theater_player_in_eeroom()
{
	for(;;)
	{
		self waittill("trigger", player);

		if(player IsLocalPlayer())
			self thread trigger_thread(player, ::eeroom_visionset_on, ::eeroom_visionset_off);
	}
}

eeroom_visionset_on(player)
{
	if(!isdefined(self.script_string))
		return;

	RealWait(1);

	switch(self.script_string)
	{
		case "asylum_room":
			visionset_name = "zombie_theater_eroom_asylum";
			break;

		case "pentagon_room":
			visionset_name = "zombie_theater_erooms_pentagon";
			break;

		case "girls_new_room":
			visionset_name = "zombie_theater_eroom_girlnew";
			break;

		case "girls_old_room":
			visionset_name = "zombie_theater_eroom_girlold";
			break;

		default:
			return;
	}

	clientnum = player GetLocalClientNumber();
	clientscripts\_visionset_mgr::visionset_apply(clientnum, visionset_name);
}

eeroom_visionset_off(player)
{
	switch(self.script_string)
	{
		case "asylum_room":
			visionset_name = "zombie_theater_eroom_asylum";
			break;

		case "pentagon_room":
			visionset_name = "zombie_theater_erooms_pentagon";
			break;

		case "girls_new_room":
			visionset_name = "zombie_theater_eroom_girlnew";
			break;

		case "girls_old_room":
			visionset_name = "zombie_theater_eroom_girlold";
			break;

		default:
			return;
	}

	clientnum = player GetLocalClientNumber();
	clientscripts\_visionset_mgr::visionset_remove(clientnum, visionset_name);
}