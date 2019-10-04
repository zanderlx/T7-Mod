#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	level._melee_weapons = [];
	set_zombie_var("zombie_melee_default", "knife_zm");
	PrecacheItem(level.zombie_vars["zombie_melee_default"]);
}

load_melee_weapon(melee_weapon)
{
	// 0           1             2
	// melee_weapon,flourish_name,ballistic_name
	melee_weapon_table = "weapons/melee_weapons.csv";
	/# PrintLn("Loading melee weapon '" + melee_weapon + "' (" + melee_weapon_table + ")"); #/

	test = TableLookup(melee_weapon_table, 0, melee_weapon, 0);

	if(!isdefined(test) || test != melee_weapon)
		return;
	
	flourish_name = TableLookup(melee_weapon_table, 0, melee_weapon, 1);
	ballistic_name = TableLookup(melee_weapon_table, 0, melee_weapon, 2);

	if(!isdefined(flourish_name) || flourish_name == "")
		flourish_name = "none";
	if(!isdefined(ballistic_name) || ballistic_name == "")
		ballistic_name = "none";
	
	struct = SpawnStruct();
	struct.flourish_name = flourish_name;
	struct.ballistic_name = ballistic_name;

	if(flourish_name != "none")
		PrecacheItem(flourish_name);
	
	// Ballistic knives should get precached with normal weapon loading
	/*
	if(flourish_name != "none")
		PrecacheItem(ballistic_name);
	*/

	level._melee_weapons[melee_weapon] = struct;
}

get_melee_weapon(melee_weapon)
{
	if(is_melee_weapon(melee_weapon))
		return level._melee_weapons[melee_weapon];
	return undefined;
}

change_melee_weapon(melee_weapon, current_weapon)
{
	current_melee_weapon = self get_player_melee_weapon();

	if(current_melee_weapon != melee_weapon)
		self TakeWeapon(current_melee_weapon);
	
	self set_player_melee_weapon(melee_weapon);

	had_ballistic = false;
	had_ballistic_upgraded = false;
	ballistic_was_primary = false;
	weapons = self GetWeaponsListPrimaries();

	for(i = 0; i < weapons.size; i++)
	{
		if(is_ballistic_knife(weapons[i]))
		{
			had_ballistic = true;

			if(weapons[i] == current_weapon)
				ballistic_was_primary = true;
			
			self notify("zmb_lost_knife");
			self TakeWeapon(weapons[i]);

			if(maps\_zm_weapons::is_weapon_upgraded(weapons[i]))
				had_ballistic_upgraded = true;
		}
	}

	if(had_ballistic)
	{
		ballistic_name = self determine_ballistic_knife(had_ballistic_upgraded);

		if(isdefined(ballistic_name) && ballistic_name != "none")
		{
			self maps\_zm_weapons::give_buildkit_weapon(ballistic_name);
			current_weapon = ballistic_name;
		}
	}

	return current_weapon;
}

give_melee_weapon(melee_weapon, do_flourish)
{
	if(is_true(do_flourish))
	{
		flourish_name = get_flourish_weapon(melee_weapon);
		original_weapon = self do_melee_weapon_flourish_begin(melee_weapon, flourish_name);
		self waittill_any("fake_death", "death", "player_downed", "weapon_change_complete");
		self do_melee_weapon_flourish_end(original_weapon, flourish_name, melee_weapon);
	}

	self maps\_zm_weapons::weapon_give(melee_weapon, false);
}

// Flourish
get_flourish_weapon(melee_weapon)
{
	if(is_ballistic_knife(melee_weapon))
		melee_weapon = get_ballistic_root_knife(melee_weapon);
	
	data = get_melee_weapon(melee_weapon);
	Assert(isdefined(data));
	return data.flourish_name;
}

do_melee_weapon_flourish_begin(melee_weapon, flourish_name)
{
	self increment_is_drinking();
	self disable_player_move_states(true);
	original_weapon = self GetCurrentWeapon();
	weapon_options = self maps\_zm_weapons::get_weapon_options(melee_weapon);
	self GiveWeapon(flourish_name, 0, weapon_options);
	self SwitchToWeapon(flourish_name);
	return original_weapon;
}

do_melee_weapon_flourish_end(original_weapon, flourish_name, melee_weapon)
{
	self enable_player_move_states();
	self TakeWeapon(flourish_name);

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;
	
	self maps\_zm_weapons::give_buildkit_weapon(melee_weapon);
	original_weapon = self change_melee_weapon(melee_weapon, original_weapon);

	if(self HasWeapon(level.zombie_vars["zombie_melee_default"]))
		self TakeWeapon(level.zombie_vars["zombie_melee_default"]);
	
	if(is_multiple_drinking())
	{
		self decrement_is_drinking();
		return;
	}
	else if(original_weapon == level.zombie_vars["zombie_melee_default"])
	{
		self SwitchToWeapon(melee_weapon);
		self decrement_is_drinking();
		return;
	}
	else if(original_weapon != level.zombie_vars["zombie_melee_default"] && !is_placeable_mine(original_weapon) && !is_equipment(original_weapon))
		self maps\_zm_weapons::switch_back_primary_weapon(original_weapon);
	else
		self maps\_zm_weapons::switch_back_primary_weapon();
	
	self waittill("weapon_change_complete");
	
	if(!self maps\_laststand::player_is_in_laststand() && !is_true(self.intermission))
		self decrement_is_drinking();
}

// Ballistic Knife
determine_ballistic_knife(upgraded)
{
	current_melee_weapon = self get_player_melee_weapon();
	data = get_melee_weapon(current_melee_weapon);
	Assert(isdefined(data));

	if(isdefined(data.ballistic_name) && data.ballistic_name != "none")
	{
		if(is_true(upgraded))
			return maps\_zm_weapons::get_weapon_upgrade_name(data.ballistic_name);
		return data.ballistic_name;
	}
	return "none";
}

get_ballistic_root_knife(melee_weapon)
{
	for(i = 0; i < level.zombie_melee_weapon_list.size; i++)
	{
		data = get_melee_weapon(level.zombie_melee_weapon_list[i]);
		Assert(isdefined(data));

		if(data.ballistic_name == melee_weapon)
			return level.zombie_melee_weapon_list[i];
	}
	return "none";
}

has_any_ballistic_knife()
{
	weapons = self GetWeaponsListPrimaries();

	for(i = 0; i < weapons.size; i++)
	{
		if(is_ballistic_knife(weapons[i]))
			return true;
	}
	return false;
}

has_upgraded_ballistic_knife()
{
	weapons = self GetWeaponsListPrimaries();

	for(i = 0; i < weapons.size; i++)
	{
		if(is_ballistic_knife(weapons[i]) && maps\_zm_weapons::is_weapon_upgraded(weapons[i]))
			return true;
	}
	return false;
}

give_ballistic_knife(melee_weapon)
{
	upgraded = maps\_zm_weapons::is_weapon_upgraded(melee_weapon);
	ballistic_name = self determine_ballistic_knife(upgraded);

	if(isdefined(ballistic_name) && ballistic_name != "none")
		return ballistic_name;
	return melee_weapon;
}