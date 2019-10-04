#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

/*
	Perk States
		0 - Unobtained
		1 - Obtained
		2 - Paused
		3 - Unpaused

	Has Perk -> 1 or 3
	Has Perk Paused -> 2
*/

init()
{
	if(!isdefined(level._zm_include_perks))
		level._zm_include_perks = ::default_include_perks;

	run_function(level, level._zm_include_perks);
	precache_perks();
	spawn_perk_machines();
	OnPlayerConnect_Callback(::player_connect);
}

player_connect()
{
	flag_wait("all_players_connected");
	perks = get_valid_perk_array();

	for(i = 0; i < perks.size; i++)
	{
		self SetClientDvars(
			"ui_zm_perk_" + perks[i] + "_x", 0,
			"ui_zm_perk_" + perks[i] + "_image", "",
			"ui_zm_perk_" + perks[i] + "_alpha", 0
		);
	}
}

default_include_perks()
{
	// T4
	maps\perks\_zm_perk_juggernog::include_perk_for_level();
	maps\perks\_zm_perk_double_tap::include_perk_for_level();
	maps\perks\_zm_perk_quick_revive::include_perk_for_level();
	maps\perks\_zm_perk_sleight_of_hand::include_perk_for_level();

	// T5
	maps\perks\_zm_perk_divetonuke::include_perk_for_level();
	maps\perks\_zm_perk_marathon::include_perk_for_level();
	maps\perks\_zm_perk_deadshot::include_perk_for_level();
	maps\perks\_zm_perk_additionalprimaryweapon::include_perk_for_level();

	// T6
	maps\perks\_zm_perk_tombstone::include_perk_for_level();
	maps\perks\_zm_perk_chugabud::include_perk_for_level();
	// maps\perks\_zm_perk_electric_cherry::include_perk_for_level();
	// maps\perks\_zm_perk_vulture_aid::include_perk_for_level();

	// T7
	// maps\perks\_zm_perk_widows_wine::include_perk_for_level();

	// T8
}

precache_perks()
{
	set_zombie_var("zombie_perk_limit", 4);
	set_zombie_var("zombie_perk_cost", 2000);
	set_zombie_var("zombie_perk_hint_string", "Press ^3[{+activate}]^7 to buy perk [Cost: &&1]");

	PrecacheModel("collision_geo_64x64x256");

	if(isdefined(level._custom_perks))
	{
		keys = GetArrayKeys(level._custom_perks);

		for(i = 0; i < keys.size; i++)
		{
			if(isdefined(level._custom_perks[keys[i]].model_off))
				PrecacheModel(level._custom_perks[keys[i]].model_off);
			if(isdefined(level._custom_perks[keys[i]].model_on))
				PrecacheModel(level._custom_perks[keys[i]].model_on);
			if(isdefined(level._custom_perks[keys[i]].bottle))
				PrecacheItem(level._custom_perks[keys[i]].bottle);
			if(isdefined(level._custom_perks[keys[i]].shader))
				PrecacheShader(level._custom_perks[keys[i]].shader);
			if(isdefined(level._custom_perks[keys[i]].hint_string))
				PrecacheString(level._custom_perks[keys[i]].hint_string);
		}
	}
}

// Power
perk_power_on()
{
	playertrigger = self.playertrigger;
	perk = playertrigger.script_noteworthy;
	machine = playertrigger.machine;

	if(is_true(playertrigger.can_notify_power))
		level notify(perk + "_on");

	if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].model_on))
		machine SetModel(level._custom_perks[perk].model_on);

	machine Vibrate((0, -100, 0), .3, .4, 3);
	machine PlaySound("zmb_perks_power_on");
	machine thread perk_fx(perk);
	machine thread play_loop_on_machine();

	if(is_true(playertrigger.can_notify_power))
	{
		level notify(perk + "_power_on");

		// support legacy power notifies
		if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].specialty))
			level notify(level._custom_perks[perk].specialty + "_power_on");
	}

	playertrigger.power_on = true;
}

perk_power_off()
{
	playertrigger = self.playertrigger;
	perk = playertrigger.script_noteworthy;
	machine = playertrigger.machine;

	if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].model_off))
		machine SetModel(level._custom_perks[perk].model_off);

	machine notify("stop_loop_sound");
	machine notify("stop_light_fx");

	if(is_true(playertrigger.can_notify_power))
		level notify(perk + "_off");

	playertrigger.power_on = false;
}

