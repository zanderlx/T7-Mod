#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("vulture");
	clientscripts\apex\_zm_perks::register_perk_threads("vulture", ::give_vulture, ::take_vulture);
	init_vulture();

	level.zombiemode_using_vulture_perk = true;
}

init_vulture()
{
	level.zombies_global_perk_client_callback = ::vulture_global_perk_client_callback;
	OnPlayerConnect_Callback(::vulture_setup_on_player_connect);
	register_client_system("sndVultureStink", ::sndvulturestink);
	register_client_system("vulture_perk_disable_solo_quick_revive_glow", ::vulture_disable_solo_quick_revive_glow);
	register_client_system("vulture_perk_disease_meter", ::vulture_callback_stink_active);
	//clientscripts/mp/_visionset_mgr::vsmgr_register_overlay_info_style_filter("vulture_stink_overlay", 12000, 31, 0, 0, "generic_filter_zombie_perk_vulture", 0);

	level._effect["vulture_perk_zombie_stink"] = LoadFX("sanchez/vulture_aid/vulture_smell_idle");
	level._effect["vulture_perk_zombie_stink_trail"] = LoadFX("sanchez/vulture_aid/vulture_smell_trail");
	level._effect["vulture_perk_bonus_drop"] = LoadFX("sanchez/vulture_aid/vulture_powerup_on");
	level._effect["vulture_drop_picked_up"] = LoadFX("misc/fx_zombie_powerup_grab");
	level._effect["vulture_perk_wallbuy_static"] = LoadFX("sanchez/vulture_aid/vulture_wallgun_glow");
	level._effect["vulture_perk_machine_glow_doubletap"] = LoadFX("sanchez/vulture_aid/vulture_dtap_glow");
	level._effect["vulture_perk_machine_glow_juggernog"] = LoadFX("sanchez/vulture_aid/vulture_jugg_glow");
	level._effect["vulture_perk_machine_glow_revive"] = LoadFX("sanchez/vulture_aid/vulture_revive_glow");
	level._effect["vulture_perk_machine_glow_speed"] = LoadFX("sanchez/vulture_aid/vulture_speed_glow");
	level._effect["vulture_perk_machine_glow_marathon"] = LoadFX("sanchez/vulture_aid/vulture_stamin_glow");
	level._effect["vulture_perk_machine_glow_mule_kick"] = LoadFX("sanchez/vulture_aid/vulture_mule_glow");
	level._effect["vulture_perk_machine_glow_pack_a_punch"] = LoadFX("sanchez/vulture_aid/vulture_pap_glow");
	level._effect["vulture_perk_machine_glow_vulture"] = LoadFX("sanchez/vulture_aid/vulture_aid_glow");
	level._effect["vulture_perk_machine_glow_electric_cherry"] = LoadFX("sanchez/vulture_aid/vulture_cherry_glow");
	level._effect["vulture_perk_machine_glow_wunderfizz"] = LoadFX("sanchez/vulture_aid/vulture_fizz_glow");
	level._effect["vulture_perk_machine_glow_phd_flopper"] = LoadFX("sanchez/vulture_aid/vulture_phd_glow");
	level._effect["vulture_perk_machine_glow_whos_who"] = LoadFX("sanchez/vulture_aid/vulture_whoswho_glow");
	level._effect["vulture_perk_machine_glow_widows_wine"] = LoadFX("sanchez/vulture_aid/vulture_widows_glow");
	level._effect["vulture_perk_mystery_box_glow"] = LoadFX("sanchez/vulture_aid/vulture_box_glow");
	level._effect["vulture_perk_powerup_drop"] = LoadFX("sanchez/vulture_aid/vulture_powerup_glow");
	level._effect["vulture_perk_zombie_eye_glow"] = LoadFX("misc/fx_zombie_eye_vulture");

	level.perk_vulture = SpawnStruct();
	level.perk_vulture.array_stink_zombies = [];
	level.perk_vulture.array_stink_drop_locations = [];
	level.perk_vulture.players_with_vulture_perk = [];
	level.perk_vulture.vulture_vision_fx_list = [];

	register_clientflag_callback("scriptmover", 0, ::vulture_stink_fx);
	register_clientflag_callback("scriptmover", 1, ::vulture_drop_fx);
	register_clientflag_callback("scriptmover", 2, ::vulture_drop_pickup);
	register_clientflag_callback("scriptmover", 3, ::vulture_powerup_drop);
	register_clientflag_callback("scriptmover", 4, ::vulture_vision_mystery_box);
	register_clientflag_callback("actor", 0, ::vulture_stink_trail_fx);
	register_clientflag_callback("actor", 1, ::vulture_eye_glow);
	register_client_system("vulture_perk_active", ::vulture_toggle);

	level.perk_vulture.disable_solo_quick_revive_glow = false;

	if(!isdefined(level.perk_vulture.custom_funcs_enable))
		level.perk_vulture.custom_funcs_enable = [];
	if(!isdefined(level.perk_vulture.custom_funcs_disable))
		level.perk_vulture.custom_funcs_disable = [];

	level.zombie_eyes_clientfield_cb_additional = ::vulture_eye_glow_callback_from_system;
}

