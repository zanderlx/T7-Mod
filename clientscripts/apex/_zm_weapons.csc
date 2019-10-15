#include clientscripts\_utility;
#include clientscripts\apex\_utility;

init()
{
	level.zombie_weapons = [];
	level.zombie_weapons_upgraded = [];
	include_weapons();
	register_client_system("_zm_weapons", ::weapon_system_monitor);
}

include_weapons()
{
	// add_weapon_include_callback("sniper_explosive_zm",		clientscripts\apex\weapons\_zm_weap_sniper_explosive::include_weapon_for_level);
	// add_weapon_include_callback("zombie_quantum_bomb",		clientscripts\apex\weapons\_zm_weap_quantum_bomb::include_weapon_for_level);
	// add_weapon_include_callback("microwavegundw_zm",		clientscripts\apex\weapons\_zm_weap_microwavegun::include_weapon_for_level);
	// add_weapon_include_callback("humangun_zm",				clientscripts\apex\weapons\_zm_weap_humangun::include_weapon_for_level);
	add_weapon_include_callback("freezegun_zm",				clientscripts\apex\weapons\_zm_weap_freezegun::include_weapon_for_level);
	// add_weapon_include_callback("spikemore_zm",				clientscripts\apex\weapons\_zm_weap_spikemore::include_weapon_for_level);
	// add_weapon_include_callback("zombie_black_hole_bomb",	clientscripts\apex\weapons\_zm_weap_black_hole_bomb::include_weapon_for_level);
	add_weapon_include_callback("thundergun_zm",			clientscripts\apex\weapons\_zm_weap_thundergun::include_weapon_for_level);
	add_weapon_include_callback("tesla_gun_zm",				clientscripts\apex\weapons\_zm_weap_tesla::include_weapon_for_level);
}

//============================================================================================
// Loading
//============================================================================================
weapon_system_monitor(clientnum, state)
{
	// 0           1        2              3            4,       5,      6
	// weapon_name,register,inventory_type,upgrade_name,alt_name,lh_name,in_box
	tokens = StrTok(state, ",");
	weapon_name = tokens[0];
	state = tokens[1];

	if(state == "register")
	{
		if(clientnum != 0)
			return;
		if(is_weapon_included(weapon_name))
			return;

		inventory_Type = tokens[2];
		upgrade_name = tokens[3];
		alt_name = tokens[4];
		lh_name = tokens[5];
		in_box = string_to_bool(tokens[6]);

		/# PrintLn("Loading weapon on client side '" + weapon_name + "'"); #/

		struct = SpawnStruct();
		struct.inventory_Type = inventory_Type;
		struct.alt_name = alt_name;
		struct.lh_name = lh_name;
		struct.upgrade_name = upgrade_name;

		level.zombie_weapons[weapon_name] = struct;

		if(upgrade_name != "" && upgrade_name != "none")
			level.zombie_weapons_upgraded[upgrade_name] = weapon_name;

		if(in_box)
			clientscripts\apex\_zm_magicbox::add_magicbox_cycle_weapon(weapon_name);

		if(isdefined(level._zm_weapon_include_callbacks) && isdefined(level._zm_weapon_include_callbacks[weapon_name]))
			single_thread(level, level._zm_weapon_include_callbacks[weapon_name]);
	}
}

add_weapon_include_callback(weapon_name, callback_func)
{
	if(!isdefined(level._zm_weapon_include_callbacks))
		level._zm_weapon_include_callbacks = [];
	if(!isdefined(level._zm_weapon_include_callbacks[weapon_name]))
		level._zm_weapon_include_callbacks[weapon_name] = callback_func;
}

//============================================================================================
// Utilities
//============================================================================================
get_nonalternate_weapon(altWeapon)
{
	if(WeaponInventoryType(altWeapon) == "altmode")
		return WeaponAltWeaponName(altWeapon);
	return altWeapon;
}

is_weapon_included(weapon_name)
{
	return isdefined(level.zombie_weapons[weapon_name]);
}

is_weapon_or_base_included(weapon_name)
{
	if(!isdefined(level.zombie_weapons))
		return false;
	if(is_weapon_included(weapon_name))
		return true;

	base = get_base_weapon(weapon_name);
	return is_weapon_included(base);
}

get_base_weapon(upgradedweapon)
{
	upgradedweapon = get_nonalternate_weapon(upgradedweapon);

	if(isdefined(level.zombie_weapons_upgraded[upgradedweapon]))
		return level.zombie_weapons_upgraded[upgradedweapon];
	return upgradedweapon;
}

get_upgrade_weapon(weapon, add_attachment)
{
	weapon = get_nonalternate_weapon(weapon);
	weapon = ToLower(weapon);
	newWeapon = weapon;

	if(!is_weapon_upgraded(weapon))
		newWeapon = level.zombie_weapons[weapon].upgrade_name;
	return newWeapon;
}

can_upgrade_weapon(weaponname)
{
	if(!isdefined(weaponname) || weaponname == "")
		return false;

	weaponname = ToLower(weaponname);
	weaponname = get_nonalternate_weapon(weaponname);

	if(!is_weapon_upgraded(weaponname))
		return isdefined(level.zombie_weapons[weaponname].upgrade_name);
	return false;
}

is_weapon_upgraded(weaponname)
{
	if(!isdefined(weaponname) || weaponname == "")
		return false;

	weaponname = ToLower(weaponname);
	weaponname = get_nonalternate_weapon(weaponname);

	if(isdefined(level.zombie_weapons_upgraded[weaponname]))
		return true;
	return false;
}

weapon_is_dual_wield(weapon_name)
{
	return WeaponDualWieldWeaponName(weapon_name) != "none";
}

get_left_hand_weapon_model_name(weapon_name)
{
	return GetWeaponModel(WeaponDualWieldWeaponName(weapon_name));
}

// Weapon Model
spawn_weapon_model(clientnum, weapon_name, origin, angles)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return undefined;
	if(!isdefined(origin))
		return undefined;
	if(!isdefined(angles))
		angles = (0, 0, 0);

	model = spawn_model(clientnum, "tag_origin", origin, angles);
	model model_use_weapon_options(clientnum, weapon_name);

	return model;
}

model_use_weapon_options(clientnum, weapon_name)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return;

	self SetModel(GetWeaponModel(weapon_name));
	self UseWeaponHideTags(weapon_name);

	if(isdefined(self.lh_model))
	{
		if(weapon_is_dual_wield(weapon_name))
		{
			self.lh_model Hide();
			// self.lh_model Unlink();
			// self.lh_model Delete();
			// self.lh_model = undefined;
		}
		else
		{
			self.lh_model SetModel(get_left_hand_weapon_model_name(weapon_name));
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model Show();
		}
	}
	else
	{
		if(!weapon_is_dual_wield(weapon_name))
		{
			self.lh_model = spawn_model(clientnum, get_left_hand_weapon_model_name(weapon_name), self.origin + (3, 3, 3), self.angles);
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model LinkTo(self, "tag_origin");
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