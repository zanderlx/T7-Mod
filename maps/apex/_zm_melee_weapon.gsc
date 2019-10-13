#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	level._melee_weapons = [];

	set_zombie_var("zombie_melee_weapon_default", "knife_zm");
	set_zombie_var("zombie_melee_weapon_default_fallback", "fallback_zm");
}

load_melee_weapon(melee_weapon)
{
	// 0           1             2               3
	// melee_weapon,flourish_name,ballistic_name,fallback_name
	melee_weapon_table = "gamedata/weapons/melee_weapons.csv";
	/# PrintLn("Loading melee weapon '" + melee_weapon + "' (" + melee_weapon_table + ")"); #/

	test = TableLookup(melee_weapon_table, 0, melee_weapon, 0);

	if(!isdefined(test) || test != melee_weapon)
		return;

	flourish_name = TableLookup(melee_weapon_table, 0, melee_weapon, 1);
	ballistic_name = TableLookup(melee_weapon_table, 0, melee_weapon, 2);
	fallback_name = TableLookup(melee_weapon_table, 0, melee_weapon, 3);

	if(!isdefined(flourish_name) || flourish_name == "")
		flourish_name = "none";
	if(!isdefined(ballistic_name) || ballistic_name == "")
		ballistic_name = "none";
	if(!isdefined(fallback_name) || fallback_name == "")
		fallback_name = "none";

	struct = SpawnStruct();
	struct.weapon = melee_weapon;
	struct.flourish_name = flourish_name;
	struct.ballistic_name = ballistic_name;
	struct.fallback_name = fallback_name;

	if(flourish_name != "none")
		PrecacheItem(flourish_name);
	if(fallback_name != "none")
		PrecacheItem(fallback_name);

	register_melee_weapon_for_level(melee_weapon);
	level._melee_weapons[level._melee_weapons.size] = struct;
}

find_melee_weapon(weapon)
{
	if(isdefined(level._melee_weapons) && level._melee_weapons.size > 0)
	{
		for(i = 0; i < level._melee_weapons.size; i++)
		{
			if(level._melee_weapons[i].weapon == weapon)
				return level._melee_weapons[i];
		}
	}
	return undefined;
}

change_melee_weapon(weapon, current_weapon)
{
	had_fallback_weapon = self take_fallback_weapon();
	current_melee_weapon = self get_player_melee_weapon();

	if(current_melee_weapon != "none" && current_melee_weapon != weapon)
		self maps\apex\_zm_weapons::weapon_take(current_melee_weapon);

	self set_player_melee_weapon(weapon);
	had_ballistic = false;
	had_ballistic_upgraded = false;
	ballistic_was_primary = false;
	primaryWeapons = self GetWeaponsListPrimaries();

	for(i = 0; i < primaryWeapons.size; i++)
	{
		if(is_ballistic_knife(primaryWeapons[i]))
		{
			if(primaryWeapons[i] == current_weapon)
				ballistic_was_primary = true;
			if(maps\apex\_zm_weapons::is_weapon_upgraded(primaryWeapons[i]))
				had_ballistic_upgraded = true;

			had_ballistic = true;
			self maps\apex\_zm_weapons::weapon_take(primaryWeapons[i]);
		}
	}

	if(had_ballistic)
	{
		new_ballistic = self give_ballistic_knife(weapon, had_ballistic_upgraded);

		if(ballistic_was_primary)
			current_weapon = new_ballistic;

		self maps\apex\_zm_weapons::give_weapon(new_ballistic);
	}

	if(had_fallback_weapon)
		self give_fallback_weapon();
	return current_weapon;
}

give_melee_weapon(weapon)
{
	melee_weapon = find_melee_weapon(weapon);

	if(!isdefined(melee_weapon) || melee_weapon.flourish_name == "none")
	{
		IPrintLnBold("could not find flourish weapon");
		return;
	}

	original_weapon = self do_melee_weapon_flourish_begin(melee_weapon.flourish_name);
	self maps\apex\_zm_weapons::play_weapon_vo(weapon, false);
	self waittill_any("fake_death", "death", "player_downed", "weapon_change_complete");
	self do_melee_weapon_flourish_end(original_weapon, melee_weapon.flourish_name, weapon);
}

//============================================================================================
// Fallback Weapon
//============================================================================================
determine_fallback_weapon()
{
	weapon = self get_player_melee_weapon();
	melee_weapon = find_melee_weapon(weapon);

	if(isdefined(melee_weapon) && melee_weapon.fallback_name != "none")
		return melee_weapon.fallback_name;
	return level.zombie_vars["zombie_melee_weapon_default_fallback"];
}

