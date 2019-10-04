#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	level._zm_weapons = [];
	level._zm_alt_weapons = [];
	level._zm_lh_weapons = [];
	level._zm_weapons_list = [];

	level.zombie_lethal_grenade_list = [];
	level.zombie_tactical_grenade_list = [];
	level.zombie_placeable_mine_list = [];
	level.zombie_melee_weapon_list = [];
	level.zombie_equipment_list = [];

	level.zombie_lethal_grenade_player_init = "frag_grenade_zm";
	level.zombie_tactical_grenade_player_init = undefined;
	level.zombie_placeable_mine_player_init = undefined;
	level.zombie_melee_weapon_player_init = "knife_zm";
	level.zombie_equipment_player_init = undefined;

	// REMOVEME:
	level.zombie_weapons = [];

	maps\_zm_placeable_mine::init();
	maps\_zm_melee_weapon::init();

	load_weapons_for_level();
	precache_weapon_data();

	maps\_zm_weap_wallbuys::init();
	maps\_zm_hero_weapons::init();
	maps\_zm_lightning_chain::init();

	add_custom_limited_weapon_check(::is_weapon_available_in_player);
	add_custom_limited_weapon_check(::is_weapon_available_in_packapunch);
	add_custom_limited_weapon_check(::is_weapon_available_in_powerups);

	level thread register_weapon_data_client_side();
}

precache_weapon_data()
{
	set_zombie_var("zombie_weapons_upgrade_ammo_cost", 4500);
	set_zombie_var("zombie_weapons_ammo_cost_fraction", 2);
	set_zombie_var("zombie_weapons_base_limit", 2);
	// set_zombie_var("zombie_weapons_slot_", 1);
	// set_zombie_var("zombie_weapons_slot_", 2);
	// set_zombie_var("zombie_weapons_slot_", 3);

	PrecacheString(&"ZOMBIE_DYN_WEAPONCOST");
	PrecacheString(&"ZOMBIE_DYN_WEAPONCOSTAMMO");
	PrecacheString(&"ZOMBIE_DYN_WEAPONCOSTAMMO_UPGRADE");

	// TODO: Precache / Set these from correct scripts
	level._uses_retrievable_ballisitic_knives = true;
	PrecacheModel("t5_weapon_ballistic_knife_blade");
	PrecacheModel("t5_weapon_ballistic_knife_blade_retrieve");
}

play_weapon_vo(weapon_name)
{
	type = self get_weapon_vox_type(weapon_name);
	self maps\_zombiemode_audio::create_and_play_dialog("weapon_pickup", type);
}

get_weapon_vox_type(weapon_name)
{
	if(!isdefined(self.entity_num))
		return "crappy";

	if(is_weapon_upgraded(weapon_name))
	{
		if(isdefined(self.faviorite_weapons) && IsInArray(self.faviorite_weapons, weapon_name))
			return "favorite_upgrade";
		return "upgrade";
	}
	else
	{
		if(isdefined(self.faviorite_weapons) && IsInArray(self.faviorite_weapons, weapon_name))
			return "favorite";
	}

	weapon_stats = get_weapon_stats(weapon_name);

	if(isdefined(weapon_stats.vox))
		return weapon_stats.vox;
	return "crappy";
}

