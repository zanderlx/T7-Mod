#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

#using_animtree("zombie_cymbal_monkey");

include_weapon_for_level()
{
	level.cymbal_monkeys = [];
	level._effect["monkey_glow"] = LoadFX("maps/zombie/fx_zombie_monkey_light");
	maps\apex\_zm_weapons::register_zombie_weapon_callback("zombie_cymbal_monkey", ::player_give_cymbal_monkey);

	if(!isdefined(level.valid_poi_max_radius))
		level.valid_poi_max_radius = 200;
	if(!isdefined(level.valid_poi_half_height))
		level.valid_poi_half_height = 100;
	if(!isdefined(level.valid_poi_inner_spacing))
		level.valid_poi_inner_spacing = 2;
	if(!isdefined(level.valid_poi_radius_from_edges))
		level.valid_poi_radius_from_edges = 15;
	if(!isdefined(level.valid_poi_height))
		level.valid_poi_height = 36;

	if(!isdefined(level.monkey_attract_dist_diff))
		level.monkey_attract_dist_diff = 45;
	if(!isdefined(level.num_monkey_attractors))
		level.num_monkey_attractors = 96;
	if(!isdefined(level.monkey_attract_dist))
		level.monkey_attract_dist = 1536;

	OnPlayerConnect_Callback(::player_handle_cymbal_monkey);
}

player_give_cymbal_monkey()
{
	self maps\apex\_zm_weapons::give_weapon("zombie_cymbal_monkey");
	self set_player_tactical_grenade("zombie_cymbal_monkey");
}

player_handle_cymbal_monkey()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_fire", grenade, weapon);

		if(weapon == "zombie_cymbal_monkey")
		{
			grenade.use_grenade_special_long_bookmark = true;
			grenade.grenade_multiattack_bookmark_count = 1;
			grenade.weapon = weapon;
			grenade.owner = self;
			self thread player_throw_cymbal_monkey(grenade);
		}
	}
}

