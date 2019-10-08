#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	if(is_solo_game())
	{
		cost = 500;
		hint = &"ZOMBIE_PERK_QUICKREVIVE_SOLO";
		level thread revive_solo_machine_effects();
		level.solo_lives_given = 0;
		ignore_power = true;
	}
	else
	{
		cost = 1500;
		hint = &"ZOMBIE_PERK_QUICKREVIVE";
		ignore_power = false;
	}

	flag_init("solo_revive", false);

	maps\apex\_zm_perks::register_perk("revive", "specialty_quickrevive_zombies");
	maps\apex\_zm_perks::register_perk_bottle("revive", undefined, undefined, 22);
	maps\apex\_zm_perks::register_perk_machine("revive", ignore_power, hint, cost, "p7_zm_vending_revive", "p7_zm_vending_revive_on", "perk_light_blue");
	maps\apex\_zm_perks::register_perk_threads("revive", ::give_revive, ::take_revive);
	maps\apex\_zm_perks::register_perk_sounds("revive", "mus_perks_revive_sting", "mus_perks_revive_jingle", "zmb_hud_flash_revive");

	maps\apex\_zm_perks::add_perk_specialty("revive", "specialty_quickrevive");

	level.zombiemode_using_revive_perk = true;
	level._effect["revive_light_flicker"] = LoadFX("misc/fx_zombie_cola_revive_flicker");
}

give_revive()
{
	if(is_solo_game())
	{
		self.lives = 1;

		if(isdefined(level.solo_game_free_player_quickrevive) && level.solo_game_free_player_quickrevive > 0)
			level.solo_game_free_player_quickrevive--;
		else
			level.solo_lives_given++;

		if(level.solo_lives_given >= 3)
		{
			flag_set("solo_revive");
			maps\apex\_zm_perks::delete_perk_machines("revive");

			if(isdefined(level.revive_solo_fx_func))
				single_thread(level, level.revive_solo_fx_func);
		}
	}
}

take_revive(reason)
{
}

revive_solo_machine_effects()
{
	level endon("end_game");
	flag_wait("all_players_connected");
	stubs = maps\apex\_zm_perks::get_perk_machines("revive");
	array_thread(stubs, ::revive_solo_machine_effects_think);
}

revive_solo_machine_effects_think()
{
	ent = spawn_model("tag_origin", self.machine.origin, self.machine.angles);
	ent LinkTo(self.machine);
	wait 3;
	PlayFXOnTag(level._effect["revive_light_flicker"], ent, "tag_origin");
	self.machine waittill("stop_perk_power_effects");
	ent Unlink();
	ent Delete();
}