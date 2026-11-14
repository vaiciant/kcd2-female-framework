# Fitted gear: notes for Cytyryz

These notes are only for this branch, to go over the work together. They are removed before the merge.

Your refitted armour is now part of KCD2 Female Framework, and it works: the cuirasses, the gambesons, the mail and the hoods fit her and sit on each other. This page explains what changed around your meshes, what is still missing, and a few things to look at, if you can.

## What changed

- **One item for both bodies.** The game's item and your copy swap into each other. She gets your copy, and a man gets the game's piece back: Henry after `ml_ff_henry`, or a man of KCD2 Life. They are the same garment, made for another body, so they are not two items to choose from.
- **Part of the framework.** Your meshes go in the framework, not in a mod of their own.
- **The tables come from a tool.** In a table patch, a node of the game declared again takes only the attributes it is given, for every NPC too. The first table declared again 5191 nodes of the game, and 179 of them lost attributes (`ArmorType`, `HidingGroups`, `Morphs`, `ArmorArchetypeId`...). The men of the whole game lost their clothes, and the copies could not be equipped. Now a tool, `tools/fitted_gear.py`, writes the copies, the items and the swap from your meshes, with each node of the game as the game has it. It rebuilds your 948 items with the same ids.
- **What you send:** only the meshes. The tool and its guide, `REFITTING.md`, come to this repository with the next update.

## How to save a mesh

1. **Refit the game's mesh, on the man's skeleton,** around her body. Her soul is Henry's, so the mesh keeps his bones and weights.
2. **Keep the game's vertices, in the same order.** Don't add or remove any: move them. All 210 of your meshes do it now. The framework needs it to take your piece back to the game's shape when she wears a man's piece with it (next section).
3. **Save it next to where the game has it,** under `mod/kcd_female_framework/data/Objects/characters/humans/male/clothing/`, with `_fffit` before `.skin`:
   - for the game's `torso/cloth/tunic/tunic_short/tunicshort05_torso/tunicshort05_torso.skin`, it is `torso/cloth/tunic/tunic_short/tunicshort05_torso/tunicshort05_torso_fffit.skin`;
   - its LODs, if you make them, are `_fffit_lod1.skin` and `_fffit_lod2.skin`.
4. **One mesh covers every colour.** The game's colours of a garment share its mesh, so one mesh can give a dozen items.

## A man's piece together with yours

A refitted piece is made for her body, and the game's piece for Henry's. Worn together, over or under each other, one came through the other: her chest through the man's tunic, the man's tunic through your cuirass, his shoulders through your hood. Until every piece is refitted, the framework does this:

- **The men's pieces that are not refitted** have a copy too, with the game's mesh. If her torso or her smock comes through it, the copy hides them below the chest (1.32 m), where she is wider than the man. Under a loose piece nothing is hidden.
- **With one of them on,** everything refitted that she wears goes back to the game's shape: a morph made from your mesh and the game's. The whole outfit goes as a man's, and nothing crosses.
- **Without them,** with her dresses or only refitted pieces, everything stays as you refitted it.
- **Hoods** also get the game's widening for padded clothes (`#extend_hood_cloth_padded`). The short pourpoint (`GambesonShort03`) lost it in the game's own tables.

So the outfits that mix work, but she looks like a man in them. The real fix is refitting the rest. When a piece is refitted, all of this turns off for it by itself.

## What is still to refit

The game's meshes for her torso, arms, skirts, legs and neck that are not refitted yet, by garment, with the most worn first. Hats, helmets and coifs are not here: the framework's own morph fits them to her head. Hands, feet, belts and scabbards are not either.

The base pieces are the most worth doing first: the short and long tunics, and the short gambesons 02 to 04. Short pourpoint is `gambesonshort03`.

102 meshes of 59 garments, worn by 428 items.

#### Torso, arms and skirts

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

#### Legs

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

#### Neck

- **necklace01**, 2 items, like `Necklace01_mVajda`: `decoration/necklace/necklace01/necklace01.skin`
- **noose_mhangman**, 2 items, like `Noose_mHangman`: `decoration/necklace/noose_mhangman/noose_mhangman.skin`
- **plaguesuit**, 1 items, like `PlagueSuit_m01`: `head/hood/plaguesuit/plaguesuit.skin`

## Other things to look at

1. **Hoods go a little into her body, at the front.** Measured against her body at rest, between 1.25 and 1.50 m, the front of the cape goes into her chest:

   | Hood | Vertices inside | Deepest |
   |---|---|---|
   | `hood05` | 38 | 3.0 cm |
   | `hood12` | 8 | 2.5 cm |
   | `hood08` | 15 | 1.7 cm |
   | `hood11` | 9 | 1.0 cm |
   | `hood01` | 1 | 0.3 cm |

   Pushing the front of the cape out a little would fix it.
2. **Legate's robe (`HabitLegate_m01`): a gap by the neck.** Your torso narrowed the shoulders, but the robe wears the game's arms (`tunicshortlegate_arms`), which stayed where they were: the seam between them opened 3 to 5 cm. Bergov's coat (`CoatBergov_m01`) is the same, with the game's arms of the short pourpoint. Until those arms are refitted, both go in the game's shape, as a man's piece. The robe hides nothing of her: it is loose, and hiding her chest left its inside empty, seen through the neckline. Both arms are in the list.
3. **Short pourpoint with a hood.** The padding at the front of the chest comes over the cape. Refitting the pourpoint fixes it, as with your other gambesons.
4. **A little mixing towards the chest** with the base pieces. Refitting them fixes it.
5. **Four boundary meshes are never seen.** A child's mesh replaces its parent's in that part, so the boundary meshes of the parent nodes never show. They don't need refitting:
   - `head/coif/padded_coif/coif_large/boundary_head_padded_coif_large_01/boundary_head_padded_coif_large_01_fffit.skin`
   - `head/collar/collar_mail/boundary_head_collar_mail_01/boundary_head_collar_mail_01_fffit.skin`
   - `head/collar/collar_padded/boundary_head_collar_padded_01/boundary_head_collar_padded_01_fffit.skin`
   - `torso/plate/brigandine/boundary_torso_brigandine_01/boundary_torso_brigandine_01_fffit.skin`
6. **Sigismund's coat** (`CoatSigismund_m01`) now wears your refitted hood on its neck. Your table had the game's there. Check that it sits right.
7. **The hoods up.** The 59 `Hood..._up_...` items stay as you made them. Their originals are not in the tables of my copy of the game. Which version of the game are they from?

## Trying them in the game

In the console, as a woman (`ml_ff_look woman_czech_2`):

1. `ml_developer` turns on the test commands.
2. `ml_ff_fitted_give <part of the name>`, like `ml_ff_fitted_give gambesonshort03`, gives the game's pieces, and they turn into your copies in a second.
3. `ml_ff_henry` turns her back into Henry, and the copies back into the game's pieces.
