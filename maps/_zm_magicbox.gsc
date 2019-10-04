#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

#using_animtree("zm_magicbox");

init()
{
	flag_init("moving_chest_enabled", false);
	flag_init("moving_chest_now", false);
	flag_init("chest_has_been_used", false);

	level.chest_moves = 0;
	level.chest_accessed = 0;
	level.chest_index = 0;
	level.chests = [];
	level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM = 15;

	set_zombie_var("zombie_magicbox_cost", 950);
	set_zombie_var("zombie_magicbox_firesale_cost", 10);
	set_zombie_var("zombie_magicbox_joker", "zombie_teddybear");

	PrecacheModel("p6_anim_zm_magic_box");
	PrecacheModel("p6_anim_zm_magic_box_fake");
	PrecacheModel(level.zombie_vars["zombie_magicbox_joker"]);
	PrecacheString(&"ZOMBIE_MAGICBOX_BUY");
	PrecacheString(&"ZOMBIE_MAGICBOX_TRADE");

	spawn_magicboxes();
	init_starting_chest_location();
	init_weapon_weighting_funcs();
	maps\_zm_weapons::add_custom_limited_weapon_check(::is_weapon_available_in_magicbox);
}

spawn_magicboxes()
{
	structs = GetStructArray("zm_magicbox", "targetname");
	convert_legacy_magicbox_prefabs();

	if(isdefined(level._zm_extra_magicbox_locations) && level._zm_extra_magicbox_locations.size > 0)
		structs = array_merge(structs, level._zm_extra_magicbox_locations);

	if(isdefined(structs) && structs.size > 0)
	{
		for(i = 0; i < structs.size; i++)
		{
			struct = structs[i];

			if(!isdefined(struct.origin))
				continue;
			if(!struct maps\_zm_gametype::is_zm_scr_ent_valid("magicbox"))
				continue;

			origin = struct.origin;
			angles = (0, 0, 0);

			if(isdefined(struct.angles))
				angles = struct.angles;

			// Player Trigger
			stub = SpawnStruct();
			stub.origin = origin + (AnglesToRight(angles) * -25);
			stub.angles = angles;
			stub.radius = 50;
			stub.height = 50;
			stub.script_noteworthy = struct.script_noteworthy;
			stub.start_exclude = struct.start_exclude;
			stub.spawn_struct = struct;
			stub.prompt_and_visibility_func = ::playertrigger_magicbox_update_trigger;
			stub.box_hacks = [];

			// Model
			if(isdefined(struct.model_override))
			{
				stub.chest = struct.model_override;
				stub.chest SetModel("p6_anim_zm_magic_box");
			}
			else
				stub.chest = spawn_model("p6_anim_zm_magic_box", origin, angles);

			stub.chest UseAnimTree(#animtree);

			// Rubble
			stub.rubble = spawn_model("p6_anim_zm_magic_box_fake", stub.chest.origin, stub.chest.angles);
			stub.rubble UseAnimTree(#animtree);

			register_playertrigger(stub, ::playertrigger_magicbox_think);
			level.chests[level.chests.size] = stub;
			stub thread treasure_chest_think();
		}
	}
}

convert_legacy_magicbox_prefabs()
{
	triggers = GetEntArray("treasure_chest_use", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		lid = GetEnt(triggers[i].target, "targetname");
		chest_origin = GetEnt(lid.target, "targetname");
		box = GetEnt(chest_origin.target, "targetname");
		ents = GetEntArray(triggers[i].script_noteworthy + "_rubble", "script_noteworthy");

		for(j = 0; j < ents.size; j++)
		{
			if(DistanceSquared(triggers[i].origin, ents[j].origin) < 10000)
				ents[j] Delete();
		}

		struct = generate_magicbox_location(triggers[i].origin, box.angles);
		struct.model_override = box;
		struct.script_noteworthy = triggers[i].script_noteworthy;
		struct.start_exclude = triggers[i].start_exclude;

		chest_origin Delete();
		lid Delete();
		triggers[i] Delete();
	}
}

generate_magicbox_location(origin, angles)
{
	struct = SpawnStruct();
	struct.origin = origin;
	struct.angles = angles;

	if(!isdefined(level._zm_extra_magicbox_locations))
		level._zm_extra_magicbox_locations = [];

	level._zm_extra_magicbox_locations[level._zm_extra_magicbox_locations.size] = struct;
	return struct;
}

init_starting_chest_location()
{
	level.chests = array_randomize(level.chests);
	start_chest_found = false;

	for(i = 0; i < level.chests.size; i++)
	{
		if(is_true(level.random_pandora_box_start))
		{
			if(start_chest_found || is_true(level.chests[i].start_exclude))
				level.chests[i] hide_chest();
			else
			{
				level.chest_index = i;
				level.chests[i].hidden = false;
				level.chests[i] set_magicbox_state("initial");
				start_chest_found = true;
			}
		}
		else
		{
			if(start_chest_found || !isdefined(level.chests[i].script_noteworthy) || !IsSubStr(level.chests[i].script_noteworthy, "start_chest"))
				level.chests[i] hide_chest();
			else
			{
				level.chest_index = i;
				level.chests[i].hidden = false;
				level.chests[i] set_magicbox_state("initial");
				start_chest_found = true;
			}
		}
	}

	if(!start_chest_found)
	{
		level.chest_index = RandomIntRange(0, level.chests.size - 1);
		level.chests[level.chest_index].hidden = false;
		level.chests[level.chest_index] set_magicbox_state("initial");
	}

	level.chests[level.chest_index] thread default_pandora_show_func();
}

unregister_playertrigger_on_kill_think()
{
	self notify("unregister_playertrigger_on_kill_think");
	self endon("unregister_playertrigger_on_kill_think");
	self waittill("kill_chest_think");
	unregister_playertrigger(self);
}

treasure_chest_get_cost()
{
	if(is_true(self._box_opened_by_fire_sale) || (firesale_active() && self firesale_chest_valid()))
		return level.zombie_vars["zombie_magicbox_firesale_cost"];
	return level.zombie_vars["zombie_magicbox_cost"];
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
		if(isdefined(self.forced_user))
			user = self.forced_user;
		else
			self waittill("trigger", user);

		cost = self treasure_chest_get_cost();

		if(is_true(self.auto_open) || user can_player_purchase(cost))
		{
			if(!isdefined(self.no_charge))
			{
				user maps\_zombiemode_score::minus_to_player_score(cost);
				user_cost = cost;
			}
			self.chest_user = user;
			break;
		}
		else
			user maps\_zombiemode_audio::create_and_play_dialog("general", undefined, 2);
	}

	flag_set("chest_has_been_used");
	self._box_open = true;
	self._box_opened_by_fire_sale = self chest_opened_by_firesale();

	play_sound_at_pos("open_chest", self.chest.origin);
	play_sound_at_pos("music_chest", self.chest.origin);
	self thread set_magicbox_state("open");
	self.timedOut = false;
	self.weapon_out = true;
	self thread treasure_chest_weapon_spawn(user);
	self thread treasure_chest_glowfx();
	unregister_playertrigger(self);
	self waittill("randomization_done");

	if(flag("moving_chest_now") && !self._box_opened_by_fire_sale && isdefined(user_cost))
		user maps\_zombiemode_score::add_to_player_score(user_cost);

	if(flag("moving_chest_now") && !firesale_active() && !self._box_opened_by_fire_sale)
		self thread treasure_chest_move(user);
	else
	{
		self.grab_weapon_hint = true;
		self.grab_weapon_name = self.weapon_string;
		register_playertrigger(self, ::playertrigger_magicbox_think);
		self thread treasure_chest_timeout();

		for(;;)
		{
			self waittill("trigger", grabber);

			if(grabber != level && is_true(self.box_rerespun))
				user = grabber;

			if(grabber == user || grabber == level)
			{
				self.box_rerespun = undefined;

				if(grabber == user)
				{
					self notify("user_grabbed_weapon");
					vo_weapon = user maps\_zm_weapons::weapon_give(self.weapon_string);
					user thread maps\_zm_weapons::play_weapon_vo(vo_weapon);
				}
				else
					self.timedOut = true;
				break;
			}
		}

		self.grab_weapon_hint = false;
		self notify("weapon_grabbed");

		if(!is_true(self._box_opened_by_fire_sale))
			level.chest_accessed++;

		weapon_weighting_on_box_pull();
		unregister_playertrigger(self);
		play_sound_at_pos("close_chest", self.chest.origin);
		self thread set_magicbox_state("close");
		self waittill("closed");
		wait 1;

		if((firesale_active() && self firesale_chest_valid()) || self == level.chests[level.chest_index])
			register_playertrigger(self, ::playertrigger_magicbox_think);
	}

	self._box_open = false;
	self._box_opened_by_fire_sale = false;
	self.chest_user = undefined;
	self thread treasure_chest_think();
}

default_box_move_logic()
{
	level.chest_index++;

	if(level.chest_index >= level.chests.size)
	{
		temp_chest_name = level.chests[level.chest_index - 1].script_noteworthy;
		level.chest_index = 0;
		level.chests = array_randomize(level.chests);

		if(temp_chest_name == level.chests[level.chest_index].script_noteworthy)
			level.chest_index++;
	}
}

treasure_chest_move(player)
{
	level waittill("weapon_fly_away_start");
	play_crazi_sound();
	level waittill("weapon_fly_away_end");
	self hide_chest(true);
	wait .1;
	post_selection_wait_duration = 7;

	if(isdefined(player))
		player maps\_zombiemode_audio::create_and_play_dialog("general", "box_move");

	if(firesale_active() && self firesale_chest_valid())
	{
		self thread firesale_fix();

		while(firesale_active())
		{
			wait .1;
		}
	}
	else
		post_selection_wait_duration += 5;

	if(isdefined(level._zombiemode_custom_box_move_logic))
		run_function(level, level._zombiemode_custom_box_move_logic);
	else
		default_box_move_logic();

	new_loc = level.chests[level.chest_index];

	if(isdefined(new_loc.box_hacks["summon_box"]))
		run_function(new_loc, new_loc.box_hacks["summon_box"], false);

	wait post_selection_wait_duration;
	PlayFX(level._effect["poltergeist"], new_loc.chest.origin);
	new_loc show_chest();
	flag_clear("moving_chest_now");
	self.chest_moving = false;
}

treasure_chest_timeout()
{
	self endon("user_grabbed_weapon");
	self endon("box_hacked_respin");
	self endon("box_hacked_rerespin");
	wait 12;
	self notify("trigger", level);
}

treasure_chest_canPlayerReceiveWeapon(player, weapon)
{
	weapon_stats = maps\_zm_weapons::get_weapon_stats(weapon);

	if(!weapon_stats.in_box)
		return false;
	if(isdefined(player) && player maps\_zm_weapons::has_any_weapon_variant(weapon))
		return false;
	if(!maps\_zm_weapons::limited_weapon_below_quota(weapon, player))
		return false;
	if(isdefined(player) && isdefined(level.special_weapon_magicbox_check))
		return run_function(player, level.special_weapon_magicbox_check, weapon);
	return true;
}

treasure_chest_chooseWeightedRandomWeapon(player)
{
	weapons = get_weighted_weapons_list(player);
	return random(weapons);
}

clean_up_hacked_box()
{
	self waittill("box_hacked_respin");
	self.weapon_model maps\_zm_weapons::delete_weapon_model();
	self.weapon_model = undefined;
}

treasure_chest_weapon_spawn(player, respin)
{
	self endon("box_hacked_respin");
	self thread clean_up_hacked_box();
	self.weapon_string = undefined;
	self.chest SetClientFlag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);
	wait 4;
	self.chest ClearClientFlag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM);
	rand = treasure_chest_chooseWeightedRandomWeapon(player);
	self.weapon_string = rand;
	wait_network_frame();
	self.weapon_model = maps\_zm_weapons::spawn_weapon_model(rand, self.chest.origin + (0, 0, 43), self.chest.angles + (0, 180, 0), player);

	if(!is_true(self._box_opened_by_fire_sale) && !(firesale_active() && self firesale_chest_valid()))
	{
		random = RandomInt(100);

		if(level.chest_accessed < 4)
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

				if(level.chest_accessed >= 13)
				{
					if(random < 50)
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

		/#
		if(GetDvar("scr_zm_magicbox_joker") == "1")
			chance_of_joker = 100;
		#/

		if(chance_of_joker > random)
		{
			self.weapon_string = undefined;
			self.weapon_model maps\_zm_weapons::model_hide_weapon(); // hide lh model if any
			self.weapon_model.angles -= (0, 90, 0);
			self.weapon_model SetModel(level.zombie_vars["zombie_magicbox_joker"]);
			self.weapon_model Show();
			self.chest_moving = true;
			flag_set("moving_chest_now");
			level.chest_accessed = 0;
			level.chest_moves++;
		}
	}

	self notify("randomization_done");

	if(flag("moving_chest_now") && !(firesale_active() && self firesale_chest_valid()))
	{
		wait .05;
		level notify("weapon_fly_away_start");
		wait 2;
		self.weapon_model MoveZ(500, 4, 3);
		self.weapon_model waittill("movedone");
		self.weapon_model maps\_zm_weapons::delete_weapon_model();
		self notify("box_moving");
		level notify("weapon_fly_away_end");
	}
	else
	{
		weapon_weighting_on_box_weapon(rand);

		if(!isdefined(respin))
		{
			if(isdefined(self.box_hacks["respin"]))
				run_function(self, self.box_hacks["respin"], player);
		}
		else
		{
			if(isdefined(self.box_hacks["respin_respin"]))
				run_function(self, self.box_hacks["respin_respin"], player);
		}

		self.weapon_model thread timer_til_despawn();
		self waittill("weapon_grabbed");

		if(!self.timedOut)
			self.weapon_model maps\_zm_weapons::delete_weapon_model();
	}
	self.weapon_string = undefined;
}

