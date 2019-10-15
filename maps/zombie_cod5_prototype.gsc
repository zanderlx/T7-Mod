#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;

main()
{
	// first for createFX (why?)
	maps\zombie_cod5_prototype_fx::main();

	// viewmodel arms for the level
	PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen

	level thread maps\_callbacksetup::SetupCallbacks();
	//maps\_waw_destructible_opel_blitz::init_blitz();
	level.startInvulnerableTime = GetDvarInt( "player_deathInvulnerableTime" );

	level.zones = [];

	level._effect["zombie_grain"]			= LoadFx( "misc/fx_zombie_grain_cloud" );

	maps\_waw_zombiemode_radio::init();

	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;

	level.use_zombie_heroes = true;

	//DCS: no perk machines so need to init here.
	flag_init( "_start_zm_pistol_rank" );

	SetDvar( "magic_chest_movable", "0" );

	maps\_zombiemode::main();

	level.zone_manager_init_func = ::prototype_zone_init;
	init_zones[0] = "start_zone";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	init_sounds();

	//thread bad_area_fixes();

	thread above_couches_death();
	thread above_roof_death();
	thread below_ground_death();

	level thread zombie_collision_patch();

	// If you want to modify/add to the weapons table, please copy over the _zombiemode_weapons init_weapons() and paste it here.
	// I recommend putting it in it's own function...
	// If not a MOD, you may need to provide new localized strings to reflect the proper cost.

	// Set the color vision set back
	level.zombie_visionset = "zombie_prototype";

	// bhackbarth: bring this down here (rather than be called in zombie_cod5_prototype_fx::main), so we actually have clients to send fog settings to
	maps\createart\zombie_cod5_prototype_art::main();

	// need to set the "solo_game" flag here, since there are no vending machines
	level thread check_solo_game();

	// DCS: Only seems to be used in prototype.
	level thread setup_weapon_cabinet();
	level	thread maps\_interactive_objects::main();

	// TUEY new eggs
	level thread prototype_eggs();
	level thread time_to_play();

	level thread pistol_rank_setup();

	level.has_pack_a_punch = false;
}

precache_player_model_override()
{
	mptype\player_t5_zm_theater::precache();
}

give_player_model_override( entity_num )
{
	if( IsDefined( self.zm_random_char ) )
	{
		entity_num = self.zm_random_char;
	}

	switch( entity_num )
	{
		case 0:
			character\c_usa_dempsey_zt::main();// Dempsy
			break;
		case 1:
			character\c_rus_nikolai_zt::main();// Nikolai
			break;
		case 2:
			character\c_jap_takeo_zt::main();// Takeo
			break;
		case 3:
			character\c_ger_richtofen_zt::main();// Richtofen
			break;
	}
}

player_set_viewmodel_override( entity_num )
{
	switch( self.entity_num )
	{
		case 0:
			// Dempsey
			self SetViewModel( "viewmodel_usa_pow_arms" );
			break;
		case 1:
			// Nikolai
			self SetViewModel( "viewmodel_rus_prisoner_arms" );
			break;
		case 2:
			// Takeo
			self SetViewModel( "viewmodel_vtn_nva_standard_arms" );
			break;
		case 3:
			// Richtofen
			self SetViewModel( "viewmodel_usa_hazmat_arms" );
			break;
	}
}