give_vulture(clientnum)
{
}

take_vulture(clientnum)
{
}

vulture_setup_on_player_connect(clientnum)
{
	player = GetLocalPlayer(clientnum);
	player vulture_on_player_connect(clientnum);
}

vulture_on_player_connect(clientnum)
{
	clientscripts\_filter::init_filter_indices();
	clientscripts\_filter::map_material_helper(self, "generic_filter_zombie_perk_vulture");
	self vulture_vision_init(clientnum, true);
	register_perk_clientfield_names_with_corresponding_perks();
}

vulture_add_custom_func_on_enable(func)
{
	if(!isdefined(level.perk_vulture.custom_funcs_enable))
		level.perk_vulture.custom_funcs_enable = [];
	level.perk_vulture.custom_funcs_enable[level.perk_vulture.custom_funcs_enable.size] = func;
}

vulture_add_fx_to_client_array(clientnum, n_fx_id, str_special)
{
	if(isdefined(str_special) && isdefined(level.perk_vulture.fx_array[clientnum].fx_list_special))
		level.perk_vulture.fx_array[clientnum].fx_list_special[str_special] = n_fx_id;
	level.perk_vulture.fx_array[clientnum].fx_list[level.perk_vulture.fx_array[clientnum].fx_list.size] = n_fx_id;
}

vulture_add_custom_func_on_disable(func)
{
	if(!isdefined(level.perk_vulture.custom_funcs_disable))
		level.perk_vulture.custom_funcs_disable = [];
	level.perk_vulture.custom_funcs_disable[level.perk_vulture.custom_funcs_disable.size] = func;
}

vulture_eye_glow(clientnum, set, newEnt)
{
	if(set)
	{
		self thread _zombie_eye_glow_think();
		self _zombie_eye_glow_enable(clientnum);
	}
	else
		self _zombie_eye_glow_disable(clientnum);
}

vulture_eye_glow_callback_from_system(clientnum, set, newEnt)
{
	if(!set)
		self _zombie_eye_glow_disable(clientnum);
}

vulture_powerup_drop(clientnum, set, newEnt)
{
	if(set)
	{
		if(!IsInArray(level.perk_vulture.vulture_vision.powerups, self))
		{
			level.perk_vulture.vulture_vision.powerups[level.perk_vulture.vulture_vision.powerups.size] = self;
			self _powerup_drop_fx_enable(clientnum);
		}
	}
	else
	{
		level.perk_vulture.vulture_vision.powerups = array_remove_nokeys(level.perk_vulture.vulture_vision.powerups, self);
		self _powerup_drop_fx_disable(clientnum);
	}
}

vulture_drop_fx(clientnum, set, newEnt)
{
	if(set)
	{
		self.n_vulture_drop_fx = PlayFXOnTag(clientnum, level._effect["vulture_perk_bonus_drop"], self, "tag_origin");
		PlaySound(clientnum, "zmb_perks_vulture_drop", self.origin);

		if(!isdefined(self.vulture_sound_locations))
			self.vulture_sound_locations = [];
		if(isdefined(self.vulture_sound_locations[clientnum]))
			SoundStopLoopEmitter("zmb_perks_vulture_loop", self.vulture_sound_locations[clientnum]);

		self.vulture_sound_locations[clientnum] = self.origin;
		SoundLoopEmitter("zmb_perks_vulture_loop", self.vulture_sound_locations[clientnum]);
	}
	else
	{
		if(isdefined(self) && isdefined(self.n_vulture_drop_fx))
		{
			DeleteFX(clientnum, self.n_vulture_drop_fx, true);

			if(isdefined(self.vulture_sound_locations) && isdefined(self.vulture_sound_locations[clientnum]))
				SoundStopLoopEmitter("zmb_perks_vulture_loop", self.vulture_sound_locations[clientnum]);
		}
	}
}

