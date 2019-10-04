#include clientscripts\_utility;
#include clientscripts\_zm_utility;

init()
{
	level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM = 15;

	register_clientflag_callback("scriptmover", level._ZOMBIE_SCRIPTMOVER_FLAG_BOX_RANDOM, ::magicbox_cycle_callback);
}

magicbox_cycle_callback(clientnum, set, newEnt)
{
	if(clientnum != 0)
		return;
	
	if(set)
		self thread weapon_floats_up();
	else
	{
		self notify("end_float");
		cleanup_weapon_models();
	}
}

weapon_floats_up()
{
	self endon("end_float");
	cleanup_weapon_models();
	self.weapon_models = [];
	rand = treasure_chest_ChooseRandomWeapon();
	players = GetLocalPlayers();

	for(i = 0; i < players.size; i++)
	{
		self.weapon_models[i] = clientscripts\_zm_weapons::spawn_weapon_model(i, rand, self.origin, self.angles + (0, 180, 0));
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

		rand = treasure_chest_ChooseRandomWeapon();

		for(j = 0; j < self.weapon_models.size; j++)
		{
			if(isdefined(self.weapon_models[j]))
				self.weapon_models[j] clientscripts\_zm_weapons::model_use_weapon_options(j, rand);
		}
	}

	cleanup_weapon_models();
}

cleanup_weapon_models()
{
	if(isdefined(self.weapon_models))
	{
		for(i = 0; i < self.weapon_models.size; i++)
		{
			if(isdefined(self.weapon_models[i]))
				self.weapon_models[i] clientscripts\_zm_weapons::delete_weapon_model();
		}
		self.weapon_models = undefined;
	}
}

treasure_chest_ChooseRandomWeapon()
{
	return random(level._display_box_weapons);
}