// Give / Take
weapon_give(weapon_name, switch_weapon)
{
	primaryWeapons = self GetWeaponsListPrimaries();
	initial_current_weapon = self GetCurrentWeapon();
	current_weapon = self switch_from_alt_weapon(initial_current_weapon);
	weapon_limit = self get_player_weapon_limit();

	if(!isdefined(switch_weapon))
		switch_weapon = true;

	// give ammo if already own weapon
	if(is_equipment(weapon_name))
		self maps\_zombiemode_equipment::equipment_give(weapon_name);
	/*
	if(is_weapon_riotshield(weapon_name))
		self maps\_zm_weap_riotshield::reset_shield_health();
	*/

	if(self HasWeapon(weapon_name))
	{
		if(is_ballistic_knife(weapon_name))
			self notify("zmb_lost_knife");

		self GiveStartAmmo(weapon_name);

		if(switch_weapon && !is_offhand_weapon(weapon_name))
			self SwitchToWeapon(weapon_name);

		self notify("weapon_give", weapon_name);
		return weapon_name;
	}

	// swap offhand weapon types
	if(is_melee_weapon(weapon_name))
		current_weapon = maps\_zm_melee_weapon::change_melee_weapon(weapon_name, current_weapon);
	else if(is_hero_Weapon(weapon_name))
	{
		self weapon_take(self get_player_hero_weapon());
		self set_player_hero_weapon(weapon_name);
	}
	else if(is_lethal_grenade(weapon_name))
	{
		self weapon_take(self get_player_lethal_grenade());
		self set_player_lethal_grenade(weapon_name);
	}
	else if(is_tactical_grenade(weapon_name))
	{
		self weapon_take(self get_player_tactical_grenade());
		self set_player_tactical_grenade(weapon_name);
	}
	else if(is_placeable_mine(weapon_name))
	{
		self weapon_take(self get_player_placeable_mine());
		self set_player_placeable_mine(weapon_name);
	}

	// take current weapon if above weapon limit
	if(primaryWeapons.size >= weapon_limit)
	{
		if(is_placeable_mine(current_weapon) || is_equipment(current_weapon))
			current_weapon = undefined;

		if(isdefined(current_weapon))
		{
			if(!is_offhand_weapon(weapon_name))
				self weapon_take(current_weapon);
		}
	}

	// give weapon
	if(isdefined(level.zombiemode_offhand_weapon_give_override))
	{
		result = run_function(self, level.zombiemode_offhand_weapon_give_override, weapon_name);

		if(is_true(result))
		{
			self notify("weapon_give", weapon_name);
			return weapon_name;
		}
	}

	if(is_ballistic_knife(weapon_name))
		weapon_name = self maps\_zm_melee_weapon::give_ballistic_knife(weapon_name);
	else if(is_placeable_mine(weapon_name))
	{
		self maps\_zm_placeable_mine::give_placeable_mine(weapon_name);
		self notify("weapon_give", weapon_name);
		return weapon_name;
	}

	if(isdefined(level.zombie_weapon_callbacks) && isdefined(level.zombie_weapon_callbacks[weapon_name]))
	{
		single_thread(self, level.zombie_weapon_callbacks[weapon_name]);
		self notify("weapon_give", weapon_name);
		return weapon_name;
	}

	self give_buildkit_weapon(weapon_name);
	self GiveStartAmmo(weapon_name);

	if(switch_weapon && !is_offhand_weapon(weapon_name))
		self SwitchToWeapon(weapon_name);

	self notify("weapon_give", weapon_name);
	return weapon_name;
}

weapon_take(weapon_name)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return;
	if(is_ballistic_knife(weapon_name))
		self notify("zmb_lost_knife");

	self notify("weapon_take", weapon_name);

	if(self HasWeapon(weapon_name))
		self TakeWeapon(weapon_name);
}

give_weapon_or_ammo(weapon_name)
{
	// give weapon if dont already have it
	if(!self has_any_weapon_variant(weapon_name))
	{
		self weapon_give(weapon_name);
		return true;
	}

	// check if weapon can be given ammo
	if(is_offhand_weapon(weapon_name))
		return false;

	// try give weapon ammo
	return self ammo_give(weapon_name);
}

ammo_give(weapon_name)
{
	if(!self has_any_weapon_variant(weapon_name))
		return false;

	if(is_offhand_weapon(weapon_name))
	{
		if(!is_lethal_grenade(weapon_name) && !is_tactical_grenade(weapon_name))
			return false;
	}

	ammo_weapon = self get_player_weapon_with_same_base(weapon_name);

	if(!isdefined(ammo_weapon))
		ammo_weapon = weapon_name;

	if(is_offhand_weapon(ammo_weapon))
	{
		if(self GetAmmoCount(ammo_weapon) < WeaponMaxAmmo(ammo_weapon))
			give_ammo = true;
		else
			give_ammo = false;
	}
	else
	{
		dw_weapon = get_weapon_dual_wield_name(ammo_weapon);
		stockMax = WeaponMaxAmmo(ammo_weapon);
		clipCount = self GetWeaponAmmoClip(ammo_weapon);
		currStock = self GetAmmoCount(ammo_weapon);

		if(dw_weapon == "none")
		{
			if(currStock - clipCount >= stockMax)
				give_ammo = false;
			else
				give_ammo = true;
		}
		else
		{
			lhClipCount = self GetWeaponAmmoClip(dw_weapon);

			if(currStock - clipCount + lhClipCount >= stockMax)
				give_ammo = false;
			else
				give_ammo = true;
		}
	}

	if(give_ammo)
	{
		self GiveStartAmmo(ammo_weapon);
		self notify("weapon_ammo_give", ammo_weapon);
	}
	return give_ammo;
}

// Getters
get_weapons_list()
{
	return level._zm_weapons_list;
}

