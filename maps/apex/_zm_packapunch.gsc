#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

#using_animtree("zm_packapunch");

init()
{
	include_packapunch();
	precache_packapunch();
	spawn_packapunch_machines();
	maps\apex\_zm_magicbox::add_custom_limited_weapon_check(::is_weapon_available_in_packapunch);
}

include_packapunch()
{
	flag_init("pack_machine_in_use", false);

	set_zombie_var("zombie_packapunch_uses_states", false);
	set_zombie_var("zombie_packapunch_cost", 5000);
	set_zombie_var("zombie_packapunch_hint", &"ZOMBIE_PERK_PACKAPUNCH");
	set_zombie_var("zombie_packapunch_hint_pickup", &"ZOMBIE_GET_UPGRADED");
	set_zombie_var("zombie_packapunch_weapon_model", "tag_origin");
	set_zombie_var("zombie_packapunch_flag_model", "zombie_sign_please_wait");
	set_zombie_var("zombie_packapunch_machine_model", "zombie_vending_packapunch");
	set_zombie_var("zombie_packapunch_machine_model_on", "zombie_vending_packapunch_on");
	set_zombie_var("zombie_packapunch_collision_model", "collision_geo_64x64x256");
	set_zombie_var("zombie_packapunch_timeout_time", 15);

	// use to override what models cost and other settings are used
	if(isdefined(level._zm_packapunch_include))
		run_function(level, level._zm_packapunch_include);
}

precache_packapunch()
{
	level._effect["packapunch_fx"] = LoadFX("maps/zombie/fx_zombie_packapunch");

	PrecacheItem("zombie_knuckle_crack");
	PrecacheModel(level.zombie_vars["zombie_packapunch_weapon_model"]);
	PrecacheModel(level.zombie_vars["zombie_packapunch_flag_model"]);
	PrecacheModel(level.zombie_vars["zombie_packapunch_machine_model"]);
	PrecacheModel(level.zombie_vars["zombie_packapunch_machine_model_on"]);
	PrecacheModel(level.zombie_vars["zombie_packapunch_collision_model"]);
	PrecacheString(level.zombie_vars["zombie_packapunch_hint"]);
	PrecacheString(level.zombie_vars["zombie_packapunch_hint_pickup"]);
}

include_t7_packapunch()
{
	level.zombie_vars["zombie_packapunch_uses_states"] = true;
	level.zombie_vars["zombie_packapunch_weapon_model"] = "p7_zm_vending_packapunch_weapon";
	level.zombie_vars["zombie_packapunch_flag_model"] = "p7_zm_vending_packapunch_sign_wait";
	level.zombie_vars["zombie_packapunch_machine_model"] = "p7_zm_vending_packapunch";
	level.zombie_vars["zombie_packapunch_machine_model_on"] = "p7_zm_vending_packapunch_on";

	level.pap_zbarrier_state_func = ::process_pap_zbarrier_state;
}

is_weapon_available_in_packapunch(weapon, ignore_player)
{
	count = 0;

	if(isdefined(level._zm_packapunch_machines) && level._zm_packapunch_machines.size > 0)
	{
		for(i = 0; i < level._zm_packapunch_machines.size; i++)
		{
			pap = level._zm_packapunch_machines[i];

			if(isdefined(pap.current_weapon) && pap.current_weapon == weapon)
				count++;
			if(isdefined(pap.upgrade_weapon) && pap.upgrade_weapon == weapon)
				count++;
		}
	}
	return count;
}

//============================================================================================
// Third Person
//============================================================================================
pap_weapon_move_in(stub, origin_offset, angles_offset)
{
	stub endon("power_off");
	stub endon("pap_player_disconnected");
	machine = stub.machine;
	stub.worldgun RotateTo(machine.angles + angles_offset + (0, 90, 0), .35, 0, 0);
	wait .5;
	stub.worldgun MoveTo(machine.origin + origin_offset, .5, 0, 0);
}

pap_weapon_move_out(stub, origin_offset, interact_offset)
{
	stub endon("power_off");
	stub endon("pap_player_disconnected");
	machine = stub.machine;
	stub.worldgun MoveTo(machine.origin + interact_offset, .5, 0, 0);
	wait .5;

	if(!isdefined(stub.worldgun))
		return;

	stub.worldgun MoveTo(machine.origin + origin_offset, level.zombie_vars["zombie_packapunch_timeout_time"], 0, 0);
}

