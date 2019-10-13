#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("lose_perk", "p7_zm_power_up_perk_bottle", "powerup_red");
	maps\apex\_zm_powerups::register_powerup_funcs("lose_perk", undefined, ::grab_lose_perk, undefined, maps\apex\_zm_powerups::func_should_never_drop);
	maps\apex\_zm_powerups::powerup_set_prevent_pick_up_if_drinking("lose_perk", true);
}

grab_lose_perk(player)
{
	level thread lose_perk_powerup();
}

lose_perk_powerup()
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!player maps\_laststand::player_is_in_laststand() && player.sessionstate != "spectator")
			player maps\apex\_zm_perks::lose_random_perk();
	}
}