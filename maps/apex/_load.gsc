#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

main()
{
	maps\apex\_utility_code::init_apex_utility();
	/# maps\apex\_debug::debug_init(); #/
	level thread solo_game_init();
	maps\apex\_zm_power::init();
	maps\apex\_zm_perks::init();
	level thread power_off_zones_init();
}

//============================================================================================
// Solo Game
//===========================================================================================
solo_game_init()
{
	flag_init("solo_game", is_solo_game());
	flag_init("_start_zm_pistol_rank", false);
	flag_wait("all_players_connected");

	if(flag("solo_game"))
	{
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			players[i].lives = 0;
		}

		maps\_zombiemode::zombiemode_solo_last_stand_pistol();
	}

	flag_set("_start_zm_pistol_rank");
}

//============================================================================================
// Zone Powerable
//
// Disables any zones with the 'power_on' flag when power is disabled
//===========================================================================================
power_off_zones_init()
{
	maps\apex\_zm_power::add_powerable(false, undefined, ::zones_power_off);

	while(!flag_exists("zones_initialized"))
	{
		wait .05;
	}

	flag_wait("zones_initialized");

	zone_names = GetArrayKeys(level.zones);
	level._zm_power_off_zone_names = [];

	for(i = 0; i < zone_names.size; i++)
	{
		zone_name = zone_names[i];
		zone = level.zones[zone_name];

		if(!isdefined(zone.adjacent_zones) || zone.adjacent_zones.size == 0)
			continue;

		adjacent_zone_names = GetArrayKeys(zone.adjacent_zones);

		for(j = 0; j < adjacent_zone_names.size; j++)
		{
			adjacent_zone_name = adjacent_zone_names[j];
			adjacent_zone = zone.adjacent_zones[adjacent_zone_name];

			if(IsInArray(adjacent_zone.flags, "power_on"))
			{
				level._zm_power_off_zone_names[level._zm_power_off_zone_names.size] = zone_name;
				break;
			}
		}
	}
}

zones_power_off()
{
	for(i = 0; i < level._zm_power_off_zone_names.size; i++)
	{
		level thread disable_zone(level._zm_power_off_zone_names[i]);
	}
}

disable_zone(zone_name)
{
	if(!is_true(level.zones[zone_name].is_enabled))
		return;

	level.zones[zone_name].is_enabled = false;
	spawn_points = GetStructArray("player_respawn_point", "targetname");
	entry_points = GetStructArray(zone_name + "_barriers", "targetname");

	for(i = 0; i < spawn_points.size; i++)
	{
		if(isdefined(spawn_points[i].script_noteworthy) && spawn_points[i].script_noteworthy == zone_name)
			spawn_points[i].locked = true;
	}

	for(i = 0; i < entry_points.size; i++)
	{
		entry_points[i].is_active = false;
		entry_points[i] trigger_off();
	}
}