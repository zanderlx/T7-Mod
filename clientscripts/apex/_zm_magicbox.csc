#include clientscripts\_utility;
#include clientscripts\apex\_utility;

init()
{
	level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM = 15;
	register_clientflag_callback("scriptmover", level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM, ::weapon_box_callback);
}

weapon_box_callback(clientnum, set, newEnt)
{
	if(clientnum != 0)
		return;

	if(is_true(set))
		self thread weapon_floats_up();
	else
	{
		self notify("end_float");
		self cleanup_weapon_models();
	}
}

cleanup_weapon_models()
{
	if(isdefined(self.weapon_models))
	{
		players = GetLocalPlayers();

		for(i = 0; i < players.size; i++)
		{
			if(isdefined(self.weapon_models[i]))
			{
				self.weapon_models[i].dw Delete();
				self.weapon_models[i] Delete();
			}
		}
		self.weapon_models = undefined;
	}
}

weapon_floats_up()
{
	self endon("end_float");
	cleanup_weapon_models();
	self.weapon_models = [];
	weapon = treasure_chest_ChooseRandomWeapon();
	players = GetLocalPlayers();

	for(i = 0; i < players.size; i++)
	{
		self.weapon_models[i] = Spawn(i, self.origin, "script_model");
		self.weapon_models[i].angles = self.angles + (0, 180, 0);
		self.weapon_models[i] SetModel(GetWeaponModel(weapon));
		self.weapon_models[i] UseWeaponHideTags(weapon);

		self.weapon_models[i].dw = Spawn(i, self.weapon_models[i].origin - (3, 3, 3), "script_model");
		self.weapon_models[i].dw.angles = self.weapon_models[i].angles;
		self.weapon_models[i].dw Hide();
		self.weapon_models[i].dw LinkTo(self.weapon_models[i], "tag_origin");

		if(clientscripts\_zombiemode_weapons::weapon_is_dual_wield(weapon))
		{
			self.weapon_models[i].dw SetModel(clientscripts\_zombiemode_weapons::get_left_hand_weapon_model_name(weapon));
			self.weapon_models[i].dw UseWeaponHideTags(weapon);
		}

		self.weapon_models[i] MoveTo(self.origin + (0, 0, 64), 3, 2, .9);
	}

	for(i = 0; i < 39; i++)
	{
		if(i < 20)
			RealWait(.05);
		else if(i < 30)
			RealWait(.1);
		else if(i < 35)
			RealWait(.2);
		else if(i < 38)
			RealWait(.3);

		weapon = treasure_chest_ChooseRandomWeapon();
		players = GetLocalPlayers();

		for(j = 0; j < players.size; j++)
		{
			if(isdefined(self.weapon_models[j]))
			{
				self.weapon_models[j] SetModel(GetWeaponModel(weapon));
				self.weapon_models[j] UseWeaponHideTags(weapon);

				if(clientscripts\_zombiemode_weapons::weapon_is_dual_wield(weapon))
				{
					self.weapon_models[j].dw SetModel(clientscripts\_zombiemode_weapons::get_left_hand_weapon_model_name(weapon));
					self.weapon_models[j].dw UseWeaponHideTags(weapon);
					self.weapon_models[j].dw Show();
				}
				else
					self.weapon_models[j].dw Hide();
			}
		}
	}
	self cleanup_weapon_models();
}

treasure_chest_ChooseRandomWeapon()
{
	if(!isdefined(level._display_box_weapons))
		level._display_box_weapons = array("python_zm", "g11_lps_zm", "famas_zm");

	return random(level._display_box_weapons);
}