// Machines
spawn_perk_machines()
{
	if(!isdefined(level._custom_perks))
		return;

	level._zm_perk_machines = [];
	structs = GetStructArray("zm_perk_machine", "targetname");
	convert_legacy_perk_prefabs();

	if(isdefined(level._zm_extra_perk_machines) && level._zm_extra_perk_machines.size > 0)
		structs = array_merge(structs, level._zm_extra_perk_machines);

	perk_counts = [];

	if(isdefined(structs) && structs.size > 0)
	{
		for(i = 0; i < structs.size; i++)
		{
			struct = structs[i];

			if(!isdefined(struct.origin))
				continue;
			if(!struct maps\_zm_gametype::is_zm_scr_ent_valid("perks"))
				continue;

			origin = struct.origin;
			perk = struct.script_noteworthy;
			angles = (0, 0, 0);
			model = "zombie_vending_jugg";

			if(!isdefined(level._custom_perks[perk]))
				continue;
			if(!isdefined(perk_counts[perk]))
				perk_counts[perk] = 0;
			if(!isdefined(level._zm_perk_machines[perk]))
				level._zm_perk_machines[perk] = [];
			if(isdefined(struct.angles))
				angles = struct.angles;
			if(isdefined(struct.model))
				model = struct.model;
			if(isdefined(level._custom_perks[perk].model_off))
				model = level._custom_perks[perk].model_off;

			// Player Trigger
			stub = SpawnStruct();
			stub.origin = origin + (0, 0, 60);
			stub.script_noteworthy = perk;
			stub.angles = angles;
			stub.radius = 40;
			stub.height = 80;
			stub.spawn_struct = struct;
			stub.prompt_and_visibility_func = ::playertrigger_perk_update_trigger;
			stub.can_notify_power = perk_counts[perk] == 0;

			// Powerable
			stub.powerable_stub = maps\_zm_power::add_powerable(::perk_power_on, ::perk_power_off);
			stub.powerable_stub.playertrigger = stub;

			// Machine Model
			if(isdefined(struct.machine_override))
				stub.machine = struct.machine_override;
			else
				stub.machine = spawn_model(model, origin, angles);

			stub.machine SetModel(model);

			// Collision Model
			if(isdefined(struct.clip_override))
				stub.clip = struct.clip_override;
			else
			{
				stub.clip = Spawn("script_model", origin, 1);
				stub.clip.angles = angles;
				stub.clip SetModel("collision_geo_64x64x256");
				stub.clip DisconnectPaths();
				stub.clip Hide();
			}

			// Audio Bump Trigger
			stub.bump = Spawn("trigger_radius", origin + (0, 0, 20), 0, 40, 80);
			stub.bump.angles = angles;
			stub.bump.script_activated = 1;
			stub.bump.script_sound = "zmb_perks_bump_bottle";
			stub.bump.targetname = "audio_bump_trigger";

			register_playertrigger(stub, ::playertrigger_perk_think);
			perk_counts[perk]++;

			// Always powered on perk machines
			// AKA - Solo Quick Revive
			if(is_true(level._custom_perks[perk].ignore_power))
			{
				stub.powerable_stub.can_power_off = false;
				stub.powerable_stub maps\_zm_power::powerable_power_on();
			}

			level._zm_perk_machines[perk][level._zm_perk_machines[perk].size] = stub;
		}
	}
}

playertrigger_perk_update_trigger(player)
{
	self SetCursorHint("HINT_NOICON");
	can_use = self playertrigger_perk_update_stub(player);

	if(isdefined(self.hint_string))
	{
		if(isdefined(self.hint_param))
			self SetHintString(self.hint_string, self.hint_param);
		else
			self SetHintString(self.hint_string);
	}

	return can_use;
}

playertrigger_perk_update_stub(player)
{
	if(is_true(self.stub.power_on))
	{
		if(player has_perk(self.stub.script_noteworthy))
			return false;

		self.hint_string = get_perk_hint_string(self.stub.script_noteworthy);
		self.hint_param = get_perk_cost(self.stub.script_noteworthy);
		return true;
	}
	else
	{
		self.hint_string = &"ZOMBIE_NEED_POWER";
		return false;
	}
}

