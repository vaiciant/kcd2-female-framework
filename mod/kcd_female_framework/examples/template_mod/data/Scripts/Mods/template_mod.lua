-- =============================================================================
-- Template mod for KCD2 Female Framework (README.md next to faces.toml). The game loads this file when it opens, as it
-- loads every file of Scripts/Mods in every mod. Rename template_mod and TemplateMod everywhere: this file, the folder,
-- mod.manifest and faces.toml.
-- =============================================================================
TemplateMod = TemplateMod or {}

-- The woman your mod plays: one of its own faces (faces.toml) or any look of the framework (ml_ff_looks). Her look goes
-- on at every start of the game, new or loaded; a new game waits for Henry's part, after the prologue with Godwin.
-- To play Henry as he is instead, leave HEROINE as nil.
TemplateMod.HEROINE = {
	name = "Template Heroine",        -- for the log
	look = "template_heroine",        -- a look, by name or id
	hair = 3,                         -- optional: a style from 1 to 7, or a name like "katherine"
	color = "dark_brown",             -- optional: the color of that style
}

-- The framework's API that this mod needs: 9 has the faces of other mods.
TemplateMod.API = 9

local function log(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	System.LogAlways("[TEMPLATE_MOD] " .. table.concat(parts, " "))
end

-- At every start of the game, new or loaded. The framework is looked for here and not when this file loads: the load
-- order of mods is not fixed.
function TemplateMod:OnGameplayStarted()
	if not (FemaleCore and FemaleCore.LOADED) then
		log("KCD2 Female Framework is missing")
		return
	end
	if (FemaleCore.API or 0) < TemplateMod.API then
		log("KCD2 Female Framework is too old: API", tostring(FemaleCore.API), "- this mod needs", TemplateMod.API)
		return
	end
	if TemplateMod.HEROINE then
		-- The same table every time, so the framework knows it is the same woman.
		FemaleCore.RegisterStartCharacter(TemplateMod.HEROINE)
	end
	-- What else your mod does with the framework goes here, for example, from a talk or a quest of your mod:
	--   FemaleCore.SetLook("woman_czech_2")   another face, under a black screen
	--   FemaleCore.Henry()                    Henry again
	-- MODDING.md has every call.
end

local ok, problem = pcall(function()
	UIAction.RegisterEventSystemListener(TemplateMod, "System", "OnGameplayStarted", "OnGameplayStarted")
end)
log(ok and "loaded" or ("ERROR listener " .. tostring(problem)))
