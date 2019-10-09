#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("bonus_points_player", "zombie_z_money_icon", "powerup_blue");
	maps\apex\_zm_powerups::register_powerup_funcs("bonus_points_player", undefined, ::grab_bonus_points_player, undefined, maps\apex\_zm_powerups::func_should_never_drop);
	maps\apex\_zm_powerups::powerup_set_can_pick_up_in_last_stand("bonus_points_player", true);

	maps\apex\_zm_powerups::register_basic_powerup("bonus_points_team", "zombie_z_money_icon", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("bonus_points_team", undefined, ::grab_bonus_points_team, undefined, maps\apex\_zm_powerups::func_should_never_drop);
}

grab_bonus_points_player(player)
{
	points = RandomIntRange(1, 25) * 100;
	player maps\_zombiemode_score::add_to_player_score(points);
}

grab_bonus_points_team(player)
{
	level thread bonus_points_team_powerup();
}

bonus_points_team_powerup()
{
	points = RandomIntRange(1, 25) * 100;
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!player maps\_laststand::player_is_in_laststand() && player.sessionstate != "spectator")
			player maps\_zombiemode_score::add_to_player_score(points);
	}
}