vulture_drop_pickup(clientnum, set, newEnt)
{
	if(set)
	{
		PlayFX(clientnum, level._effect["vulture_drop_picked_up"], self.origin);
		return;
	}
}

vulture_vision_mystery_box(clientnum, set, newEnt)
{
	if(set)
		self _mystery_box_fx_enable(clientnum);
	else
	{
		self _mystery_box_fx_disable(clientnum);
		level.perk_vulture.vulture_vision.mystery_box = array_remove_nokeys(level.perk_vulture.vulture_vision.mystery_box, self);
	}
}

vulture_stink_fx(clientnum, set, newEnt)
{
	if(set)
	{
		if(isdefined(self))
		{
			level.perk_vulture.array_stink_drop_locations[level.perk_vulture.array_stink_drop_locations.size] = self;
			self _stink_fx_enable(clientnum);
		}
	}
	else
	{
		if(isdefined(self))
		{
			level.perk_vulture.array_stink_drop_locations = array_remove_nokeys(level.perk_vulture.array_stink_drop_locations, self);
			level.perk_vulture.array_stink_drop_locations = array_removeUndefined(level.perk_vulture.array_stink_drop_locations);
			self _stink_fx_disable(clientnum);
		}
	}
}

vulture_toggle(clientnum, newval, fieldname)
{
	player = GetLocalPlayer(clientnum);

	if(newval == "1")
	{
		if(!IsInArray(level.perk_vulture.players_with_vulture_perk, player))
			level.perk_vulture.players_with_vulture_perk[clientnum] = player;

		array_func(level.perk_vulture.array_stink_zombies, ::_stink_trail_enable, clientnum);
		array_func(level.perk_vulture.array_stink_drop_locations, ::_stink_fx_enable, clientnum);
		player vulture_vision_enable(clientnum);

		for(i = 0; i < level.perk_vulture.custom_funcs_enable.size; i ++)
		{
			run_function(level, level.perk_vulture.custom_funcs_enable[i], clientnum);
		}
	}
	else
	{
		level.perk_vulture.players_with_vulture_perk[clientnum] = undefined;

		_clean_up_global_zombie_arrays(clientnum);
		array_func(level.perk_vulture.array_stink_zombies, ::_stink_trail_disable, clientnum);
		array_func(level.perk_vulture.array_stink_drop_locations, ::_stink_fx_disable, clientnum);

		player vulture_vision_disable(clientnum);

		for(i = 0; i < level.perk_vulture.custom_funcs_disable.size; i ++)
		{
			run_function(level, level.perk_vulture.custom_funcs_disable[i], clientnum);
		}
	}
}

vulture_stink_trail_fx(clientnum, set, newEnt)
{
	if(!isdefined(level.perk_vulture.array_stink_zombies))
		level.perk_vulture.array_stink_zombies = [];

	if(set)
	{
		level.perk_vulture.array_stink_zombies[level.perk_vulture.array_stink_zombies.size] = self;
		self _stink_trail_enable(clientnum);
	}
	else
	{
		level.perk_vulture.array_stink_zombies = array_remove_nokeys(level.perk_vulture.array_stink_zombies, self);
		_clean_up_global_zombie_arrays(clientnum);
		self _stink_trail_disable(clientnum);
	}
}

_powerup_drop_fx_enable(clientnum)
{
	if(isdefined(self))
	{
		if(!isdefined(self.perk_vulture_fx_id))
			self.perk_vulture_fx_id = [];

		if(_player_has_vulture(clientnum))
		{
			self.perk_vulture_fx_id[clientnum] = PlayFX(clientnum, level._effect["vulture_perk_powerup_drop"], self.origin);
			level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list[level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list.size] = self.perk_vulture_fx_id[clientnum];
		}
	}
}

