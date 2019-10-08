#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	include_perks();
	precache_perks();
	spawn_perk_machines();
	OnPlayerConnect_Callback(::player_connect);
}

player_connect()
{
	self.num_perks = 0;
	self._obtained_perks = [];

	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
	{
		perks = get_valid_perks_array();

		for(i = 0; i < perks.size; i++)
		{
			self SetClientDvars(
				"ui_zm_perk_" + perks[i] + "_x", 0,
				"ui_zm_perk_" + perks[i] + "_image", level._custom_perks[perks[i]].shader,
				"ui_zm_perk_" + perks[i] + "_alpha", 0
			);
		}
	}
}

include_perks()
{
	if(!isdefined(level._zm_perk_includes))
		level._zm_perk_includes = ::default_include_perks;

	set_zombie_var("zombie_perk_cost", 2000);
	set_zombie_var("zombie_perk_bottle", "zombie_perk_bottle");
	set_zombie_var("zombie_perk_hint", &"ZOMBIE_PERK_GENERIC");
	set_zombie_var("zombie_perk_limit", 4);
	set_zombie_var("zombie_perk_use_menu_hud", true);
	set_zombie_var("zombie_perk_collision_model", "collision_geo_64x64x256");

	run_function(level, level._zm_perk_includes);
}

default_include_perks()
{
	maps\apex\perks\_zm_perk_juggernog::include_perk_for_level();
	maps\apex\perks\_zm_perk_double_tap::include_perk_for_level();
	maps\apex\perks\_zm_perk_sleight_of_hand::include_perk_for_level();
	maps\apex\perks\_zm_perk_quick_revive::include_perk_for_level();

	maps\apex\perks\_zm_perk_divetonuke::include_perk_for_level();
	maps\apex\perks\_zm_perk_marathon::include_perk_for_level();
	maps\apex\perks\_zm_perk_deadshot::include_perk_for_level();
	maps\apex\perks\_zm_perk_additionalprimaryweapon::include_perk_for_level();

	// maps\apex\perks\_zm_perk_tombstone::include_perk_for_level();
	// maps\apex\perks\_zm_perk_chugabud::include_perk_for_level();
	// maps\apex\perks\_zm_perk_electric_cherry::include_perk_for_level();
	// maps\apex\perks\_zm_perk_vulture::include_perk_for_level();

	// maps\apex\perks\_zm_perk_widows_wine::include_perk_for_level();
}

precache_perks()
{
	perks = get_valid_perks_array();
	PrecacheItem(level.zombie_vars["zombie_perk_bottle"]);
	PrecacheString(level.zombie_vars["zombie_perk_hint"]);
	PrecacheModel(level.zombie_vars["zombie_perk_collision_model"]);

	level._effect["perk_light_yellow"]= LoadFX("misc/fx_zombie_cola_dtap_on");
	level._effect["perk_light_red"]= LoadFX("misc/fx_zombie_cola_jugg_on");
	level._effect["perk_light_blue"]= LoadFX("misc/fx_zombie_cola_revive_on");
	level._effect["perk_light_green"]= LoadFX("misc/fx_zombie_cola_on");

	for(i = 0; i < perks.size; i++)
	{
		PrecacheShader(level._custom_perks[perks[i]].shader);

		if(isdefined(level._custom_perks[perks[i]].hint))
			PrecacheString(level._custom_perks[perks[i]].hint);
		if(isdefined(level._custom_perks[perks[i]].bottle))
			PrecacheItem(level._custom_perks[perks[i]].bottle);
		if(isdefined(level._custom_perks[perks[i]].machine_on))
			PrecacheModel(level._custom_perks[perks[i]].machine_on);
		if(isdefined(level._custom_perks[perks[i]].machine_off))
			PrecacheModel(level._custom_perks[perks[i]].machine_off);
	}

	// in debug mode we remove the perk limit
	/# level.zombie_vars["zombie_perk_limit"] = perks.size; #/
}

//============================================================================================
// Power
//============================================================================================
perk_power_think()
{
	for(;;)
	{
		flag_wait("power_on");
		self perk_power_on();
		flag_waitopen("power_on");
		self perk_power_off();
	}
}

perk_power_on()
{
	perk = self.script_noteworthy;

	if(isdefined(level._custom_perks[perk].machine_on))
		self.machine SetModel(level._custom_perks[perk].machine_on);

	self.machine Vibrate((0, -100, 0), .3, .4, 3);
	self.machine PlaySound("zmb_perks_power_on");
	self.machine thread perk_power_effects_think(perk);
	self.power_on = true;
}

