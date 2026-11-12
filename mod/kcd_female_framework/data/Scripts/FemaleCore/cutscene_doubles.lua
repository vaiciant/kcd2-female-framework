-- =============================================================================
-- Henry's doubles in the cutscenes of the engine. In a cutscene, Henry is an
-- AnimChar of its layer, and the soul in Properties.Body.guidBodyPresetId gives its look. Most use the player's soul,
-- so they show her. 27 use a soul of their own, which the game gives Henry's head: wet at the lake, wounded when he
-- falls, his arm bandaged, dreaming, whipped, naked in the romances. While the character in use is a woman, those take
-- the player's soul. Henry as a man sees them as always.
--
-- KCD2 Male Framework does the same for a man with a look of its own, with its own copy of this file. Both give the
-- player's soul when a look of either is on, and keep the double's own soul in the same field, so each leaves as it is
-- what the other did.
--
-- A layer makes its doubles when it loads, and that calls AnimChar.SetFromProperties, which the game looks up each
-- time: the soul changes there, before the model. The game keeps its own AnimChar.OnSpawn, so a change there is never
-- called. While a cutscene plays, the doubles that are there already are checked once a second too, and
-- one that changes starts again, like ml_w_actor_set did. Out of cutscenes nothing is searched. This copy
-- searches for both frameworks: DOUBLES_SCAN tells KCD2 Male Framework to leave it to this one.
-- =============================================================================
FemaleCore = FemaleCore or {}

FemaleCore.PLAYER_SOUL = "4c2dcffb-dea1-6263-72d7-b39f4db2d8b5"
-- The souls of Henry's doubles with a look of their own (Libs/Tables/rpg/soul.xml), and what they are.
FemaleCore.HENRY_DOUBLE_SOULS = {
	["2a15d6ae-46cf-4172-825e-ab4cd504dcc0"] = "prepadeni_jindrichWet",
	["734090a0-9276-4783-9d31-d6a66c69673b"] = "prepadeni_jindrichInjured",
	["4407e676-8058-4f2b-ad2f-8228f9c1989f"] = "kkut_henry",
	["e0831215-924c-43b2-8bd9-8c26a5b15b81"] = "cutscene_henry_injured_arm",
	["d47c88db-0a13-4140-870f-b06824b5e3a7"] = "cutscene_henry_whipped_mild",
	["e41ba721-1f76-4182-afbb-46b207b0850c"] = "cutscene_henry_whipped_severe",
	["ff8cd1f5-5470-40d9-b9bb-5262ce4738ad"] = "cutscene_really_naked_henry",
}
-- 1 while a cutscene plays: Config/CVarOverrides/Cutscene.cfg sets it.
FemaleCore.DOUBLES_CVAR = "e_SkipInFrustumOptimizationWH"
FemaleCore.DOUBLES_SCAN = true

local function try(label, fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		FemaleCore.Log("ERROR", label, result)
		return nil
	end
	return result
end

-- A woman of this framework, or a man with a look of KCD2 Male Framework.
local function lookInUse()
	if FemaleCore.WomanInUse ~= nil and FemaleCore.WomanInUse() then
		return true
	end
	local ok, man = pcall(function() return MaleCore and MaleCore.ModelInUse and MaleCore.ModelInUse() end)
	return ok and man == true
end

-- The soul the double should have: the player's while a look is on, and its own the rest of the time. Nothing for a
-- double that is not one of Henry's with a soul of its own.
local function wantedSoul(entity)
	local body = entity.Properties and entity.Properties.Body
	if type(body) ~= "table" then
		return nil
	end
	local own = entity.ml_own_soul or body.guidBodyPresetId
	if not FemaleCore.HENRY_DOUBLE_SOULS[own] then
		return nil
	end
	entity.ml_own_soul = own
	return body, lookInUse() and FemaleCore.PLAYER_SOUL or own
end

-- True when the soul changed.
local function setSoul(entity, when)
	local body, soul = wantedSoul(entity)
	if not body or body.guidBodyPresetId == soul then
		return false
	end
	body.guidBodyPresetId = soul
	FemaleCore.Log("cutscene double", entity:GetName(), FemaleCore.HENRY_DOUBLE_SOULS[entity.ml_own_soul],
		soul == FemaleCore.PLAYER_SOUL and "takes the player's soul" or "has its own soul again", when)
	return true
end

-- The game loads AnimChar.lua the first time it makes one, so it may not be there yet: the tick tries again. Only with
-- the game's scripts in place, and the script runs only if the game has not run it yet.
local function watch()
	if type(AnimChar) ~= "table" and type(EntityCommon) == "table" and type(EntityCommon.DeriveOverride) == "function" then
		try("cutscene doubles", Script.LoadScript, "Scripts/Entities/WH/Others/AnimChar.lua")
	end
	if type(AnimChar) ~= "table" or AnimChar.ml_ff_watched or type(AnimChar.SetFromProperties) ~= "function" then
		return
	end
	local original = AnimChar.SetFromProperties
	AnimChar.SetFromProperties = function(self, ...)
		pcall(setSoul, self, "(when made)")
		return original(self, ...)
	end
	AnimChar.ml_ff_watched = true
	FemaleCore.Log("cutscene doubles: watched")
end

local function inCutscene()
	local value = try("cutscene", System.GetCVar, FemaleCore.DOUBLES_CVAR)
	return tonumber(value) == 1
end

-- From the tick, once a second: one cvar out of cutscenes, and the doubles only in them.
function FemaleCore.CutsceneDoubles()
	watch()
	if not inCutscene() then
		return
	end
	local doubles = System.GetEntitiesByClass("AnimChar")
	if not doubles then
		return
	end
	for _, entity in ipairs(doubles) do
		if setSoul(entity, "(already there)") then
			try("cutscene double", function() entity:OnReset() end)
		end
	end
end
