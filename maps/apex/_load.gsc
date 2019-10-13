#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

main()
{
	maps\apex\_utility_code::init_apex_utility();
	/# maps\apex\_debug::debug_init(); #/
	level thread solo_game_init();
	maps\apex\_zm_weapons::init();
	maps\apex\_zm_magicbox::init();
	maps\apex\_zm_powerups::init();
	maps\apex\_zm_power::init();
	maps\apex\_zm_perks::init();
	maps\apex\_zm_packapunch::init();
	level thread power_off_zones_init();
	OnPlayerConnect_Callback(::onPlayerSpawned);
}

//============================================================================================
// Callbacks
//============================================================================================
_AddCallback(type, func)
{
	if(!isdefined(level._callbacks))
		level._callbacks = [];
	if(!isdefined(level._callbacks[type]))
		level._callbacks[type] = [];

	maps\_callbackglobal::AddCallback(type, func);
}

_RemoveCallback(type, func)
{
	if(isdefined(level._callbacks) && isdefined(level._callbacks[type]))
		maps\_callbackglobal::RemoveCallback(type, func);
}

_Callback(type)
{
	if(!isdefined(level._callbacks))
		return;
	if(!isdefined(level._callbacks[type]))
		return;
	if(level._callbacks[type].size == 0)
		return;

	self maps\_callbackglobal::Callback(type);
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		self _Callback("on_player_spawned");
	}
}

//============================================================================================
// Solo Game
//============================================================================================
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
// Disables zones when power is turned off
// if the only flag for the zone is 'power_on'
// if zone has more than 1 activation flag
// we assume it can be accesed by other means then just the power activating
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
	flags = []; // array for flags seperated by zone name, built from all ajacent zones

	for(i = 0; i < zone_names.size; i++)
	{
		zone_name = zone_names[i];
		zone = level.zones[zone_name];
		// /# level thread zone_debug(zone_name); #/

		if(!isdefined(zone.adjacent_zones) || zone.adjacent_zones.size == 0)
			continue;

		adjacent_zone_names = GetArrayKeys(zone.adjacent_zones);

		for(j = 0; j < adjacent_zone_names.size; j++)
		{
			adjacent_zone_name = adjacent_zone_names[j];
			adjacent_zone = zone.adjacent_zones[adjacent_zone_name];

			if(!isdefined(flags[adjacent_zone_name]))
				flags[adjacent_zone_name] = [];
			if(isdefined(adjacent_zone.flags) && adjacent_zone.flags.size > 0)
				flags[adjacent_zone_name] = array_merge(flags[adjacent_zone_name], adjacent_zone.flags);
		}
	}

	for(i = 0; i < zone_names.size; i++)
	{
		zone_name = zone_names[i];

		if(isdefined(flags[zone_name]) && flags[zone_name].size == 1 && flags[zone_name][0] == "power_on")
			level._zm_power_off_zone_names[level._zm_power_off_zone_names.size] = zone_name;
	}

	// level thread power_zone_debug();
}

power_zone_debug()
{
	/#
	flag_wait("begin_spawning");

	for(;;)
	{
		maps\apex\_debug::DrawStringList((0, 0, 100), level._zm_power_off_zone_names, (1, 1, 1));
		wait .05;
	}
	#/
}

zone_debug(zone_name)
{
	/#
	flag_wait("begin_spawning");

	mins = (-16, -16, -16);
	maxs = (16, 16, 16);

	zone = level.zones[zone_name];

	list = array("Zone: " + zone_name);

	if(IsInArray(level._zm_power_off_zone_names, zone_name))
		list[list.size] = "Power Off Zone: TRUE";
	else
		list[list.size] = "Power Off Zone: FALSE";

	if(isdefined(zone.adjacent_zones) && zone.adjacent_zones.size > 0)
	{
		list[list.size] = "";
		list[list.size] = "Adjacent Zones:";
		adjacent_zone_names = GetArrayKeys(zone.adjacent_zones);

		for(i = 0; i < adjacent_zone_names.size; i++)
		{
			adjacent_zone_name = adjacent_zone_names[i];
			adjacent_zone = zone.adjacent_zones[adjacent_zone_name];
			list[list.size] = "    " + adjacent_zone_name;

			if(isdefined(adjacent_zone.flags) && adjacent_zone.flags.size > 0)
			{
				str = "        flags: ";

				for(j = 0; j < adjacent_zone.flags.size; j++)
				{
					str += adjacent_zone.flags[j];

					if(j + 1 < adjacent_zone.flags.size)
						str += ", ";
				}

				list[list.size] = str;
			}
		}
	}

	for(;;)
	{
		wait .05;
		player = GetPlayers()[0];

		if(!isdefined(player))
			continue;

		zone = level.zones[zone_name];

		if(isdefined(zone.volumes))
		{
			for(i = 0; i < zone.volumes.size; i++)
			{
				origin = zone.volumes[i].origin;

				if(!within_fov(player.origin, player.angles, origin, Cos(65)))
					continue;

				Box(origin, mins, maxs, 0, (1, 1, 1));
				maps\apex\_debug::DrawStringList(origin, list, (1, 1, 1));
			}
		}
	}
	#/
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

	spawn_points = GetStructArray("player_respawn_point", "targetname");
	entry_points = GetStructArray(zone_name + "_barriers", "targetname");
	players = GetPlayers(); // maps\_zombiemode_zone_manager::get_players_in_zone(zone_name); // returns amount of players not array of players
	zombies = get_round_enemy_array();

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

	for(i = 0; i < zombies.size; i++)
	{
		if(!isdefined(zombies[i]) || !IsAlive(zombies[i]))
			continue;
		if(!zombies[i] maps\_zombiemode_zone_manager::entity_in_zone(zone_name))
			continue;

		// zombie in disabled zone
		// kill and respawn the zombie
		if(is_true(level.put_timed_out_zombies_back_in_queue) && !flag("dog_round"))
		{
			if(!zombies[i].ignoreall && !is_true(zombies[i].nuked) && !is_true(zombies[i].marked_for_death))
				level.zombie_total++;
		}

		level.zombies_timeout_playspace++;
		zombies[i] DoDamage(zombies[i].maxhealth + 1, (0, 0, 0));
	}

	if(isdefined(players) && players.size > 0)
	{
		for(i = 0; i < players.size; i++)
		{
			if(!isdefined(players[i]) || players[i].sessionstate == "spectator")
				continue;
			if(!players[i] maps\_zombiemode_zone_manager::entity_in_zone(zone_name))
				continue;
			if(is_true(players[i].inteleportation))
				continue;

			origin = players[i].spectator_respawn.origin;
			angles = players[i].spectator_respawn.angles;

			new_origin = undefined;

			if(isdefined(level.check_valid_spawn_override))
				new_origin = run_function(players[i], level.check_valid_spawn_override, players[i]);
			if(!isdefined(new_origin))
				new_origin = players[i] maps\_zombiemode::check_for_valid_spawn_near_team(players[i]);
			if(isdefined(new_origin))
				origin = new_origin;

			players[i] DontInterpolate();
			players[i] SetOrigin(origin);
			players[i] SetPlayerAngles(angles);
			players[i] thread short_god_mode();
		}
	}

	level.zones[zone_name].is_enabled = false; // disable last so entity_in_zone can return true
}

short_god_mode()
{
	self endon("disconnect");
	self endon("death");
	self endon("fake_death");
	self EnableInvulnerability();
	wait 3.5;
	self DisableInvulnerability();
}