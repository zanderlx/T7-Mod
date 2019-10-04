#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("minigun", "p7_zm_power_up_minigun");
	maps\_zm_powerups::register_powerup_fx("minigun", "powerup_blue");
	maps\_zm_powerups::register_powerup_threads("minigun", ::func_should_drop_minigun, undefined, undefined, undefined);
	maps\_zm_powerups::register_powerup_ui("minigun", true, "uie_moto_powerup_minigun", "zombie_powerup_minigun_time", "zombie_powerup_minigun_on");
	maps\_zm_powerups::register_timed_powerup_threads("minigun", ::minigun_on, ::minigun_off);
	maps\powerups\_zm_powerup_weapon::set_powerup_weapon_name("minigun", "minigun_zm");
}

minigun_on()
{
	self maps\powerups\_zm_powerup_weapon::powerup_weapon_on("minigun");
}

minigun_off()
{
	self maps\powerups\_zm_powerup_weapon::powerup_weapon_off("minigun");
}

func_should_drop_minigun()
{
	if(!maps\powerups\_zm_powerup_weapon::func_can_drop_powerup_weapon("minigun"))
		return false;
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
			if(level.solo_lives_given == 0)
				return true;
		}
		else
			return true;
	}
	return false;
}