_powerup_drop_fx_disable(clientnum)
{
	if(isdefined(self) && isdefined(self.perk_vulture_fx_id) && isdefined(self.perk_vulture_fx_id[clientnum]))
		DeleteFX(clientnum, self.perk_vulture_fx_id[clientnum], true);
}

_stink_trail_enable(clientnum)
{
	if(isdefined(self) && !isdefined(self.n_vulture_fx_trail) && _player_has_vulture(clientnum))
		self thread _loop_stink_trail(clientnum);
}

_loop_stink_trail(clientnum)
{
	self endon("vulture_stop_stink_trail_fx");

	if(!isdefined(self.perk_vulture_stink_trail))
		self.perk_vulture_stink_trail = [];

	if(!isdefined(self.sndent))
	{
		self.sndent = Spawn(0, self.origin, "script_origin");
		self.sndent LinkTo(self, "tag_origin");
	}

	sndent = self.sndent;
	sndent PlayLoopSound("zmb_perks_vulture_stink_loop", 1);
	self thread sndloopstinktraildelete(sndent);

	while(isdefined(self))
	{
		self.perk_vulture_stink_trail[clientnum] = PlayFX(clientnum, level._effect["vulture_perk_zombie_stink_trail"], self.origin);
		RealWait(0.1);
	}

	if(isdefined(sndent))
	{
		sndent StopLoopSound();
		sndent Delete();
	}
}

sndloopstinktraildelete(sndent)
{
	self endon("death");
	self waittill_any("vulture_stop_stink_trail_fx", "vulture_stop_stink_fx");

	if(isdefined(sndent))
	{
		sndent StopLoopSound();
		sndent Delete();
	}
}

_stink_trail_disable(clientnum)
{
	if(isdefined(self) && isdefined(self.perk_vulture_stink_trail) && isdefined(self.perk_vulture_stink_trail[clientnum]))
	{
		self notify("vulture_stop_stink_trail_fx");
		DeleteFX(clientnum, self.perk_vulture_stink_trail[clientnum], false);
	}
}

_stink_fx_enable(clientnum)
{
	if(isdefined(self) && !isdefined(self.n_vulture_fx_id) && _player_has_vulture(clientnum))
		self thread _loop_stink_stationary(clientnum);
}

_loop_stink_stationary(clientnum)
{
	if(!isdefined(self.perk_vulture_fx))
		self.perk_vulture_fx = [];

	self.perk_vulture_fx_active = true;
	sndorigin = self.origin;
	SoundLoopEmitter("zmb_perks_vulture_stink_loop", sndorigin);
	self thread sndloopstinkstationarydelete(sndorigin);

	while(isdefined(self) && isdefined(self.perk_vulture_fx_active) && self.perk_vulture_fx_active)
	{
		self.perk_vulture_fx[clientnum] = PlayFX(clientnum, level._effect["vulture_perk_zombie_stink"], self.origin);
		RealWait(0.125);
	}

	SoundStopLoopEmitter("zmb_perks_vulture_stink_loop", sndorigin);
}

sndloopstinkstationarydelete(sndorigin)
{
	self endon("death");
	self waittill_any("vulture_stop_stink_trail_fx", "vulture_stop_stink_fx");

	if(isdefined(sndorigin))
		SoundStopLoopEmitter("zmb_perks_vulture_stink_loop", sndorigin);
}

_stink_fx_disable(clientnum, b_kill_fx_immediately)
{
	if(isdefined(self))
	{
		self.perk_vulture_fx_active = false;
		self notify("vulture_stop_stink_fx");

		if(isdefined(self.perk_vulture_fx) && isdefined(self.perk_vulture_fx[clientnum]))
			DeleteFX(clientnum, self.perk_vulture_fx[clientnum], true);
	}
}

_mystery_box_fx_enable(clientnum)
{
	if(!IsInArray(level.perk_vulture.vulture_vision.mystery_box, self))
		level.perk_vulture.vulture_vision.mystery_box[level.perk_vulture.vulture_vision.mystery_box.size] = self;
	if(!isdefined(self.perk_vulture_fx_id))
		self.perk_vulture_fx_id = [];

	if(_player_has_vulture(clientnum))
	{
		n_fx_id = PlayFX(clientnum, level._effect["vulture_perk_mystery_box_glow"], self.origin, AnglesToRight(self.angles), AnglesToForward(self.angles));
		level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list[level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list.size] = n_fx_id;
		self.perk_vulture_fx_id[clientnum] = n_fx_id;
	}
}

