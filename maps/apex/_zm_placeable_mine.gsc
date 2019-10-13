#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

init()
{
	level._zm_placeable_mines_howto_hints = [];
	set_zombie_var("zombie_weapons_slot_mines", 4);
	level thread replenish_placeable_mines_after_round();
	OnPlayerSpawned_Callback(::create_placeable_mine_weapon_watchers);
}

load_mine_for_level(weapon_name)
{
	/*
		0           1                2
		weapon_name,retrievable_hint,howto_hint
	*/
	placeable_mine_table = "gamedata/weapons/placeable_mines.csv";
	test = TableLookup(placeable_mine_table, 0, weapon_name, 0);

	// ensure data exists in table
	if(test != weapon_name)
		return;

	retrievable_hint = TableLookupIString(placeable_mine_table, 0, weapon_name, 1);
	howto_hint = TableLookupIString(placeable_mine_table, 0, weapon_name, 2);

	PrecacheString(retrievable_hint);
	PrecacheString(howto_hint);

	maps\_weaponobjects::create_retrievable_hint(weapon_name, retrievable_hint);
	register_placeable_mine_for_level(weapon_name);
	level._zm_placeable_mines_howto_hints[weapon_name] = howto_hint;
}

create_placeable_mine_weapon_watchers()
{
	self endon("disconnect");
	waittillframeend; // let _weaponobjects.gsc handle some shit first

	if(isdefined(level.zombie_placeable_mine_list))
	{
		for(i = 0; i < level.zombie_placeable_mine_list.size; i++)
		{
			weapon_name = level.zombie_placeable_mine_list[i];
			watcher_name = get_placeable_mine_watcher_name(weapon_name);

			watcher = self maps\_weaponobjects::create_use_weapon_object_watcher(watcher_name, weapon_name, self.team);
			watcher.onSpawnRetrieveTriggers = maps\_weaponobjects::on_spawn_retrievable_weapon_object;
			watcher.pickup = ::pickup_placeable_mine;
			watcher.pickup_trigger_listener = ::pickup_placeable_mine_trigger_listener;
			watcher.skip_weapon_object_damage = true;
		}
	}

	self thread watch_placeable_mine();
}

replenish_placeable_mines_after_round()
{
	level endon("end_game");

	for(;;)
	{
		level waittill("between_round_over");

		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			weapon_name = players[i] get_player_placeable_mine();

			if(!isdefined(weapon_name) || weapon_name == "none")
				continue;

			players[i] give_placeable_mine(weapon_name, false);
		}
	}
}

//============================================================================================
// How To
//============================================================================================
show_placeable_mine_howto(weapon_name)
{
	if(!isdefined(level._zm_placeable_mines_howto_hints[weapon_name]))
		return;

	hud = NewClientHudElem(self);
	hud.x = 320;
	hud.y = 220;
	hud.alignX = "center";
	hud.alignY = "bottom";
	hud.fontScale = 1.6;
	hud.alpha = 1;
	hud.sort = 20;
	hud SetText(level._zm_placeable_mines_howto_hints[weapon_name]);
	wait 3.5;
	hud Destroy();
}

//============================================================================================
// Weapon Objects
//============================================================================================
watch_placeable_mine()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("grenade_fire", grenade, weapon_name);

		if(is_placeable_mine(weapon_name))
		{
			grenade.owner = self;
			self enable_placeable_mine_triggers(weapon_name);
		}
	}
}

pickup_placeable_mine()
{
	player = self.owner;
	weapon_name = self.name;

	if(!player HasWeapon(weapon_name))
	{
		player give_placeable_mine(weapon_name);
		player SetWeaponAmmoClip(weapon_name, 0);
		player enable_placeable_mine_triggers(weapon_name);
	}

	self maps\_weaponobjects::pick_up();

	if(player GetWeaponAmmoClip(weapon_name) >= WeaponClipSize(weapon_name))
		player disable_placeable_mine_triggers(weapon_name);
}

pickup_placeable_mine_trigger_listener(trigger, player)
{
	self endon("delete");
	self endon("death");
	trigger endon("delete");
	trigger endon("death");

	watcher_name = get_placeable_mine_watcher_name(self.name);
	str_enable = "zmb_enable_" + watcher_name + "_prompt";
	str_disable = "zmb_disable_" + watcher_name + "_prompt";
	state = true;

	for(;;)
	{
		result = player waittill_any_return(str_enable, str_disable, "spawned_player");

		if(result == str_disable)
		{
			if(is_true(state))
			{
				trigger Unlink();
				trigger trigger_off();
				state = false;
			}
		}
		else
		{
			if(!is_true(state))
			{
				trigger trigger_on();
				trigger LinkTo(self);
				state = true;
			}
		}
	}
}

//============================================================================================
// Utils
//============================================================================================
get_placeable_mine_watcher_name(weapon_name)
{
	return GetSubStr(weapon_name, 0, weapon_name.size - 3);
}

enable_placeable_mine_triggers(weapon_name)
{
	watcher_name = get_placeable_mine_watcher_name(weapon_name);
	self notify("zmb_enable_" + watcher_name + "_prompt");
}

disable_placeable_mine_triggers(weapon_name)
{
	watcher_name = get_placeable_mine_watcher_name(weapon_name);
	self notify("zmb_disable_" + watcher_name + "_prompt");
}

give_placeable_mine(weapon_name, show_howto)
{
	self set_player_placeable_mine(weapon_name);
	self SetActionSlot(level.zombie_vars["zombie_weapons_slot_mines"], "weapon", weapon_name);
	self maps\apex\_zm_weapons::give_weapon(weapon_name);
	self SetWeaponAmmoClip(weapon_name, 2);
	self enable_placeable_mine_triggers(weapon_name);

	if(is_true(show_howto))
		self thread show_placeable_mine_howto(weapon_name);
}