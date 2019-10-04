#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("divetonuke", "uie_moto_perk_divetonuke", "zombie_perk_bottle_nuke_t7");
	maps\_zm_perks::register_perk_specialty("divetonuke", "specialty_flakjacket");
	maps\_zm_perks::register_perk_machine("divetonuke", 2000, &"ZOMBIE_PERK_DIVETONUKE", "p7_zm_vending_nuke", "p7_zm_vending_nuke_on", "divetonuke_light", "mus_perks_phd_sting", "mus_perks_phd_jingle");
	maps\_zm_perks::register_perk_threads("divetonuke", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("divetonuke", "zmb_hud_flash_phd");

	set_zombie_var("zombie_perk_divetonuke_radius", 300);
	set_zombie_var("zombie_perk_divetonuke_min_damage", 1000);
	set_zombie_var("zombie_perk_divetonuke_max_damage", 5000);

	level._effect["divetonuke_light"] = LoadFX("misc/fx_zombie_cola_dtap_on");
	level._effect["divetonuke_groundhit"] = LoadFX("apex/maps/zombie/fx_zmb_phdflopper_exp");
	level.zombiemode_using_divetonuke_perk = true;
	level.zombiemode_divetonuke_perk_func = ::divetonuke_explode;
}

divetonuke_explode(attacker, origin)
{
	RadiusDamage(origin, level.zombie_vars["zombie_perk_divetonuke_radius"], level.zombie_vars["zombie_perk_divetonuke_max_damage"], level.zombie_vars["zombie_perk_divetonuke_min_damage"], attacker, "MOD_GRENADE_SPLASH");
	PlayFX(level._effect["divetonuke_groundhit"], origin);
	attacker PlaySound("zmb_phdflop_explo");
	attacker visionset_activate("divetonuke_vision");
	wait .5;
	attacker visionset_deactivate("divetonuke_vision");
}