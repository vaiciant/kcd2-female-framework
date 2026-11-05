# KCD2 Female Framework: developer guide

How the framework works inside, for mod makers who need more than [MODDING.md](MODDING.md).

| | |
|---|---|
| Name | KCD2 Female Framework |
| `modid` | `kcd_female_framework` |
| Prefix of table rows, items and components | `ml_ff_` |
| Prefix of console commands | `ml_ff_` |
| Lua global | `FemaleCore` |
| Game | Kingdom Come: Deliverance II 1.5.x, tested on 1.5.6 |
| License | Free for any use, with a credit: see [LICENSE](LICENSE) |

The `modid` has no digit, because the game allows only lowercase letters and underscores.

## Contents

1. [What it does](#1-what-it-does)
2. [Why it is built this way](#2-why-it-is-built-this-way)
3. [Load order](#3-load-order)
4. [How a look is put on](#4-how-a-look-is-put-on)
5. [Lua API](#5-lua-api)
6. [Skald](#6-skald)
7. [Clothing](#7-clothing)
8. [Coexistence and removal](#8-coexistence-and-removal)
9. [Known limits](#9-known-limits)
10. [Building from source](#10-building-from-source)

## 1. What it does

It gives the player a woman's head, body, hair and clothes, while keeping combat and riding.

| It contains | It does not contain |
|---|---|
| 55 looks: 50 generic women's faces and 5 named women of the story | Jobs, wages, origins, reputation or any gameplay loop |
| Women's meshes fitted to the male skeleton | New animations |
| Copies of the 315 women's garments, which a male soul can wear | A woman's voice: the voice stays Henry's |
| The clothing rules: what can be worn with what | A moving mouth on women's heads |
| 7 hair styles in up to 9 colors, and no beards | A way back to Henry, for now |
| Its looks on Henry and on the playable character of KCD2 Life | A character of its own |

## 2. Why it is built this way

### 2.1 Why the character is a man wearing a woman's parts

The obvious route is a real female player. It does not work:

- `PlayerFemale.lua` exists, with its own skeleton and animation database, but nothing can select it. `SwitchPlayer` takes only a `PlayerId`, and `player.xml` has no class column.
- The female skeleton has no combat or riding animations.
- The game looks for each piece only in the component tree of the soul's gender, `Male` or `Female`. A male soul cannot equip an `F_*` item.

So the character stays a male soul on the male skeleton, and every woman's piece is copied into the `Male` tree under the `ml_ff_` prefix. Combat and riding work without any extra animation.

### 2.2 The mesh pipeline

A woman's mesh on male bones comes out short and deformed, because the engine moves a mesh relative to the rest pose of its own skeleton. The tools rewrite the game's `.skin` files with plain Python. They need no editor and no engine.

| Problem | What the tools do |
|---|---|
| Binary format | Read the chunk table of the `.skin` format (`CrCh`, version `0x746`), and write meshes, streams, bones, morphs and physics chunks back |
| Different proportions | Move each vertex, through its bone weights, by what its bones move from one skeleton to the other. Positions only: the hands have other axes in each skeleton but point the same way. Only the fingers are straightened |
| Seeing inside the head in first person | Bit 0 of the alpha of the vertex color is the `FirstPersonView` hiding group. The mask is copied from Henry's head by UV, because heads share their UV map |
| Clothes removing the whole body | The body is split into hands, arms, feet, legs and torso, because each garment removes only its own part |
| Skirts on a wide male stance | The hem opens, and the skirt is weighted to follow the thighs. Cloth simulation is removed |
| Helmets too high on a smaller head | A morph, `#ml_ff_head`, on the men's headgear meshes. Only a woman's head turns it on, so for everyone else they behave as the original |
| Hoods too wide on a dress | A second morph, `#ml_ff_dress_fit`, which only the dress turns on. Morphs are written in chunk `0x2002`, whose layout was checked against 146 game meshes |

### 2.3 Failures worth knowing about

| Failure | Cause | State |
|---|---|---|
| Invalid write at `WHGame.dll+0x20F574F` on putting on a woman's body | The split kept the morph chunk, which indexes the whole mesh, so a morph pointed past the end of a part | Fixed: the parts are written without morphs, and keep their physics shapes |
| Crash when a beard is built on a woman's head | Women's heads have no beard meshes | Avoided: the framework never tries a beard on one, and a beard override keeps the game's barber screen from showing one |
| `D3D12 Device Removed`, `DeviceStatus=PageFault`, once, entering the barber screen | Unknown. The head and the table were ruled out | Not seen again, and not fixed |

## 3. Load order

Your mod needs the framework active. There is no official way to declare a dependency, so check at run time:

```lua
-- In your OnGameplayStarted handler, never at file load: the load order is not guaranteed.
if not (FemaleCore and FemaleCore.LOADED) then
	System.LogAlways("[MYMOD] KCD2 Female Framework is missing")
	return
end
```

With a `mod_order.txt`, only the mods listed load, in that order. Without it, Steam mods load first in arbitrary order, then the `Mods` folder alphabetically. Some mod managers rewrite the file at launch. Hence the run-time check.

## 4. How a look is put on

1. **The token.** Lua puts a token in Henry's inventory for a moment: `ml_ff_set_N` for look `N`, or `ml_ff_reset` to turn every look off.
2. **The overrides.** The module `ml_ff_face`, in the framework's Skald project, hears the token. Each look has a state, `chosen_N`, and two `BodyPartOverride` nodes, head and body, on Henry's soul. The first look also turns on the state `woman`, her underwear and the clothing rules.
3. **The rebuild.** The model only shows the overrides after it rebuilds. The native `Barber` object forces it: two real hair changes, and back with `Revert`. A woman has no beard to change.
4. **The hair.** `Barber:Commit` puts her hair on the soul, where the woman's haircut at the barber and the framework's commands can change it. `Commit` also keeps in the soul the head that is shown, so on the first change her hair goes on while Henry's head still shows.
5. **Saving.** The states live in the project, so every map and every save keeps them. After a load, Lua puts `ml_ff_ask` in Henry's inventory, and Skald answers with as many `ml_ff_answer` tokens as the id of the look that is on. Lua reads them, takes them away, and rebuilds the model. Nothing stays in the inventory.
6. **The black screen.** While the look changes, the HUD fades to black with a line of text (`SetFaderState` and `SetNarrativeSubtitles`), and the `player` action map is locked. Every call takes `noScreen`, which leaves the screen as it is.

The playable character of KCD2 Life, the soul `ml_player`, gets the same nodes with `new_` in front of their names. See [section 5.4](#54-the-character-of-kcd2-life).

## 5. Lua API

All mods share one Lua state, so a call is a plain function call. A look is its name, like `"woman_czech_2"`, or its id, like `5`. Ids never change, and they are shared with KCD2 Male Framework: the ids of the women are not one after another.

### 5.1 State

| Function or value | Returns |
|---|---|
| `FemaleCore.LOADED` | `true` once the framework has loaded |
| `FemaleCore.API` | An integer, raised when the API changes |
| `FemaleCore.IsWoman()` | `true` if Henry is a woman |
| `FemaleCore.Current()` | The id of Henry's look, or `0` while he is a man |
| `FemaleCore.OtherCharacter` | A function your mod sets when it plays a character of its own. While it returns `true`, the commands do nothing |

### 5.2 Looks

| Function | Returns |
|---|---|
| `FemaleCore.ListLooks()` | Every look, in menu order. `FemaleCore.ListLooks(FemaleCore.MAN)` returns none |
| `FemaleCore.GetLook(look)` | A look table, or `nil` |
| `FemaleCore.FindLook(name)` | The same, by name only |

A look table has `id`, `name`, `ethnicity` (`"czech"`, `"hungarian"`, `"romani"`, or `nil` for a named character's face), `age` (`"young"` or `"old"`), `villager` (`false` for a named character's face), `soul` (the GUID of a model with that look, to show it in a selector), and `style` and `color`, the hair it starts with.

### 5.3 Changing Henry

| Function | What it does |
|---|---|
| `FemaleCore.BecomeWoman(look, noScreen)` | Henry becomes a woman, with that look or the first one |
| `FemaleCore.SetLook(look, noScreen)` | Changes her head and body. Her hair stays |
| `FemaleCore.SetRandomLook(noScreen)` | Her head and body of a look at random among all but hers, and the hair it starts with. Returns that look, or `nil` |
| `FemaleCore.SetHair(style, color)` | Style 1 to 7, and a color by number, 1 to 9, or by name. Style 3 has only the first six colors |
| `FemaleCore.Refresh()` | Rebuilds the model, for when the look does not show |
| `FemaleCore.Henry()` | Not possible yet: it only says so, in the middle of the screen |
| `FemaleCore.Hair()` | Her style and color, and `true` if the framework knows them. After a load it does not, and returns the hair her look starts with |

`FemaleCore.HAIR_COLORS` lists the colors by name, and `FemaleCore.HAIR_STYLES` how many each style has. `BecomeWoman`, `SetLook` and `SetHair` return `true` if they started the change.

### 5.4 The character of KCD2 Life

KCD2 Life keeps its character, `SwitchPlayer` and its soul `ml_player`, and only calls the framework. A mod that switches to that same soul can do the same:

| When | Call |
|---|---|
| Before the switch, with Henry in use | `FemaleCore.ChooseNewCharacter(look)`: Henry gets `ml_ff_look_N`, the token of that look |
| When the switch ends | The mod's own Skald project gives Henry the token `FemaleCore.NEW_STARTED_TOKEN`, and the look turns on |
| Once the new character is in use | `FemaleCore.ShowNewCharacter(look, style, color, after)`: her hair, and the rebuild. `after` runs at the end |
| After every load and every map | `FemaleCore.UseNewCharacter(id)`, with the look if she is a woman and `0` if not, and then `FemaleCore.Refresh()` |
| Before the switch, if you like | `FemaleCore.GiveFreeHaircut()`: her next woman's haircut at a barber is free, so she can choose her hair |

`SwitchPlayer` does not show what was turned on before it, so the look waits for the token of the end of the switch.

### 5.5 Clothing

| Function or value | Returns |
|---|---|
| `FemaleCore.CopyOf(class)` | The GUID of the copy of a woman's item of the game, or `nil` |
| `FemaleCore.CLOTHES` | The whole table: each item of the game, and its copy |

## 6. Skald

### 6.1 Rules

- Each mod has its own Skald project, `Quests/<modid>.xml`. Edges do not cross projects, but tokens in Henry's inventory do: two projects hear the same token.
- Do not edit vanilla quest files. Add your own project, and give roles to NPCs with STORM (`addRole`). Your dialog then joins the NPC's menu.
- Lua talks to Skald with a token in Henry's inventory. Skald talks to Lua with `CreatePlayerReward`, and Lua reads the item.
- During the session of a `SwitchPlayer`, Skald does not see the new character's inventory. Give your tokens to Henry before the switch.
- A bad node can take down the whole graph without an error. Add nodes in small steps and test each one.
- `Variables.SetGlobal` is lost when the region changes, so publish variables again on a tick.

### 6.2 Tokens

| Token | Direction | Meaning |
|---|---|---|
| `ml_ff_set_N` | Lua to Skald | Look `N` on Henry |
| `ml_ff_reset` | Lua to Skald | Every look of Henry off |
| `ml_ff_ask` and `ml_ff_answer` | Lua to Skald, and back | The look in use, after a load: as many answers as its id |
| `ml_ff_look_N` | Lua to Skald | Look `N` for the character of KCD2 Life, before the switch |
| `ml_ff_new_started` | Another Skald project to this one | The switch to the character of KCD2 Life has ended |
| `ml_ff_henry_stripped_*` | Skald to Lua | A garment came off. Lua shows why |
| `ml_ff_free_haircut` | Lua to Skald | Her next woman's haircut at a barber is free |

The women's garments give a tagged effect while worn: `200` a dress, `201` women's shoes, `202` women's headwear. Skald reads them with `BuffTagCheck`.

### 6.3 Listening to a token

`ItemDescriptorTrigger` only reads, so your project can watch a token of the framework too:

```xml
<ObjectProperties Name="henry" PositionY="0" PositionX="-900" DeclaringType="wh::rpgmodule::I_Soul">
	<Asset Name="I_Soul" Alias="henry" />
</ObjectProperties>
<State Name="always_on" PositionY="-150" PositionX="-900" TypeT="bool">
	<Constant Name="DefaultValue" Value="true" />
</State>
<Function Name="descriptor" PositionY="0" PositionX="-600" MethodName="wh::entitymodule::CreateItemClassDescriptor" DeclaringType="wh::entitymodule">
	<Constant Name="ItemClass" Value="GUID OF THE TOKEN" />
	<Constant Name="Amount" Value="1" />
</Function>
<ItemDescriptorTrigger Name="token" PositionY="0" PositionX="-300">
	<Edge From="henry.Inventory" To="Inventory" />
	<Edge From="descriptor.ItemDescriptor" To="ItemDescriptor" />
	<Edge From="always_on.State" To="IsActive" />
</ItemDescriptorTrigger>
```

Declare Henry's soul in the `Assets` of your module:

```xml
<Assets>
	<SoulAsset Name="henry" SharedSoulGuids="4c2dcffb-dea1-6263-72d7-b39f4db2d8b5" />
</Assets>
```

### 6.4 The barber

The game's barber screen reads `rpg/barber_option`, one list for everyone with no column for gender. A mod can only add rows, so a woman's hair there would show to every man too. The framework's module `ml_ff_barber` adds a dialog instead, `ml_ff_barber_dialog`, to every NPC with the `BARBER` role, and it takes the place of the game's haircut:

- It uses the game's own line, `ui_barber_di_seq5_3vfx`, *Give me a haircut*.
- The framework ships the game's `Quests/Final/Barbora/open_world/barber/barber/barber_dialog/barber_dialogue.xml`, with `AND gvar('ml_ff_woman') != 1 AND gvar('ml_mf_model') != 1` on its two haircut options: KCD2 Male Framework has the same kind of talk for a man with a look, and ships the same copy. A file of a mod with the same path replaces the game's. The tools copy it from your game, so it is not in the repository.
- It shows while `gvar('ml_ff_woman') == 1`. Lua sets it every second, from `FemaleCore.IsWoman()` or the new character of `FemaleCore.UseNewCharacter`.
- The price goes to the `Payment_seq_ff_cut` port: 50 groschen, or 0 after `ml_ff_free_haircut`. The coins move from the player to the barber when she accepts.
- With Realish Economy, the game's barber asks 5 groschen, and so does hers. On each load, `female_core.lua` checks for one of that mod's files with `System.IsFileExist`, and gives Henry or the new character of KCD2 Life the token `ml_ff_price_low` or `ml_ff_price_game` for a moment. The state `low_price` keeps the price.
- Each style or color calls `FemaleCore.Barber.Style(n)` or `Color(n)`, which try the hair on a `Barber` session. `Accept()` commits it and `Cancel()`, or leaving the talk, reverts it.
- It keeps the camera of a normal talk, on her: no line has a camera command, a mood or a prop, as in the game's barber greeting. The barber's `barber` mood and props, made for the haircut screen with the player in the chair, moved the camera to the wall.

The beard override `woman_beard`, on while she is a woman, keeps any beard off her head all the same.

## 7. Clothing

A shop or another mod hands out the `F_*` item. When it reaches a woman's inventory, the framework swaps it for its copy in the `Male` tree, with the same health. Shops keep their items. The check runs once a second.

The copies cover the women's garments of these types, and the rules treat them by group:

| Group | `ArmorType` | What the rule does |
|---|---|---|
| Dress | `F_SimpleDress`, `F_Smock` | Takes off men's clothes from the torso, the hands and the legs |
| Shoes | `F_Shoes` | Come off with men's clothes on the chest |
| Headwear | `F_Hood`, `F_HoodOpen`, `F_Bonnet`, `F_CapAndWimple`, `F_Hat`, `F_Veil`, `F_VeilAndWimple` | Comes off with men's clothes on the chest |

Garments of other types, and garments of other mods, are not converted. With a man of KCD2 Life, the rules take off any copy of a woman's garment.

## 8. Coexistence and removal

| Situation | What happens |
|---|---|
| The framework alone, in the game's campaign | Looks go on Henry's soul, with no switch. His voice, name and story stay |
| With KCD2 Male Framework | Before Henry becomes a woman, his man's face comes off. While he is a woman, its commands do nothing |
| With KCD2 Life | Its character gets the looks, and the commands do nothing with it |
| Removing the mod, with a save from before `ml_ff_female` | Nothing changes |
| Removing the mod, with a save where Henry is a woman | Not supported |
| Back to Henry from a woman | Not possible yet |

The framework adds no entity classes to the save. A save that holds an entity of a class that a mod defined does not load without that mod.

## 9. Known limits

- A woman cannot go back to Henry yet.
- The framework replaces the game's barber dialog file. A mod that replaces the same file clashes with it.
- The adjusted headgear meshes live at the game's paths and replace its own. Another mod that replaces the same mesh wins or loses by load order, and if it wins, the helmet sits high on a woman.
- After a game update, the meshes must be rebuilt if their sources changed.
- Women's mouths do not move: the fix broke the face, so it was dropped.
- In the inventory preview, the underwear sometimes shows only after reopening the inventory.
- Clothes from other mods are not converted.

## 10. Building from source

The meshes derive from the game's files, so they are not in the repository. With Python 3.11 or later and your own copy of the game, from the root of the repository:

```bash
python -I tools/extract_game.py
python -I -X utf8 tools/generate_models.py
python -I -X utf8 mod/kcd_female_framework/tools/generate_women.py
python -I tools/install_mod.py mod/kcd_female_framework
```

- `tools/extract_game.py` copies the game tables that the tools read into `game_files/`, once, and again after a game update.
- `tools/generate_models.py` reads `looks.toml`, adds the faces of the game that fit, and writes the Skald graph, the tokens and the Lua data. A face of another mod goes in by hand, as an entry of `looks.toml`.
- `tools/generate_women.py` writes the meshes fitted to the male skeleton, their components, the copies of the garments and the headgear morphs.
- `tools/install_mod.py` packs the mod and copies it to the game. The game must be closed.

Set `KCD2_GAME` to the game's folder if it is not in the default Steam library.

The license does not cover the meshes the tools produce: they derive from Warhorse's files.
