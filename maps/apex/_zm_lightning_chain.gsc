#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

#using_animtree("generic_human");

init()
{
	level._effect["tesla_bolt"] = LoadFX("maps/zombie/fx_zombie_tesla_bolt_secondary");
	level._effect["tesla_shock"] = LoadFX("maps/zombie/fx_zombie_tesla_shock");
	level._effect["tesla_shock_secondary"] = LoadFX("maps/zombie/fx_zombie_tesla_shock_secondary");
	level._effect["tesla_shock_eyes"] = LoadFX("maps/zombie/fx_zombie_tesla_shock_eyes");

	level.default_lightning_chain_params = create_lightning_chain_params();
	init_tesla_anims();
	set_zombie_var("tesla_head_gib_chance",	50);

	OnPlayerConnect_Callback(::on_player_connect);
	// causes default death animscript logic
	// to not happen on tesla kills
	// moved from tesla gun script to here
	maps\_zombiemode_spawner::register_zombie_death_animscript_callback(::was_enemy_killed_by_tesla);
}

init_tesla_anims()
{
	level._zombie_tesla_death = [];
	level._zombie_tesla_death["zombie"] = [];
	level._zombie_tesla_crawl_death = [];
	level._zombie_tesla_crawl_death["zombie"] = [];

	level._zombie_tesla_death["zombie"][0] = %ai_zombie_tesla_death_a;
	level._zombie_tesla_death["zombie"][1] = %ai_zombie_tesla_death_b;
	level._zombie_tesla_death["zombie"][2] = %ai_zombie_tesla_death_c;
	level._zombie_tesla_death["zombie"][3] = %ai_zombie_tesla_death_d;
	level._zombie_tesla_death["zombie"][4] = %ai_zombie_tesla_death_e;
	level._zombie_tesla_crawl_death["zombie"][0] = %ai_zombie_tesla_crawl_death_a;
	level._zombie_tesla_crawl_death["zombie"][1] = %ai_zombie_tesla_crawl_death_b;
}

create_lightning_chain_params(max_arcs, max_enemies_killed, radius_start, radius_decay, head_gib_chance, arc_travel_time, kills_for_powerup, min_fx_distance, network_death_choke, should_kill_enemies, arc_fx_sound, no_fx)
{
	if(!isdefined(max_arcs))
		max_arcs = 5;
	if(!isdefined(max_enemies_killed))
		max_enemies_killed = 10;
	if(!isdefined(radius_start))
		radius_start = 300;
	if(!isdefined(radius_decay))
		radius_decay = 20;
	if(!isdefined(head_gib_chance))
		head_gib_chance = 75;
	if(!isdefined(arc_travel_time))
		arc_travel_time = .11;
	if(!isdefined(kills_for_powerup))
		kills_for_powerup = 10;
	if(!isdefined(min_fx_distance))
		min_fx_distance = 128;
	if(!isdefined(network_death_choke))
		network_death_choke = 4;
	if(!isdefined(should_kill_enemies))
		should_kill_enemies = true;
	// if(!isdefined(arc_fx_sound))
	// 	arc_fx_sound = undefined;
	if(!isdefined(no_fx))
		no_fx = false;

	lcp = SpawnStruct();
	lcp.max_arcs = max_arcs;
	lcp.max_enemies_killed = max_enemies_killed;
	lcp.radius_start = radius_start;
	lcp.radius_decay = radius_decay;
	lcp.head_gib_chance = head_gib_chance;
	lcp.arc_travel_time = arc_travel_time;
	lcp.kills_for_powerup = kills_for_powerup;
	lcp.min_fx_distance = min_fx_distance;
	lcp.network_death_choke = network_death_choke;
	lcp.should_kill_enemies = should_kill_enemies;
	lcp.arc_fx_sound = arc_fx_sound;
	lcp.no_fx = no_fx;
	return lcp;
}