_mystery_box_fx_disable(clientnum)
{
	if(_player_has_vulture(clientnum) && isdefined(level.perk_vulture.vulture_vision.mystery_box) && isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum]) && isdefined(self.perk_vulture_fx_id) && isdefined(self.perk_vulture_fx_id[clientnum]))
		DeleteFX(clientnum, self.perk_vulture_fx_id[clientnum], true);
}

_zombie_eye_glow_think()
{
	level.perk_vulture.vulture_vision.actors_eye_glow[level.perk_vulture.vulture_vision.actors_eye_glow.size] = self;
	self waittill_any("death", "entityshutdown");
	level.perk_vulture.vulture_vision.actors_eye_glow = array_removeUndefined(level.perk_vulture.vulture_vision.actors_eye_glow);
}

_zombie_eye_glow_enable(clientnum)
{
	if(_player_has_vulture(clientnum) && isdefined(self))
	{
		if(!isdefined(self.perk_vulture_fx_id))
			self.perk_vulture_fx_id = [];

		n_fx_id = level._effect["vulture_perk_zombie_eye_glow"];

		if(isdefined(level.perk_vulture.vulture_vision.actors_eye_glow_override))
			n_fx_id = level.perk_vulture.vulture_vision.actors_eye_glow_override;
		if(isdefined(self.vulture_perk_actor_eye_glow_override))
			n_fx_id = self.vulture_perk_actor_eye_glow_override;

		self.perk_vulture_fx_id[clientnum] = PlayFXOnTag(clientnum, n_fx_id, self, "J_Eyeball_LE");
	}
}

set_vulture_custom_eye_glow(n_fx_id)
{
	level.perk_vulture.vulture_vision.actors_eye_glow_override = n_fx_id;
}

_zombie_eye_glow_disable(clientnum)
{
	if(isdefined(self) && isdefined(self.perk_vulture_fx_id) && isdefined(self.perk_vulture_fx_id[clientnum]))
		DeleteFX(clientnum, self.perk_vulture_fx_id[clientnum], true);
}

_player_has_vulture(clientnum)
{
	return isdefined(level.perk_vulture.players_with_vulture_perk[clientnum]);
}

_clean_up_global_zombie_arrays(clientnum)
{
	if(isdefined(level.perk_vulture.array_stink_zombies))
		level.perk_vulture.array_stink_zombies = array_removeUndefined(level.perk_vulture.array_stink_zombies);
}

vulture_vision_init(clientnum, b_first_run)
{
	if(!isdefined(b_first_run))
		b_first_run = false;

	if(!isdefined(level.perk_vulture.vulture_vision))
	{
		level.perk_vulture.vulture_vision = SpawnStruct();
		level.perk_vulture.vulture_vision.perk_machines = [];
		level.perk_vulture.vulture_vision.mystery_box = [];
		level.perk_vulture.vulture_vision.powerups = [];
		level.perk_vulture.vulture_vision.actors_eye_glow = [];
		level.perk_vulture.vulture_vision.custom = [];
		vulture_vision_update_wallbuy_list(clientnum, b_first_run);
		setup_perk_machine_fx();
		a_perk_machines = GetStructArray("zm_perk_machine", "targetname");

		for(i = 0; i < a_perk_machines.size; i ++)
		{
			struct = a_perk_machines[i];
			level.perk_vulture.vulture_vision.perk_machines[struct.script_noteworthy] = struct;
		}

		level.perk_vulture.vulture_vision_enabled = true;
		level thread wallbuy_update_listener(clientnum);
	}
}

wallbuy_update_listener(clientnum)
{
	while(true)
	{
		level waittill("wallbuy_updated");
		vulture_vision_update_wallbuy_list(clientnum);
	}
}

