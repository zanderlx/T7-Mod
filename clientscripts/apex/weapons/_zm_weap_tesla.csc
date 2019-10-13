#include clientscripts\_utility;
#include clientscripts\_fx;
#include clientscripts\_music;

include_weapon_for_level()
{
	level._effect["tesla_viewmodel_rail"] = LoadFX("maps/zombie/fx_zombie_tesla_rail_view");
	level._effect["tesla_viewmodel_tube"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view");
	level._effect["tesla_viewmodel_tube2"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view2");
	level._effect["tesla_viewmodel_tube3"] = LoadFX("maps/zombie/fx_zombie_tesla_tube_view3");
	level._effect["tesla_viewmodel_rail_upgraded"]	= LoadFX("maps/zombie/fx_zombie_tesla_rail_view_ug");
	level._effect["tesla_viewmodel_tube_upgraded"]	= LoadFX("maps/zombie/fx_zombie_tesla_tube_view_ug");
	level._effect["tesla_viewmodel_tube2_upgraded"]	= LoadFX("maps/zombie/fx_zombie_tesla_tube_view2_ug");
	level._effect["tesla_viewmodel_tube3_upgraded"]	= LoadFX("maps/zombie/fx_zombie_tesla_tube_view3_ug");

	level thread player_init();
	level thread tesla_notetrack_think();
}

player_init()
{
	waitforclient(0);
	level.tesla_play_fx = [];
	level.tesla_play_rail = true;

	players = GetLocalPlayers();
	for(i = 0; i < players.size; i++)
	{
		level.tesla_play_fx[i] = false;
		players[i] thread tesla_fx_rail(i);
		players[i] thread tesla_fx_tube(i);
		players[i] thread tesla_happy(i);
	}
}

tesla_fx_rail(clientnum)
{
	self endon("disconnect");

	for(;;)
	{
		RealWait(RandomFloatRange(8, 12));

		if(!level.tesla_play_fx[clientnum])
			continue;
		if(!level.tesla_play_rail)
			continue;

		currentweapon = GetCurrentWeapon(clientnum);

		if(currentweapon != "tesla_gun_zm" && currentweapon != "tesla_gun_upgraded_zm")
			continue;
		if(IsADS(clientnum) || IsThrowingGrenade(clientnum) || IsMeleeing(clientnum) || IsOnTurret(clientnum))
			continue;
		if(GetWeaponAmmoClip(clientnum, currentweapon) <= 0)
			continue;

		fx = level._effect["tesla_viewmodel_rail"];

		if(currentweapon == "tesla_gun_upgraded_zm")
			fx = level._effect["tesla_viewmodel_rail_upgraded"];

		PlayViewmodelFx(clientnum, fx, "tag_flash");
		PlaySound(clientnum, "wpn_tesla_effects", (0, 0, 0));
	}
}

tesla_fx_tube(clientnum)
{
	self endon("disconnect");

	for(;;)
	{
		RealWait(.1);

		if(!level.tesla_play_fx[clientnum])
			continue;

		currentweapon = GetCurrentWeapon(clientnum);

		if(currentweapon != "tesla_gun_zm" && currentweapon != "tesla_gun_upgraded_zm")
			continue;
		if(IsThrowingGrenade(clientnum) || IsMeleeing(clientnum) || IsOnTurret(clientnum))
			continue;

		ammo = GetWeaponAmmoClip(clientnum, currentweapon);

		if(ammo <= 0)
			continue;

		fx = level._effect["tesla_viewmodel_tube"];

		if(currentweapon == "tesla_gun_upgraded_zm")
		{
			if(ammo == 3 || ammo == 4)
				fx = level._effect["tesla_viewmodel_tube2_upgraded"];
			else if(ammo == 1 || ammo == 2)
				fx = level._effect["tesla_viewmodel_tube3_upgraded"];
			else
				fx = level._effect["tesla_viewmodel_tube_upgraded"];
		}
		else
		{
			if(ammo == 1)
				fx = level._effect["tesla_viewmodel_tube3"];
			else if ( ammo == 2 )
				fx = level._effect["tesla_viewmodel_tube2"];
			else
				fx = level._effect["tesla_viewmodel_tube"];
		}

		PlayViewmodelFx(clientnum, fx, "tag_brass");
	}
}

tesla_notetrack_think()
{
	for(;;)
	{
		level waittill("notetrack", clientnum, note);

		switch( note )
		{
			case "sndnt#wpn_tesla_switch_flip_off":
			case "sndnt#wpn_tesla_first_raise_start":
				level.tesla_play_fx[clientnum] = false;
				break;

			case "sndnt#wpn_tesla_switch_flip_on":
			case "sndnt#wpn_tesla_pullout_start":
			case "tesla_idle_start":
				level.tesla_play_fx[clientnum] = true;
				break;
		}
	}
}

tesla_happy(clientnum)
{
	for(;;)
	{
		level waittill("TGH");

		currentweapon = GetCurrentWeapon(clientnum);

		if(currentweapon == "tesla_gun_zm" || currentweapon == "tesla_gun_upgraded_zm")
		{
			PlaySound(clientnum, "wpn_tesla_happy", (0, 0, 0));
			level.tesla_play_rail = false;
			RealWait(2);
			level.tesla_play_rail = true;
		}
	}
}