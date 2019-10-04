#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("free_perk", "p7_zm_power_up_perk_bottle");
	maps\_zm_powerups::register_powerup_fx("free_perk", "powerup_green");
	maps\_zm_powerups::register_powerup_threads("free_perk", undefined, ::free_perk_grabbed, undefined, undefined);
	maps\_zm_powerups::remove_powerup_from_regular_drops("free_perk");
}

free_perk_grabbed(player)
{
	array_thread(GetPlayers(), ::free_perk);
	return true;
}

free_perk()
{
	if(self maps\_laststand::player_is_in_laststand())
		return;
	if(self.sessionstate == "spectator")
		return;

	IPrintLnBold("give random perk");
	self give_random_perk();
}