timer_til_despawn()
{
	self endon("death");
	self endon("kill_weapon_movement");
	self MoveTo(self.origin - (0, 0, 43), 12, 6);
	wait 12;
	self maps\_zm_weapons::delete_weapon_model();
}

treasure_chest_glowfx()
{
	ent = spawn_model("tag_origin", self.chest.origin, self.chest.angles + (90, 90, 0));
	ent LinkTo(self.chest);
	PlayFXOnTag(level._effect["chest_light"], ent, "tag_origin");
	self waittill_either("weapon_grabbed", "box_moving");
	ent Unlink();
	ent Delete();
}

default_pandora_show_func()
{
	if(!isdefined(self.pandora_light))
	{
		self.pandora_light = spawn_model("tag_origin", self.chest.origin, self.chest.angles + (-90, 90, 0));
		self.pandora_light LinkTo(self.chest);
		PlayFXOnTag(level._effect["lght_marker"], self.pandora_light, "tag_origin");
	}
	PlayFX(level._effect["lght_marker_flare"], self.pandora_light.origin);
}

is_weapon_available_in_magicbox(weapon_name, ignore_player)
{
	count = 0;

	for(i = 0; i < level.chests.size; i++)
	{
		chest = level.chests[i];

		if(isdefined(ignore_player))
		{
			if(isdefined(chest.forced_user) && chest.forced_user != ignore_player)
				continue;
			if(isdefined(chest.chest_user) && chest.chest_user != ignore_player)
				continue;
		}

		if(isdefined(chest.grab_weapon_name) && chest.grab_weapon_name == weapon_name)
			count++;
		else if(isdefined(chest.weapon_string) && chest.weapon_string == weapon_name)
			count++;
	}

	return count;
}