//-------------------------------------------------------------------------------
// weapon cabinets which open on use
//-------------------------------------------------------------------------------
setup_weapon_cabinet()
{
	// the triggers which are targeted at doors
	weapon_cabs = GetEntArray( "weapon_cabinet_use", "targetname" );

	for( i = 0; i < weapon_cabs.size; i++ )
	{

		weapon_cabs[i] SetHintString( &"ZOMBIE_CABINET_OPEN_1500" );
		weapon_cabs[i] setCursorHint( "HINT_NOICON" );
		weapon_cabs[i] UseTriggerRequireLookAt();
	}

	array_thread( weapon_cabs, ::weapon_cabinet_think );
}
weapon_cabinet_think()
{
	weapons = getentarray( "cabinet_weapon", "targetname" );

	doors = getentarray( self.target, "targetname" );
	for( i = 0; i < doors.size; i++ )
	{
		doors[i] NotSolid();
	}

	self.has_been_used_once = false;

	self thread maps\apex\_zm_weapons::decide_hide_show_hint();

	while( 1 )
	{
		self waittill( "trigger", player );

		if( !player maps\apex\_zm_weapons::can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		cost = 1500;
		if( self.has_been_used_once )
		{
			cost = maps\apex\_zm_weapons::get_weapon_cost( self.zombie_weapon_upgrade );
		}
		else
		{
			if( IsDefined( self.zombie_cost ) )
			{
				cost = self.zombie_cost;
			}
		}

		ammo_cost = maps\apex\_zm_weapons::get_ammo_cost( self.zombie_weapon_upgrade );

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( self.has_been_used_once )
		{
			player_has_weapon = player maps\apex\_zm_weapons::has_weapon_or_upgrade( self.zombie_weapon_upgrade );

			if( !player_has_weapon )
			{
				if( player.score >= cost )
				{
					self play_sound_on_ent( "purchase" );
					player maps\_zombiemode_score::minus_to_player_score( cost );
					player maps\apex\_zm_weapons::weapon_give( self.zombie_weapon_upgrade );
					player maps\apex\_zm_weapons::check_collector_achievement( self.zombie_weapon_upgrade );
				}
				else // not enough money
				{
					play_sound_on_ent( "no_purchase" );
					player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money" );
				}
			}
			else if ( player.score >= ammo_cost )
			{
				ammo_given = player maps\apex\_zm_weapons::ammo_give( self.zombie_weapon_upgrade );
				if( ammo_given )
				{
					self play_sound_on_ent( "purchase" );
					player maps\_zombiemode_score::minus_to_player_score( ammo_cost ); // this give him ammo to early
				}
			}
			else // not enough money
			{
				play_sound_on_ent( "no_purchase" );
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money" );
			}
		}
		else if( player.score >= cost ) // First time the player opens the cabinet
		{
			self.has_been_used_once = true;

			self play_sound_on_ent( "purchase" );

			self SetHintString( &"WAW_ZOMBIE_WEAPONCOSTAMMO", cost, ammo_cost );
			self setCursorHint( "HINT_NOICON" );
			player maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );

			doors = getentarray( self.target, "targetname" );

			for( i = 0; i < doors.size; i++ )
			{
				if( doors[i].model == "dest_test_cabinet_ldoor_dmg0" )
				{
					doors[i] thread weapon_cabinet_door_open( "left" );
				}
				else if( doors[i].model == "dest_test_cabinet_rdoor_dmg0" )
				{
					doors[i] thread weapon_cabinet_door_open( "right" );
				}
			}

			player_has_weapon = player maps\apex\_zm_weapons::has_weapon_or_upgrade( self.zombie_weapon_upgrade );

			if( !player_has_weapon )
			{
				player maps\apex\_zm_weapons::weapon_give( self.zombie_weapon_upgrade );
				player maps\apex\_zm_weapons::check_collector_achievement( self.zombie_weapon_upgrade );
			}
			else
			{
				if( player maps\apex\_zm_weapons::has_upgrade( self.zombie_weapon_upgrade ) )
				{
					player maps\apex\_zm_weapons::ammo_give( self.zombie_weapon_upgrade+"_upgraded" );
				}
				else
				{
					player maps\apex\_zm_weapons::ammo_give( self.zombie_weapon_upgrade );
				}
			}
		}
		else // not enough money
		{
			play_sound_on_ent( "no_purchase" );
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money" );
		}
	}
}
weapon_cabinet_door_open( left_or_right )
{
	if( left_or_right == "left" )
	{
		self rotateyaw( 120, 0.3, 0.2, 0.1 );
	}
	else if( left_or_right == "right" )
	{
		self rotateyaw( -120, 0.3, 0.2, 0.1 );
	}
}
//-------------------------------------------------------------------------------

bad_area_fixes()
{
	thread disable_stances_in_zones();
}


// do point->distance checks and volume checks
disable_stances_in_zones()
{
 	players = get_players();

 	for (i = 0; i < players.size; i++)
 	{
 		players[i] thread fix_hax();
		players[i] thread fix_couch_stuckspot();
 		//players[i] thread in_bad_zone_watcher();
 		players[i] thread out_of_bounds_watcher();
 	}
}




