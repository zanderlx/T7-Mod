#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	flag_init("pack_machine_in_use", false);
	
	PrecacheItem("zombie_knuckle_crack");
	// PrecacheModel("zombie_vending_packapunch");
	// PrecacheModel("zombie_vending_packapunch_on");
	PrecacheModel("p7_zm_vending_packapunch");
	PrecacheModel("p7_zm_vending_packapunch_on");
	PrecacheModel("p7_zm_vending_packapunch_sign_wait");
	PrecacheModel("p7_zm_vending_packapunch_weapon");
	PrecacheString(&"ZOMBIE_PERK_PACKAPUNCH");
	PrecacheString(&"ZOMBIE_GET_UPGRADED");
	
	level._effect["packapunch_fx"] = LoadFX("maps/zombie/fx_zombie_packapunch");
	level.zombiemode_using_pack_a_punch = true;

	array_thread(GetEntArray("zombie_vending_upgrade", "targetname"), ::vending_weapon_upgrade);
	level thread turn_PackAPunch_on();
}

third_person_weapon_upgrade(weapon, origin, angles, packa_rollers, perk_machine, player)
{
	upgrade_name = maps\_zm_weapons::get_weapon_upgrade_name(weapon);
	forward = AnglesToForward(angles);
	interact_pos = origin + (forward * -25);
	PlayFX(level._effect["packapunch_fx"], origin + (0, 0, -35), forward);
	model = maps\_zm_weapons::spawn_weapon_model(weapon, interact_pos, angles, player);
	model RotateTo(angles + (0, 90, 0), .35, 0, 0);
	wait .5;
	model MoveTo(origin, .5, 0, 0);
	self PlaySound("zmb_perks_packa_upgrade");

	if(isdefined(perk_machine.wait_flag))
		perk_machine.wait_flag RotateTo(perk_machine.wait_flag.angles + (179, 0, 0), .25, 0, 0);
	
	wait .35;
	model maps\_zm_weapons::model_use_weapon_options(upgrade_name, player);
	model maps\_zm_weapons::model_hide_weapon();
	wait 3;
	model maps\_zm_weapons::model_show_weapon();
	model MoveTo(interact_pos, .5, 0, 0);

	if(isdefined(perk_machine.wait_flag))
		perk_machine.wait_flag RotateTo(perk_machine.wait_flag.angles - (179, 0, 0), .25, 0, 0);
	
	wait .5;
	model MoveTo(origin, 15, 0, 0);
	return model;
}

can_pack_weapon(weapon)
{
	if(flag("pack_machine_in_use"))
		return true;
	if(!maps\_zm_weapons::is_weapon_included(weapon))
		return false;
	if(!maps\_zm_weapons::can_upgrade_weapon(weapon))
		return false;
	return true;
}

player_use_can_pack_now()
{
	if(!vending_trigger_can_player_use(self))
		return false;
	
	weapon = self GetCurrentWeapon();

	if(!self can_pack_weapon(weapon))
		return false;
	return true;
}

vending_machine_trigger_think()
{
	self endon("death");

	for(;;)
	{
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			if((isdefined(self.pack_player) && self.pack_player != players[i]) || !players[i] player_use_can_pack_now())
				self SetInvisibleToPlayer(players[i], true);
			else
				self SetInvisibleToPlayer(players[i], false);
		}
		wait .05;
	}
}

