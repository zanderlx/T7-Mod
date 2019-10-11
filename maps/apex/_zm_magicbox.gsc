#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	precache_magicbox();

	if(!isdefined(level.weapon_weighting_funcs))
		level.weapon_weighting_funcs = [];
	if(!isdefined(level.pandora_show_func))
		level.pandora_show_func = ::default_pandora_show_func;
	if(!isdefined(level.pandora_fx_func))
		level.pandora_fx_func = ::default_pandora_fx_func;

	flag_init("moving_chest_enabled", false);
	flag_init("moving_chest_now", false);
	flag_init("chest_has_been_used", false);

	level.chest_index = 0;
	level.chest_moves = 0;
	level.chest_accessed = 0;
	level.chests = GetEntArray("treasure_chest_use", "targetname");
	level._zombiemode_check_firesale_loc_valid_func = ::default_check_firesale_loc_valid_func;
	array_func(level.chests, ::get_chest_pieces);
	// level.chests[level.chests.size] = spawn_magicbox((0, 0, 0), (0, 0, 0));

	if(level.chests.size > 1)
	{
		flag_set("moving_chest_enabled");
		level.chests = array_randomize(level.chests);
		init_starting_chest_location();
	}

	array_thread(level.chests, ::treasure_chest_think);
}

precache_magicbox()
{
	PrecacheModel("zombie_treasure_box");
	PrecacheModel("zombie_coast_bearpile");
	PrecacheModel("zombie_treasure_box_lid");
	PrecacheModel("zombie_teddybear");
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
	level.chests[start_chest_index] hide_rubble();
	level.chests[start_chest_index].hidden = false;
	single_thread(level.chests[start_chest_index], level.pandora_show_func);
}

hide_rubble()
{
	for(i = 0; i < self.chest_rubble.size; i++)
	{
		self.chest_rubble[i] Hide();
	}
}

show_rubble()
{
	for(i = 0; i < self.chest_rubble.size; i++)
	{
		self.chest_rubble[i] Show();
	}
}

set_treasure_chest_cost(cost)
{
	level.zombie_treasure_chest_cost = cost;
}

get_chest_pieces()
{
	self.box_hacks = [];
	self.chest_lid = GetEnt(self.target, "targetname");
	self.chest_origin = GetEnt(self.chest_lid.target, "targetname");
	self.chest_box = GetEnt(self.chest_origin.target, "targetname");
	self.chest_rubble = GetEntArray(self.script_noteworthy + "_rubble", "script_noteworthy");
}

play_crazi_sound()
{
	if(is_true(level.player_4_vox_override))
		self PlayLocalSound("zmb_laugh_rich");
	else
		self PlayLocalSound("zmb_laugh_child");
}

show_chest()
{
	single_thread(self, level.pandora_show_func);
	self enable_trigger();
	self.chest_lid Show();
	self.chest_box Show();
	self.chest_lid PlaySound("zmb_box_poof_land");
	self.chest_lid PlaySound("zmb_couch_slam");
	self.hidden = false;

	if(isdefined(self.box_hacks["summon_box"]))
		run_function(self, self.box_hacks["summon_box"], false);
}

hide_chest()
{
	self disable_trigger();
	self.chest_lid Hide();
	self.chest_box Hide();

	if(isdefined(self.pandora_light))
		self.pandora_light Delete();

	self.hidden = true;

	if(isdefined(self.box_hacks["summon_box"]))
		run_function(self, self.box_hacks["summon_box"], true);
}

default_pandora_fx_func()
{
	if(isdefined(self.pandora_light))
	{
		self.pandora_light Unlink();
		self.pandora_light Delete();
	}

	self.pandora_light = spawn_model("tag_origin", self.chest_origin.origin, self.chest_origin.angles + (-90, 0, 0));
	self.pandora_light LinkTo(self.chest_box);
	PlayFXOnTag(level._effect["lght_marker"], self.pandora_light, "tag_origin");
}

default_pandora_show_func()
{
	run_function(self, level.pandora_fx_func);
	PlaySoundAtPosition("zmb_box_poof", self.chest_lid.origin);
	wait .5;
	PlayFX(level._effect["lght_marker_flare"], self.pandora_light.origin);
}