get_nonealt_weapon(weapon_name)
{
	if(is_alt_weapon(weapon_name))
	{
		alt_weapon = get_weapon_alt_name(weapon_name);

		if(alt_weapon != "" && alt_weapon != "none")
			return alt_weapon;
	}
	return weapon_name;
}

get_rh_weapon(weapon_name)
{
	if(is_lh_weapon(weapon_name))
	{
		weapons_list = get_weapons_list();

		for(i = 0; i < weapons_list.size; i++)
		{
			lh_weapon = get_weapon_dual_wield_name(weapons_list[i]);

			if(is_lh_weapon(weapon_name) && lh_weapon == weapon_name)
				return weapons_list[i];
		}
	}
	return weapon_name;
}

get_weapon_stats(weapon_name)
{
	weapon_name = get_nonealt_weapon(weapon_name);
	return level._zm_weapons[weapon_name];
}

get_root_weapon(weapon_name)
{
	weapon_name = get_nonealt_weapon(weapon_name); // none alt weapons
	weapons_list = get_weapons_list();
	is_dw = is_lh_weapon(weapon_name);

	for(i = 0; i < weapons_list.size; i++)
	{
		lh_weapon = get_weapon_dual_wield_name(weapons_list[i]);

		// Left Hand DW -> Right Hand DW
		if(is_dw && is_lh_weapon(weapons_list[i]) && lh_weapon == weapon_name)
			return weapons_list[i];

		weapon_stats = get_weapon_stats(weapons_list[i]);

		if(!isdefined(weapon_stats))
			continue;

		// Upgraded -> Downgraded
		if(weapon_stats.upgrade_name == weapon_name)
			return weapons_list[i];
	}

	return weapon_name;
}

get_player_weapon_with_same_base(weapon_name)
{
	// return the first 'player' weapon that has the same root weapon as specified weapon
	root_weapon = get_root_weapon(weapon_name);
	weapons = self GetWeaponsListPrimaries();

	for(i = 0; i < weapons.size; i++)
	{
		test = get_root_weapon(weapons[i]);

		if(test == root_weapon)
			return weapons[i];
	}
	return undefined;
}

get_weapon_upgrade_name(weapon_name)
{
	weapon_stats = get_weapon_stats(weapon_name);
	return weapon_stats.upgrade_name;
}

get_weapon_dual_wield_name(weapon_name)
{
	weapon_name = get_nonealt_weapon(weapon_name);
	return WeaponDualWieldWeaponName(weapon_name);
}

get_weapon_alt_name(weapon_name)
{
	return WeaponAltWeaponName(weapon_name);
}

// Setters
// Utils
is_weapon_included(weapon_name)
{
	return isdefined(level._zm_weapons[weapon_name]);
}

is_weapon_or_base_included(weapon_name)
{
	if(!is_weapon_included(weapon_name))
		return false;
	base_weapon = get_root_weapon(weapon_name);
	return is_weapon_included(base_weapon);
}

switch_from_alt_weapon(alt_weapon)
{
	weapon_name = get_nonealt_weapon(alt_weapon);

	if(alt_weapon != weapon_name)
	{
		self SwitchToWeapon(weapon_name);
		self waittill_notify_or_timeout("weapon_change_complete", 1);
	}
	return weapon_name;
}

switch_back_primary_weapon(oldprimary)
{
	if(self maps\_laststand::player_is_in_laststand())
		return;

	if(!isdefined(oldprimary) || oldprimary == "none" || is_offhand_weapon(oldprimary) || !self HasWeapon(oldprimary))
		oldprimary = undefined;
	else if(is_hero_weapon(oldprimary) && self get_player_hero_weapon_power() <= 0)
		oldprimary = undefined;

	primaryWeapons = self GetWeaponsListPrimaries();

	if(isdefined(oldprimary) && IsInArray(primaryWeapons, oldprimary))
		self SwitchToWeapon(oldprimary);
	else if(primaryWeapons.size > 0)
		self SwitchToWeapon(primaryWeapons[0]);
}

can_upgrade_weapon(weapon_name)
{
	upgrade_name = get_weapon_upgrade_name(weapon_name);
	return upgrade_name != "none";
}

is_weapon_upgraded(weapon_name)
{
	root_weapon = get_root_weapon(weapon_name);
	root_weapon_stats = get_weapon_stats(root_weapon);
	return isdefined(root_weapon_stats) && root_weapon_stats.upgrade_name == weapon_name;
}

is_wonder_weapon(weapon_name)
{
	weapon_stats = get_weapon_stats(weapon_name);
	return is_true(weapon_stats.is_wonder_weapon);
}