playertrigger_perk_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);

		perk = self.stub.script_noteworthy;
		cost = get_perk_cost(perk);

		if(!is_true(self.stub.power_on))
			continue;

		if(!self vending_trigger_can_player_use(player))
		{
			wait .1;
			continue;
		}

		if(player has_perk(perk) || player has_perk_paused(perk))
		{
			self.stub.machine PlaySound("evt_perk_deny");
			player maps\_zombiemode_audio::create_and_play_dialog("general", "sigh");
			continue;
		}

		if(!player can_player_purchase(cost))
		{
			self.stub.machine PlaySound("evt_perk_deny");
			player maps\_zombiemode_audio::create_and_play_dialog("general", "outofmoney");
			continue;
		}

		if(!player can_player_purchase_perk())
		{
			self.stub.machine PlaySound("evt_perk_deny");
			player maps\_zombiemode_audio::create_and_play_dialog("general", "sigh");
			continue;
		}

		player thread vending_trigger_post_think(self.stub);
	}
}

convert_legacy_perk_prefabs()
{
	triggers = GetEntArray("zombie_vending", "targetname");
	keys = undefined;

	if(isdefined(level._custom_perks))
		keys = GetArrayKeys(level._custom_perks);

	for(i = 0; i < triggers.size; i++)
	{
		perk = triggers[i].script_noteworthy;
		origin = triggers[i].origin;
		angles = triggers[i].angles;
		machine = undefined;
		clip = undefined;

		if(isdefined(triggers[i].target))
		{
			targets = GetEntArray(triggers[i].target, "targetname");

			for(j = 0; j < targets.size; j++)
			{
				if(targets[j].classname == "script_model")
				{
					if(!isdefined(machine))
						machine = targets[j];
				}
				else if(isdefined(targets[j].script_noteworthy) && targets[j].script_noteworthy == "clip")
				{
					if(!isdefined(clip))
						clip = targets[j];
				}
				else
					targets[j] Delete();
			}
		}

		triggers[i] Delete();

		if(isdefined(keys))
		{
			for(j = 0; j < keys.size; j++)
			{
				if(isdefined(level._custom_perks[keys[j]].specialty) && perk == level._custom_perks[keys[j]].specialty)
				{
					perk = keys[j];

					struct = generate_machine_location(perk, origin, angles);
					struct.machine_override = machine;
					struct.clip_override = clip;
					break;
				}
			}
		}
	}
}

vending_trigger_post_think(stub)
{
	perk = stub.script_noteworthy;
	cost = get_perk_cost(perk);
	origin = stub maps\_zm_trigger_per_player::playertrigger_origin();

	PlaySoundAtPosition("evt_bottle_dispense", origin);
	self maps\_zombiemode_score::minus_to_player_score(cost);
	self.perk_purchased = perk;
	self notify("perk_purchased", perk);
	// TODO: Play Sting

	self thread drink_from_perk_bottle(perk);
	result = self waittill_any_return("perk_abort_drinking", "perk_drink_complete", "perk_drink_failed");
	self.perk_purchased = undefined;

	if(result == "perk_abort_drinking" || result == "perk_drink_failed")
		return;
	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	self give_perk(perk, true);
}

vending_trigger_can_player_use(player)
{
	if(player maps\_laststand::player_is_in_laststand() || is_true(player.intermission))
		return false;
	if(player in_revive_trigger())
		return false;
	if(!player can_buy_weapon())
		return false;
	if(player IsThrowingGrenade())
		return false;
	if(player IsSwitchingWeapons())
		return false;
	if(player is_drinking())
		return false;
	return true;
}

perk_fx(perk)
{
	fx_name = undefined;

	if(isdefined(level._custom_perks[perk].light_fx))
		fx_name = level._custom_perks[perk].light_fx;
	if(!isdefined(fx_name))
		return;
	if(!isdefined(level._effect[fx_name]))
		return;

	wait 3;

	ent = spawn_model("tag_origin", self.origin, self.angles);
	ent LinkTo(self);
	PlayFXOnTag(level._effect[fx_name], ent, "tag_origin");
	self waittill("stop_light_fx");
	ent Unlink();
	ent Delete();
}