vulture_vision_update_wallbuy_list(clientnum, b_first_run)
{
	if(!isdefined(b_first_run))
		b_first_run = false;

	if(isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum]) && isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_wallbuy))
	{
		for(i = 0; i < level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_wallbuy.size; i ++)
		{
			n_fx_id = level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_wallbuy[i];
			DeleteFX(clientnum, n_fx_id, true);
		}
	}

	// level.perk_vulture.vulture_vision.wall_buys_static = [];
	// level.perk_vulture.vulture_vision.wall_buys_dynamic = [];
	// a_wall_buys = _get_wallbuy_array();
	// a_keys = GetArrayKeys(a_wall_buys);

	// for(i = 0; i < a_keys.size; i ++)
	// {
	// 	s_temp = a_wall_buys[a_keys[i]];

	// 	if(s_temp.script_noteworthy == "dynamic")
	// 	{
	// 		if(isdefined(s_temp.models) && s_temp.models.size > 0)
	// 			level.perk_vulture.vulture_vision.wall_buys_static[level.perk_vulture.vulture_vision.wall_buys_static.size] = s_temp;
	// 		else
	// 			level.perk_vulture.vulture_vision.wall_buys_dynamic[level.perk_vulture.vulture_vision.wall_buys_dynamic.size] = s_temp;
	// 		continue;
	// 	}
	// 	else
	// 		level.perk_vulture.vulture_vision.wall_buys_static[level.perk_vulture.vulture_vision.wall_buys_static.size] = s_temp;
	// }

	if(!b_first_run)
		vulture_vision_show_wallbuy_fx(clientnum);
}

vulture_vision_show_wallbuy_fx(clientnum)
{
	// if(_player_has_vulture(clientnum))
	// {
	// 	s_temp = level.perk_vulture.vulture_vision_fx_list[clientnum];

	// 	for(i = 0; i < level.perk_vulture.vulture_vision.wall_buys_static.size; i ++)
	// 	{
	// 		ent = level.perk_vulture.vulture_vision.wall_buys_static[i];
	// 		s_temp.fx_list_wallbuy[s_temp.fx_list_wallbuy.size] = PlayFX(clientnum, level._effect["vulture_perk_wallbuy_static"], ent.origin, AnglesToForward(ent.angles), AnglesToUp(ent.angles));
	// 	}

	// 	for(i = 0; i < level.perk_vulture.vulture_vision.wall_buys_dynamic.size; i ++)
	// 	{
	// 		ent = level.perk_vulture.vulture_vision.wall_buys_dynamic[i];
	// 		s_temp.fx_list_wallbuy[s_temp.fx_list_wallbuy.size] = PlayFX(clientnum, level._effect["vulture_perk_wallbuy_dynamic"], ent.origin, AnglesToForward(ent.angles), AnglesToUp(ent.angles));
	// 	}
	// }
}

vulture_vision_enable(clientnum)
{
	if(isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum]))
		vulture_vision_disable(clientnum);

	level.perk_vulture.vulture_vision_fx_list[clientnum] = SpawnStruct();
	s_temp = level.perk_vulture.vulture_vision_fx_list[clientnum];
	s_temp.player_ent = self;
	s_temp.fx_list = [];
	s_temp.fx_list_wallbuy = [];
	s_temp.fx_list_special = [];
	vulture_vision_show_wallbuy_fx(clientnum);
	a_keys = GetArrayKeys(level.perk_vulture.vulture_vision.perk_machines);

	for(i = 0; i < a_keys.size; i ++)
	{
		s_perk_machine = level.perk_vulture.vulture_vision.perk_machines[a_keys[i]];

		if(isdefined(level.perk_vulture.vulture_vision.perk_machine_fx[a_keys[i]]))
			str_perk_machine_fx = level.perk_vulture.vulture_vision.perk_machine_fx[a_keys[i]];
		else
			str_perk_machine_fx = "vulture_perk_machine_glow_speed";

		if((a_keys[i] == "specialty_weapupgrade" || a_keys[i] == "vulture") || !self has_perk(clientnum, a_keys[i]))
		{
			if(a_keys[i] != "revive" || !level.perk_vulture.disable_solo_quick_revive_glow)
				s_temp.fx_list_special[a_keys[i]] = PlayFX(clientnum, level._effect[str_perk_machine_fx], s_perk_machine.origin, AnglesToForward(s_perk_machine.angles), AnglesToUp(s_perk_machine.angles));
		}
	}

	if(level.perk_vulture.vulture_vision.mystery_box.size > 0)
	{
		level.perk_vulture.vulture_vision.mystery_box = array_removeUndefined(level.perk_vulture.vulture_vision.mystery_box);
		array_func(level.perk_vulture.vulture_vision.mystery_box, ::_mystery_box_fx_enable, clientnum);
	}

	array_func(level.perk_vulture.vulture_vision.powerups, ::_powerup_drop_fx_enable, clientnum);
	array_func(level.perk_vulture.vulture_vision.actors_eye_glow, ::_zombie_eye_glow_enable, clientnum);
	self.perk_vulture = s_temp;
	level.perk_vulture.fx_array[clientnum] = s_temp;
}