// FireSale Helpers
firesale_active()
{
	return is_true(level.zombie_vars["zombie_powerup_fire_sale_on"]);
}

firesale_chest_valid()
{
	if(isdefined(level._zombiemode_check_firesale_loc_valid_func))
		return run_function(self, level._zombiemode_check_firesale_loc_valid_func);
	return true;
}

chest_opened_by_firesale()
{
	if(!firesale_active())
		return false;
	if(is_true(self.auto_open))
		return false;
	return self firesale_chest_valid();
}

firesale_fix()
{
	if(firesale_active())
	{
		self thread show_chest();
		wait_network_frame();
		level waittill("fire_sale_off");

		while(is_true(self._box_open))
		{
			wait .05;
		}

		self thread hide_chest();
	}
}

// Player Trigger
playertrigger_magicbox_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);
		self.stub notify("trigger", player);
	}
}

playertrigger_magicbox_update_trigger(player)
{
	self SetCursorHint("HINT_NOICON");
	can_use = self playertrigger_magicbox_update_stub(player);

	if(isdefined(self.hint_string))
	{
		if(isdefined(self.hint_param1))
			self SetHintString(self.hint_string, self.hint_param1);
		else
			self SetHintString(self.hint_string);
	}

	return true;
}

playertrigger_magicbox_update_stub(player)
{
	if(!self trigger_visible_to_player(player))
		return false;

	if(is_true(self.stub.grab_weapon_hint))
	{
		weapon_stats = maps\_zm_weapons::get_weapon_stats(self.stub.grab_weapon_name);
		self.hint_string = &"ZOMBIE_MAGICBOX_TRADE";
		self.hint_param1 = weapon_stats.display_name;
	}
	else
	{
		self.hint_string = &"ZOMBIE_MAGICBOX_BUY";
		self.hint_param1 = self.stub treasure_chest_get_cost();
	}

	return true;
}

