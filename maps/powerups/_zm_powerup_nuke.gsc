#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("nuke", "p7_zm_power_up_nuke");
	maps\_zm_powerups::register_powerup_fx("nuke", "powerup_green");
	maps\_zm_powerups::register_powerup_threads("nuke", undefined, ::nuke_grabbed, undefined, undefined);

	level._effect["nuke_exp"] = LoadFX("misc/fx_zombie_mini_nuke");
}

nuke_grabbed(player)
{
	level thread nuke_zombies(player, self.origin);
	return true;
}

nuke_zombies(player, origin)
{
	PlayFX(level._effect["nuke_exp"], origin);
	level thread nuke_flash();
	Earthquake(.6, 2.4, origin, 700);
	zombies = GetAISpeciesArray("axis", "all");
	zombies = get_array_of_closest(origin, zombies);
	zombies_nuked = [];

	for(i = 0; i < zombies.size; i++)
	{
		if(is_true(zombies[i].marked_for_death))
			continue;
		
		if(isdefined(zombies[i].nuke_damage_func))
		{
			single_thread(zombies[i], zombies[i].nuke_damage_func);
			continue;
		}

		if(is_magic_bullet_shield_enabled(zombies[i]))
			continue;
		
		zombies[i].marked_for_death = true;
		zombies[i].nuked = true;
		zombies_nuked[zombies_nuked.size] = zombies[i];
	}

	ragdoll_count = 0;

	for(i = 0; i < zombies_nuked.size; i++)
	{
		if(!isdefined(zombies_nuked[i]))
			continue;
		if(is_magic_bullet_shield_enabled(zombies_nuked[i]))
			continue;
		
		if(DistanceSquared(origin, zombies_nuked[i].origin) <= 13225 && !is_true(zombies_nuked[i].isdog) && ragdoll_count < 12)
		{
			dir = VectorNormalize(zombies_nuked[i].origin - origin);
			dir *= 147;
			dir += (0, 0, 146);
			zombies_nuked[i] StartRagdoll();
			zombies_nuked[i] LaunchRagdoll(dir);
			mod = "MOD_BURNED";
			ragdoll_count++;
		}
		else
		{
			PlayFX(level._effect["dog_gib"], zombies_nuked[i].origin);
			mod = "MOD_EXPLOSIVE";
		}
		
		zombies_nuked[i] DoDamage(zombies_nuked[i].health + 666, zombies_nuked[i].origin, undefined, undefined, remove_mod_from_methodofdeath(mod));
	}
	array_run(GetPlayers(), maps\_zombiemode_score::player_add_points, "nuke_powerup", 400);
}

nuke_flash()
{
	play_sound_2d("evt_nuke_flash");
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