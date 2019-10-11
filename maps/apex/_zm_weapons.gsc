#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	level._zombie_custom_add_weapons = ::custom_add_weapons;
	OnPlayerSpawned_Callback(::player_spawned);
}

custom_add_weapons()
{
	level.zombie_weapons_upgraded = [];
	keys = GetArrayKeys(level.zombie_weapons);

	for(i = 0; i < keys.size; i++)
	{
		weapon = keys[i];

		if(isdefined(level.zombie_weapons[weapon].upgrade_name))
			level.zombie_weapons_upgraded[level.zombie_weapons[weapon].upgrade_name] = weapon;
	}
}

//============================================================================================
// Grenade Duds
//============================================================================================
player_spawned()
{
	self thread watchForGrenadeDuds();
	self thread watchForGrenadeLauncherDuds();
	self.staticWeaponStartTime = GetTime();
}

watchForGrenadeDuds()
{
	self endon("spawned_player");
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_fire", grenade, weapon);

		if(!is_equipment(weapon) && !is_placeable_mine(weapon))
		{
			grenade thread checkForGrenadeDud(weapon, true, self);
			grenade thread watchForScriptExplosion(weapon, true, self);
		}
	}
}

watchForGrenadeLauncherDuds()
{
	self endon("spawned_player");
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_launcher_fire", grenade, weapon);
		grenade thread checkForGrenadeDud(weapon, false, self);
		grenade thread watchForScriptExplosion(weapon, false, self);
	}
}

grenade_safe_to_throw(player, weapon)
{
	if(isdefined(level.grenade_safe_to_throw))
		return run_function(self, level.grenade_safe_to_throw, player, weapon);
	return true;
}

grenade_safe_to_bounce(player, weapon)
{
	if(isdefined(level.grenade_safe_to_bounce))
		return run_function(self, level.grenade_safe_to_bounce, player, weapon);
	return true;
}

makeGrenadeDudAndDestroy()
{
	self endon("death");
	self notify("grenade_dud");
	// self MakeGrenadeDud();
	wait 3;

	if(isdefined(self))
		self Delete();
}

checkForGrenadeDud(weapon, isThrownGrenade, player)
{
	self endon("death");
	player endon("zombify");

	if(!self grenade_safe_to_throw(player, weapon))
	{
		self thread makeGrenadeDudAndDestroy();
		return;
	}

	for(;;)
	{
		self waittill_any_or_timeout(.25, "grenade_bounce", "stationary");

		if(!self grenade_safe_to_bounce(player, weapon))
		{
			self thread makeGrenadeDudAndDestroy();
			return;
		}
	}
}

wait_explode()
{
	self endon("grenade_dud");
	self endon("done");
	self waittill("explode", origin);
	level.explode_position = origin;
	level.explode_position_valid = true;
	self notify("done");
}

wait_timeout(time)
{
	self endon("grenade_dud");
	self endon("done");
	wait time;
	self notify("done");
}

wait_for_explosion(time)
{
	level.explode_position = (0, 0, 0);
	level.explode_position_valid = false;
	self thread wait_explode();
	self thread wait_timeout(time);
	self waittill("done");
	self notify("death_or_explode", level.explode_position, level.explode_position_valid);
}

watchForScriptExplosion(weapon, isThrownGrenade, player)
{
	self endon("grenade_dud");

	if(is_lethal_grenade(weapon) /*|| is_grenade_launcher(weapon)*/)
	{
		self thread wait_for_explosion(20);
		self waittill("death_or_explode", origin, exploded);

		if(is_true(exploded))
			level notify("grenade_exploded", origin, 256, 300, 75);
	}
}

//============================================================================================
// Utils
//============================================================================================
get_nonalternate_weapon(altWeapon)
{
	if(WeaponInventoryType(altWeapon) == "altmode")
		return WeaponAltWeaponName(altWeapon);
	return altWeapon;
}

swicth_from_alt_weapon(current_weapon)
{
	alt = get_nonalternate_weapon(current_weapon);

	if(alt != current_weapon)
	{
		self SwitchToWeapon(alt);
		self waittill_any_or_timeout(1, "weapon_change_complete");
		return alt;
	}
	return current_weapon;
}

