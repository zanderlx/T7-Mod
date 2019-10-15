#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_weapon_for_level()
{
	register_clientflag_callback("missile", level._CF_SCRIPTMOVER_CLIENT_FLAG_SPIKEMORE, ::spikemore_detonate);
	register_clientflag_callback("actor", level._CF_ACTOR_CLIENT_FLAG_SPIKEMORE, ::spikemore_add_spikes);

	level.spikemore_fired_recently = false;
	level.recent_spikemore_fire_origin = (0, 0, 0);
	level.recent_spikemore_fire_angles = (0, 0, 0);
	level.spikemore_detectionAngle = 50;
	level.spikemore_detectionDot = Cos(level.spikemore_detectionAngle);
	level.spikemore_projectile_speed = 1500;
}

_set_recently_fired(origin, angles)
{
	level.recent_spikemore_fire_origin = origin;
	level.recent_spikemore_fire_angels = angles;
}

spikemore_detonate(clientnum, int_set, ent_new)
{
	PlaySound(clientnum, "wpn_spikemore_impact", self.origin);
	/# PrintLn("Client Spikemore detonate: " + local_client_num); #/
	_set_recently_fired(self.origin, self.angels);
	PlayFX(clientnum, level._effect["fx_ztem_spikemore"], self.origin, AnglesToForward(self.angles));

	for(i = 0; i < 3; i++)
	{
		yaw = RandomFloatRange(level.recent_spikemore_fire_angles[1] - level.spikemore_detectionAngle, level.recent_spikemore_fire_angles[1] + level.spikemore_detectionAngle);
		forward = AnglesToForward((0, yaw, 0));
		z = RandomFloatRange(100, 150);
		dest = level.recent_spikemore_fire_origin + forward * 400 + (0, 0, z);
		trace = BulletTrace(level.recent_spikemore_fire_origin, dest, false, undefined);

		if(isdefined(trace) && trace["fraction"] < 1)
			level thread _spawn_spear(clientnum, trace, VectorToAngles(forward));
	}
}

_spawn_spear(clientnum, trace, angles)
{
	dist = Distance(trace["position"], level.recent_spikemore_fire_origin);
	time = dist / level.spikemore_projectile_speed;
	RealWait(time);
	e = spawn_model(clientnum, "t5_weapon_bamboo_spear_spikemore_small", trace["position"], angles + (0, 90, 0));
	delayed_remove(e);
}

spikemore_add_spikes(clientnum, int_set, ent_new)
{
	/# PrintLn("Client Spikemore add spikes"); #/

	j = [];
	j[j.size] = "J_SpineLower";
	j[j.size] = "J_Elbow_LE";
	j[j.size] = "J_Elbow_RI";
	j[j.size] = "J_Head";
	j[j.size] = "J_Clavicle_RI";
	j[j.size] = "J_Clavicle_LE";
	j[j.size] = "J_Hip_LE";
	j[j.size] = "J_Hip_RI";
	j = array_randomize(j);

	for(i = 0; i < 3 && i < j.size; i++)
	{
		joint = j[i];
		jointPos = self GetTagOrigin(joint);
		e = spawn_model(clientnum, "t5_weapon_bamboo_spear_spikemore_small", jointPos, (0, 0, 0));
		e LinkTo(self, joint);
		self thread delayed_remove_or_ent_shutdown(e);
	}
}

spikemore_waittill_notify_or_timeout(msg, timer)
{
	self endon(msg);
	RealWait(timer);
}

delayed_remove_or_ent_shutdown(ent)
{
	self spikemore_waittill_notify_or_timeout("entityshutdown", 10);

	if(isdefined(ent))
		ent Delete();
}

delayed_remove(ent)
{
	RealWait(10);

	if(isdefined(ent))
		ent Delete();
}
