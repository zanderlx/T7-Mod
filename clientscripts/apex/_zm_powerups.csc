#include clientscripts\_utility;
#include clientscripts\apex\_utility;

init()
{
	include_powerups();
	precache_powerups();
}

include_powerups()
{
	if(!isdefined(level._zm_powerup_includes))
		level._zm_powerup_includes = ::default_include_powerups;

	run_function(level, level._zm_powerup_includes);
}

precache_powerups()
{
	level._effect["powerup_green_on"] = LoadFX("misc/fx_zombie_powerup_on");
	level._effect["powerup_green_grabbed"] = LoadFX("misc/fx_zombie_powerup_grab");
	level._effect["powerup_green_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_wave");
	level._effect["powerup_red_on"] = LoadFX("misc/fx_zombie_powerup_on_red");
	level._effect["powerup_red_grabbed"] = LoadFX("misc/fx_zombie_powerup_red_grab");
	level._effect["powerup_red_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_red_wave");
	level._effect["powerup_blue_on"] = LoadFX("misc/fx_zombie_powerup_solo_on");
	level._effect["powerup_blue_grabbed"] = LoadFX("misc/fx_zombie_powerup_solo_grab");
	level._effect["powerup_blue_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_solo_wave");
	level._effect["powerup_yellow_on"] = LoadFX("misc/fx_zombie_powerup_caution_on");
	level._effect["powerup_yellow_grabbed"] = LoadFX("misc/fx_zombie_powerup_caution_grab");
	level._effect["powerup_yellow_grabbed_wave"] = LoadFX("misc/fx_zombie_powerup_caution_wave");
}

default_include_powerups()
{
	// T4
	clientscripts\apex\powerups\_zm_powerup_full_ammo::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_insta_kill::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_double_points::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_carpenter::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_nuke::include_powerup_for_level();

	// T5
	clientscripts\apex\powerups\_zm_powerup_fire_sale::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_minigun::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_bonfire_sale::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_tesla::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_bonus_points::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_free_perk::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_random_weapon::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_empty_clip::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_lose_perk::include_powerup_for_level();
	clientscripts\apex\powerups\_zm_powerup_lose_points::include_powerup_for_level();
}

//============================================================================================
// Utils
//============================================================================================
get_valid_powerup_array()
{
	if(isdefined(level._zm_valid_powerup_names_cache) && level._zm_valid_powerup_names_cache.size > 0)
		return level._zm_valid_powerup_names_cache;
	else
	{
		powerup_names = GetArrayKeys(level.zombie_powerups);
		result = [];

		for(i = 0; i < powerup_names.size; i++)
		{
			if(is_powerup_valid(powerup_names[i]))
				result[result.size] = powerup_names[i];
		}

		level._zm_valid_powerup_names_cache = result;
		return result;
	}
}

//============================================================================================
// Weapon Powerups
//============================================================================================
register_powerup_weapon(powerup_name, weapon_name)
{
	if(!isdefined(level.zombie_powerup_weapon))
		level.zombie_powerup_weapon = [];
	if(!isdefined(level.zombie_powerup_weapon[powerup_name]))
		level.zombie_powerup_weapon[powerup_name] = weapon_name;
}

is_weapon_powerup(powerup_name)
{
	if(!is_powerup_valid(powerup_name))
		return false;
	if(!is_timed_powerup(powerup_name))
		return false;
	if(!isdefined(level.zombie_powerup_weapon))
		return false;
	if(!isdefined(level.zombie_powerup_weapon[powerup_name]))
		return false;
	return level.zombie_powerup_weapon[powerup_name] != "none";
}

//============================================================================================
// Registry
//============================================================================================
is_powerup_valid(powerup_name)
{
	if(!isdefined(level.zombie_powerups))
		return false;
	if(!isdefined(level.zombie_powerups[powerup_name]))
		return false;
	return is_true(level.zombie_powerups[powerup_name].valid);
}

is_timed_powerup(powerup_name)
{
	if(!is_powerup_valid(powerup_name))
		return false;
	return is_true(level.zombie_powerups[powerup_name].is_timed_powerup);
}

_register_undefined_powerup(powerup_name)
{
	if(!isdefined(level.zombie_powerups))
		level.zombie_powerups = [];
	if(isdefined(level.zombie_powerups[powerup_name]))
		return;

	level.zombie_powerups[powerup_name] = SpawnStruct();
	level.zombie_powerups[powerup_name].valid = false;
	level.zombie_powerups[powerup_name].is_timed_powerup = false;
}

register_basic_powerup(powerup_name)
{
	_register_undefined_powerup(powerup_name);
	level.zombie_powerups[powerup_name].valid = true;
}

register_timed_powerup(powerup_name)
{
	_register_undefined_powerup(powerup_name);
	level.zombie_powerups[powerup_name].is_timed_powerup = true;
}