give_fallback_weapon()
{
	fallback_name = self determine_fallback_weapon();
	self maps\apex\_zm_weapons::give_weapon(fallback_name);
	self SwitchToWeapon(fallback_name);
}

take_fallback_weapon()
{
	fallback_name = self determine_fallback_weapon();
	had_weapon = self HasWeapon(fallback_name);
	self maps\apex\_zm_weapons::weapon_take(fallback_name);
	return had_weapon;
}

//============================================================================================
// Ballistic Knife
//============================================================================================
has_any_ballistic_knife()
{
	primaryWeapons = self GetWeaponsListPrimaries();

	for(i = 0; i < primaryWeapons.size; i++)
	{
		if(is_ballistic_knife(primaryWeapons[i]))
			return true;
	}
	return false;
}

has_upgraded_ballistic_knife()
{
	primaryWeapons = self GetWeaponsListPrimaries();

	for(i = 0; i < primaryWeapons.size; i++)
	{
		if(is_ballistic_knife(primaryWeapons[i]) && maps\apex\_zm_weapons::is_weapon_upgraded(primaryWeapons[i]))
			return true;
	}
	return false;
}

give_ballistic_knife(weapon, upgraded)
{
	current_melee_weapon = self get_player_melee_weapon();
	melee_weapon = find_melee_weapon(current_melee_weapon);

	if(isdefined(melee_weapon) && melee_weapon.ballistic_name != "none")
	{
		weapon = melee_weapon.ballistic_name;

		if(is_true(upgraded))
			weapon = maps\apex\_zm_weapons::get_upgrade_weapon(weapon);
	}
	return weapon;
}

is_ballistic_knife(weapon)
{
	if(isdefined(level._melee_weapons) && level._melee_weapons.size > 0)
	{
		for(i = 0; i < level._melee_weapons.size; i++)
		{
			ballistic_name = level._melee_weapons[i].ballistic_name;

			if(ballistic_name == "none")
				continue;
			if(ballistic_name == weapon)
				return true;

			upgrade_name = maps\apex\_zm_weapons::get_upgrade_weapon(ballistic_name);

			if(upgrade_name == "none" || upgrade_name == ballistic_name)
				continue;
			if(weapon == upgrade_name)
				return true;
		}
	}
	return false;
}

//============================================================================================
// Flourish
//============================================================================================
do_melee_weapon_flourish_begin(flourish_name)
{
	self increment_is_drinking();
	self disable_player_move_states(true);
	original_weapon = self GetCurrentWeapon();
	self maps\apex\_zm_weapons::give_weapon(flourish_name);
	self SwitchToWeapon(flourish_name);
	return original_weapon;
}

do_melee_weapon_flourish_end(original_weapon, flourish_name, weapon)
{
	self enable_player_move_states();
	self maps\apex\_zm_weapons::weapon_take(flourish_name);

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	self maps\apex\_zm_weapons::give_weapon(weapon);
	original_weapon = self change_melee_weapon(weapon, original_weapon);
	self maps\apex\_zm_weapons::weapon_take(level.zombie_vars["zombie_melee_weapon_default"]);

	if(self is_multiple_drinking())
	{
		self decrement_is_drinking();
		return;
	}
	else if(original_weapon == level.zombie_vars["zombie_melee_weapon_default"])
	{
		self SwitchToWeapon(weapon);
		self decrement_is_drinking();
		return;
	}
	else if(original_weapon != level.zombie_vars["zombie_melee_weapon_default"] && !is_placeable_mine(original_weapon) && !is_equipment(original_weapon))
		self maps\apex\_zm_weapons::switch_back_primary_weapon(original_weapon);
	else
		self maps\apex\_zm_weapons::switch_back_primary_weapon();

	self waittill("weapon_change_complete");

	if(!self maps\_laststand::player_is_in_laststand() || !is_true(self.intermission))
		self decrement_is_drinking();
}

is_flourish_weapon(weapon)
{
	if(isdefined(level._melee_weapons) && level._melee_weapons.size > 0)
	{
		for(i = 0; i < level._melee_weapons.size; i++)
		{
			if(level._melee_weapons[i].flourish_name != "none" && level._melee_weapons[i].flourish_name == weapon)
				return true;
		}
	}
	return false;
}