play_loop_on_machine()
{
	ent = Spawn("script_origin", self.origin);
	ent PlayLoopSound("zmb_perks_machine_loop");
	ent LinkTo(self);
	self waittill("stop_loop_sound");
	ent Unlink();
	ent Delete();
}

delete_perk_machines(perk, do_anim)
{
	if(!isdefined(level._zm_perk_machines))
		return;
	if(!isdefined(level._zm_perk_machines[perk]) || level._zm_perk_machines[perk].size == 0)
		return;

	array_thread(level._zm_perk_machines[perk], ::delete_perk_machine_core, do_anim);
}

delete_perk_machine_core(do_anim)
{
	perk = self.script_noteworthy;
	machine = self.machine;

	unregister_playertrigger(self);
	maps\_zm_power::remove_powerable(self.powerable_stub);
	machine notify("stop_loop_sound");
	machine notify("stop_light_fx");

	if(is_true(do_anim))
	{
		machine PlaySound("zmb_box_move");
		machine PlaySound("zmb_whoosh");
		machine MoveTo(machine.origin + (0, 0, 40), 3);

		if(isdefined(level.custom_vibrate_func))
			run_function(machine, level.custom_vibrate_func, machine);
		else
		{
			dir = machine.origin;
			dir = (dir[1], dir[0], 0);

			if(dir[1] < 0 || (dir[0] > 0 && dir[1] > 0))
				dir = (dir[0], dir[1] * -1, 0);
			else if(dir[0] < 0)
				dir = (dir[0] * -1, dir[1], 0);

			machine Vibrate(dir, 10, .5, 5);
		}

		machine waittill("moveddone");
		PlayFX(level._effect["poltergeist"], machine.origin);
		machine PlaySound("zmb_box_poof");
	}

	if(isdefined(self.clip))
	{
		self.clip ConnectPaths();
		self.clip Delete();
	}

	if(isdefined(self.bump))
		self.bump Delete();

	machine Delete();
}

// HUD
perk_hud_create(perk)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(isdefined(self.perk_hud[perk]))
		return;

	shader = "";

	if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].shader))
		shader = level._custom_perks[perk].shader;

	self.perk_hud[perk] = self.perk_hud.size * 30;

	self SetClientDvars(
		"ui_zm_perk_" + perk + "_x", self.perk_hud[perk],
		"ui_zm_perk_" + perk + "_image", shader,
		"ui_zm_perk_" + perk + "_alpha", 1
	);

	// hud = create_simple_hud(self);
	// hud.foreground = true;
	// hud.sort = 1;
	// hud.hidewheninmenu = false;
	// hud.alignX = "left";
	// hud.alignY = "bottom";
	// hud.horzAlign = "user_left";
	// hud.vertAlign = "user_bottom";
	// hud.x = self.perk_hud.size * 30;
	// hud.y = hud.y - 70;
	// hud.alpha = 1;
	// hud SetShader(shader, 24, 24);

	// self.perk_hud[perk] = hud;
}

perk_hud_destroy(perk)
{
	if(!isdefined(self.perk_hud))
		return;
	if(!isdefined(self.perk_hud[perk]))
		return;

	self.perk_hud[perk] = undefined;

	self SetClientDvars(
		"ui_zm_perk_" + perk + "_x", 0,
		"ui_zm_perk_" + perk + "_image", "",
		"ui_zm_perk_" + perk + "_alpha", 0
	);

	// self.perk_hud[perk] destroy_hud();
	// self.perk_hud[perk] = undefined;
}

perk_hud_grey(perk, on_off)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(!isdefined(self.perk_hud[perk]))
		return;

	if(is_true(on_off))
	{
		// if(self.perk_hud[perk].alpha != .333)
		// {
		// 	self.perk_hud[perk] FadeOverTime(.5);
		// 	self.perk_hud[perk].alpha = .333;
		// }

		self SetClientDvar("ui_zm_perk_" + perk + "_alpha", .33);

	}
	else
	{
		// if(self.perk_hud[perk].alpha != 1)
		// {
		// 	self.perk_hud[perk] FadeOverTime(.5);
		// 	self.perk_hud[perk].alpha = 1;
		// }
		self SetClientDvar("ui_zm_perk_" + perk + "_alpha", 1);
	}
}

