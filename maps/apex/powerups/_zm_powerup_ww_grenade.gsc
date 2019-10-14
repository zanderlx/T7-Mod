#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("ww_grenade", "p7_zm_power_up_widows_wine", "powerup_blue");
	maps\apex\_zm_powerups::register_powerup_funcs("ww_grenade", undefined, ::grab_ww_grenade, undefined, maps\apex\_zm_powerups::func_should_never_drop);
}

grab_ww_grenade(player)
{
	player thread ww_grenade_powerup();
}

ww_grenade_powerup()
{
	if(!self maps\_laststand::player_is_in_laststand() && self.sessionstate != "spectator")
	{
		if(self has_perk("widows"))
		{
			current_lethal_grenade = self get_player_lethal_grenade();
			oldammo = self GetWeaponAmmoClip(current_lethal_grenade);
			maxammo = WeaponStartAmmo(current_lethal_grenade);
			newammo = Int(Min(maxammo, Max(0, oldammo + 1)));
			self SetWeaponAmmoClip(current_lethal_grenade, newammo);
		}
	}
}