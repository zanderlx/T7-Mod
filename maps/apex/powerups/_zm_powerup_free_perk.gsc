#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("free_perk", "p7_zm_power_up_perk_bottle", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("free_perk", undefined, ::grab_free_perk, undefined, maps\apex\_zm_powerups::func_should_never_drop);
	maps\apex\_zm_powerups::powerup_set_prevent_pick_up_if_drinking("free_perk", true);
}

grab_free_perk(player)
{
	level thread free_perk_powerup();
}

free_perk_powerup()
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!player maps\_laststand::player_is_in_laststand() && player.sessionstate != "spectator")
			player maps\apex\_zm_perks::give_random_perk();
	}
}