#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk(
		"chugabud", // Internal name of this perk
		undefined, // Function called when perk is obtained
		undefined, // Function called when perk is lost 
		undefined, // Function called when perk is paused
		undefined // Function called when perk is unpaused
	);

	level._effect["chugabud_light"] = LoadFX("misc/fx_zombie_cola_on");
	level._effect["chugabud_revive_fx"] = LoadFX("apex/weapon/quantum_bomb/fx_player_position_effect");
	level._effect["chugabud_bleedout_fx"] = LoadFX("apex/weapon/quantum_bomb/fx_player_position_effect");

	add_level_notify_callback("chugabud_effects_enable", ::whoswhoaudio, true);
	add_level_notify_callback("chugabud_effects_disable", ::whoswhoaudio, false);
}

whoswhoaudio(clientnum, enabled)
{
	player = GetLocalPlayer(clientnum);

	if(is_true(enabled))
	{
		if(!isdefined(level.sndwwent))
			level.sndwwent = Spawn(0, (0, 0, 0), "script_origin");
		
		PlaySound(0, "evt_ww_activate", (0, 0, 0));
		level.sndwwent PlayLoopSound("evt_ww_looper");
		clientscripts\_audio::snd_set_snapshot("zmb_duck_ww");
		player thread clientscripts\_zombiemode::zombie_vision_set_apply("_xS78_whoswho", 50, 0, clientnum);
	}
	else
	{
		if(isdefined(level.sndwwent))
		{
			level.sndwwent Delete();
			level.sndwwent = undefined;
		}

		PlaySound(0, "evt_ww_deactivate", (0, 0, 0));
		clientscripts\_audio::snd_set_snapshot("default");
		player thread clientscripts\_zombiemode::zombie_vision_set_remove("_xS78_whoswho", 0, clientnum);
	}
}