trigger_visible_to_player(player)
{
	self SetInvisibleToPlayer(player);

	if(isdefined(self.stub.chest_user) && !is_true(self.stub.box_rerespun))
	{
		if(player != self.stub.chest_user || !player can_buy_weapon())
			return false;
	}
	else
	{
		if(!player can_buy_weapon())
			return false;
	}

	self SetVisibleToPlayer(player);
	return true;
}

// Utils
show_chest(dont_enable_trigger)
{
	self thread set_magicbox_state("arriving");
	self waittill("arrived");
	self thread default_pandora_show_func();

	if(!is_true(dont_enable_trigger))
		register_playertrigger(self, ::playertrigger_magicbox_think);

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
	{
		self.pandora_light Unlink();
		self.pandora_light Delete();
		self.pandora_light = undefined;
	}

	self.hidden = true;

	if(isdefined(self.box_hacks["summon_box"]))
		run_function(self, self.box_hacks["summon_box"], true);

	if(is_true(doBoxLeave))
	{
		PlaySoundAtPosition("zmb_box_move", self.chest.origin);
		PlaySoundAtPosition("zmb_box_whoosh", self.chest.origin);
		PlaySoundAtPosition("zmb_vox_ann_magicbox", self.chest.origin);
		self thread set_magicbox_state("leaving");
		self waittill("left");
		self thread set_magicbox_state("away");
		PlayFX(level._effect["poltergeist"], self.chest.origin);
		PlaySoundAtPosition("zmb_box_poof", self.chest.origin);
	}
	else
		self thread set_magicbox_state("away");
}

