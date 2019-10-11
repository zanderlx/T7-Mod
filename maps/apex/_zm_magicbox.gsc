#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

#using_animtree("zm_magicbox");

init()
{
	include_magicbox();
	precache_magicbox();
	spawn_magicboxes();
	init_starting_chest_location();
	array_thread(level.chests, ::treasure_chest_think);
}

precache_magicbox()
{
	// PrecacheModel("zombie_treasure_box");
	// PrecacheModel("zombie_coast_bearpile");
	// PrecacheModel("zombie_treasure_box_lid");
	PrecacheModel(level.zombie_vars["zombie_magicbox_model"]);
	PrecacheModel(level.zombie_vars["zombie_magicbox_rubble_model"]);
	PrecacheModel(level.zombie_vars["zombie_magicbox_joker_model"]);
	PrecacheString(level.zombie_vars["zombie_magicbox_hint_buy"]);
	PrecacheString(level.zombie_vars["zombie_magicbox_hint_trade"]);
}

include_magicbox()
{
	flag_init("moving_chest_enabled", false);
	flag_init("moving_chest_now", false);
	flag_init("chest_has_been_used", false);

	level.chest_index = 0;
	level.chest_moves = 0;
	level.chest_accessed = 0;
	level.chests = [];
	level._zombiemode_check_firesale_loc_valid_func = ::default_check_firesale_loc_valid_func;
	level.magicbox_zbarrier_state_func = ::process_magicbox_zbarrier_state;
	level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM = 15;

	set_zombie_var("zombie_magicbox_cost", 950);
	set_zombie_var("zombie_magicbox_model", "p6_anim_zm_magic_box");
	set_zombie_var("zombie_magicbox_rubble_model", "p6_anim_zm_magic_box_fake");
	set_zombie_var("zombie_magicbox_joker_model", "zombie_teddybear");
	set_zombie_var("zombie_magicbox_hint_buy", &"ZOMBIE_MAGICBOX_BUY");
	set_zombie_var("zombie_magicbox_hint_trade", &"ZOMBIE_MAGICBOX_TRADE");

	if(isdefined(level._zm_magicbox_include))
		run_function(level, level._zm_magicbox_include);
	if(!isdefined(level.weapon_weighting_funcs))
		level.weapon_weighting_funcs = [];
	if(!isdefined(level.pandora_show_func))
		level.pandora_show_func = ::default_pandora_show_func;
	if(!isdefined(level.pandora_fx_func))
		level.pandora_fx_func = ::default_pandora_fx_func;
}

generate_magicbox_location(origin, angles)
{
	stub = SpawnStruct();
	stub.origin = origin;
	stub.angles = angles + (0, 90, 0);

	if(!isdefined(level._generated_magicboxes))
		level._generated_magicboxes = [];
	level._generated_magicboxes[level._generated_magicboxes.size] = stub;
	return stub;
}