vending_weapon_upgrade()
{
	perk_machine = GetEnt(self.target, "targetname");
	packa_rollers = Spawn("script_origin", self.origin);
	packa_timer = Spawn("script_origin", self.origin);
	packa_rollers LinkTo(self);
	packa_timer LinkTo(self);

	perk_machine SetModel("p7_zm_vending_packapunch");

	if(isdefined(perk_machine.target))
		perk_machine.wait_flag = GetEnt(perk_machine.target, "targetname");
	if(isdefined(perk_machine.wait_flag))
		perk_machine.wait_flag SetModel("p7_zm_vending_packapunch_sign_wait");
	
	self UseTriggerRequireLookAt();
	self SetHintString(&"ZOMBIE_NEED_POWER");
	self SetCursorHint("HINT_NOICON");
	level waittill("Pack_A_Punch_on");
	self thread vending_machine_trigger_think();
	perk_machine PlayLoopSound("zmb_perks_packa_loop");
	self thread vending_weapon_upgrade_cost();

	for(;;)
	{
		self waittill("trigger", player);
		weapon = player GetCurrentWeapon();
		weapon = maps\_zm_weapons::get_root_weapon(weapon);

		if(!vending_trigger_can_player_use(player) || !maps\_zm_weapons::can_upgrade_weapon(weapon))
		{
			wait .1;
			continue;
		}

		if(is_true(level.pap_moving))
			continue;
		
		if(!player can_player_purchase(self.cost))
		{
			self PlaySound("deny");
			player maps\_zombiemode_audio::create_and_play_dialog("general", "perk_deny", undefined, 0);
			continue;
		}

		self.pack_player = player;
		flag_set("pack_machine_in_use");
		player maps\_zombiemode_score::minus_to_player_score(self.cost);
		PlaySoundAtPosition("evt_bottle_dispense", self.origin);
		self thread maps\_zombiemode_audio::play_jingle_or_stinger("mus_perks_packa_sting");
		player maps\_zombiemode_audio::create_and_play_dialog("weapon_pickup", "upgrade_wait");
		self disable_trigger();
		player thread do_knuckle_crack();
		self.current_weapon = weapon;
		weaponmodel = player third_person_weapon_upgrade(weapon, perk_machine.origin + (0, 0, 35), perk_machine.angles + (0, 90, 0), packa_rollers, perk_machine, player);
		self enable_trigger();
		self SetHintString(&"ZOMBIE_GET_UPGRADED");
		self thread wait_for_player_to_take(player, weapon, packa_timer);
		self thread wait_for_timeout(weapon, packa_timer);
		self waittill_either("pap_timeout", "pap_taken");
		self.current_weapon = "none";
		weaponmodel maps\_zm_weapons::delete_weapon_model();
		self SetHintString(&"ZOMBIE_PERK_PACKAPUNCH", self.cost);
		self.pack_player = undefined;
		flag_clear("pack_machine_in_use");
	}
}

vending_weapon_upgrade_cost()
{
	for(;;)
	{
		self.cost = 5000;
		self SetHintString(&"ZOMBIE_PERK_PACKAPUNCH", self.cost);
		level waittill("powerup bonfire sale");
		self.cost = 1000;
		self SetHintString(&"ZOMBIE_PERK_PACKAPUNCH", self.cost);
		level waittill("bonfire_sale_off");
	}
}

wait_for_player_to_take(player, weapon, packa_timer)
{
	self endon("pap_timeout");
	packa_timer PlayLoopSound("zmb_perks_packa_ticktock");
	upgrade_name = maps\_zm_weapons::get_weapon_upgrade_name(weapon);

	for(;;)
	{
		self waittill("trigger", trigger_player);

		if(trigger_player == player && vending_trigger_can_player_use(player))
		{
			packa_timer StopLoopSound();
			self notify("pap_taken");
			player notify("pap_taken");
			player.pap_used = true;
			upgrade_name = player maps\_zm_weapons::weapon_give(upgrade_name, true);
			player maps\_zm_weapons::play_weapon_vo(upgrade_name);
			return;
		}
	}
}

wait_for_timeout(weapon, packa_timer)
{
	self endon("pap_taken");
	wait 15;
	self notify("pap_timeout");
	packa_timer StopLoopSound();
	packa_timer PlaySound("zmb_perks_packa_deny");
}

do_knuckle_crack()
{
	result = self upgrade_knuckle_crack_begin();
	self waittill_any("fake_death", "death", "player_downed", "weapon_change_complete");
	self upgrade_knuckle_crack_end();
}

upgrade_knuckle_crack_begin()
{
	self increment_is_drinking();
	self disable_player_move_states(true);
	primaries = self GetWeaponsListPrimaries();
	gun = self GetCurrentWeapon();

	if(gun != "none" && !is_placeable_mine(gun) && !is_equipment(gun))
		self maps\_zm_weapons::weapon_take(gun);
	else
		return;
	
	self GiveWeapon("zombie_knuckle_crack");
	self SwitchToWeapon("zombie_knuckle_crack");
}

upgrade_knuckle_crack_end()
{
	self enable_player_move_states();
	self TakeWeapon("zombie_knuckle_crack");

	if(self maps\_laststand::player_is_in_laststand() || is_true(self.intermission))
		return;
	
	self decrement_is_drinking();
	primaries = self GetWeaponsListPrimaries();

	if(self is_drinking())
		return;
	else
		self maps\_zm_weapons::switch_back_primary_weapon();
}

turn_PackAPunch_on()
{
	level waittill("Pack_A_Punch_on");
	array_run(GetEntArray("zombie_vending_upgrade", "targetname"), ::activate_PackAPunch);
}

activate_PackAPunch()
{
	machine = GetEnt(self.target, "targetname");

	// machine SetModel("zombie_vending_packapunch_on");
	machine SetModel("p7_zm_vending_packapunch_on");
	machine PlaySound("zmb_perks_power_on");
	machine Vibrate((0, -100, 0), .3, .4, 3);
}

vending_trigger_can_player_use(player)
{
	if(!player can_buy_weapon())
		return false;
	if(player IsThrowingGrenade())
		return false;
	if(player IsSwitchingWeapons())
		return false;
	return true;
}