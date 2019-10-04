#include clientscripts\_utility;
#include clientscripts\_zm_utility;

init()
{
	if(!isdefined(level._zm_include_perks))
		level._zm_include_perks = ::default_include_perks;
	
	register_client_system("_zm_perks", ::perk_system_monitor);
	run_function(level, level._zm_include_perks);
}

default_include_perks()
{
	// T4
	clientscripts\perks\_zm_perk_juggernog::include_perk_for_level();
	clientscripts\perks\_zm_perk_double_tap::include_perk_for_level();
	clientscripts\perks\_zm_perk_quick_revive::include_perk_for_level();
	clientscripts\perks\_zm_perk_sleight_of_hand::include_perk_for_level();

	// T5
	clientscripts\perks\_zm_perk_divetonuke::include_perk_for_level();
	clientscripts\perks\_zm_perk_marathon::include_perk_for_level();
	clientscripts\perks\_zm_perk_deadshot::include_perk_for_level();
	clientscripts\perks\_zm_perk_additionalprimaryweapon::include_perk_for_level();

	// T6
	clientscripts\perks\_zm_perk_tombstone::include_perk_for_level();
	clientscripts\perks\_zm_perk_chugabud::include_perk_for_level();
	// clientscripts\perks\_zm_perk_electric_cherry::include_perk_for_level();
	// clientscripts\perks\_zm_perk_vulture_aid::include_perk_for_level();
	
	// T7
	// clientscripts\perks\_zm_perk_widows_wine::include_perk_for_level();

	// T8
}

// Client System
perk_system_monitor(clientnum, state, oldState)
{
	tokens = StrTok(state, ",");
	perk = tokens[0];
	perk_state = Int(tokens[1]);

	set_player_perk_state(clientnum, perk, perk_state);
}

// Utils
get_player_perk_state(clientnum, perk)
{
	if(!isdefined(level._zm_player_perks))
		level._zm_player_perks = [];
	if(!isdefined(level._zm_player_perks[clientnum]))
		level._zm_player_perks[clientnum] = [];
	if(!isdefined(level._zm_player_perks[clientnum][perk]))
		level._zm_player_perks[clientnum][perk] = 0;
	return level._zm_player_perks[clientnum][perk];
}

set_player_perk_state(clientnum, perk, state)
{
	current_state = get_player_perk_state(clientnum, perk);

	if(current_state != state)
	{
		level._zm_player_perks[clientnum][perk] = state;

		switch(state)
		{
			case 0: // Unobtained
				if(isdefined(level._custom_perks[perk].thread_take))
					single_thread(level._custom_perks[perk].thread_take, clientnum);
				break;

			case 1: // Obtained
				if(isdefined(level._custom_perks[perk].thread_give))
					single_thread(level._custom_perks[perk].thread_give, clientnum);
				break;

			case 2: // Paused
				if(isdefined(level._custom_perks[perk].thread_pause))
					single_thread(level._custom_perks[perk].thread_pause, clientnum);
				break;
			
			case 3: // Unpaused
				if(isdefined(level._custom_perks[perk].thread_unpause))
					single_thread(level._custom_perks[perk].thread_unpause, clientnum);
				break;
		}
	}
}

// Registry
register_perk(perk, thread_give, thread_take, thread_pause, thread_unpause)
{
	if(!isdefined(level._custom_perks))
		level._custom_perks = [];
	if(isdefined(level._custom_perks[perk]))
		return;
	
	struct = SpawnStruct();
	struct.thread_give = thread_give;
	struct.thread_take = thread_take;
	struct.thread_pause = thread_pause;
	struct.thread_unpause = thread_unpause;

	level._custom_perks[perk] = struct;
}