spawn_magicboxes()
{
	structs = GetStructArray("zm_magicbox", "targetname");
	convert_legacy_magicbox_prefabs();

	if(!isdefined(level._generated_chest_num))
		level._generated_chest_num = 0;
	if(isdefined(level._generated_magicboxes) && level._generated_magicboxes.size > 0)
		structs = array_merge(structs, level._generated_magicboxes);
	if(!isdefined(structs) || structs.size == 0)
		return;

	for(i = 0; i < structs.size; i++)
	{
		stub = structs[i];

		origin = stub.origin;
		angles = stub.angles;

		if(!isdefined(origin))
			continue;
		if(!isdefined(angles))
			angles = (0, 0, 0);

		// Chest Model
		if(isdefined(stub.box_override))
		{
			stub.chest = stub.box_override;
			origin = stub.chest.origin;
			angles = stub.chest.angles;
		}
		else
			stub.chest = spawn_model("tag_origin", origin, angles);

		stub.chest SetModel(level.zombie_vars["zombie_magicbox_model"]);
		stub.chest UseAnimTree(#animtree);

		// Rubble Model
		if(isdefined(stub.rubble_override))
		{
			stub.rubble = stub.rubble_override;
			stub.rubble.origin = origin;
			stub.rubble.angles = angles;
		}
		else
			stub.chest = spawn_model("tag_origin", origin, angles);

		stub.rubble SetModel(level.zombie_vars["zombie_magicbox_rubble_model"]);
		stub.rubble UseAnimTree(#animtree);

		// PlayerTrigger
		stub.origin = origin + (AnglesToRight(angles) * -25);
		stub.angles = angles;
		stub.radius = 50;
		stub.height = 50;
		stub.script_unitrigger_type = "playertrigger_radius_use";
		stub.box_hacks = [];
		stub.prompt_and_visibility_func = ::playertrigger_update_prompt;

		if(!isdefined(stub.zombie_cost))
			stub.zombie_cost = level.zombie_vars["zombie_magicbox_cost"];

		if(!isdefined(stub.script_noteworthy))
		{
			stub.script_noteworthy = "generated_magicbox_0" + level._generated_chest_num;
			level._generated_chest_num++;
		}

		register_playertrigger(stub, ::playertrigger_think);
		level.chests[level.chests.size] = stub;
	}
}

convert_legacy_magicbox_prefabs()
{
	triggers = GetEntArray("treasure_chest_use", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		trigger = triggers[i];
		lid = GetEnt(trigger.target, "targetname");
		chest_origin = GetEnt(lid.target, "targetname");
		box = GetEnt(chest_origin.target, "targetname");
		rubble = GetEntArray(trigger.script_noteworthy + "_rubble", "script_noteworthy");
		rubble_model = getClosest(box.origin, rubble);
		rubble = array_remove(rubble, rubble_model);

		stub = generate_magicbox_location(box.origin, box.angles);
		stub.box_override = box;
		stub.rubble_override = rubble_model;
		stub.script_noteworthy = trigger.script_noteworthy;
		stub.start_exclude = trigger.start_exclude;
		stub.zombie_cost = trigger.zombie_cost;

		array_func(rubble, ::self_delete);
		chest_origin Delete();
		lid Delete();
		trigger Delete();
	}
}

playertrigger_update_prompt(player)
{
	self.hint_param1 = undefined;
	self.hint_string = undefined;

	if(!self trigger_visible_to_player(player))
		return false;

	if(is_true(self.stub.grab_weapon_hint))
		self.hint_string = level.zombie_vars["zombie_magicbox_hint_trade"];
	else
	{
		self.hint_string = level.zombie_vars["zombie_magicbox_hint_buy"];
		self.hint_param1 = self.stub.zombie_cost;
	}
	return true;
}

trigger_visible_to_player(player)
{
	if(isdefined(self.stub.chest_user) && !is_true(self.stub.box_rerespun))
	{
		if(player != self.stub.chest_user || !player maps\_zombiemode_weapons::can_buy_weapon())
			return false;
	}
	else
	{
		if(!player maps\_zombiemode_weapons::can_buy_weapon())
			return false;
	}
	return true;
}

playertrigger_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);
		self.stub notify("trigger", player);
	}
}

unregister_playertrigger_on_kill_think()
{
	self notify("unregister_playertrigger_on_kill_think");
	self endon("unregister_playertrigger_on_kill_think");
	self waittill("kill_chest_think");
	unregister_playertrigger(self);
}

default_check_firesale_loc_valid_func()
{
	return true;
}

default_weighting_func()
{
	return 1;
}

default_1st_move_weighting_func()
{
	if(level.chest_moves > 0)
		return 1;
	else
		return 0;
}

default_cymbal_monkey_weighting_func()
{
	players = GetPlayers();
	count = 0;

	for(i = 0; i < players.size; i++)
	{
		if(players[i] maps\_zombiemode_weapons::has_weapon_or_upgrade("zombie_cymbal_monkey"))
			count++;
	}

	if(count > 0)
		return 1;
	else
	{
		if(level.round_number < 10)
			return 3;
		return 5;
	}
}

init_starting_chest_location()
{
	start_chest_index = -1;

	for(i = 0; i < level.chests.size; i++)
	{
		chest = level.chests[i];

		if(is_true(level.random_pandora_box_start))
		{
			if(start_chest_index != -1 || is_true(chest.start_exclude))
				chest hide_chest();
			else
				start_chest_index = i;
		}
		else
		{
			if(start_chest_index != -1 || !isdefined(chest.script_noteworthy) || !IsSubStr(chest.script_noteworthy, "start_chest"))
				chest hide_chest();
			else
				start_chest_index = i;
		}
	}

	if(start_chest_index == -1)
		start_chest_index = RandomInt(level.chests.size);

	level.chest_index = start_chest_index;
	level.chests[start_chest_index].hidden = false;
	level.chests[start_chest_index] set_magic_box_zbarrier_state("initial");
	single_thread(level.chests[start_chest_index], level.pandora_show_func);
}

