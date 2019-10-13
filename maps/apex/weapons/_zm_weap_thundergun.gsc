#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

#using_animtree("generic_human");

include_weapon_for_level()
{
	level._effect["thundergun_viewmodel_power_cell1"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view1");
	level._effect["thundergun_viewmodel_power_cell2"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view2");
	level._effect["thundergun_viewmodel_power_cell3"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view3");
	level._effect["thundergun_viewmodel_steam"] = LoadFX("weapon/thunder_gun/fx_thundergun_steam_view");
	level._effect["thundergun_viewmodel_power_cell1_upgraded"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view1");
	level._effect["thundergun_viewmodel_power_cell2_upgraded"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view2");
	level._effect["thundergun_viewmodel_power_cell3_upgraded"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view3");
	level._effect["thundergun_viewmodel_steam_upgraded"] = LoadFX("weapon/thunder_gun/fx_thundergun_steam_view");
	level._effect["thundergun_knockdown_ground"] = LoadFX("weapon/thunder_gun/fx_thundergun_knockback_ground");
	level._effect["thundergun_smoke_cloud"] = LoadFX("weapon/thunder_gun/fx_thundergun_smoke_cloud");

	set_zombie_var("thundergun_cylinder_radius", 180);
	set_zombie_var("thundergun_fling_range", 480);
	set_zombie_var("thundergun_gib_range", 900);
	set_zombie_var("thundergun_gib_damage", 75);
	set_zombie_var("thundergun_knockdown_range", 1200);
	set_zombie_var("thundergun_knockdown_damage", 15);

	level.thundergun_gib_refs = [];
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "guts";
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "right_arm";
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "left_arm";

	level.basic_zombie_thundergun_knockdown = ::zombie_knockdown;
	maps\_zombiemode_spawner::register_zombie_death_animscript_callback(::enemy_killed_by_thundergun);

	init_thundergun_anims();
	OnPlayerSpawned_Callback(::wait_for_thundergun_fired);
}

init_thundergun_anims()
{
	level._zombie_knockdowns = [];
	level._zombie_knockdowns["zombie"] = [];
	level._zombie_knockdowns["zombie"]["front"] = [];
	level._zombie_knockdowns["zombie"]["front"]["no_legs"] = [];
	level._zombie_knockdowns["zombie"]["front"]["has_legs"] = [];
	level._zombie_knockdowns["zombie"]["left"] = [];
	level._zombie_knockdowns["zombie"]["right"] = [];
	level._zombie_knockdowns["zombie"]["back"] = [];
	level._zombie_getups = [];
	level._zombie_getups["zombie"] = [];
	level._zombie_getups["zombie"]["back"] = [];
	level._zombie_getups["zombie"]["back"]["early"] = [];
	level._zombie_getups["zombie"]["back"]["late"] = [];
	level._zombie_getups["zombie"]["belly"] = [];
	level._zombie_getups["zombie"]["belly"]["early"] = [];
	level._zombie_getups["zombie"]["belly"]["late"] = [];
	level._zombie_knockdowns["zombie"]["front"]["no_legs"][0] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["zombie"]["front"]["no_legs"][1] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["zombie"]["front"]["no_legs"][2] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][0] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][1] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][2] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][3] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][4] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][5] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][6] = %ai_zombie_thundergun_hit_stumblefall;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][7] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][8] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][9] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][10] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][11] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][12] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][13] = %ai_zombie_thundergun_hit_deadfallknee;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][14] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][15] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][16] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][17] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][18] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][19] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["zombie"]["front"]["has_legs"][20] = %ai_zombie_thundergun_hit_flatonback;
	level._zombie_knockdowns["zombie"]["left"][0] = %ai_zombie_thundergun_hit_legsout_right;
	level._zombie_knockdowns["zombie"]["right"][0] = %ai_zombie_thundergun_hit_legsout_left;
	level._zombie_knockdowns["zombie"]["back"][0] = %ai_zombie_thundergun_hit_faceplant;
	level._zombie_getups["zombie"]["back"]["early"][0] = %ai_zombie_thundergun_getup_b;
	level._zombie_getups["zombie"]["back"]["early"][1] = %ai_zombie_thundergun_getup_c;
	level._zombie_getups["zombie"]["back"]["late"][0] = %ai_zombie_thundergun_getup_b;
	level._zombie_getups["zombie"]["back"]["late"][1] = %ai_zombie_thundergun_getup_c;
	level._zombie_getups["zombie"]["back"]["late"][2] = %ai_zombie_thundergun_getup_quick_b;
	level._zombie_getups["zombie"]["back"]["late"][3] = %ai_zombie_thundergun_getup_quick_c;
	level._zombie_getups["zombie"]["belly"]["early"][0] = %ai_zombie_thundergun_getup_a;
	level._zombie_getups["zombie"]["belly"]["late"][0] = %ai_zombie_thundergun_getup_a;
	level._zombie_getups["zombie"]["belly"]["late"][1] = %ai_zombie_thundergun_getup_quick_a;
}