perk_power_off()
{
	self.power_on = false;
	perk = self.script_noteworthy;

	if(isdefined(level._custom_perks[perk].machine_off))
		self.machine SetModel(level._custom_perks[perk].machine_off);

	self.machine notify("stop_perk_power_effects");
	self.machine Vibrate((0, -100, 0), .3, .4, 3);
}

perk_power_effects_think(perk)
{
	ent = spawn_model("tag_origin", self.origin, self.angles);
	ent LinkTo(self);
	ent PlayLoopSound("zmb_perks_machine_loop");

	wait 3;

	if(isdefined(level._custom_perks[perk].light_fx))
		PlayFXOnTag(level._effect[level._custom_perks[perk].light_fx], ent, "tag_origin");

	self waittill("stop_perk_power_effects");
	ent StopLoopSound();
	ent Unlink();
	ent Delete();
}

//============================================================================================
// PlayerTrigger / Machines
//============================================================================================
generate_perk_spawn_struct(perk, origin, angles)
{
	struct = SpawnStruct();
	struct.origin = origin;
	struct.script_noteworthy = perk;

	if(isdefined(angles))
		struct.angles = angles + (0, 90, 0);
	else
		struct.angles = (0, 0, 0);

	if(!isdefined(level._generated_perk_machines))
		level._generated_perk_machines = [];
	level._generated_perk_machines[level._generated_perk_machines.size] = struct;
	return struct;
}

spawn_perk_machines()
{
	structs = GetStructArray("zm_perk_machine", "targetname");
	convert_legacy_perk_machines();

	if(isdefined(level._generated_perk_machines))
		structs = array_merge(structs, level._generated_perk_machines);
	if(!isdefined(structs) || structs.size == 0)
		return;

	for(i = 0; i < structs.size; i++)
	{
		struct = structs[i];

		if(!isdefined(struct.origin) || !isdefined(struct.script_noteworthy))
			continue;
		if(!is_perk_valid(struct.script_noteworthy))
			continue;

		origin = struct.origin;
		perk = struct.script_noteworthy;
		angles = struct.angles;
		model = "zombie_vending_jugg";

		if(!isdefined(angles))
			angles = struct.angles;

		// Spawn perk machine
		if(isdefined(struct.machine_override))
		{
			struct.machine = struct.machine_override;
			model = struct.machine.model;
		}
		else
			struct.machine = spawn_model("tag_origin", origin, angles);

		if(isdefined(level._custom_perks[perk].machine_off))
			model = level._custom_perks[perk].machine_off;

		struct.machine.origin = origin;
		struct.machine.angles = angles;
		struct.machine SetModel(model);

		// Spawn perk collision
		if(isdefined(struct.clip_override))
			struct.clip = struct.clip_override;
		else
			struct.clip = Spawn("script_model", origin, 1);

		struct.clip.origin = origin;
		struct.clip.angles = angles;
		struct.clip DisconnectPaths();
		struct.clip Hide();

		if(struct.clip.classname == "script_model")
			struct.clip SetModel(level.zombie_vars["zombie_perk_collision_model"]);

		// Spawn perk bump trigger
		struct.bump = Spawn("trigger_radius", origin, 0, 40, 50);
		struct.bump.angles = angles;
		struct.bump thread perk_audio_bump_trigger_think();

		// power
		struct thread perk_power_think();

		// Setup spawn struct as a playertrigger stub
		struct.origin = origin + (0, 0, 60);
		struct.radius = 40;
		struct.height = 80;
		struct.script_unitrigger_type = "playertrigger_radius_use";
		struct.prompt_and_visibility_func = ::playertrigger_update_prompt;
		struct.power_on = false;

		if(isdefined(level._custom_perks[perk].jingle))
			struct thread perk_machine_jingle_timer();

		register_playertrigger(struct, ::playertrigger_think);
	}
}

