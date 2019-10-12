#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_audio;

init()
{
	init_weapon_upgrade();
//	init_weapon_cabinet();
}

// For buying weapon upgrades in the environment
init_weapon_upgrade()
{
	weapon_spawns = [];
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" );

	for( i = 0; i < weapon_spawns.size; i++ )
	{
		// hint_string = get_weapon_hint( weapon_spawns[i].zombie_weapon_upgrade );
		// cost = get_weapon_cost( weapon_spawns[i].zombie_weapon_upgrade );
		hint_string = level.zombie_weapons[weapon_spawns[i].zombie_weapon_upgrade].display_name;
		cost = level.zombie_weapons[weapon_spawns[i].zombie_weapon_upgrade].cost;

		weapon_spawns[i] SetHintString( hint_string, cost );
		weapon_spawns[i] setCursorHint( "HINT_NOICON" );
		weapon_spawns[i] UseTriggerRequireLookAt();

		weapon_spawns[i] thread weapon_spawn_think();
		model = getent( weapon_spawns[i].target, "targetname" );
		model useweaponhidetags( weapon_spawns[i].zombie_weapon_upgrade );
		model hide();
	}
}

// weapon cabinets which open on use
init_weapon_cabinet()
{
	// the triggers which are targeted at doors
	weapon_cabs = GetEntArray( "weapon_cabinet_use", "targetname" );

	for( i = 0; i < weapon_cabs.size; i++ )
	{

		weapon_cabs[i] SetHintString( &"ZOMBIE_CABINET_OPEN_1500" );
		weapon_cabs[i] setCursorHint( "HINT_NOICON" );
		weapon_cabs[i] UseTriggerRequireLookAt();
	}

//	array_thread( weapon_cabs, ::weapon_cabinet_think );
}

weapon_show_hint_choke()
{
	level._weapon_show_hint_choke = 0;

	while(1)
	{
		wait(0.05);
		level._weapon_show_hint_choke = 0;
	}
}