play_crazi_sound()
{
	if(is_true(level.player_4_vox_override))
		self PlayLocalSound("zmb_laugh_rich");
	else
		self PlayLocalSound("zmb_laugh_child");
}

show_chest(dont_enable_trigger)
{
	self thread set_magic_box_zbarrier_state("arriving");
	self waittill("arrived");
	single_thread(self, level.pandora_show_func);

	if(!is_true(dont_enable_trigger))
		register_playertrigger(self, ::playertrigger_think);

	PlaySoundAtPosition("zmb_box_poof_land", self.chest.origin);
	PlaySoundAtPosition("zmb_couch_slam", self.chest.origin);
	self.hidden = false;

	if(isdefined(self.box_hacks["summon_box"]))
		run_function(self, self.box_hacks["summon_box"], false);
}

hide_chest(doBoxLeave)
{
	unregister_playertrigger(self);

	if(isdefined(self.pandora_light))
		self.pandora_light Delete();

	self.hidden = true;

	if(isdefined(self.box_hacks["summon_box"]))
		run_function(self, self.box_hacks["summon_box"], true);

	if(is_true(doBoxLeave))
	{
		PlaySoundAtPosition("zmb_box_move", self.chest.origin);
		PlaySoundAtPosition("zmb_whoosh", self.chest.origin);

		if(is_true(level.player_4_vox_override))
			PlaySoundAtPosition("zmb_vox_rich_magicbox", self.chest.origin);
		else
			PlaySoundAtPosition("zmb_vox_ann_magicbox", self.chest.origin);

		self thread set_magic_box_zbarrier_state("leaving");
		self waittill("left");
		self thread set_magic_box_zbarrier_state("away");
		PlayFX(level._effect["poltergeist"], self.rubble.origin);
		PlaySoundAtPosition("zmb_box_poof", self.rubble.origin);
	}
	else
		self thread set_magic_box_zbarrier_state("away");
}

default_pandora_fx_func()
{
	if(isdefined(self.pandora_light))
	{
		self.pandora_light Unlink();
		self.pandora_light Delete();
	}

	self.pandora_light = spawn_model("tag_origin", self.chest.origin, self.chest.angles + (-90, 90, 0));
	self.pandora_light LinkTo(self.chest);
	PlayFXOnTag(level._effect["lght_marker"], self.pandora_light, "tag_origin");
}

default_pandora_show_func()
{
	run_function(self, level.pandora_fx_func);
	PlaySoundAtPosition("zmb_box_poof", self.chest.origin);
	wait .5;
	PlayFX(level._effect["lght_marker_flare"], self.pandora_light.origin);
}