third_person_weapon_upgrade(stub, current_weapon, upgrade_weapon)
{
	stub endon("power_off");
	stub endon("pap_player_disconnected");

	machine = stub.machine;
	origin_offset = (0, 0, 35);
	angles_offset = (0, 90, 0);
	origin_base = machine.origin;
	angles_base = machine.angles;
	forward = AnglesToForward(angles_base + angles_offset);
	interact_offset = origin_offset + (forward * -25);

	if(!isdefined(machine.fx_ent))
	{
		machine.fx_ent = spawn_model("tag_origin", origin_base + origin_offset + (0, 0, -35), angles_base + angles_offset);
		machine.fx_ent LinkTo(machine);
	}

	PlayFXOnTag(level._effect["packapunch_fx"], machine.fx_ent, "tag_origin");

	if(pap_should_use_states())
	{
		stub.weapon.weapon_name = current_weapon;
		stub set_state_take_gun();
	}
	else
	{
		stub.worldgun = maps\apex\_zm_weapons::spawn_weapon_model(current_weapon, origin_base + interact_offset, self.angles);

		if(isdefined(level.custom_pap_move_in))
			run_function(self, level.custom_pap_move_in, stub, origin_offset, angles_offset);
		else
			self pap_weapon_move_in(stub, origin_offset, angles_offset);
	}

	machine PlaySound("zmb_perks_packa_upgrade");

	if(pap_should_use_states())
		wait 3.35;
	else
	{
		stub.flag RotateTo(stub.flag.angles - (179, 0, 0), .25, 0, 0);
		wait .35;
		stub.worldgun maps\apex\_zm_weapons::model_hide_weapon();
		wait 3;
	}

	machine PlaySound("zmb_perks_packa_ready");

	if(pap_should_use_states())
	{
		stub.weapon.weapon_name = upgrade_weapon;
		stub set_state_eject_gun();
	}
	else
	{
		stub.worldgun maps\apex\_zm_weapons::model_use_weapon_options(upgrade_weapon);
		stub.flag RotateTo(stub.flag.angles + (179, 0, 0), .25, 0, 0);

		if(isdefined(level.custom_pap_move_out))
			run_function(self, level.custom_pap_move_out, stub, origin_offset, interact_offset);
		else
			self pap_weapon_move_out(stub, origin_offset, interact_offset);
	}
}

//============================================================================================
// Machine
//============================================================================================
generate_packapunch_spawn_struct(origin, angles)
{
	struct = SpawnStruct();
	struct.origin = origin;

	if(isdefined(angles))
		struct.angles = angles + (0, 90, 0);
	else
		struct.angles = (0, 0, 0);

	if(!isdefined(level._generated_packapunch_machines))
		level._generated_packapunch_machines = [];
	level._generated_packapunch_machines[level._generated_packapunch_machines.size] = struct;
	return struct;
}