has_weapon_or_root(weapon_name)
{
	root_weapon = get_root_weapon(weapon_name);

	if(self HasWeapon(weapon_name))
		return true;
	if(root_weapon != weapon_name && self HasWeapon(root_weapon))
		return true;
	if(is_ballistic_knife(root_weapon) && self maps\_zm_melee_weapon::has_any_ballistic_knife())
		return true;
	return false;
}

has_weapon_upgrade(weapon_name)
{
	weapon_name = get_nonealt_weapon(weapon_name);

	if(is_ballistic_knife(weapon_name) && self maps\_zm_melee_weapon::has_upgraded_ballistic_knife())
		return true;
	if(is_weapon_upgraded(weapon_name) && self HasWeapon(weapon_name))
		return true;

	if(can_upgrade_weapon(weapon_name))
	{
		upgrade_name = get_weapon_upgrade_name(weapon_name);

		if(self HasWeapon(upgrade_name))
			return true;
	}
	return false;
}

has_weapon_or_upgrade(weapon_name)
{
	if(self has_weapon_upgrade(weapon_name))
		return true;
	if(self HasWeapon(weapon_name))
		return true;
	return false;
}

has_any_weapon_variant(weapon_name)
{
	if(self has_weapon_or_root(weapon_name))
		return true;
	if(self has_weapon_or_upgrade(weapon_name))
		return true;
	return false;
}

// Weapon Model
spawn_weapon_model(weapon_name, origin, angles, player)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return undefined;
	if(!isdefined(origin))
		return undefined;
	if(!isdefined(angles))
		angles = (0, 0, 0);

	model = spawn_model("tag_origin", origin, angles);
	model model_use_weapon_options(weapon_name, player);

	return model;
}

model_use_weapon_options(weapon_name, player)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return;

	weapon_options = get_weapon_model_options(weapon_name, player);

	self SetModel(GetWeaponModel(weapon_name));
	self UseWeaponHideTags(weapon_name);
	self.weapon_name = weapon_name;
	self.weapon_options = weapon_options;
	// self SetWeaponOptions(weapon_options);

	dw_weapon = get_weapon_dual_wield_name(weapon_name);

	if(isdefined(self.lh_model))
	{
		if(dw_weapon == "none")
		{
			self.lh_model Hide();
			// self.lh_model Unlink();
			// self.lh_model Delete();
			// self.lh_model = undefined;
		}
		else
		{
			self.lh_model SetModel(GetWeaponModel(dw_weapon));
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model Show();
			// self.lh_model SetWeaponOptions(weapon_options);
		}
	}
	else
	{
		if(dw_weapon != "none")
		{
			self.lh_model = spawn_model(GetWeaponModel(dw_weapon), self.origin + (3, 3, 3), self.angles);
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model LinkTo(self);
			// self.lh_model SetWeaponOptions(weapon_options);
		}
	}
}

model_show_weapon()
{
	if(isdefined(self.lh_model))
		self.lh_model Show();
	self Show();
}

model_hide_weapon()
{
	if(isdefined(self.lh_model))
		self.lh_model Hide();
	self Hide();
}

delete_weapon_model()
{
	if(isdefined(self.lh_model))
	{
		self.lh_model Unlink();
		self.lh_model Delete();
		self.lh_model = undefined;
	}

	self Delete();
}

get_weapon_model_options(weapon_name, player)
{
	if(!isdefined(player))
		return get_default_weapon_options();

	return player get_weapon_options(weapon_name);
}

// Weapon Build Kits
give_buildkit_weapon(weapon_name)
{
	weapon_options = self get_weapon_options(weapon_name);
	model_index = 0;
	self GiveWeapon(weapon_name, model_index, weapon_options);

	// if(is_ballistic_knife(weapon_name))
	// 	self maps\_zm_melee_weapon::give_ballistic_knife(weapon_name);
}

// Weapon Options
get_default_weapon_options()
{
	if(isdefined(level._zm_default_weapon_options))
		return level._zm_default_weapon_options;
	else
	{
		if(IsPlayer(self))
		{
			level._zm_default_weapon_options = self CalcWeaponOptions(0);
			return level._zm_default_weapon_options;
		}
		return 0;
	}
}

get_weapon_options(weapon_name)
{
	if(!isdefined(self._zm_weapon_options))
		self._zm_weapon_options = [];
	if(isdefined(self._zm_weapon_options[weapon_name]))
		return self._zm_weapon_options[weapon_name];

	weapon_options = self calc_default_weapon_options(weapon_name);
	self set_weapon_options(weapon_name, weapon_options);
	return weapon_options;
}

