#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

main()
{
	maps\apex\_utility_code::init_apex_utility();
	/# maps\apex\_debug::debug_init(); #/
	level thread solo_game_init();
	maps\apex\_zm_perks::init();
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