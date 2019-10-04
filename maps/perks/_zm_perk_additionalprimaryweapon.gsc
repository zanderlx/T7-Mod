#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("additionalprimaryweapon", "uie_moto_perk_mule_kick", "zombie_perk_bottle_additionalprimaryweapon_t7");
	maps\_zm_perks::register_perk_specialty("additionalprimaryweapon", "specialty_additionalprimaryweapon");
	maps\_zm_perks::register_perk_machine("additionalprimaryweapon", 4000, &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON", "p7_zm_vending_three_gun", "p7_zm_vending_three_gun_on", "additionalprimaryweapon_light", "mus_perks_mulekick_sting", "mus_perks_mulekick_jingle");
	maps\_zm_perks::register_perk_threads("additionalprimaryweapon", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("additionalprimaryweapon", "zmb_hud_flash_additionalprimaryweapon");

	set_zombie_var("zombie_perk_additionalprimaryweapon_count", 1);

	level._effect["additionalprimaryweapon_light"] = LoadFX("apex/misc/fx_zombie_cola_arsenal_on");
	level.zombiemode_using_additionalprimaryweapon_perk = true;
	place_additionalprimaryweapon_machine();
}

place_additionalprimaryweapon_machine()
{
	if(!isdefined(level.zombie_additionalprimaryweapon_machine_origin))
		return;

	struct = maps\_zm_perks::generate_machine_location("additionalprimaryweapon", level.zombie_additionalprimaryweapon_machine_origin, level.zombie_additionalprimaryweapon_machine_angles);
}