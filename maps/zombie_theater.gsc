#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\zombie_theater_magic_box;
#include maps\zombie_theater_movie_screen;
#include maps\zombie_theater_quad;
#include maps\zombie_theater_teleporter;

#using_animtree("generic_human");

main()
{
	level thread maps\zombie_theater_ffotd::main_start();
	maps\zombie_theater_fx::main();
	maps\zombie_theater_amb::main();
	PrecacheModel("collision_geo_64x64x128");
	PrecacheModel("collision_wall_128x128x10");
	PrecacheModel("zombie_zapper_cagelight_red");
	PrecacheModel("zombie_zapper_cagelight_green");
	PrecacheShader("ac130_overlay_grain");
	PrecacheShellShock("electrocution");
	PrecacheModel("zombie_theater_reelcase_obj");
	PrecacheShader("zom_icon_theater_reel");
	PrecacheModel("viewmodel_usa_pow_arms");
	PrecacheModel("viewmodel_rus_prisoner_arms");
	PrecacheModel("viewmodel_vtn_nva_standard_arms");
	PrecacheModel("viewmodel_usa_hazmat_arms");
	PrecacheModel("zombie_zapper_cagelight_on");
	PrecacheModel("zombie_zapper_cagelight");
	PrecacheModel("lights_hang_single");
	PrecacheModel("lights_hang_single_on_nonflkr");
	PrecacheModel("zombie_theater_chandelier1arm_off");
	PrecacheModel("zombie_theater_chandelier1arm_on");
	PrecacheModel("zombie_theater_chandelier1_off");
	PrecacheModel("zombie_theater_chandelier1_on");

	if(GetDvarInt( #"artist") > 0)
		return;

	level.dogs_enabled = true;
	level.random_pandora_box_start = true;
	level.zombie_anim_override = maps\zombie_theater::anim_override_func;
	curtain_anim_init();
	level thread maps\_callbacksetup::SetupCallbacks();
	level.quad_move_speed = 35;
	level.quad_traverse_death_fx = maps\zombie_theater_quad::quad_traverse_death_fx;
	level.quad_explode = true;
	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;
	level.custom_ai_type = array(maps\_zombiemode_ai_quad::init, maps\_zombiemode_ai_dogs::init);
	level.door_dialog_function = maps\_zombiemode::play_door_dialog;
	level.first_round_spawn_func = true;
	level.use_zombie_heroes = true;
	level.disable_protips = 1;
	maps\_zombiemode::main();
	battlechatter_off("allies");
	battlechatter_off("axis");
	maps\_zombiemode_ai_dogs::enable_dog_rounds();
	init_zombie_theater();
	maps\_compass::setupMiniMap("menu_map_zombie_theater");
	level.ignore_spawner_func = ::theater_ignore_spawner;
	level.zone_manager_init_func = ::theater_zone_init;
	level thread maps\_zombiemode_zone_manager::manage_zones(array("foyer_zone", "foyer2_zone"));
	level thread maps\_zombiemode_auto_turret::init();
    level thread set_rope_collision();
	level.extracam_screen = GetEnt("theater_extracam_screen", "targetname");
	level.extracam_screen Hide();
	clientNotify("camera_stop");
	init_sounds();
	level thread spawn_theater_collisions();
	maps\zombie_theater_teleporter::teleport_pad_hide_use();
	level thread maps\zombie_theater_ffotd::main_end();
}

anim_override_func()
{
	level.scr_anim["zombie"]["walk7"] = %ai_zombie_walk_v8;
}

#using_animtree("zombie_theater");

curtain_anim_init() // Requires new function to use the zombie_theater animtree
{
	level.scr_anim["curtains_move"] = %o_zombie_theatre_curtain;
}

theater_playanim(animname)
{
	self UseAnimTree(#animtree);
	self AnimScripted(animname + "_done", self.origin, self.angles, level.scr_anim[animname], "normal", undefined, 2);
}

init_zombie_theater()
{
	flag_init("curtains_done", false);
	flag_init("lobby_occupied", false);
	flag_init("dining_occupied", false);
	flag_init("special_quad_round", false);

	level thread wait_for_power();
	level thread maps\zombie_theater_magic_box::magic_box_init();
	level thread maps\zombie_theater_movie_screen::initMovieScreen();
	level thread maps\zombie_theater_quad::init_roofs();
	level thread teleporter_intro();
}

teleporter_intro()
{
	flag_wait("all_players_spawned");

	wait .25;

	players = GetPlayers();

	for(i = 0; i < players.size; i++)
	{
		players[i] SetTransported(2);
	}

	PlaySoundAtPosition("evt_beam_fx_2d", (0, 0, 0));
	PlaySoundAtPosition("evt_pad_cooldown_2d", (0, 0, 0));
}

wait_for_power()
{
	flag_wait("power_on");
	maps\zombie_theater_teleporter::teleporter_init();

	chandelier = GetEntArray("theater_chandelier","targetname");

	for(i = 0; i < chandelier.size; i++)
	{
		if(chandelier[i].model == "zombie_theater_chandelier1arm_off")
			chandelier[i] SetModel("zombie_theater_chandelier1arm_on");
		else if(chandelier[i].model == "zombie_theater_chandelier1_off")
			chandelier[i] SetModel("zombie_theater_chandelier1_on");
	}

	wait_network_frame();
	level notify("Pack_A_Punch_on");
	wait_network_frame();
	players = GetPlayers();
	level.quads_per_round = 4 * players.size;
	level notify("quad_round_can_end");
	level.delay_spawners = undefined;
	level thread quad_wave_init();
}

init_sounds()
{
	maps\_zombiemode_utility::add_sound("wooden_door", "zmb_door_wood_open");
	maps\_zombiemode_utility::add_sound("fence_door", "zmb_door_fence_open");
}

theater_zone_init()
{
	flag_init("always_on", true);
	maps\_zombiemode_zone_manager::add_adjacent_zone("foyer_zone", "foyer2_zone", "always_on");
	maps\_zombiemode_zone_manager::add_adjacent_zone("foyer_zone", "vip_zone", "magic_box_foyer1");
	maps\_zombiemode_zone_manager::add_adjacent_zone("foyer2_zone", "crematorium_zone", "magic_box_crematorium1");
	maps\_zombiemode_zone_manager::add_adjacent_zone("foyer_zone", "crematorium_zone", "magic_box_crematorium1");
	maps\_zombiemode_zone_manager::add_adjacent_zone("vip_zone", "dining_zone", "vip_to_dining");
	maps\_zombiemode_zone_manager::add_adjacent_zone("crematorium_zone", "alleyway_zone", "magic_box_alleyway1");
	maps\_zombiemode_zone_manager::add_adjacent_zone("dining_zone", "dressing_zone", "dining_to_dressing");
	maps\_zombiemode_zone_manager::add_adjacent_zone("dressing_zone", "stage_zone", "magic_box_dressing1");
	maps\_zombiemode_zone_manager::add_adjacent_zone("stage_zone", "west_balcony_zone", "magic_box_west_balcony2");
	maps\_zombiemode_zone_manager::add_adjacent_zone("theater_zone", "foyer2_zone", "power_on");
	maps\_zombiemode_zone_manager::add_adjacent_zone("theater_zone", "stage_zone", "power_on");
	maps\_zombiemode_zone_manager::add_adjacent_zone("west_balcony_zone", "alleyway_zone", "magic_box_west_balcony1");
}

theater_ignore_spawner(spawner)
{
	if(!flag("curtains_done"))
	{
		if(spawner.script_noteworthy == "quad_zombie_spawner")
			return true;
	}

	if(flag("special_quad_round"))
	{
		if(spawner.script_noteworthy != "quad_zombie_spawner")
			return true;
	}

	if(!flag("lobby_occupied"))
	{
		if(spawner.script_noteworthy == "quad_zombie_spawner" && spawner.targetname == "foyer_zone_spawners")
			return true;
	}

	if(!flag("dining_occupied"))
	{
		if(spawner.script_noteworthy == "quad_zombie_spawner" && spawner.targetname == "zombie_spawner_dining")
			return true;
	}

	return false;
}

quad_wave_init()
{
	level thread time_for_quad_wave("foyer_zone");
	level thread time_for_quad_wave("theater_zone");
	level thread time_for_quad_wave("stage_zone");
	level thread time_for_quad_wave("dining_zone");
	level waittill("end_of_round");
	flag_clear("special_quad_round");
}

time_for_quad_wave(zone_name)
{
	level waittill("between_round_over");

	if(isdefined(level.next_dog_round) && level.next_dog_round == level.round_number)
	{
		level thread time_for_quad_wave(zone_name);
		return;
	}

	zone = level.zones[zone_name];
	max = level.zombie_vars["zombie_max_ai"];
	multiplier = level.round_number / 5;
	player_num = GetPlayers().size;
	chance = 100;
	current_round = level.round_number;

	if(multiplier < 1)
		multiplier = 1;
	if(current_round >= 10)
		multiplier *= current_round * .15;

	if(player_num == 1)
		max += Int((.5 * level.zombie_vars["zombie_ai_per_player"]) * multiplier);
	else
		max += Int(((player_num - 1) * level.zombie_vars["zombie_ai_per_player"]) * multiplier);

	max_zombies = maps\_zm_utility::run_function(level, level.max_zombie_func, max);

	if(current_round % 3 == 0 && chance >= RandomInt(100))
	{
		if(zone.is_occupied)
		{
			flag_set("special_quad_round");
			maps\_zombiemode_zone_manager::reinit_zone_spawners();

			while(level.zombie_total < max_zombies / 2 && current_round == level.round_number)
			{
				wait .1;
			}

			flag_clear("special_quad_round");
			maps\_zombiemode_zone_manager::reinit_zone_spawners();
		}
	}

	level thread time_for_quad_wave(zone_name);
}

set_rope_collision()
{
	techrope = GetEntArray("techrope01", "targetname");

	if(isdefined(techrope))
	{
		for(i = 0; i < techrope.size; i++)
		{
			RopeSetFlag(techrope[i], "collide", 1);
			RopeSetFlag(techrope[i], "no_lod", 1);
		}
	}
}

spawn_theater_collisions()
{
	ents = array(
		spawn_model("collision_geo_64x64x128", (-391, 1194, 16), (0, 301.8, 0)),
		spawn_model("collision_geo_64x64x128", (480, 1155, -16), (0, 357, 0)),
		spawn_model("collision_geo_64x64x128", (-20, 957, 128), (0, 0, 0)),
		spawn_model("collision_geo_64x64x128", (20, 957, 128), (0, 0, 0)),
		spawn_model("collision_wall_128x128x10", (1458, -57, 342), (0, 0, 0)),
		spawn_model("collision_wall_128x128x10", (1891, 576, 48), (0, 90, 0)),
		spawn_model("collision_wall_128x128x10", (1538, 1288, 48), (0, 90, 0)),
		spawn_model("collision_wall_128x128x10", (-1099, 1120, 332), (0, 90, 0)),
		spawn_model("collision_wall_128x128x10", (-1749, 552, 168), (0, 90, 0)),
		spawn_model("collision_wall_128x128x10", (-763, 834, 96), (0, 90, 0)),
		spawn_model("collision_geo_64x64x128", (-1746, -378, 147), (0, 0, 0))
	);

	for(i = 0; i < ents.size; i++)
	{
		ents[i] Hide();
	}
}