#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zm_utility;

init()
{
	OnPlayerConnect_Callback(::player_connect);
}

player_connect()
{
	self.hero_weapon_power = 0;
	self.current_player_hero_weapon = "none";
}

give_hero_weapon(weapon_name)
{
	self set_player_hero_weapon(weapon_name);
}

take_hero_weapon(weapon_name)
{
	self set_player_hero_weapon("none");
}