#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("minigun", "zombie_pickup_minigun", "powerup_blue");
	maps\apex\_zm_powerups::register_powerup_funcs("minigun", undefined, undefined, undefined, ::func_should_drop_minigun);
	maps\apex\_zm_powerups::register_timed_powerup("minigun", true, "zom_icon_minigun", "zombie_powerup_minigun_time", "zombie_powerup_minigun_on");
	maps\apex\_zm_powerups::register_timed_powerup_funcs("minigun", undefined, undefined, undefined);
	maps\apex\_zm_powerups::register_powerup_weapon("minigun", "minigun_zm");
}

func_should_drop_minigun()
{
	if(minigun_no_drop())
		return false;
	return true;
}

minigun_no_drop()
{
	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		if(is_true(players[i].zombie_vars["zombie_powerup_minigun_on"]))
			return true;
	}

	if(!flag("power_on"))
	{
		if(flag("solo_game"))
		{
			if(!isdefined(level.solo_lives_given) || level.solo_lives_given == 0)
				return true;
		}
		else
			return true;
	}
	return false;
}