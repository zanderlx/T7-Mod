#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	level.zombie_weapons = [];
	level.zombie_weapons_upgraded = [];
	load_weapons_for_level();
	OnPlayerSpawned_Callback(::player_spawned);
	level thread register_weapon_data_client_side();
}

//============================================================================================
// Grenade Duds
//============================================================================================
player_spawned()
{
	self thread watchForGrenadeDuds();
	self thread watchForGrenadeLauncherDuds();
	self.staticWeaponStartTime = GetTime();
}

watchForGrenadeDuds()
{
	self endon("spawned_player");
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_fire", grenade, weapon);

		if(!is_equipment(weapon) && !is_placeable_mine(weapon))
		{
			grenade thread checkForGrenadeDud(weapon, true, self);
			grenade thread watchForScriptExplosion(weapon, true, self);
		}
	}
}

watchForGrenadeLauncherDuds()
{
	self endon("spawned_player");
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_launcher_fire", grenade, weapon);
		grenade thread checkForGrenadeDud(weapon, false, self);
		grenade thread watchForScriptExplosion(weapon, false, self);
	}
}

grenade_safe_to_throw(player, weapon)
{
	if(isdefined(level.grenade_safe_to_throw))
		return run_function(self, level.grenade_safe_to_throw, player, weapon);
	return true;
}

grenade_safe_to_bounce(player, weapon)
{
	if(isdefined(level.grenade_safe_to_bounce))
		return run_function(self, level.grenade_safe_to_bounce, player, weapon);
	return true;
}

makeGrenadeDudAndDestroy()
{
	self endon("death");
	self notify("grenade_dud");
	// self MakeGrenadeDud();
	wait 3;

	if(isdefined(self))
		self Delete();
}

checkForGrenadeDud(weapon, isThrownGrenade, player)
{
	self endon("death");
	player endon("zombify");

	if(!self grenade_safe_to_throw(player, weapon))
	{
		self thread makeGrenadeDudAndDestroy();
		return;
	}

	for(;;)
	{
		self waittill_any_or_timeout(.25, "grenade_bounce", "stationary");

		if(!self grenade_safe_to_bounce(player, weapon))
		{
			self thread makeGrenadeDudAndDestroy();
			return;
		}
	}
}

wait_explode()
{
	self endon("grenade_dud");
	self endon("done");
	self waittill("explode", origin);
	level.explode_position = origin;
	level.explode_position_valid = true;
	self notify("done");
}

wait_timeout(time)
{
	self endon("grenade_dud");
	self endon("done");
	wait time;
	self notify("done");
}

wait_for_explosion(time)
{
	level.explode_position = (0, 0, 0);
	level.explode_position_valid = false;
	self thread wait_explode();
	self thread wait_timeout(time);
	self waittill("done");
	self notify("death_or_explode", level.explode_position, level.explode_position_valid);
}

watchForScriptExplosion(weapon, isThrownGrenade, player)
{
	self endon("grenade_dud");

	if(is_lethal_grenade(weapon) /*|| is_grenade_launcher(weapon)*/)
	{
		self thread wait_for_explosion(20);
		self waittill("death_or_explode", origin, exploded);

		if(is_true(exploded))
			level notify("grenade_exploded", origin, 256, 300, 75);
	}
}

//============================================================================================
// Utils
//============================================================================================
get_nonalternate_weapon(altWeapon)
{
	if(WeaponInventoryType(altWeapon) == "altmode")
		return WeaponAltWeaponName(altWeapon);
	return altWeapon;
}

swicth_from_alt_weapon(current_weapon)
{
	alt = get_nonalternate_weapon(current_weapon);

	if(alt != current_weapon)
	{
		self SwitchToWeapon(alt);
		self waittill_any_or_timeout(1, "weapon_change_complete");
		return alt;
	}
	return current_weapon;
}

switch_back_primary_weapon(oldPrimary)
{
	if(self maps\_laststand::player_is_in_laststand())
		return;

	if(!isdefined(oldPrimary) || oldPrimary == "none" || /*maps\_zm_melee_weapon::is_flourish_weapon(oldPrimary) ||*/ is_melee_weapon(oldPrimary) || is_placeable_mine(oldPrimary) || is_lethal_grenade(oldPrimary) || is_tactical_grenade(oldPrimary) || !self HasWeapon(oldPrimary))
		oldPrimary = undefined;

	primaryWeapons = self GetWeaponsListPrimaries();

	if(isdefined(oldPrimary) && IsInArray(primaryWeapons, oldPrimary))
		self SwitchToWeapon(oldPrimary);
	else if(primaryWeapons.size > 0)
		self SwitchToWeapon(primaryWeapons[0]);
}