convert_legacy_perk_machines()
{
	triggers = GetEntArray("zombie_vending", "targetname");
	perks = get_valid_perks_array();

	for(i = 0; i < triggers.size; i++)
	{
		if(isdefined(triggers[i].script_noteworthy))
		{
			targets = GetEntArray(triggers[i].target, "targetname");
			perk = get_perk_from_speciality(triggers[i].script_noteworthy);

			if(!isdefined(perk))
				perk = triggers[i].script_noteworthy;

			if(is_perk_valid(perk))
			{
				machine = undefined;
				clip = undefined;

				for(j = 0; j < targets.size; j++)
				{
					if(is_equal(targets[j].script_noteworthy, "clip"))
					{
						if(!isdefined(clip))
						{
							clip = targets[j];
							continue;
						}
						targets[j] ConnectPaths();
					}
					else
					{
						if(!isdefined(machine))
						{
							machine = targets[j];
							continue;
						}
					}

					targets[j] Delete();
				}

				origin = triggers[i].origin;
				angles = triggers[i].angles;

				if(isdefined(machine))
				{
					origin = machine.origin;
					angles = machine.angles;
				}

				stub = generate_perk_spawn_struct(perk, origin, angles);
				stub.machine_override = machine;
				stub.clip_override = clip;
			}
			else
			{
				for(j = 0; j < targets.size; j++)
				{
					if(is_equal(targets[j].script_noteworthy, "clip"))
						targets[j] ConnectPaths();
					targets[j] Delete();
				}
			}
		}
		triggers[i] Delete();
	}
}

playertrigger_update_prompt(player)
{
	if(!self trigger_visible_to_player(player))
		return false;

	if(is_true(self.stub.power_on))
	{
		self.hint_string = get_perk_hint_string(self.stub.script_noteworthy);
		self.hint_param1 = player get_perk_cost(self.stub.script_noteworthy);
		// self maps\apex\_utility_code::playertrigger_set_hintstring();
		return true;
	}
	else
	{
		self.hint_string = &"ZOMBIE_NEED_POWER";
		// self maps\apex\_utility_code::playertrigger_set_hintstring();
		return true;
	}
}

playertrigger_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);

		if(!is_true(self.stub.power_on))
			continue;

		player thread vending_trigger_give_perk(self.stub);
	}
}

trigger_visible_to_player(player)
{
	if(player has_perk(self.stub.script_noteworthy))
		return false;
	if(!self vending_trigger_can_player_use(player))
		return false;
	if(player in_revive_trigger())
		return false;

	weapon = player GetCurrentWeapon();

	if(is_equipment/*_that_blocks_purchase*/(weapon))
		return false;
	if(player hacker_active())
		return false;
	return true;
}

vending_trigger_can_player_use(player)
{
	if(player maps\_laststand::player_is_in_laststand() || is_true(player.intermission))
		return false;
	if(player in_revive_trigger())
		return false;
	if(!player maps\_zombiemode_weapons::can_buy_weapon())
		return false;
	if(player IsThrowingGrenade())
		return false;
	if(player IsSwitchingWeapons())
		return false;
	if(player is_drinking())
		return false;
	return true;
}

vending_trigger_give_perk(stub)
{
	self endon("disconnect");

	perk = stub.script_noteworthy;
	cost = self get_perk_cost(perk);
	perk_limit = self get_player_perk_purchase_limit();

	if(self.score < cost)
	{
		PlaySoundAtPosition("evt_perk_deny", stub.origin);
		self maps\_zombiemode_audio::create_and_play_dialog("general", "perk_deny", undefined, 0);
		return;
	}

	if(self.num_perks >= perk_limit)
	{
		PlaySoundAtPosition("evt_perk_deny", stub.origin);
		self maps\_zombiemode_audio::create_and_play_dialog("general", "sigh");
		return;
	}

	PlaySoundAtPosition("evt_bottle_dispsense", stub.origin);
	self maps\_zombiemode_score::minus_to_player_score(cost);
	self.perk_purchased = perk;

	if(isdefined(level._custom_perks[perk].sting))
		stub.machine thread maps\_zombiemode_audio::play_jingle_or_stinger(level._custom_perks[perk].sting);

	self drink_from_perk_bottle(perk);

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	if(isdefined(level.perk_bought_func))
		run_function(self, level.perk_bought_func, perk);

	self.perk_purchased = undefined;
	self give_perk(perk, true);
}

// custom function to allow
// power on / off
perk_machine_jingle_timer()
{
	// zombiemode audio uses this
	// to determine which broken
	// sound logic to use
	self.machine.script_sound = level._custom_perks[self.script_noteworthy].jingle;
	self.machine thread maps\_zombiemode_audio::play_random_broken_sounds();

	for(;;)
	{
		wait RandomFloatRange(31, 45);

		if(!is_true(self.power_on))
			continue;
		if(RandomInt(100) < 15)
			self.machine thread maps\_zombiemode_audio::play_jingle_or_stinger(self.machine.script_sound);
	}
}

