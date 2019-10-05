#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

#using_animtree("generic_human");

include_perk_for_level()
{
	maps\_zm_perks::register_perk("cherry", "uie_moto_perk_cherry", "zombie_perk_bottle_cherry_t7");
	maps\_zm_perks::register_perk_machine("cherry", 2000, &"ZOMBIE_PERK_ELECTRICCHERRY", "jb_zm_vending_electric_cherry", "jb_zm_vending_electric_cherry_on", "cherry_light", "mus_perks_cherry_sting", "mus_perks_cherry_jingle");
	maps\_zm_perks::register_perk_threads("cherry", ::give_cherry, ::take_chery, ::take_chery, ::give_cherry);

	level._effect["cherry_light"] = LoadFX("misc/fx_zombie_cola_on");
	level._effect["electric_cherry_explode"] = LoadFX("sanchez/electric_cherry/cherry_shock_death");
	level._effect["electric_cherry_reload_small"] = LoadFX("sanchez/electric_cherry/cherry_shock_small");
	level._effect["electric_cherry_reload_medium"] = LoadFX("sanchez/electric_cherry/cherry_shock_medium");
	level._effect["electric_cherry_reload_large"] = LoadFX("sanchez/electric_cherry/cherry_shock_large");

	level.zombiemode_using_electriccherry_perk = true;
	// level.electric_cherry_stun = array(%ai_zombie_afterlife_stun_a, %ai_zombie_afterlife_stun_b, %ai_zombie_afterlife_stun_c, %ai_zombie_afterlife_stun_d, %ai_zombie_afterlife_stun_e);

	OnPlayerLastStand_Callback(::on_laststand);
}

give_cherry()
{
	self thread electric_cherry_reload_attack();
}

take_chery()
{
	self notify("stop_electric_cherry_reload_attack");
}

electric_cherry_death_fx()
{
	self electric_cherry_ai_fx("tesla_death_fx", "tesla_shock", true);
}

electric_cherry_shock_fx()
{
	self electric_cherry_ai_fx("tesla_shock_fx", "tesla_shock_secondary", false);
}

electric_cherry_ai_fx(fx_type, fx_name, allow_gibbing)
{
	self endon("death");

	tag = "J_SpineUpper";

	if(is_true(self.isdog))
		tag = "J_Spine1";

	self PlaySound("wpn_imp_tesla");
	maps\_zombiemode_net::network_safe_play_fx_on_tag(fx_type, 2, level._effect[fx_name], self, tag);

	if(is_true(self.head_gibbed) || is_true(self.no_gib))
		allow_gibbing = false;
	if(is_true(allow_gibbing) && isdefined(self.tesla_head_gib_func))
		run_function(self, self.tesla_head_gib_func);
}

electric_cherry_stun()
{
	self endon("death");
	self notify("stun_zombie");
	self endon("stun_zombie");

	if(self.health <= 0)
		return;
	if(!is_true(self.has_legs))
		return;
	if(self.animname != "zombie")
		return;
	if(is_true(self.ignoreme))
		return;

	self notify("stop_find_flesh");

	for(i = 0; i < 2; i++)
	{
		self AnimScripted("stunned", self.origin, self.angles, random(level.electric_cherry_stun));
		self animscripts\zombie_shared::DoNoteTracks("stunned");
	}
	self thread maps\_zombiemode_spawner::find_flesh();
}

electric_cherry_reload_attack()
{
	self endon("disconnect");
	self endon("stop_electric_cherry_reload_attack");

	self.wait_on_reload = [];
	self.consecutive_electric_cherry_attacks = 0;

	for(;;)
	{
		self waittill("reload_start");
		weapon = self GetCurrentWeapon();

		if(IsInArray(self.wait_on_reload, weapon))
			continue;

		self.wait_on_reload[self.wait_on_reload.size] = weapon;
		self.consecutive_electric_cherry_attacks++;
		clip_count = self GetWeaponAmmoClip(weapon);
		clip_max = WeaponClipSize(weapon);
		fraction = clip_count / clip_max;
		perk_radius = linear_map(fraction, 1, 0, 32, 128);
		perk_damage = linear_map(fraction, 1, 0, 1, 1045);
		self thread check_for_reload_complete(weapon);

		switch(self.consecutive_electric_cherry_attacks)
		{
			case 1:
				zombie_limit = undefined;
				break;

			case 2:
				zombie_limit = 8;
				break;

			case 3:
				zombie_limit = 4;
				break;

			case 4:
				zombie_limit = 2;
				break;

			default:
				zombie_limit = 0;
				break;
		}

		self thread electric_cherry_cooldown_timer(weapon);
		self thread electric_cherry_do_damage(fraction, undefined, perk_radius, perk_damage, zombie_limit);
	}
}

