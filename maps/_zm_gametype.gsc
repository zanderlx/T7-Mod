#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	if(!isdefined(level.zm_scr_gameloc_default))
		level.zm_scr_gameloc_default = "aether";
	if(!isdefined(level.zm_scr_gametype_default))
		level.zm_scr_gametype_default = "classic";

	level.zm_scr_gametype = GetDvar("scr_zm_gametype");
	level.zm_scr_gameloc = GetDvar("scr_zm_gameloc");

	if(level.zm_scr_gametype == "")
		level.zm_scr_gametype = level.zm_scr_gametype_default;
	if(level.zm_scr_gameloc == "")
		level.zm_scr_gameloc = level.zm_scr_gameloc_default;

	switch(level.zm_scr_gametype)
	{
		case "classic":
			maps\gametypes\classic::setup_gametype_for_level();
			break;

		default:
			/#
			AssertMsg("Unsupported Gametype: " + level.zm_scr_gametype);
			#/
			break;
	}
}

get_zm_scr_name(name)
{
	// level.scr_zm_gametype = "classic";
	// level.scr_zm_gameloc = "start_room";
	// get_zm_scr_name("perks") -> classic_perks_start_room

	return level.zm_scr_gametype + "_" + name + "_" + level.zm_scr_gameloc;
}

is_zm_scr_ent_valid(name)
{
	scr_name = get_zm_scr_name(name);

	if(isdefined(self.script_string))
	{
		tokens = StrTok(self.script_string, " ");

		if(IsInArray(tokens, scr_name))
			return true;
	}
	else
		return true;
}