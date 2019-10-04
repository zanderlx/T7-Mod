#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("jugg", "uie_moto_perk_juggernog", "zombie_perk_bottle_jugg_t7");
	maps\_zm_perks::register_perk_specialty("jugg", "specialty_armorvest");
	maps\_zm_perks::register_perk_machine("jugg", 2500, &"ZOMBIE_PERK_JUGGERNAUT", "p7_zm_vending_jugg", "p7_zm_vending_jugg_on", "jugger_light", "mus_perks_jugger_sting", "mus_perks_jugger_jingle");
	maps\_zm_perks::register_perk_threads("jugg", ::give_jugg, ::take_jugg, ::pause_jugg, ::unpause_jugg);
	maps\_zm_perks::register_perk_flash_audio("jugg", "zmb_hud_flash_jugga");

	register_player_health(::jugg_health_qualifier, ::jugg_health_amount);

	set_zombie_var("zombie_perk_juggernaut_health", 160);
	set_zombie_var("zombie_perk_juggernaut_health_upgrade", 190);

	level._effect["jugger_light"] = LoadFX("misc/fx_zombie_cola_jugg_on");
	level.zombiemode_using_juggernaut_perk = true;
}

jugg_health_qualifier()
{
	return self has_perk("jugg");
}

jugg_health_amount()
{
	return level.zombie_vars["zombie_perk_juggernaut_health"];
}

give_jugg()
{
	self set_player_max_health(true, false);
}

take_jugg()
{
	self set_player_max_health(true, true);
}

pause_jugg()
{
	self set_player_max_health(true, true);
}

unpause_jugg()
{
	self set_player_max_health(true, false);
}