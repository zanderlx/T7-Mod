#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

main()
{
	flag_init("solo_game", false);
	flag_init("_start_zm_pistol_rank", true);

	maps\apex\_utility_code::init_apex_utility();
	/# maps\apex\_debug::debug_init(); #/

	maps\apex\_zm_perks::init();
}