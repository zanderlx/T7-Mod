#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	if(!maps\_zm_weapons::is_weapon_included("claymore_zm"))
		return;

	level.claymores = [];
	level._effect["claymore_laser"] = LoadFX("weapon/claymore/fx_claymore_laser");

	OnPlayerSpawned_Callback(::init_claymore_watcher);
}

init_claymore_watcher()
{
	self endon("disconnect");
	waittillframeend;
	wait 1;

	watcher = maps\_weaponobjects::get_weapon_object_watcher_by_weapon("claymore_zm");
	Assert(isdefined(watcher));
	watcher.onSpawn = ::on_claymore_spawned;
	watcher.onSpawnFX = maps\_weaponobjects::on_spawn_claymore_fx;
	watcher.activateSound = "claymore_activated_SP";
	watcher.detectionDot = Cos(70);
	watcher.detectionMinDist = 20;
	watcher.skip_weapon_object_damage = false;
}

on_claymore_spawned(watcher, player)
{
	self thread claymore_detonation(watcher);
	// self thread claymore_damage();
	self maps\_zm_placeable_mine::enable_placeable_mine_triggers("claymore_zm");
}

claymore_detonation(watcher)
{
	self endon("death");
	self waittill_not_moving();

	if(!isdefined(level.claymores))
		level.claymores = [];

	trigger = Spawn("trigger_radius", self.origin + (0, 0, 0 - 96), 1, 96, 192);
	trigger EnableLinkTo();
	trigger LinkTo(self);

	self thread delete_claymores_on_death(trigger);

	level.claymores[level.claymores.size] = self;

	if(level.claymores.size > 15)
		level.claymores[0] Delete();

	for(;;)
	{
		trigger waittill("trigger", ent);

		if(isdefined(self.owner) && ent == self.owner)
			continue;
		if(isdefined(ent.pers) && isdefined(ent.pers["team"]) && ent.pers["team"] != "axis")
			continue;
		if(!self can_zombie_detonate_claymore(watcher, ent))
			continue;

		if(ent DamageConeTrace(self.origin, self) > 0)
		{
			self PlaySound(watcher.activateSound);
			wait .4;
			self maps\_weaponobjects::weapon_detonate(self.owner);
			return;
		}
	}
}

delete_claymores_on_death(trigger)
{
	self waittill("death");
	level.claymores = array_remove_nokeys(level.claymores, self);
	level.claymores = array_removeUndefined(level.claymores);

	wait .05;

	if(isdefined(trigger))
		trigger Delete();
}

can_zombie_detonate_claymore(watcher, zombie)
{
	pos = zombie.origin + (0, 0, 32);
	dirToPos = pos - self.origin;
	objectForward = AnglesToForward(self.angles);
	dist = VectorDot(dirToPos, objectForward);

	if(dist < watcher.detectionMinDist)
		return false;

	dirToPos = VectorNormalize(dirToPos);
	dot = VectorDot(dirToPos, objectForward);
	return dot > watcher.detectionDot;
}