on_player_connect()
{
	self endon("disconnect");
	self waittill("spawned_player");

	self.tesla_network_death_choke = 0;

	for(;;)
	{
		wait_network_frame();
		wait_network_frame();
		self.tesla_network_death_choke = 0;
	}
}

was_enemy_killed_by_tesla()
{
	return is_true(self.tesla_death);
}

is_lightning_chain_damage(mod)
{
	return mod == "MOD_PROJECTILE" || mod == "MOD_PROJECTILE_SPLASH";
}

damage_init(player, params)
{
	player endon("disconnect");

	if(!isdefined(params))
		params = level.default_lightning_chain_params;

	if(is_true(player.tesla_firing))
	{
		/# debug_print("TESLA: Player: '" + player.playername + "' currently processing tesla damage"); #/
		return;
	}

	if(is_true(self.zombie_tesla_hit))
		return;

	/# debug_print("TESLA: Player: '" + player.playername + "' hit with the tesla gun"); #/

	player.tesla_enemies = undefined;
	player.tesla_enemies_hit = 1;
	player.tesla_powerup_dropped = false;
	player.tesla_arc_count = 0;
	player.tesla_firing = true;

	self arc_damage(self, player, 1, params);

	if(player.tesla_enemies_hit >= 4)
		player thread lc_killstreak_sound();

	player.tesla_enemies_hit = 0;
	player.tesla_firing = false;
}

lc_killstreak_sound()
{
	self endon("disconnect");
	self maps\_zombiemode_audio::create_and_play_dialog("kill", "tesla");
	wait 3.5;
	level clientNotify("TGH");
}

arc_damage(source_enemy, player, arc_num, params)
{
	player endon("disconnect");

	if(!isdefined(params))
		params = level.default_lightning_chain_params;
	if(!isdefined(player.tesla_network_death_choke))
		player.tesla_network_death_choke = 0;
	if(!isdefined(player.tesla_enemies_hit))
		player.tesla_enemies_hit = 0;

	/# debug_print("TESLA: Evaluating arc damage for arc: " + arc_num + " Current enemies hit: " + player.tesla_enemies_hit); #/
	lc_flag_hit(self, true);
	radius_decay = params.radius_decay * arc_num;
	origin = self GetTagOrigin("J_Head");

	if(!isdefined(origin))
		origin = self.origin;

	enemies = lc_get_enemies_in_area(origin, params.radius_start - radius_decay, player);
	wait_network_frame();
	lc_flag_hit(enemies, true);
	self thread lc_do_damage(source_enemy, arc_num, player, params);
	/# debug_print("TESLA: " + enemies.size + " enemies hit during arc: " + arc_num); #/

	for(i = 0; i < enemies.size; i++)
	{
		if(!isdefined(enemies[i]) || enemies[i] == self)
			continue;

		if(lc_end_arc_damage(arc_num + 1, player.tesla_enemies_hit, params))
		{
			lc_flag_hit(enemies[i], false);
			continue;
		}

		player.tesla_enemies_hit++;
		enemies[i] arc_damage(self, player, arc_num + 1, params);
	}
}

arc_damage_ent(player, arc_num, params)
{
	if(!isdefined(params))
		params = level.default_lightning_chain_params;
	lc_flag_hit(self, true);
	self thread lc_do_damage(self, arc_num, player, params);
}

lc_end_arc_damage(arc_num, enemies_hit_num, params)
{
	if(!isdefined(params))
		params = level.default_lightning_chain_params;

	if(arc_num >= params.max_arcs)
	{
		/# debug_print("TESLA: Ending arc. Max arcs hit"); #/
		return true;
	}

	if(enemies_hit_num >= params.max_enemies_killed)
	{
		/# debug_print("TESLA: Ending arc. Max enemies killed"); #/
		return true;
	}

	radius_decay = params.radius_decay * arc_num;

	if(params.radius_start - radius_decay <= 0)
	{
		/# debug_print("TESLA: Ending arc. Radius is less or equal to zero"); #/
		return true;
	}
	return false;
}

