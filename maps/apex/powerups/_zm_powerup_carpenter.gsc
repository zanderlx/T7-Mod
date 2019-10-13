#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\apex\_utility;

include_powerup_for_level()
{
	maps\apex\_zm_powerups::register_basic_powerup("carpenter", "p7_zm_power_up_carpenter", "powerup_green");
	maps\apex\_zm_powerups::register_powerup_funcs("carpenter", undefined, ::grab_carpenter, undefined, ::func_should_drop_carpenter);
}

grab_carpenter(player)
{
	level thread start_carpenter();
}

func_should_drop_carpenter()
{
	if(get_num_window_destroyed() < 5)
		return false;
	return true;
}

start_carpenter()
{
	ent = Spawn("script_origin", (0, 0, 0));
	ent PlayLoopSound("evt_carpenter");
	window_boards = level.exterior_goals;
	boards_near_players = get_near_boards(window_boards);
	boards_far_from_playrs = get_far_boards(window_boards);
	repair_far_boards(boards_far_from_playrs);
	repair_near_boards(boards_near_players);
	ent StopLoopSound();
	ent PlaySound("evt_carpenter_end", "sound_done");
	ent waittill("sound_done");
	array_func(GetPlayers(), maps\_zombiemode_score::player_add_points, "carpenter_powerup", 200);
	ent Delete();
}

get_near_boards(windows)
{
	players = GetPlayers();
	boards_near_players = [];

	for(i = 0; i < windows.size; i++)
	{
		window = windows[i];

		for(j = 0; j < players.size; j++)
		{
			player = players[j];

			if(DistanceSquared(player.origin, window.origin) <= 562500)
			{
				boards_near_players[boards_near_players.size] = window;
				break;
			}
		}
	}
	return boards_near_players;
}

get_far_boards(windows)
{
	players = GetPlayers();
	boards_far_from_playrs = [];

	for(i = 0; i < windows.size; i++)
	{
		window = windows[i];

		for(j = 0; j < players.size; j++)
		{
			player = players[j];

			if(DistanceSquared(player.origin, window.origin) >= 562500)
			{
				boards_far_from_playrs[boards_far_from_playrs.size] = window;
				break;
			}
		}
	}
	return boards_far_from_playrs;
}

repair_near_boards(barriers)
{
	for(i = 0; i < barriers.size; i++)
	{
		barrier = barriers[i];
		num_chunks_checked = 0;
		last_repaired_chunk = undefined;

		for(;;)
		{
			if(all_chunks_intact(barrier.barrier_chunks))
				break;

			chunk = get_random_destroyed_chunk(barrier.barrier_chunks);

			if(!isdefined(chunk))
				break;

			barrier thread maps\_zombiemode_blockers::replace_chunk(chunk, undefined, true);
			last_repaired_chunk = chunk;
			barrier.clip enable_trigger();
			barrier.clip DisconnectPaths();
			num_chunks_checked++;

			if(num_chunks_checked >= 20)
				break;
		}

		if(isdefined(last_repaired_chunk))
		{
			while(last_repaired_chunk.state == "mid_repair")
			{
				wait .05;
			}
		}
	}
}

repair_far_boards(barriers)
{
	for(i = 0; i < barriers.size; i++)
	{
		barrier = barriers[i];

		if(all_chunks_intact(barrier.barrier_chunks))
			continue;

		for(j = 0; j < barrier.barrier_chunks.size; j++)
		{
			chunk = barrier.barrier_chunks[j];
			chunk DontInterpolate();
			barrier maps\_zombiemode_blockers::replace_chunk_instant(chunk);
		}
		barrier.clip enable_trigger();
		barrier.clip DisconnectPaths();
		wait_network_frame();
		wait_network_frame();
		wait_network_frame();
	}
}

get_num_window_destroyed()
{
	num = 0;

	for(i = 0; i < level.exterior_goals.size; i++)
	{
		if(all_chunks_destroyed(level.exterior_goals[i].barrier_chunks))
			num++;
	}
	return num;
}