#include clientscripts\_utility;
#include clientscripts\apex\_utility;

init()
{
	level._client_perks = [];

	if(!isdefined(level._zm_perk_includes))
		level._zm_perk_includes = ::default_include_perks;

	run_function(level, level._zm_perk_includes);
	precache_perks();
	finalize_perk_registration();
	OnPlayerConnect_Callback(::player_connect);
}

finalize_perk_registration(perk)
{
	perks = get_valid_perks_array();

	for(i = 0; i < perks.size; i++)
	{
		add_level_notify_callback("client_give_perk_" + perks[i], ::update_perk_state, perks[i], true);
		add_level_notify_callback("client_take_perk_" + perks[i], ::update_perk_state, perks[i], false);
	}
}

player_connect(clientnum)
{
	level._client_perks[clientnum] = [];
}

default_include_perks()
{
	clientscripts\apex\perks\_zm_perk_juggernog::include_perk_for_level();
	clientscripts\apex\perks\_zm_perk_double_tap::include_perk_for_level();
	clientscripts\apex\perks\_zm_perk_sleight_of_hand::include_perk_for_level();
	clientscripts\apex\perks\_zm_perk_quick_revive::include_perk_for_level();

	clientscripts\apex\perks\_zm_perk_divetonuke::include_perk_for_level();
	clientscripts\apex\perks\_zm_perk_marathon::include_perk_for_level();
	clientscripts\apex\perks\_zm_perk_deadshot::include_perk_for_level();
	clientscripts\apex\perks\_zm_perk_additionalprimaryweapon::include_perk_for_level();

	clientscripts\apex\perks\_zm_perk_tombstone::include_perk_for_level();
	// clientscripts\apex\perks\_zm_perk_chugabud::include_perk_for_level();
	// clientscripts\apex\perks\_zm_perk_electric_cherry::include_perk_for_level();
	// clientscripts\apex\perks\_zm_perk_vulture::include_perk_for_level();

	// clientscripts\apex\perks\_zm_perk_widows_wine::include_perk_for_level();
}

precache_perks()
{
	level._effect["perk_light_yellow"]= LoadFX("misc/fx_zombie_cola_dtap_on");
	level._effect["perk_light_red"]= LoadFX("misc/fx_zombie_cola_jugg_on");
	level._effect["perk_light_blue"]= LoadFX("misc/fx_zombie_cola_revive_on");
	level._effect["perk_light_green"]= LoadFX("misc/fx_zombie_cola_on");
}

update_perk_state(clientnum, perk, state)
{
	if(is_true(state))
	{
		if(has_perk(clientnum, perk))
			return;

		level._client_perks[clientnum][level._client_perks[clientnum].size] = perk;

		if(isdefined(level._custom_perks[perk].give_func))
			single_thread(self, level._custom_perks[perk].give_func, clientnum);
	}
	else
	{
		if(has_perk(clientnum, perk))
		{
			level._client_perks[clientnum] = array_remove_nokeys(level._client_perks[clientnum], perk);

			if(isdefined(level._custom_perks[perk].take_func))
				single_thread(self, level._custom_perks[perk].take_func, clientnum);
		}
	}
}

//============================================================================================
// Utilities
//============================================================================================
get_valid_perks_array()
{
	if(isdefined(level._zm_valid_perk_array_cache))
		return level._zm_valid_perk_array_cache; // only need to build this array once
	else
	{
		result = [];

		if(isdefined(level._custom_perks))
		{
			keys = GetArrayKeys(level._custom_perks);

			for(i = 0; i < level._custom_perks.size; i++)
			{
				if(is_perk_valid(keys[i]))
					result[result.size] = keys[i];
			}
		}

		level._zm_valid_perk_array_cache = result;
		return result;
	}
}

get_perk_from_speciality(specialty)
{
	perks = get_valid_perks_array();

	for(i = 0; i < perks.size; i++)
	{
		if(!isdefined(level._custom_perks[perks[i]].specialties) || level._custom_perks[perks[i]].specialties.size == 0)
			continue;
		if(IsInArray(level._custom_perks[perks[i]].specialties, specialty))
			return perks[i];
	}
	return undefined;
}

//============================================================================================
// Registry
//============================================================================================
is_perk_valid(perk)
{
	if(!isdefined(level._custom_perks))
		return false;
	if(!isdefined(level._custom_perks[perk]))
		return false;
	return is_true(level._custom_perks[perk].valid);
}

_register_undefined_perk(perk)
{
	if(!isdefined(level._custom_perks))
		level._custom_perks = [];
	if(isdefined(level._custom_perks[perk]))
		return;

	level._custom_perks[perk] = SpawnStruct();
}

register_perk(perk)
{
	_register_undefined_perk(perk);

	level._custom_perks[perk].valid = true;
}

add_perk_specialty(perk, specialty)
{
	_register_undefined_perk(perk);

	if(!isdefined(level._custom_perks[perk].specialties))
		level._custom_perks[perk].specialties = [];
	if(!IsInArray(level._custom_perks[perk].specialties, specialty))
		level._custom_perks[perk].specialties[level._custom_perks[perk].specialties.size] = specialty;
}

register_perk_threads(perk, give_func, take_func)
{
	_register_undefined_perk(perk);
	level._custom_perks[perk].give_func = give_func;
	level._custom_perks[perk].take_func = take_func;
}