treasure_chest_think()
{
	self endon("kill_chest_think");

	user = undefined;
	user_cost = undefined;
	self.box_rerespun = undefined;
	self.weapon_out = undefined;

	for(;;)
	{
		if(isdefined(self.forced_user) && IsPlayer(self.forced_user))
			user = self.forced_user;
		else
			self waittill("trigger", user);

		if(is_true(self.auto_open) && is_player_valid(user))
		{
			if(is_true(self.no_charge))
				user_cost = 0;
			else
			{
				user_cost = self.zombie_cost;
				user maps\_zombiemode_score::minus_to_player_score(user_cost);
			}

			self.chest_user = user;
			break;
		}
		else if(is_player_valid(user) && user.score >= self.zombie_cost)
		{
			user_cost = self.zombie_cost;
			user maps\_zombiemode_score::minus_to_player_score(user_cost);
			self.chest_user = user;
			break;
		}
		else if(user.score < self.zombie_cost)
			user maps\_zombiemode_audio::create_and_play_dialog("general", "no_money", undefined, 2);
	}

	flag_set("chest_has_been_used");
	self._box_open = true;
	self._box_opened_by_fire_sale = false;

	if(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && !is_true(self.auto_open) && run_function(self, level._zombiemode_check_firesale_loc_valid_func))
		self._box_opened_by_fire_sale = true;

	play_sound_at_pos("open_chest", self.chest.origin);
	play_sound_at_pos("music_chest", self.chest.origin);
	self set_magic_box_zbarrier_state("open");
	self.timedOut = false;
	self.weapon_out = true;
	self thread treasure_chest_weapon_spawn(user);
	self thread treasure_chest_glowfx();
	unregister_playertrigger(self);
	self waittill("randomization_done");

	if(flag("moving_chest_now") && !is_true(self._box_opened_by_fire_sale) && isdefined(user_cost) && user_cost > 0)
		user maps\_zombiemode_score::add_to_player_score(user_cost, false);

	if(flag("moving_chest_now") && !is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]))
		self thread treasure_chest_move(user);
	else
	{
		self.grab_weapon_hint = true;
		self.chest_user = user;
		register_playertrigger(self, ::playertrigger_think);
		self thread treasure_chest_timeout();

		for(;;)
		{
			self waittill("trigger", grabber);
			self.weapon_out = undefined;

			if(grabber != level && is_true(self.box_rerespun))
				user = grabber;

			if(grabber == user || grabber == level)
			{
				self.box_rerespun = undefined;

				if(grabber == user)
				{
					self notify("user_grabbed_weapon");
					user thread maps\_zombiemode_weapons::weapon_give(self.weapon_string);
					break;
				}
				else if(grabber == level)
				{
					self.timedOut = true;
					break;
				}
			}
		}

		self.grab_weapon_hint = false;
		self notify("weapon_grabbed");

		if(!is_true(self._box_opened_by_fire_sale))
			level.chest_accessed++;
		if(level.chest_moves > 0 && isdefined(level.pulls_since_last_ray_gun))
			level.pulls_since_last_ray_gun++;
		if(isdefined(level.pulls_since_last_tesla_gun))
			level.pulls_since_last_tesla_gun++;

		unregister_playertrigger(self);
		play_sound_at_pos("close_chest", self.origin);
		self set_magic_box_zbarrier_state("close");
		self waittill("closed");
		wait 1;

		if((is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && run_function(self, level._zombiemode_check_firesale_loc_valid_func)) || self == level.chests[level.chest_index])
			register_playertrigger(self, ::playertrigger_think);
	}

	self._box_open = false;
	self._box_opened_by_fire_sale = false;
	self.chest_user = undefined;
	self notify("chest_accessed");
	self thread treasure_chest_think();
}

default_box_move_logic()
{
	index = -1;

	for(i = 0; i < level.chests.size; i++)
	{
		if(IsSubStr(level.chests[i].script_noteworthy, "move" + (level.chest_moves + 1)) && i != level.chest_index)
		{
			index = i;
			break;
		}
	}

	if(index == -1)
		level.chest_index++;
	else
		level.chest_index = index;

	if(level.chest_index > level.chests.size)
	{
		temp_chest_name = level.chests[level.chest_index - 1].script_noteworthy;
		level.chest_index = 0;
		level.chests = array_randomize(level.chests);

		if(temp_chest_name == level.chests[level.chest_index].script_noteworthy)
			level.chest_index++;
	}
}

treasure_chest_move(player_vox)
{
	level waittill("weapon_fly_away_start");
	array_thread(GetPlayers(), ::play_crazi_sound);
	level waittill("weapon_fly_away_end");
	self hide_chest(true);
	wait .1;
	post_selection_wait_duration = 7;

	if(isdefined(player_vox))
		player_vox maps\_zombiemode_audio::create_and_play_dialog("general", "box_move");

	if(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && run_function(self, level._zombiemode_check_firesale_loc_valid_func))
	{
		current_sale_time = level.zombie_vars["zombie_powerup_fire_sale_time"];
		wait_network_frame();
		self thread fire_sale_fix();
		level.zombie_vars["zombie_powerup_fire_sale_time"] = current_sale_time;

		while(level.zombie_vars["zombie_powerup_fire_sale_time"] > 0)
		{
			wait .1;
		}
	}
	else
		post_selection_wait_duration += 5;

	if(isdefined(level._zombiemode_custom_box_move_logic))
		run_function(self, level._zombiemode_custom_box_move_logic);
	else
		default_box_move_logic();

	if(isdefined(level.chests[level.chest_index].box_hacks["summon_box"]))
		run_function(level.chests[level.chest_index], level.chests[level.chest_index].box_hacks["summon_box"], false);

	wait post_selection_wait_duration;
	PlayFX(level._effect["poltergeist"], level.chests[level.chest_index].chest.origin);
	level.chests[level.chest_index] show_chest();
	flag_clear("moving_chest_now");
	self.chest_moving = false;
}