lc_get_enemies_in_area(origin, distance, player)
{
	/# level thread lc_debug_arc(origin, distance); #/

	distance_squared = distance * distance;
	enemies = [];

	if(!isdefined(player.tesla_enemies))
	{
		player.tesla_enemies = get_round_enemy_array();

		if(player.tesla_enemies.size > 0)
			player.tesla_enemies = get_array_of_closest(origin, player.tesla_enemies);
	}

	zombies = player.tesla_enemies;

	if(isdefined(zombies))
	{
		for(i = 0; i < zombies.size; i++)
		{
			if(!isdefined(zombies[i]))
				continue;
			if(is_true(zombies[i].lightning_chain_immune))
				continue;

			test_origin = zombies[i] GetTagOrigin("J_Head");

			if(!isdefined(test_origin))
				test_origin = zombies[i].origin;

			if(is_true(zombies[i].zombie_tesla_hit))
				continue;
			if(is_magic_bullet_shield_enabled(zombies[i]))
				continue;
			if(DistanceSquared(origin, test_origin) > distance_squared)
				continue;
			if(!BulletTracePassed(origin, test_origin, false, undefined))
				continue;

			enemies[enemies.size] = zombies[i];
		}
	}
	return enemies;
}

lc_flag_hit(enemy, hit)
{
	if(isdefined(enemy))
	{
		if(IsArray(enemy))
		{
			for(i = 0; i < enemy.size; i++)
			{
				if(isdefined(enemy[i]))
					enemy[i].zombie_tesla_hit = hit;
			}
		}
		else
			enemy.zombie_tesla_hit = hit;
	}
}

lc_do_damage(source_enemy, arc_num, player, params)
{
	player endon("disconnect");

	if(!isdefined(params))
		params = level.default_lightning_chain_params;
	if(!isdefined(self) || !IsAlive(self))
		return;

	self lc_set_death_anim();

	if(isdefined(source_enemy) && source_enemy != self)
	{
		if(player.tesla_arc_count > 3)
		{
			wait_network_frame();
			player.tesla_arc_count = 0;
		}
		player.tesla_arc_count++;
		source_enemy lc_play_arc_fx(self, params);
	}

	while(player.tesla_network_death_choke > params.network_death_choke)
	{
		/# debug_print("TESLA: Choking Tesla Damage. Dead enemies this network frame: " + player.tesla_network_death_choke); #/
		wait .05;
	}

	if(!isdefined(self) || !IsAlive(self))
		return;

	player.tesla_network_death_choke++;
	self lc_play_death_fx(arc_num, params);
	self.tesla_death = params.should_kill_enemies;
	origin = player.origin;

	if(isdefined(source_enemy) && source_enemy != self)
		origin = source_enemy.origin;
	if(!isdefined(self) || !IsAlive(self))
		return;

	if(is_true(params.should_kill_enemies))
	{
		if(isdefined(self.tesla_damage_func))
		{
			run_function(self, self.tesla_damage_func, origin, player);
			return;
		}

		self DoDamage(self.health + 666, origin, player, undefined, "MOD_UNKNOWN");

		if(!is_true(self.deathpoints_already_given))
		{
			self.deathpoints_already_given = true;
			player maps\_zombiemode_score::player_add_points("death", "", "");
		}

		/*
		if(isdefined(params.challenge_stat_name) && isdefined(player) && IsPlayer(player))
			player maps\_zm_stats::increment_challenge_stat(params.challenge_stat_name);
		*/
	}

	/*
	if(!is_true(player.tesla_powerup_dropped) && player.tesla_enemies_hit >= params.kills_for_powerup)
	{
		player.tesla_powerup_dropped = true;
		level.zombie_vars["zombie_drop_item"] = true;
		level thread maps\_zm_powerups::powerup_drop(self.origin);
	}
	*/
}

