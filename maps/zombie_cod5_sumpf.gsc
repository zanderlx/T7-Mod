#include common_scripts\utility;
#include maps\_utility;
#include maps\_music;
#include maps\zombie_cod5_sumpf_perks;
#include maps\zombie_cod5_sumpf_magic_box;
#include maps\zombie_cod5_sumpf_trap_pendulum;
#include maps\zombie_cod5_sumpf_zipline;
#include maps\zombie_cod5_sumpf_trap_perk_electric;
#include maps\_zombiemode_utility;

main()
{
	//Needs to be first for CreateFX
	maps\zombie_cod5_sumpf_fx::main();

	// viewmodel arms for the level
	PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen

	level thread maps\_callbacksetup::SetupCallbacks();

	// make sure we randomize things in the map once
	level.randomize_perks = false;
	//level.exit_level_func = ::sumpf_exit_level;

	// JMA - used to modify the percentages of pulls of ray gun and tesla gun in magic box
	level.pulls_since_last_ray_gun = 0;
	level.pulls_since_last_tesla_gun = 0;
	level.player_drops_tesla_gun = false;

	// enable for dog rounds
	level.dogs_enabled = true;

	// enable for zombie risers within active player zones
	level.zombie_rise_spawners = [];

	// JV contains zombies allowed to be on fire
	level.burning_zombies = [];

	level.use_zombie_heroes = true;

	level.kzmb_name = "sumpf_kzmb";

	//ESM - red and green lights for the traps
	precachemodel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	precacheshellshock("electrocution");

	//JV - shellshock for player zipline damage
	precacheshellshock("death");

	precachestring(&"WAW_ZOMBIE_BETTY_ALREADY_PURCHASED");
	precachestring(&"WAW_ZOMBIE_BETTY_HOWTO");

	// DCS: switching over to use structs.
	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;


	// bring over the custom anims for the japanese zombies
	level.custom_ai_type = [];
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_waw_zombiemode_ai_japanese::init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_dogs::init );

	maps\_zombiemode_ai_dogs::enable_dog_rounds();

	level._effect["zombie_grain"]			= LoadFx( "misc/fx_zombie_grain_cloud" );

	maps\_waw_zombiemode_radio::init();

	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;

	level.use_zombie_heroes = true;

	level.Player_Spawn_func = ::sumpf_player_spawn_placement;

	maps\_zombiemode::main();

	level.zone_manager_init_func = ::sumpf_zone_init;
	init_zones[0] = "center_building_upstairs";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );
	level thread setup_water_physics();
	level thread water_burst_overwrite();

	// eschmidt: _waw_zombiemode sets level.flag
	init_zombie_sumpf();
	init_sounds();


	//DCS: get betties working.
	maps\_zombiemode_betty::init();

	// Set the color vision set back
	level.zombie_visionset = "zombie_sumpf";

	maps\createart\zombie_cod5_sumpf_art::main();

	level notify("setup_rope");

	level.has_pack_a_punch = false;

	SetSavedDvar("sv_maxPhysExplosionSpheres", 15);

	//added for performance concerns- not in waw
	SetCullDist( 2400 );

	SetSavedDvar( "r_lightGridEnableTweaks", 1 );
	SetSavedDvar( "r_lightGridIntensity", 1.25 );
	SetSavedDvar( "r_lightGridContrast", .1 );

	VisionSetNaked("zombie_sumpf", 0);
}

setup_water_physics()
{
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	for (i = 0; i < players.size; i++)
  {
		players[i] SetClientDvars("phys_buoyancy",1);
	}
}
//-------------------------------------------------------------------------------
// Zone Management.
//-------------------------------------------------------------------------------
sumpf_zone_init()
{
	flag_init( "always_on" );
	flag_set( "always_on" );

	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_upstairs", "center_building_upstairs_buy", "unlock_hospital_upstairs" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_upstairs", "center_building_combined", "unlock_hospital_downstairs" );

	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_upstairs_buy", "center_building_combined", "unlock_hospital_upstairs" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_upstairs_buy", "center_building_combined", "unlock_hospital_downstairs" );


	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_combined", "northeast_outside", "ne_magic_box" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_combined", "northwest_outside", "nw_magic_box" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_combined", "southeast_outside", "se_magic_box" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "center_building_combined", "southwest_outside", "sw_magic_box" );

	maps\_zombiemode_zone_manager::add_adjacent_zone( "northeast_outside", "northeast_building", "northeast_building_unlocked" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "northwest_outside", "northwest_building", "northwest_building_unlocked" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "southeast_outside", "southeast_building", "southeast_building_unlocked" );
	maps\_zombiemode_zone_manager::add_adjacent_zone( "southwest_outside", "southwest_building", "southwest_building_unlocked" );
}

