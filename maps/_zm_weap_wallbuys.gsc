#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	spawn_wallbuys();
}

spawn_wallbuys()
{
	structs = GetStructArray("zm_weap_wallbuy", "targetname");
	convert_legacy_wallbuys();

	if(isdefined(level._zm_extra_weapon_wallbuys) && level._zm_extra_weapon_wallbuys.size > 0)
		structs = array_merge(structs, level._zm_extra_weapon_wallbuys);
	
	if(!isdefined(structs) || structs.size == 0)
		return;

	for(i = 0; i < structs.size; i++)
	{
		struct = structs[i];

		if(!isdefined(struct.origin))
			continue;
		if(!struct maps\_zm_gametype::is_zm_scr_ent_valid("wallbuys"))
			continue;
		
		origin = struct.origin;
		weapon = struct.zombie_weapon_upgrade;
		angles = (0, 0, 0);

		if(isdefined(struct.angles))
			angles = struct.angles;
		
		// Player Trigger
		stub = SpawnStruct();
		stub.origin = origin;
		stub.zombie_weapon_upgrade = weapon;
		stub.weapon = weapon;
		stub.angles = angles;
		stub.radius = 40;
		stub.height = 80;
		stub.spawn_struct = struct;
		stub.require_look_at = true;
		stub.prompt_and_visibility_func = ::playertrigger_weapon_update_trigger;
		stub.first_time_triggered = false;

		// Weapon Model
		if(isdefined(struct.model_override))
		{
			stub.model = struct.model_override;
			stub.model UseWeaponHideTags(weapon);
		}
		else
			stub.model = maps\_zm_weapons::spawn_weapon_model(weapon, origin, angles);
		
		stub.model Hide();

		if(isdefined(stub.model.lh_model))
			stub.model.lh_model Hide();

		register_playertrigger(stub, ::playertrigger_weapon_think);
	}
}

wallbuy_give_weapon(stub)
{
	weapon = stub.zombie_weapon_upgrade;
	cost = get_weapon_wallbuy_cost(self, weapon);

	if(is_melee_weapon(weapon))
	{
		if(self HasWeapon(weapon))
			return;
		
		self thread maps\_zm_melee_weapon::give_melee_weapon(weapon, true);
	}
	else
	{
		if(wallbuy_supports_ammo(weapon))
		{
			if(!self maps\_zm_weapons::give_weapon_or_ammo(weapon))
				return;
		}
		else
		{
			if(self maps\_zm_weapons::has_weapon_or_root(weapon))
			{
				ammo_given = false;

				if(is_lethal_grenade(weapon) || is_tactical_grenade(weapon))
					ammo_given = self maps\_zm_weapons::ammo_give(weapon);
				else
					ammo_given = false;
				
				if(!ammo_given)
					return;
			}
			else
				weapon = self maps\_zm_weapons::weapon_give(weapon, true);
		}
	}

	stub thread wallbuy_do_first_time_trigger(self);
	self play_sound_on_ent("purchase");
	self thread maps\_zm_weapons::play_weapon_vo(weapon);
	self maps\_zombiemode_score::minus_to_player_score(cost);
}

wallbuy_do_first_time_trigger(player)
{
	if(is_true(self.first_time_triggered))
		return;
	
	self.first_time_triggered = true;
	model = self.model;
	player_angles = VectortoAngles(player.origin - model.origin);
	player_yaw = player_angles[1];
	weapon_yaw = model.angles[1];
	yaw_diff = AngleClamp180(player_yaw - weapon_yaw);
	
	if(yaw_diff > 0)
		yaw = weapon_yaw - 90;
	else
		yaw = weapon_yaw + 90;
	
	model.og_origin = model.origin;
	model.origin = model.origin + (AnglesToForward((0, yaw, 0)) * 8);
	wait .05;
	model Show();

	if(isdefined(model.lh_model))
		model.lh_model Show();
	
	play_sound_at_pos("weapon_show", model.origin, model);
	model MoveTo(model.og_origin, 1);
}

convert_legacy_wallbuys()
{
	// Wallbuys
	triggers = GetEntArray("weapon_upgrade", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		weapon = triggers[i].zombie_weapon_upgrade;
		model = GetEnt(triggers[i].target, "targetname");

		struct = generate_wallbuy(weapon, triggers[i].origin, model.angles);
		struct.model_override = model;
		triggers[i] Delete();
	}

	// Claymore Buys
	triggers = GetEntArray("claymore_purchase", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		model = GetEnt(triggers[i].target, "targetname");

		struct = generate_wallbuy("claymore_zm", triggers[i].origin, model.angles);
		struct.model_override = model;
		triggers[i] Delete();
	}

	// Spikemore Buys
	triggers = GetEntArray("spikemore_purchase", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		model = GetEnt(triggers[i].target, "targetname");

		struct = generate_wallbuy("spikemore_zm", triggers[i].origin, model.angles);
		struct.model_override = model;
		triggers[i] Delete();
	}

	// Bowie Knife
	triggers = GetEntArray("bowie_upgrade", "targetname");

	for(i = 0; i < triggers.size; i++)
	{
		model = GetEnt(triggers[i].target, "targetname");

		struct = generate_wallbuy("bowie_knife_zm", triggers[i].origin, model.angles);
		struct.model_override = model;
		triggers[i] Delete();
	}
}