set_weapon_options(weapon_name, weapon_options)
{
	if(!isdefined(self._zm_weapon_options))
		self._zm_weapon_options = [];
	self._zm_weapon_options[weapon_name] = weapon_options;

	if(self HasWeapon(weapon_name))
		self UpdateWeaponOptions(weapon_name, weapon_options);
}

calc_default_weapon_options(weapon_name)
{
	if(is_weapon_upgraded(weapon_name))
	{
		ci = 15;
		li = RandomIntRange(0, 6);
		ri = RandomIntRange(0, 20);
		rci = RandomIntRange(0, 6);

		if(ri == 8) // scary eyes | weapon_reticle_zom_eyes
			rci = 3; // purple color | 175 0 255
		if(ri == 2) // letter a | weapon_reticle_zom_a
			rci = 6; // pink color | 255 105 180
		if(ri == 7) // letter e | weapon_reticle_zom_e
			rci = 1; // green color | 0 255 0

		// Famas always has smiley face
		if(weapon_name == "famas_upgraded_zm")
			ri = 21;

		return self CalcWeaponOptions(ci, li, ri, rci);
	}
	else
		return self get_default_weapon_options();
}

// Weapon Limits
limited_weapon_below_quota(weapon_name, ignore_player)
{
	// level marked as to not include limited weapons
	if(is_true(level.no_limited_weapons))
		return false;
	// no limited weapon_name checks exist, assume below quota
	if(!isdefined(level.custom_limited_weapon_checks) || level.custom_limited_weapon_checks.size == 0)
		return true;

	weapon_stats = get_weapon_stats(weapon_name);
	limit = weapon_stats.limit;

	// limit not set or below 0, all players can have this weapon
	if(!isdefined(limit) || limit <= -1)
		return true;

	count = 0;

	for(i = 0; i < level.custom_limited_weapon_checks.size; i++)
	{
		func = level.custom_limited_weapon_checks[i];

		if(!isdefined(func))
			continue;

		count += run_function(level, func, weapon_name, ignore_player);

		// too many items have this weapon
		if(count >= limit)
			return false;
	}
	// weapon below quote, players can obtain it
	return true;
}

add_custom_limited_weapon_check(func)
{
	if(!isdefined(level.custom_limited_weapon_checks))
		level.custom_limited_weapon_checks = [];
	level.custom_limited_weapon_checks[level.custom_limited_weapon_checks.size] = func;
}

remove_custom_limited_weapon_check(func)
{
	if(isdefined(level.custom_limited_weapon_checks) && IsInArray(level.custom_limited_weapon_checks))
		level.custom_limited_weapon_checks = ArrayRemoveValue(level.custom_limited_weapon_checks, func, false);
}

is_weapon_available_in_player(weapon_name, ignore_player)
{
	players = GetPlayers();
	count = 0;

	for(i = 0; i < players.size; i++)
	{
		if(isdefined(ignore_player) && players[i] != ignore_player)
			continue;

		if(players[i] has_any_weapon_variant(weapon_name))
			count++;
	}
	return count;
}

is_weapon_available_in_packapunch(weapon_name, ignore_player)
{
	triggers = GetEntArray("zombie_vending_upgrade", "targetname");
	count = 0;

	for(i = 0; i < triggers.size; i++)
	{
		if(isdefined(triggers[i].current_weapon) && triggers[i].current_weapon == weapon_name)
			count++;
	}

	return count;
}

is_weapon_available_in_powerups(weapon_name, ignore_player)
{
	count = 0;

	if(isdefined(level.random_weapon_powerups))
	{
		for(i = 0; i < level.random_weapon_powerups.size; i++)
		{
			if(isdefined(level.random_weapon_powerups[i]) && level.random_weapon_powerups[i].weapon == weapon_name)
				count++;
		}
	}

	return count;
}

// Weapon Data
get_default_weapondata(weapon_name)
{
	dw_weapon = get_weapon_dual_wield_name(weapon_name);
	alt_weapon = get_weapon_alt_name(weapon_name);

	weapondata = [];
	weapondata["weapon"] = weapon_name;
	weapondata["clip"] = WeaponClipSize(weapon_name);
	weapondata["stock"] = WeaponMaxAmmo(weapon_name);

	if(dw_weapon == "none")
		weapondata["lh_clip"] = 0;
	else
		weapondata["lh_clip"] = WeaponClipSize(dw_weapon);

	if(alt_weapon == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = WeaponClipSize(alt_weapon);
		weapondata["alt_stock"] = WeaponMaxAmmo(alt_weapon);
	}
	return weapondata;
}