//-------------------------------------------------------------------------------
init_sounds()
{
	maps\_zombiemode_utility::add_sound( "wooden_door", "zmb_door_wood_open" );

	iprintlnbold ("init_audio");

	level thread toilet_useage();
	level thread radio_one();
	level thread radio_two();
	level thread radio_three();
	level thread radio_eggs();
	level thread battle_radio();
	level thread whisper_radio();
  level thread meteor_trigger();
	level thread book_useage();
	level thread setup_custom_vox();
	level thread superegg_one();
	level thread superegg_two();
	level thread superegg_three();
	level thread super_egg();

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
init_zombie_sumpf()
{
	// Setup the magic box
	thread maps\zombie_cod5_sumpf_magic_box::magic_box_init();

	//ESM - new electricity traps
	level thread maps\zombie_cod5_sumpf_trap_perk_electric::init_elec_trap_trigs();

	// JMA - setup zipline deactivated trigger
	zipHintDeactivated = getent("zipline_deactivated_hint_trigger", "targetname");
	zipHintDeactivated sethintstring(&"WAW_ZOMBIE_ZIPLINE_DEACTIVATED");
	zipHintDeactivated SetCursorHint("HINT_NOICON");

	// JMA - setup log trap clear debris hint string
	penBuyTrigger = getentarray("pendulum_buy_trigger","targetname");

	if ( !level.mutators["mutator_noTraps"] )
	{
		for(i = 0; i < penBuyTrigger.size; i++)
		{
			penBuyTrigger[i] sethintstring( &"WAW_ZOMBIE_CLEAR_DEBRIS" );
			penBuyTrigger[i] setCursorHint( "HINT_NOICON" );
		}

		//turning on the lights for the pen trap
		level thread maps\zombie_cod5_sumpf::turnLightRed("pendulum_light");
	}
}


//ESM - added for green light/red light functionality for traps
turnLightGreen(name)
{
	zapper_lights = getentarray(name,"targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_green");
		if (isDefined(zapper_lights[i].target))
		{
			old_light_effect = getent(zapper_lights[i].target, "targetname");
			light_effect = spawn("script_model",zapper_lights[i].origin + (0, 0, 10));
			//light_effect = spawn("script_model",zapper_lights[i].origin);
			light_effect setmodel("tag_origin");
			light_effect.angles = (0,270,0);
			light_effect.targetname = "effect_" + name + i;
			old_light_effect delete();
			zapper_lights[i].target = light_effect.targetname;
			playfxontag(level._effect["zapper_light_ready"],light_effect,"tag_origin");
		}
	}
}

turnLightRed(name)
{
	zapper_lights = getentarray(name,"targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_red");
		if (isDefined(zapper_lights[i].target))
		{
			old_light_effect = getent(zapper_lights[i].target, "targetname");
			light_effect = spawn("script_model",zapper_lights[i].origin + (0, 0, 10));
			//light_effect = spawn("script_model",zapper_lights[i].origin);
			light_effect setmodel("tag_origin");
			light_effect.angles = (0,270,0);
			light_effect.targetname = "effect_" + name + i;
			old_light_effect delete();
			zapper_lights[i].target = light_effect.targetname;
			playfxontag(level._effect["zapper_light_notready"],light_effect,"tag_origin");
		}
	}
}
book_useage()
{
	book_counter = 0;
	book_trig = getent("book_trig", "targetname");
	book_trig SetCursorHint( "HINT_NOICON" );
	book_trig UseTriggerRequireLookAt();

	if(IsDefined(book_trig))
	{
		maniac_l = getent("maniac_l", "targetname");
		maniac_r = getent("maniac_r", "targetname");

		book_trig waittill( "trigger", player );

		if(IsDefined(maniac_l))
		{
			maniac_l playsound("maniac_l");

		}
		if(IsDefined(maniac_r))
		{
			maniac_r playsound("maniac_r");

		}

	}
}


toilet_useage()
{

	toilet_counter = 0;
	toilet_trig = getent("toilet", "targetname");
	toilet_trig SetCursorHint( "HINT_NOICON" );
	toilet_trig UseTriggerRequireLookAt();

//	off_the_hook = spawn ("script_origin", toilet_trig.origin);
	toilet_trig playloopsound ("phone_hook");

	if (!IsDefined (level.music_override))
	{
		level.music_override = false;
	}

	toilet_trig waittill( "trigger", player );
	toilet_trig stoploopsound(0.5);
	toilet_trig playloopsound("phone_dialtone");

	wait(0.5);

	toilet_trig waittill( "trigger", player );
	toilet_trig stoploopsound(0.5);
	toilet_trig playsound("dial_9", "sound_done");
	toilet_trig waittill("sound_done");

	toilet_trig waittill( "trigger", player );
	toilet_trig playsound("dial_1", "sound_done");
	toilet_trig waittill("sound_done");

	toilet_trig waittill( "trigger", player );
	toilet_trig playsound("dial_1");
	wait(0.5);
	toilet_trig playsound("riiing");
	wait(1);
	toilet_trig playsound("riiing");
	wait(1);
	toilet_trig playsound ("toilet_flush", "sound_done");
	toilet_trig waittill ("sound_done");
	playsoundatposition ("zmb_cha_ching", toilet_trig.origin);

	level thread play_music_easter_egg(player);
}

