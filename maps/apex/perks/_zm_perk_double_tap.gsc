#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_perk_for_level()
{
	maps\apex\_zm_perks::register_perk("doubletap", "specialty_doubletap_zombies");
	maps\apex\_zm_perks::register_perk_bottle("doubletap", undefined, undefined, 23);
	maps\apex\_zm_perks::register_perk_machine("doubletap", false, &"ZOMBIE_PERK_DOUBLETAP", 2000, "p7_zm_vending_doubletap2", "p7_zm_vending_doubletap2_on", "perk_light_yellow");
	maps\apex\_zm_perks::register_perk_threads("doubletap", ::give_doubletap, ::take_doubletap);
	maps\apex\_zm_perks::register_perk_sounds("doubletap", "mus_perks_doubletap_sting", "mus_perks_doubletap_jingle", "zmb_hud_flash_jugga");

	maps\apex\_zm_perks::add_perk_specialty("doubletap", "specialty_rof");

	level.zombiemode_using_doubletap_perk = true;
	OnPlayerConnect_Callback(::set_doubletap2_dvar);
}

give_doubletap()
{
}

take_doubletap(reason)
{
}

set_doubletap2_dvar()
{
	self SetClientDvar("perk_weapRateEnhanced", "1");
}