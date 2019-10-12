# T7-Mod
[![Discord](https://img.shields.io/badge/chat-Discord-blue.svg?label=Discord)](https://discord.gg/rTTb3uB)

Black Ops 1 mod, Rescripting and Downporting alot of features from newer games
See here for current mod [TODO list](https://github.com/ApexModder/T7-Mod/projects/1?fullscreen=true)
All development for this mod will and has been streamed live over at [**_ApexModder's_** Twitch](https://www.twitch.tv/apexmdr/)

**Note:** Mod has only been tested on Kino Der Toten so far, Other maps may & possible will crash, This is due to replacing functions and scripts they use.
Support for other maps will come once the base mod and all major function / script changes have been completed.

**Note:** There may be and possible are major bugs and issues in the mod. They will all be fixed by the time the mod releases.

## Features & Changes
- Player Trigger
	- These are triggers which handle all logic and prompts per player.
	- Every player sees a different hint string

- VisionSet System
	- Removed the vision system `_zombiemode.csc`
	- Replaced with a much improved version
	- Visions can be applied from server side that intreact with with the system client side

- Rewritten Powerups System
	- No longer any hard scripted logic in main powerups script
	- All powerup logic automated, individual powerups just speciy what happens during 'onGrab' 'onTimeout' 'onTimedPowerupStart' etc
	- All powerupes seperated in to a script per powerup
	- Black Ops III powerup hud logic downported

- Rewritten Perk System
	- Perks are no longer required to be named `specialty_`
	- Perks can still have `specialty` tied to them, that are set & unset with the perk
	- Perk icons moved to menu, this reduces the amount of HudElements used in script
	- No longer any hard scripted logic in main perks script
	- Perk bottle now supoprts 'indexed' models and 'weaponOptions.csv'
	- All perks seperated in to a script per perk
	- Perk machines now use `PlayerTriggers`

- Rewritten Pack-A-Punch
	- Pack-A-Punch now uses state based xanims
	- Pack-A-Punch now uses `PlayerTriggers`

- Rewritten Magicbox
	- Magicbox now uses state based xanims
	- Magicbox now uses `PlayerTriggers`
	- All Magicbox logic moved out of `_zombiemode_weapons.gsc/.csc` into `_zm_magicbox.gsc/.csc`
	- Fixed Magicbox cycle being fps based

- Rewritten Weapons Script
	- Weapons now loaded from csv string tables
		- Removed the need for each level to manually include
		- Auto registeres and loads correct weapons on the client side
		- Auto registeres correct weapons offhand types
	- Many weapon utility functions downported from Black Ops III
	- `weapon_give()` now supports any weapon type, not just primary and melee weapons
		- Swaps out lethal, tactical, melee weapons automaticly

## Credits
- **_ApexModder_** - Mod Owner
- **_xSanchez78_**
	- Ported **Black Ops 3** models and anims to **Black Ops 1**
	- **Huge** scripting help
		- VisionSet System
		- PlayerTrigger System
		- Various other down ported scripts
- **_Scobalula_** - For developing and releasing various of his tools (**Greyhound**, **HydraX**)
- **_Tom BMX_** - For developing and releasing **FF Extractor**
