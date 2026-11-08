# KCD2 Female Framework: changelog

Only minor versions are listed here: 0.1.0, 0.2.0 and so on. Every build between them raises the last number of the version, and those builds are not listed.

## 0.2.0

- **Her face moves.** Her lips move with Henry's voice, and she blinks and makes faces, as a man does. Every head now carries its face poses, and the bones of its face sit where the fitted face is.
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