player_throw_cymbal_monkey(grenade)
{
	self endon("disconnect");

	if(isdefined(grenade))
	{
		grenade endon("death");

		if(self maps\_laststand::player_is_in_laststand())
		{
			if(isdefined(grenade.damagearea))
				grenade.damagearea Delete();
			grenade Delete();
			return;
		}

		grenade Hide();
		model = maps\apex\_zm_weapons::spawn_weapon_model("zombie_cymbal_monkey", grenade.origin, grenade.angles);
		model SetModel("weapon_zombie_monkey_bomb"); // need to use world model for anim GetWeaponModel() gets the viewmodel
		model UseAnimTree(#animtree);
		model LinkTo(grenade);
		model.angles = grenade.angles;
		model thread monkey_cleanup(grenade);

		clone = undefined;

		if(is_true(level.cymbal_monkey_dual_view))
		{
			model SetVisibleToAllExceptTeam(level.zombie_team);
			clone = maps\apex\_zm_clone::spawn_player_clone(self, (0, 0, -999), level.cymbal_monkey_clone_weapon, undefined);
			model.simulacrum = clone;
			clone maps\apex\_zm_clone::clone_animate("idle");
			clone thread clone_player_angles(self);
			clone NotSolid();
			clone Hide();
		}

		grenade thread watch_for_dud(model, clone);
		grenade thread watch_for_emp(model, clone);

		info = SpawnStruct();
		info.sound_attractors = [];
		grenade waittill("stationary");

		if(isdefined(level.grenade_planted))
			single_thread(self, level.grenade_planted, grenade, model);

		if(isdefined(grenade))
		{
			// grenade.ground_ent = grenade GetGroundEnt();

			if(isdefined(model))
			{
				if(isdefined(grenade.ground_ent) && grenade.ground_ent.classname != "worldspawn")
				{
					// model SetMovingPlatformEnabled(true);
					model LinkTo(grenade.ground_ent);
					grenade thread FakeLinkTo(model);
				}
				else if(!is_true(grenade.backlinked))
				{
					model Unlink();
					model.origin = grenade.origin;
					model.angles = grenade.angles;
				}

				wait .1;
				model AnimScripted("cymbal_monkey_anim", grenade.origin, grenade.angles, %o_monkey_bomb);
			}

			if(isdefined(clone))
			{
				clone ForceTeleport(grenade.origin, grenade.angles);
				clone thread hide_owner(self);
				grenade thread proximity_detonate(self);
				clone Show();
				clone SetInvisibleToAll();
				clone SetVisibleToTeam(level.zombie_team);
			}

			grenade ResetMissileDetonationTime();
			PlayFXOnTag(level._effect["monkey_glow"], model, "tag_origin");

			valid_poi = check_point_in_playable_area(grenade.origin);

			/*
			if(is_true(level.move_valid_poi_to_navmesh))
				valid_poi = grenade move_valid_poi_to_navmesh(valid_poi);
			*/

			if(isdefined(level.check_valid_poi))
				valid_poi = run_function(grenade, level.check_valid_poi, valid_poi);

			if(valid_poi)
			{
				grenade create_zombie_point_of_interest(level.monkey_attract_dist_diff, level.num_monkey_attractors, 10000);
				grenade.attract_to_origin = true;
				grenade thread create_zombie_point_of_interest_attractor_positions(4, level.monkey_attract_dist_diff);
				grenade thread wait_for_attractor_positions_complete();
				grenade thread do_monkey_sound(model, info);
				level.cymbal_monkeys[level.cymbal_monkeys.size] = grenade;
			}
			else
			{
				grenade.script_noteworthy = undefined;
				level thread grenade_stolen_by_sam(grenade, model, clone);
			}
		}
		else
		{
			grenade.script_noteworthy = undefined;
			level thread grenade_stolen_by_sam(grenade, model, clone);
		}
	}
}

grenade_stolen_by_sam(grenade, model, clone)
{
	if(!isdefined(model))
		return;

	dir = model.origin;
	dir = (dir[1], dir[0], 0);

	if(dir[1] < 0 || (dir[0] > 0 && dir[1] > 0))
		dir = (dir[0], dir[1] * -1, 0);
	else if(dir[0] < 0)
		dir = (dir[0] * -1, dir[1], 0);

	array_func(GetPlayers(), maps\apex\_zm_magicbox::play_crazi_sound);
	PlayFXOnTag(level._effect["grenade_samantha_steal"], model, "tag_origin");
	model StopAnimScripted();
	model MoveZ(60, 1, .25, .25);
	model Vibrate(dir, 1.5, 2.5, 1);
	model waittill("moveddone");
	model Delete();

	if(isdefined(clone))
		clone Delete();

	if(isdefined(grenade))
	{
		if(isdefined(grenade.damagearea))
			grenade.damagearea Delete();
		grenade Delete();
	}
}

monkey_cleanup(parent)
{
	while(isdefined(parent))
	{
		wait .05;
	}

	if(isdefined(self) && is_true(self.dud))
		wait 6;
	if(isdefined(self.simulacrum))
		self.simulacrum Delete();

	self Delete();
}

do_monkey_sound(model, info)
{
	self.monk_scream_vox = false;

	if(!self maps\apex\_zm_weapons::grenade_safe_to_bounce(self.owner, "zombie_cymbal_monkey"))
	{
		self PlaySound("zmb_vox_monkey_scream");
		self.monk_scream_vox = true;
	}
	else if(isdefined(level.monkey_song_override) && run_function(self, level.monkey_song_override, self.owner, "zombie_cymbal_monkey"))
	{
		self PlaySound("zmb_vox_monkey_scream");
		self.monk_scream_vox = true;
	}
	else if(isdefined(level.monk_scream_trig) && self IsTouching(level.monk_scream_trig))
	{
		self PlaySound("zmb_vox_monkey_scream");
		self.monk_scream_vox = true;
	}

	if(!is_true(self.monk_scream_vox))
	{
		if(/*level.musicSystem.currentPlayType < 4*/!is_true(level.music_override))
		{
			if(is_true(level.cymbal_monkey_dual_view))
				self PlaySoundToTeam("zmb_monkey_song", level.player_team);
			else
				self PlaySound("zmb_monkey_song");
		}

		self thread play_delayed_explode_vox();
	}

	self waittill("explode", origin);
	level notify("grenade_exploded", origin, 100, 5000, 450);
	level.cymbal_monkeys = array_remove_nokeys(level.cymbal_monkeys, self);
	level.cymbal_monkeys = array_removeUndefined(level.cymbal_monkeys);

	if(isdefined(model))
		model StopAnimScripted();

	array_notify(info.sound_attractors, "monkey_blown_up");
}

play_delayed_explode_vox()
{
	wait 6.5;

	if(isdefined(self))
		self PlaySound("zmb_vox_monkey_explode");
}

FakeLinkTo(linkee)
{
	self notify("fakelinkto");
	self endon("fakelinkto");
	self.backlinked = true;

	while(isdefined(self) && isdefined(linkee))
	{
		self.origin = linkee.origin;
		self.angles = linkee.angles;
		wait .05;
	}
}

proximity_detonate(owner)
{
	wait 1.5;

	if(!isdefined(self))
		return;

	damagearea = Spawn("trigger_radius", self.origin + (0, 0, 96), level.SPAWNFLAG_TRIGGER_AI_NEUTRAL, 96, 144);
	// damagearea SetExcludeTeamForTrigger(owner.team);
	damagearea EnableLinkTo();
	damagearea LinkTo(self);
	self.damagearea = damagearea;

	for(;;)
	{
		damagearea waittill("trigger", ent);

		if(isdefined(owner) && ent == owner)
			continue;
		if(isdefined(ent.team) && ent.tag_origin == owner.team)
			continue;

		self PlaySound("wpn_claymore_alert");
		RadiusDamage(self.origin + (0, 0, 12), 192, 1, 1, owner, "MOD_GRENADE_SPLASH", "zombie_cymbal_monkey");

		if(isdefined(owner))
			self Detonate(owner);
		else
			self Detonate();
		break;
	}

	if(isdefined(damagearea))
		damagearea Delete();
}

hide_owner(owner)
{
	owner notify("hide_owner");
	owner endon("hide_owner");
	// owner SetPerk("specialty_immuneemms");
	owner.no_burning_fx = true;
	owner notify("stop_flame_sounds");
	owner SetVisibleToAllExceptTeam(level.zombie_team);
	owner.hide_owner = true;

	if(isdefined(level._effect["human_disappears"]))
		PlayFX(level._effect["human_disappears"], owner.origin);

	self thread show_owner_on_attack(owner);
	result = self waittill_any_return("explode", "death", "grenade_dud");
	owner notify("show_owner");
	// owner UnSetPerk("specialty_immuneemms");

	if(isdefined(level._effect["human_disappears"]))
		PlayFX(level._effect["human_disappears"], owner.origin);

	owner.no_burning_fx = undefined;
	owner SetVisibleToAll();
	owner.hide_owner = undefined;
	owner Show();
}

show_owner_on_attack(owner)
{
	owner endon("hide_owner");
	owner endon("show_owner");
	self endon("explode");
	self endon("death");
	self endon("grenade_dud");

	owner.show_for_time = undefined;

	for(;;)
	{
		owner waittill("weapon_fired");
		owner thread show_briefly(.5);
	}
}

show_briefly(showtime)
{
	self endon("show_owner");

	if(isdefined(self.show_for_time))
	{
		self.show_for_time = showtime;
		return;
	}

	self.show_for_time = showtime;
	self SetVisibleToAll();

	while(self.show_for_time > 0)
	{
		self.show_for_time -= .05;
		wait .05;
	}

	self SetVisibleToAllExceptTeam(level.zombie_team);
	self.show_for_time = undefined;
}

clone_player_angles(owner)
{
	self endon("death");
	owner endon("death");

	for(;;)
	{
		self.angles = owner.angles;
		wait .05;
	}
}

watch_for_emp(model, clone)
{
	self endon("death");

	if(!maps\apex\_zm_weapons::is_weapon_included("emp_zm"))
		return;

	for(;;)
	{
		level waittill("emp_detonate", origin, radius);

		if(DistanceSquared(origin, self.origin) < radius * radius)
			break;
	}

	self.stun_fx = true;

	if(isdefined(level._equipment_emp_destroy_fx))
		PlayFX(level._equipment_emp_destroy_fx, self.origin + (0, 0, 5), (0, RandomFloat(360), 0));

	wait .15;

	self.attract_to_origin = false;
	self deactivate_zombie_point_of_interest();
	model StopAnimScripted();
	wait 1;
	self Detonate();
	wait 1;

	if(isdefined(model))
		model Delete();
	if(isdefined(clone))
		clone Delete();
	if(isdefined(self.damagearea))
		self.damagearea Delete();
	self Delete();
}

watch_for_dud(model, clone)
{
	self endon("death");
	self waittill("grenade_dud");
	model.dud = true;
	self PlaySound("zmb_vox_monkey_scream");
	self.monk_scream_vox = true;
	wait 3;

	if(isdefined(model))
		model Delete();
	if(isdefined(clone))
		clone Delete();
	if(isdefined(self.damagearea))
		self.damagearea Delete();
	self Delete();
}

wait_for_attractor_positions_complete()
{
	self waittill("attractor_positions_generated");
	self.attract_to_origin = false;
}