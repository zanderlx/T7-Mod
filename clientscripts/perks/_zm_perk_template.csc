#include clientscripts\_utility;
#include clientscripts\_zm_utility;

include_perk_for_level()
{
	clientscripts\_zm_perks::register_perk(
		"template", // Internal name of this perk
		undefined, // Function called when perk is obtained
		undefined, // Function called when perk is lost 
		undefined, // Function called when perk is paused
		undefined // Function called when perk is unpaused
	);

	// MATCH FX NAMES FROM GSC
	level._effect["template_perk_light"] = LoadFX("misc/fx_zombie_cola_jugg_on"); // Light fx played for for this perks machine
}