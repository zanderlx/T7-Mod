#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	maps\_zm_perks::register_perk("widows", "uie_moto_perk_widows", "zombie_perk_bottle_widowswine_t7");
	maps\_zm_perks::register_perk_machine("widows", 2000, &"ZOMBIE_PERK_WIDOWSWINE", "p7_zm_vending_widows_wine", "p7_zm_vending_widows_wine_on", "widows_light", "mus_perks_widows_sting", "mus_perks_widows_jingle");
	maps\_zm_perks::register_perk_threads("widows", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("widows", undefined);

	level._effect["widows_light"] = LoadFX("misc/fx_zombie_cola_jugg_on");
	level.zombiemode_using_widows_perk = true;

	// include_powerup_for_level();
}

// Powerup
include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("ww_grenade", "p7_zm_power_up_widows_wine");
	maps\_zm_powerups::register_powerup_fx("ww_grenade", "powerup_blue");
	maps\_zm_powerups::register_powerup_threads("ww_grenade", undefined, ::ww_grenade_grabbed, undefined, undefined);
	maps\_zm_powerups::remove_powerup_from_regular_drops("ww_grenade");
}

ww_grenade_grabbed(player)
{
	if(!player maps\_laststand::player_is_in_laststand() && player.sessionstate != "spectator")
	{
		if(player has_perk("widows"))
		{
			grenade = player get_player_lethal_grenade();
			oldAmmo = player GetWeaponAmmoClip(grenade);
			maxAmmo = WeaponStartAmmo(grenade);
			newAmmo = Int(Min(maxAmmo, Max(0, oldAmmo + 1)));
			player SetWeaponAmmoClip(grenade, newAmmo);
		}
	}
	return true;
}