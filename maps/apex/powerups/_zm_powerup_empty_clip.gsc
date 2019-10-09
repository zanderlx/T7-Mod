#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("empty_clip", "zombie_ammocan", "powerup_red");
	maps\apex\_zm_powerups::register_powerup_funcs("empty_clip", undefined, ::grab_empty_clip, undefined, maps\apex\_zm_powerups::func_should_never_drop);
}

grab_empty_clip(player)
{
	level thread empty_clip_powerup();
}

empty_clip_powerup()
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!player maps\_laststand::player_is_in_laststand() && player.sessionstate != "spectator")
		{
			weapon = player GetCurrentWeapon();
			player SetWeaponAmmoClip(weapon, 0);
		}
	}
}