fire_sale_fix()
{
	if(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]))
	{
		self.old_cost = self.zombie_cost;
		self thread show_chest();
		self.zombie_cost = level.zombie_vars["zombie_powerup_fire_sale_chest_cost"];
		wait_network_frame();
		level waittill("fire_sale_off");

		while(is_true(self._box_open))
		{
			wait .1;
		}

		self thread hide_chest(true);
		self.zombie_cost = self.old_cost;
	}
}

treasure_chest_timeout()
{
	self endon("user_grabbed_weapon");
	self endon("box_hacked_respin");
	self endon("box_hacked_rerespin");
	wait 12;
	self notify("trigger", level);
}

treasure_chest_CanPlayerReceiveWeapon(player, weapon)
{
	if(!is_weapon_in_box(weapon))
		return false;
	if(isdefined(player) && player maps\_zombiemode_weapons::has_weapon_or_upgrade(weapon))
		return false;
	if(!limited_weapon_below_quota(weapon, player))
		return false;
	if(isdefined(player) && isdefined(level.special_weapon_magicbox_check))
		return run_function(player, level.special_weapon_magicbox_check, weapon);
	return true;
}

treasure_chest_ChooseWeightedRandomWeapon(player)
{
	keys = array_randomize(GetArrayKeys(level.zombie_weapons));

	for(i = 0; i < keys.size; i++)
	{
		if(treasure_chest_CanPlayerReceiveWeapon(player, keys[i]))
			return keys[i];
	}
	return keys[0];
}

limited_weapon_below_quota(weapon, ignore_player)
{
	if(isdefined(level.limited_weapons) && isdefined(level.limited_weapons[weapon]))
	{
		upgrade_weapon = weapon;

		if(isdefined(level.zombie_weapons[weapon]) && isdefined(level.zombie_weapons[weapon].upgrade_name))
			upgrade_weapon = level.zombie_weapons[weapon].upgrade_name;

		count = 0;
		limit = level.limited_weapons[weapon];
		players = GetPlayers();
		pap_triggers = level._zm_packapunch_machines;

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isdefined(ignore_player) && ignore_player == player)
				continue;

			if(maps\_zombiemode_weapons::has_weapon_or_upgrade(weapon))
			{
				count++;

				if(count >= limit)
					return false;
			}
		}

		for(i = 0; i < pap_triggers.size; i++)
		{
			if(isdefined(pap_triggers[i].current_weapon) && (pap_triggers[i].current_weapon == weapon || pap_triggers[i].current_weapon == upgrade_weapon))
			{
				count++;

				if(count >= limit)
					return false;
			}
		}

		for(i = 0; i < level.chests.size; i++)
		{
			if(isdefined(level.chests[i].weapon_string) && level.chests[i].weapon_string == weapon)
			{
				count++;

				if(count >= limit)
					return false;
			}
		}

		if(isdefined(level.custom_limited_weapon_checks))
		{
			for(i = 0; i < level.custom_limited_weapon_checks.size; i++)
			{
				count += run_function(level, level.custom_limited_weapon_checks[i], weapon, ignore_player);
			}

			if(count >= limit)
				return false;
		}
	}
	return true;
}

clean_up_hacked_box()
{
	self endon("box_spin_done");
	self waittill("box_hacked_repsin");

	if(isdefined(self.weapon_model_dw))
	{
		self.weapon_model_dw Delete();
		self.weapon_model_dw = undefined;
	}

	if(isdefined(self.weapon_model))
	{
		self.weapon_model Delete();
		self.weapon_model = undefined;
	}
}

