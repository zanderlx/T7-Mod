#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_weapon_for_level()
{
	level._ZOMBIE_PLAYER_FLAG_HUMANGUN_HIT_RESPONSE = 11;
	register_clientflag_callback( "player", level._ZOMBIE_PLAYER_FLAG_HUMANGUN_HIT_RESPONSE, ::humangun_player_hit_response );
	level._ZOMBIE_PLAYER_FLAG_HUMANGUN_UPGRADED_HIT_RESPONSE = 10;
	register_clientflag_callback( "player", level._ZOMBIE_PLAYER_FLAG_HUMANGUN_UPGRADED_HIT_RESPONSE, ::humangun_upgraded_player_hit_response );

	level._ZOMBIE_ACTOR_FLAG_HUMANGUN_HIT_RESPONSE = 12;
	register_clientflag_callback( "actor", level._ZOMBIE_ACTOR_FLAG_HUMANGUN_HIT_RESPONSE, ::humangun_zombie_hit_response );
	level._ZOMBIE_ACTOR_FLAG_HUMANGUN_UPGRADED_HIT_RESPONSE = 11;
	register_clientflag_callback( "actor", level._ZOMBIE_ACTOR_FLAG_HUMANGUN_UPGRADED_HIT_RESPONSE, ::humangun_upgraded_zombie_hit_response );

	// WW: vision set for players when hit with human gun
	level._humangun_player_hit_visionset = "zombie_humangun_player_hit";
	level._humangun_player_hit_visionset_priority = 8;

	level._humangun_upgraded_player_hit_visionset = "zombie_humangun_upgraded_player_hit";
	level._humangun_upgraded_player_hit_visionset_priority = 9;

	level._humangun_visionset_transition_time = 0.3;

	level._effect["humangun_viewmodel_reload"]			= LoadFX( "weapon/human_gun/fx_hgun_reload" );
	level._effect["humangun_viewmodel_reload_upgraded"]	= LoadFX( "weapon/human_gun/fx_hgun_reload_ug" );
	level._effect["humangun_glow_neck"]					= LoadFX( "weapon/human_gun/fx_hgun_1st_hit_glow_zombie" );
	level._effect["humangun_glow_neck_upgraded"]		= LoadFX( "weapon/human_gun/fx_hgun_1st_hit_glow_zombie_ug" );
	level._effect["humangun_glow_neck_critical"]		= LoadFX( "weapon/human_gun/fx_hgun_timer_glow_zombie_ug" );
	level._effect["humangun_glow_spine_upgraded"]		= LoadFX( "weapon/human_gun/fx_hgun_2nd_hit_glow_zombie_ug" );
	level._effect["humangun_explosion"]					= LoadFX( "weapon/human_gun/fx_hgun_explosion_ug" );
	level._effect["humangun_explosion_death_mist"]		= loadfx( "maps/zombie/fx_zmb_coast_jackal_death" );

	level thread player_init();
	level thread humangun_notetrack_think();
}

player_init()
{
	waitforclient( 0 );
	level.humangun_play_sfx = [];

	players = GetLocalPlayers();
	for( i = 0; i < players.size; i++ )
	{
		player = players[i];
		level.humangun_play_sfx[i] = false;
		level.humangun_sfx_is_playing[i] = false;
		player thread humangun_sfx( i );
	}
}


humangun_sfx( localclientnum )
{
	self endon( "disconnect" );

	for( ;; )
	{
		realwait( 0.1 );

		currentweapon = GetCurrentWeapon( localclientnum );
		if ( !level.humangun_play_sfx[localclientnum] || IsThrowingGrenade( localclientnum ) || IsMeleeing( localclientnum ) || IsOnTurret( localclientnum ) || (currentweapon != "humangun_zm" && currentweapon != "humangun_upgraded_zm") )
		{
			humangun_sfx_off( localclientnum );
			continue;
		}

		humangun_sfx_on( localclientnum );
	}
}


