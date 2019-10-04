#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

include_powerup_for_level()
{
	maps\_zm_powerups::register_powerup("carpenter", "p7_zm_power_up_carpenter");
	maps\_zm_powerups::register_powerup_fx("carpenter", "powerup_green");
	maps\_zm_powerups::register_powerup_threads("carpenter", ::func_should_drop_carpenter, ::carpenter_grabbed, undefined, undefined);
}

carpenter_grabbed(player)
{
	level thread start_carpenter(self.origin);
	return true;
}

func_should_drop_carpenter()
{
	return get_num_window_destroyed() > 5;
	// return true;
}

start_carpenter(origin)
{
	ent = Spawn("script_origin", (0, 0, 0));
	ent PlayLoopSound("evt_carpenter");
	boards_near_players = get_near_boards();
	boards_far_from_players = array_exclude(level.exterior_goals, boards_near_players);
	repair_far_boards(boards_far_from_players);
	repair_near_boards(boards_near_players);
	ent StopLoopSound(1);
	ent PlaySoundWithNotify("evt_carpenter_end", "sound_done");
	ent waittill("sound_done");
	array_run(GetPlayers(), maps\_zombiemode_score::player_add_points, "carpenter_powerup", 200);
	ent Delete();
}

get_near_boards()
{
	players = GetPlayers();
	boards_near_players = [];

	for(i = 0; i < level.exterior_goals.size; i++)
	{
		close = false;

		for(j = 0; j < players.size; j++)
		{
			if(DistanceSquared(players[j].origin, level.exterior_goals[i].origin) <= 562500)
			{
				close = true;
				break;
			}
		}

		if(close)
			boards_near_players[boards_near_players.size] = level.exterior_goals[i];
	}
	return boards_near_players;
}

repair_far_boards(barriers)
{
	for(i = 0; i < barriers.size; i++)
	{
		if(all_chunks_intact(barriers[i].barrier_chunks))
			continue;
		
		for(j = 0; j < barriers[i].barrier_chunks.size; j++)
		{
			barriers[i].barrier_chunks[j] DontInterpolate();
			barriers[i] maps\_zombiemode_blockers::replace_chunk_instant(barriers[i].barrier_chunks[j]);
		}
		barriers[i].clip enable_trigger();
		barriers[i].clip DisconnectPaths();
		wait_network_frame();
		wait_network_frame();
		wait_network_frame();
	}
}

repair_near_boards(barriers)
{
	for(i = 0; i < barriers.size; i++)
	{
		num_chunks_checked = 0;
		last_repaired_chunk = undefined;

		for(;;)
		{
			if(all_chunks_intact(barriers[i].barrier_chunks))
				break;
			
			chunk = get_random_destroyed_chunk(barriers[i].barrier_chunks);

			if(!isdefined(chunk))
				break;
			
			barriers[i] thread maps\_zombiemode_blockers::replace_chunk(chunk, undefined, true);
			last_repaired_chunk = chunk;
			barriers[i].clip enable_trigger();
			barriers[i].clip DisconnectPaths();
			wait_network_frame();
			num_chunks_checked++;

			if(num_chunks_checked >= 20)
				break;
		}

		while(isdefined(last_repaired_chunk) && last_repaired_chunk.state == "mid_repair")
		{
			wait .05;
		}
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