#include clientscripts\_utility;

weapon_is_dual_wield(name)
{
	switch(name)
	{
		case  "cz75dw_zm":
		case  "cz75dw_upgraded_zm":
		case  "m1911_upgraded_zm":
		case  "hs10_upgraded_zm":
		case  "pm63_upgraded_zm":
		case  "microwavegundw_zm":
		case  "microwavegundw_upgraded_zm":
			return true;
		default:
			return false;
	}
}

get_left_hand_weapon_model_name( name )
{
	switch ( name )
	{
		case  "microwavegundw_zm":
			return GetWeaponModel( "microwavegunlh_zm" );
		case  "microwavegundw_upgraded_zm":
			return GetWeaponModel( "microwavegundwlh_upgraded_zm" );
		default:
			return GetWeaponModel( name );
	}
}

is_weapon_included( weapon_name )
{
	if ( !IsDefined( level._included_weapons ) )
	{
		return false;
	}

	for ( i = 0; i < level._included_weapons.size; i++ )
	{
		if ( weapon_name == level._included_weapons[i] )
		{
			return true;
		}
	}

	return false;
}


include_weapon( weapon, display_in_box, func )
{
	if ( !IsDefined( level._included_weapons ) )
	{
		level._included_weapons = [];
	}

	level._included_weapons[level._included_weapons.size] = weapon;

	if ( !IsDefined( level._display_box_weapons ) )
	{
		level._display_box_weapons = [];
	}

	if ( !IsDefined( display_in_box ) )
	{
		display_in_box = true;
	}

	if ( !display_in_box )
	{
		return;
	}

	level._display_box_weapons[level._display_box_weapons.size] = weapon;
}