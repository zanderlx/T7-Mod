#include clientscripts\_utility;
#include clientscripts\_zm_utility;

init()
{
	level._zm_weapons = [];
	level._zm_weapons_list = [];
	level._display_box_weapons = [];

	register_client_system("_zm_weapons", ::weapon_system_monitor);
}

weapon_system_monitor(clientnum, state, oldState)
{
	// 0           1        2            3       4
	// weapon_name,register,upgrade_name,lh_name,in_box
	tokens = StrTok(state, ",");
	weapon_name = tokens[0];
	state = tokens[1];

	if(state == "register")
	{
		if(isdefined(level._zm_weapons[weapon_name]))
			return;

		upgrade_name = tokens[2];
		lh_name = tokens[3];
		in_box = string_to_bool(tokens[4]);

		struct = SpawnStruct();
		struct.upgrade_name = upgrade_name;
		struct.in_box = in_box;
		struct.lh_name = lh_name;

		/# PrintLn("Loading weapon on client side '" + weapon_name + "'"); #/

		level._zm_weapons[weapon_name] = struct;
		level._zm_weapons_list[level._zm_weapons_list.size] = weapon_name;

		if(in_box)
			level._display_box_weapons[level._display_box_weapons.size] = weapon_name;
	}
}

get_weapons_list()
{
	return level._zm_weapons_list;
}

get_weapon_stats(weapon_name)
{
	return level._zm_weapons[weapon_name];
}

get_weapon_upgrade_name(weapon_name)
{
	stats = get_weapon_stats(weapon_name);
	return stats.upgrade_name;
}

get_weapon_dual_wield_name(weapon_name)
{
	stats = get_weapon_stats(weapon_name);
	return stats.lh_name;
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
		}
	}
	else
	{
		if(dw_weapon != "none")
		{
			self.lh_model = spawn_model(clientnum, GetWeaponModel(dw_weapon), self.origin + (3, 3, 3), self.angles);
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