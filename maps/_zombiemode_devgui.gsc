#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;


/#

init()
{
	SetDvar( "zombie_devgui", "" );
	SetDvar( "scr_zombie_round", "1" );
	SetDvar( "scr_zombie_dogs", "1" );

	level thread zombie_devgui_think();
}


zombie_devgui_think()
{
	for ( ;; )
	{
		cmd = GetDvar( #"zombie_devgui" );

		switch ( cmd )
		{
		case "money":
			players = get_players();
			array_thread( players, ::zombie_devgui_give_money );
			if ( players.size > 1 )
			{
				for ( i=0; i<level.team_pool.size; i++ )
				{
					level.team_pool[i].score += 100000;
					level.team_pool[i].old_score += 100000;
					level.team_pool[i] maps\_zombiemode_score::set_team_score_hud();
				}
			}
			break;

		case "round":
			zombie_devgui_goto_round( GetDvarInt( #"scr_zombie_round" ) );
			break;
		case "round_next":
			zombie_devgui_goto_round( level.round_number + 1 );
			break;
		case "round_prev":
			zombie_devgui_goto_round( level.round_number - 1 );
			break;

		case "monkey_round":
			zombie_devgui_monkey_round();
			break;

		case "thief_round":
			zombie_devgui_thief_round();
			break;

		case "dog_round":
			zombie_devgui_dog_round( GetDvarInt( #"scr_zombie_dogs" ) );
			break;

		case "dog_round_skip":
			zombie_devgui_dog_round_skip();
			break;

		case "print_variables":
			zombie_devgui_dump_zombie_vars();
			break;

		case "revive_all":
			zombie_devgui_revive_all();
			break;

		case "power_on":
			flag_set( "power_on" );
			Objective_State(8,"done");
			break;

		case "power_off":
			flag_clear("power_on");
			break;

		case "director_easy":
			zombie_devgui_director_easy();
			break;

		case "open_sesame":
			zombie_devgui_open_sesame();
			break;

		case "disable_kill_thread_toggle":
			zombie_devgui_disable_kill_thread_toggle();
			break;

		case "check_kill_thread_every_frame_toggle":
			zombie_devgui_check_kill_thread_every_frame_toggle();
			break;

		//case "zombie_airstrike":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_artillery":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_napalm":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_helicopter":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_turret":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_portal":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_dogs":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_rcbomb":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_cloak":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;
		//
		//case "zombie_endurance":
		//	array_thread( get_players(), ::zombie_devgui_give_ability, cmd );
		//	break;

		case "":
			break;

		default:
			if ( IsDefined( level.custom_devgui ) )
			{
				[[level.custom_devgui]]( cmd );
			}
			else
			{
				//iprintln( "Unknown devgui command: '" + cmd + "'" );
			}
			break;
		}

		SetDvar( "zombie_devgui", "" );
		wait( 0.5 );
	}
}


zombie_devgui_open_sesame()
{
	setdvar("zombie_unlock_all",1);

	//turn on the power first
	flag_set( "power_on" );

	//give everyone money
	players = get_players();
	array_thread( players, ::zombie_devgui_give_money );

	//get all the door triggers and trigger them
	// DOORS ----------------------------------------------------------------------------- //
	zombie_doors = GetEntArray( "zombie_door", "targetname" );

	for( i = 0; i < zombie_doors.size; i++ )
	{
		zombie_doors[i] notify("trigger",players[0]);
		wait(.05);
	}

	// AIRLOCK DOORS ----------------------------------------------------------------------------- //
	zombie_airlock_doors = GetEntArray( "zombie_airlock_buy", "targetname" );

	for( i = 0; i < zombie_airlock_doors.size; i++ )
	{
		zombie_airlock_doors[i] notify("trigger",players[0]);
		wait(.05);
	}

	// DEBRIS ---------------------------------------------------------------------------- //
	zombie_debris = GetEntArray( "zombie_debris", "targetname" );

	for( i = 0; i < zombie_debris.size; i++ )
	{
		zombie_debris[i] notify("trigger",players[0]);
		wait(.05);
	}

	wait( 1 );
	setdvar( "zombie_unlock_all", 0 );
}

zombie_devgui_give_money()
{
	assert( IsDefined( self ) );
	assert( IsPlayer( self ) );
	assert( IsAlive( self ) );

	level.devcheater = 1;

	self maps\_zombiemode_score::add_to_player_score( 100000 );
}

zombie_devgui_goto_round( target_round )
{
	player = get_players()[0];

	if ( target_round < 1 )
	{
		target_round = 1;
	}

	level.devcheater = 1;

	level.zombie_total = 0;
	maps\_zombiemode::ai_calculate_health( target_round );
	level.round_number = target_round - 1;

	level notify( "kill_round" );

	// fix up the hud
// 	if( IsDefined( level.chalk_hud2 ) )
// 	{
// 		level.chalk_hud2 maps\_zombiemode_utility::destroy_hud();
//
// 		if ( level.round_number < 11 )
// 		{
// 			level.chalk_hud2 = maps\_zombiemode::create_chalk_hud( 64 );
// 		}
// 	}
//
// 	if ( IsDefined( level.chalk_hud1 ) )
// 	{
// 		level.chalk_hud1 maps\_zombiemode_utility::destroy_hud();
// 		level.chalk_hud1 = maps\_zombiemode::create_chalk_hud();
//
// 		switch( level.round_number )
// 		{
// 		case 0:
// 		case 1:
// 			level.chalk_hud1 SetShader( "hud_chalk_1", 64, 64 );
// 			break;
// 		case 2:
// 			level.chalk_hud1 SetShader( "hud_chalk_2", 64, 64 );
// 			break;
// 		case 3:
// 			level.chalk_hud1 SetShader( "hud_chalk_3", 64, 64 );
// 			break;
// 		case 4:
// 			level.chalk_hud1 SetShader( "hud_chalk_4", 64, 64 );
// 			break;
// 		default:
// 			level.chalk_hud1 SetShader( "hud_chalk_5", 64, 64 );
// 			break;
// 		}
// 	}

	//iprintln( "Jumping to round: " + target_round );
	wait( 1 );

	// kill all active zombies
	zombies = GetAiSpeciesArray( "axis", "all" );

	if ( IsDefined( zombies ) )
	{
		for (i = 0; i < zombies.size; i++)
		{
			if ( is_true( zombies[i].ignore_devgui_death ) )
			{
				continue;
			}
			zombies[i] dodamage(zombies[i].health + 666, zombies[i].origin);
		}
	}
}


zombie_devgui_monkey_round()
{
	if ( IsDefined( level.next_monkey_round ) )
	{
		zombie_devgui_goto_round( level.next_monkey_round );
	}
}

zombie_devgui_thief_round()
{
	if ( IsDefined( level.next_thief_round ) )
	{
		zombie_devgui_goto_round( level.next_thief_round );
	}
}

zombie_devgui_dog_round( num_dogs )
{
	if( !IsDefined( level.dogs_enabled ) || !level.dogs_enabled )
	{
		//iprintln( "Dogs not enabled in this map" );
		return;
	}

	if( !IsDefined( level.dog_rounds_enabled ) || !level.dog_rounds_enabled )
	{
		//iprintln( "Dog rounds not enabled in this map" );
		return;
	}

	if( !IsDefined( level.enemy_dog_spawns ) || level.enemy_dog_spawns.size < 1 )
	{
		//iprintln( "Dog spawners not found in this map" );
		return;
	}

	if ( !flag( "dog_round" ) )
	{
		//iprintln( "Spawning " + num_dogs + " dogs" );
		SetDvar( "force_dogs", num_dogs );
	}
	else
	{
		//iprintln( "Removing dogs" );
	}

	zombie_devgui_goto_round( level.round_number + 1 );
}

zombie_devgui_dog_round_skip()
{
	if ( IsDefined( level.next_dog_round ) )
	{
		zombie_devgui_goto_round( level.next_dog_round );
	}
}


zombie_devgui_dump_zombie_vars()
{
	if ( !IsDefined( level.zombie_vars ) )
	{
		return;
	}


	if( level.zombie_vars.size > 0 )
	{
		//iprintln( "Zombie Variables Sent to Console" );
		println( "##### Zombie Variables #####");
	}
	else
	{
		return;
	}

	var_names = GetArrayKeys( level.zombie_vars );

	for( i = 0; i < level.zombie_vars.size; i++ )
	{
		key = var_names[i];
		println( key + ":     " + level.zombie_vars[key] );
	}

	println( "##### End Zombie Variables #####");
}


zombie_devgui_revive_all()
{
	players = get_players();
	reviver = players[0];

	for ( i = 0; i < players.size; i++ )
	{
		if ( !players[i] maps\_laststand::player_is_in_laststand() )
		{
			reviver = players[i];
			break;
		}
	}

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] maps\_laststand::player_is_in_laststand() )
		{
			players[i] maps\_laststand::revive_force_revive( reviver );
			players[i] notify ( "zombified" );
		}
	}
}

zombie_devgui_director_easy()
{
	if ( IsDefined( level.director_devgui_health ) )
	{
		[[ level.director_devgui_health ]]();
	}
}

zombie_devgui_disable_kill_thread_toggle()
{
	if ( !is_true( level.disable_kill_thread ) )
	{
		level.disable_kill_thread = true;
	}
	else
	{
		level.disable_kill_thread = false;
	}
}


zombie_devgui_check_kill_thread_every_frame_toggle()
{
	if ( !is_true( level.check_kill_thread_every_frame ) )
	{
		level.check_kill_thread_every_frame = true;
	}
	else
	{
		level.check_kill_thread_every_frame = false;
	}
}


#/