// States
magicbox_teddy_twitches()
{
	self endon("magicbox_state_change");

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

magicbox_arrives()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_arrive", %o_zombie_magic_box_arrive, 1, .2, 1);
	self.chest waittillend("box_arrive");
	self notify("arrived");
}

magicbox_leaves()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_leave", %o_zombie_magic_box_leave, 1, .2, 1);
	self.chest waittillend("box_leave");
	self notify("left");
}

magicbox_opens()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_open", %o_zombie_magic_box_open, 1, .2, 1);
	self.chest waittillend("box_open");
	self notify("opened");
}

magicbox_closes()
{
	self.chest ClearAnim(%root, .2);
	self.chest SetFlaggedAnim("box_close", %o_zombie_magic_box_close, 1, .2, 1);
	self.chest waittillend("box_close");
	self notify("closed");
}

set_magicbox_state(state)
{
	self notify("magicbox_state_change");

	switch(state)
	{
		case "away":
			self.chest Hide();
			self.rubble Show();
			self thread magicbox_teddy_twitches();
			self.state = "away";
			break;

		case "arriving":
			self.chest Show();
			self.rubble Hide();
			self thread magicbox_arrives();
			self.state = "arriving";
			break;

		case "initial":
			self.chest Show();
			self.rubble Hide();
			register_playertrigger(self, ::playertrigger_magicbox_think);
			self.state = "initial";
			break;

		case "open":
			self.chest Show();
			self.rubble Hide();
			self thread magicbox_opens();
			self.state = "open";
			break;

		case "close":
			self.chest Show();
			self.rubble Hide();
			self thread magicbox_closes();
			self.state = "close";
			break;

		case "leaving":
			self.chest Show();
			self.rubble Hide();
			self thread magicbox_leaves();
			self.state = "leaving";
			break;
	}
}

// Weapon Weighting
init_weapon_weighting_funcs()
{
	if(isdefined(level._zm_override_weapon_weighting_init_func))
	{
		run_function(level, level._zm_override_weapon_weighting_init_func);
		return;
	}

	level.pulls_since_last_ray_gun = 0;
	level.pulls_since_last_tesla_gun = 0;
	level.player_seen_tesla_gun = false;

	if(get_mapname() == "zombie_cod5_factory")
		add_weapon_weighting_func("ray_gun_zm", ::factory_ray_gun_weighting_func);

	add_weapon_weighting_func("tesla_gun_zm", ::default_tesla_weighting_func);
	add_weapon_weighting_func("zombie_cymbal_monkey", ::default_cymbal_monkey_weighting_func);

	if(isdefined(level._zm_custom_weapon_weighting_init_func))
		run_function(level, level._zm_custom_weapon_weighting_init_func);
}