get_player_weapondata(player, weapon_name)
{
	if(!isdefined(weapon_name))
		weapon_name = player GetCurrentWeapon();

	dw_weapon = get_weapon_dual_wield_name(weapon_name);
	alt_weapon = get_weapon_alt_name(weapon_name);

	weapondata = [];
	weapondata["weapon"] = weapon_name;

	if(weapon_name == "none")
	{
		weapondata["clip"] = 0;
		weapondata["stock"] = 0;
	}
	else
	{
		weapondata["clip"] = player GetWeaponAmmoClip(weapon_name);
		weapondata["stock"] = player GetWeaponAmmoStock(weapon_name);
	}

	if(dw_weapon == "none")
		weapondata["lh_clip"] = 0;
	else
		weapondata["lh_clip"] = player GetWeaponAmmoClip(dw_weapon);

	if(alt_weapon == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = player GetWeaponAmmoClip(alt_weapon);
		weapondata["alt_stock"] = player GetWeaponAmmoStock(alt_weapon);
	}
	return weapondata;
}

weapon_is_better(left, right)
{
	if(left != right)
	{
		left_upgraded = is_weapon_upgraded(left);
		right_upgraded = is_weapon_upgraded(right);

		if(left_upgraded && right_upgraded)
			return cointoss();
		else if(left_upgraded)
			return true;
	}
	return false;
}

merge_weapons(oldweapondata, newweapondata)
{
	weapondata = [];

	if(weapon_is_better(oldweapondata["weapon"], newweapondata["weapon"]))
		weapondata["weapon"] = oldweapondata["weapon"];
	else
		weapondata["weapon"] = newweapondata["weapon"];

	weapon_name = weapondata["weapon"];
	dw_weapon = get_weapon_dual_wield_name(weapon_name);
	alt_weapon = get_weapon_alt_name(weapon_name);

	if(weapon_name == "none")
	{
		weapondata["clip"] = 0;
		weapondata["stock"] = 0;
	}
	else
	{
		weapondata["clip"] = newweapondata["clip"] + oldweapondata["clip"];
		weapondata["clip"] = Int(Min(weapondata["clip"], WeaponClipSize(weapon_name)));
		weapondata["stock"] = newweapondata["stock"] + oldweapondata["stock"];
		weapondata["stock"] = Int(Min(weapondata["stock"], WeaponMaxAmmo(weapon_name)));
	}

	if(dw_weapon == "none")
		weapondata["lh_clip"] = 0;
	else
	{
		weapondata["lh_clip"] = newweapondata["lh_clip"] + oldweapondata["lh_clip"];
		weapondata["lh_clip"] = Int(Min(weapondata["lh_clip"], WeaponClipSize(dw_weapon)));
	}

	if(alt_weapon == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = newweapondata["alt_clip"] + oldweapondata["alt_clip"];
		weapondata["alt_clip"] = Int(Min(weapondata["alt_clip"], WeaponClipSize(alt_weapon)));
		weapondata["alt_stock"] = newweapondata["alt_stock"] + oldweapondata["alt_stock"];
		weapondata["alt_stock"] = Int(Min(weapondata["alt_stock"], WeaponMaxAmmo(alt_weapon)));
	}
	return weapondata;
}

weapondata_give(weapondata)
{
	current = self get_player_weapon_with_same_base(weapondata["weapon"]);

	if(isdefined(current))
	{
		curweapondata = get_player_weapondata(self, current);
		self weapon_take(current);
		weapondata = merge_weapons(curweapondata, weapondata);
	}

	weapon_name = weapondata["weapon"];
	dw_weapon = get_weapon_dual_wield_name(weapon_name);
	alt_weapon = get_weapon_alt_name(weapon_name);

	self weapon_give(weapon_name, true);

	if(weapon_name != "none")
	{
		self SetWeaponAmmoClip(weapon_name, weapondata["clip"]);
		self SetWeaponAmmoStock(weapon_name, weapondata["stock"]);
	}

	if(dw_weapon != "none")
		self SetWeaponAmmoClip(dw_weapon, weapondata["lh_clip"]);

	if(alt_weapon != "none" && get_weapon_alt_name(alt_weapon) == weapon_name)
	{
		self SetWeaponAmmoClip(alt_weapon, weapondata["alt_clip"]);
		self SetWeaponAmmoStock(alt_weapon, weapondata["alt_clip"]);
	}
}