switch_back_primary_weapon(oldPrimary)
{
	if(self maps\_laststand::player_is_in_laststand())
		return;

	if(!isdefined(oldPrimary) || oldPrimary == "none" || /*maps\_zm_melee_weapon::is_flourish_weapon(oldPrimary) ||*/ is_melee_weapon(oldPrimary) || is_placeable_mine(oldPrimary) || is_lethal_grenade(oldPrimary) || is_tactical_grenade(oldPrimary) || !self HasWeapon(oldPrimary))
		oldPrimary = undefined;

	primaryWeapons = self GetWeaponsListPrimaries();

	if(isdefined(oldPrimary) && IsInArray(primaryWeapons, oldPrimary))
		self SwitchToWeapon(oldPrimary);
	else if(primaryWeapons.size > 0)
		self SwitchToWeapon(primaryWeapons[0]);
}

is_weapon_included(weapon_name)
{
	if(!isdefined(level.zombie_weapons))
		return false;
	return isdefined(level.zombie_weapons[weapon_name]);
}

is_weapon_or_base_included(weapon_name)
{
	if(!isdefined(level.zombie_weapons))
		return false;
	if(is_weapon_included(weapon_name))
		return true;

	base = get_base_weapon(weapon_name);
	return is_weapon_included(base);
}

get_base_weapon(upgradedweapon)
{
	upgradedweapon = get_nonalternate_weapon(upgradedweapon);

	if(isdefined(level.zombie_weapons_upgraded[upgradedweapon]))
		return level.zombie_weapons_upgraded[upgradedweapon];
	return upgradedweapon;
}

get_upgrade_weapon(weapon, add_attachment)
{
	weapon = get_nonalternate_weapon(weapon);
	weapon = ToLower(weapon);
	newWeapon = weapon;

	if(!is_weapon_upgraded(weapon))
		newWeapon = level.zombie_weapons[weapon].upgrade_name;
	return newWeapon;
}

can_upgrade_weapon(weaponname)
{
	if(!isdefined(weaponname) || weaponname == "")
		return false;

	weaponname = ToLower(weaponname);
	weaponname = get_nonalternate_weapon(weaponname);

	if(!is_weapon_upgraded(weaponname))
		return isdefined(level.zombie_weapons[weaponname].upgrade_name);
	return false;
}

is_weapon_upgraded(weaponname)
{
	if(!isdefined(weaponname) || weaponname == "")
		return false;

	weaponname = ToLower(weaponname);
	weaponname = get_nonalternate_weapon(weaponname);

	if(isdefined(level.zombie_weapons_upgraded[weaponname]))
		return true;
	return false;
}

has_upgrade(weaponname)
{
	has_upgrade = false;

	if(isdefined(level.zombie_weapons[weaponname]) && isdefined(level.zombie_weapons[weaponname].upgrade_name))
		has_upgrade = self HasWeapon(level.zombie_weapons[weaponname].upgrade_name);
	if(!has_upgrade && weaponname == "knife_ballistic_zm") // maps\_zm_melee_weapon::has_any_ballistic_knife_upgraded()
		has_upgrade = self has_upgrade("knife_ballistic_bowie_zm") || self has_upgrade("knife_ballistic_sickle_zm");
	return has_upgrade;
}

has_weapon_or_upgrade(weaponname)
{
	has_weapon = false;

	if(is_weapon_included(weaponname))
		has_weapon = self HasWeapon(weaponname) || self has_upgrade(weaponname);
	if(!has_weapon && weaponname == "knife_ballistic_zm") // maps\_zm_melee_weapon::has_any_ballistic_knife()
		has_weapon = self has_weapon_or_upgrade("knife_ballistic_bowie_zm") || self has_weapon_or_upgrade("knife_ballistic_sickle_zm");
	return has_weapon;
}

can_buy_weapon()
{
	if(isdefined(self.is_drinking) && self is_drinking())
		return false;
	if(self hacker_active())
		return false;

	current_weapon = self GetCurrentWeapon();

	if(is_placeable_mine(current_weapon) || is_equipment(current_weapon))
		return false;
	if(self in_revive_trigger())
		return false;
	if(current_weapon == "none")
		return false;
	return true;
}

weapon_is_dual_wield(name)
{
	return WeaponDualWieldWeaponName(name) != "none";
}

get_left_hand_weapon_model_name(name)
{
	return GetWeaponModel(WeaponDualWieldWeaponName(name));
}

