-- =============================================================================
-- KCD2 Female Framework: startup. The game loads this file when it opens. It works with
-- Henry in the game with no other mod: MODDING.md.
-- =============================================================================
FemaleCore = FemaleCore or {}
FemaleCore.LOADED = true

Script.LoadScript("Scripts/FemaleCore/female_core.lua")
Script.LoadScript("Scripts/FemaleCore/looks_data.lua")
Script.LoadScript("Scripts/FemaleCore/clothes_data.lua")
Script.LoadScript("Scripts/FemaleCore/barber.lua")
Script.LoadScript("Scripts/FemaleCore/cutscene_doubles.lua")

if not (FemaleCore.BecomeWoman and FemaleCore.LOOKS and FemaleCore.CLOTHES and FemaleCore.Barber and FemaleCore.CutsceneDoubles) then
	System.LogAlways("[ML_FF] ERROR a file did not load")
	return
end

System.AddCCommand("ml_ff_looks", "FemaleCore.PrintLooks()", "Lists the women's looks of KCD2 Female Framework: name, people, age and id")
System.AddCCommand("ml_ff_female", "FemaleCore.FemaleCommand(%line)", "Turns Henry into a woman, with a look or the first one, like ml_ff_female woman_czech_2, and a hair, as ml_ff_hair takes it. A last word true leaves out the black screen")
System.AddCCommand("ml_ff_look", "FemaleCore.LookCommand(%line)", "Gives her the head and body of a look, by name or id, like ml_ff_look woman_romani_3, and a hair if given, like ml_ff_look woman_czech_2 5 blonde. Henry becomes a woman with it. A last word true leaves out the black screen")
System.AddCCommand("ml_ff_henry", "FemaleCore.HenryCommand(%line)", "Turns her back into Henry: his head, body and hair, with no beard. A last word true leaves out the black screen")
System.AddCCommand("ml_ff_random", "FemaleCore.RandomCommand(%line)", "Gives her a look at random among all, with the hair it starts with. Henry becomes a woman with it. A last word true leaves out the black screen")
System.AddCCommand("ml_ff_hair", "FemaleCore.HairCommand(%line)", "Gives her a hair style from 1 to 7 and a color, like ml_ff_hair 2 blonde, the game's name of one, like f_hair_002_blonde, or the hair of katherine, rose, mother or miriam")
System.AddCCommand("ml_ff_refresh", "FemaleCore.RefreshCommand()", "Rebuilds the model, for when her look does not show")
System.AddCCommand("ml_ff_start", "FemaleCore.StartCommand(%line)", "The next game that starts or loads begins as a woman with that look, like ml_ff_start woman_czech_2, and a hair, as ml_ff_hair takes it: type it in the main menu before New Game. ml_ff_start none cancels it")

local ok, problem = pcall(function() UIAction.RegisterEventSystemListener(FemaleCore, "System", "OnGameplayStarted", "OnGameplayStarted") end)
FemaleCore.Log(ok and "listening to OnGameplayStarted" or ("ERROR listener " .. tostring(problem)))