setup_perk_machine_fx()
{
	register_perk_machine_fx("jugg", "vulture_perk_machine_glow_juggernog");
	register_perk_machine_fx("doubletap", "vulture_perk_machine_glow_doubletap");
	register_perk_machine_fx("revive", "vulture_perk_machine_glow_revive");
	register_perk_machine_fx("speed_cola", "vulture_perk_machine_glow_speed");
	// register_perk_machine_fx("specialty_weapupgrade", "vulture_perk_machine_glow_pack_a_punch");
	register_perk_machine_fx("marathon", "vulture_perk_machine_glow_marathon");
	register_perk_machine_fx("mule_kick", "vulture_perk_machine_glow_mule_kick");
	register_perk_machine_fx("vulture", "vulture_perk_machine_glow_vulture");
	register_perk_machine_fx("divetonuke", "vulture_perk_machine_glow_phd_flopper");
	register_perk_machine_fx("cherry", "vulture_perk_machine_glow_electric_cherry");
	register_perk_machine_fx("chugabud", "vulture_perk_machine_glow_whos_who");
	register_perk_machine_fx("widows", "vulture_perk_machine_glow_widows_wine");
	register_perk_machine_fx("deadshot", "vulture_perk_machine_glow_deadshot");
	register_perk_machine_fx("tombstone", "vulture_perk_machine_glow_tombstone");
}

register_perk_machine_fx(str_perk, str_fx_reference)
{
	if(!isdefined(level.perk_vulture.vulture_vision.perk_machine_fx))
		level.perk_vulture.vulture_vision.perk_machine_fx = [];
	if(!isdefined(level.perk_vulture.vulture_vision.perk_machine_fx[str_perk]))
		level.perk_vulture.vulture_vision.perk_machine_fx[str_perk] = str_fx_reference;
}

vulture_vision_disable(clientnum)
{
	if(isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum]))
	{
		if(isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list))
		{
			keys = GetArrayKeys(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list);
			for(i = 0; i < keys.size; i ++)
			{
				n_fx_id = level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list[keys[i]];
				DeleteFX(clientnum, n_fx_id, true);
			}
		}

		if(isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_wallbuy))
		{
			keys = GetArrayKeys(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_wallbuy);
			for(i = 0; i < keys.size; i ++)
			{
				n_fx_id = level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_wallbuy[keys[i]];
				DeleteFX(clientnum, n_fx_id, true);
			}
		}

		if(isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_special))
		{
			keys = GetArrayKeys(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_special);
			for(i = 0; i < keys.size; i ++)
			{
				n_fx_id = level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_special[keys[i]];
				DeleteFX(clientnum, n_fx_id, true);
			}
		}
	}

	array_func(level.perk_vulture.vulture_vision.powerups, ::_powerup_drop_fx_disable, clientnum);
	array_func(level.perk_vulture.vulture_vision.actors_eye_glow, ::_zombie_eye_glow_disable, clientnum);
}

_get_wallbuy_array()
{
	return level._active_wallbuys;
}

