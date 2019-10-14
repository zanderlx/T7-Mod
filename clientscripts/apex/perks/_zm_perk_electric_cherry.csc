#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("cherry");
	clientscripts\apex\_zm_perks::register_perk_threads("cherry", ::give_cherry, ::take_cherry);

	level._effect["cherry_light"] = LoadFX("misc/fx_zombie_cola_on");
	level._effect["electric_cherry_explode"] = LoadFX("sanchez/electric_cherry/cherry_shock_death");
	level._effect["electric_cherry_reload_small"] = LoadFX("sanchez/electric_cherry/cherry_shock_small");
	level._effect["electric_cherry_reload_medium"] = LoadFX("sanchez/electric_cherry/cherry_shock_medium");
	level._effect["electric_cherry_reload_large"] = LoadFX("sanchez/electric_cherry/cherry_shock_large");
	level.zombiemode_using_electriccherry_perk = true;

	add_level_notify_callback("cherry_fx_cancel", ::electric_cherry_reload_attack_fx, 0);
	add_level_notify_callback("cherry_fx_small", ::electric_cherry_reload_attack_fx, 1);
	add_level_notify_callback("cherry_fx_medium", ::electric_cherry_reload_attack_fx, 2);
	add_level_notify_callback("cherry_fx_large", ::electric_cherry_reload_attack_fx, 3);
	add_level_notify_callback("cherry_fx_death", ::electric_cherry_reload_attack_fx, 4);
}

give_cherry(clientnum)
{
}

take_cherry(clientnum)
{
}

electric_cherry_reload_attack_fx(clientnum, newVal)
{
	player = GetLocalPlayer(clientnum);

	if(isdefined(player.electric_cherry_reload_fx))
	{
		StopFX(clientnum, player.electric_cherry_reload_fx);
		player.electric_cherry_reload_fx = undefined;
	}

	switch(newVal)
	{
		case 1:
			player.electric_cherry_reload_fx = PlayFXOnTag(clientnum, level._effect["electric_cherry_reload_small"], player, "tag_origin");
			break;

		case 2:
			player.electric_cherry_reload_fx = PlayFXOnTag(clientnum, level._effect["electric_cherry_reload_medium"], player, "tag_origin");
			break;

		case 3:
			player.electric_cherry_reload_fx = PlayFXOnTag(clientnum, level._effect["electric_cherry_reload_large"], player, "tag_origin");
			break;

		case 4:
			player.electric_cherry_reload_fx = PlayFXOnTag(clientnum, level._effect["electric_cherry_explode"], player, "tag_origin");
			break;
	}
}