weapondata_take(weapondata)
{
	weapon_name = weapondata["weapon"];
	dw_weapon = get_weapon_dual_wield_name(weapon_name);
	alt_weapon = get_weapon_alt_name(weapon_name);

	if(weapon_name != "none")
		self weapon_take(weapon_name);
	if(dw_weapon != "none")
		self weapon_take(dw_weapon);
	if(alt_weapon != "none")
		self weapon_take(alt_weapon);
}

// Loadout
create_loadout(weapons)
{
	loadout = SpawnStruct();
	loadout.weapons = [];

	for(i = 0; i < weapons.size; i++)
	{
		if(maps\powerups\_zm_powerup_weapon::is_powerup_weapon(weapons[i]))
			continue;

		loadout.weapons[loadout.weapons.size] = get_default_weapondata(weapons[i]);

		if(!isdefined(loadout.current))
			loadout.current = weapons[i];
	}

	return loadout;
}

player_get_loadout()
{
	loadout = SpawnStruct();
	loadout.current = self GetCurrentWeapon();
	loadout.weapons = [];
	weapons = self GetWeaponsList();

	for(i = 0; i < weapons.size; i++)
	{
		if(maps\powerups\_zm_powerup_weapon::is_powerup_weapon(weapons[i]))
			continue;
		loadout.weapons[loadout.weapons.size] = get_player_weapondata(self, weapons[i]);
	}

	return loadout;
}

player_give_loadout(loadout, replace_existing)
{
	if(is_true(replace_existing))
		self TakeAllWeapons();

	for(i = 0; i < loadout.weapons.size; i++)
	{
		self weapondata_give(loadout.weapons[i]);
	}

	if(is_offhand_weapon(loadout.current))
		self SwitchToWeapon();
	else
		self SwitchToWeapon(loadout.current);
}

player_take_loadout(loadout)
{
	for(i = 0; i < loadout.weapons.size; i++)
	{
		self weapondata_take(loadout.weapons[i]);
	}
}

is_weapon_available_in_loadout(weapon_name, loadout)
{
	count = 0;
	upgrade_weapon = get_weapon_upgrade_name(weapon_name);

	if(isdefined(loadout) && isdefined(loadout.weapons))
	{
		for(i = 0; i < loadout.weapons.size; i++)
		{
			loadout_weapon = loadout.weapons[i]["weapon"];

			if(weapon_name == loadout_weapon || upgrade_weapon == loadout_weapon)
				count++;
		}
	}
	return count;
}

// Loading
load_weapons_for_level(weapons_list_table, stats_table)
{
	mapname = get_mapname();

	if(!isdefined(weapons_list_table))
		weapons_list_table = "weapons/" + mapname + ".csv";
	if(!isdefined(stats_table))
		stats_table = "weapons/stats.csv";

	/# PrintLn("Loading weapons for level '" + mapname + "' (" + weapons_list_table + ")"); #/
	weapons_list = load_weapons_list_for_level(weapons_list_table);

	for(i = 0; i < weapons_list.size; i++)
	{
		load_weapon_for_level(weapons_list[i]);
	}
}