decide_hide_show_hint( endon_notify )
{
	if( isDefined( endon_notify ) )
	{
		self endon( endon_notify );
	}

	if(!IsDefined(level._weapon_show_hint_choke))
	{
		level thread weapon_show_hint_choke();
	}

	use_choke = false;

	if(IsDefined(level._use_choke_weapon_hints) && level._use_choke_weapon_hints == 1)
	{
		use_choke = true;
	}


	while( true )
	{

		last_update = GetTime();

		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if( players[i] maps\apex\_zm_weapons::can_buy_weapon())
			{
				self SetInvisibleToPlayer( players[i], false );
			}
			else
			{
				self SetInvisibleToPlayer( players[i], true );
			}
		}

		if(use_choke)
		{
			while((level._weapon_show_hint_choke > 4) && (GetTime() < (last_update + 150)))
			{
				wait 0.05;
			}
		}
		else
		{
			wait(0.1);
		}

		level._weapon_show_hint_choke ++;
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

weapon_set_first_time_hint( cost )
{
	ammo_cost = Int(cost / 2);

	if ( isDefined( level.has_pack_a_punch ) && !level.has_pack_a_punch )
	{
		self SetHintString( &"ZOMBIE_WEAPONCOSTAMMO", cost, ammo_cost );
	}
	else
	{
		self SetHintString( &"ZOMBIE_WEAPONCOSTAMMO_UPGRADE", cost, ammo_cost );
	}
}

weapon_spawn_think()
{
	// cost = get_weapon_cost( self.zombie_weapon_upgrade );
	cost = level.zombie_weapons[self.zombie_weapon_upgrade].cost;
	is_grenade = (WeaponType( self.zombie_weapon_upgrade ) == "grenade");

	self thread decide_hide_show_hint();

	self.first_time_triggered = false;
	for( ;; )
	{
		self waittill( "trigger", player );
		// if not first time and they have the weapon give ammo

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( !player maps\apex\_zm_weapons::can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		if( player has_powerup_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		// Allow people to get ammo off the wall for upgraded weapons
		player_has_weapon = player maps\apex\_zm_weapons::has_weapon_or_upgrade( self.zombie_weapon_upgrade );

		if( !player_has_weapon )
		{
			// else make the weapon show and give it
			if( player.score >= cost )
			{
				if( self.first_time_triggered == false )
				{
					model = getent( self.target, "targetname" );
					//					model show();
					model thread weapon_show( player );
					self.first_time_triggered = true;

					if(!is_grenade)
					{
						self weapon_set_first_time_hint( cost );
					}
				}

				player maps\_zombiemode_score::minus_to_player_score( cost );

				bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type weapon",
						player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, cost, self.zombie_weapon_upgrade, self.origin );

				if ( is_lethal_grenade( self.zombie_weapon_upgrade ) )
				{
					player maps\apex\_zm_weapons::weapon_take( player get_player_lethal_grenade() );
					player set_player_lethal_grenade( self.zombie_weapon_upgrade );
				}

				player maps\apex\_zm_weapons::weapon_give( self.zombie_weapon_upgrade, false, false );
			}
			else
			{
				play_sound_on_ent( "no_purchase" );
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 1 );

			}
		}
		else
		{
			// MM - need to check and see if the player has an upgraded weapon.  If so, the ammo cost is much higher
			if(IsDefined(self.hacked) && self.hacked)	// hacked wall buys have their costs reversed...
			{
				if ( !player maps\apex\_zm_weapons::has_upgrade( self.zombie_weapon_upgrade ) )
				{
					ammo_cost = 4500;
				}
				else
				{
					ammo_cost = Int(cost / 2);
				}
			}
			else
			{
				if ( player maps\apex\_zm_weapons::has_upgrade( self.zombie_weapon_upgrade ) )
				{
					ammo_cost = 4500;
				}
				else
				{
					ammo_cost = Int(cost / 2);
				}
			}
			// if the player does have this then give him ammo.
			if( player.score >= ammo_cost )
			{
				if( self.first_time_triggered == false )
				{
					model = getent( self.target, "targetname" );
					//					model show();
					model thread weapon_show( player );
					self.first_time_triggered = true;
					if(!is_grenade)
					{
						// self weapon_set_first_time_hint( cost, get_ammo_cost( self.zombie_weapon_upgrade ) );
						self weapon_set_first_time_hint(cost);
					}
				}

//				MM - I don't think this is necessary
// 				if( player HasWeapon( self.zombie_weapon_upgrade ) && player has_upgrade( self.zombie_weapon_upgrade ) )
// 				{
// 					ammo_given = player ammo_give( self.zombie_weapon_upgrade, true );
// 				}
//				else
				if( player maps\apex\_zm_weapons::has_upgrade( self.zombie_weapon_upgrade ) )
				{
					ammo_given = player maps\apex\_zm_weapons::ammo_give( level.zombie_weapons[ self.zombie_weapon_upgrade ].upgrade_name );
				}
				else
				{
					ammo_given = player maps\apex\_zm_weapons::ammo_give( self.zombie_weapon_upgrade );
				}

				if( ammo_given )
				{
						player maps\_zombiemode_score::minus_to_player_score( ammo_cost ); // this give him ammo to early

					bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type ammo",
						player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, ammo_cost, self.zombie_weapon_upgrade, self.origin );
				}
			}
			else
			{
				play_sound_on_ent( "no_purchase" );
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 0 );
			}
		}
	}
}

weapon_show( player )
{
	player_angles = VectorToAngles( player.origin - self.origin );

	player_yaw = player_angles[1];
	weapon_yaw = self.angles[1];

	if ( isdefined( self.script_int ) )
	{
		weapon_yaw -= self.script_int;
	}

	yaw_diff = AngleClamp180( player_yaw - weapon_yaw );

	if( yaw_diff > 0 )
	{
		yaw = weapon_yaw - 90;
	}
	else
	{
		yaw = weapon_yaw + 90;
	}

	self.og_origin = self.origin;
	self.origin = self.origin +( AnglesToForward( ( 0, yaw, 0 ) ) * 8 );

	wait( 0.05 );
	self Show();

	play_sound_at_pos( "weapon_show", self.origin, self );

	time = 1;
	self MoveTo( self.og_origin, time );
}