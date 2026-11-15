# Template mod for KCD2 Female Framework

A mod that plays a woman of its own, ready to copy and rename. It has:

| File | What |
|---|---|
| `faces.toml` | One face of its own, `template_heroine`, and the lines for a head of your own, commented out |
| `data/Scripts/Mods/template_mod.lua` | Its Lua: it checks that the framework is there and new enough, and makes `template_heroine` the start character, so every game, new or loaded, plays her |
| `mod.manifest` | Its name, id and version |
| `data/Libs`, `data/Quests`, `data/Scripts/FemaleCore` | What the face tool wrote from `faces.toml`. You do not edit them: you run the tool again |

KCD2 Male Framework has the same template for a man.

## Making it yours

1. **Copy the folder** wherever you keep your mod, and rename `template_mod` to the id of your mod: the folder, `data/Scripts/Mods/template_mod.lua`, the `modid` in `mod.manifest` and the `id` in `faces.toml`. In the Lua, rename `TemplateMod` and `[TEMPLATE_MOD]` too.
2. **Delete what the tool wrote**, the files under `data/Libs`, `data/Quests` and `data/Scripts/FemaleCore`, since they carry the old id.
3. **Choose her face** in `faces.toml`: a head of the framework ([LOOKS.md](../../LOOKS.md)) or a head of your own, her body, and the style and color of her hair. [MAKING_FACES.md](../../MAKING_FACES.md) explains every field.
4. **Run the face tool**, from the root of the framework's repository, after every change of `faces.toml`:

   ```bash
   python -I -X utf8 mod/kcd_female_framework/tools/make_face_pack.py path/to/your_mod
   ```

5. **Point the Lua at her:** in `HEROINE`, the `look` is the `name` of her face in `faces.toml`, or any look of the framework. Leave `HEROINE` as `nil` if your mod plays Henry as he is.
6. **Pack and install it,** with the game closed, from the root of the repository:

   ```bash
   python -I tools/install_mod.py path/to/your_mod
   ```

   Then enable it in your mod manager, next to KCD2 Female Framework.

## Trying it

- In `kcd.log`, `[TEMPLATE_MOD] loaded` when the game opens, and `[ML_FF] looks of template_mod: 1`.
- In a game, new or loaded, `[ML_FF] start character: Template Heroine`. A few seconds later, she has her look. A new game waits for Henry's part, after the prologue with Godwin.
- `ml_ff_look template_heroine` in the console puts her look on at any time, and `ml_ff_henry` turns her back into Henry.

## Clothes for her

- **The game's clothes** fit her already: her dresses, and the men's armour and clothes, refitted ([FITTED_GEAR.md](../../FITTED_GEAR.md)).
- **Clothes of your mod:** make them as a normal women's garment of the game, in this same mod, and convert them with `tools/convert_clothes.py`, which writes their copies for her into the mod. [MAKING_CLOTHES.md](../../MAKING_CLOTHES.md) explains it, and how to make them by hand.

## More

- Every call of the framework: [MODDING.md](../../MODDING.md).
- The console commands: [COMMANDS.md](../../COMMANDS.md).
- Credit KCD2 Female Framework where people can see it, like a line in your mod's description. That is the only condition of its license.
