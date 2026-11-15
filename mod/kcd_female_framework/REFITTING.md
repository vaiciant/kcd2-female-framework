# KCD2 Female Framework: refitting the men's clothes

For modellers who refit the game's men's armour and clothes to her body, as Cytyryz does for the fitted gear ([FITTED_GEAR.md](FITTED_GEAR.md)). You make the mesh. A tool writes the tables, the items and the swap.

To make a new garment of your own, in your own mod, read [MAKING_CLOTHES.md](MAKING_CLOTHES.md) instead.

## Once

You need the framework's repository, the game installed and Python 3.11 or later. Set `KCD2_GAME` to the game's folder if it is not in the default Steam library. From the root of the repository:

1. **Extract the game's tables:**

   ```bash
   python -I tools/extract_game.py
   ```

2. **Generate her meshes.** Her body goes under `mod/kcd_female_framework/data/Objects/characters/humans/ml_ff_woman/body/`, to fit to:

   ```bash
   python -I -X utf8 mod/kcd_female_framework/tools/generate_women.py
   ```

Run both again after a game update.

## For each piece

1. **Refit the man's mesh to her body,** on the man's skeleton. Her soul is Henry's, so the mesh keeps his bones and weights.
2. **Save it next to where the game has it,** under `mod/kcd_female_framework/data/Objects/characters/humans/male/clothing/`, with `_fffit` before `.skin`:
   - for the game's `torso/plate/cuirass/cuirass03_torso/cuirass03_torso.skin`, it is `torso/plate/cuirass/cuirass03_torso/cuirass03_torso_fffit.skin`;
   - its LODs, if it has them, are `_fffit_lod1.skin` and `_fffit_lod2.skin`;
   - `_ffslim` works the same way.
3. **Run the tool:**

   ```bash
   python -I -X utf8 mod/kcd_female_framework/tools/fitted_gear.py
   ```

   Run it again after every change of meshes.
4. **Check it:**

   ```bash
   python -I -X utf8 mod/kcd_female_framework/tools/fitted_gear.py --check
   ```

   It changes nothing. It says which files are not up to date, and which refitted meshes no piece of the game wears.
5. **Try it in the game.** With the game closed, `python -I tools/install_mod.py mod/kcd_female_framework`. In the console, as a woman: `ml_developer`, then `ml_ff_fitted_give <part of the name>`, like `ml_ff_fitted_give cuirass03`. The game's pieces turn into her copies in a second. Look at each one from the front, the side and the back.
6. **Commit** the refitted meshes and the files the tool wrote. The `_ffmen` meshes stay out: the tool makes them again. Never the game's own files: the repository's `.gitignore` lets through only the `_fffit` and `_ffslim` meshes.

## What the tool writes

| File | What |
|---|---|
| `data/Libs/Tables/Character/CharacterComponent__kcd_female_framework_fitted.xml` | A copy `<piece>_ff` of every piece of the game that wears your mesh |
| `data/Libs/Tables/item/item__kcd_female_framework_fitted.xml` | A copy `<item>_ff` of every item with that piece, with the same stats |
| `data/Scripts/FemaleCore/fitted_gear_data.lua` | Each item and its copy: she gets the copy, a man the game's item |
| `FITTED_GEAR.md` | The list of copies, at the end |
| `REFITTING.md` | The list of meshes still to refit, on this page |

- **One mesh, many items.** The game's colours of a garment share its mesh, so a dozen items can come from one mesh.
- **The copy is a child of the game's piece.** It has all its meshes, with yours in their place, and keeps the rest of the piece: materials, belts and hiding groups.
- **Ids.** A new copy takes an id made from its name, and keeps it from then on.
- **The pieces nobody refitted yet.** A man's piece for the torso has a copy even without your mesh. If her torso or her smock comes through the game's mesh, the copy hides them under it, below the chest. If not, her body stays under it (`KeepBodyLayer`), so an open neckline shows her and not the inside of the piece. The tool measures it with her meshes. When you refit it, the copy takes your mesh and keeps its id, so a save keeps the item.
- **A piece made to go over another garment.** The legate wears his robe over his tunic, and the robe has nothing at the shoulders. Its copy keeps her body under it, hidden below the chest, so her shoulders fill what it leaves open. The tool has these pieces in `OVER_A_GARMENT`.
- **A piece with a part left.** If a refitted piece still wears a game mesh on her body, it goes as a man's piece until that part is refitted. Legate's robe, with a refitted torso and the game's arms, opened a seam of 3 to 5 cm by the neck until its arms were refitted too.
- **Back to the game's shape.** Those same pieces switch on a morph, `#ml_ff_men_fit`, that takes every refitted piece back to the game's shape. With a man's piece on, she goes as a man, and your piece does not cross it, over it or under it. For each refitted mesh, the tool writes a copy next to it, `<name>_ffmen.skin`, with that morph: what each vertex moves back to where the game has it. The copies wear that mesh, and the pak takes only those. It is not in git, since it carries the game's shape: the tool makes it. Your mesh has to keep the game's vertices, in the same order, or the tool stops and says so.

## Still to refit

The goal is every piece of the game covered for her, and Cytyryz has refitted them all. The rest fits her as it is: hats, helmets and coifs take the framework's morph for her head, and gloves, boots, belts and scabbards go on her as on Henry. If an update of the game brings new pieces, the tool lists here their meshes for her torso, arms, skirts, legs and neck, by garment, with the most worn first. The game's colours of a garment share its meshes, so each one here covers all of them. A mesh leaves the list when its refitted one is saved.

Until a piece is refitted, she goes as a man with it: it hides her torso below the chest, and the refitted pieces she wears with it go back to the game's shape. Once it is refitted, the whole outfit fits her.

<!-- Still to refit: written by tools/fitted_gear.py. -->

Nothing: every piece of the game is refitted. If an update of the game brings new ones, they come here.

<!-- End of the list. -->

## How the game puts a piece together

- A piece takes its meshes from its node and from its parents in the component table, one mesh per part: torso, arms, waist, legs, neck, head.
- A child's mesh replaces its parent's in that part.
- Some parents have a `boundary_` mesh that every child replaces. A refitted one would not show, and `--check` names it.
