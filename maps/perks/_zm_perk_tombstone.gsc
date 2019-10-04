#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_perk_for_level()
{
	if(is_solo_game())
		return;

	maps\_zm_perks::register_perk("tombstone", "uie_moto_perk_tombstone", "zombie_perk_bottle_tombstone_t6");
	maps\_zm_perks::register_perk_machine("tombstone", 3000, &"ZOMBIE_PERK_TOMBSTONE", "zombie_vending_tombstone", "zombie_vending_tombstone_on", "tombstone_light", "mus_perks_tombstone_sting", "mus_perks_tombstone_jingle");
	maps\_zm_perks::register_perk_threads("tombstone", undefined, undefined, undefined, undefined);
	maps\_zm_perks::register_perk_flash_audio("tombstone", undefined);

	level._effect["tombstone_light"] = LoadFX("misc/fx_zombie_cola_on");
	level.zombiemode_using_tombstone_perk = true;

	PrecacheModel("ch_tombstone1");

	level.tombstone_laststand_func = ::tombstone_laststand;
	level.tombstone_spawn_func = ::tombstone_spawn;
	level.tombstones = [];
	level.tombstone_index = 0;

	OnPlayerConnect_Callback(::tombstone_player_init);
	OnPlayerLastStand_Callback(::on_laststand);
	maps\_zm_weapons::add_custom_limited_weapon_check(::is_weapon_available_in_tombstone);
}

tombstone_player_init()
{
	self.tombstone_index = level.tombstone_index;
	level.tombstone_index++;
	level.tombstones[self.tombstone_index] = SpawnStruct();
	self ent_flag_init("tombstone_spawned", false);
}

tombstone_spawn()
{
	dc = spawn_model("tag_origin", self.origin + (0, 0, 40), self.angles);
	dc_icon = spawn_model("ch_tombstone1", dc.origin, dc.angles);
	dc_icon LinkTo(dc);
	dc.icon = dc_icon;
	dc.script_noteworthy = "player_tombstone_model";
	dc.player = self;
	self thread tombstone_clear();
	dc thread tombstone_wobble();
	dc thread tombstone_revived(self);
	result = self waittill_any_return("player_revived", "spawned_player", "disconnect", "tombstone_bypass");

	if(result == "player_revived" || result == "disconnect")
	{
		dc notify("tombstone_timedout");
		dc_icon Unlink();
		dc_icon Delete();
		dc Delete();
		return;
	}
	dc thread tombstone_timeout();
	dc thread tombstone_grab();
}

tombstone_clear()
{
	self waittill_either("tombstone_timedout", "tombstone_grabbed");
	level.tombstones[self.tombstone_index] = SpawnStruct();
}

tombstone_revived(player)
{
	self endon("tombstone_timedout");
	player endon("disconnect");

	shown = true;

	while(isdefined(self) && isdefined(player))
	{
		if(isdefined(player.reviveTrigger) && is_true(player.reviveTrigger.beingRevived))
		{
			if(shown)
			{
				shown = false;
				self.icon Hide();
			}
		}
		else
		{
			if(!shown)
			{
				shown = true;
				self.icon Show();
			}
		}
		wait .05;
	}
}

tombstone_laststand()
{
	dc = level.tombstones[self.tombstone_index];
	dc.player = self;
	dc.loadout = self maps\_zm_weapons::player_get_loadout();
	dc.perks = self get_perk_array();
}

tombstone_grab()
{
	self endon("tombstone_timedout");

	wait 1;

	for(;;)
	{
		players = GetPlayers();

		for(i = 0; i < players.size; i++)
		{
			if(players[i].is_zombie)
				continue;
			
			if(isdefined(self.player) && players[i] == self.player)
			{
				istombstonepowered = false;

				if(isdefined(level._zm_perk_machines) && isdefined(level._zm_perk_machines["tombstone"]) && level._zm_perk_machines["tombstone"].size > 0)
				{
					for(j = 0; j < level._zm_perk_machines["tombstone"].size; j++)
					{
						if(is_true(level._zm_perk_machines["tombstone"][i].power_on))
						{
							istombstonepowered = true;
							break;
						}
					}
				}

				if(istombstonepowered)
				{
					if(Distance(players[i].origin, self.origin) < 64)
					{
						PlayFX(level._effect["powerup_grabbed"], self.origin);
						PlayFX(level._effect["powerup_grabbed_wave"], self.origin);
						players[i] tombstone_give();
						wait .1;
						PlaySoundAtPosition("zmb_tombstone_grab", self.origin);
						self StopLoopSound();
						self.icon Unlink();
						self.icon Delete();
						self Delete();
						self notify("tombstone_grabbed");
						players[i] clientNotify("dc0");
						players[i] notify("dance_on_my_grave");
					}
				}
			}
		}
		wait_network_frame();
	}
}

tombstone_give()
{
	dc = level.tombstones[self.tombstone_index];
	self maps\_zm_weapons::player_give_loadout(dc.loadout, true);

	for(i = 0; i < dc.perks.size; i++)
	{
		if(self has_perk(dc.perks[i]))
			continue;
		if(dc.perks[i] == "revive" && is_solo_game())
			continue;
		
		self give_perk(dc.perks[i], false);
	}
}

tombstone_wobble()
{
	self endon("tombstone_grabbed");
	self endon("tombstone_timedout");

	wait 1;

	PlayFXOnTag(level._effect["powerup_on"], self, "tag_origin");
	self PlaySound("zmb_tombstone_spawn");
	self PlayLoopSound("zmb_tombstone_looper");

	while(isdefined(self))
	{
		self RotateYaw(360, 3);
		wait 2.9;
	}
}

tombstone_timeout()
{
	self endon("tombstone_grabbed");
	self thread playtombstonetimeraudio();
	wait 48.5;

	for(i = 0; i < 40; i++)
	{
		if(i % 2)
			self.icon Hide();
		else
			self.icon Show();
		
		if(i < 15)
			wait .5;
		else if(i < 25)
			wait .25;
		else
			wait .1;
	}

	self notify("tombstone_timedout");
	self.icon Unlink();
	self.icon Delete();
	self Delete();
}

playtombstonetimeraudio()
{
	self endon("tombstone_grabbed");
	self endon("tombstone_timedout");
	player = self.player;
	self thread playtombstonetimerout(player);

	for(;;)
	{
		player PlaySoundToPlayer("zmb_tombstone_timer_count", player);
		wait 1;
	}
}

playtombstonetimerout(player)
{
	self endon("tombstone_grabbed");
	self waittill("tombstone_timedout");
	player PlaySoundToPlayer("zmb_tombstone_timer_out", player);
}

is_weapon_available_in_tombstone(weapon, player_to_check)
{
	count = 0;

	for(i = 0; i < level.tombstones.size; i++)
	{
		dc = level.tombstones[i];

		if(isdefined(player_to_check) && dc.player != player_to_check)
			continue;
		
		count += maps\_zm_weapons::is_weapon_available_in_loadout(weapon, dc.loadout);
	}
	return count;
}

on_laststand()
{
	if(self ent_flag("tombstone_spawned"))
		return;
	
	if(self has_perk("tombstone"))
	{
		run_function(self, level.tombstone_laststand_func);
		single_thread(self, level.tombstone_spawn_func);
		self ent_flag_set("tombstone_spawned");
	}
}