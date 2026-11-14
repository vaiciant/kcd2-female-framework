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
- **A piece with a part left.** If a refitted piece still wears a game mesh on her body, it goes as a man's piece until that part is refitted. Legate's robe, with your torso and the game's arms, opened a seam of 3 to 5 cm by the neck.
- **Back to the game's shape.** Those same pieces switch on a morph, `#ml_ff_men_fit`, that takes every refitted piece back to the game's shape. With a man's piece on, she goes as a man, and your piece does not cross it, over it or under it. For each refitted mesh, the tool writes a copy next to it, `<name>_ffmen.skin`, with that morph: what each vertex moves back to where the game has it. The copies wear that mesh, and the pak takes only those. It is not in git, since it carries the game's shape: the tool makes it. Your mesh has to keep the game's vertices, in the same order, or the tool stops and says so.

## Still to refit

The game's meshes for her torso, arms, skirts, legs and neck that nobody has refitted yet, by garment, with the most worn first. The game's colours of a garment share its meshes, so each one here covers all of them. The tool keeps this list: a mesh leaves it when its refitted one is saved.

Until a piece is refitted, she goes as a man with it: it hides her torso below the chest, and the refitted pieces she wears with it go back to the game's shape. Once it is refitted, the whole outfit fits her.

<!-- Still to refit: written by tools/fitted_gear.py. -->

102 meshes of 59 garments, worn by 428 items.

### Torso, arms and skirts