electric_cherry_cooldown_timer(weapon)
{
	self notify("electric_cherry_cooldown_started");
	self endon("electric_cherry_cooldown_started");
	self endon("disconnect");

	reload_time = WeaponReloadTime(weapon);

	if(self has_perk("sleight"))
		reload_time *= GetDvarFloat("perk_weapReloadMultiplier");

	wait reload_time + 3;
	self.consecutive_electric_cherry_attacks = 0;
}

check_for_reload_complete(weapon)
{
	self endon("disconnect");
	self endon("cherry_player_lost_weapon_" + weapon);

	self thread weapon_replaced_monitor(weapon);

	for(;;)
	{
		self waittill("reload");

		current_weapon = self GetCurrentWeapon();

		if(weapon == current_weapon)
		{
			self.wait_on_reload = ArrayRemoveValue(self.wait_on_reload, weapon, false);
			self notify("cherry_weapon_reload_complete_" + weapon);
			return;
		}
	}
}

weapon_replaced_monitor(weapon)
{
	self endon("disconnect");
	self endon("cherry_weapon_reload_complete_" + weapon);

	for(;;)
	{
		self waittill("weapon_change");

		weapons = self GetWeaponsListPrimaries();

		if(!IsInArray(weapons, weapon))
		{
			self notify("cherry_player_lost_weapon_" + weapon);
			self.wait_on_reload = ArrayRemoveValue(self.wait_on_reload, weapon, false);
			return;
		}
	}
}

electric_cherry_reload_fx(fraction, laststand_effect)
{
	if(is_true(laststand_effect))
	{
		shock_fx = "electric_cherry_explode";
		self levelNotify("cherry_fx_death");
	}
	else if(fraction >= .67)
	{
		shock_fx = "electric_cherry_reload_small";
		self levelNotify("cherry_fx_small");
	}
	else if(fraction >= .33 && fraction < .67)
	{
		shock_fx = "electric_cherry_reload_medium";
		self levelNotify("cherry_fx_medium");
	}
	else
	{
		shock_fx = "electric_cherry_reload_large";
		self levelNotify("cherry_fx_large");
	}

	model = spawn_model("tag_origin", self.origin, self.angles);
	model SetInvisibleToAll();
	model SetVisibleToPlayer(self);
	model thread electric_cherry_link_reload_fx(self);
	PlayFXOnTag(level._effect[shock_fx], model, "tag_origin");
	self waittill_notify_or_timeout("disconnect", 1);
	self levelNotify("cherru_fx_cancel");
	model notify("electric_cherry_reload_fx_over");
	model Delete();
}

electric_cherry_link_reload_fx(player)
{
	self endon("death");
	self endon("delete");
	self endon("electric_cherry_reload_fx_over");
	player endon("disconnect");

	for(;;)
	{
		self.origin = player GetTagOrigin("tag_origin");
		self.angles = player GetTagAngles("tag_origin");
		wait .05;
	}
}

electric_cherry_do_damage(fraction, laststand_effect, radius, damage, zombie_limit)
{
	if(!isdefined(fraction))
		fraction = 1;
	if(!isdefined(radius))
		radius = 500;
	if(!isdefined(damage))
		damage = 1000;
	if(isdefined(zombie_limit) && zombie_limit <= 0)
		return;

	self thread electric_cherry_reload_fx(fraction, laststand_effect);
	self PlaySound("zmb_cherry_explode");
	wait .05;
	a_zombies = get_array_of_closest(self.origin, GetAISpeciesArray("axis", "all"), undefined, undefined, radius);
	zombies_hit = 0;

	for(i = 0; i < a_zombies.size; i++)
	{
		if(isdefined(a_zombies[i]) && IsAlive(a_zombies[i]))
		{
			if(a_zombies[i].health <= damage)
			{
				a_zombies[i] thread electric_cherry_death_fx();
				self maps\_zombiemode_score::add_to_player_score(40);
			}
			else
			{
				a_zombies[i] thread electric_cherry_stun();
				a_zombies[i] thread electric_cherry_shock_fx();
			}

			wait .1;

			a_zombies[i] DoDamage(damage, self.origin, self, self);
			zombies_hit++;

			if(isdefined(zombie_limit) && zombies_hit >= zombie_limit)
				break;
		}
	}
}

on_laststand()
{
	if(isdefined(level.custom_cherry_laststand_func))
		single_thread(self, level.custom_cherry_laststand_func);
	else
		self thread electric_cherry_do_damage(1, true);
}