#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

#using_animtree("zm_ally");

spawn_player_clone(player, origin, forceWeapon, forceModel)
{
	if(isdefined(forceModel))
		model = forceModel;
	else
		model = player.model;

	clone = spawn_model(model, origin, player.angles);

	if(isdefined(forceWeapon) && forceWeapon != "none")
		clone maps\apex\_zm_weapons::attach_weapon_model(forceWeapon, undefined, undefined, player);
	else
		clone maps\apex\_zm_weapons::attach_weapon_model(player GetCurrentWeapon(), undefined, undefined, player);

	if(isdefined(player.headModel))
	{
		clone.headModel = player.headModel;
		clone Attach(clone.headModel, "", true);
	}

	if(isdefined(player.hatModel))
	{
		clone.hatModel = player.hatModel;
		clone Attach(clone.hatModel);
	}

	clone thread ballistic_knife_revive();
	return clone;
}

ballistic_knife_revive()
{
	self endon("death");
	self MakeFakeAI();
	self SetCanDamage(true);
	self.team = level.player_team;
	self.health = 999999;
	self thread ballistic_knife_melee_watcher();
	array_thread(GetPlayers(), ::ballistic_knife_watcher, self);
}

ballistic_knife_melee_watcher()
{
	self endon("death");

	for(;;)
	{
		self waittill("damage", amount, attacker, direction_vec, point, type);
		weapon = attacker GetCurrentWeapon();

		if(type == "MOD_MELEE")
		{
			if(maps\apex\_zm_melee_weapon::is_ballistic_knife(weapon) && maps\apex\_zm_weapons::is_weapon_upgraded(weapon))
				self notify("player_revived", attacker);
		}
	}
}

ballistic_knife_watcher(clone)
{
	self endon("disconnect");
	clone endon("death");

	for(;;)
	{
		self waittill("ballistic_knife_stationary", retrievable_model, normal, prey);

		if(isdefined(prey) && prey == clone)
		{
			if(maps\apex\_zm_melee_weapon::is_ballistic_knife(retrievable_model.name) && maps\apex\_zm_weapons::is_weapon_upgraded(retrievable_model.name))
			{
				clone notify("player_revived", self);
				return;
			}
		}
	}
}

clone_animate(animtype)
{
	self UseAnimTree(#animtree);

	switch(animtype)
	{
		case "laststand":
			self SetAnim(%pb_laststand_idle);
			break;

		// case "afterlife":
		// 	self SetAnim(%pb_afterlife_laststand_idle);
		// 	break;

		case "idle":
		default:
			self SetAnim(%pb_stand_alert);
			break;
	}
}