#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	PrecacheString(&"ZOMBIE_POWERUP_MAX_AMMO");

	maps\apex\_zm_powerups::register_basic_powerup("full_ammo", "p7_zm_power_up_max_ammo", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("full_ammo", undefined, ::grab_full_ammo, undefined, maps\apex\_zm_powerups::func_should_always_drop);
}

grab_full_ammo(player)
{
	level thread full_ammo_powerup();
	level thread full_ammo_on_hud();
}

full_ammo_powerup()
{
	players = GetPlayers();
	level notify("zmb_max_ammo_level");

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player maps\_laststand::player_is_in_laststand())
			continue;

		if(isdefined(level.check_player_is_ready_for_ammo))
		{
			result = run_function(player, level.check_player_is_ready_for_ammo, player);

			if(!is_true(result))
				continue;
		}

		weapons = player GetWeaponsList();
		player notify("zmb_max_ammo");
		player notify("zmb_lost_knife");
		player notify("zmb_disable_claymore_prompt");
		player notify("zmb_disable_spikemore_prompt");

		for(j = 0; j < weapons.size; j++)
		{
			weapon = weapons[j];

			if(isdefined(level.zombie_weapons_no_max_ammo) && IsInArray(level.zombie_weapons_no_max_ammo, weapon))
				continue;

			if(player HasWeapon(weapon))
				player GiveMaxAmmo(weapon);
		}
	}
}

full_ammo_on_hud()
{
	hud = maps\_hud_util::createFontString("objective", 2);
	hud maps\_hud_util::setPoint("TOP", undefined, 0, 290);
	hud.sort = .5;
	hud.alpha = 0;
	hud FadeOverTime(.5);
	hud.alpha = 1;
	hud.label = &"ZOMBIE_POWERUP_MAX_AMMO";
	wait .5;
	host = getHostPlayer();
	host PlaySound("zmb_full_ammo");
	hud FadeOverTime(1.5);
	hud MoveOverTime(1.5);
	hud.y = 270;
	hud.alpha = 0;
	wait 1.5;
	hud Destroy();
}