#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

/#
debug_init()
{
	if(GetDebugDvarString("scr_zm_playerTrigger_debug", "") == "")
		SetDvar("scr_zm_playerTrigger_debug", "0");
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
		Box(trigger.origin, (0 - radius, 0 - radius, 0 - height), (radius, radius, height), trigger.angles[1], (0, 1, 0));

	DrawCylinder(origin, radius/2, height/2);
	DrawStringList(origin, array(
		"playertrigger:",
		"OP: " + player.playername,
		"R: " + radius,
		"H: " + height
	));
}
#/