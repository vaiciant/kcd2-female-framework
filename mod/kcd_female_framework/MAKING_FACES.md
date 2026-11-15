# KCD2 Female Framework: faces from your mod

A face is a look: a head, a body, and the hair she starts with. Your mod can add faces of its own, next to the framework's, without changing the framework's files. Players use them like any other look: `ml_ff_look <name>`, and your mod can start the game with one (`RegisterStartCharacter`, in [MODDING.md](MODDING.md)).

This is not like clothes. A garment of your mod is a copy that she wears ([MAKING_CLOTHES.md](MAKING_CLOTHES.md)). A face changes Henry's head and body, and the save has to keep which face is on. So a face pack needs a few pieces of its own, and a tool writes them all from one file.

## What you write

A `faces.toml` at the root of your mod. [`examples/sample_faces/faces.toml`](examples/sample_faces/faces.toml) is a template with every field explained:

```toml
[pack]
id = "my_faces"            # the id of your mod
name = "My Faces"

[[face]]
name = "my_heroine"        # the name players type: ml_ff_look my_heroine
head = "ml_ff_head_016"    # a head of the framework
body = "ml_ff_body_tan_03" # a body of the framework
hair = 2                   # a style from 1 to 7
color = "ginger"           # and its color
```

- **Heads:** those the framework has, which [LOOKS.md](LOOKS.md) lists, or a head of your own (see "A head of your own" below).
- **Bodies:** those the framework has, the `ml_ff_body_*` of its tables.
- **Up to ten faces** in a pack.

## Running the tool

You need the framework's repository and Python 3.11 or later. From its root:

```bash
python -I -X utf8 mod/kcd_female_framework/tools/make_face_pack.py path/to/your_mod
```

It writes into your mod:

| File | What |
|---|---|
| `data/Libs/Tables/item/item__<id>.xml` | One token per face |
| `data/Quests/<id>.xml` and `data/Quests/<id>/<id>_faces.xml` | Your Skald project: each face turns on with its token and off with the framework's reset, puts its head and body on Henry, and tells the framework its id when asked |
| `data/Scripts/FemaleCore/Looks/<id>.lua` | Registers your faces with `FemaleCore.RegisterLooks` |
| `mod.manifest` | Only if your mod has none |

Run it again after every change of `faces.toml`. The framework does the rest: when one of your faces goes on, it makes Henry a woman, with her shift and the rules of her clothes, as with its own looks.

## A head of your own

A face can bring its own head instead of one of the framework's. Give its mesh and its material in place of `head`:

```toml
[[face]]
name = "my_heroine"
head_mesh = "source/my_head/my_head.skin"   # your head, in your mod
material = "source/my_head/my_head.mtl"     # its material
body = "ml_ff_body_tan_03"
hair = 2
color = "ginger"
```

The head is a woman's head as the game's are: on the game's female skeleton. The easiest start is a woman's head of the game, changed in your 3D tool. Next to `my_head.skin` go:

| File | What |
|---|---|
| `my_head_lod1.skin`, `my_head_lod2.skin` | Its LODs, the head from farther away |
| `my_head_poses.xml` | Its face poses. Without them, her face keeps still when she talks |

The player is Henry, on the male skeleton, so the tool fits your head to it, as the framework fits the game's women's heads, and hides it in first-person view. It writes the head into `data/Objects/characters/humans/<id>/head/<face>/` and its node into `data/Libs/Tables/Character/CharacterComponent__<id>.xml`. Your source files stay where they are: keep them out of `data/` if you do not want them packed with your mod. A woman never has a beard, so the head needs none.

- **Textures:** those that the material names next to it, as `File="./my_head_diff.tif"`, go with the head, with their mipmaps (`.dds`, `.dds.1`...). Those it names by their full path in your mod stay where they are.

[`examples/sample_own_head`](examples/sample_own_head) is a face with a head of its own. Its head is a stand-in: its `stand_in.py` copies a woman's head of the game into `source/`, where yours would go, so you can try the tool before you have one.

## The ids

The save keeps a face by a number, shared by both frameworks. A pack takes a block of ten, from 200 to 499: block 0 is 200 to 209, block 1 is 210 to 219, up to block 29. The tool picks the block from the id of your mod, and says which. To choose it, set `block` in `[pack]`.

If two packs land on the same block, the framework keeps the first one it reads and leaves out the faces of the other. The log says it: `look <name> of <pack> left out`. Then set another `block` in one of them. Once players have saves with your faces, keep your block and the order of your faces: a save with a face whose id changed shows another face, or none.

## Trying it

1. Install your mod with the framework, and enable both.
2. In the log, `[ML_FF] looks of <id>: <count>` says how many of your faces went in.
3. In the console: `ml_ff_looks` lists them at the end, and `ml_ff_look <name>` puts one on.
4. Save, load, and check that she still has your face.
5. With a head of your own: look down in first-person view, and talk to someone to see her face move.

The framework's own samples are [`examples/sample_faces`](examples/sample_faces), with two faces, `sample_redhead` and `sample_dark`, and [`examples/sample_own_head`](examples/sample_own_head), with `sample_own_woman`.

## With a character of your mod

To start every game with one of your faces, register it as the start character, by its name. [`examples/template_mod`](examples/template_mod) does it, ready to copy:

```lua
FemaleCore.RegisterStartCharacter({ name = "My Heroine", look = "my_heroine" })
```