is_weapon_included(weapon_name)
{
	if(!isdefined(level.zombie_weapons))
		return false;
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

get_upgrade_weapon(weapon)
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

has_upgrade(weaponname)
{
	has_upgrade = false;

	if(isdefined(level.zombie_weapons[weaponname]) && isdefined(level.zombie_weapons[weaponname].upgrade_name))
		has_upgrade = self HasWeapon(level.zombie_weapons[weaponname].upgrade_name);
	if(!has_upgrade && weaponname == "knife_ballistic_zm") // maps\_zm_melee_weapon::has_any_ballistic_knife_upgraded()
		has_upgrade = self has_upgrade("knife_ballistic_bowie_zm") || self has_upgrade("knife_ballistic_sickle_zm");
	return has_upgrade;
}

has_weapon_or_upgrade(weaponname)
{
	has_weapon = false;

	if(is_weapon_included(weaponname))
		has_weapon = self HasWeapon(weaponname) || self has_upgrade(weaponname);
	if(!has_weapon && weaponname == "knife_ballistic_zm") // maps\_zm_melee_weapon::has_any_ballistic_knife()
		has_weapon = self has_weapon_or_upgrade("knife_ballistic_bowie_zm") || self has_weapon_or_upgrade("knife_ballistic_sickle_zm");
	return has_weapon;
}

can_buy_weapon()
{
	if(isdefined(self.is_drinking) && self is_drinking())
		return false;
	if(self hacker_active())
		return false;

	current_weapon = self GetCurrentWeapon();

	if(is_placeable_mine(current_weapon) || is_equipment(current_weapon))
		return false;
	if(self in_revive_trigger())
		return false;
	if(current_weapon == "none")
		return false;
	return true;
}

weapon_is_dual_wield(name)
{
	return WeaponDualWieldWeaponName(name) != "none";
}

get_left_hand_weapon_model_name(name)
{
	return GetWeaponModel(WeaponDualWieldWeaponName(name));
}

get_pack_a_punch_weapon_options(weapon)
{
	if(!isdefined(self.pack_a_punch_weapon_options_default))
		self.pack_a_punch_weapon_options_default = self CalcWeaponOptions(0);
	if(!isdefined(self.pack_a_punch_weapon_options))
		self.pack_a_punch_weapon_options = [];
	if(isdefined(self.pack_a_punch_weapon_options[weapon]))
		return self.pack_a_punch_weapon_options[weapon];

	if(!is_weapon_upgraded(weapon))
	{
		self.pack_a_punch_weapon_options[weapon] = self.pack_a_punch_weapon_options_default;
		return self.pack_a_punch_weapon_options[weapon];
	}

	reticle_index = RandomIntRange(0, 21);
	reticle_color_index = RandomIntRange(0, 6);

	if(weapon == "famas_upgraded_zm")
		reticle_index = 21;
	else
	{
		if(RandomInt(10) < 3)
			reticle_index = 0;
	}

	if(reticle_index == 8)
		reticle_color_index = 3;
	if(reticle_index == 2)
		reticle_color_index = 6;
	if(reticle_index == 7)
		reticle_color_index = 1;
	if(reticle_index == 22)
		reticle_color_index = 6;

	self.pack_a_punch_weapon_options[weapon] = self CalcWeaponOptions(15, RandomIntRange(0, 6), reticle_index, reticle_color_index);
	return self.pack_a_punch_weapon_options[weapon];
}

//============================================================================================
// Weapon Model
//============================================================================================
attach_weapon_model(weapon_name, rh_tag, lh_tag)
{
	if(!isdefined(rh_tag))
		rh_tag = "tag_weapon";
	if(!isdefined(lh_tag))
		lh_tag = "tag_weapon_left";

	self Attach(GetWeaponModel(weapon_name), rh_tag);

	if(weapon_is_dual_wield(weapon_name))
		self Attach(get_left_hand_weapon_model_name(weapon_name), lh_tag);

	self UseWeaponHideTags(weapon_name);
}

detach_weapon_model(weapon_name, rh_tag, lh_tag)
{
	if(!isdefined(rh_tag))
		rh_tag = "tag_weapon";
	if(!isdefined(lh_tag))
		lh_tag = "tag_weapon_left";

	self Detach(GetWeaponModel(weapon_name), rh_tag);

	if(weapon_is_dual_wield(weapon_name))
		self Detach(get_left_hand_weapon_model_name(weapon_name), lh_tag);
}

spawn_weapon_model(weapon_name, origin, angles)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return undefined;
	if(!isdefined(origin))
		return undefined;
	if(!isdefined(angles))
		angles = (0, 0, 0);

	model = spawn_model("tag_origin", origin, angles);
	model model_use_weapon_options(weapon_name);

	return model;
}

