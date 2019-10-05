#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	flag_init("_start_zm_pistol_rank", false);
	flag_init("solo_game", false);
	registerClientSys("apex_client_sys");
	set_zombie_var("player_base_health", 100);

	maps\_zm_gametype::init();
	maps\_zm_powerups::init();
	maps\_zm_trigger_per_player::init();
	maps\_zm_power::init();
	maps\_zm_magicbox::init();
	maps\_zm_weapons::init();
	maps\_zm_perks::init();
	maps\_zm_packapunch::init();

	maps\weapons\_zm_weap_claymore::init();
	maps\weapons\_zm_weap_tesla::init();
	maps\weapons\_zm_weap_thundergun::init();
	maps\weapons\_zm_weap_crossbow::init();

	level thread post_all_players_connected();

	/#
	level.zombie_vars["zombie_perk_limit"] = level._custom_perks.size;
	#/

	OnPlayerConnect_Callback(::player_connect);
}

post_all_players_connected()
{
	flag_wait("all_players_connected");
	flag_set("_start_zm_pistol_rank");

	if(is_solo_game())
	{
		flag_set("solo_game");
		maps\_zombiemode::zombiemode_solo_last_stand_pistol();
		array_run(GetPlayers(), ::player_solo_init);
	}
}

player_solo_init()
{
	self.lives = 0;
}

player_connect()
{
	self thread onPlayerSpawned();
	self thread debug_update_dvars();
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		self _Callback("on_player_spawned");
	}
}

// Debug
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