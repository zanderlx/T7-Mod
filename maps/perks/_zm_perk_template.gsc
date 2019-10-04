#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	// All perk register functions are optional aside from `maps\_zm_perks::register_perk`

	maps\_zm_perks::register_perk(
		"template", // Internal name of this perk
		"template_perk_shader", // The shader material name for this perk
		"template_perk_bottle" // The bottle weapon name for this perk
	);

	maps\_zm_perks::register_perk_specialty(
		"template", // Internal name of this perk
		"specialty_" // Engine perk name to be set / unset with this perk
	);

	maps\_zm_perks::register_perk_machine(
		"template", // Internal name of this perk
		500, // The cost of this perk
		&"TEMPLATE_PERK_HINT_STRING", // This perks hint string
		"template_perk_machine_off", // This perks off machine model
		"template_perk_machine_on", // This perks on machine model
		"template_perk_light", // Light fx played for for this perks machine
		"mus_perks_template_sting", // This perks sting sound
		"mus_perks_template_jingle" // This perks jingle sound
	);

	maps\_zm_perks::register_perk_threads(
		"template", // Internal name of this perk
		undefined, // Function called when perk is obtained
		undefined, // Function called when perk is lost
		undefined, // Function called when perk is paused
		undefined // Function called when perk is unpaused
	);

	maps\_zm_perks::register_perk_flash_audio(
		"template", // Internal name of this perk
		undefined // Sound played when perk hud is flashing
	);

	// level._effect[<MATCH_FX_NAME_ABOVE>] = LoadFX(<PATH_TO_EFX_FILE>);
	level._effect["template_perk_light"] = LoadFX("misc/fx_zombie_cola_jugg_on"); // Light fx played for for this perks machine
}