spawn_packapunch_machines()
{
	level._zm_packapunch_machines = [];
	structs = GetStructArray("zm_packapunch_machine", "targetname");
	convert_legacy_machines();

	if(isdefined(level._generated_packapunch_machines) && level._generated_packapunch_machines.size > 0)
		structs = array_merge(structs, level._generated_packapunch_machines);
	if(!isdefined(structs) || structs.size == 0)
		return;

	for(i = 0; i < structs.size; i++)
	{
		struct = structs[i];
		origin = struct.origin;
		angles = struct.angles;

		if(!isdefined(origin))
			continue;
		if(!isdefined(angles))
			angles = (0, 0, 0);

		// Spawn machine
		if(isdefined(struct.machine_override))
		{
			struct.machine = struct.machine_override;
			angles = struct.machine.angles;
		}
		else
			struct.machine = spawn_model("tag_origin", origin, angles);

		struct.machine UseAnimTree(#animtree);
		struct.machine SetModel(level.zombie_vars["zombie_packapunch_machine_model"]);

		// Spawn flag
		if(isdefined(struct.flag_override))
		{
			struct.flag = struct.flag_override;
			angles = struct.flag.angles;
		}
		else
		{
			// (16, -24, 42) // waw prefab offset
			// (13, -29, -50) // zombie_pentagon prefab offset
			flag_origin = origin + (0, 0, 50) + (AnglesToRight(angles) * -13) + (AnglesToForward(angles) * 24);
			struct.flag = spawn_model("tag_origin", flag_origin, angles);
		}

		struct.flag UseAnimTree(#animtree);
		struct.flag SetModel(level.zombie_vars["zombie_packapunch_flag_model"]);
		struct.flag.angles = angles + (179, 0, 0);

		// Spawn perk collision
		struct.clip = Spawn("script_model", origin, 1);
		struct.clip.angles = angles;
		struct.clip SetModel(level.zombie_vars["zombie_packapunch_collision_model"]);
		struct.clip DisconnectPaths();
		struct.clip Hide();

		// Spawn weapon
		struct.weapon = spawn_model(level.zombie_vars["zombie_packapunch_weapon_model"], struct.machine.origin, struct.machine.angles);
		struct.weapon UseAnimTree(#animtree);

		// Spawn perk bump trigger
		struct.bump = Spawn("trigger_radius", origin, 0, 40, 50);
		struct.bump.angles = angles;
		// struct.bump thread perk_audio_bump_trigger_think(); // TODO: Bottle bump sounds

		// powerable
		struct.powerable = maps\apex\_zm_power::add_powerable(false, ::packapunch_power_on, ::packapunch_power_off);
		struct.powerable.playertrigger = struct;

		// Setup spawn struct as a playertrigger stub
		struct.origin = origin + (0, 0, 60);
		struct.radius = 40;
		struct.height = 80;
		struct.script_unitrigger_type = "playertrigger_radius_use";
		struct.prompt_and_visibility_func = ::playertrigger_update_prompt;
		// struct.power_on = false;

		// Extras
		struct.rollers = Spawn("script_origin", struct.origin);
		struct.rollers.angles = angles;
		struct.rollers LinkTo(struct.machine);

		struct.timer = Spawn("script_origin", struct.origin);
		struct.timer.angles = angles;
		struct.timer LinkTo(struct.machine);

		// TODO: Play packapunch jingle
		// mx_packa_jingle
		// struct thread perk_machine_jingle_timer();

		register_playertrigger(struct, ::playertrigger_think);
		level._zm_packapunch_machines[level._zm_packapunch_machines.size] = struct;

		// Set initial state
		// doing this for some reason kills machine
		// no future states get set, machine is stuck
		// struct thread set_initial_machine_state();
	}
}

convert_legacy_machines()
{
	triggers = GetEntArray("zombie_vending_upgrade", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		machine = GetEnt(triggers[i].target, "targetname");

		struct = generate_packapunch_spawn_struct(machine.origin, machine.angles);
		struct.machine_override = machine;

		if(isdefined(machine.target))
			struct.flag_override = GetEnt(machine.target, "targetname");

		triggers[i] Delete();
	}
}

set_initial_machine_state()
{
	flag_wait("begin_spawning");
	self set_state_initial();
}

//============================================================================================
// Powerable
//============================================================================================
packapunch_power_on()
{
	stub = self.playertrigger;

	if(pap_should_use_states())
		stub set_state_power_on();
	else
	{
		stub.machine SetModel(level.zombie_vars["zombie_packapunch_machine_model_on"]);
		stub.machine PlaySound("zmb_perks_power_on");
		stub.machine Vibrate((0, -100, 0), .3, .4, 3);
		stub.machine PlayLoopSound("zmb_perks_packa_loop");
		stub.power_on = true;
	}

	stub notify("power_on");
}

packapunch_power_off()
{
	stub = self.playertrigger;

	if(pap_should_use_states())
		stub set_state_power_off();
	else
	{
		stub.power_on = false;
		stub.machine SetModel(level.zombie_vars["zombie_packapunch_machine_model"]);
		stub.machine Vibrate((0, -100, 0), .3, .4, 3);
		stub.machine StopLoopSound(.1);
		stub.rollers StopLoopSound(.1);
		stub.timer StopLoopSound(.1);
	}

	stub notify("power_off");
}

//============================================================================================
// PlayerTrigger
//============================================================================================
playertrigger_update_prompt(player)
{
	if(is_true(self.stub.trigger_hidden))
		return false;

	if(is_true(self.stub.power_on))
	{
		if(isdefined(self.stub.pack_player) && self.stub.pack_player != player)
			return false;
		if(!player player_use_can_pack_now())
			return false;

		if(isdefined(self.stub.current_weapon))
		{
			self.hint_param1 = undefined; // fixes hintstring sometimes showing `Hold 5000 for upgraded weapon`
			self.hint_string = level.zombie_vars["zombie_packapunch_hint_pickup"];
		}
		else
		{
			self.hint_string = level.zombie_vars["zombie_packapunch_hint"];
			self.hint_param1 = level.zombie_vars["zombie_packapunch_cost"];
			// TODO: Update cost for bonfire sale powerup
		}
		return true;
	}
	else
	{
		self.hint_string = &"ZOMBIE_NEED_POWER";
		return true;
	}
}

playertrigger_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);

		if(flag("pack_machine_in_use"))
			self.stub notify("player_grabbed_weapon", player);
		else
		{
			if(!is_true(self.stub.power_on))
				continue;

			current_weapon = player GetCurrentWeapon();
			current_weapon = maps\apex\_zm_weapons::get_nonalternate_weapon(current_weapon);

			if(current_weapon == "microwavegun_zm")
				current_weapon = "microwavegundw_zm";

			if(isdefined(level.custom_pap_validation))
			{
				valid = run_function(self, level.custom_pap_validation, player);

				if(!is_true(valid))
					continue;
			}

			if(player.score < level.zombie_vars["zombie_packapunch_cost"])
			{
				self.stub.machine PlaySound("deny");
				player thread maps\_zombiemode_audio::create_and_play_dialog("general", "perk_deny", undefined, 0);
				continue;
			}

			self.stub thread vending_post_think(player, current_weapon);
		}
	}
}