load_weapon_for_level(weapon_name, stats_table)
{
	Assert(isdefined(weapon_name));
	Assert(!isdefined(level._zm_weapons[weapon_name]));

	if(!isdefined(stats_table))
		stats_table = "weapons/stats.csv";

	/# PrintLn("Loading weapon '" + weapon_name + "' (" + stats_table + ")"); #/

	// 0           1            2            3    4      5     6   7                8
	// weapon_name,upgrade_name,display_name,cost,in_box,limit,vox,is_wonder_weapon,offhand_type

	test = TableLookup(stats_table, 0, weapon_name, 0);

	if(!isdefined(test) || test != weapon_name)
	{
		/# PrintLn("Failed to load weapon '" + weapon_name + "', no stats defined for weapon in stats table (" + stats_table + ")"); #/
		return;
	}

	upgrade_name = TableLookup(stats_table, 0, weapon_name, 1);
	display_name = TableLookupIString(stats_table, 0, weapon_name, 2);
	cost = Int(TableLookup(stats_table, 0, weapon_name, 3));
	in_box = string_to_bool(TableLookup(stats_table, 0, weapon_name, 4));
	limit = Int(TableLookup(stats_table, 0, weapon_name, 5));
	vox = TableLookup(stats_table, 0, weapon_name, 6);
	is_wonder_weapon = string_to_bool(TableLookup(stats_table, 0, weapon_name, 7));
	offhand_type = TableLookup(stats_table, 0, weapon_name, 8);
	alt_weapon = get_weapon_alt_name(weapon_name);
	lh_weapon = get_weapon_dual_wield_name(weapon_name);

	struct = SpawnStruct();
	struct.upgrade_name = upgrade_name;
	struct.display_name = display_name;
	struct.cost = cost;
	struct.in_box = in_box;
	struct.limit = undefined;
	struct.vox = vox;
	struct.is_wonder_weapon = is_wonder_weapon;
	struct.is_ballistic_knife = false;

	if(isdefined(limit) && limit >= 0)
		struct.limit = limit;

	PrecacheItem(weapon_name);
	PrecacheString(display_name);

	level._zm_weapons[weapon_name] = struct;

	switch(offhand_type)
	{
		case "lethal":
			level.zombie_lethal_grenade_list[level.zombie_lethal_grenade_list.size] = weapon_name;
			break;

		case "tactical":
			level.zombie_tactical_grenade_list[level.zombie_tactical_grenade_list.size] = weapon_name;
			break;

		case "mine":
			level.zombie_placeable_mine_list[level.zombie_placeable_mine_list.size] = weapon_name;
			maps\_zm_placeable_mine::load_mine_for_level(weapon_name);
			break;

		case "ballistic":
			struct.is_ballistic_knife = true;
			// maps\_zm_melee_weapon::load_ballistic_knife(weapon_name);
			break;

		case "melee":
			level.zombie_melee_weapon_list[level.zombie_melee_weapon_list.size] = weapon_name;
			maps\_zm_melee_weapon::load_melee_weapon(weapon_name);
			break;

		case "equipment":
			level.zombie_equipment_list[level.zombie_equipment_list.size] = weapon_name;
			break;

		case "none":
		default:
			break;
	}

	if(isdefined(alt_weapon) && alt_weapon != "" && alt_weapon != "none" && !IsInArray(level._zm_alt_weapons, alt_weapon))
	{
		PrecacheItem(alt_weapon);
		level._zm_alt_weapons[level._zm_alt_weapons.size] = alt_weapon;
	}

	if(isdefined(lh_weapon) && lh_weapon != "" && lh_weapon != "none" && !IsInArray(level._zm_lh_weapons, lh_weapon))
	{
		PrecacheItem(lh_weapon);
		PrecacheModel(GetWeaponModel(lh_weapon));
		level._zm_lh_weapons[level._zm_lh_weapons.size] = lh_weapon;
	}

	if(!IsInArray(level._zm_weapons_list, weapon_name))
		level._zm_weapons_list[level._zm_weapons_list.size] = weapon_name;
}

// Stupid hack function to load a list of strings from stringtables
load_weapons_list_for_level(weapons_list_table)
{
	mapname = get_mapname();

	if(!isdefined(weapons_list_table))
		weapons_list_table = "weapons/" + mapname + ".csv";

	/# PrintLn("Loading weapons list for level '" + mapname + "' (" + weapons_list_table + ")"); #/

	// Would use StrTok and store list in csv file per mapname
	// but it seems either StrTok or TableLookup has a hard string length limit
	// was not loading knife_ballistic_bowie_zm and others after it (in zombie_theater)
	// as string was too long
	//
	// changeed to put weapons per line and lookup a index rather than mapname
	// that way we dont hit the string length issue mentioed above
	// annoying little issue but thats what you get for modding a older game
	// return StrTok(TableLookup(weapons_list_table, 0, mapname, 1), "|");

	// 0     1
	// index,weapon_name

	weapons_list = [];
	i = 0;
	str = TableLookup(weapons_list_table, 0, i, 1);

	while(isdefined(str) && str != "" && str != "none")
	{
		weapons_list[weapons_list.size] = str;
		i++;
		str = TableLookup(weapons_list_table, 0, i, 1);
	}

	/# PrintLn("Loaded weapons list for level '" + mapname + "', Found " + weapons_list.size + " weapons"); #/

	return weapons_list;
}

register_weapon_data_client_side()
{
	// set_client_system_state("_zm_weapons", weapon_name + ",register," + upgrade_name + "," + lh_weapon + "," + bool_to_string(in_box));
	flag_wait("all_players_connected");
	weapons_list = get_weapons_list();

	for(i = 0; i < weapons_list.size; i++)
	{
		weapon_name = weapons_list[i];
		weapon_stats = get_weapon_stats(weapon_name);
		upgrade_name = get_weapon_upgrade_name(weapon_name);
		lh_weapon = get_weapon_dual_wield_name(weapon_name);
		in_box = weapon_stats.in_box;
		set_client_system_state("_zm_weapons", weapon_name + ",register," + upgrade_name + "," + lh_weapon + "," + bool_to_string(in_box));
	}
}