update_perk_hud()
{
	if(isdefined(self.perk_hud))
	{
		keys = GetArrayKeys(self.perk_hud);

		for(i = 0; i < keys.size; i++)
		{
			self.perk_hud[keys[i]] = i * 30;
			self SetClientDvar("ui_zm_perk_" + keys[i] + "_x", self.perk_hud[keys[i]]);
		}
	}
}

// Bottle
perk_give_bottle_begin(perk)
{
	self disable_player_move_states();
	self increment_is_drinking();

	gun = self GetCurrentWeapon();
	bottle = get_perk_bottle(perk);

	if(isdefined(bottle))
	{
		self GiveWeapon(bottle);
		self SwitchToWeapon(bottle);
	}
	return gun;
}

perk_give_bottle_end(gun, perk)
{
	self enable_player_move_states();
	bottle = get_perk_bottle(perk);

	if(isdefined(bottle))
		self TakeWeapon(bottle);

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	if(self is_multiple_drinking())
	{
		self decrement_is_drinking();
		return;
	}
	else if(gun != "none" && !is_placeable_mine(gun) && !is_equipment(gun))
	{
		self maps\_zm_weapons::switch_back_primary_weapon(gun);

		if(is_melee_weapon(gun))
		{
			self decrement_is_drinking();
			return;
		}
	}
	else
		self maps\_zm_weapons::switch_back_primary_weapon();

	self waittill("weapon_change_complete");

	if(!self maps\_laststand::player_is_in_laststand() && !is_true(self.intermission))
		self decrement_is_drinking();
}

// Logic
perk_think(perk)
{
	perk_str = perk + "_stop";
	result = self waittill_any_return("fake_death", "death", "player_downed", perk_str);

	if(self should_retain_perk(perk))
	{
		self thread perk_think(perk);
		return;
	}

	self set_player_perk_state(perk, 0);
	self.num_perks--;

	if(isdefined(level._custom_perks[perk].specialty))
		self UnSetPerk(level._custom_perks[perk].specialty);
	if(isdefined(level._custom_perks[perk].thread_take))
		single_thread(self, level._custom_perks[perk].thread_take);

	self perk_hud_destroy(perk);
	self.perk_purchased = undefined;

	if(isdefined(level.perk_lost_func))
		run_function(self, level.perk_lost_func, perk);

	self notify("perk_lost", perk);
}

// Utils
should_retain_perk(perk)
{
	if(isdefined(self._retain_perk_array) && is_true(self._retain_perk_array[perk]))
		return true;
	if(is_true(self._retain_perks))
		return true;
	return false;
}

get_valid_perk_array()
{
	if(isdefined(level._custom_perks))
		return GetArrayKeys(level._custom_perks);
	else
		return [];
}

give_perk_core(perk, bought)
{
	if(self get_player_perk_state(perk) > 0)
		return;

	self set_player_perk_state(perk, 1);
	self.num_perks++;

	if(is_true(bought))
	{
		if(isdefined(level.perk_bought_func))
			run_function(self, level.perk_bought_func, perk);

		self thread maps\_zombiemode_audio::perk_vox(perk);
		self SetBlur(9, .1);
		wait .1;
		self SetBlur(0, .1);
		self notify("perk_bought", perk);
	}

	if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]))
	{
		if(isdefined(level._custom_perks[perk].specialty))
			self SetPerk(level._custom_perks[perk].specialty);
		if(isdefined(level._custom_perks[perk].thread_give))
			single_thread(self, level._custom_perks[perk].thread_give);
	}

	if(!isdefined(self.perk_history))
		self.perk_history = [];
	if(!isdefined(self.perks_active))
		self.perks_active = [];

	self.perk_history[self.perk_history.size] = perk;
	self.perks_active[self.perks_active.size] = perk;
	self perk_hud_create(perk);
	self notify("perk_acquired", perk);
	self.stats["perks"]++;
	self thread perk_think(perk);
}

pause_perk_core(perk)
{
	if(self has_perk_paused(perk))
		return;

	if(self has_perk(perk))
	{
		self set_player_perk_state(perk, 2);

		if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]))
		{
			if(isdefined(level._custom_perks[perk].specialty))
				self UnSetPerk(level._custom_perks[perk].specialty);
			if(isdefined(level._custom_perks[perk].thread_pause))
				single_thread(self, level._custom_perks[perk].thread_pause);
		}

		self perk_hud_grey(perk, true);
		self notify("perk_paused", perk);
	}
}