vending_post_think(player, current_weapon)
{
	self.pack_player = player;
	flag_set("pack_machine_in_use");
	self thread destroy_weapon_in_blackout(player);
	self thread destroy_weapon_on_disconnect(player);
	player maps\_zombiemode_score::minus_to_player_score(level.zombie_vars["zombie_packapunch_cost"]);
	PlaySoundAtPosition("evt_bottle_dispense", self.origin);
	self.machine thread maps\_zombiemode_audio::play_jingle_or_stinger("mus_perks_packa_sting");
	player maps\_zombiemode_audio::create_and_play_dialog("weapon_pickup", "upgrade_wait");
	self.trigger_hidden = true;
	player thread do_knuckle_crack();
	upgrade_weapon = maps\apex\_zm_weapons::get_upgrade_weapon(current_weapon);
	self.current_weapon = current_weapon;
	self.upgrade_weapon = upgrade_weapon;
	player third_person_weapon_upgrade(self, current_weapon, upgrade_weapon);
	self.trigger_hidden = false;
	self thread wait_for_player_to_take(player, current_weapon, upgrade_weapon);
	self thread wait_for_timeout(player);
	self waittill_any("pap_timeout", "pap_taken", "pap_player_disconnected", "power_off");
	self set_state_powered();
	self.current_weapon = undefined;
	self.upgrade_weapon = undefined;

	if(isdefined(self.worldgun))
	{
		self.worldgun maps\apex\_zm_weapons::delete_weapon_model();
		self.worldgun = undefined;
	}
	self.pack_player = undefined;
	flag_clear("pack_machine_in_use");
}

wait_for_player_to_take(player, weapon, upgrade_weapon)
{
	self endon("pap_timeout");
	self endon("pap_player_disconnected");
	self endon("power_off");

	for(;;)
	{
		self.timer PlayLoopSound("zmb_perks_packa_timer");
		self waittill("player_grabbed_weapon", grabber);
		self.timer StopLoopSound(.05);

		if(grabber == player)
		{
			current_weapon = player GetCurrentWeapon();

			if(is_player_valid(player) && !player is_drinking() && !is_placeable_mine(current_weapon) && !is_equipment(current_weapon) && current_weapon != "syrette_sp" && current_weapon != "none" && !player hacker_active())
			{
				self notify("pap_taken");
				player notify("pap_taken");
				player.pap_used = true;
				player maps\apex\_zm_weapons::weapon_give(upgrade_weapon, false, false);
				return;
			}
		}
	}
}

wait_for_timeout(player)
{
	self endon("pap_taken");
	self endon("pap_player_disconnected");
	self endon("power_off");
	self thread wait_for_disconnect(player);
	wait level.zombie_vars["zombie_packapunch_timeout_time"];
	self notify("pap_timeout");
	self.timer StopLoopSound(.05);
	self.timer PlaySound("zmb_perks_packa_deny");
}

wait_for_disconnect(player)
{
	self endon("pap_timeout");
	self endon("pap_taken");
	player waittill("disconnect");
	self notify("pap_player_disconnected");
}

destroy_weapon_on_disconnect(player)
{
	self endon("pap_taken");
	self endon("pap_timeout");
	self endon("power_off");
	player waittill("disconnect");

	if(isdefined(self.worldgun))
	{
		self.worldgun maps\apex\_zm_weapons::delete_weapon_model();
		self.worldgun = undefined;
	}
}