treasure_chest_weapon_spawn(player, repsin)
{
	self endon("box_hacked_respin");
	self thread clean_up_hacked_box();
	self.weapon_string = undefined;
	self.chest SetClientFlag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);
	wait 4;
	self.weapon_string = treasure_chest_ChooseWeightedRandomWeapon(player);
	self.chest ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);
	wait_network_frame();
	self.weapon_model = spawn_model(GetWeaponModel(self.weapon_string), self.chest.origin + (0, 0, 43), self.chest.angles + (0, 180, 0));
	self.weapon_model UseWeaponHideTags(self.weapon_string);

	if(maps\_zombiemode_weapons::weapon_is_dual_wield(self.weapon_string))
	{
		self.weapon_model_dw = spawn_model(maps\_zombiemode_weapons::get_left_hand_weapon_model_name(self.weapon_string), self.weapon_model.origin - (3, 3, 3), self.weapon_model.angles);
		self.weapon_model_dw UseWeaponHideTags(self.weapon_string);
		self.weapon_model_dw LinkTo(self.weapon_model);
	}

	if(!is_true(self._box_opened_by_fire_sale) && !(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && run_function(self, level._zombiemode_check_firesale_loc_valid_func)))
	{
		random = RandomInt(100);

		if(!isdefined(level.chest_min_move_usage))
			level.chest_min_move_usage = 4;

		if(level.chest_accessed < level.chest_min_move_usage)
			chance_of_joker = -1;
		else
		{
			chance_of_joker = level.chest_accessed + 20;

			if(level.chest_moves == 0 && level.chest_accessed >= 8)
				chance_of_joker = 100;

			if(level.chest_accessed >= 4 && level.chest_accessed < 8)
			{
				if(random < 15)
					chance_of_joker = 100;
				else
					chance_of_joker = -1;
			}

			if(level.chest_moves > 0)
			{
				if(level.chest_accessed >= 8 && level.chest_accessed < 13)
				{
					if(random < 30)
						chance_of_joker = 100;
					else
						chance_of_joker = -1;
				}
			}
		}

		if(is_true(self.no_fly_away))
			chance_of_joker = -1;
		if(isdefined(level._zombiemode_chest_joker_chance_mutator_func))
			chance_of_joker = run_function(level, level._zombiemode_chest_joker_chance_mutator_func, chance_of_joker);

		if(chance_of_joker > random)
		{
			self.weapon_string = undefined;
			self.weapon_model SetModel(level.zombie_vars["zombie_magicbox_joker_model"]);
			self.weapon_model.angles = self.chest.angles + (0, 90, 0);

			if(isdefined(self.weapon_model_dw))
			{
				self.weapon_model_dw Unlink();
				self.weapon_model_dw Delete();
				self.weapon_model_dw = undefined;
			}

			self.chest_moving = true;
			flag_set("moving_chest_now");
			level.chest_accessed = 0;
			level.chest_moves++;
		}
	}

	self notify("randomization_done");

	if(flag("moving_chest_now") && !(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && run_function(self, level._zombiemode_check_firesale_loc_valid_func)))
	{
		wait .5;
		level notify("weapon_fly_away_start");
		wait 2;
		self.weapon_model MoveZ(500, 4, 3);
		self.weapon_model waittill("movedone");
		self.weapon_model Delete();
		self notify("box_moving");
		level notify("weapon_fly_away_end");
	}
	else
	{
		if(self.weapon_string == "ray_gun_zm")
			level.pulls_since_last_ray_gun = 0;
		if(self.weapon_string == "tesla_gun_zm")
		{
			level.pulls_since_last_tesla_gun = 0;
			level.player_seen_tesla_gun = true;
		}

		if(is_true(repsin))
		{
			if(isdefined(self.box_hacks["respin_respin"]))
				run_function(self, self.box_hacks["respin_respin"], self.chest, player);
		}
		else
		{
			if(isdefined(self.box_hacks["respin"]))
				run_function(self, self.box_hacks["respin"], self.chest, player);
		}

		self.weapon_model thread timer_til_despawn(self.weapon_model_dw);
		self waittill("weapon_grabbed");

		if(!is_true(self.timedOut))
		{
			if(isdefined(self.weapon_model_dw))
			{
				self.weapon_model_dw Unlink();
				self.weapon_model_dw Delete();
				self.weapon_model_dw = undefined;
			}

			if(isdefined(self.weapon_model))
			{
				self.weapon_model Delete();
				self.weapon_model = undefined;
			}
		}
	}

	self.weapon_string = undefined;
	self notify("box_spin_done");
}

timer_til_despawn(weapon_model_dw)
{
	self endon("kill_weapon_movement");
	self MoveTo(self.origin - (0, 0, 43), 12, 6);
	wait 12;

	if(isdefined(weapon_model_dw))
	{
		weapon_model_dw Unlink();
		weapon_model_dw Delete();
	}

	if(isdefined(self))
		self Delete();
}