get_pack_a_punch_weapon_options(weapon)
{
	if(!isdefined(self.pack_a_punch_weapon_options_default))
		self.pack_a_punch_weapon_options_default = self CalcWeaponOptions(0);
	if(!isdefined(self.pack_a_punch_weapon_options))
		self.pack_a_punch_weapon_options = [];
	if(isdefined(self.pack_a_punch_weapon_options[weapon]))
		return self.pack_a_punch_weapon_options[weapon];

	if(!is_weapon_upgraded(weapon))
	{
		self.pack_a_punch_weapon_options[weapon] = self.pack_a_punch_weapon_options_default;
		return self.pack_a_punch_weapon_options[weapon];
	}

	reticle_index = RandomIntRange(0, 21);
	reticle_color_index = RandomIntRange(0, 6);

	if(weapon == "famas_upgraded_zm")
		reticle_index = 21;
	else
	{
		if(RandomInt(10) < 3)
			reticle_index = 0;
	}

	if(reticle_index == 8)
		reticle_color_index = 3;
	if(reticle_index == 2)
		reticle_color_index = 6;
	if(reticle_index == 7)
		reticle_color_index = 1;
	if(reticle_index == 22)
		reticle_color_index = 6;

	self.pack_a_punch_weapon_options[weapon] = self CalcWeaponOptions(15, RandomIntRange(0, 6), reticle_index, reticle_color_index);
	return self.pack_a_punch_weapon_options[weapon];
}

//============================================================================================
// Give
//============================================================================================
weapon_give(weapon, magic_box, nosound)
{
	primaryWeapons = self GetWeaponsListPrimaries();
	initial_current_weapon = self GetCurrentWeapon();
	current_weapon = self swicth_from_alt_weapon(initial_current_weapon);
	weapon_limit = self get_player_weapon_limit();

	if(is_equipment(weapon))
		self maps\_zombiemode_equipment::equipment_give(weapon);

	if(self HasWeapon(weapon))
	{
		if(IsSubStr(weapon, "knife_ballistic_"))
			self notify("zmb_lost_knife");

		self GiveStartAmmo(weapon);

		if(!is_offhand_weapon(weapon))
			self SwitchToWeapon(weapon);

		return weapon;
	}

	if(is_lethal_grenade(weapon))
	{
		old_lethal = self get_player_lethal_grenade();

		if(old_lethal != "none")
			self TakeWeapon(old_lethal);

		self set_player_lethal_grenade(weapon);
	}
	else if(is_tactical_grenade(weapon))
	{
		old_tactical = self get_player_tactical_grenade();

		if(old_tactical != "none")
			self TakeWeapon(old_tactical);

		self set_player_tactical_grenade(weapon);
	}
	else if(is_placeable_mine(weapon))
	{
		old_mine = self get_player_placeable_mine();

		if(old_mine != "none")
			self TakeWeapon(old_mine);

		self set_player_placeable_mine(weapon);
	}

	if(primaryWeapons.size >= weapon_limit)
	{
		if(is_placeable_mine(current_weapon) || is_equipment(current_weapon))
			current_weapon = undefined;

		if(isdefined(current_weapon))
		{
			if(!is_offhand_weapon(current_weapon))
			{
				if(IsSubStr(current_weapon, "knife_ballistic_"))
					self notify("zmb_lost_knife");
				self TakeWeapon(current_weapon);
			}
		}
	}

	if(isdefined(level.zombiemode_offhand_weapon_give_override))
	{
		if(run_function(self, level.zombiemode_offhand_weapon_give_override, weapon))
			return weapon;
	}

	if(weapon == "knife_ballistic_zm" && self HasWeapon("bowie_knife_zm"))
		weapon = "knife_ballistic_bowie_zm";
	else if(weapon == "knife_ballistic_zm" && self HasWeapon("sickle_knife_zm"))
		weapon = "knife_ballistic_sickle_zm";
	else if(is_placeable_mine(weapon))
	{
		self thread maps\_zombiemode_claymore::claymore_setup();

		if(!is_true(nosound))
			self play_weapon_vo(weapon, magic_box);

		return weapon;
	}

	if(isdefined(level.zombie_weapons_callbacks) && isdefined(level.zombie_weapons_callbacks[weapon]))
	{
		single_thread(self, level.zombie_weapons_callbacks[weapon]);

		if(!is_true(nosound))
			self play_weapon_vo(weapon, magic_box);

		return weapon;
	}

	if(!is_true(nosound))
		self play_sound_on_ent("purchase");

	self GiveWeapon(weapon, 0, self get_pack_a_punch_weapon_options(weapon));
	self GiveStartAmmo(weapon);

	if(!is_offhand_weapon(weapon))
	{
		if(!is_melee_weapon(weapon))
			self SwitchToWeapon(weapon);
		else
			self SwitchToWeapon(current_weapon);
	}

	if(!is_true(nosound))
		self play_weapon_vo(weapon, magic_box);
	return weapon;
}

