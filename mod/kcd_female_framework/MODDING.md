# Using KCD2 Female Framework in your mod

This is the short guide: how to turn Henry into a woman in your story or your mod, with one command and nothing to set up. It works in the game with no other mod. The [developer guide](FRAMEWORK_DEVELOPER_GUIDE.md) explains how it works inside.

## One command

From the console:

```text
ml_ff_female
ml_ff_female woman_czech_2
```

From the Lua of your mod:

```lua
FemaleCore.BecomeWoman()                  -- the first look
FemaleCore.BecomeWoman("woman_czech_2")   -- that look
```

That is all. The framework does the rest by itself:

- Henry keeps playing as himself: his story, his skills and his things. The game is the same, with a woman in his place.
- She gets the head, the body and the hair of the look.
- Women's clothes that reach her inventory turn into copies that fit her, and she can wear them.
- Hats, hoods and helmets sit right on her head.
- Her face hides in first-person view.
- `ml_ff_hair` changes her hair: styles and colors, and never a beard. At any barber of the game, her haircut is a woman's.
- Combat, riding, saving and loading work as for any player.

It takes a few seconds, under a black screen with a line that says so. If your mod covers the screen on its own, pass `true` as the last argument to leave it as it is: `FemaleCore.BecomeWoman("woman_czech_2", true)`. Every command is in [COMMANDS.md](COMMANDS.md).

She keeps Henry's voice and lines, and the story still calls her Henry. A mod that wants a different person, with her own name and things, starts a new character, as KCD2 Life does (see "If your mod plays its own character").

## Back to Henry

```text
ml_ff_henry
```

```lua
FemaleCore.Henry()
```

She becomes Henry again, in the same save: his head and body, his usual hair and no beard. Her clothes come off, with a notice. It takes the same `noScreen` as the other calls. His head and body stay on as a look of the framework while he is a man, because after a woman's head, `Barber:Commit` did not give him his own back.

Removing the framework from a save where Henry was ever a woman is not supported. If your mod may be removed with it, make it save before `BecomeWoman`, or tell your players to.

## Changing her look

```text
ml_ff_look woman_romani_3
```

```lua
FemaleCore.SetLook("woman_romani_3")
```

It changes the head and the body. Her hair stays until she visits a barber.

`ml_ff_random`, or `FemaleCore.SetRandomLook()`, gives her a look at random among all but hers, with the hair it starts with, and returns that look.

## Her hair

```text
ml_ff_hair 2 blonde
```

```lua
FemaleCore.SetHair(2, "blonde")
```

A style from 1 to 7 and a color, by name or by number. [COMMANDS.md](COMMANDS.md) lists the colors.

At any barber of the game, her haircut is a woman's, for the usual price, 50 groschen or 5 with Realish Economy: she picks the style and the color in the talk and sees each one before she takes it. It takes the place of the game's haircut at every NPC with the `BARBER` role, so your mod has nothing to do.

## The looks

`ml_ff_looks` writes every look in the console. Each one has a short name that never changes:

| Name | What it is |
|---|---|
| `woman_czech_1`, `woman_hungarian_1`, `woman_romani_1`… | A generic face of the game, by people and number |
| `ml_ff_head_katherine` and the like | The face of a named character of the story: it keeps its internal name |

From Lua:

```lua
for _, look in ipairs(FemaleCore.ListLooks(FemaleCore.WOMAN)) do
	-- look.id, look.name, look.ethnicity ("czech", "hungarian", "romani" or nil),
	-- look.age ("young" or "old"), look.villager (false for a named character's face)
end
```

Use `look.villager` and `look.age` to offer only the faces that suit your story, as KCD2 Life offers only young villagers.

## Adding faces

Every look is an entry of [`looks.toml`](looks.toml): the head of the game, the body, the hair, and its people. To add a face, even one from another mod:

1. Add an entry with the next `id` and the name of its head. Without `ethnicity`, it shows with its internal name.
2. Run `tools/generate_models.py` and then `tools/generate_women.py`, from the root of the repository. They write the rest: the model, the token, the copy of the head fitted to the player's skeleton, with its face poses.

The generator also adds by itself every face of the game that fits. It never changes an entry that is already there.

## Before you call it

**Check that the framework is there,** in your `OnGameplayStarted` handler, never when your file loads: the load order of mods is not fixed.

```lua
if not (FemaleCore and FemaleCore.LOADED) then
	System.LogAlways("[MYMOD] KCD2 Female Framework is missing")
	return
end
```

## If your mod plays its own character

The commands put the look on Henry's soul. If your mod switches to a character of its own, as KCD2 Life does, tell the framework, so its commands do nothing while that character is in use:

```lua
FemaleCore.OtherCharacter = function() return MyMod.IsOwnCharacter() end
```

The framework also puts a look on the playable character of KCD2 Life, its soul `ml_player`. KCD2 Life keeps the switch, `SwitchPlayer`, and only calls the framework:

| When | Call |
|---|---|
| Before the switch, with Henry in use | `FemaleCore.ChooseNewCharacter(look)`: Henry gets the token of that look |
| When the switch ends | Your Skald project gives Henry `FemaleCore.NEW_STARTED_TOKEN`, and the look turns on |
| Once the new character is in use | `FemaleCore.ShowNewCharacter(look, style, color, after)`: her hair, a style and a color or the look's, and the model rebuilds. `after` runs at the end |
| After every load and every map | `FemaleCore.Refresh()` |
| Before the switch, if her first haircut should be free | `FemaleCore.GiveFreeHaircut()`: her next woman's haircut at a barber costs nothing |

A mod that switches to that same soul can do the same.

After every load and every map, also say whether that character is a woman: `FemaleCore.UseNewCharacter(look)`, or `0` for a man. Her clothes then change for copies she can wear, as with Henry. `FemaleCore.CopyOf(class)` gives the copy of a woman's item, to dress her.

## With KCD2 Male Framework

They work alone or together. [KCD2 Male Framework](https://github.com/vaiciant/kcd2-male-framework) gives Henry another man's face with `ml_mf_look`, and `ml_mf_henry` brings his own back. While Henry is a woman, its commands do nothing, so they do not put a man's face on her. Use version 0.2.0 or later of both.

If your mod puts a head of its own on Henry after he was a woman, do as KCD2 Male Framework does:

```lua
FemaleCore.TakeOffHenry()   -- before your head goes on: the framework's look of Henry comes off
FemaleCore.KeepHenry()      -- when Henry gets his own face back: the framework puts its look of him on again
```

Both do nothing when they are not needed, so they are safe to call every time.

## Credit

Use it in any mod, closed or open, free or paid. The only condition is a credit where people can see it, like a line in your mod's description: "Uses KCD2 Female Framework". See [LICENSE](LICENSE).
