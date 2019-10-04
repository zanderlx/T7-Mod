#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	if(GetDvar("scr_zm_playerTrigger_debug") == "")
		SetDvar("scr_zm_playerTrigger_debug", "0");

	OnPlayerConnect_Callback(::trigger_per_player_think);
}

trigger_per_player_think()
{
	self endon("disconnect");

	for(;;)
	{
		if(isdefined(level.trigger_per_player))
		{
			for(i = 0; i < level.trigger_per_player.size; i++)
			{
				self trigger_per_player_check(level.trigger_per_player[i]);
				/#
				self thread debug_playertrigger(level.trigger_per_player[i]);
				#/
			}
		}
		wait .05;
	}
}

playertrigger_origin()
{
	if(isdefined(self.originFunc))
		return run_function(self, self.originFunc);
	else
		return self.origin;
}

trigger_per_player_check(struct)
{
	check_origin = struct playertrigger_origin();
	entity_num = self GetEntityNumber();
	dist = Distance2DSquared(self.origin, check_origin);
	test = (struct.radius + 15) * (struct.radius + 15);
	
	if(dist < test)
	{
		if(!isdefined(struct.trigger_pool[entity_num]))
		{
			struct.trigger_pool[entity_num] = Spawn("trigger_radius_use", check_origin, 0, struct.radius, struct.height);
			struct.trigger_pool[entity_num].angles = struct.angles;
			struct.trigger_pool[entity_num].stub = struct;
			struct.trigger_pool[entity_num] SetInvisibleToAll();
			struct.trigger_pool[entity_num] SetVisibleToPlayer(self);

			if(is_true(struct.require_look_at))
				struct.trigger_pool[entity_num] UseTriggerRequireLookAt();
			if(isdefined(struct.onSpawnFunc))
				run_function(struct, struct.onSpawnFunc, struct.trigger_pool[entity_num]);
			
			struct.trigger_pool[entity_num] thread check_visibility(self, struct);
			struct.trigger_pool[entity_num].parent_player = self;
		}
	}
	else
	{
		if(isdefined(struct.trigger_pool[entity_num]))
		{
			struct.trigger_pool[entity_num] notify("kill_trigger");
			struct.trigger_pool[entity_num] Delete();
			struct.trigger_pool[entity_num] = undefined;
		}
	}
}

check_visibility(player, struct)
{
	self endon("death");

	for(;;)
	{
		is_visible = true;

		if(isdefined(struct.prompt_and_visibility_func))
			is_visible = run_function(self, struct.prompt_and_visibility_func, player);
		
		if(is_visible)
		{
			if(!is_true(self.thread_running))
			{
				self.thread_running = true;
				self thread run_trigger_func(struct.trigger_func);
			}
		}
		else
		{
			if(is_true(self.thread_running))
			{
				self.thread_running = false;
				self notify("kill_trigger");
			}
		}
		wait .05;
	}
}

run_trigger_func(trigger_func)
{
	self endon("kill_trigger");

	if(isdefined(trigger_func))
		run_function(self, trigger_func);
}

playertrigger_trigger(player)
{
	return self.trigger_pool[player GetEntityNumber()];
}

debug_playertrigger(struct)
{
	/#
	if(GetDvar("scr_zm_playerTrigger_debug") != "1")
		return;

	origin = struct playertrigger_origin();
	trigger = struct playertrigger_trigger(self);
	radius = struct.radius;
	height = struct.height;

	text = [];
	text[text.size] = "playertrigger:";
	text[text.size] = "OP: " + self.playername;
	text[text.size] = "R: " + radius;
	text[text.size] = "H: " + height;

	if(isdefined(trigger))
		Box(trigger.origin, (0 - radius, 0 - radius, 0 - height), (radius, radius, height), trigger.angles[1], (0, 1, 0));
		
	DrawCylinder(origin, radius, height);
	
	for(i = 0; i < text.size; i++)
	{
		Print3D(origin + (0, 0, text.size + 1 * 10) - (0, 0, i * 15), text[i]);
	}
	#/
}