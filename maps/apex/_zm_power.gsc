#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	// level power state
	flag_init("power_on", false);
	level._zm_power_state = false;

	// electric switch
	electric_switch_init();

	// power doors
	power_doors_init();
}

//============================================================================================
// Electric Switch
//============================================================================================
electric_switch_init()
{
	PrecacheString(&"ZOMBIE_ELECTRIC_SWITCH");
	PrecacheString(&"ZOMBIE_ELECTRIC_SWITCH_OFF");

	if(isdefined(level._custom_electric_switch_think))
	{
		single_thread(level, level._custom_electric_switch_think);
		return;
	}

	level thread electric_switch_think();
}

electric_switch_think()
{
	trigger = GetEnt("use_elec_switch", "targetname");
	handle = GetEnt("elec_switch", "targetname");
	struct = GetStruct("elec_switch_fx", "targetname");

	if(isdefined(struct))
		fx_pos = struct.origin;
	else if(isdefined(handle))
		fx_pos = handle.origin;
	else
		fx_pos = trigger.origin;

	trigger SetCursorHint("HINT_NOICON");
	trigger.script_string = "allow_power_off";
	trigger.power_on = false;
	trigger thread electric_switch_watch_power_state();
	ent = spawn_model("tag_origin", fx_pos, (0, 0, 0));

	for(;;)
	{
		trigger SetHintString(&"ZOMBIE_ELECTRIC_SWITCH");
		trigger waittill("trigger", player);
		trigger.power_on = true;

		if(isdefined(handle))
		{
			handle RotateRoll(-90, .3);
			handle PlaySound("zmb_switch_flip");
			handle waittill("rotatedone");
		}

		// PlayFX(level._effect["switch_sparks"], fx_pos);
		PlayFXOnTag(level._effect["switch_sparks"], ent, "tag_origin");

		if(isdefined(handle))
			handle PlaySound("zmb_turn_on");

		// Power on
		set_level_power_state(true);

		if(!isdefined(trigger.script_string) || trigger.script_string != "allow_power_off")
			return;

		trigger SetHintString(&"ZOMBIE_ELECTRIC_SWITCH_OFF");
		trigger waittill("trigger", player);
		trigger.power_on = false;
		ent Delete();
		ent = spawn_model("tag_origin", fx_pos, (0, 0, 0));

		if(isdefined(handle))
		{
			handle RotateRoll(90, .3);
			handle waittill("rotatedone");
		}

		// Power Off
		set_level_power_state(false);
	}
}

electric_switch_watch_power_state()
{
	for(;;)
	{
		flag_wait("power_on");

		if(!is_true(self.power_on))
			self notify("trigger", level);

		flag_waitopen("power_on");

		if(is_true(self.power_on))
			self notify("trigger", level);
	}
}

//============================================================================================
// Power
//============================================================================================
set_level_power_state(power_on_off)
{
	if(is_true(power_on_off))
	{
		if(is_true(level._zm_power_state))
			return;

		// level power state
		level._zm_power_state = true;
		flag_set("power_on");

		// extra powerables
		if(isdefined(level._zm_powerables))
			array_func(level._zm_powerables, ::powerable_power_on);

		// notify CSC
		level levelNotify("ZPO");
	}
	else
	{
		if(is_true(level._zm_power_state))
		{
			// level power state
			level._zm_power_state = false;
			flag_clear("power_on");

			// extra powerables
			if(isdefined(level._zm_powerables))
				array_func(level._zm_powerables, ::powerable_power_off);

			// notify CSC
			level levelNotify("ZPOff");
		}
	}
}

is_power_on()
{
	return is_true(level._zm_power_state);
}

//============================================================================================
// Powerables
//============================================================================================
powerable_initial_power_init(initial_power_state)
{
	level waittill("fade_introblack");

	// override ignoring power for inital power state
	ignore_power = self.ignore_power;
	self.ignore_power = false;

	if(is_true(initial_power_state))
		self powerable_power_on();
	else
	{
		// NOOP:
		// everything defaults to power off initally
		// do nothing
	}

	self.ignore_power = ignore_power;
}

add_powerable(initial_power_state, power_on_func, power_off_func)
{
	struct = SpawnStruct();
	struct.power_on = false;
	struct.power_on_func = power_on_func;
	struct.power_off_func = power_off_func;
	struct thread powerable_initial_power_init(initial_power_state);

	if(!isdefined(level._zm_powerables))
		level._zm_powerables = [];
	level._zm_powerables[level._zm_powerables.size] = struct;
	return struct;
}

powerable_power_on()
{
	if(is_true(self.ignore_power))
		return;
	if(is_true(self.power_on))
		return;

	self.power_on = true;

	if(isdefined(self.power_on_func))
		single_thread(self, self.power_on_func);
}

powerable_power_off()
{
	if(is_true(self.ignore_power))
		return;

	if(is_true(self.power_on))
	{
		self.power_on = false;

		if(isdefined(self.power_off_func))
			single_thread(self, self.power_off_func);
	}
}

//============================================================================================
// Power Doors
//============================================================================================
power_doors_init()
{
	// electric_door
	// electric_buyable_door
	zombie_doors = GetEntArray("zombie_door", "targetname");

	for(i = 0; i < zombie_doors.size; i++)
	{
		door = zombie_doors[i];

		if(!isdefined(door.script_noteworthy))
			continue;
		if(door.script_noteworthy != "electric_door" && door.script_noteworthy != "electric_buyable_door")
			continue;

		// no power on function
		// handled in zombiemode_blockers door logic functions
		door.powerable_stub = add_powerable(false, undefined, ::power_door_off);
		door.powerable_stub.door = door;
	}
}

power_door_off()
{
	door = self.door;

	// door already closed
	if(!is_true(door._door_open))
		return;

	door power_door_close();
}

power_door_close()
{
	if(isdefined(self.script_flag))
	{
		// deactivate zone?
		/*
		tokens = StrTok(self.script_flag, ",");

		for(i = 0; i < tokens.size; i++)
		{
			flag_clear(tokens[i]);
		}
		*/
	}

	if(self.script_noteworthy == "electric_buyable_door")
	{
		cost = 1000;

		if(isdefined(self.zombie_cost))
			cost = self.zombie_cost;

		self set_hint_string(self, "default_buy_door_" + cost);
	}
	else
		self SetHintString(&"ZOMBIE_NEED_POWER");

	self thread maps\_zombiemode_blockers::door_think();
	self._door_open = false;
	array_func(self.doors, maps\_zombiemode_blockers::door_activate, undefined, false);
	array_func(GetEntArray(self.target, "target"), ::trigger_on);
	self notify("door_closed");
}