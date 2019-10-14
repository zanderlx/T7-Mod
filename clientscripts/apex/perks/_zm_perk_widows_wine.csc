#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("widows");
	clientscripts\apex\_zm_perks::register_perk_threads("widows", ::give_widows, ::take_widows);

	clientscripts\apex\powerups\_zm_powerup_ww_grenade::include_powerup_for_level();

	level._effect["widows_wine_wrap"] = LoadFX("sanchez/widows_wine/fx_widows_wine_zombie");
	level._effect["widows_wine_exp_1p"] = LoadFX("sanchez/widows_wine/fx_widows_wine_explode");

	level.zombiemode_using_widows_perk = true;

	register_clientflag_callback("actor", 2, ::widows_wine_wrap_cb);
	register_client_system("widows_wine_1p_contact_explosion", ::widows_wine_1p_contact_explosion);
}

give_widows(clientnum)
{
}

take_widows(clientnum)
{
}

widows_wine_wrap_cb(localClientNum, set, newEnt)
{
	if(set)
	{
		if(isdefined(self) && IsAlive(self))
		{
			if(!isdefined(self.fx_widows_wine_wrap))
				self.fx_widows_wine_wrap = PlayFXOnTag(localClientNum, level._effect["widows_wine_wrap"], self, "j_spineupper");

			if(!isdefined(self.sndWidowsWine))
			{
				self PlaySound(0, "wpn_wwgrenade_cocoon_imp");
				self.sndWidowsWine = self PlayLoopSound("wpn_wwgrenade_cocoon_lp", 0.1);
			}
		}
	}
	else
	{
		if(isdefined(self.fx_widows_wine_wrap))
		{
			StopFX(localClientNum, self.fx_widows_wine_wrap);
			self.fx_widows_wine_wrap = undefined;
		}

		if(isdefined(self.sndWidowsWine))
		{
			self PlaySound(0, "wpn_wwgrenade_cocoon_stop");
			self StopLoopSound(self.sndWidowsWine, 0.1);
		}
	}
}

widows_wine_1p_contact_explosion(localClientNum, state, fieldName)
{
	level thread widows_wine_1p_contact_explosion_play(localClientNum);
}

widows_wine_1p_contact_explosion_play(localClientNum)
{
	fx_contact_explosion = PlayViewmodelFX(localClientNum, level._effect["widows_wine_exp_1p"], "tag_flash");
	RealWait(2);
	DeleteFX(localClientNum, fx_contact_explosion, true);
}