#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("lose_points_team", "zombie_z_money_icon", "powerup_red");
	maps\apex\_zm_powerups::register_powerup_funcs("lose_points_team", undefined, ::grab_lose_points_team, undefined, maps\apex\_zm_powerups::func_should_never_drop);

	maps\apex\_zm_powerups::register_basic_powerup("lose_points_player", "zombie_z_money_icon", "powerup_red"); // TODO: powerup_<>? bad powerup that affects grabber, what color to use?
	maps\apex\_zm_powerups::register_powerup_funcs("lose_points_player", undefined, ::grab_lose_points_player, undefined, maps\apex\_zm_powerups::func_should_never_drop);
	maps\apex\_zm_powerups::powerup_set_can_pick_up_in_last_stand("lose_points_player", true);
}

grab_lose_points_player(player)
{
	points = RandomIntRange(1, 25) * 100;

	if(0 > player.score - points)
		player maps\_zombiemode_score::minus_to_player_score(player.score);
	else
		player maps\_zombiemode_score::minus_to_player_score(points);
}

grab_lose_points_team(player)
{
	level thread lose_points_powerup();
}

lose_points_powerup()
{
	points = RandomIntRange(1, 25) * 100;
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!player maps\_laststand::player_is_in_laststand() && player.sessionstate != "spectator")
		{
			if(0 > player.score - points)
				player maps\_zombiemode_score::minus_to_player_score(player.score);
			else
				player maps\_zombiemode_score::minus_to_player_score(points);
		}
	}
}