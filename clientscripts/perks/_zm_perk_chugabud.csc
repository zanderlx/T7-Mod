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
	clientscripts\_visionset_mgr::visionset_register_info("whoswho_vision", "_xS78_whoswho", 51, 0, 0, false);
}

whoswhoaudio(clientnum, enabled)
{
	if(is_true(enabled))
	{
		if(!isdefined(level.sndwwent))
			level.sndwwent = Spawn(0, (0, 0, 0), "script_origin");

		PlaySound(0, "evt_ww_activate", (0, 0, 0));
		level.sndwwent PlayLoopSound("evt_ww_looper");
		clientscripts\_audio::snd_set_snapshot("zmb_duck_ww");
		clientscripts\_visionset_mgr::visionset_activate(clientnum, "whoswho_vision");
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
		clientscripts\_visionset_mgr::visionset_deactivate(clientnum, "whoswho_vision");
	}
}