model_use_weapon_options(weapon_name)
{
	if(!isdefined(weapon_name) || weapon_name == "none")
		return;

	self SetModel(GetWeaponModel(weapon_name));
	self UseWeaponHideTags(weapon_name);
	self.weapon_name = weapon_name;

	if(isdefined(self.lh_model))
	{
		if(weapon_is_dual_wield(weapon_name))
		{
			self.lh_model SetModel(get_left_hand_weapon_model_name(weapon_name));
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model Show();
		}
		else
		{
			self.lh_model Hide();
			// self.lh_model Unlink();
			// self.lh_model Delete();
			// self.lh_model = undefined;
		}
	}
	else
	{
		if(weapon_is_dual_wield(weapon_name))
		{
			self.lh_model = spawn_model(get_left_hand_weapon_model_name(weapon_name), self.origin + (3, 3, 3), self.angles);
			self.lh_model UseWeaponHideTags(weapon_name);
			self.lh_model LinkTo(self);
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

//============================================================================================
// Give
//============================================================================================
weapon_give(weapon, magic_box, nosound)
{
	primaryWeapons = self GetWeaponsListPrimaries();
	initial_current_weapon = self GetCurrentWeapon();
	current_weapon = self swicth_from_alt_weapon(initial_current_weapon);
	weapon_limit = self get_player_weapon_limit();

	if(is_equipment(weapon))
		self maps\_zombiemode_equipment::equipment_give(weapon);

	if(self HasWeapon(weapon))
	{
		if(IsSubStr(weapon, "knife_ballistic_"))
			self notify("zmb_lost_knife");

		self GiveStartAmmo(weapon);

		if(!is_offhand_weapon(weapon))
			self SwitchToWeapon(weapon);

		return weapon;
	}

	if(is_lethal_grenade(weapon))
	{
		old_lethal = self get_player_lethal_grenade();

		if(old_lethal != "none")
			self TakeWeapon(old_lethal);

		self set_player_lethal_grenade(weapon);
	}
	else if(is_tactical_grenade(weapon))
	{
		old_tactical = self get_player_tactical_grenade();

		if(old_tactical != "none")
			self TakeWeapon(old_tactical);

		self set_player_tactical_grenade(weapon);
	}
	else if(is_placeable_mine(weapon))
	{
		old_mine = self get_player_placeable_mine();

		if(old_mine != "none")
			self TakeWeapon(old_mine);

		self set_player_placeable_mine(weapon);
	}

	if(primaryWeapons.size >= weapon_limit)
	{
		if(is_placeable_mine(current_weapon) || is_equipment(current_weapon))
			current_weapon = undefined;

		if(isdefined(current_weapon))
		{
			if(!is_offhand_weapon(current_weapon))
			{
				if(IsSubStr(current_weapon, "knife_ballistic_"))
					self notify("zmb_lost_knife");
				self TakeWeapon(current_weapon);
			}
		}
	}

	if(isdefined(level.zombiemode_offhand_weapon_give_override))
	{
		if(run_function(self, level.zombiemode_offhand_weapon_give_override, weapon))
			return weapon;
	}

	if(weapon == "knife_ballistic_zm" && self HasWeapon("bowie_knife_zm"))
		weapon = "knife_ballistic_bowie_zm";
	else if(weapon == "knife_ballistic_zm" && self HasWeapon("sickle_knife_zm"))
		weapon = "knife_ballistic_sickle_zm";
	else if(is_placeable_mine(weapon))
	{
		self thread maps\_zombiemode_claymore::claymore_setup();

		if(!is_true(nosound))
			self play_weapon_vo(weapon, magic_box);

		return weapon;
	}

	if(isdefined(level.zombie_weapons_callbacks) && isdefined(level.zombie_weapons_callbacks[weapon]))
	{
		single_thread(self, level.zombie_weapons_callbacks[weapon]);

		if(!is_true(nosound))
			self play_weapon_vo(weapon, magic_box);

		return weapon;
	}

	if(!is_true(nosound))
		self play_sound_on_ent("purchase");

	self GiveWeapon(weapon, 0, self get_pack_a_punch_weapon_options(weapon));
	self GiveStartAmmo(weapon);

	if(!is_offhand_weapon(weapon))
	{
		if(!is_melee_weapon(weapon))
			self SwitchToWeapon(weapon);
		else
			self SwitchToWeapon(current_weapon);
	}

	if(!is_true(nosound))
		self play_weapon_vo(weapon, magic_box);
	return weapon;
}

ammo_give(weapon)
{
	give_ammo = false;

	if(is_offhand_weapon(weapon))
	{
		if(self has_weapon_or_upgrade(weapon))
		{
			if(self GetAmmoCount(weapon) < WeaponMaxAmmo(weapon))
				give_ammo = true;
		}
	}
	else
	{
		stock_max = WeaponStartAmmo(weapon);
		clip_count = self GetWeaponAmmoClip(weapon);
		current_stock = self GetAmmoCount(weapon);

		if(current_stock - clip_count >= stock_max)
			give_ammo = false;
		else
			give_ammo =true;
	}

	if(give_ammo)
	{
		self play_sound_on_ent("purchase");
		self GiveMaxAmmo(weapon);

		alt_weap = WeaponAltWeaponName(weapon);

		if(alt_weap != "none")
			self GiveMaxAmmo(alt_weap);
	}
	return give_ammo;
}

//============================================================================================
// Weapon VOX
//============================================================================================
play_weapon_vo(weapon, magic_box)
{
	if(isdefined(level._audio_custom_weapon_check))
		type = run_function(self, level._audio_custom_weapon_check, weapon);
	else
		type = self weapon_type_check(weapon);

	self thread maps\_zombiemode_audio::create_and_play_dialog("weapon_pickup", type);
}

weapon_type_check( weapon )
{
	switch(self get_player_index())
	{
		case 0:
			if(weapon == "m16_zm")
				return "favorite";
			else if(weapon == "rottweil72_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 1:
			if(weapon == "fnfal_zm")
				return "favorite";
			else if(weapon == "hk21_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 2:
			if(weapon == "china_lake_zm")
				return "favorite";
			else if(weapon == "thundergun_upgraded_zm")
				return "favorite_upgrade";
			break;

		case 3:
			if(weapon == "mp40_zm")
				return "favorite";
			else if(weapon == "crossbow_explosive_upgraded_zm")
				return "favorite_upgrade";
			break;
	}

	if(is_weapon_upgraded(weapon))
		return "upgrade";
	else
		return level.zombie_weapons[weapon].vox;
}

get_player_index()
{
	return self.entity_num;
}

//============================================================================================
// Weapon Data
//============================================================================================
get_player_weapondata(weapon)
{
	weapondata = [];

	if(isdefined(weapon))
		weapondata["name"] = weapon;
	else
		weapondata["name"] = self GetCurrentWeapon();

	weapondata["dw_name"] = WeaponDualWieldWeaponName(weapondata["name"]);
	weapondata["alt_name"] = WeaponAltWeaponName(weapondata["name"]);

	if(weapondata["name"] == "none")
	{
		weapondata["clip"] = 0;
		weapondata["stock"] = 0;
	}
	else
	{
		weapondata["clip"] = self GetWeaponAmmoClip(weapondata["name"]);
		weapondata["stock"] = self GetWeaponAmmoStock(weapondata["name"]);
	}

	if(weapondata["dw_name"] == "none")
		weapondata["lh_clip"] = 0;
	else
		weapondata["lh_clip"] = self GetWeaponAmmoClip(weapondata["dw_name"]);

	if(weapondata["alt_name"] == "none")
	{
		weapondata["alt_clip"] = 0;
		weapondata["alt_stock"] = 0;
	}
	else
	{
		weapondata["alt_clip"] = self GetWeaponAmmoClip(weapondata["alt_name"]);
		weapondata["alt_stock"] = self GetWeaponAmmoStock(weapondata["alt_name"]);
	}
	return weapondata;
}

weapondata_give(weapondata)
{
	self weapon_give(weapondata["name"], false, true);

	self SetWeaponAmmoStock(weapondata["name"], weapondata["stock"]);
	self SetWeaponAmmoClip(weapondata["name"], weapondata["clip"]);

	if(weapondata["dw_name"] != "none")
		self SetWeaponAmmoClip(weapondata["dw_name"], weapondata["lh_clip"]);

	if(weapondata["alt_name"] != "none")
	{
		self SetWeaponAmmoStock(weapondata["alt_name"], weapondata["alt_stock"]);
		self SetWeaponAmmoClip(weapondata["alt_name"], weapondata["alt_clip"]);
	}
}

//============================================================================================
// Weapon Loading
//============================================================================================
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
	Assert(!isdefined(level.zombie_weapons[weapon_name]));

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
	alt_weapon = WeaponAltWeaponName(weapon_name);
	lh_weapon = WeaponDualWieldWeaponName(weapon_name);

	struct = SpawnStruct();
	struct.upgrade_name = upgrade_name;
	struct.display_name = display_name;
	struct.cost = cost;
	struct.vox = vox;
	struct.is_wonder_weapon = is_wonder_weapon;
	struct.is_ballistic_knife = false;

	if(isdefined(limit) && limit >= 0)
		struct.limit = limit;

	PrecacheItem(weapon_name);
	PrecacheString(display_name);

	level.zombie_weapons[weapon_name] = struct;

	switch(offhand_type)
	{
		case "lethal":
			register_lethal_grenade_for_level(weapon_name);
			break;

		case "tactical":
			register_tactical_grenade_for_level(weapon_name);
			break;

		case "mine":
			register_placeable_mine_for_level(weapon_name);
			// maps\_zm_placeable_mine::load_mine_for_level(weapon_name);
			break;

		case "ballistic":
			register_lethal_grenade_for_level(weapon_name);
			struct.is_ballistic_knife = true;
			// maps\_zm_melee_weapon::load_ballistic_knife(weapon_name);
			break;

		case "melee":
			register_melee_weapon_for_level(weapon_name);
			// maps\_zm_melee_weapon::load_melee_weapon(weapon_name);
			break;

		case "equipment":
			register_equipment_for_level(weapon_name);
			break;

		case "none":
		default:
			break;
	}

	if(is_true(in_box))
	{
		maps\apex\_zm_magicbox::add_weapon_to_magicbox(weapon_name);

		if(isdefined(limit) && limit > 0)
			maps\apex\_zm_magicbox::add_limited_weapon(weapon_name, limit);
	}

	if(isdefined(upgrade_name) && upgrade_name != "" && upgrade_name != "none")
	{
		PrecacheItem(upgrade_name);
		level.zombie_weapons_upgraded[upgrade_name] = weapon_name;
	}

	if(isdefined(alt_weapon) && alt_weapon != "" && alt_weapon != "none")
		PrecacheItem(alt_weapon);

	if(isdefined(lh_weapon) && lh_weapon != "" && lh_weapon != "none")
	{
		PrecacheItem(lh_weapon);
		PrecacheModel(GetWeaponModel(lh_weapon));
	}
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
	flag_wait("all_players_connected");
	weapons_list = GetArrayKeys(level.zombie_weapons);

	for(i = 0; i < weapons_list.size; i++)
	{
		weapon_name = weapons_list[i];
		inventory_type = WeaponInventoryType(weapon_name);
		upgrade_name = get_upgrade_weapon(weapon_name);
		alt_weapon = WeaponAltWeaponName(weapon_name);
		lh_weapon = WeaponDualWieldWeaponName(weapon_name);
		in_box = maps\apex\_zm_magicbox::is_weapon_in_box(weapon_name);

		set_client_system_state("_zm_weapons", weapon_name + ",register," + inventory_type + "," + upgrade_name + "," + alt_weapon + "," + lh_weapon + "," + bool_to_string(in_box), level);
	}
}