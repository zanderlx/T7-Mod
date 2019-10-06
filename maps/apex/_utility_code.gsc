#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

//============================================================================================
// Utility Setup
//============================================================================================
init_apex_utility()
{
	// Fake Client Systems - xSanchez78
	registerClientSys("fake_client_systems");
	playertrigger_init();
}

//============================================================================================
// PlayerTrigger - xSanchez78
//============================================================================================
playertrigger_init()
{
	OnPlayerConnect_Callback(::playertrigger_think);
}

playertrigger_think()
{
	self endon("disconnect");

	for(;;)
	{
		if(isdefined(level.trigger_per_player))
			array_func(level.trigger_per_player, ::trigger_per_player_check, self);
		wait .05;
	}
}

trigger_per_player_check(player)
{
	entity_num = player GetEntityNumber();
	origin = self playertrigger_origin();
	dist = Distance2DSquared(player.origin, origin);
	test = (self.radius + 15) * (self.radius + 15);

	if(dist < test)
	{
		if(!isdefined(self.trigger_pool[entity_num]))
		{
			if(!isdefined(self.script_unitrigger_type))
			{
				/# PrintLn("PLAYERTRIGGER: stub.script_unitrigger_type is undefined"); #/
				return;
			}

			switch(self.script_unitrigger_type)
			{
				case "unitrigger_radius":
				case "playertrigger_radius":
					trigger = Spawn("trigger_radius", origin, 0, self.radius, self.height);
					break;

				case "unitrigger_radius_use":
				case "playertrigger_radius_use":
					trigger = Spawn("trigger_radius_use", origin, 0, self.radius, self.height);
					break;

				default:
					/# PrintLn("PLAYERTRIGGER: Unknown trigger type: " + self.script_unitrigger_type); #/
					return;
			}

			trigger.angles = self.angles;
			trigger.stub = self;
			trigger.parent_player = player;
			trigger SetInvisibleToAll();
			trigger SetVisibleToPlayer(player);
			self copy_zombie_keys_onto_trigger(trigger);
			self playertrigger_copy_stub_hintstring(trigger);

			if(isdefined(self.onSpawnFunc))
				run_function(self, self.onSpawnFunc, trigger);
			if(is_true(trigger.require_look_at))
				trigger UseTriggerRequireLookAt();

			trigger playertrigger_set_hintstring();
			self thread check_visibility(trigger, player);
			self.trigger_pool[entity_num] = trigger;
		}
	}
	else
	{
		if(isdefined(self.trigger_pool[entity_num]))
		{
			self.trigger_pool[entity_num] notify("kill_trigger");
			self.trigger_pool[entity_num] Delete();
			self.trigger_pool[entity_num] = undefined;
		}
	}

	/# self maps\apex\_debug::playertrigger_debug(player); #/
}

copy_zombie_keys_onto_trigger(trigger)
{
	trigger.script_noteworthy = self.script_noteworthy;
	trigger.targetname = self.targetname;
	trigger.target = self.target;
	trigger.zombie_weapon_upgrade = self.zombie_weapon_upgrade;
	trigger.clientFieldName = self.clientFieldName;
	trigger.useTime = self.useTime;
}

check_visibility(trigger, player)
{
	trigger endon("death");

	for(;;)
	{
		is_visible = true;

		if(isdefined(self.prompt_and_visibility_func))
			is_visible = run_function(trigger, self.prompt_and_visibility_func, player);

		if(is_true(is_visible))
		{
			if(!is_true(trigger.thread_running))
			{
				trigger.thread_running = true;
				self thread run_trigger_func(trigger);
			}
		}
		else
		{
			if(is_true(trigger.thread_running))
			{
				trigger.thread_running = false;
				trigger notify("kill_trigger");
			}
		}
		wait .05;
	}
}

run_trigger_func(trigger)
{
	trigger endon("death");
	trigger endon("kill_trigger");

	if(isdefined(self.trigger_func))
		run_function(trigger, self.trigger_func);
}

playertrigger_origin()
{
	if(isdefined(self.originFunc))
		return run_function(self, self.originFunc);
	return self.origin;
}

playertrigger_trigger(player)
{
	entity_num = player GetEntityNumber();

	if(isdefined(self.trigger_pool[entity_num]))
		return self.trigger_pool[entity_num];
	return undefined;
}

playertrigger_set_hintstring()
{
	if(isdefined(self.cursor_hint))
		self SetCursorHint(self.cursor_hint);
	else
		self SetCursorHint("HINT_NOICON");

	if(isdefined(self.hint_string))
	{
		if(isdefined(self.hint_param6))
		{
			// We assume params 1-5 are defined if param6 is defined
			Assert(isdefined(self.hint_param1));
			Assert(isdefined(self.hint_param2));
			Assert(isdefined(self.hint_param3));
			Assert(isdefined(self.hint_param4));
			Assert(isdefined(self.hint_param5));
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2, self.hint_param3, self.hint_param4, self.hint_param5, self.hint_param6);
		}
		else if(isdefined(self.hint_param5))
		{
			// We assume params 1-4 are defined if param5 is defined
			Assert(isdefined(self.hint_param1));
			Assert(isdefined(self.hint_param2));
			Assert(isdefined(self.hint_param3));
			Assert(isdefined(self.hint_param4));
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2, self.hint_param3, self.hint_param4, self.hint_param5);
		}
		else if(isdefined(self.hint_param4))
		{
			// We assume params 1-3 are defined if param4 is defined
			Assert(isdefined(self.hint_param1));
			Assert(isdefined(self.hint_param2));
			Assert(isdefined(self.hint_param3));
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2, self.hint_param3, self.hint_param4);
		}
		else if(isdefined(self.hint_param3))
		{
			// We assume params 1 & 2 are defined if param3 is defined
			Assert(isdefined(self.hint_param1));
			Assert(isdefined(self.hint_param2));
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2, self.hint_param3);
		}
		else if(isdefined(self.hint_param2))
		{
			// We assume params 1 are defined if param2 is defined
			Assert(isdefined(self.hint_param1));
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2);
		}
		else if(isdefined(self.hint_param1))
			self SetHintString(self.hint_string, self.hint_param1);
		else
			self SetHintString(self.hint_string);
	}
}

playertrigger_copy_stub_hintstring(trigger)
{
	trigger.cursor_hint = self.cursor_hint;
	trigger.hint_string = self.hint_string;
	trigger.hint_param1 = self.hint_param1;
	trigger.hint_param2 = self.hint_param2;
	trigger.hint_param3 = self.hint_param3;
	trigger.hint_param4 = self.hint_param4;
	trigger.hint_param5 = self.hint_param5;
	trigger.hint_param6 = self.hint_param6;
}