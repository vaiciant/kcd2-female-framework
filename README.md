# KCD2 Female Framework (`kcd_female_framework`)

**Works on its own or with [KCD2 Male Framework](https://github.com/vaiciant/kcd2-male-framework). Required by [KCD2 Life](https://github.com/vaiciant/kcd2-life).**

A library for *Kingdom Come: Deliverance II* (PC, game version 1.5) that makes playable women possible. The player gets a woman's head, body and hair, women's clothes that fit, and keeps fighting and riding like any player. One console command turns Henry into a woman in any game, and other mods can build on it. Any mod may use it, with a credit as the only condition.

> **Back to Henry in the same save.** `ml_ff_female` turns Henry himself into a woman, and `ml_ff_henry` turns her back
> into him. Removing the mod from a save where he was ever a woman is not supported, so keep a save from before if you
> may want to.

## How it works

The game only knows how to play a man. Combat, riding, alchemy and the rest expect the male player and its skeleton, and nothing can select the female player class. A mod that swaps in a woman's model breaks them.

So the player stays a male soul on the male skeleton, and wears a woman's parts:

- **Copies in the male tree.** The game looks for each piece only in the component tree of the soul's gender. Every woman's piece, from heads and bodies to 315 garments, is copied into the `Male` tree under the `ml_ff_` prefix.
- **Meshes fitted to the male skeleton.** A woman's mesh on male bones comes out short and deformed. The tools move each vertex, through its bone weights, by what its bones move from one skeleton to the other, and straighten the fingers. Skirts open over the wider stance.
- **A body in five parts.** Torso, arms, hands, legs and feet, so each garment hides only the part it covers.
- **First-person heads.** Each head hides in first person through the `FirstPersonView` bit of its vertex colors, like Henry's.
- **Headgear.** 146 men's hats, hoods and helmets get a morph that only a woman's head turns on. For everyone else they are unchanged.
- **The look.** Head, body and underwear are `BodyPartOverride` nodes in the framework's Skald project, on Henry's soul. Lua picks a look with a token in Henry's inventory, and the native `Barber` object puts on her hair and forces the model to rebuild. The states live in the project, so every map and every save keeps them.
- **Back to Henry.** `Barber:Commit` keeps in the soul the head that is shown, but after a woman's head it does not give Henry his own back. So his head, his body and his underwear go on as one more look of the framework, and stay on while he is a man. On each load the framework also asks whether her state is still on with a man, which kept her shift and her beard without a mesh on him, and turns it off. A look of KCD2 Male Framework takes their place, and its `ml_mf_henry` puts them back.
- **Clothes.** A woman's garment that reaches her inventory turns into its copy, with the same condition. Once a second, Skald checks what she wears: a dress takes off men's clothes from the torso, hands and legs, and men's clothes on the chest take off women's shoes and headwear. A notice says what came off.
- **The barber.** The game's barber screen reads one list for everyone, `barber_option.xml`, with no column for gender, and a mod can only add rows to it. So while she is a woman, the barber's haircut is the framework's own dialog, `ml_ff_barber`, with the same line, *Give me a haircut*. The game's haircut is hidden: the framework ships the game's `barber_dialogue.xml` with `gvar('ml_ff_woman') != 1 AND gvar('ml_mf_model') != 1` added to its two haircut options, the same copy as KCD2 Male Framework. Her dialog keeps the camera of a normal talk, on her, so each hair shows as she picks it. Each choice calls `TryHair` on a `Barber` session, *I'll take this one* commits it, and leaving the talk reverts it. A beard override, the empty `m_beard_00`, keeps her clean shaven all the same.
- **The game's scenes.** Five scenes of the game put Henry's own parts on the player with overrides of their own: wet, wounded and bandaged in the prologue in Trosecko, and wet at the Cumans' swimming contest. An override of a quest wins over hers, so she showed his wounded head, his body and his breeches there. While she is a woman, the framework keeps a buff with no effect and no icon on her, `ml_ff_woman`, and ships the game's files of those five scenes with one more condition on each override of the player: no `ml_ff_woman`. She keeps her head, her body and her shift, with no wounds or bandages, and Henry as a man sees the scenes as they were. KCD2 Male Framework ships the same files, which leave Henry's head and body off a man with a face of its own too. The pillory in Troskowitz dresses the player in Henry's hose and boots with an outfit of its own, `PlayerOutfitOverride`, and the outfit goes on the model without her overrides: his body showed under her head until a load, which rebuilt her right. Its copy keeps the outfit and gives the player a token, `ml_scene_rebuild`, when it goes on and when it comes off, and the framework rebuilds her look. She wears the hose and boots, as the cutscene shows her. KCD2 Male Framework ships the same copy and the same token, for a man with a face of its own. The tools copy the files from your game, so they are not in the repository.
- **Henry's doubles in the cutscenes.** In a cutscene of the engine, Henry is an `AnimChar` of the cutscene's layer, and the soul in its `Properties.Body.guidBodyPresetId` gives its look. Most use the player's soul, so they show her. 27 use a soul of their own that the game gives Henry's head: wet at the lake, wounded when he falls, his arm bandaged, dreaming, whipped, naked in the romances. While she is a woman, the framework gives those the player's soul: it wraps `AnimChar.SetFromProperties`, which the game looks up when a layer makes its doubles, and once a second it checks the doubles that are there already. Henry as a man sees them as always. KCD2 Male Framework does the same for a man with a look of its own, and the two agree.

## Features

| Feature | What it does |
|---|---|
| Every face of the game | All 50 generic women's faces, young and old, and 5 named women of the story whose faces fit |
| Women's clothes | The 315 women's garments of the shops, worn with their own condition. Shops keep the game's items |
| Fitted gear | The men's armour and clothes of the game, 948 items with the story and DLC armour, refitted to her body by Cytyryz. They swap to their fitted copies as her dresses do: [FITTED_GEAR.md](mod/kcd_female_framework/FITTED_GEAR.md) |
| Hair | 7 hair styles of the time and up to 9 colors, and by command the hairs of four women of the story: Katherine, Rose, Miriam and the mother. Never a beard: a beard on a woman's head crashes the game. Braids keep still: the framework leaves out the bones that swing them |
| Her haircut | At any barber of the game, her haircut is a woman's, in place of the game's. The style and the color are chosen in the talk and tried on at once, for the game's price: 50 groschen, or 5 with Realish Economy |
| Combat and riding | They work, because the character is still the game's player |
| A new character of another mod | The same look on the playable character of KCD2 Life |
| Back to Henry | `ml_ff_henry` gives him his head, body and hair back, with no beard, in the same save. Her clothes come off, with a notice |

## Console commands

| Command | What it does |
|---|---|
| `ml_ff_looks` | Lists every face: its name, its people, its age, its id and the characters of the game who wear it. [LOOKS.md](mod/kcd_female_framework/LOOKS.md) has the same list, and who wears what |
| `ml_ff_female [name]` | Turns Henry into a woman, with that look or the first one. He keeps his story, his skills and his things |
| `ml_ff_look <name> [hair]` | Changes the head and the body to that look, like `ml_ff_look woman_czech_2` or `ml_ff_look ml_ff_head_katherine`, and the hair if given, like `ml_ff_look woman_czech_2 5 blonde`. From Henry, it turns him into a woman with it |
| `ml_ff_random` | Gives her a look at random among all, with the hair it starts with. From Henry, it turns him into a woman with it |
| `ml_ff_hair <hair>` | Changes her hair, like `ml_ff_hair 2 blonde` or `ml_ff_hair f_hair_002_blonde`, or to the hair of `katherine`, `rose`, `mother` or `miriam`, which the barber does not have |
| `ml_ff_henry` | Turns her back into Henry: his head, body and hair, with no beard |
| `ml_ff_refresh` | Rebuilds the model, for when her look does not show |
| `ml_ff_start [look]` | The next game that starts or loads begins as a woman with that look: type it in the main menu before New Game |

While the model changes, the screen goes black for a few seconds. A last `true` leaves it as it is. Typed with the inventory, the map or a menu open, a command waits until you close it. [COMMANDS.md](mod/kcd_female_framework/COMMANDS.md) has every command, with its Lua call.

## For modders

One call turns Henry into a woman: `ml_ff_female` in the console, or `FemaleCore.BecomeWoman()` from your mod. [MODDING.md](mod/kcd_female_framework/MODDING.md) shows how, in a few lines. The [developer guide](mod/kcd_female_framework/FRAMEWORK_DEVELOPER_GUIDE.md) explains the API, the Skald tokens and how each piece works.

```lua
-- In your OnGameplayStarted handler: the load order is not guaranteed.
if FemaleCore and FemaleCore.LOADED then
	for _, look in ipairs(FemaleCore.ListLooks()) do
		System.LogAlways(look.name)
	end
end
```

## Compatibility and known limits

- **Back to Henry** gives him his usual hair and no beard, not the ones he had before.
- **With KCD2 Male Framework,** use 0.2.0 or later of both: from then on it takes Henry's head off before its own looks and puts it back with `ml_mf_henry`. From 0.4.0 of both, a woman goes straight to one of its faces with `ml_mf_look`, and one of its faces straight to a woman with `ml_ff_female`, with no `ml_ff_henry` in between.
- **The barber's talk.** The framework replaces the game's `barber_dialogue.xml`, with its haircut hidden for her, and for a man with a look of KCD2 Male Framework, which ships the same copy. A mod that replaces the same file clashes with it, and the one that loads last wins.
- **The game's scenes.** The six scene files replace the game's, like the barber's talk, and KCD2 Male Framework ships the same ones: a mod that replaces the same files clashes with them.
- **Removing it** from a save where Henry is or was a woman is not supported: after `ml_ff_henry` his head comes from the framework. Keep a save from before `ml_ff_female`.
- **Headgear meshes.** The 146 adjusted meshes replace the game's at their own paths. A mod that replaces the same meshes wins or loses by load order, and if it wins, the helmet sits high on her.
- **Her face moves.** She says Henry's lines, and her lips, eyes and brows move with them, as a man's do.
- **Game updates.** The meshes must be rebuilt if their sources change.

## Installing

Subscribe on the Steam Workshop, or download it from Nexus Mods and put its folder in the game's `Mods` folder. No launch options and no tools: the meshes come ready in the mod.

## Building from source

The meshes derive from the game's files, so they are not in this repository. You build them from your own copy of the game, with Python 3.11 or later. From the root of the repository:

```bash
python -I tools/extract_game.py
python -I -X utf8 tools/generate_models.py
python -I -X utf8 mod/kcd_female_framework/tools/generate_women.py
python -I tools/install_mod.py mod/kcd_female_framework
```

| Tool | What it writes |
|---|---|
| `tools/extract_game.py` | The game tables that the tools read, from your game into `game_files/`. Once, and again after a game update |
| `tools/generate_models.py` | The catalog of looks in `looks.toml` and `LOOKS.md`, the Skald graph, the tokens and the Lua data of both frameworks, and the game's barber dialog with its haircut for men only |
| `tools/generate_women.py` | The meshes fitted to the male skeleton, their components, the copies of the women's garments and the headgear morphs |
| `tools/install_mod.py` | Packs the mod and copies it to the game. The game must be closed |

Set `KCD2_GAME` to the game's folder if it is not in the default Steam library.

## Roadmap to 1.0.0

Plans, not promises.

- ~~**Speech:** a mouth that moves with the lines, as a man's does.~~ Done in 0.2.0.
- ~~**A way back to Henry,** with his own face, in the same save.~~ Done in 0.2.0.
- **Clothes from other mods:** tested with clothing mods, and a clear pipeline to fit their garments to her, as the tools do for the game's. Loose jackets and cloaks over her body go with it.

## License

Free for any use, also in closed work. The only condition: credit KCD2 Female Framework where people can see it, like a line in your mod's description or credits. Asking for donations or Patreon support is fine, as long as nothing in your mod is only for those who pay: Warhorse's rules do not allow selling KCD2 mods. You do not need to include the license or publish your source. It does not cover the game's files or anything derived from them, such as the meshes. See [LICENSE](LICENSE).