perk_audio_bump_trigger_think()
{
	self endon("death");

	in_trigger = [];
	extra_change = [];

	for(;;)
	{
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			num = players[i] GetEntityNumber();

			if(is_true(in_trigger[num]))
			{
				if(is_true(extra_change[num]))
					continue;

				if(players[i] GetStance() == "prone")
				{
					extra_change[num] = true;
					players[i] maps\_zombiemode_score::add_to_player_score(100);
				}
			}

			if(players[i] IsTouching(self))
			{
				if(is_true(in_trigger[num]))
					continue;

				in_trigger[num] = true;
				players[i] PlaySound("fly_bump_bottle");
			}
			else
			{
				if(is_true(in_trigger[num]))
					in_trigger[num] = false;
			}
		}
		wait .05;
	}
}

//============================================================================================
// Perk Logic
//============================================================================================
perk_think(perk)
{
	perk_str = perk + "_stop";
	result = self waittill_any_return("fake_death", "death", "player_downed", perk_str);

	if(self should_ratain_perk(perk))
	{
		self thread perk_think(perk);
		return;
	}

	if(result != perk_str)
		self notify(perk_str);

	self._obtained_perks = array_remove_nokeys(self._obtained_perks, perk);
	self.num_perks--;

	if(isdefined(level._custom_perks[perk].specialties))
	{
		for(i = 0; i < level._custom_perks[perk].specialties.size; i++)
		{
			self UnSetPerk(level._custom_perks[perk].specialties[i]);
		}
	}

	if(isdefined(level._custom_perks[perk].take_func))
		single_thread(self, level._custom_perks[perk].take_func, result);

	self levelNotify("client_take_perk_" + perk);
	self perk_hud_destroy(perk);
	self.perk_purchased = undefined;

	if(isdefined(level.perk_lost_func))
		run_function(self, level.perk_lost_func, perk);

	self notify("perk_lost", perk);
}

should_ratain_perk(perk)
{
	if(!is_perk_valid(perk))
		return false;

	if(isdefined(level._custom_perks[perk].retain_func))
	{
		retain_perk = run_function(self, level._custom_perks[perk].retain_func);

		if(is_true(retain_perk))
			return true;
	}

	// retain all perks
	if(is_true(self._retain_perks))
		return true;
	// retain this specific perk
	if(isdefined(self._retain_perk_array) && is_true(self._retain_perk_array[perk]))
		return true;
	return false;
}

//============================================================================================
// Perk Bottle Drink Anim
//============================================================================================
drink_from_perk_bottle(perk)
{
	gun = self do_perk_bottle_drink_start(perk);
	result = self waittill_any("fake_death", "death", "player_downed", "weapon_change_complete");
	self do_perk_bottle_drink_end(perk, gun);
}

do_perk_bottle_drink_start(perk)
{
	self increment_is_drinking();
	self disable_player_move_states(true);
	bottle = get_perk_bottle(perk);
	weapon_options = self get_perk_bottle_weapon_options(perk);
	model_index = 0;
	gun = self GetCurrentWeapon();

	if(isdefined(level._custom_perks[perk].model_index))
		model_index = level._custom_perks[perk].model_index;

	self GiveWeapon(bottle, model_index, weapon_options);
	self SwitchToWeapon(bottle);
	return gun;
}

do_perk_bottle_drink_end(perk, gun)
{
	self enable_player_move_states();
	self TakeWeapon(get_perk_bottle(perk));

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	if(self is_multiple_drinking())
	{
		self decrement_is_drinking();
		return;
	}
	else if(gun != "none" && !is_placeable_mine(gun) && !is_equipment(gun))
	{
		self SwitchToWeapon(gun);

		if(is_melee_weapon(gun))
		{
			self decrement_is_drinking();
			return;
		}
	}
	else
	{
		weapons = self GetWeaponsListPrimaries();

		if(isdefined(weapons) && weapons.size > 0)
			self SwitchToWeapon(weapons[0]);
	}

	self waittill("weapon_change_complete");

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	self decrement_is_drinking();
}

//============================================================================================
// Perk Hud
//============================================================================================
perk_hud_create(perk)
{
	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
		self perk_hud_create_menu(perk);
	else
		self perk_hud_create_legacy(perk);
}