wait_for_thundergun_fired()
{
	self endon("disconnect");
	self endon("spawned_player");

	for(;;)
	{
		self waittill("weapon_fired");
		weapon = self GetCurrentWeapon();

		if(is_thundergun(weapon))
		{
			self thread thundergun_fired();
			view_pos = self GetTagOrigin("tag_flash") - self GetPlayerViewHeight();
			view_angles = self GetTagAngles("tag_flash");
			PlayFX(level._effect["thundergun_smoke_cloud"], view_pos, AnglesToForward(view_angles), AnglesToUp(view_angles));
		}
	}
}

thundergun_network_choke()
{
	level.thundergun_network_choke_count++;

	if(!(level.thundergun_network_choke_count % 10))
	{
		wait_network_frame();
		wait_network_frame();
		wait_network_frame();
	}
}

thundergun_fired()
{
	PhysicsExplosionCylinder(self.origin, 600, 240, 1);
	self thread thundergun_affect_ais();
}

thundergun_affect_ais()
{
	if(!isdefined(level.thundergun_knockdown_enemies))
		level.thundergun_knockdown_enemies = [];
	if(!isdefined(level.thundergun_knockdown_gib))
		level.thundergun_knockdown_gib = [];
	if(!isdefined(level.thundergun_fling_enemies))
		level.thundergun_fling_enemies = [];
	if(!isdefined(level.thundergun_fling_vecs))
		level.thundergun_fling_vecs = [];

	self thundergun_get_enemies_in_range();
	level.thundergun_network_choke_count = 0;

	for(i = 0; i < level.thundergun_fling_enemies.size; i++)
	{
		level.thundergun_fling_enemies[i] thread thundergun_fling_zombie(self, level.thundergun_fling_vecs[i], i);
	}

	for(i = 0; i < level.thundergun_knockdown_enemies.size; i++)
	{
		level.thundergun_knockdown_enemies[i] thread thundergun_knockdown_zombie(self, level.thundergun_knockdown_gib[i]);
	}

	level.thundergun_knockdown_enemies = [];
	level.thundergun_knockdown_gib = [];
	level.thundergun_fling_enemies = [];
	level.thundergun_fling_vecs = [];
}

