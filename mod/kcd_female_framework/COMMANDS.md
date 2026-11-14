# KCD2 Female Framework: console commands

Every command of the framework, and the Lua call that does the same from another mod. Open the console with the key under Esc, type the command and press Enter. They need no launch options.

A look is its name or its id: `woman_czech_2` or `4`. `ml_ff_looks` lists them all.

**In the game only.** The commands that change the model wait for the game itself: typed with the inventory, the map or a menu open, the change starts once you close it.

| Command | What it does | From Lua |
|---|---|---|
| `ml_ff_looks` | Writes every look in the console: its name, its people, its age, its id and the characters of the game with a name of their own who wear its face, as in [LOOKS.md](LOOKS.md) | `FemaleCore.ListLooks()` |
| `ml_ff_female [look] [hair] [true]` | Turns Henry into a woman, with that look or the first one, and with a hair if given, as `ml_ff_hair` takes it. He keeps his story, his skills and his things | `FemaleCore.BecomeWoman(look, noScreen, style, color)` |
| `ml_ff_look <look> [hair] [true]` | Changes her head and her body to that look. Her hair stays, unless a hair follows, as `ml_ff_hair` takes it: `ml_ff_look woman_czech_2 5 blonde`. [LOOKS.md](LOOKS.md) has this command for every character. From Henry, it turns him into a woman with that look, as `ml_ff_female` does | `FemaleCore.SetLook(look, noScreen, style, color)` |
| `ml_ff_random [true]` | Gives her a look at random among all but hers, with the hair it starts with. From Henry, it turns him into a woman with it | `FemaleCore.SetRandomLook(noScreen)` |
| `ml_ff_hair <hair>` | Gives her a hair style, from 1 to 7, and a color, by name or by number from 1 to 9, like `ml_ff_hair 2 blonde`. Also the game's name of one, like `ml_ff_hair f_hair_002_blonde`, or the hair of a woman of the story that the barber does not have: `katherine`, `rose`, `mother` or `miriam` | `FemaleCore.SetHair(style, color)` |
| `ml_ff_henry [true]` | Turns her back into Henry: his head, body and hair, with no beard. Her clothes come off, with a notice | `FemaleCore.Henry(noScreen, after)` |
| `ml_ff_refresh` | Rebuilds the model, for when her look does not show | `FemaleCore.Refresh()` |
| `ml_ff_start [look] [hair]` | The next game that starts or loads begins as a woman with that look, and with a hair if given, as `ml_ff_hair` takes it. It works in the main menu, before New Game. `none` cancels it; with nothing, it says which look waits | `FemaleCore.StartAs(look, style, color)` |

**Colors:** `dark_brown`, `black`, `light_brown`, `blonde`, `ginger`, `dark_ginger`, `dark_grey`, `grey` and `white`, numbered from 1 to 9 in that order. Style 3 has only the first six.

## Developer mode

`ml_developer` turns on the test commands of the framework until the game closes. KCD2 Life has the same command, and either one turns on both.

| Command | What it does |
|---|---|
| `ml_ff_npc_dress <name>` | Puts an item on the nearest woman NPC, within 10 m, by its name in the item table, as `wh_cheat_addItem` takes it: `ml_ff_npc_dress Cuirass03_m03_A5`, or its copy for her, `Cuirass03_m03_A5_ff`. It knows the fitted gear and the clothes other mods register with their names; any other name says it cannot be put on |
| `ml_ff_fitted_give [word] [copies]` | Gives the game's pieces of the fitted gear, refitted or not, which turn into her copies while she is a woman. A word gives only those whose name has it, like `ml_ff_fitted_give cuirass`. With `copies`, the copies themselves: a man gets the game's pieces back |

## Before the game starts

`ml_ff_start` chooses her look before you play, and works in the main menu too: open the console there, type it, and start a new game.

```text
ml_ff_start woman_czech_2
```

The game does not tell a new game from a loaded one, so the look goes on at the next start of the game, new or loaded, a few seconds after you have control, under the black screen. A new game begins with Godwin: the look waits for Henry's part, and for the end of the cutscene that starts it, so it goes on once he rides. It goes on once: `ml_ff_start none` cancels it before that. From Lua, `FemaleCore.StartAs(look)` does the same, and `FemaleCore.StartLook()` says which look waits.

## The black screen

While the model changes, the screen goes black for a few seconds, with a line that says so, and the character cannot move. A last `true` leaves the screen as it is:

```text
ml_ff_look woman_czech_2 true
```

From Lua it is the last argument, `noScreen`. Left out, it is `false`, and the screen goes black. A mod that covers the screen on its own, as KCD2 Life does, passes `true`.

## Going back to Henry

`ml_ff_henry` turns her back into Henry, in the same save, under the black screen. He gets his own head and body, his usual hair and no beard, not the ones he had before. Women's clothes come off, with a notice, as a man cannot wear them. `ml_ff_female` makes him a woman again at any time.

His head and body stay on as a look of the framework while he is a man. A look of KCD2 Male Framework 0.2.0 or later takes their place, and `ml_mf_henry` puts them back.

## When the commands do nothing

- **Another character in use.** A mod that plays its own character instead of Henry, as KCD2 Life does, turns them off.
- **Not a woman yet.** `ml_ff_hair` needs her first: `ml_ff_look`, `ml_ff_random` or `ml_ff_female`.

Each command writes what it did in the console and in `kcd.log`, in lines that start with `[ML_FF]`.

## Limits

- **At the barber,** *Give me a haircut* gives her a woman's haircut. She never gets a beard.
- **Removing the mod** from a save where Henry is or was a woman is not supported: after `ml_ff_henry`, his face comes from the framework. Keep a save from before `ml_ff_female`.
- **For a moment after a load,** the framework asks for the look in use, and two small tokens may show in the inventory for a second.

## With KCD2 Male Framework

Both ways go straight, with no `ml_ff_henry` in between. From a face of [KCD2 Male Framework](https://github.com/vaiciant/kcd2-male-framework/blob/main/mod/kcd_male_framework/COMMANDS.md), `ml_ff_female` takes it off and turns him into a woman. From a woman, its `ml_mf_look` and `ml_mf_random` turn her back into Henry with this framework and then put the face on: use 0.4.0 or later of this one. Its other commands do nothing while she is a woman.