//Chris_P - added additional checks for some hax/exploits on the stairs, by the grenade bag and on one of the columns/pillars
fix_hax()
{
	self endon("disconnect");
	self endon("death");

	check = 15;
	check1 = 10;

	while(1)
	{

		//stairs
		wait(.5);
		if( distance2d(self.origin,( 101, -100, 40)) < check )
		{
			self setorigin ( (101, -90, self.origin[2]));
		}

		//crates/boxes
		else if( distance2d(self.origin, ( 816, 645, 12) ) < check )
		{
			self setorigin ( (816, 666, self.origin[2]) );

		}

		else if( distance2d( self.origin, (376, 643, 184) ) < check )
		{
			self setorigin( (376, 665, self.origin[2]) );
		}

		//by grandfather clock
		else	if(distance2d(self.origin,(519 ,765, 155)) < check1)
		{
			self setorigin( (516, 793,self.origin[2]) );
		}

		//broken pillar
		else if( distance2d(self.origin,(315 ,346, 79))<check1)
		{
			self setorigin( (317, 360, self.origin[2]) );
		}

		//rubble by pillar
		else if( distance2d(self.origin,(199, 133, 18))<check)
		{
			self setorigin( (172, 123, self.origin[2]) );
		}

		//nook in curved stairs
		else if( distance2d(self.origin,(142 ,-100 ,91))<check1)
		{
			self setorigin( (139 ,-87, self.origin[2]) );
		}

		//by sawed off shotty
		else if( distance2d(self.origin,(192, 369 ,185))<check1)
		{
			self setorigin( (195, 400 ,self.origin[2]) );
		}

		//rubble pile in the corner
		else if( distance2d(self.origin,(-210, 641, 247)) < check)
		{
			self setorigin( (-173 ,677,self.origin[2] ) );
		}

	}

}



fix_couch_stuckspot()
{
	self endon("disconnect");
	self endon("death");
	level endon("upstairs_blocker_purchased");

	while(1)
	{
		wait(.5);

		if( distance2d(self.origin, ( 181, 161, 206) ) < 10 )
		{
			self setorigin ( (175, 175 , self.origin[2]) );

		}

	}

}




in_bad_zone_watcher()
{
	self endon ("disconnect");
	level endon ("fake_death");

	no_prone_and_crouch_zones = [];

 	// grenade wall
 	no_prone_and_crouch_zones[0]["min"] = (-205, -128, 144);
 	no_prone_and_crouch_zones[0]["max"] = (-89, -90, 269);

  	no_prone_zones = [];

  	// grenade wall
  	no_prone_zones[0]["min"] = (-205, -128, 144);
 	no_prone_zones[0]["max"] = (-55, 30, 269);

	// near the sawed off
  	no_prone_zones[1]["min"] = (88, 305, 144);
 	no_prone_zones[1]["max"] = (245, 405, 269);

	while (1)
 	{
		array_check = 0;

		if ( no_prone_and_crouch_zones.size > no_prone_zones.size)
		{
			array_check = no_prone_and_crouch_zones.size;
		}
		else
		{
			array_check = no_prone_zones.size;
		}

 		for(i = 0; i < array_check; i++)
 		{
 			if (isdefined(no_prone_and_crouch_zones[i]) &&
 				self is_within_volume(no_prone_and_crouch_zones[i]["min"][0], no_prone_and_crouch_zones[i]["max"][0],
 											no_prone_and_crouch_zones[i]["min"][1], no_prone_and_crouch_zones[i]["max"][1],
 											no_prone_and_crouch_zones[i]["min"][2], no_prone_and_crouch_zones[i]["max"][2]))
 			{
 				self allowprone(false);
 				self allowcrouch(false);
 				break;
 			}
 			else if (isdefined(no_prone_zones[i]) &&
 				self is_within_volume(no_prone_zones[i]["min"][0], no_prone_zones[i]["max"][0],
 											no_prone_zones[i]["min"][1], no_prone_zones[i]["max"][1],
 											no_prone_zones[i]["min"][2], no_prone_zones[i]["max"][2]))
 			{
 				self allowprone(false);
 				break;
 			}
 			else
 			{
 				self allowprone(true);
 				self allowcrouch(true);
 			}


 		}
 		wait 0.05;
 	}
}


is_within_volume(min_x, max_x, min_y, max_y, min_z, max_z)
{
	if (self.origin[0] > max_x || self.origin[0] < min_x)
	{
		return false;
	}
	else if (self.origin[1] > max_y || self.origin[1] < min_y)
	{
		return false;
	}
	else if (self.origin[2] > max_z || self.origin[2] < min_z)
	{
		return false;
	}

	return true;
}




