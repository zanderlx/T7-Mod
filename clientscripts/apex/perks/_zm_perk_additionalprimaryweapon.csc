#include clientscripts\_utility;
#include clientscripts\apex\_utility;

include_perk_for_level()
{
	clientscripts\apex\_zm_perks::register_perk("mule_kick");
	clientscripts\apex\_zm_perks::add_perk_specialty("mule_kick", "specialty_additionalprimaryweapon");
	clientscripts\apex\_zm_perks::register_perk_threads("mule_kick", ::give_mule_kick, ::take_mule_kick);
	level._effect["perk_light_mule_kick"] = LoadFX("apex/misc/fx_zombie_cola_arsenal_on");
	level.zombiemode_using_additionalprimaryweapon_perk = true;
}

give_mule_kick(clientnum)
{
}

take_mule_kick(clientnum)
{
}