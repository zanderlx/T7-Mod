#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	if(!maps\_zm_weapons::is_weapon_included("crossbow_explosive_zm"))
		return;
	
	PrecacheItem("explosive_bolt_zm");
	PrecacheItem("explosive_bolt_upgraded_zm");

	maps\_zombiemode::register_player_damage_callback(::crossbow_player_damage_override);
	maps\_zombiemode_spawner::register_zombie_death_event_callback(::crossbow_zombie_death_event);
	maps\_zombiemode_spawner::register_zombie_damage_callback(::crossbow_zombie_damage_event);

	OnPlayerConnect_Callback(::watch_for_monkey_bolt);
}

crossbow_player_damage_override(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime)
{
	if(is_crossbow_upgraded(sWeapon) && sMeansOfDeath == "MOD_IMPACT")
		level.monkey_bolt_holder = self;

	return -1;
}

crossbow_zombie_death_event()
{
	if(!isdefined(self.attacker))
		return;
	
	if(isdefined(self.damageweapon))
		weapon = self.damageweapon;
	else
		weapon = self.attacker GetCurrentWeapon();

	if(isdefined(level.monkey_bolt_holder) && IsPlayer(level.monkey_bolt_holder))
	{
		if(self.damagemod == "MOD_GRENADE_SPLASH")
		{
			if(is_crossbow_upgraded(weapon) || is_crossbow_bolt_upgraded(weapon))
				level._bolt_on_back++;
		}
	}
}

crossbow_zombie_damage_event(mod, hit_location, hit_origin, player, amount)
{
	if(isdefined(self.damageweapon))
		weapon = self.damageweapon;
	else
		weapon = player GetCurrentWeapon();

	if(is_crossbow_upgraded(weapon) && mod == "MOD_IMPACT")
		level.monkey_bolt_holder = self;

	return false;
}

watch_for_monkey_bolt()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_fire", grenade, weapon, parent);

		if(is_crossbow_variant(weapon))
		{
			if(isdefined(level.zombiemode_cross_bow_fired))
				single_thread(level, level.zombiemode_cross_bow_fired, grenade, weapon, parent, self);
			
			if(is_crossbow_upgraded(weapon) || is_crossbow_bolt_upgraded(weapon))
				grenade thread crossbow_monkey_bolt(self);
		}
	}
}

crossbow_monkey_bolt(player)
{
	level thread monkey_bolt_cleanup(self);
	attract_dit_diff = 45;
	num_attractors = 96;
	max_attract_dist = 1536;

	if(isdefined(level.monkey_attract_dist_diff))
		attract_dit_diff = level.monkey_attract_dist_diff;
	if(isdefined(level.num_monkey_attractors))
		num_attractors = level.num_monkey_attractors;
	if(isdefined(level.monkey_attract_dist))
		max_attract_dist = level.monkey_attract_dist;

	if(isdefined(level.monkey_bolt_holder))
	{
		if(IsPlayer(player) || is_true(level.monkey_bolt_holder.can_move_with_bolt))
			self create_zombie_point_of_interest(max_attract_dist, num_attractors, 10000, true);
		else if(IsAI(level.monkey_bolt_holder))
		{
			level thread wait_for_monkey_bolt_to_die(self, level.monkey_bolt_holder);

			if(is_true(level.monkey_bolt_holder.is_traversing))
				level.monkey_bolt_holder waittill("zombie_end_traverse");
			
			if(IsAlive(level.monkey_bolt_holder))
				level.monkey_bolt_holder thread monkey_bolt_taunts(self);

			self create_zombie_point_of_interest(max_attract_dist, num_attractors, 10000, true);
			valid_poi = check_point_in_active_zone(self.origin);

			if(!valid_poi)
				valid_poi = check_point_in_playable_area(self.origin);
			if(valid_poi)
				self thread create_zombie_point_of_interest_attractor_positions(4, attract_dit_diff);
		}
	}
	else
	{
		valid_poi = check_point_in_active_zone(self.origin);

		if(!valid_poi)
			valid_poi = check_point_in_playable_area(self.origin);

		if(!valid_poi && is_true(level.use_alternate_poi_positioning))
		{
			bkwd = AnglesToForward(self.angles) * -20;
			new_pos = self.origin + bkwd + (0, 0, -50);
			valid_poi = check_point_in_playable_area(new_pos);

			if(valid_poi)
			{
				alt_poi = Spawn("script_origin", new_pos);
				alt_poi create_zombie_point_of_interest(max_attract_dist, num_attractors, 10000, true);
				alt_poi thread create_zombie_point_of_interest_attractor_positions(4, attract_dit_diff);
				alt_poi thread wait_for_bolt_death(self);
			}
		}

		if(valid_poi)
		{
			self create_zombie_point_of_interest(max_attract_dist, num_attractors, 10000, true);
			self thread create_zombie_point_of_interest_attractor_positions(4, attract_dit_diff);
		}
	}
}

wait_for_bolt_death(bolt)
{
	bolt waittill("death");
	self Delete();
}

wait_for_monkey_bolt_to_die(bolt, zombie)
{
	bolt endon("death");
	zombie waittill("death");

	if(!isdefined(level.delete_monkey_bolt_on_zombie_death) || !run_function(zombie, level.delete_monkey_bolt_on_zombie_death))
		return;
	if(isdefined(bolt))
		bolt Delete();
}

monkey_bolt_taunts(grenade)
{
	self endon("death");

	if(isdefined(self.monkey_bolt_taunts) && run_function(self, self.monkey_bolt_taunts, grenade))
		return;
	else if(is_true(self.isdog) || !is_true(self.has_legs))
		return false;
	else if(isdefined(self.animname) && self.animname == "thief_zombie")
		return;
	else if(is_true(self.in_the_ceiling))
		return;
	
	while(isdefined(grenade))
	{
		if(isdefined(level._zombie_board_taunt[self.animname]))
		{
			taunt_anim = random(level._zombie_board_taunt[self.animname]);

			if(self.animname == "zombie")
				self thread maps\_zombiemode_audio::do_zombies_playvocals("taunt", self.animname);
			

			if(!IsAlive(self))
				return;
			
			self.allowdeath = true;
			self AnimScripted("zombie_taunt", self.origin, self.angles, taunt_anim, "normal", undefined);

			if(!IsAlive(self))
				return;
			
			wait GetAnimLength(taunt_anim);
		}
		wait .05;
	}

	level.monkey_bolt_holder = undefined;
}

monkey_bolt_cleanup(grenade)
{
	while(isdefined(grenade))
	{
		wait .1;
	}

	if(isdefined(level.monkey_bolt_holder))
		level.monkey_bolt_holder = undefined;
}

is_crossbow(weapon)
{
	return weapon == "crossbow_explosive_zm" || is_crossbow_upgraded(weapon);
}

is_crossbow_bolt(weapon)
{
	return weapon == "explosive_bolt_zm" || is_crossbow_bolt_upgraded(weapon);
}

is_crossbow_upgraded(weapon)
{
	return weapon == "crossbow_explosive_upgraded_zm";
}

is_crossbow_bolt_upgraded(weapon)
{
	return weapon == "explosive_bolt_upgraded_zm";
}

is_crossbow_variant(weapon)
{
	return is_crossbow(weapon) || is_crossbow_bolt(weapon);
}