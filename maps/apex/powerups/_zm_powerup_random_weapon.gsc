#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	level.random_weapon_powerups = [];

	maps\apex\_zm_powerups::register_basic_powerup("random_weapon", "tag_origin", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("random_weapon", ::setup_random_weapon, ::grab_random_weapon, ::cleanup_random_weapon, maps\apex\_zm_powerups::func_should_never_drop);
	maps\apex\_zm_powerups::powerup_set_prevent_pick_up_if_drinking("random_weapon", true);
	maps\apex\_zm_powerups::powerup_set_can_pick_up_in_last_stand("random_weapon", false);
	maps\apex\_zm_powerups::powerup_set_can_pick_up_in_revive_trigger("random_weapon", false);

	maps\apex\_zm_magicbox::add_custom_limited_weapon_check(::is_weapon_available_in_random_weapon_powerup);
}

setup_random_weapon()
{
	self.weapon = maps\apex\_zm_magicbox::treasure_chest_ChooseWeightedRandomWeapon();
	self.base_weapon = self.weapon;

	level.random_weapon_powerups[level.random_weapon_powerups.size] = self;

	if(maps\apex\_zm_weapons::can_upgrade_weapon(self.weapon) && !RandomInt(4))
		self.weapon = maps\apex\_zm_weapons::get_upgrade_weapon(self.weapon);

	self maps\apex\_zm_weapons::model_use_weapon_options(self.weapon);
}

grab_random_weapon(player)
{
	return self random_weapon_powerup(player);
}

cleanup_random_weapon()
{
	level.random_weapon_powerups = array_remove_nokeys(level.random_weapon_powerups, self);
	self maps\apex\_zm_weapons::delete_weapon_model();
	level.random_weapon_powerups = array_removeUndefined(level.random_weapon_powerups);
}

random_weapon_powerup_throttle()
{
	self.random_weapon_powerup_throttle = true;
	wait .25;
	self.random_weapon_powerup_throttle = false;
}

random_weapon_powerup(player)
{
	if(player.sessionstate == "spectator")
		return true;
	if(is_true(player.random_weapon_powerup_throttle) || player IsSwitchingWeapons())
		return true;

	current_weapon = player GetCurrentWeapon();
	current_weapon_type = WeaponInventoryType(current_weapon);

	if(!is_tactical_grenade(self.weapon))
	{
		if(current_weapon_type != "primary" && current_weapon_type != "altmode")
			return true;

		if(maps\apex\_zm_weapons::is_weapon_upgraded(self.weapon))
		{
			if(!maps\apex\_zm_weapons::is_weapon_included(self.base_weapon))
				return true;
		}
		else
		{
			if(!maps\apex\_zm_weapons::is_weapon_included(self.weapon))
				return true;
		}
	}

	player thread random_weapon_powerup_throttle();
	player maps\apex\_zm_weapons::weapon_give(self.weapon, false, true);
	return false;
}

is_weapon_available_in_random_weapon_powerup(weapon, ignore_player)
{
	count = 0;

	if(isdefined(level.random_weapon_powerups) && level.random_weapon_powerups.size > 0)
	{
		for(i = 0; i < level.random_weapon_powerups.size; i++)
		{
			if(!isdefined(level.random_weapon_powerups[i]))
				continue;
			if(level.random_weapon_powerups[i].base_weapon == weapon || level.random_weapon[i].weapon == weapon)
				count++;
		}
	}
	return count;
}