destroy_weapon_in_blackout(player)
{
	self endon("pap_taken");
	self endon("pap_timeout");
	self endon("pap_player_disconnected");
	self waittill("power_off");

	self set_state_take_gun();
	player PlayLocalSound("zmb_laugh_child");
	wait 1.5;

	if(isdefined(self.worldgun))
	{
		self.worldgun RotateTo(self.worldgun.angles + (RandomInt(90) - 45, 0, RandomInt(360) - 180), 1.5, 0, 0);
		self waittill("rotatedone");
		self.worldgun maps\apex\_zm_weapons::delete_weapon_model();
		self.worldgun = undefined;
	}
}

can_pack_weapon(weapon_name)
{
	if(flag("pack_machine_in_use"))
		return true;
	if(!maps\apex\_zm_weapons::is_weapon_or_base_included(weapon_name))
		return false;
	if(!maps\apex\_zm_weapons::can_upgrade_weapon(weapon_name))
		return false;
	return true;
}

player_use_can_pack_now()
{
	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return false;
	if(self IsThrowingGrenade())
		return false;
	if(self IsSwitchingWeapons())
		return false;
	if(!self maps\apex\_zm_weapons::can_buy_weapon())
		return false;
	if(self hacker_active())
		return false;
	if(!self can_pack_weapon(self GetCurrentWeapon()))
		return false;
	return true;
}

//============================================================================================
// Knuckle Crack
//============================================================================================
do_knuckle_crack()
{
	self upgrade_kuckle_crack_begin();
	self waittill_any("fake_death", "death", "player_downed", "weapon_change_complete");
	self upgrade_kuckle_crack_end();
}

upgrade_kuckle_crack_begin()
{
	self increment_is_drinking();
	self disable_player_move_states(true);
	primaries = self GetWeaponsListPrimaries();
	gun = self GetCurrentWeapon();

	if(gun != "non" && !is_placeable_mine(gun) && !is_equipment(gun))
		self maps\apex\_zm_weapons::weapon_take(gun);
	else
		return undefined;

	self maps\apex\_zm_weapons::give_weapon("zombie_knuckle_crack");
	self SwitchToWeapon("zombie_knuckle_crack");
}

upgrade_kuckle_crack_end()
{
	self enable_player_move_states();
	self maps\apex\_zm_weapons::weapon_take("zombie_knuckle_crack");

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	self decrement_is_drinking();

	if(self is_drinking())
		return;
	else
		self maps\apex\_zm_weapons::switch_back_primary_weapon();
}

//============================================================================================
// States
//============================================================================================
pap_should_use_states()
{
	return is_true(level.zombie_vars["zombie_packapunch_uses_states"]);
}

get_pap_zbarrier_state()
{
	if(pap_should_use_states())
		return self.state;
	return undefined;
}

set_pap_zbarrier_state(state)
{
	if(!pap_should_use_states())
		return;

	self.machine Hide();
	self.flag Hide();
	self.weapon Hide();
	self.weapon DetachAll();

	self.state = state;
	self notify("zbarrier_state_change");

	if(isdefined(level.pap_zbarrier_state_func))
		run_function(self, level.pap_zbarrier_state_func, state);
}

process_pap_zbarrier_state(state)
{
	switch(state)
	{
		case "initial":
			self.machine Show();
			self thread pap_initial();
			break;
		case "power_off":
			self.machine Show();
			self thread pap_power_off();
			break;
		case "power_on":
			self.machine Show();
			self thread pap_power_on();
			break;
		case "powered":
			self.machine Show();
			self thread pap_powered();
			break;
		case "take_gun":
			self.machine Show();
			self.flag Show();
			self.weapon Show();
			self.weapon maps\apex\_zm_weapons::attach_weapon_model(self.weapon.weapon_name);
			self thread pap_take_gun();
			break;
		case "eject_gun":
			self.machine Show();
			self.flag Show();
			self.weapon Show();
			self.weapon maps\apex\_zm_weapons::attach_weapon_model(self.weapon.weapon_name);
			self thread pap_eject_gun();
			break;
		/*case "leaving":
			self.machine Show();
			self thread pap_leaving();
			break;
		case "arriving":
			self.machine Show();
			self thread pap_arriving();
			break;*/
		case "hidden":
			break;
		default:
			if(isdefined(level.custom_pap_state_handler))
				run_function(self, level.custom_pap_state_handler, state);
			break;
	}
}

