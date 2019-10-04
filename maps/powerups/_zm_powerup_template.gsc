#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup(
		"template", // Internal name of this powerup
		"template_powerup" // The powerups model
	);

	maps\_zm_powerups::register_powerup_ui(
		"template", // Internal name of this powerup
		false, // true/false if to use player.zombie_vars or level.zombie_vars
		"cf_template_powerup", // The powerups clientfield name
		"template_powerup_time", // The powerups time name
		"template_powerup_on" // The powerups on name
	);

	maps\_zm_powerups::register_powerup_fx(
		"template", // Internal name of this powerup
		"powerup_green" // Which fx to play on the powerup (powerup_green)
	);

	maps\_zm_powerups::register_powerup_threads(
		"template", // Internal name of this powerup
		func_can_drop, // Function called to check if powerup can be dropped
		func_grabbed, // Function called to check if powerup can be grabbed
		thread_setup, // Function called to setup this powerup
		func_cleanup // Function called after a powerup as timedout or been grabbed for cleanup
	);

	maps\_zm_powerups::set_powerup_can_pickup_in_laststand(
		"template", // Internal name of this powerup
		false // Can powerup be grabbed in laststand
	);

	maps\_zm_powerups::set_powerup_can_pickup_if_drinking(
		"template", // Internal name of this powerup
		true // Can powerup be grabbed if drinking
	);
}