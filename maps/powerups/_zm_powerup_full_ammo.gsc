#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	PrecacheString(&"ZOMBIE_POWERUP_MAX_AMMO");

	maps\_zm_powerups::register_powerup("full_ammo", "p7_zm_power_up_max_ammo");
	maps\_zm_powerups::register_powerup_fx("full_ammo", "powerup_green");
	maps\_zm_powerups::register_powerup_threads("full_ammo", undefined, ::full_ammo_grabbed, undefined, undefined);
}

full_ammo_grabbed(player)
{
	array_thread(GetPlayers(), ::full_ammo);
	level thread full_ammo_on_hud();
	return true;
}

full_ammo()
{
	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;

	self notify("zmb_max_ammo");
	self notify("zmb_lost_knife");

	placeable_mine = self get_player_placeable_mine();

	if(isdefined(placeable_mine) && placeable_mine != "none")
		self maps\_zm_placeable_mine::disable_placeable_mine_triggers(placeable_mine);

	weapons = self GetWeaponsList();

	for(i = 0; i < weapons.size; i++)
	{
		if(isdefined(level.zombie_weapons_no_max_ammo) && IsInArray(level.zombie_weapons_no_max_ammo, weapons[i]))
			continue;

		type = WeaponInventoryType(weapons[i]);

		if(type == "primary" || type == "altmode")
		{
			self SetWeaponAmmoClip(weapons[i], WeaponClipSize(weapons[i]));
			dw_name = maps\_zm_weapons::get_weapon_dual_wield_name(weapons[i]);

			if(dw_name != "none")
				self SetWeaponAmmoClip(dw_name, WeaponClipSize(dw_name));
		}
		self GiveMaxAmmo(weapons[i]);
	}
}

full_ammo_on_hud()
{
	hud = maps\_hud_util::createFontString("objective", 2);
	hud maps\_hud_util::setPoint("TOP", undefined, 0, 290);
	hud.sort = .5;
	hud.alpha = 0;
	hud FadeOverTime(.5);
	hud.alpha = 1;
	hud.label = &"ZOMBIE_POWERUP_MAX_AMMO";
	PlaySoundAtPosition("zmb_full_ammo", (0, 0, 0));
	wait .5;
	hud FadeOverTime(1.5);
	hud MoveOverTime(1.5);
	hud.y = 270;
	hud.alpha = 0;
	wait 1.5;
	hud Destroy();
}