unpause_perk_core(perk)
{
	if(self has_perk(perk))
		return;

	if(self has_perk_paused(perk))
	{
		self set_player_perk_state(perk, 3);

		if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]))
		{
			if(isdefined(level._custom_perks[perk].specialty))
				self SetPerk(level._custom_perks[perk].specialty);
			if(isdefined(level._custom_perks[perk].thread_unpause))
				single_thread(self, level._custom_perks[perk].thread_unpause);
		}

		self perk_hud_grey(perk, false);
		self notify("perk_unpaused", perk);
		self set_player_max_health(false, false);
	}
}

drink_from_perk_bottle(perk)
{
	gun = self perk_give_bottle_begin(perk);
	result = self waittill_any_return("fake_death", "death", "player_downed", "weapon_change_complete", "perk_abort_drinking", "disconnect");
	self perk_give_bottle_end(gun, perk);
	self notify("burp");

	if(result == "weapon_change_complete")
		self notify("perk_drink_complete");
	else
		self notify("perk_drink_failed");
}

get_player_perk_state(perk)
{
	if(!isdefined(self._zm_perks))
		self._zm_perks = [];
	if(!isdefined(self._zm_perks[perk]))
		self._zm_perks[perk] = 0;
	return self._zm_perks[perk];
}

set_player_perk_state(perk, state)
{
	old_state = self get_player_perk_state(perk);
	new_state = state;

	if(new_state != old_state)
	{
		set_client_system_state("_zm_perks", perk + "," + new_state, self);
		self notify("perk_state_changed", perk, old_state, new_state);
	}

	self._zm_perks[perk] = new_state;
}

generate_machine_location(perk, origin, angles)
{
	struct = SpawnStruct();
	struct.origin = origin;
	struct.angles = angles;
	struct.script_noteworthy = perk;

	if(!isdefined(level._zm_extra_perk_machines))
		level._zm_extra_perk_machines = [];

	level._zm_extra_perk_machines[level._zm_extra_perk_machines.size] = struct;
	return struct;
}

get_perk_bottle(perk)
{
	if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].bottle))
		return level._custom_perks[perk].bottle;
	return undefined;
}

get_perk_cost(perk)
{
	if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].cost))
	{
		if(IsInt(level._custom_perks[perk].cost))
			return level._custom_perks[perk].cost;
		else
			return run_function(level, level._custom_perks[perk].cost);
	}
	return level.zombie_vars["zombie_perk_cost"];
}

get_perk_hint_string(perk)
{
	if(isdefined(level._custom_perks) && isdefined(level._custom_perks[perk]) && isdefined(level._custom_perks[perk].hint_string))
		return level._custom_perks[perk].hint_string;
	return level.zombie_vars["zombie_perk_hint_string"];
}

// Registry
_register_undefined_perk(perk)
{
	if(!isdefined(level._custom_perks))
		level._custom_perks = [];
	if(isdefined(level._custom_perks[perk]))
		return;

	level._custom_perks[perk] = SpawnStruct();
}

register_perk(perk, shader, bottle)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].shader = shader;
	level._custom_perks[perk].bottle = bottle;
}

register_perk_specialty(perk, specialty)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].specialty = specialty;
}

register_perk_machine(perk, cost, hint_string, model_off, model_on, light_fx, sting, jingle)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].cost = cost;
	level._custom_perks[perk].hint_string = hint_string;
	level._custom_perks[perk].model_off = model_off;
	level._custom_perks[perk].model_on = model_on;
	level._custom_perks[perk].light_fx = light_fx;
	level._custom_perks[perk].sting = sting;
	level._custom_perks[perk].jingle = jingle;
}

register_perk_threads(perk, thread_give, thread_take, thread_pause, thread_unpause)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].thread_give = thread_give;
	level._custom_perks[perk].thread_take = thread_take;
	level._custom_perks[perk].thread_pause = thread_pause;
	level._custom_perks[perk].thread_unpause = thread_unpause;
}

register_perk_flash_audio(perk, flash_sound)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].flash_sound = flash_sound;
}

set_perk_ignore_power(perk)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].ignore_power = true;
}