play_music_easter_egg(player)
{
	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "egg" );

	wait(4);

	if( IsDefined( player ) )
	{
	    player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "music_activate" );
	}

	wait(236);
	level.music_override = false;
	level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );
}


play_radio_sounds()
{
	radio_one = getent("radio_one_origin", "targetname");
	radio_two = getent("radio_two_origin", "targetname");
	radio_three = getent("radio_three_origin", "targetname");

	pa_system = getent("speaker_in_attic", "targetname");

	radio_one stoploopsound(2);
	radio_two stoploopsound(2);
	radio_three stoploopsound(2);

	wait(0.05);
	pa_system playsound("secret_message", "message_complete");
	pa_system waittill("message_complete");

	radio_one playsound ("static");
	radio_two playsound ("static");
	radio_three playsound ("static");
}
radio_eggs()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;
	}
	while(level.radio_counter < 3)
	{
		wait(2);
	}
	level thread play_radio_sounds();


}
superegg_one()
{
	if(!IsDefined (level.superegg_counter))
	{
		level.superegg_counter = 0;
	}

	superegg_one_trig = getent ("superegg_radio_trigger_1", "targetname");
	superegg_one_trig UseTriggerRequireLookAt();
	superegg_one_trig SetCursorHint( "HINT_NOICON" );
	superegg_radio_one = getent("superegg_radio_origin_1", "targetname");

	superegg_one_trig waittill( "trigger" );
	level.superegg_counter = level.superegg_counter + 1;
	superegg_radio_one playloopsound ("static_loop");
}
superegg_two()
{
	if(!IsDefined (level.superegg_counter))
	{
		level.superegg_counter = 0;
	}

	superegg_two_trig = getent ("superegg_radio_trigger_2", "targetname");
	superegg_two_trig UseTriggerRequireLookAt();
	superegg_two_trig SetCursorHint( "HINT_NOICON" );
	superegg_radio_two = getent("superegg_radio_origin_2", "targetname");

	superegg_two_trig waittill( "trigger" );
	level.superegg_counter = level.superegg_counter + 1;
	superegg_radio_two playloopsound ("static_loop");
}
superegg_three()
{
	if(!IsDefined (level.superegg_counter))
	{
		level.superegg_counter = 0;
	}

	superegg_three_trig = getent ("superegg_radio_trigger_3", "targetname");
	superegg_three_trig UseTriggerRequireLookAt();
	superegg_three_trig SetCursorHint( "HINT_NOICON" );
	superegg_radio_three = getent("superegg_radio_origin_3", "targetname");

	superegg_three_trig waittill( "trigger" );
	level.superegg_counter = level.superegg_counter + 1;
	superegg_radio_three playloopsound ("static_loop");
}
play_super_egg_radio_pa_sounds()
{
	superegg_radio_one = getent("radio_one_origin", "targetname");
	superegg_radio_two = getent("radio_two_origin", "targetname");
	superegg_radio_three = getent("radio_three_origin", "targetname");

	pa_system = getent("speaker_in_attic", "targetname");

	superegg_radio_one stoploopsound(2);
	superegg_radio_two stoploopsound(2);
	superegg_radio_three stoploopsound(2);

	wait(0.05);
	pa_system playsound("superegg_secret_message", "message_complete");
	pa_system waittill("message_complete");

	superegg_radio_one playsound ("static");
	superegg_radio_two playsound ("static");
	superegg_radio_three playsound ("static");
}
super_egg()
{
	if(!IsDefined (level.superegg_counter))
	{
		level.superegg_counter = 0;
	}
	while(level.superegg_counter < 3)
	{
		wait(2);
	}
	level thread play_super_egg_radio_pa_sounds();


}
battle_radio()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;
	}

	battle_radio_trig = getent ("battle_radio_trigger", "targetname");
	battle_radio_trig UseTriggerRequireLookAt();
	battle_radio_trig SetCursorHint( "HINT_NOICON" );
	battle_radio_origin = getent("battle_radio_origin", "targetname");

	battle_radio_trig waittill( "trigger", player);
	battle_radio_origin playsound ("battle_message");

}
whisper_radio()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;
	}

	whisper_radio_trig = getent ("whisper_radio_trigger", "targetname");
	whisper_radio_trig UseTriggerRequireLookAt();
	whisper_radio_trig SetCursorHint( "HINT_NOICON" );
	whisper_radio_origin = getent("whisper_radio_origin", "targetname");

	whisper_radio_trig waittill( "trigger");
	whisper_radio_origin playsound ("whisper_message");

}
radio_one()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;
	}

	radio_one_trig = getent ("radio_one", "targetname");
	radio_one_trig UseTriggerRequireLookAt();
	radio_one_trig SetCursorHint( "HINT_NOICON" );
	radio_one = getent("radio_one_origin", "targetname");

	radio_one_trig waittill( "trigger" );
	level.radio_counter = level.radio_counter + 1;
	radio_one playloopsound ("static_loop");
}
radio_two()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;
	}

	radio_two_trig = getent ("radio_two", "targetname");
	radio_two_trig UseTriggerRequireLookAt();
	radio_two_trig SetCursorHint( "HINT_NOICON" );
	radio_two = getent("radio_two_origin", "targetname");

	radio_two_trig waittill( "trigger", players);
	level.radio_counter = level.radio_counter + 1;
	radio_two playloopsound ("static_loop");


}
radio_three()
{
	if(!IsDefined (level.radio_counter))
	{
		level.radio_counter = 0;
	}

	radio_three_trig = getent ("radio_three_trigger", "targetname");
	radio_three_trig UseTriggerRequireLookAt();
	radio_three_trig SetCursorHint( "HINT_NOICON" );
	radio_three = getent("radio_three_origin", "targetname");

	radio_three_trig waittill( "trigger", players);
	level.radio_counter = level.radio_counter + 1;
	radio_three playloopsound ("static_loop");

}


