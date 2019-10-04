#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	flag_init("power_on", false);
	flag_init("global_power_on", false);

	PrecacheString(&"ZOMBIE_ELECTRIC_SWITCH");
	PrecacheString(&"ZOMBIE_ELECTRIC_SWITCH_OFF");

	level thread power_switch_think();
	level thread global_power_think();
}

power_switch_think()
{
	trigger = GetEnt("use_elec_switch", "targetname");
	master_switch = GetEnt("elec_switch", "targetname");
	fx_struct = GetStruct("elec_switch_fx", "targetname");

	trigger SetCursorHint("HINT_NOICON");

	fx_pos = undefined;

	if(isdefined(fx_struct))
		fx_pos = fx_struct.origin;
	else if(isdefined(master_switch))
		fx_pos = master_switch.origin;
	
	fx_ent = undefined;

	for(;;)
	{
		trigger SetHintString(&"ZOMBIE_ELECTRIC_SWITCH");
		trigger waittill("trigger", player);

		if(isdefined(master_switch))
		{
			master_switch RotateRoll(-90, .3);
			master_switch PlaySound("zmb_switch_flip");
			master_switch waittill("rotatedone");
		}
		else
			wait .3;

		if(isdefined(fx_ent))
		{
			fx_ent Delete();
			fx_ent = undefined;
		}
		
		if(isdefined(fx_pos))
		{
			fx_ent = spawn_model("tag_origin", fx_pos, (0, 0, 0));
			PlayFXOnTag(level._effect["switch_sparks"], fx_ent, "tag_origin");
		}

		flag_set("power_on");

		if(!isdefined(trigger.script_string) || trigger.script_string != "allow_power_off")
			break;
		
		trigger SetHintString(&"ZOMBIE_ELECTRIC_SWITCH_OFF");
		trigger waittill("trigger", player);

		if(isdefined(fx_ent))
			fx_ent Delete();
		
		if(isdefined(master_switch))
		{
			master_switch RotateRoll(90, .3);
			master_switch waittill("rotatedone");
		}
		else
			wait .3;
		
		flag_clear("power_on");
	}
}

global_power_on()
{
	if(flag("global_power_on"))
		return;
	
	if(isdefined(level._zm_powerables))
		array_run(level._zm_powerables, ::powerable_power_on);
	
	clientNotify("ZPO");
	flag_set("power_on");
	flag_set("global_power_on");
}

global_power_off()
{
	if(!flag("global_power_on"))
		return;
	
	if(isdefined(level._zm_powerables))
		array_run(level._zm_powerables, ::powerable_power_off);
	
	clientNotify("ZPOff");
	flag_clear("power_off");
	flag_clear("global_power_on");
}

global_power_think()
{
	for(;;)
	{
		flag_wait("power_on");
		global_power_on();
		flag_waitopen("power_on");
		global_power_off();
	}
}

add_powerable(thread_power_on, thread_power_off)
{
	if(!isdefined(level._zm_powerables))
		level._zm_powerables = [];
	
	struct = SpawnStruct();
	struct.thread_power_on = thread_power_on;
	struct.thread_power_off = thread_power_off;
	struct.power_on = false;
	struct.can_power_off = true;

	level._zm_powerables[level._zm_powerables.size] = struct;
	return struct;
}

remove_powerable(powerable)
{
	if(!isdefined(level._zm_powerables))
		level._zm_powerables = [];
	if(!IsInArray(level._zm_powerables, powerable))
		return;

	powerable powerable_power_off();
	level._zm_powerables = array_remove_nokeys(level._zm_powerables, powerable);
}

powerable_power_on()
{
	if(!is_true(self.power_on))
	{
		self.power_on = true;

		if(isdefined(self.thread_power_on))
			single_thread(self, self.thread_power_on);
	}
}

powerable_power_off()
{
	if(is_true(self.can_power_off) && is_true(self.power_on))
	{
		self.power_on = false;

		if(isdefined(self.thread_power_off))
			single_thread(self, self.thread_power_off);
	}
}