pap_initial()
{
	self.machine ClearAnim(%root, .2);
	self.machine SetFlaggedAnim("packapunch_initial", %o_zombie_base_packapunch_poweron, 1, .2, 1);
	// self.machine waittillend("packapunch_initial");
}

pap_power_off()
{
	self.machine ClearAnim(%root, .2);
	self.machine SetFlaggedAnim("packapunch_poweroff", %o_zombie_base_packapunch_poweron, 1, .2, 1);
	self.power_on = false;
	self.machine SetModel(level.zombie_vars["zombie_packapunch_machine_model"]);
	self.machine StopLoopSound(.1);
	self.rollers StopLoopSound(.1);
	self.timer StopLoopSound(.1);
	// self.machine waittillend("packapunch_poweroff");
}

pap_power_on()
{
	// wait while `initial` is in `openinng` state, only used for teleporting in black ops 3
	// self pap_waittill_state_complete("arrving");

	self.machine ClearAnim(%root, .2);
	self.machine SetFlaggedAnim("packapunch_poweron", %o_zombie_base_packapunch_poweron, 1, .2, 1);
	self.machine SetModel(level.zombie_vars["zombie_packapunch_machine_model_on"]);
	self.machine PlaySound("zmb_perks_power_on");
	self.machine PlayLoopSound("zmb_perks_packa_loop");
	// self.machine waittillend("packapunch_poweron");
	self.power_on = true;
	wait 1;
	self thread set_state_powered();
}

pap_powered()
{
	self endon("zbarrier_state_change");

	for(;;)
	{
		self.machine ClearAnim(%root, .2);
		self.machine SetFlaggedAnim("packapunch_working_loop", %o_zombie_base_packapunch_working_loop, 1, .2, 1);
		self.machine waittillend("packapunch_working_loop");
		wait .05;
	}
}

pap_take_gun()
{
	self endon("zbarrier_state_change");

	self.weapon ClearAnim(%root, .2);
	self.weapon SetFlaggedAnim("packapunch_worldguns_taken", %o_zombie_base_packapunch_worldguns_taken, 1, .2, 1);

	self.machine ClearAnim(%root, .2);
	self.machine SetFlaggedAnim("packapunch_take_gun", %o_zombie_base_packapunch_working_take_gun, 1, .2, 1);
	// self.machine waittillend("packapunch_take_gun");

	self.flag ClearAnim(%root, .2);
	self.flag SetFlaggedAnim("packapunch_flag_up", %o_zombie_base_packapunch_flag_up, 1, .2, 1);
	// self.flag waittillend("packapunch_flag_up");

	self.weapon waittillend("packapunch_worldguns_taken");
	self.weapon Hide();
	self.weapon DetachAll();
}

pap_eject_gun()
{
	self endon("zbarrier_state_change");

	self.machine ClearAnim(%root, .2);
	self.machine SetFlaggedAnim("packapunch_eject_gun", %o_zombie_base_packapunch_working_eject_gun, 1, .2, 1);
	// self.machine waittillend("packapunch_eject_gun");

	self.flag ClearAnim(%root, .2);
	self.flag SetFlaggedAnim("packapunch_flag_down", %o_zombie_base_packapunch_flag_down, 1, .2, 1);
	// self.flag waittillend("packapunch_flag_down");

	self.weapon ClearAnim(%root, .2);
	self.weapon SetFlaggedAnim("packapunch_worldguns_ejected", %o_zombie_base_packapunch_worldguns_ejected, 1, .2, 1);
	// self.weapon waittillend("packapunch_worldguns_ejected");
}

set_state_initial()
{
	self thread set_pap_zbarrier_state("initial");
}

set_state_power_off()
{
	self thread set_pap_zbarrier_state("power_off");
}

set_state_power_on()
{
	self thread set_pap_zbarrier_state("power_on");
}

set_state_powered()
{
	self thread set_pap_zbarrier_state("powered");
}

set_state_take_gun()
{
	self thread set_pap_zbarrier_state("take_gun");
}

set_state_eject_gun()
{
	self thread set_pap_zbarrier_state("eject_gun");
}

// set_state_leaving()
// {
// 	self thread set_pap_zbarrier_state("leaving");
// }

// set_state_arriving()
// {
// 	self thread set_pap_zbarrier_state("arriving");
// }

set_state_hidden()
{
	self thread set_pap_zbarrier_state("hidden");
}