perk_hud_destroy(perk)
{
	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
		self perk_hud_destroy_menu(perk);
	else
		self perk_hud_destroy_legacy(perk);
}

update_perk_hud()
{
	if(is_true(level.zombie_vars["zombie_perk_use_menu_hud"]))
		self update_perk_hud_menu();
	else
		self update_perk_hud_legacy();
}

// Menu Hud
perk_hud_create_menu(perk)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(isdefined(self.perk_hud[perk]))
		return;

	x = self.perk_hud.size * 30;

	self SetClientDvars(
		"ui_zm_perk_" + perk + "_x", x,
		"ui_zm_perk_" + perk + "_alpha", 1
	);

	self.perk_hud[perk] = x;
}

perk_hud_destroy_menu(perk)
{
	if(!isdefined(self.perk_hud))
		return;
	if(!isdefined(self.perk_hud[perk]))
		return;

	self SetClientDvars(
		"ui_zm_perk_" + perk + "_x", 0,
		"ui_zm_perk_" + perk + "_alpha", 0
	);
}

update_perk_hud_menu()
{
	if(isdefined(self.perk_hud))
	{
		keys = GetArrayKeys(self.perk_hud);

		for(i = 0; i < keys.size; i++)
		{
			self SetClientDvar("ui_zm_perk_" + keys[i] + "_x", i * 30);
		}
	}
}

// Legacy Hud
perk_hud_create_legacy(perk)
{
	if(!isdefined(self.perk_hud))
		self.perk_hud = [];
	if(isdefined(self.perk_hud[perk]))
		return;

	shader = level._custom_perks[perk].shader;
	hud = create_simple_hud(self);
	hud.foreground = true;
	hud.sort = 1;
	hud.hidewheninmenu = true;
	hud.alignX = "left";
	hud.alignY = "bottom";
	hud.horzAlign = "user_left";
	hud.vertAlign = "user_bottom";
	hud.x = self.perk_hud.size * 30;
	hud.y -= 70;
	hud.alpha = 1;
	hud SetShader(shader, 24, 24);
	self.perk_hud[perk] = hud;
}

perk_hud_destroy_legacy(perk)
{
	if(!isdefined(self.perk_hud))
		return;
	if(!isdefined(self.perk_hud[perk]))
		return;

	self.perk_hud[perk] destroy_hud();
	self.perk_hud[perk] = undefined;
}

update_perk_hud_legacy()
{
	if(isdefined(self.perk_hud))
	{
		keys = GetArrayKeys(self.perk_hud);

		for(i = 0; i < keys.size; i++)
		{
			self.perk_hud[keys[i]].x = i * 30;
		}
	}
}

//============================================================================================
// Utilities
//============================================================================================
get_valid_perks_array()
{
	if(isdefined(level._zm_valid_perk_array_cache))
		return level._zm_valid_perk_array_cache; // only need to build this array once
	else
	{
		result = [];

		if(isdefined(level._custom_perks))
		{
			keys = GetArrayKeys(level._custom_perks);

			for(i = 0; i < level._custom_perks.size; i++)
			{
				if(is_perk_valid(keys[i]))
					result[result.size] = keys[i];
			}
		}

		level._zm_valid_perk_array_cache = result;
		return result;
	}
}

get_perk_from_speciality(specialty)
{
	perks = get_valid_perks_array();

	for(i = 0; i < perks.size; i++)
	{
		if(!isdefined(level._custom_perks[perks[i]].specialties) || level._custom_perks[perks[i]].specialties.size == 0)
			continue;
		if(IsInArray(level._custom_perks[perks[i]].specialties, specialty))
			return perks[i];
	}
	return undefined;
}

give_perk(perk, bought)
{
	if(!is_perk_valid(perk))
		return;
	if(self has_perk(perk))
		return;

	self._obtained_perks[self._obtained_perks.size] = perk;
	self.num_perks++;

	if(is_true(bought))
	{
		self thread maps\_zombiemode_audio::perk_vox(perk);
		self SetBlur(4, .1);
		wait .1;
		self SetBlur(0, .1);
		self notify("perk_bought", perk);
	}

	if(isdefined(level._custom_perks[perk].give_func))
		single_thread(self, level._custom_perks[perk].give_func);

	if(isdefined(level._custom_perks[perk].specialties))
	{
		for(i = 0; i < level._custom_perks[perk].specialties.size; i++)
		{
			self SetPerk(level._custom_perks[perk].specialties[i]);
		}
	}

	self levelNotify("client_give_perk_" + perk);
	self perk_hud_create(perk);
	self.stats["perks"]++;
	self thread perk_think(perk);
}