humangun_sfx_off( localclientnum )
{
	if ( level.humangun_sfx_is_playing[localclientnum] )
	{
		level thread deactivate_humangun_loop();

		level.humangun_sfx_is_playing[localclientnum] = false;
	}
}


humangun_sfx_on( localclientnum )
{
	if ( !level.humangun_sfx_is_playing[localclientnum] )
	{
		level thread activate_humangun_loop();

		level.humangun_sfx_is_playing[localclientnum] = true;
	}
}


humangun_get_eject_viewmodel_effect( upgraded )
{
	if ( upgraded )
	{
		return level._effect["humangun_viewmodel_reload_upgraded"];
	}
	else
	{
		return level._effect["humangun_viewmodel_reload"];
	}
}


humangun_notetrack_think()
{
	level.humangun_sound_ent = spawn( 0, (0,0,0), "script_origin" );

	for ( ;; )
	{
		level waittill( "notetrack", localclientnum, note );

		//println( "@@@ Got notetrack: " + note + " for client: " + localclientnum );
		currentweapon = GetCurrentWeapon( localclientnum );

		switch( note )
		{
		case "audio_deactivate_humangun_loop":
			level.humangun_play_sfx[localclientnum] = false;
		break;

		case "audio_activate_humangun_loop":
			level.humangun_play_sfx[localclientnum] = true;
		break;

		case "eject_fx":
			PlayViewmodelFx( localclientnum, humangun_get_eject_viewmodel_effect( currentweapon == "humangun_upgraded_zm" ), "tag_eject_fx" );
		break;

		}
	}
}


humangun_create_hit_response_fx( localClientNum, tag, effect )
{
	if ( !isdefined( self._humangun_hit_response_fx[localClientNum][tag] ) )
	{
		self._humangun_hit_response_fx[localClientNum][tag] = PlayFxOnTag( localClientNum, effect, self, tag );
	}
}


humangun_delete_hit_response_fx( localClientNum, tag )
{
	if ( isdefined( self._humangun_hit_response_fx[localClientNum][tag] ) )
	{
		DeleteFx( localClientNum, self._humangun_hit_response_fx[localClientNum][tag], false );
		self._humangun_hit_response_fx[localClientNum][tag] = undefined;
	}
}


humangun_zombie_hit_response_internal( localClientNum, set, newEnt, upgraded, zombie )
{
	if ( localClientNum != 0 )
	{
		return;
	}

	if ( !isdefined( self._humangun_hit_response_fx ) )
	{
		self._humangun_hit_response_fx = [];
	}

	players = GetLocalPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		if(!zombie && players[i] IsSpectating())
		{
			continue;			// No FX for spectating players.
		}


		if ( !isdefined( self._humangun_hit_response_fx[i] ) )
		{
			self._humangun_hit_response_fx[i] = [];
		}

		//clean up any existing fx, just in case
		self humangun_delete_hit_response_fx( i, "j_neck" );
		self humangun_delete_hit_response_fx( i, "J_SpineLower" );

		if ( set )
		{
			if ( zombie )
			{
				self clientscripts\_zombiemode::deleteZombieEyes( i );
			}

			if ( !upgraded )
			{
				self humangun_create_hit_response_fx( i, "j_neck", level._effect["humangun_glow_neck"] );
			}
			else
			{
				self humangun_create_hit_response_fx( i, "j_neck", level._effect["humangun_glow_neck_upgraded"] );
				self humangun_create_hit_response_fx( i, "J_SpineLower", level._effect["humangun_glow_spine_upgraded"] );
			}
		}
	}
}


humangun_player_hit_response( localClientNum, set, newEnt )
{
	self thread humangun_player_visionset( localClientNum, set, newEnt, false );
	self humangun_zombie_hit_response_internal( localClientNum, set, newEnt, false, false );
}


humangun_upgraded_player_hit_response( localClientNum, set, newEnt )
{
	self thread humangun_player_visionset( localClientNum, set, newEnt, true );
	self humangun_zombie_hit_response_internal( localClientNum, set, newEnt, true, false );
}


