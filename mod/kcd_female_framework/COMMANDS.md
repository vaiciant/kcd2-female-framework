# KCD2 Female Framework: console commands

Every command of the framework, and the Lua call that does the same from another mod. Open the console with the key under Esc, type the command and press Enter. They need no launch options.

A look is its name or its id: `woman_czech_2` or `4`. `ml_ff_looks` lists them all.

**In the game only.** The commands that change the model wait for the game itself: typed with the inventory, the map or a menu open, the change starts once you close it.

| Command | What it does | From Lua |
|---|---|---|
| `ml_ff_looks` | Writes every look in the console: its name, its people, its age and its id | `FemaleCore.ListLooks()` |
| `ml_ff_female [look] [true]` | Turns Henry into a woman, with that look or the first one. He keeps his story, his skills and his things | `FemaleCore.BecomeWoman(look, noScreen)` |
| `ml_ff_look <look> [true]` | Changes her head and her body to that look. Her hair stays | `FemaleCore.SetLook(look, noScreen)` |
| `ml_ff_random [true]` | Gives her a look at random among all but hers, with the hair it starts with | `FemaleCore.SetRandomLook(noScreen)` |
| `ml_ff_hair <style> <color>` | Gives her a hair style, from 1 to 7, and a color, by name or by number from 1 to 9, like `ml_ff_hair 2 blonde` | `FemaleCore.SetHair(style, color)` |
| `ml_ff_henry` | Going back to Henry is not possible yet: it only says so, in the middle of the screen | `FemaleCore.Henry()` |
| `ml_ff_refresh` | Rebuilds the model, for when her look does not show | `FemaleCore.Refresh()` |

**Colors:** `dark_brown`, `black`, `light_brown`, `blonde`, `ginger`, `dark_ginger`, `dark_grey`, `grey` and `white`, numbered from 1 to 9 in that order. Style 3 has only the first six.

## The black screen

While the model changes, the screen goes black for a few seconds, with a line that says so, and the character cannot move. A last `true` leaves the screen as it is:

```text
ml_ff_look woman_czech_2 true
```

From Lua it is the last argument, `noScreen`. Left out, it is `false`, and the screen goes black. A mod that covers the screen on its own, as KCD2 Life does, passes `true`.

## Going back to Henry

**Not possible yet.** A woman cannot become Henry again: in that save she stays a woman. `ml_ff_henry` changes nothing, and says so in the middle of the screen.

Keep a save from before `ml_ff_female` to play on with Henry.

## When the commands do nothing

- **Another character in use.** A mod that plays its own character instead of Henry, as KCD2 Life does, turns them off.
- **Not a woman yet.** `ml_ff_look`, `ml_ff_random` and `ml_ff_hair` need `ml_ff_female` first.

Each command writes what it did in the console and in `kcd.log`, in lines that start with `[ML_FF]`.

## Limits

- **No way back to Henry** yet, as above.
- **At the barber,** *Give me a haircut* gives her a woman's haircut. She never gets a beard.
- **Removing the mod** from a save where Henry is a woman is not supported. Keep a save from before `ml_ff_female`.
- **For a moment after a load,** the framework asks for the look in use, and two small tokens may show in the inventory for a second.

## With KCD2 Male Framework

After `ml_ff_female`, the `ml_mf_` commands of [KCD2 Male Framework](https://github.com/vaiciant/kcd2-male-framework/blob/main/mod/kcd_male_framework/COMMANDS.md) do nothing, so they do not put a man's face on her.
