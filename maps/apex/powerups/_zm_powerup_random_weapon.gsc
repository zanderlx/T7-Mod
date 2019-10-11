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
}

setup_random_weapon()
{
	self.weapon = maps\apex\_zm_magicbox::treasure_chest_ChooseWeightedRandomWeapon();
	self.base_weapon = self.weapon;

	level.random_weapon_powerups[level.random_weapon_powerups.size] = self;

	if(isdefined(level.zombie_weapons[self.weapon].upgrade_name) && !RandomInt(4))
		self.weapon = level.zombie_weapons[self.weapon].upgrade_name;

	self SetModel(GetWeaponModel(self.weapon));
	self UseWeaponHideTags(self.weapon);

	if(maps\apex\_zm_weapons::weapon_is_dual_wield(self.weapon))
	{
		self.worldgundw = spawn_model(maps\apex\_zm_weapons::get_left_hand_weapon_model_name(self.weapon), self.origin + (3, 3, 3), self.angles);
		self.worldgundw UseWeaponHideTags(self.weapon);
		self.worldgundw LinkTo(self, "tag_weapon", (3, 3, 3), (0, 0, 0));
	}
}

grab_random_weapon(player)
{
	return self random_weapon_powerup(player);
}

cleanup_random_weapon()
{
	if(isdefined(self.worldgundw))
	{
		self.worldgundw Unlink();
		self.worldgundw Delete();
		self.worldgundw = undefined;
	}

	level.random_weapon_powerups = array_remove_nokeys(level.random_weapon_powerups, self);
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