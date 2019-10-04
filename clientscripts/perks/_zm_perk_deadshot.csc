#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk("deadshot", ::give_deadshot, ::take_deadshot, ::take_deadshot, ::give_deadshot);

	level._effect["deadshot_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level.zombiemode_using_deadshot_perk = true;
}

give_deadshot(clientnum)
{
	player = GetLocalPlayer(clientnum);

	if(!player IsLocalPlayer() || player IsSpectating())
		return;

	player UseAlternateAimParams();
}

take_deadshot(clientnum)
{
	player = GetLocalPlayer(clientnum);

	if(!player IsLocalPlayer() || player IsSpectating())
		return;

	player ClearAlternateAimParams();
}