- **tunicshort05**, 18 items, like `TunicShort05_m01_D`: `torso/cloth/tunic/tunic_short/tunicshort05_torso/tunicshort05_torso.skin`, `arms/arms_splited/tunicshort05_arms/tunicshort05_arms.skin`, `torso/cloth/tunic/tunic_short/tunicshort05_waist/tunicshort05_waist.skin`
- **tuniclong03**, 15 items, like `TorsoPainter_m02`: `torso/cloth/tunic/tunic_long/tuniclong03_torso/tuniclong03_torso.skin`, `arms/arms_splited/tuniclong03_arms/tuniclong03_arms.skin`, `torso/cloth/tunic/tunic_long/tuniclong03_waist/tuniclong03_waist.skin`
- **tunicshort01**, 15 items, like `TunicShort01_m01_D`: `arms/arms_splited/tunicshort01_arms/tunicshort01_arms.skin`
- **tunicshort01_m01_d**, 15 items, like `TunicShort01_m01_D`: `torso/cloth/tunic/tunic_short/tunicshort01_m01_d_torso/tunicshort01_m01_d_torso.skin`, `torso/cloth/tunic/tunic_short/tunicshort01_m01_d_waist/tunicshort01_m01_d_waist.skin`
- **tuniclong02**, 14 items, like `TunicLong02_m01_C`: `torso/cloth/tunic/tunic_long/tuniclong02_torso/tuniclong02_torso.skin`, `arms/arms_splited/tuniclong02_arms/tuniclong02_arms.skin`, `torso/cloth/tunic/tunic_long/tuniclong02_waist/tuniclong02_waist.skin`
- **gambesonshort02**, 13 items, like `GambesonShort02_m01_E1`: `torso/cloth/gambeson/gambeson_short/gambesonshort02_torso/gambesonshort02_torso.skin`, `arms/arms_splited/gambesonshort02_arms/gambesonshort02_arms.skin`, `torso/cloth/gambeson/gambeson_short/gambesonshort02_waist/gambesonshort02_waist.skin`
- **gambesonshort03**, 13 items, like `CoatBergov_m01`: `torso/cloth/gambeson/gambeson_short/gambesonshort03_torso/gambesonshort03_torso.skin`, `arms/arms_splited/gambesonshort03_arms/gambesonshort03_arms.skin`, `torso/cloth/gambeson/gambeson_short/gambesonshort03_waist/gambesonshort03_waist.skin`
- **tuniclong05**, 13 items, like `TunicLong05_m01_E`: `torso/cloth/tunic/tunic_long/tuniclong05_torso/tuniclong05_torso.skin`, `arms/arms_splited/tuniclong05_arms/tuniclong05_arms.skin`, `torso/cloth/tunic/tunic_long/tuniclong05_waist/tuniclong05_waist.skin`
- **gambesonshort04**, 12 items, like `GambesonShort04_m01_C3`: `torso/cloth/gambeson/gambeson_short/gambesonshort04_torso/gambesonshort04_torso.skin`, `arms/arms_splited/gambesonshort04_arms/gambesonshort04_arms.skin`, `torso/cloth/gambeson/gambeson_short/gambesonshort04_waist/gambesonshort04_waist.skin`
- **tuniclong01**, 12 items, like `TunicLong01_m01_C`: `torso/cloth/tunic/tunic_long/tuniclong01_torso/tuniclong01_torso.skin`, `arms/arms_splited/tuniclong01_arms/tuniclong01_arms.skin`, `torso/cloth/tunic/tunic_long/tuniclong01_waist/tuniclong01_waist.skin`
- **tunicshort03**, 12 items, like `TunicShort03_m01_D`: `torso/cloth/tunic/tunic_short/tunicshort03_torso/tunicshort03_torso.skin`, `arms/arms_splited/tunicshort03_arms/tunicshort03_arms.skin`, `torso/cloth/tunic/tunic_short/tunicshort03_waist/tunicshort03_waist.skin`
- **tunicshort04**, 11 items, like `TunicShort04_m01_A`: `torso/cloth/tunic/tunic_short/tunicshort04_torso/tunicshort04_torso.skin`, `arms/arms_splited/tunicshort04_arms/tunicshort04_arms.skin`, `torso/cloth/tunic/tunic_short/tunicshort04_waist/tunicshort04_waist.skin`
- **tunicshort06**, 11 items, like `TunicShort06_m01_D`: `torso/cloth/tunic/tunic_short/tunicshort06_torso/tunicshort06_torso.skin`, `arms/arms_splited/tunicshort06_arms/tunicshort06_arms.skin`, `torso/cloth/tunic/tunic_short/tunicshort06_waist/tunicshort06_waist.skin`
- **tunicshort08**, 11 items, like `TunicShort08_m01_C`: `torso/cloth/tunic/tunic_short/tunicshort08_torso/tunicshort08_torso.skin`, `arms/arms_splited/tunicshort08/tunicshort08.skin`, `torso/cloth/tunic/tunic_short/tunicshort08_waist/tunicshort08_waist.skin`
- **tuniclong04**, 10 items, like `TunicLong04_m01_D`: `torso/cloth/tunic/tunic_long/tuniclong04_torso/tuniclong04_torso.skin`, `arms/arms_splited/tuniclong04_arms/tuniclong04_arms.skin`, `torso/cloth/tunic/tunic_long/tuniclong04_waist/tuniclong04_waist.skin`
- **tunicshort02**, 10 items, like `TunicShort02_m01_D`: `torso/cloth/tunic/tunic_short/tunicshort02_torso/tunicshort02_torso.skin`, `arms/arms_splited/tunicshort02/tunicshort02.skin`, `torso/cloth/tunic/tunic_short/tunicshort02_waist/tunicshort02_waist.skin`
- **tunicshort07**, 6 items, like `TunicShort07_m01_E`: `torso/cloth/tunic/tunic_short/tunicshort07_torso/tunicshort07_torso.skin`, `arms/arms_splited/tunicshort07_arms/tunicshort07_arms.skin`
- **devil**, 3 items, like `PourpointDevil01_m01`: `torso/cloth/pourpoint/devil_torso/devil_torso.skin`
- **tunicshortlegate**, 3 items, like `HabitLegate_m01`: `torso/cloth/tunic/tunic_short/tunicshortlegate_torso/tunicshortlegate_torso.skin`, `arms/arms_splited/tunicshortlegate_arms/tunicshortlegate_arms.skin`, `torso/cloth/tunic/tunic_short/tunicshortlegate_waist/tunicshortlegate_waist.skin`
- **gambesonshortistvan**, 2 items, like `GambesonShortIstvan_m01`: `torso/cloth/gambeson/gambeson_short/gambesonshortistvan_torso/gambesonshortistvan_torso.skin`, `arms/arms_splited/gambesonshortistvan_arms/gambesonshortistvan_arms.skin`
- **gambesonshortkomar**, 2 items, like `GambesonShortKomar_m01`: `torso/cloth/gambeson/gambeson_short/gambesonshortkomar_torso/gambesonshortkomar_torso.skin`, `arms/arms_splited/gambesonshortkomar_arms/gambesonshortkomar_arms.skin`, `torso/cloth/gambeson/gambeson_short/gambesonshortkomar_waist/gambesonshortkomar_waist.skin`
- **gambesonshortkubyenka**, 2 items, like `GambesonShortKubyenka_m01`: `torso/cloth/gambeson/gambeson_short/gambesonshortkubyenka_torso/gambesonshortkubyenka_torso.skin`, `arms/arms_splited/gambesonshortkubyenka_arms/gambesonshortkubyenka_arms.skin`, `torso/cloth/gambeson/gambeson_short/gambesonshortkubyenka_waist/gambesonshortkubyenka_waist.skin`
- **boundary_waist_tunic_long_01**, 1 items, like `TunicLongSigismund_m01`: `torso/cloth/tunic/tunic_long/boundary_waist_tunic_long_01/boundary_waist_tunic_long_01.skin`
- **coatzachary**, 1 items, like `CoatZachary_m01`: `torso/decor/coat/coatzachary_torso/coatzachary_torso.skin`, `arms/arms_splited/coatzachary_arms/coatzachary_arms.skin`, `torso/decor/coat/coatzachary_waist/coatzachary_waist.skin`
- **cuirass10**, 1 items, like `Cuirass10_m01`: `torso/plate/cuirass/cuirass10_torso/cuirass10_torso.skin`
- **gambesonshortsamuel**, 1 items, like `GambesonShortSamuel_m01`: `arms/arms_splited/gambesonshortsamuel_arms/gambesonshortsamuel_arms.skin`, `torso/cloth/gambeson/gambeson_short/gambesonshortsamuel_torso/gambesonshortsamuel_torso.skin`
- **lichtenstein**, 1 items, like `GambesonShortLichtenstein_m01`: `arms/arms_splited/lichtenstein_arms/lichtenstein_arms.skin`, `torso/cloth/pourpoint/lichtenstein_torso/lichtenstein_torso.skin`
- **torsopainter**, 1 items, like `TorsoPainter_m01`: `torso/cloth/pourpoint/torsopainter_torso/torsopainter_torso.skin`, `arms/arms_splited/torsopainter_arms/torsopainter_arms.skin`
- **torsopainter_flipped**, 1 items, like `TorsoPainter_flipped_m01`: `torso/cloth/pourpoint/torsopainter_flipped_torso/torsopainter_flipped_torso.skin`, `arms/arms_splited/torsopainter_flipped_arms/torsopainter_flipped_arms.skin`
- **tuniclongsigismund**, 1 items, like `TunicLongSigismund_m01`: `torso/cloth/tunic/tunic_long/tuniclongsigismund_torso/tuniclongsigismund_torso.skin`
- **waffenrockscaring**, 1 items, like `WaffenrockScaring_m01`: `torso/decor/waffenrock/waffenrockscaring_torso/waffenrockscaring_torso.skin`