take_perk(perk)
{
	if(self has_perk(perk))
		self notify(perk + "_stop");
}

give_random_perk()
{
	perks = self get_player_unobtained_perks();

	if(!isdefined(perks) || perks.size == 0)
		return undefined;

	perk = random(perks);
	self give_perk(perk, false);
	return perk;
}

lose_random_perk()
{
	perks = self get_player_obtained_perks();

	if(!isdefined(perks) || perks.size == 0)
		return undefined;

	perk = random(perks);
	self take_perk(perk);
	return perk;
}

get_perk_cost(perk)
{
	if(!is_perk_valid(perk))
		return -1;

	cost = level.zombie_vars["zombie_perk_cost"];

	if(isdefined(level._custom_perks[perk].cost))
	{
		if(IsInt(level._custom_perks[perk].cost))
			cost = level._custom_perks[perk].cost;
		else
			cost = run_function(self, level._custom_perks[perk].cost);
	}
	return cost;
}

get_perk_hint_string(perk)
{
	hint_string = level.zombie_vars["zombie_perk_hint"];

	if(!is_perk_valid(perk))
		return hint_string;

	if(isdefined(level._custom_perks[perk].hint))
		hint_string = level._custom_perks[perk].hint;
	return hint_string;
}

get_perk_bottle(perk)
{
	bottle = level.zombie_vars["zombie_perk_bottle"];

	if(!is_perk_valid(perk))
		return bottle;
	if(isdefined(level._custom_perks[perk].bottle))
		bottle = level._custom_perks[perk].bottle;
	return bottle;
}

get_perk_bottle_weapon_options(perk)
{
	if(!isdefined(self._perk_bottle_weapon_options))
		self._perk_bottle_weapon_options = [];
	if(isdefined(self._perk_bottle_weapon_options[perk]))
		return self._perk_bottle_weapon_options[perk];

	camo_index = 0;

	if(is_perk_valid(perk) && isdefined(level._custom_perks[perk].camo_index))
		camo_index = level._custom_perks[perk].camo_index;

	self._perk_bottle_weapon_options[perk] = self CalcWeaponOptions(camo_index);
	return self._perk_bottle_weapon_options[perk];
}

//============================================================================================
// Registry
//============================================================================================
is_perk_valid(perk)
{
	if(!isdefined(level._custom_perks))
		return false;
	if(!isdefined(level._custom_perks[perk]))
		return false;
	return is_true(level._custom_perks[perk].valid);
}

_register_undefined_perk(perk)
{
	if(!isdefined(level._custom_perks))
		level._custom_perks = [];
	if(isdefined(level._custom_perks[perk]))
		return;

	level._custom_perks[perk] = SpawnStruct();
}

register_perk(perk, shader)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].shader = shader;
	level._custom_perks[perk].valid = true;
}

add_perk_specialty(perk, specialty)
{
	_register_undefined_perk(perk);

	if(!isdefined(level._custom_perks[perk].specialties))
		level._custom_perks[perk].specialties = [];
	if(!IsInArray(level._custom_perks[perk].specialties, specialty))
		level._custom_perks[perk].specialties[level._custom_perks[perk].specialties.size] = specialty;
}

register_perk_bottle(perk, bottle, model_index, camo_index)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].bottle = bottle;
	level._custom_perks[perk].model_index = model_index;
	level._custom_perks[perk].camo_index = camo_index;
}

register_perk_machine(perk, hint, cost, machine_off, machine_on, light_fx)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].hint = hint;
	level._custom_perks[perk].cost = cost;
	level._custom_perks[perk].machine_off = machine_off;
	level._custom_perks[perk].machine_on = machine_on;
	level._custom_perks[perk].light_fx = light_fx;
}

register_perk_threads(perk, give_func, take_func, retain_func)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].give_func = give_func;
	level._custom_perks[perk].take_func = take_func;
	level._custom_perks[perk].retain_func = retain_func;
}

register_perk_sounds(perk, sting, jingle, flash)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].sting = sting;
	level._custom_perks[perk].jingle = jingle;
	level._custom_perks[perk].flash = flash;
}