# KCD2 Female Framework: making clothes for her

The woman of the framework is Henry with a woman's head and body. His soul is still a man's, and the game looks for a character's clothes only in the branch of its gender, Male. So a garment for her is a copy in the Male branch, fitted to the man's skeleton, and registered with the framework, which swaps each item for its copy while she is a woman.

There are two ways to make one: make a normal women's garment and let the tool convert it, or make the three parts by hand.

## The easy way: a women's garment, converted

1. **Make your garment as for any woman of the game:**
   - its `Clothing` in the Female branch, in `Libs/Tables/Character/CharacterComponent__<yourmod>.xml`, under one of the game's groups (Torso, Legs, Head…), with `FilePath="humans/female/clothing/"`;
   - its meshes skinned to the women's skeleton, under `Objects/characters/humans/female/clothing/`;
   - its items in `Libs/Tables/item/item__<yourmod>.xml`.
2. **Give it one of the women's types:** `F_SimpleDress` or `F_Smock` for a dress, `F_Shoes`, or `F_Hood`, `F_Bonnet`, `F_CapAndWimple`, `F_Hat`, `F_HoodOpen`, `F_Veil` or `F_VeilAndWimple` for the head. The framework's rules know these types: a dress takes a man's clothes off her torso, hands and legs, and a man takes them off. The tool tells you about a garment that has none.
3. **Convert it.** Get the framework's repository, extract the game's tables once with `python -I tools/extract_game.py`, and from its root run:

   ```bash
   python -I -X utf8 mod/kcd_female_framework/tools/convert_clothes.py <folder of your mod>
   ```

4. **It writes four things in your mod.** Ship them with it:
   - `Libs/Tables/Character/CharacterComponent__<modid>_ff.xml`: each garment, copied into the Male branch as `ml_ff_<name>`;
   - `Libs/Tables/item/item__<modid>_ff.xml`: each item, copied as `ml_ff_<name>`, with the same stats;
   - `Objects/characters/humans/ml_ff_woman/clothing/`: your meshes, fitted to her;
   - `Scripts/FemaleCore/Clothes/<modid>.lua`: the flag that says the copies are for her.
5. **Run it again after every change** to your clothes: it writes the four over.

The fit is automatic: each vertex moves as its bones move from the women's skeleton to the man's. Cloth that the game simulates stays still, as on the framework's own dresses. Look at the garment in the game, from the front, the side and the back, before you publish it.

Your mod needs a version of KCD2 Female Framework that reads the flag: `FemaleCore.API` 7 or later.

## By hand

The tool makes three parts. You can make them yourself, for example for a man's piece refitted to her in Blender. For the game's own men's pieces, `tools/fitted_gear.py` makes them from the refitted meshes: [REFITTING.md](REFITTING.md) explains it.

1. **The mesh, fitted to her.** It is skinned to the man's skeleton, since the soul is Henry's, and shaped for her body. Run `tools/generate_women.py` once and you have her bodies under `Objects/characters/humans/ml_ff_woman/body/`, to fit to.
2. **The copy, in the tables.** A `Clothing` in the Male branch that points to those meshes, and an item that wears it. By convention its name is `ml_ff_<name>`. It has to be unique in the Male branch: a name repeated there does not work. The nodes of the game above it go in your table as the game has them, with all their attributes: a node declared again takes the attributes you give it, for every NPC too, and a missing `ArmorType`, `HidingGroups` or `Morphs` breaks the men's clothes of the whole game. `--check` finds them.
3. **The flag.** A Lua file in `Scripts/FemaleCore/Clothes/` of your mod, with any name, that registers each item and its copy:

   ```lua
   FemaleCore.RegisterClothes({
   	{ original = "<id of the item>", copy = "<id of its copy for her>" },
   	{ original = "<id of a man's piece>", copy = "<id of it refitted for her>", back = true },
   }, "<your mod>")
   ```

   - She gets the copy of each original that reaches her inventory, with the same condition.
   - With `back = true`, the original is a man's piece, and a man gets it back: Henry after `ml_ff_henry`, or a man of KCD2 Life.
   - Without it, the copy is a woman's garment, and the framework's rules take it off a man, if it has a women's type.
   - A garment made only for her, with no item of the game behind it, needs no entry: she wears it as it is.
   - `name` and `copy_name`, the item names of both, are optional: with them, `ml_ff_npc_dress <name>` finds your items. The tool writes them.

Check a mod made by hand, or converted, with:

```bash
python -I -X utf8 mod/kcd_female_framework/tools/convert_clothes.py <folder of your mod> --check
```

It checks that each entry has its items, that each copy has its `Clothing` in the Male branch of your tables, and that its meshes are in your mod.

## Testing

`ml_developer` turns on the framework's test commands until the game closes. `ml_ff_fitted_give` gives the pieces of the fitted gear, which turn into her copies, and `ml_ff_npc_dress <name>` puts one of your items on the nearest woman NPC. In the log, `[ML_FF] clothes of <your mod>: <count>` says how many of your entries it took when the game started.