vulture_global_perk_client_callback(clientnum, newval, fieldname)
{
	b_icon_should_appear = newval == "1";

	if(isdefined(level.perk_vulture) && b_icon_should_appear)
	{
		if(isdefined(level.perk_vulture.vulture_vision.perk_clientfields[fieldname]))
		{
			str_perk = level.perk_vulture.vulture_vision.perk_clientfields[fieldname];

			if((str_perk != "specialty_weapupgrade" && str_perk != "vulture" && self has_perk(clientnum, str_perk)) || (str_perk == "revive" && level.perk_vulture.disable_solo_quick_revive_glow))
			{
				if(_player_has_vulture(clientnum) && isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum]) && isdefined(level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_special[str_perk]))
					DeleteFX(clientnum, level.perk_vulture.vulture_vision_fx_list[clientnum].fx_list_special[str_perk], true);
			}
		}
	}
}

register_perk_with_clientfield(str_clientfield, str_perk)
{
	if(!isdefined(level.perk_vulture.vulture_vision.perk_clientfields))
		level.perk_vulture.vulture_vision.perk_clientfields = [];
	if(!isdefined(level.perk_vulture.vulture_vision.perk_clientfields[str_clientfield]))
		level.perk_vulture.vulture_vision.perk_clientfields[str_clientfield] = str_perk;
}

register_perk_clientfield_names_with_corresponding_perks()
{
	/*
	register_perk_with_clientfield("perk_additional_primary_weapon", "mule_kick");
	register_perk_with_clientfield("perk_dead_shot", "deadshot");
	register_perk_with_clientfield("perk_dive_to_nuke", "divetonuke");
	register_perk_with_clientfield("perk_double_tap", "doubletap");
	register_perk_with_clientfield("perk_juggernaut", "jugg");
	register_perk_with_clientfield("perk_marathon", "marathon");
	register_perk_with_clientfield("perk_quick_revive", "revive");
	register_perk_with_clientfield("perk_sleight_of_hand", "speed_cola");
	register_perk_with_clientfield("perk_tombstone", "tombstone");
	register_perk_with_clientfield("perk_chugabud", "chugabud");
	register_perk_with_clientfield("perk_electric_cherry", "cherry");
	register_perk_with_clientfield("perk_vulture", "vulture");
	register_perk_with_clientfield("perk_widows", "widows");
	*/
}

vulture_disable_solo_quick_revive_glow(clientnum, newval, fieldname)
{
	if(newval == "1")
		level.perk_vulture.disable_solo_quick_revive_glow = true;
	else
		level.perk_vulture.disable_solo_quick_revive_glow = false;
}

sndvulturestink(clientnum, newval, fieldname)
{
	player = GetLocalPlayer(clientnum);

	if(newval == "1")
		player thread sndactivatevulturestink();
	else
		player thread snddeactivatevulturestink();
}

sndactivatevulturestink()
{
	if(!isdefined(self.sndstinkent))
	{
		self.sndstinkent = Spawn(0, (0, 0, 0), "script_origin");
		self.sndstinkent PlayLoopSound("zmb_perks_vulture_stink_player_loop", 0.5);
	}

	PlaySound(0, "zmb_perks_vulture_stink_start", (0, 0, 0));
	clientscripts\_audio::snd_set_snapshot("zmb_buried_stink");
}

snddeactivatevulturestink()
{
	PlaySound(0, "zmb_perks_vulture_stink_stop", (0, 0, 0));
	clientscripts\_audio::snd_set_snapshot("default");

	if(isdefined(self.sndstinkent))
	{
		self.sndstinkent StopLoopSound();
		self.sndstinkent Delete();
		self.sndstinkent = undefined;
	}
}

vulture_callback_stink_active(clientnum, newval, fieldname)
{
	player = GetLocalPlayer(clientnum);

	if(isdefined(player))
	{
		if(newval != "0")
		{
			player vulture_fogbank_enable(clientnum);
			return;
		}
		else
			player vulture_fogbank_disable(clientnum);
	}
}

vulture_fogbank_disable(clientnum)
{
	if(isdefined(level.perk_vulture.fog_banks_enabled) && isdefined(level.perk_vulture.fog_bank_stink_off))
	{
		//SetWorldFogActiveBank(clientnum, level.perk_vulture.fog_bank_stink_off);
	}
}

vulture_fogbank_enable(clientnum)
{
	if(isdefined(level.perk_vulture.fog_banks_enabled) && isdefined(level.perk_vulture.fog_bank_stink_on))
	{
		//SetWorldFogActiveBank(clientnum, level.perk_vulture.fog_bank_stink_on);
	}
}