ammo_give(weapon)
{
	give_ammo = false;

	if(is_offhand_weapon(weapon))
	{
		if(self has_weapon_or_upgrade(weapon))
		{
			if(self GetAmmoCount(weapon) < WeaponMaxAmmo(weapon))
				give_ammo = true;
		}
	}
	else
	{
		stock_max = WeaponStartAmmo(weapon);
		clip_count = self GetWeaponAmmoClip(weapon);
		current_stock = self GetAmmoCount(weapon);

		if(current_stock - clip_count >= stock_max)
			give_ammo = false;
		else
			give_ammo =true;
	}

	if(give_ammo)
	{
		self play_sound_on_ent("purchase");
		self GiveMaxAmmo(weapon);

		alt_weap = WeaponAltWeaponName(weapon);

		if(alt_weap != "none")
			self GiveMaxAmmo(alt_weap);
	}
	return give_ammo;
}

//============================================================================================
// Weapon VOX
//============================================================================================
play_weapon_vo(weapon, magic_box)
{
	if(isdefined(level._audio_custom_weapon_check))
		type = run_function(self, level._audio_custom_weapon_check, weapon);
	else
		type = self weapon_type_check(weapon);

	self thread maps\_zombiemode_audio::create_and_play_dialog("weapon_pickup", type);
}

weapon_type_check( weapon )
{
	switch(self get_player_index())
	{
		case 0:
			if(weapon == "m16_zm")
				return "favorite";
			else if(weapon == "rottweil72_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 1:
			if(weapon == "fnfal_zm")
				return "favorite";
			else if(weapon == "hk21_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 2:
			if(weapon == "china_lake_zm")
				return "favorite";
			else if(weapon == "thundergun_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 3:
			if(weapon == "mp40_zm")
				return "favorite";
			else if(weapon == "crossbow_explosive_upgraded_zm")
				return "favorite_upgrade";
			break;
	}

	if(is_weapon_upgraded(weapon))
		return "upgrade";
	else
		return level.zombie_weapons[weapon].vox;
}

get_player_index()
{
	return self.entity_num;
}

//============================================================================================
// Weapon Data
//============================================================================================
get_player_weapondata(weapon)
{
	weapondata = [];

	if(isdefined(weapon))
		weapondata["name"] = weapon;
	else
		weapondata["name"] = self GetCurrentWeapon();

	weapondata["dw_name"] = WeaponDualWieldWeaponName(weapondata["name"]);
	weapondata["alt_name"] = WeaponAltWeaponName(weapondata["name"]);

	if(weapondata["name"] == "none")
	{
		weapondata["clip"] = 0;
		weapondata["stock"] = 0;
	}
	else
	{
		weapondata["clip"] = self GetWeaponAmmoClip(weapondata["name"]);
		weapondata["stock"] = self GetWeaponAmmoStock(weapondata["name"]);
	}

	if(weapondata["dw_name"] == "none")
		weapondata["lh_clip"] = 0;
	else
		weapondata["lh_clip"] = self GetWeaponAmmoClip(weapondata["dw_name"]);

	if(weapondata["alt_name"] == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = self GetWeaponAmmoClip(weapondata["alt_name"]);
		weapondata["alt_stock"] = self GetWeaponAmmoStock(weapondata["alt_name"]);
	}
	return weapondata;
}

weapondata_give(weapondata)
{
	self weapon_give(weapondata["name"], false, true);

	self SetWeaponAmmoStock(weapondata["name"], weapondata["stock"]);
	self SetWeaponAmmoClip(weapondata["name"], weapondata["clip"]);

	if(weapondata["dw_name"] != "none")
		self SetWeaponAmmoClip(weapondata["dw_name"], weapondata["lh_clip"]);

	if(weapondata["alt_name"] != "none")
	{
		self SetWeaponAmmoStock(weapondata["alt_name"], weapondata["alt_stock"]);
		self SetWeaponAmmoClip(weapondata["alt_name"], weapondata["alt_clip"]);
	}
}