init_sounds()
{
	maps\_zombiemode_utility::add_sound( "break_stone", "break_stone" );
}

above_couches_death()
{
	level endon ("junk purchased");

	while (1)
	{
		wait 0.2;

		players = get_players();

		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] > 145)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);
			}
		}
	}
}

above_roof_death()
{
	while (1)
	{
		wait 0.2;

		players = get_players();

		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] > 235)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);
			}
		}
	}
}

below_ground_death()
{
	while (1)
	{
		wait 0.2;

		players = get_players();

		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] < -11)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);
			}
		}
	}
}


out_of_bounds_watcher()
{
	self endon ("disconnect");

	outside_of_map = [];

 	outside_of_map[0]["min"] = (361, 591, -11);
 	outside_of_map[0]["max"] = (1068, 1031, 235);

 	outside_of_map[1]["min"] = (-288, 591, -11);
 	outside_of_map[1]["max"] = (361, 1160, 235);

 	outside_of_map[2]["min"] = (-272, 120, -11);
 	outside_of_map[2]["max"] = (370, 591, 235);

 	outside_of_map[3]["min"] = (-272, -912, -11);
 	outside_of_map[3]["max"] = (273, 120, 235);

	while (1)
 	{
		array_check = outside_of_map.size;

		kill_player = true;
 		for(i = 0; i < array_check; i++)
 		{
 			if (self is_within_volume(	outside_of_map[i]["min"][0], outside_of_map[i]["max"][0],
 										outside_of_map[i]["min"][1], outside_of_map[i]["max"][1],
 										outside_of_map[i]["min"][2], outside_of_map[i]["max"][2]))
 			{
 				kill_player = false;

 			}
 		}

 		if (kill_player)
 		{
 			setsaveddvar("player_deathInvulnerableTime", 0);
			self DoDamage( self.health + 1000, self.origin, undefined, undefined, "riflebullet" );
			setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);
 		}

 		wait 0.2;
 	}

}

check_solo_game()
{
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	if ( players.size == 1 )
	{
		flag_set( "solo_game" );
		level.solo_lives_given = 0;
		players[0].lives = 0;
	}
}
//*****************************************************************************
// ZONE INIT
//*****************************************************************************
prototype_zone_init()
{
	flag_init( "always_on" );
	flag_set( "always_on" );

	// foyer_zone
	add_adjacent_zone( "start_zone", "box_zone", "start_2_box" );
	add_adjacent_zone( "start_zone", "upstairs_zone", "start_2_upstairs" );
	add_adjacent_zone( "box_zone", "upstairs_zone", "box_2_upstairs" );
}

prototype_eggs()
{
		trigs = getentarray ("evt_egg_killme", "targetname");
		for(i=0;i<trigs.size;i++)
		{
			trigs[i] thread check_for_egg_damage();
		}

}
check_for_egg_damage()
{
	if(!IsDefined (level.egg_damage_counter))
	{
		level.egg_damage_counter = 0;
	}
	self waittill ("damage");
	level.egg_damage_counter = level.egg_damage_counter + 1;
//	iprintlnbold ("ouch");
}
time_to_play()
{
	if(!IsDefined (level.egg_damage_counter))
	{
		level.egg_damage_counter = 0;
	}

	while(level.egg_damage_counter < 3)
	{
		wait(0.5);
	}

	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "egg" );

	wait(4);
/*
	if( IsDefined( player ) )
	{
	    player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "music_activate" );
	}
*/

	wait(223);
	level.music_override = false;
	level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

}

pistol_rank_setup()
{
	flag_init( "_start_zm_pistol_rank" );

	flag_wait( "all_players_connected" );
	players = GetPlayers();
	if ( players.size == 1 )
	{
		solo = true;
		flag_set( "solo_game" );
		level.solo_lives_given = 0;
		players[0].lives = 0;
		level maps\_zombiemode::zombiemode_solo_last_stand_pistol();
	}

	flag_set( "_start_zm_pistol_rank" );
}

zombie_collision_patch()
{
	PreCacheModel("collision_geo_32x32x128");

	collision = spawn("script_model", (518, 756, 209));
	collision setmodel("collision_geo_32x32x128");
	collision.angles = (0, 0, 0);
	collision Hide();
}