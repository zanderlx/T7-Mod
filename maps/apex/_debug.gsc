#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

/#
debug_init()
{
	if(GetDebugDvarString("scr_zm_playerTrigger_debug", "") == "")
		SetDvar("scr_zm_playerTrigger_debug", "0");

	OnPlayerConnect_Callback(::debug_update_dvars);
}

debug_update_dvars()
{
	self endon("disconnect");

	self SetClientDvars(
		"ui_dbg_x", 0,
		"ui_dbg_y", 0,
		"ui_dbg_player_origin", self.origin,
		"ui_dbg_player_angles", self.angles
	);

	for(;;)
	{
		self SetClientDvars(
			"ui_dbg_player_origin", self.origin,
			"ui_dbg_player_angles", self.angles
		);

		wait .05;
	}
}

//============================================================================================
// Trigger
//============================================================================================
DrawTrigger(color)
{
	if(!isdefined(color))
		color = (1, 1, 1);

	radius = 16;
	height = 16;
	angles = (0, 0, 0);

	if(isdefined(self.radius))
		radius = self.radius;
	if(isdefined(self.height))
		height = self.height;
	if(isdefined(self.angles))
		angles = self.angles;

	mins = (0 - radius, 0 - radius, 0 - height);
	maxs = (radius, radius, height);

	Box(self.origin, mins, maxs, angles[1], color);
}

//============================================================================================
// Strings
//============================================================================================
DrawStringList(origin, strings, color, offset_z)
{
	if(!isdefined(strings))
		return;
	if(!isdefined(color))
		color = (1, 0, 0);
	if(!isdefined(offset_z))
		offset_z = 15;

	start = origin + (0, 0, strings.size + 1 * 10);

	for(i = 0; i < strings.size; i++)
	{
		Print3D(start - (0, 0, i * offset_z), strings[i], color);
	}
}

//============================================================================================
// PlayerTrigger - xSanchez78
//============================================================================================
playertrigger_debug(player)
{
	if(!GetDebugDvarBool("scr_zm_playerTrigger_debug", false))
		return;

	origin = self maps\apex\_utility_code::playertrigger_origin();
	trigger = self maps\apex\_utility_code::playertrigger_trigger(player);
	radius = self.radius;
	height = self.height;

	if(isdefined(trigger))
	{
		trigger.radius = radius;
		trigger.height = height;
		trigger DrawTrigger((0, 1, 0));
	}

	DrawCylinder(origin, radius/2, height/2);
	DrawStringList(origin, array(
		"playertrigger:",
		"OP: " + player.playername,
		"R: " + radius,
		"H: " + height
	));
}
#/