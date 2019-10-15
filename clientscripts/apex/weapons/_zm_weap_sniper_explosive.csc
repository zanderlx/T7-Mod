#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_weapon_for_level()
{
	level._ZOMBIE_ACTOR_FLAG_SNIPER_EXPLOSIVE_DEATH = 13;
	register_clientflag_callback( "actor", level._ZOMBIE_ACTOR_FLAG_SNIPER_EXPLOSIVE_DEATH, ::sniper_explosive_death_response );

	level._effect["sniper_explosive_death_mist"] = loadfx( "maps/zombie/fx_zmb_coast_jackal_death" );

	level thread player_init();
}

player_init()
{
	waitforclient( 0 );

	players = GetLocalPlayers();
	for( i = 0; i < players.size; i++ )
	{
		player = players[i];
	}
}

sniper_explosive_death_response( localClientNum, set, newEnt )
{
	if ( localClientNum != 0 )
	{
		return;
	}

	if ( !set )
	{
		return;
	}

	tag_pos = self gettagorigin( "J_SpineLower" );

	// kill the eye glow and damage fx and play the right explosion effect for each player
	players = GetLocalPlayers();
	for( i = 0; i < players.size; i++ )
	{
		self clientscripts\_zombiemode::deleteZombieEyes( i );
		playfx( i, level._effect["sniper_explosive_death_mist"], tag_pos );
	}
}
