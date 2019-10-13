#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("nuke", "p7_zm_power_up_nuke", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("nuke", undefined, ::grab_nuke, undefined, maps\apex\_zm_powerups::func_should_always_drop);

	level._effect["powerup_nuke_explosion"] = LoadFX("misc/fx_zombie_mini_nuke");
}

grab_nuke(player)
{
	level thread nuke_powerup(self.origin);
}

nuke_powerup(origin)
{
	level thread nuke_delay_spawning(3);
	zombies = get_round_enemy_array();
	PlayFX(level._effect["powerup_nuke_explosion"], origin);
	level thread nuke_flash();
	wait .5;
	zombies = get_array_of_closest(origin, zombies);
	zombies_nuked = [];

	for(i = 0; i < zombies.size; i++)
	{
		zombie = zombies[i];

		if(is_true(zombie.marked_for_death))
			continue;

		if(isdefined(zombie.nuke_damage_func))
		{
			single_thread(zombie, zombie.nuke_damage_func);
			continue;
		}

		if(is_magic_bullet_shield_enabled(zombie))
			continue;

		zombie.marked_for_death = true;
		zombie.nuked = true;
		zombies_nuked[zombies_nuked.size] = zombie;
	}

	for(i = 0; i < zombies_nuked.size; i++)
	{
		zombie = zombies_nuked[i];
		wait RandomFloatRange(.1, .7);

		if(!isdefined(zombie))
			continue;
		if(is_magic_bullet_shield_enabled(zombie))
			continue;

		if(i < 5 && !is_true(zombie.isdog))
		{
			zombie thread animscripts\zombie_death::flame_death_fx();
			zombie PlaySound("evt_nuked");
		}

		if(!is_true(zombie.isdog))
		{
			if(!is_true(zombie.no_gib))
				zombie maps\_zombiemode_spawner::zombie_head_gib();
			zombie PlaySound("evt_nuked");
		}
		zombie DoDamage(zombie.health + 666, zombie.origin);
	}

	level notify("nuke_complete");
	array_func(GetPlayers(), maps\_zombiemode_score::player_add_points, "nuke_powerup", 400);
}

nuke_flash()
{
	host = getHostPlayer();
	host PlaySound("evt_nuke_flash");

	hud = NewHudElem();
	hud.x = 0;
	hud.y = 0;
	hud.alpha = 0;
	hud.horzAlign = "fullscreen";
	hud.vertAlign = "fullscreen";
	hud.foreground = true;
	hud SetShader("white", 640, 480);
	hud FadeOverTime(.2);
	hud.alpha = .8;
	wait .5;
	hud FadeOverTime(1);
	hud.alpha = 0;
	wait 1.1;
	hud Destroy();
}

nuke_delay_spawning(spawn_delay)
{
	level endon("disable_nuke_delay_spawning");

	if(is_true(level.disable_nuke_delay_spawning))
		return;

	b_spawn_zombies_before_nuke = flag("spawn_zombies");
	flag_clear("spawn_zombies");
	level waittill("nuke_complete");

	if(is_true(level.disable_nuke_delay_spawning))
		return;

	wait spawn_delay;

	if(b_spawn_zombies_before_nuke)
		flag_set("spawn_zombies");
}