meteor_trigger()
{
	//player = getplayers();
	level endon("meteor_triggered");
	dmgtrig = GetEnt( "meteor", "targetname" );

	while(1)
	{
		dmgtrig waittill("trigger", player);
		if(distancesquared(player.origin, dmgtrig.origin) < 1096 * 1096)
		{
			player thread maps\_zombiemode_audio::create_and_play_dialog("level", "meteor");
			level notify ("meteor_triggered");
		}
		else
		{
			wait(0.1);
		}
	}

}

setup_custom_vox()
{
	wait(1);
	level.plr_vox["level"]["jugga"] = "gen_perk_jugga";
	level.plr_vox["level"]["doubletap"] = "gen_perk_dbltap";
	level.plr_vox["level"]["speed"] = "gen_perk_speed";
	level.plr_vox["level"]["revive"] = "gen_perk_revive";

	level.plr_vox["level"]["zipline"] = "zipline";
	level.plr_vox["level"]["trap_log"] = "trap_log";
	level.plr_vox["level"]["trap_barrel"] = "trap_barrel";
	level.plr_vox["level"]["meteor"] = "meteor";

}

//-------------------------------------------------------------------------------
// Solo Revive zombie exit points.
//-------------------------------------------------------------------------------
sumpf_exit_level()
{
	zombies = GetAiArray( "axis" );
	for ( i = 0; i < zombies.size; i++ )
	{
		zombies[i] thread sumpf_find_exit_point();
	}
}
sumpf_find_exit_point()
{
	self endon( "death" );

	player = getplayers()[0];

	dist_zombie = 0;
	dist_player = 0;
	dest = 0;

	away = VectorNormalize( self.origin - player.origin );
	endPos = self.origin + vector_scale( away, 600 );

	locs = array_randomize( level.enemy_dog_locations );

	for ( i = 0; i < locs.size; i++ )
	{
		dist_zombie = DistanceSquared( locs[i].origin, endPos );
		dist_player = DistanceSquared( locs[i].origin, player.origin );

		if ( dist_zombie < dist_player )
		{
			dest = i;
			break;
		}
	}

	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );

	self setgoalpos( locs[dest].origin );

	while ( 1 )
	{
		if ( !flag( "wait_and_revive" ) )
		{
			break;
		}
		wait_network_frame();
	}

	self thread maps\_zombiemode_spawner::find_flesh();
}

//-------------------------------------------------------------------------------
// override to prevent player spawning on roof
//-------------------------------------------------------------------------------
sumpf_player_spawn_placement()
{
	structs = getstructarray( "initial_spawn_points", "targetname" );

	flag_wait( "all_players_connected" );

	players = get_players();

	for( i = 0; i < players.size; i++ )
	{
		players[i] setorigin( structs[i].origin );
		players[i] setplayerangles( structs[i].angles );
		players[i].spectator_respawn = structs[i];
	}
}

water_burst_overwrite()
{
	level waittill("between_round_over");
	level._effect["rise_burst_water"]		  	= LoadFX("maps/zombie/fx_zombie_body_wtr_burst_smpf");
	level._effect["rise_billow_water"]			= LoadFX("maps/zombie/fx_zombie_body_wtr_billow_smpf");
}