### Legs

- **hosejoined02**, 36 items, like `HoseJoined02_m01_B`: `legs/hose/hose_joined/hosejoined02/hosejoined02.skin`
- **hoseseparate01**, 33 items, like `HoseSeparate01_m01_D`: `legs/hose/hose_separate/hoseseparate01/hoseseparate01.skin`
- **hosejoined01**, 15 items, like `HoseJoined01_m01_C`: `legs/hose/hose_joined/hosejoined01/hosejoined01.skin`
- **hoseseparate05**, 15 items, like `HoseSeparate05_m01_D`: `legs/hose/hose_separate/hoseseparate05/hoseseparate05.skin`
- **legsbrigandine03**, 15 items, like `LegsBrigandine03_m01_B4`: `legs/leg_armour/legs_brigandine/legsbrigandine03/legsbrigandine03.skin`
- **hoseseparate04**, 14 items, like `HoseSeparate04_m01_E`: `legs/hose/hose_separate/hoseseparate04/hoseseparate04.skin`
- **legsbrigandine04**, 14 items, like `LegsBrigandine01_mMarkvartDream`: `legs/leg_armour/legs_brigandine/legsbrigandine04/legsbrigandine04.skin`
- **hoseloose01**, 11 items, like `HoseLoose01_m01_C`: `legs/hose/hose_loose/hoseloose01/hoseloose01.skin`
- **legsplate05**, 9 items, like `LegsPlate05_m01_C3`: `legs/leg_armour/legs_plate/legsplate05/legsplate05.skin`
- **legsbrigandine01**, 8 items, like `LegsBrigandine01_m01_D2`: `legs/leg_armour/legs_brigandine/legsbrigandine01/legsbrigandine01.skin`
- **legsplate03**, 7 items, like `LegsPlate03_m01_A5`: `legs/leg_armour/legs_plate/legsplate03/legsplate03.skin`
- **legsplate01**, 6 items, like `LegsPlate01_m01_C3`: `legs/leg_armour/legs_plate/legsplate01/legsplate01.skin`
- **legsplate04**, 5 items, like `LegsPlate04_m01_D1`: `legs/leg_armour/legs_plate/legsplate04/legsplate04.skin`
- **legsplate02**, 4 items, like `LegsPlate02_m01_B4`: `legs/leg_armour/legs_plate/legsplate02/legsplate02.skin`
- **legsplate06**, 3 items, like `LegsPlate06_m01_D1`: `legs/leg_armour/legs_plate/legsplate06/legsplate06.skin`
- **legsplate07**, 3 items, like `LegsPlate07_m01_E1`: `legs/leg_armour/legs_plate/legsplate07/legsplate07.skin`
- **hosejoinedcapon**, 1 items, like `HoseJoinedCapon_m01`: `legs/hose/hose_joined/hosejoinedcapon/hosejoinedcapon.skin`
- **hosejoineddevil**, 1 items, like `HoseJoinedDevil_m01`: `legs/hose/hose_joined/hosejoineddevil/hosejoineddevil.skin`
- **hosejoinedlegate**, 1 items, like `HoseJoined02_mLegate`: `legs/hose/hose_joined/hosejoinedlegate/hosejoinedlegate.skin`
- **hosejoinedsigismund**, 1 items, like `HoseJoinedSigismund_m01`: `legs/hose/hose_joined/hosejoinedsigismund/hosejoinedsigismund.skin`
- **legs_plate_zizka**, 1 items, like `LegsPlateZizka_m01`: `legs/leg_armour/legs_plate/legs_plate_zizka/legs_plate_zizka.skin`
- **legspaddedgodwin**, 1 items, like `LegsPaddedGodwin_m01`: `legs/hose/legs_padded/legspaddedgodwin/legspaddedgodwin.skin`
- **legsplatebruncvik**, 1 items, like `LegsPlateBrunswig_m01`: `legs/leg_armour/legs_plate/legsplatebruncvik/legsplatebruncvik.skin`
- **legsplatecapon**, 1 items, like `LegsPlateCapon_m01`: `legs/leg_armour/legs_plate/legsplatecapon/legsplatecapon.skin`
- **m_underwear04**, 1 items, like `prepadeni_henryWetBreeches`: `underwear/m_underwear04/m_underwear04.skin`

### Neck

- **necklace01**, 2 items, like `Necklace01_mVajda`: `decoration/necklace/necklace01/necklace01.skin`
- **noose_mhangman**, 2 items, like `Noose_mHangman`: `decoration/necklace/noose_mhangman/noose_mhangman.skin`
- **plaguesuit**, 1 items, like `PlagueSuit_m01`: `head/hood/plaguesuit/plaguesuit.skin`

<!-- End of the list. -->

## How the game puts a piece together

- A piece takes its meshes from its node and from its parents in the component table, one mesh per part: torso, arms, waist, legs, neck, head.
- A child's mesh replaces its parent's in that part.
- Some parents have a `boundary_` mesh that every child replaces. A refitted one would not show, and `--check` names it.