treasure_chest_think()
{
	self endon("kill_chest_think");

	if(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && run_function(self, level._zombiemode_check_firesale_loc_valid_func))
		self set_hint_string(self, "powerup_fire_sale_cost");
	else
		self set_hint_string(self, "default_treasure_chest_" + self.zombie_cost);

	self SetCursorHint("HINT_NOICON");
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

		weapon = user GetCurrentWeapon();

		if(user in_revive_trigger() || user is_drinking() || is_true(self.disabled) || weapon == "none")
			continue;

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

	self.chest_lid thread treasure_chest_lid_open();
	self.timedOut = false;
	self.weapon_out = true;
	self.chest_origin thread treasure_chest_weapon_spawn(self, user);
	self.chest_origin thread treasure_chest_glowfx();
	self disable_trigger();
	self.chest_origin waittill("randomization_done");

	if(flag("moving_chest_now") && !is_true(self._box_opened_by_fire_sale) && isdefined(user_cost) && user_cost > 0)
		user maps\_zombiemode_score::add_to_player_score(user_cost, false);

	if(flag("moving_chest_now") && !is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]))
		self thread treasure_chest_move(user);
	else
	{
		self.grab_weapon_hint = true;
		self.chest_user = user;
		self SetHintString(&"ZOMBIE_TRADE_WEAPONS");
		self SetCursorHint("HINT_NOICON");
		self enable_trigger();
		self thread treasure_chest_timeout();

		for(;;)
		{
			self waittill("trigger", grabber);

			self.weapon_out = undefined;

			if(IsPlayer(grabber))
			{
				if(grabber is_drinking())
					continue;
				if(grabber GetCurrentWeapon() == "none")
					continue;

				// if grabber is player, graber != level == true
				if(is_true(self.box_rerespun))
					user = grabber;
			}

			if(grabber == user || grabber == level)
			{
				self.box_rerespun = undefined;
				current_weapon = "none";

				if(is_player_valid(user))
					current_weapon = user GetCurrentWeapon();

				if(grabber == user && is_player_valid(user) && !user is_drinking() && !is_placeable_mine(current_weapon) && !is_equipment(current_weapon) && current_weapon != "syrette_sp")
				{
					self notify("user_grabbed_weapon");
					user thread maps\_zombiemode_weapons::weapon_give(self.chest_origin.weapon_string);
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
		self.chest_origin notify("weapon_grabbed");

		if(!is_true(self._box_opened_by_fire_sale))
			level.chest_accessed++;
		if(level.chest_moves > 0 && isdefined(level.pulls_since_last_ray_gun))
			level.pulls_since_last_ray_gun++;
		if(isdefined(level.pulls_since_last_tesla_gun))
			level.pulls_since_last_tesla_gun++;

		self disable_trigger();
		self.chest_lid thread treasure_chest_lid_close(self.timedOut);
		wait 3;

		if((is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && run_function(self, level._zombiemode_check_firesale_loc_valid_func)) || self == level.chests[level.chest_index])
		{
			self enable_trigger();
			self SetVisibleToAll();
		}
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
	self.chest_lid thread treasure_chest_lid_close(false);
	self SetVisibleToAll();
	self hide_chest();

	fake_pieces = [];
	fake_pieces[0] = spawn_model(self.chest_lid.model, self.chest_lid.origin, self.chest_lid.angles);
	fake_pieces[1] = spawn_model(self.chest_box.model, self.chest_box.origin, self.chest_box.angles);
	anchor = Spawn("script_origin", fake_pieces[0].origin);
	soundPoint = Spawn("script_origin", self.chest_origin.origin);
	anchor PlaySound("zmb_box_move");

	for(i = 0; i < fake_pieces.size; i++)
	{
		fake_pieces[i] LinkTo(anchor);
	}

	PlaySoundAtPosition("zmb_whoosh", soundPoint.origin);

	if(is_true(level.player_4_vox_override))
		PlaySoundAtPosition("zmb_vox_rich_magicbox", soundPoint.origin);
	else
		PlaySoundAtPosition("zmb_vox_ann_magicbox", soundPoint.origin);

	anchor MoveTo(anchor.origin + (0, 0, 50), 5);

	if(isdefined(level.custom_vibrate_func))
		run_function(anchor, level.custom_vibrate_func, anchor);
	else
	{
		dir = self.chest_box.origin - self.chest_lid.origin;
		dir = (dir[1], dir[0], 0);

		if(dir[1] < 0 || (dir[0] > 0 && dir[1] > 0))
			dir = (dir[0], dir[1] * -1, 0);
		else if(dir[0] < 0)
			dir = (dir[0] * -1, dir[1], 0);

		anchor Vibrate(dir, 10, .5, 5);
	}

	anchor waittill("movedone");
	PlayFX(level._effect["poltergeist"], self.chest_origin.origin);
	PlaySoundAtPosition("zmb_box_poof", soundPoint.origin);
	array_func(fake_pieces, ::self_delete);
	self show_rubble();
	wait .1;
	anchor Delete();
	soundPoint Delete();
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
	PlayFX(level._effect["poltergeist"], level.chests[level.chest_index].origin);
	level.chests[level.chest_index] show_chest();
	level.chests[level.chest_index] hide_rubble();
	flag_clear("moving_chest_now");
	self.chest_origin.chest_moving = false;
}

fire_sale_fix()
{
	if(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]))
	{
		self.old_cost = self.zombie_cost;
		self thread show_chest();
		self thread hide_rubble();
		self.zombie_cost = level.zombie_vars["zombie_powerup_fire_sale_chest_cost"];
		self set_hint_string(self, "powerup_fire_sale_cost");
		wait_network_frame();
		level waittill("fire_sale_off");

		while(is_true(self._box_open))
		{
			wait .1;
		}

		PlayFX(level._effect["poltergeist"], self.origin);
		self PlaySound("zmb_box_poof_land");
		self PlaySound("zmb_couch_slam");
		self thread hide_chest();
		self thread show_rubble();
		self.zombie_cost = self.old_cost;
		self set_hint_string(self, "default_treasure_chest_" + self.zombie_cost);
	}
}

treasure_chest_timeout()
{
	self endon("user_grabbed_weapon");
	self.chest_origin endon("box_hacked_respin");
	self.chest_origin endon("box_hacked_rerespin");
	wait 12;
	self notify("trigger", level);
}

treasure_chest_lid_open()
{
	self RotateRoll(105, .5, .25);
	play_sound_at_pos("open_chest", self.origin);
	play_sound_at_pos("music_chest", self.origin);
}

treasure_chest_lid_close(timedOut)
{
	self RotateRoll(-105, .5, .25);
	play_sound_at_pos("close_chest", self.origin);
	self notify("lid_closed");
}

treasure_chest_ChooseRandomWeapon(player)
{
	return random(level.zombie_weapons);
}

treasure_chest_ChooseWeightedRandomWeapon(player)
{
	keys = GetArrayKeys(level.zombie_weapons);
	filtered = [];

	for(i = 0; i < keys.size; i++)
	{
		if(!isdefined(keys[i]))
			continue;
		if(!is_weapon_in_box(keys[i]))
			continue;

		if(isdefined(level.weapon_weighting_funcs[keys[i]]))
		{
			count = run_function(level, level.weapon_weighting_funcs[keys[i]]);

			if(isdefined(count))
			{
				if(count > 1)
				{
					for(j = 0; j < count; j++)
					{
						filtered[filtered.size] = keys[i];
					}
				}
			}
			else
				filtered[filtered.size] = keys[i];
		}
		else
			filtered[filtered.size] = keys[i];
	}

	if(isdefined(level.limited_weapons))
	{
		keys2 = GetArrayKeys(level.limited_weapons);
		players = GetPlayers();
		pap_triggers = level._zm_packapunch_machines;

		for(i = 0; i < keys2.size; i++)
		{
			weapon = keys2[i];
			count = 0;

			for(j = 0; j < players.size; j++)
			{
				if(players[j] maps\_zombiemode_weapons::has_weapon_or_upgrade(weapon))
					count++;
			}

			for(j = 0; j < pap_triggers.size; j++)
			{
				if(isdefined(pap_triggers[j].current_weapon) && pap_triggers[j].current_weapon == weapon)
					count++;
				else if(isdefined(pap_triggers[j].upgrade_weapon) && pap_triggers[j].upgrade_weapon == weapon)
					count++;
			}

			for(j = 0; j < level.chests.size; j++)
			{
				if(isdefined(level.chests[j].chest_origin.weapon_string) && level.chests[j].chest_origin.weapon_string == weapon)
					count++;
			}

			if(isdefined(level.random_weapon_powerups))
			{
				for(j = 0; j < level.random_weapon_powerups.size; j++)
				{
					if(isdefined(level.random_weapon_powerups[j]) && level.random_weapon_powerups[j].base_weapon == weapon)
						count++;
				}
			}

			if(count >= level.limited_weapons[weapon])
				filtered = array_remove(filtered, weapon);
		}
	}
	return random(filtered);
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

treasure_chest_weapon_spawn(chest, player, repsin)
{
	self endon("box_hacked_respin");
	self thread clean_up_hacked_box();
	self.weapon_string = undefined;
	modelname = undefined;
	rand = undefined;
	number_cycles = 40;
	chest.chest_box SetClientFlag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);

	for(i = 0; i < number_cycles; i++)
	{
		if(i < 20)
			wait .05;
		else if(i < 30)
			wait .1;
		else if(i < 35)
			wait .2;
		else if(i < 38)
			wait .3;

		if(i + 1 < number_cycles)
			rand = treasure_chest_ChooseRandomWeapon(player);
		else
			rand = treasure_chest_ChooseWeightedRandomWeapon(player);
	}

	self.weapon_string = rand;
	chest.chest_box ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);
	wait_network_frame();
	floatHeight = 40;
	self.weapon_model = spawn_model(GetWeaponModel(rand), self.origin + (0, 0, floatHeight), self.angles + (0, 90, 0));
	self.weapon_model UseWeaponHideTags(rand);

	if(maps\_zombiemode_weapons::weapon_is_dual_wield(rand))
	{
		self.weapon_model_dw = spawn_model(maps\_zombiemode_weapons::get_left_hand_weapon_model_name(rand), self.weapon_model.origin - (3, 3, 3), self.weapon_model.angles);
		self.weapon_model_dw UseWeaponHideTags(rand);
		self.weapon_model_dw LinkTo(self.weapon_model);
	}

	if(!is_true(chest._box_opened_by_fire_sale) && !(is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]) && run_function(self, level._zombiemode_check_firesale_loc_valid_func)))
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

		if(is_true(chest.no_fly_away))
			chance_of_joker = -1;
		if(isdefined(level._zombiemode_chest_joker_chance_mutator_func))
			chance_of_joker = run_function(level, level._zombiemode_chest_joker_chance_mutator_func, chance_of_joker);

		if(chance_of_joker > random)
		{
			self.weapon_string = undefined;
			self.weapon_model SetModel("zombie_teddybear");
			self.weapon_model.angles = self.angles;

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
		if(rand == "ray_gun_zm")
			level.pulls_since_last_ray_gun = 0;
		if(rand == "tesla_gun_zm")
		{
			level.pulls_since_last_tesla_gun = 0;
			level.player_seen_tesla_gun = true;
		}

		if(is_true(repsin))
		{
			if(isdefined(chest.box_hacks["respin_respin"]))
				run_function(self, chest.box_hacks["respin_respin"], chest, player);
		}
		else
		{
			if(isdefined(chest.box_hacks["respin"]))
				run_function(self, chest.box_hacks["respin"], chest, player);
		}

		self.weapon_model thread timer_til_despawn(floatHeight, self.weapon_model_dw);
		self waittill("weapon_grabbed");

		if(!is_true(chest.timedOut))
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

timer_til_despawn(floatHeight, weapon_model_dw)
{
	self endon("kill_weapon_movement");
	self MoveTo(self.origin - (0, 0, floatHeight), 12, 6);
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
	fx_ent = spawn_model("tag_origin", self.origin, self.angles + (90, 0, 0));
	fx_ent LinkTo(self);
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

spawn_magicbox(origin, angles)
{
	if(!isdefined(level._generated_chest_num))
		level._generated_chest_num = 0;

	base_angles = angles + (0, 90, 0);
	forward = AnglesToForward(base_angles);
	right = AnglesToRight(base_angles);
	chest_box = spawn_model("zombie_treasure_box", origin, base_angles);
	chest_rubble = spawn_model("zombie_coast_bearpile", origin +(0, 0, 5.5) + (right * 14.5) + (forward * 18.5), base_angles + (0, 125, 0));
	chest_lid = spawn_model("zombie_treasure_box_lid", origin + (0, 0, 17.5) + (right * 12), base_angles);
	chest_origin = Spawn("script_origin", chest_box.origin);
	chest_origin.angles = chest_box.angles;
	trigger = Spawn("trigger_radius_use", origin + (0, 0, 60), 0, 40, 80);
	trigger.box_hacks = [];
	trigger.zombie_cost = 950;
	trigger.angles = angles;
	trigger.targetname = "treasure_chest_use";
	trigger.script_noteworthy = "generated_chest_00" + level._generated_chest_num;
	trigger.chest_rubble = array(chest_rubble);

	for(i = 0; i < trigger.chest_rubble.size; i++)
	{
		trigger.chest_rubble[i].script_noteworthy = trigger.script_noteworthy + "_rubble";
	}

	trigger.chest_box = chest_box;
	trigger.chest_lid = chest_lid;
	trigger.chest_origin = chest_origin;
	level._generated_chest_num++;
	return trigger;
}