// Player Trigger
playertrigger_weapon_update_trigger(player)
{
	self SetCursorHint("HINT_NOICON");
	self.hint_param1 = undefined;
	self.hint_param2 = undefined;
	self.hint_param3 = undefined;
	self.hint_param4 = undefined;

	can_use = self playertrigger_weapon_update_stub(player);

	if(isdefined(self.hint_string))
	{
		if(isdefined(self.hint_param4))
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2, self.hint_param3, self.hint_param4);
		else if(isdefined(self.hint_param3))
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2, self.hint_param3);
		else if(isdefined(self.hint_param2))
			self SetHintString(self.hint_string, self.hint_param1, self.hint_param2);
		else if(isdefined(self.hint_param1))
			self SetHintString(self.hint_string, self.hint_param1);
		else
			self SetHintString(self.hint_string);
	}

	return can_use;
}

playertrigger_weapon_update_stub(player)
{
	if(!is_player_valid(player))
		return false;
	if(!player can_buy_weapon())
		return false;
	if(player has_powerup_weapon())
		return false;
	return self playertrigger_set_weapon_hintstring(player);
}

playertrigger_weapon_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill("trigger", player);

		cost = get_weapon_wallbuy_cost(player, self.stub.zombie_weapon_upgrade);

		if(!player can_buy_weapon())
			continue;
		if(!is_player_valid(player))
			continue;
		if(player has_powerup_weapon())
			continue;
		
		if(!player can_player_purchase(cost))
		{
			self.stub.model play_sound_on_ent("no_purchase");
			player maps\_zombiemode_audio::create_and_play_dialog("general", "no_money");
			continue;
		}

		player thread wallbuy_give_weapon(self.stub);
	}
}

playertrigger_set_weapon_hintstring(player)
{
	stub = self.stub;
	weapon = stub.zombie_weapon_upgrade;
	weapon_stats = maps\_zm_weapons::get_weapon_stats(weapon);
	
	self.hint_string = &"ZOMBIE_DYN_WEAPONCOST";
	self.hint_param1 = weapon_stats.display_name;
	self.hint_param2 = weapon_stats.cost;

	if(is_lethal_grenade(weapon) || is_tactical_grenade(weapon))
		return true;

	if(wallbuy_supports_ammo(weapon))
	{
		// show ammo cost if player has any variant of this weapon
		if(player maps\_zm_weapons::has_any_weapon_variant(weapon))
		{
			self.hint_string = &"ZOMBIE_DYN_WEAPONCOSTAMMO";
			self.hint_param3 = Int(weapon_stats.cost / level.zombie_vars["zombie_weapons_ammo_cost_fraction"]);

			// show upgrade ammo cost if
			// weapon is upgraded
			// weapon can be upgraded
			// player has upgraded variant
			if(player maps\_zm_weapons::has_weapon_upgrade(weapon) || maps\_zm_weapons::is_weapon_upgraded(weapon) || maps\_zm_weapons::can_upgrade_weapon(weapon))
			{
				self.hint_string = &"ZOMBIE_DYN_WEAPONCOSTAMMO_UPGRADE";
				self.hint_param4 = level.zombie_vars["zombie_weapons_upgrade_ammo_cost"];
			}
		}
	}
	else
	{
		if(player maps\_zm_weapons::has_any_weapon_variant(weapon))
		{
			self.hint_string = undefined;
			self.hint_param1 = undefined;
			self.hint_param2 = undefined;
			return false;
		}
	}
	return true;
}

// Utils
generate_wallbuy(weapon, origin, angles)
{
	struct = SpawnStruct();
	struct.zombie_weapon_upgrade = weapon;
	struct.origin = origin;
	struct.angles = angles;

	if(!isdefined(level._zm_extra_weapon_wallbuys))
		level._zm_extra_weapon_wallbuys = [];
	
	level._zm_extra_weapon_wallbuys[level._zm_extra_weapon_wallbuys.size] = struct;
	return struct;
}

get_weapon_wallbuy_cost(player, weapon)
{
	weapon_stats = maps\_zm_weapons::get_weapon_stats(weapon);
	cost = weapon_stats.cost;

	if(!wallbuy_supports_ammo(weapon))
		return cost;

	if(player maps\_zm_weapons::has_any_weapon_variant(weapon))
	{
		ammo_cost = Int(weapon_stats.cost / level.zombie_vars["zombie_weapons_ammo_cost_fraction"]);
		upgrade_ammo_cost = level.zombie_vars["zombie_weapons_upgrade_ammo_cost"];

		if(player maps\_zm_weapons::has_weapon_upgrade(weapon))
			return upgrade_ammo_cost;
		else
			return ammo_cost;
	}
	return cost;
}

wallbuy_supports_ammo(weapon)
{
	if(is_offhand_weapon(weapon))
		return false;
	return true;
}