humangun_zombie_hit_response( localClientNum, set, newEnt )
{
	if ( isdefined( self.humangun_zombie_hit_response ) )
	{
		self [[ self.humangun_zombie_hit_response ]]( localClientNum, set, newEnt, false );
		return;
	}

	if ( isdefined( self.humangun_zombie_1st_hit_was_upgraded ) && self.humangun_zombie_1st_hit_was_upgraded )
	{
		if ( localClientNum != 0 )
		{
			return;
		}

		if ( set )
		{
			players = GetLocalPlayers();
			for ( i = 0; i < players.size; i++ )
			{
				self humangun_delete_hit_response_fx( i, "j_neck" );
				self humangun_create_hit_response_fx( i, "j_neck", level._effect["humangun_glow_neck_critical"] );
			}
		}
		else
		{
			self humangun_zombie_hit_response_internal( localClientNum, set, newEnt, false, true ); // clears existing effects

			tag_pos = self gettagorigin( "J_SpineLower" );

			players = GetLocalPlayers();
			for ( i = 0; i < players.size; i++ )
			{
				playfx( i, level._effect["humangun_explosion"], tag_pos );
				playfx( i, level._effect["humangun_explosion_death_mist"], tag_pos );
			}
		}
	}
	else
	{
		self humangun_zombie_hit_response_internal( localClientNum, set, newEnt, false, true );
	}
}


humangun_upgraded_zombie_hit_response( localClientNum, set, newEnt )
{
	if ( isdefined( self.humangun_zombie_hit_response ) )
	{
		self [[ self.humangun_zombie_hit_response ]]( localClientNum, set, newEnt, true );
		return;
	}

	if ( set )
	{
		self.humangun_zombie_1st_hit_was_upgraded = true;
	}
	self humangun_zombie_hit_response_internal( localClientNum, set, newEnt, true, true );
}

// vision set if player is hit by human gun
humangun_player_visionset( int_local_client, set, ent_new, bool_upgraded )
{
	self endon( "disconnect" );

	if(self IsSpectating())
	{
		return;			// No vision sets for specting players, currently.
	}

	if(IsDefined(ent_new) && ent_new)
	{
		return;
	}

	// this should only run on the player that is in the water, the other split screen player should fall out of this
	player = GetLocalPlayers()[ int_local_client ];
	if( player GetEntityNumber() != self GetEntityNumber() )
	{
		return;	// only do this for the player in the water
	}

	if( set )
	{
		if( bool_upgraded ) // if the gun is upgraded
		{
			// add vision set on the player
			self thread zombie_vision_set_apply( level._humangun_upgraded_player_hit_visionset, level._humangun_upgraded_player_hit_visionset_priority, level._humangun_visionset_transition_time, int_local_client );
		}
		else // the gun is normal
		{
			// add vision set on the player
			self thread zombie_vision_set_apply( level._humangun_player_hit_visionset, level._humangun_player_hit_visionset_priority, level._humangun_visionset_transition_time, int_local_client );
		}
	}
	else
	{
		if( bool_upgraded ) // upgraded
		{
			// remove vision set
			zombie_vision_set_remove( level._humangun_upgraded_player_hit_visionset, level._humangun_visionset_transition_time, int_local_client );
		}
		else // normal
		{
			// remove vision set
			zombie_vision_set_remove( level._humangun_player_hit_visionset, level._humangun_visionset_transition_time, int_local_client );
		}
	}
}


activate_humangun_loop()
{
    level endon( "audio_deact_hg_loop" );

    level notify( "audio_act_hg_loop" );

    PlaySound( 0, "wpn_humangun_loop_start", (0,0,0) );
    level.humangun_sound_ent PlayLoopSound( "wpn_humangun_loop", 1 );
}


deactivate_humangun_loop()
{
    level endon( "audio_act_hg_loop" );

    level notify( "audio_deact_hg_loop" );

    PlaySound( 0, "wpn_humangun_loop_end", (0,0,0) );
    level.humangun_sound_ent stoploopsound( .5 );
}
