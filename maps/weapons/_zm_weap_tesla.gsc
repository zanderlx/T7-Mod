#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	if(!maps\_zm_weapons::is_weapon_included("tesla_gun_zm"))
		return;

	level._effect["tesla_viewmodel_rail"] = LoadFX("maps/zombie/fx_zombie_tesla_rail_view");
	level._effect["tesla_viewmodel_tube"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view");
	level._effect["tesla_viewmodel_tube2"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view2");
	level._effect["tesla_viewmodel_tube3"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view3");
	level._effect["tesla_viewmodel_rail_upgraded"] = LoadFX("maps/zombie/fx_zombie_tesla_rail_view_ug");
	level._effect["tesla_viewmodel_tube_upgraded"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view_ug");
	level._effect["tesla_viewmodel_tube2_upgraded"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view2_ug");
	level._effect["tesla_viewmodel_tube3_upgraded"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view3_ug");

	level.tesla_lightning_params = maps\_zm_lightning_chain::create_lightning_chain_params(
		5, // max_arcs
		10, // max_enemies_killed
		300, // radius_start
		20, // radius_decay
		75, // head_gib_chance
		.11, // arc_travel_time
		10, // kills_for_powerup
		128, // min_fx_distance
		4, // network_death_choke
		undefined, // should_kill_enemies
		"wpn_tesla_bounce" // arc_fx_sound
	);

	PrecacheShellShock("electrocution");

	maps\_zombiemode_spawner::register_zombie_damage_callback(::tesla_zombie_damage_response); // TODO: zombiemode damage override callback
	OnPlayerSpawned_Callback(::on_player_spawned);
}

is_tesla_gun(weapon)
{
	return weapon == "tesla_gun_zm" || weapon == "tesla_gun_upgraded_zm";
}

is_tesla_damage(mod, weapon)
{
	return is_tesla_gun(weapon) && maps\_zm_lightning_chain::is_lightning_chain_damage(mod);
}

on_player_spawned()
{
	self thread tesla_sound_thread();
	self thread tesla_pvp_thread();
}

tesla_sound_thread()
{
	self endon("disconnect");

	for(;;)
	{
		result = self waittill_any_return("grenade_fire", "death", "player_downed", "weapon_change", "grenade_pullout", "disconnect");
		weapon = self GetCurrentWeapon();

		if(!isdefined(result))
			continue;

		if((result == "weapon_change" || result == "grenade_fire") && is_tesla_gun(weapon))
		{
			if(!isdefined(self.tesla_loop_sound))
			{
				self.tesla_loop_sound = Spawn("script_origin", self.origin);
				self.tesla_loop_sound LinkTo(self);
				self thread cleanup_loop_sound(self.tesla_loop_sound);
			}

			self.tesla_loop_sound PlayLoopSound("wpn_tesla_idle", .25);
			self thread tesla_engine_sweets();
		}
		else
		{
			self notify("weap_away");

			if(isdefined(self.tesla_loop_sound))
				self.tesla_loop_sound StopLoopSound(.25);
		}
	}
}

cleanup_loop_sound(loop_sound)
{
	self waittill("disconnect");

	if(isdefined(loop_sound))
		loop_sound Delete();
}

tesla_engine_sweets()
{
	self endon("disconnect");
	self endon("weap_away");

	for(;;)
	{
		wait RandomIntRange(7, 15);
		self play_tesla_sound("wpn_tesla_sweeps_idle");
	}
}

tesla_pvp_thread()
{
	self endon("disconnect");
	self endon("death");

	for(;;)
	{
		self waittill("weapon_pvp_attack", attacker, weapon, damage, mod);

		if(self maps\_laststand::player_is_in_laststand())
			continue;
		if(!is_tesla_damage(mod, weapon))
			continue;

		if(self == attacker)
		{
			damage = Max(Int(self.maxhealth * .25), 25);

			if(self.health - damage < 1)
				self.health = 1;
			else
				self.health -= damage;
		}

		self SetElectrified(true);
		self ShellShock("electrocution", 1);
		self PlaySound("wpn_tesla_bounce");
	}
}

play_tesla_sound(emotion)
{
	self endon("disconnect");

	if(!isdefined(level.one_emo_at_a_time))
		level.one_emo_at_a_time = false;
	if(!isdefined(level.var_counter))
		level.var_counter = 0;

	if(is_true(level.one_emo_at_a_time))
	{
		level.var_counter++;
		level.one_emo_at_a_time = true;
		str_notify = "sound_complete_" + level.var_counter;
		org = Spawn("script_origin", self.origin);
		org LinkTo(self);
		org PlaySoundWithNotify(emotion, str_notify);
		org waittill(str_notify);
		org Delete();
		level.one_emo_at_a_time = false;
	}
}

tesla_zombie_damage_response(mod, hit_location, hit_origin, player, amount)
{
	if(isdefined(self.damageweapon))
		weapon = self.damageweapon;
	else
		weapon = player GetCurrentWeapon();

	if(is_tesla_damage(mod, weapon))
	{
		self thread maps\_zm_lightning_chain::damage_init(player, level.tesla_lightning_params);
		return true;
	}
	return false;
}