treasure_chest_glowfx()
{
	fx_ent = spawn_model("tag_origin", self.chest.origin, self.chest.angles + (90, 90, 0));
	fx_ent LinkTo(self.chest);
	PlayFXOnTag(level._effect["chest_light"], fx_ent, "tag_origin");
	self waittill_either("weapon_grabbed", "box_moving");
	fx_ent Unlink();
	fx_ent Delete();
}

is_weapon_in_box(weapon)
{
	if(!isdefined(level._zm_box_weapons))
		return false;
	return IsInArray(level._zm_box_weapons, weapon);
}

set_magic_box_zbarrier_state(state)
{
	self notify("zbarrier_state_change");
	self.rubble Hide();
	self.chest Hide();
	run_function(self, level.magicbox_zbarrier_state_func, state);
	self.state = state;
}

process_magicbox_zbarrier_state(state)
{
	switch(state)
	{
		case "away":
			self.rubble Show();
			self thread magic_box_teddy_twitches();
			break;
		case "arriving":
			self.chest Show();
			self thread magic_box_arrives();
			break;
		case "initial":
			self.chest Show();
			register_playertrigger(self, ::playertrigger_think);
			break;
		case "open":
			self.chest Show();
			self thread magic_box_opens();
			break;
		case "close":
			self.chest Show();
			self thread magic_box_closes();
			break;
		case "leaving":
			self.chest Show();
			self thread magic_box_leaves();
			break;
		case "hidden":
			break;
		default:
			if(isdefined(level.custom_magicbox_state_handler))
				run_function(self, level.custom_magicbox_state_handler, state);
			break;
	}
}

magic_box_teddy_twitches()
{
	self endon("zbarrier_state_change");

	for(;;)
	{
		wait RandomFloatRange(180, 1800);
		self.rubble ClearAnim(%root, .2);
		self.rubble SetAnim(%o_zombie_magic_box_fake_idle_twitch_a, 1, .2, 1);
		wait RandomFloatRange(180, 1800);
		self.rubble ClearAnim(%root, .2);
		self.rubble SetAnim(%o_zombie_magic_box_fake_idle_twitch_b, 1, .2, 1);
	}
}

magic_box_arrives()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_arrive", %o_zombie_magic_box_arrive, 1, .2, 1);
	self.chest waittillend("box_arrive");
	self notify("arrived");
}

magic_box_leaves()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_leave", %o_zombie_magic_box_leave, 1, .2, 1);
	self.chest waittillend("box_leave");
	self notify("left");
}

magic_box_opens()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_open", %o_zombie_magic_box_open, 1, .2, 1);
	self.chest waittillend("box_open");
	self notify("opened");
}

magic_box_closes()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_close", %o_zombie_magic_box_close, 1, .2, 1);
	self.chest waittillend("box_close");
	self notify("closed");
}

// spawning t4 / t5 styled magicbox
// spawn_magicbox(origin, angles)
// {
// 	if(!isdefined(level._generated_chest_num))
// 		level._generated_chest_num = 0;

// 	base_angles = angles + (0, 90, 0);
// 	forward = AnglesToForward(base_angles);
// 	right = AnglesToRight(base_angles);
// 	chest_box = spawn_model("zombie_treasure_box", origin, base_angles);
// 	chest_rubble = spawn_model("zombie_coast_bearpile", origin +(0, 0, 5.5) + (right * 14.5) + (forward * 18.5), base_angles + (0, 125, 0));
// 	chest_lid = spawn_model("zombie_treasure_box_lid", origin + (0, 0, 17.5) + (right * 12), base_angles);
// 	chest_origin = Spawn("script_origin", chest_box.origin);
// 	chest_origin.angles = chest_box.angles;
// 	trigger = Spawn("trigger_radius_use", origin + (0, 0, 60), 0, 40, 80);
// 	trigger.box_hacks = [];
// 	trigger.zombie_cost = 950;
// 	trigger.angles = angles;
// 	trigger.targetname = "treasure_chest_use";
// 	trigger.script_noteworthy = "generated_chest_00" + level._generated_chest_num;
// 	trigger.chest_rubble = array(chest_rubble);

// 	for(i = 0; i < trigger.chest_rubble.size; i++)
// 	{
// 		trigger.chest_rubble[i].script_noteworthy = trigger.script_noteworthy + "_rubble";
// 	}

// 	trigger.chest_box = chest_box;
// 	trigger.chest_lid = chest_lid;
// 	trigger.chest_origin = chest_origin;
// 	level._generated_chest_num++;
// 	return trigger;
// }