weapon_weighting_on_box_pull()
{
	if(isdefined(level._zm_override_weapon_weighting_pull_func))
	{
		run_function(level, level._zm_override_weapon_weighting_pull_func);
		return;
	}

	if(maps\_zm_weapons::is_weapon_included("ray_gun_zm") && level.chest_moves > 0)
		level.pulls_since_last_ray_gun++;
	if(maps\_zm_weapons::is_weapon_included("tesla_gun_zm"))
		level.pulls_since_last_tesla_gun++;

	if(isdefined(level._zm_custom_weapon_weighting_pull_func))
		run_function(level, level._zm_custom_weapon_weighting_pull_func);
}

weapon_weighting_on_box_weapon(weapon)
{
	if(isdefined(level._zm_override_weapon_weighting_select_func))
	{
		run_function(level, level._zm_override_weapon_weighting_select_func, weapon);
		return;
	}

	if(maps\_zm_weapons::is_weapon_included(weapon))
	{
		if(weapon == "ray_gun_zm")
			level.pulls_since_last_ray_gun = 0;

		if(weapon == "tesla_gun_zm")
		{
			level.pulls_since_last_tesla_gun = 0;
			level.player_seen_tesla_gun = true;
		}
	}

	if(isdefined(level._zm_custom_weapon_weighting_select_func))
		run_function(level, level._zm_custom_weapon_weighting_select_func, weapon);
}

add_weapon_weighting_func(weapon_name, weighting_func)
{
	if(!isdefined(level.weapon_weighting_funcs))
		level.weapon_weighting_funcs = [];
	if(!isdefined(weighting_func))
		weighting_func = ::default_weapon_weighting_func;

	level.weapon_weighting_funcs[weapon_name] = weighting_func;
}

get_weighted_weapons_list(player)
{
	weapons_list = maps\_zm_weapons::get_weapons_list();
	result = [];

	for(i = 0; i < weapons_list.size; i++)
	{
		weapon_name = weapons_list[i];

		if(!treasure_chest_canPlayerReceiveWeapon(player, weapon_name))
			continue;

		if(isdefined(level.weapon_weighting_funcs) && isdefined(level.weapon_weighting_funcs[weapon_name]))
		{
			num_entries = run_function(level, level.weapon_weighting_funcs[weapon_name]);

			if(isdefined(num_entries) && num_entries > 0)
			{
				for(j = 0; j < num_entries.size; j++)
				{
					result[result.size] = weapon_name;
				}
			}
			else
				result[result.size] = weapon_name;
		}
		else
			result[result.size] = weapon_name;
	}

	return result;
}

default_weapon_weighting_func()
{
	return 1;
}

default_1st_move_weighting_func()
{
	if(level.chest_moves > 0)
		return 1;
	return 0;
}

default_upgrade_weapon_weighting_func()
{
	if(level.chest_moves > 1)
		return 1;
	return 0;
}

default_tesla_weighting_func()
{
	num_to_add = 1;

	if(isdefined(level.pulls_since_last_tesla_gun))
	{
		weapons_list = maps\_zm_weapons::get_weapons_list();

		if(is_true(level.player_drops_tesla_gun))
			num_to_add = Int(.2 * weapons_list.size);

		if(!is_true(level.player_seen_tesla_gun))
		{
			if(level.round_number > 10)
				num_to_add += Int(.2 * weapons_list.size);
			else if(level.round_number > 5)
				num_to_add += Int(.15 * weapons_list.size);
		}
	}
	return num_to_add;
}

default_cymbal_monkey_weighting_func()
{
	players = GetPlayers();
	count = 0;

	for(i = 0; i < players.size; i++)
	{
		if(players[i] maps\_zm_weapons::has_weapon_or_upgrade("zombie_cymbal_monkey"))
			count++;
	}

	if(count > 1)
		return 1;
	if(level.round_number < 10)
		return 3;
	return 5;
}

factory_ray_gun_weighting_func()
{
	if(level.chest_moves > 0)
	{
		num_to_add = 1;

		if(isdefined(level.pulls_since_last_ray_gun))
		{
			weapons_list = maps\_zm_weapons::get_weapons_list();

			if(level.pulls_since_last_ray_gun > 11)
				num_to_add += Int(weapons_list.size * .1);
			else if(level.pulls_since_last_ray_gun)
				num_to_add += Int(.05 * weapons_list.size);
		}
		return num_to_add;
	}
	return 0;
}