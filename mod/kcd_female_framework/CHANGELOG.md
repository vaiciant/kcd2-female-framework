# KCD2 Female Framework: changelog

Only minor versions are listed here: 0.1.0, 0.2.0 and so on. Every build between them raises the last number of the version, and those builds are not listed.

## 1.0.0

Every man's armour and piece of clothing of the game fits her now, refitted by Cytyryz, who joins the framework. Other mods can add faces of their own, dress her, and play a woman of their own from the start.

### New

- **The fitted gear, by [Cytyryz](https://www.nexusmods.com/profile/Cytyryz?gameId=7286).** Over 1,350 items of the game, with the story and DLC armour, refitted to her body: tunics, hose, gambesons, mail, plate, coats, hoods, collars and necklaces sit on each other as they should. Each one turns into her copy as her dresses do, and back to the game's piece for a man. [FITTED_GEAR.md](FITTED_GEAR.md) lists them.
- **Her hair under the hoods.** What would hang out through the cape is hidden.
- **Dressed from the start.** At the start of a game as a woman, what Henry wears turns into her copies and stays on.
- **The prologue.** Henry's gear there belongs to the quest. Once she has full control, she gets her own version of each piece, and it goes away with the quest's at the ambush.
- **A character of your mod.** `FemaleCore.RegisterStartCharacter` makes a look the start of every game, new or loaded, with no command.
- **Faces from other mods,** with the framework's heads or a woman's head of your own: `tools/make_face_pack.py` writes them from one file. [MAKING_FACES.md](MAKING_FACES.md) explains it.
- **Clothes from other mods.** A normal women's garment of your mod, converted for her with `tools/convert_clothes.py`, swaps as her dresses do. [MAKING_CLOTHES.md](MAKING_CLOTHES.md) explains it.
- **A template mod,** `examples/template_mod`: a face of its own and a woman it plays from the start, with the steps to make it yours.
- **A companion's clothes.** `FemaleCore.DressNpc` puts a piece on a woman NPC, and `ml_ff_npc_dress` tries one.
- **Developer mode:** `ml_ff_fitted_give`, `ml_ff_fitted_test`, `ml_ff_fitted_showcase`, `ml_ff_start_character` and `ml_ff_inventory`, to try all this.
- **For modders:** `FemaleCore.RegisterClothes`, `RegisterLooks` and `RegisterStartCharacter`. `FemaleCore.API` is 9.

### Fixes

- **Legate's robe** shows her chest and shoulders.
- **Her thighs** no longer disappear under a tunic when she wears no shift.
- **Hoods** no longer go into her chest.

## 0.5.0

Her hair goes on with her face, from one command, and four hairs of women of the story join the seven of the barber. KCD2 Female Voice, a mod of its own, now gives her a woman's voice.

### New

- **A hair in `ml_ff_look`.** `ml_ff_look woman_czech_2 5 blonde` gives her that face and that hair at once. `ml_ff_female` and `ml_ff_start` take it too.
- **Hairs of the story.** `ml_ff_hair katherine` gives her Katherine's hair, which the barber does not have; `rose`, `mother` and `miriam` work too. Their braids keep still.
- **The game's names.** `ml_ff_hair f_hair_005_blonde` works, as LOOKS.md writes the hair of each character.
- **LOOKS.md** has, for every character of the game, the command that gives the face with her hair.
- **A woman's voice.** KCD2 Female Voice, a separate mod, gives her a woman's voice in every line of Henry.
- **For modders:** `FemaleCore.SetLook`, `BecomeWoman` and `StartAs` take a hair after the look. `FemaleCore.API` is 6.

## 0.4.0

It works on its own or with KCD2 Male Framework, and goes from one to the other directly. Her look now reaches the game's cutscenes.

### New

- **One command to a look.** `ml_ff_look` and `ml_ff_random` turn Henry into a woman with that look. `ml_ff_female` is no longer needed first.
- **Straight to a man's face.** With KCD2 Male Framework, `ml_mf_look` and `ml_mf_random` turn her into a man with that face, without going back to Henry first.
- **Cutscenes.** The doubles of Henry that the game's cutscenes make wear her look.
- **The pillory.** She wears hose there, and her look comes back right after it.
- **On its own.** It no longer needs KCD2 Male Framework, and works with it as before. KCD2 Life needs both.
- **LOOKS.md** says which named characters of the game wear each face, and `ml_ff_looks` shows their names.
- **For modders:** `FemaleCore.Henry(noScreen, after)` and `FemaleCore.Ready()`. `FemaleCore.API` is 5.

### Fixes

- **Commands right after loading** wait until both frameworks have read the save, so nothing is put on before the look of the save.
- **A save where she became a man** no longer keeps her woman's state on.
- **The doubles of the cutscenes** keep the haircut from the barber.

## 0.3.0

- **Start a new game as a woman.** `ml_ff_start woman_czech_2`, in the console of the main menu before New Game, chooses her look. It goes on once Henry's part begins, after the prologue with Godwin and the cutscene that ends it. It works for the next game that starts or loads, once, and `ml_ff_start none` cancels it.
- **Her own body in the game's scenes.** Five scenes put Henry's own parts on the player: wet, wounded and bandaged in the prologue, and wet at the Cumans' swimming contest. She now keeps her head, her body and her shift there, also after loading a save in the middle of them. Henry as a man sees them as before. Those five scene files replace the game's, so a mod that replaces the same files clashes with them.
- **For modders:** `FemaleCore.StartAs(look)` and `FemaleCore.StartLook()` are new. `FemaleCore.API` is 3.
- **License:** asking for donations or Patreon support for a mod that uses it is fine, as long as nothing in it is only for those who pay. Warhorse's rules do not allow selling KCD2 mods.

## 0.2.0

- **Her face moves.** Her lips move when she speaks, and she blinks and makes faces, as a man does. Every head now carries its face poses, and the bones of its face sit where the fitted face is.
- **Back to Henry.** `ml_ff_henry` turns her back into Henry, in the same save: his head and body, his usual hair and no beard. Her clothes come off, with a notice. `ml_ff_female` makes him a woman again at any time.
- **With KCD2 Male Framework 0.2.0 or later,** its faces work after going back to Henry, and `ml_mf_henry` keeps his own.
- **For modders:** `FemaleCore.Henry(noScreen)` works, and `FemaleCore.TakeOffHenry()`, `FemaleCore.KeepHenry()` and `FemaleCore.HenryKept()` are new. `FemaleCore.API` is 2.
- Removing the mod from a save where Henry was ever a woman is still not supported. Keep a save from before `ml_ff_female`.

## 0.1.0

The first release.

- **Playable women.** One command, `ml_ff_female`, turns Henry into a woman, and other mods can do it from Lua.
- **55 faces:** every common woman's face of the game and five women of the story. `ml_ff_random` picks one at random.
- **Women's clothes** from any shop, fitted to the player's skeleton, with their condition. Men's hats and helmets sit right on her head.
- **Her hair:** 7 styles and up to 9 colors, and a woman's haircut at every barber of the game, for the game's price: 50 groschen, or 5 with Realish Economy.
- **First person** hides her face, as it does Henry's.
- **Clothes that make sense:** a dress and men's armour come off each other, with a notice.
