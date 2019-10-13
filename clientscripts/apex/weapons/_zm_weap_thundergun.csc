#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_weapon_for_level()
{
	level._effect["thundergun_viewmodel_power_cell1"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view1");
	level._effect["thundergun_viewmodel_power_cell2"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view2");
	level._effect["thundergun_viewmodel_power_cell3"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view3");
	level._effect["thundergun_viewmodel_steam"] = LoadFX("weapon/thunder_gun/fx_thundergun_steam_view");
	level._effect["thundergun_viewmodel_power_cell_upgraded1"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view1");
	level._effect["thundergun_viewmodel_power_cell_upgraded2"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view2");
	level._effect["thundergun_viewmodel_power_cell_upgraded3"] = LoadFX("weapon/thunder_gun/fx_thundergun_power_cell_view3");
	level._effect["thundergun_viewmodel_steam"] = LoadFX("weapon/thunder_gun/fx_thundergun_steam_view");
	level._effect["thundergun_viewmodel_steam_upgraded"] = LoadFX("weapon/thunder_gun/fx_thundergun_steam_view");

	level.thundergun_steam_vents = 3;
	level.thundergun_power_cell_fx_handles = [];
	level.thundergun_power_cell_fx_handles[level.thundergun_power_cell_fx_handles.size] = -1;
	level.thundergun_power_cell_fx_handles[level.thundergun_power_cell_fx_handles.size] = -1;
	level.thundergun_power_cell_fx_handles[level.thundergun_power_cell_fx_handles.size] = -1;

	level thread player_init();
	level thread thundergun_notetrack_think();
}

player_init()
{
	waitforclient(0);
	level.thundergun_play_fx_power_cell = [];

	players = GetLocalPlayers();
	for(i = 0; i < players.size; i++)
	{
		level.thundergun_play_fx_power_cell[i] = true;
		players[i] thread thundergun_fx_power_cell(i);
	}
}

thundergun_fx_power_cell(clientnum)
{
	self endon("disconnect");

	oldAmmo = -1;
	oldCount = -1;
	self thread thundergun_fx_listener(clientnum);

	for(;;)
	{
		RealWait(.1);

		while(!ClientHasSnapshot(0))
		{
			wait 1/60;
		}

		currentweapon = GetCurrentWeapon(clientnum);

		if(!level.thundergun_play_fx_power_cell[clientnum] || IsThrowingGrenade(clientnum) || IsMeleeing(clientnum) || IsOnTurret(clientnum) || (currentweapon != "thundergun_zm" && currentweapon != "thundergun_upgraded_zm"))
		{
			if(oldAmmo != -1)
				thundergun_play_power_cell_fx(clientnum, 0);

			oldAmmo = -1;
			oldCount = -1;
			continue;
		}

		ammo = GetWeaponAmmoClip(clientnum, currentweapon);

		if(oldAmmo > 0 && oldAmmo != ammo)
			thundergun_fx_fire(clientnum);

		oldAmmo = ammo;

		if(ammo > level.thundergun_power_cell_fx_handles.size)
			ammo = level.thundergun_power_cell_fx_handles.size;

		if(oldCount == -1 || oldCount != ammo)
			level thread thundergun_play_power_cell_fx(clientnum, ammo);

		oldCount = ammo;
	}
}

thundergun_play_power_cell_fx(clientnum, count)
{
	level notify( "kill_power_cell_fx" );

	for(i = 0; i < level.thundergun_power_cell_fx_handles.size; i++)
	{
		if(isdefined(level.thundergun_power_cell_fx_handles[i]) && level.thundergun_power_cell_fx_handles[i] != -1)
		{
			DeleteFX(clientnum, level.thundergun_power_cell_fx_handles[i]);
			level.thundergun_power_cell_fx_handles[i] = -1;
		}
	}

	if(!count)
		return;

	level endon("kill_power_cell_fx");

	for ( ;; )
	{
		currentweapon = GetCurrentWeapon(clientnum);

		if(currentweapon != "thundergun_zm" && currentweapon != "thundergun_upgraded_zm")
		{
			wait 1/60;
			continue;
		}

		for(i = count; i > 0; i--)
		{
			fx = level._effect["thundergun_viewmodel_power_cell" + i];

			if(currentweapon == "thundergun_upgraded_zm")
				fx = level._effect["thundergun_viewmodel_power_cell_upgraded" + i];

			level.thundergun_power_cell_fx_handles[i - 1] = PlayViewmodelFx(clientnum, fx, "tag_bulb" + i);
		}
		RealWait(3);
	}
}

thundergun_fx_fire(clientnum)
{
	currentweapon = GetCurrentWeapon(clientnum);

	fx = level._effect["thundergun_viewmodel_steam"];

	if(currentweapon == "thundergun_upgraded_zm")
		fx = level._effect["thundergun_viewmodel_steam_upgraded"];

	for(i = level.thundergun_steam_vents; i > 0; i--)
	{
		PlayViewmodelFx(clientnum, fx, "tag_steam" + i);
	}

	PlaySound(clientnum, "wpn_thunder_breath", (0, 0, 0));
}

thundergun_notetrack_think()
{
	for(;;)
	{
		level waittill("notetrack", clientnum, note);

		switch(note)
		{
			case "thundergun_putaway_start":
				level.thundergun_play_fx_power_cell[clientnum] = false;
				break;

			case "thundergun_pullout_start":
				level.thundergun_play_fx_power_cell[clientnum] = true;
				break;

			case "thundergun_fire_start":
				thundergun_fx_fire(clientnum);
				break;
		}
	}
}

thundergun_death_effects(clientnum, weaponname, userdata)
{
}

thundergun_fx_listener(clientnum)
{
	self endon("disconnect");

	for(;;)
	{
		level waittill("tgfx0");
		level.thundergun_play_fx_power_cell[clientnum] = false;
		level waittill("tgfx1");
		level.thundergun_play_fx_power_cell[clientnum] = true;
	}
}
