#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	flag_init("solo_revive", false);

	maps\_zm_perks::register_perk("revive", "uie_moto_perk_quick_revive", "zombie_perk_bottle_revive_t7");
	maps\_zm_perks::register_perk_specialty("revive", "specialty_quickrevive");
	maps\_zm_perks::register_perk_machine("revive", ::get_revive_cost, &"ZOMBIE_PERK_QUICKREVIVE", "p7_zm_vending_revive", "p7_zm_vending_revive_on", "revive_light", "mus_perks_revive_sting", "mus_perks_revive_jingle");
	maps\_zm_perks::register_perk_threads("revive", ::give_revive, undefined, undefined, ::unpause_revive);
	maps\_zm_perks::register_perk_flash_audio("revive", "zmb_hud_flash_revive");

	if(is_solo_game())
		maps\_zm_perks::set_perk_ignore_power("revive");

	level._effect["revive_light"] = LoadFX("misc/fx_zombie_cola_revive_on");
	level._effect["revive_light_flicker"] = LoadFX("misc/fx_zombie_cola_revive_flicker");
	level.solo_lives_given = 0;
	level.solo_game_free_player_quickrevive = false;
	level.zombiemode_using_revive_perk = true;

	level thread watch_revive_power_on();
}

get_revive_cost()
{
	if(is_solo_game())
		return 500;
	else
		return 1500;
}

give_revive()
{
	if(is_solo_game())
	{
		self.lives = 1;

		if(is_true(level.solo_game_free_player_quickrevive))
			level.solo_game_free_player_quickrevive = false;
		else
		{
			level.solo_lives_given++;

			if(level.solo_lives_given >= 3)
			{
				flag_set("solo_revive");
				maps\_zm_perks::delete_perk_machines("revive", true);

				if(isdefined(level.revive_solo_fx_func))
					level thread [[level.revive_solo_fx_func]]();
			}
		}
	}
}

unpause_revive()
{
	if(is_solo_game())
		self.lives = 1;
}

watch_revive_power_on()
{
	for(;;)
	{
		level waittill("revive_on");

		if(isdefined(level._zm_perk_machines) && isdefined(level._zm_perk_machines["revive"]) && level._zm_perk_machines["revive"].size > 0)
			array_run(level._zm_perk_machines["revive"], ::turn_revive_on);

		level waittill("revive_off");

		if(isdefined(level._zm_perk_machines) && isdefined(level._zm_perk_machines["revive"]) && level._zm_perk_machines["revive"].size > 0)
			array_notify(level._zm_perk_machines["revive"], "stop_revive_solo_fx");
	}
}

turn_revive_on()
{
	wait 3;

	if(is_solo_game())
	{
		ent = spawn_model("tag_origin", self.machine.origin, self.machine.angles);
		ent LinkTo(self.machine);
		PlayFXOnTag(level._effect["revive_light_flicker"], ent, "tag_origin");
		self waittill_either("stop_revive_solo_fx", "stop_light_fx");
		ent Unlink();
		ent Delete();
	}
}