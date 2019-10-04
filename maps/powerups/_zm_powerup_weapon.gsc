#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

/*
	How to use

		call `maps\powerups\_zm_powerup_weapon::set_powerup_weapon_name(<powerup_name>, <weapon_name>);` with usual powerup registration

		call `[player] maps\powerups\_zm_powerup_weapon::powerup_weapon_on(<powerup_name>);` when your timed powerup starts
		call `[player] maps\powerups\_zm_powerup_weapon::powerup_weapon_off(<powerup_name>);` when your timed powerup stops

		To manually remove a powerup weapon
			call `maps\powerups\_zm_powerup_weapon::remove_powerup_weapon(<powerup_name>);`

		Optional but reccomended
			Add the following to your powerups 'can_drop' function, This ensures that the powerup only drops when it has a weapon assigned
			```
			if(!maps\powerups\_zm_powerup_weapon::func_can_drop_powerup_weapon(<powerup_name>))
				return false;
			```

		`maps\powerups\_zm_powerup_weapon::init();` does not have to be called, but can be called from your powerup registration

		See minigun for a example powerup using this system
*/

init()
{
	if(!isdefined(level._zombie_minigun_powerup_last_stand_func))
		level._zombie_minigun_powerup_last_stand_func = ::powerup_weapon_gunner_downed;
	if(!isdefined(level.zombie_vars["zombie_powerup_weapon_allow_weapon_switch"]))
		set_zombie_var("zombie_powerup_weapon_allow_weapon_switch", true);
}

remove_powerup_weapon(powerup)
{
	time_name = level.zombie_powerups[powerup].time_name;

	if(is_true(level.zombie_powerups[powerup].per_player))
		self.zombie_vars[time_name] = 0;
	else
		level.zombie_vars[time_name] = 0;
}

set_powerup_weapon_name(powerup, weapon)
{
	init();

	if(!isdefined(level._zm_powerup_weapons))
		level._zm_powerup_weapons = [];

	PrecacheItem(weapon);
	level._zm_powerup_weapons[powerup] = weapon;
	maps\_zm_powerups::set_weapon_ignore_max_ammo(weapon);
}

is_powerup_weapon(weapon)
{
	if(isdefined(level._zm_powerup_weapons))
	{
		keys = GetArrayKeys(level._zm_powerup_weapons);

		for(i = 0; i < keys.size; i++)
		{
			if(level._zm_powerup_weapons[keys[i]] == weapon)
				return true;
		}
	}
	return false;
}

func_can_drop_powerup_weapon(powerup)
{
	return isdefined(level._zm_powerup_weapons) && isdefined(level._zm_powerup_weapons[powerup]);
}

powerup_weapon_on(powerup)
{
	if(!func_can_drop_powerup_weapon(powerup))
		return;

	if(self has_powerup_weapon())
	{
		if(self._current_powerup_weapon == powerup)
			return;

		remove_powerup_weapon(self._current_powerup_weapon);
		wait_network_frame();
		wait_network_frame();
	}

	self.has_powerup_weapon = true;
	self._current_powerup_weapon = powerup;
	self increment_is_drinking();

	if(is_true(level.zombie_vars["zombie_powerup_weapon_allow_weapon_switch"]))
		self EnableWeaponCycling();
	else
		self DisableWeaponCycling();

	self._zombie_gun_before_powerup_weapon = self GetCurrentWeapon();
	self maps\_zm_weapons::give_buildkit_weapon(level._zm_powerup_weapons[powerup]);
	self SwitchToWeapon(level._zm_powerup_weapons[powerup]);

	if(is_true(level.zombie_vars["zombie_powerup_weapon_allow_weapon_switch"]))
		self thread powerup_weapon_change(powerup);

	self thread powerup_weapon_cleanup(powerup);
}

powerup_weapon_off(powerup)
{
	if(self has_powerup_weapon() && self._current_powerup_weapon == powerup)
		self notify("powerup_weapon_timedout");
}

powerup_weapon_change(powerup)
{
	self endon("disconnect");
	self endon("player_downed");
	self endon("powerup_weapon_cleanup");
	self endon("replace_weapon_powerup");

	for(;;)
	{
		self waittill("weapon_change", new_weapon, old_weapon);

		if(new_weapon != "none" && new_weapon != level._zm_powerup_weapons[powerup])
			break;
	}

	self notify("replace_weapon_powerup");
}

powerup_weapon_cleanup(powerup)
{
	result = self waittill_any_return("disconnect", "player_downed", "replace_weapon_powerup", "powerup_weapon_cleanup", "powerup_weapon_timedout");

	if(result != "powerup_weapon_cleanup")
		self notify("powerup_weapon_cleanup");

	remove_powerup_weapon(powerup);

	if(result == "disconnect")
		return;

	self TakeWeapon(level._zm_powerup_weapons[powerup]);

	if(result != "player_downed")
	{
		self maps\_zm_weapons::switch_back_primary_weapon(self._zombie_gun_before_powerup_weapon);
		self decrement_is_drinking();
	}

	self.has_powerup_weapon = false;
	self._current_powerup_weapon = undefined;
	self._zombie_gun_before_powerup_weapon = undefined;
}

powerup_weapon_gunner_downed()
{
	if(self has_powerup_weapon())
		self powerup_weapon_off(self._current_powerup_weapon);
}