lc_play_death_fx(arc_num, params)
{
	if(!isdefined(params))
		params = level.default_lightning_chain_params;

	tag = "J_SpineUpper";
	fx = "tesla_shock";

	if(is_true(self.isdog))
		tag = "J_Spine1";

	if(isdefined(self.teslafxtag))
		tag = self.teslafxtag;
	else if(self.animname != "zombie")
		tag = "tag_origin";
	/*
	else if(self.archetype != "zombie")
		tag = "tag_origin";
	*/

	if(arc_num > 1)
		fx = "tesla_shock_secondary";
	if(!is_true(params.should_kill_enemies))
		fx = "tesla_shock_nonfatal";

	if(is_true(params.no_fx))
	{
		// NOOP:
	}
	else
	{
		maps\_zombiemode_net::network_safe_play_fx_on_tag("tesla_death_fx", 2, level._effect[fx], self, tag);
		self PlaySound("wpn_imp_tesla");
	}

	if(isdefined(self.tesla_head_gib_func) && !is_true(self.head_gibbed) && is_true(params.should_kill_enemies) && !is_true(self.no_gib))
		run_function(self, self.tesla_head_gib_func);
}

lc_play_arc_fx(target, params)
{
	if(!isdefined(params))
		params = level.default_lightning_chain_params;

	if(!isdefined(self) || !isdefined(target))
	{
		wait params.arc_travel_time;
		return;
	}

	tag = "J_SpineUpper";
	target_tag = "J_SpineUpper";

	if(is_true(self.isdog))
		tag = "J_Spine1";
	else if(self.animname != "zombie")
		tag = "tag_origin";
	/*
	else if(self.archetype != "zombie")
		tag = "tag_origin";
	*/

	if(is_true(target.isdog))
		target_tag = "J_Spine1";
	else if(target.animname != "zombie")
		target_tag = "tag_origin";
	/*
	else if(target.archetype != "zombie")
		target_tag = "tag_origin";
	*/

	origin = self GetTagOrigin(tag);
	target_origin = target GetTagOrigin(target_tag);
	distance_squared = params.min_fx_distance * params.min_fx_distance;

	if(DistanceSquared(origin, target_origin) < distance_squared)
	{
		/# debug_print("TESLA: Not playing arcing FX. Enemies too close."); #/
		return;
	}

	ent = spawn_model("tag_origin", origin);
	PlayFXOnTag(level._effect["tesla_bolt"], ent, "tag_origin");

	if(isdefined(params.arc_fx_sound))
		PlaySoundAtPosition(params.arc_fx_sound, ent.origin);

	ent MoveTo(target_origin, params.arc_travel_time);
	ent waittill("movedone");
	ent Delete();
}

lc_debug_arc(origin, distance)
{
	/#
	if(GetDvarInt(#"zombie_debug") != 3)
		return;

	start = GetTime();

	while(GetTime() < start + 3000)
	{
		DrawCylinder(origin, distance, 1);
		wait .05;
	}
	#/
}

lc_set_death_anim()
{
	if(is_true(self.isdog))
		self.a.nodeath = undefined;
	else
	{
		deathanim = self determine_tesla_death_anim();

		if(isdefined(deathanim))
			self.deathanim = deathanim;
	}

	if(is_true(self.is_traversing))
		self.deathanim = undefined;
}

determine_tesla_death_anim()
{
	if(is_true(self.has_legs))
	{
		if(isdefined(level._zombie_tesla_crawl_death) && isdefined(level._zombie_tesla_crawl_death[self.animname]))
			return random(level._zombie_tesla_crawl_death[self.animname]);
	}
	else
	{
		if(isdefined(level._zombie_tesla_death) && isdefined(level._zombie_tesla_death[self.animname]))
			return random(level._zombie_tesla_death[self.animname]);
	}
	return undefined;
}