thundergun_get_enemies_in_range()
{
	view_pos = self GetWeaponMuzzlePoint();
	zombies = get_array_of_closest(view_pos, get_round_enemy_array(), undefined, undefined, level.zombie_vars["thundergun_knockdown_range"]);

	if(!isdefined(zombies))
		return;

	knockdown_range_squared = level.zombie_vars["thundergun_knockdown_range"] * level.zombie_vars["thundergun_knockdown_range"];
	gib_range_squared = level.zombie_vars["thundergun_gib_range"] * level.zombie_vars["thundergun_gib_range"];
	fling_range_squared = level.zombie_vars["thundergun_fling_range"] * level.zombie_vars["thundergun_fling_range"];
	cyliner_radius_squared = level.zombie_vars["thundergun_cylinder_radius"] * level.zombie_vars["thundergun_cylinder_radius"];

	forward_view_angles = self GetWeaponForwardDir();
	end_pos = view_pos + (forward_view_angles * level.zombie_vars["thundergun_knockdown_range"]);

	/#
	if(GetDvarInt(#"scr_thundergun_debug") == 2)
	{
		near_circle_pos = view_pos + (forward_view_angles * 2);
		Circle(near_circle_pos, level.zombie_vars["thundergun_cylinder_radius"], (1, 0, 0), false, false, 100);
		Line(near_circle_pos, end_pos, (0, 0, 1), 1, false, 100);
		Circle(end_pos, level.zombie_vars["thundergun_cylinder_radius"], (1, 0, 0), false, false, 100);
	}
	#/

	for(i = 0; i < zombies.size; i++)
	{
		if(!isdefined(zombies[i]) || !IsAlive(zombies[i]))
			continue;

		test_origin = zombies[i] GetCentroid();
		test_range_squared = DistanceSquared(view_pos, test_origin);

		if(test_range_squared > knockdown_range_squared)
		{
			/# zombies[i] thundergun_debug_print("range", (1, 0, 0)); #/
			return;
		}

		normal = VectorNormalize(test_origin - view_pos);
		dot = VectorDot(forward_view_angles, normal);

		if(0 > dot)
		{
			/# zombies[i] thundergun_debug_print("dot", (1, 0, 0)); #/
			continue;
		}

		radial_origin = PointOnSegmentNearestToPoint(view_pos, end_pos, test_origin);

		if(DistanceSquared(test_origin, radial_origin) > cyliner_radius_squared)
		{
			/# zombies[i] thundergun_debug_print("cylinder", (1, 0, 0)); #/
			continue;
		}

		if(0 == zombies[i] DamageConeTrace(view_pos, self))
		{
			/# zombies[i] thundergun_debug_print("cone", (1, 0, 0)); #/
			continue;
		}

		if(test_range_squared < fling_range_squared)
		{
			level.thundergun_fling_enemies[level.thundergun_fling_enemies.size] = zombies[i];
			dist_mult = (fling_range_squared - test_range_squared) / fling_range_squared;
			fling_vec = VectorNormalize(test_origin - view_pos);

			if(5000 < test_range_squared)
				fling_vec = fling_vec + VectorNormalize(test_origin - radial_origin);

			fling_vec = (fling_vec[0], fling_vec[1], Abs(fling_vec[2]));
			fling_vec = fling_vec * (200 * dist_mult);
			level.thundergun_fling_vecs[level.thundergun_fling_vecs.size] = fling_vec;
			zombies[i] thread setup_thundergun_vox(self, true, false, false);
		}
		else if(test_range_squared < gib_range_squared)
		{
			level.thundergun_knockdown_enemies[level.thundergun_knockdown_enemies.size] = zombies[i];
			level.thundergun_knockdown_gib[level.thundergun_knockdown_gib.size] = true;
			zombies[i] thread setup_thundergun_vox(self, false, true, false);
		}
		else
		{
			level.thundergun_knockdown_enemies[level.thundergun_knockdown_enemies.size] = zombies[i];
			level.thundergun_knockdown_gib[level.thundergun_knockdown_gib.size] = false;
			zombies[i] thread setup_thundergun_vox(self, false, false, true);
		}
	}
}

thundergun_debug_print(msg, color)
{
	/#
	if(!GetDvarInt(#"scr_thundergun_debug"))
		return;
	if(!isdefined(color))
		color = (1, 1, 1);

	Print3D(self.origin + (0, 0, 60), msg, color, 1, 1, 40);
	#/
}

thundergun_fling_zombie(player, fling_vec, index)
{
	if(!isdefined(self) || !IsAlive(self))
		return;

	if(isdefined(self.thundergun_fling_func))
	{
		run_function(self, self.thundergun_fling_func, player);
		return;
	}

	self.deathpoints_already_given = true;
	self DoDamage(self.health + 666, player.origin, player);

	if(self.health <= 0)
	{
		if(isdefined(player) && isdefined(level.hero_power_update))
			single_thread(level, level.hero_power_update, player, self);

		points = 10;

		if(!index)
			points = maps\_zombiemode_score::get_zombie_death_player_points();
		else if(1 == index)
			points = 30;

		player maps\_zombiemode_score::player_add_points("thundergun_fling", points);
		self StartRagdoll();
		self LaunchRagdoll(fling_vec);
		self.thundergun_death = true;
	}
}

zombie_knockdown(player, gib)
{
	if(is_true(gib) && !is_true(self.gibbed))
	{
		self.a.gib_ref = random(level.thundergun_gib_refs);
		self thread animscripts\zombie_death::do_gib();
	}

	if(isdefined(level.override_thundergun_damage_func))
		run_function(self, level.override_thundergun_damage_func, player, gib);
	else
	{
		damage = level.zombie_vars["thundergun_knockdown_damage"];
		self PlaySound("fly_thundergun_forcehit");
		self.thundergun_handle_pain_notetracks = ::handle_thundergun_pain_notetracks;
		self DoDamage(damage, player.origin, player);
		// self AnimCustom(&playThundergunPainAnim); // From T7 script
	}
}

thundergun_knockdown_zombie(player, gib)
{
	self endon("death");

	PlaySoundAtPosition("wpn_thundergun_proj_impact", self.origin);

	if(!isdefined(self) || !IsAlive(self))
		return;
	if(isdefined(self.thundergun_knockdown_func))
		run_function(self, self.thundergun_knockdown_func, player, gib);
}

handle_thundergun_pain_notetracks(note)
{
	if(note == "zombie_knockdown_ground_impact")
	{
		PlayFX(level._effect["thundergun_knockdown_ground"], self.origin, AnglesToForward(self.angles), AnglesToUp(self.angles));
		self PlaySound("fly_thundergun_forcehit");
	}
}

is_thundergun(weapon)
{
	return weapon == "thundergun_zm" || weapon == "thundergun_upgraded_zm";
}

is_thundergun_damage()
{
	if(isdefined(self.damageweapon) && !is_thundergun(self.damageweapon))
		return false;
	if(self.damagemod != "MOD_GRENADE")
		return false;
	if(self.damagemod != "MOD_GRENADE_SPLASH")
		return false;
	return true;
}

enemy_killed_by_thundergun()
{
	return is_true(self.thundergun_death);
}

setup_thundergun_vox(player, fling, gib, knockdown)
{
	if(!isdefined(self) || !IsAlive(self))
		return;

	if(is_true(fling))
	{
		if(30 > RandomIntRange(1, 100))
			player maps\_zombiemode_audio::create_and_play_dialog("kill", "thundergun");
	}
}