-- =============================================================================
-- FemaleCore: the API of KCD2 Female Framework (MODDING.md). It turns Henry himself into a
-- woman, changes her look and turns her back into Henry, with no other mod. Head, body and
-- underwear are overrides of ml_ff_face.xml, picked with a token given to Henry, and Skald
-- takes off the clothes that do not go together. Her hair goes on his soul with the native
-- Barber object. The model only shows the overrides after a rebuild, which two real hair
-- changes force: a woman has no beard to change. Women's clothes that reach her inventory
-- turn into copies she can wear.
-- =============================================================================
FemaleCore = FemaleCore or {}

-- 2 since 0.2.0: Henry() works, and TakeOffHenry(), KeepHenry() and HenryKept() are new. 6: SetLook, BecomeWoman and
-- StartAs take a hair, and SetHair the game's names and the hairs of the women of the story. 7: RegisterClothes,
-- and the clothes of Scripts/FemaleCore/Clothes. 8: RegisterStartCharacter. 9: RegisterLooks, and the faces of
-- Scripts/FemaleCore/Looks.
FemaleCore.API = 9
FemaleCore.MAN = 1
FemaleCore.WOMAN = 2
FemaleCore.TOKEN_MS = 1000
FemaleCore.REBUILD_MS = 1000
FemaleCore.TICK_MS = 1000
FemaleCore.NOTICE_SECONDS = 6
-- Every style has them.
FemaleCore.REBUILD_HAIRS = { "ml_ff_hair_002_black", "ml_ff_hair_002_blonde" }
-- The same, for Henry back as a man: men's hair. A beard would be on her head until his shows.
FemaleCore.HENRY_REBUILD_HAIRS = { "m_hair_005_black", "m_hair_005_dark_brown" }
-- Henry's own hair and no beard, as KCD2 Male Framework gives them back.
FemaleCore.HENRY_HAIR = "m_hair_henry"
FemaleCore.HENRY_BEARD = "m_beard_00"
-- A beard on the head of a woman has crashed the game. This one has no mesh, so it fits any head.
FemaleCore.SAFE_BEARD = "m_beard_00"
-- The hair styles, each with how many of HAIR_COLORS it has: the game has no grey for style 3.
FemaleCore.HAIR_STYLES = { 9, 9, 6, 9, 9, 9, 9 }
FemaleCore.HAIR_COLORS = { "dark_brown", "black", "light_brown", "blonde", "ginger", "dark_ginger", "dark_grey", "grey", "white" }
-- The hairs of women of the story that the framework fits too, out of the barber: f_hair_katherine of the game is
-- ml_ff_hair_katherine here. generate_women.py mounts the same ones (HAIRS).
FemaleCore.NAMED_HAIRS = { "katherine", "rose", "mother", "miriam" }
-- FemaleCore.LOOKS and the tokens come from looks_data.lua, and FemaleCore.CLOTHES from clothes_data.lua.

-- A mod that plays its own character instead of Henry, like KCD2 Life, puts here a function that says so. The look
-- goes on Henry's soul, so with another character the commands do nothing.
FemaleCore.OtherCharacter = FemaleCore.OtherCharacter or function() return false end

function FemaleCore.Log(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	System.LogAlways("[ML_FF] " .. table.concat(parts, " "))
end

local function try(label, fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then
		FemaleCore.Log("ERROR", label, result)
		return nil
	end
	return result
end

-- For barber.lua.
FemaleCore.Try = try

local function notHenry()
	local ok, other = pcall(FemaleCore.OtherCharacter)
	if ok and other then
		FemaleCore.Log("the character in use is not Henry: nothing to do")
		return true
	end
	return false
end

-- Skald reacts when it arrives.
local function sendToken(guid)
	try("token", function() player.inventory:CreateItem(guid, 1, 1) end)
	Script.SetTimer(FemaleCore.TOKEN_MS, function()
		try("token", function() player.inventory:DeleteItemOfClass(guid, 1) end)
	end)
end

-- The token of a look. A look of another mod (RegisterLooks) has its own project, and the framework's needs this one too,
-- to make her a woman as its own looks do (MAKING_FACES.md).
local function sendLookToken(look)
	sendToken(look.token)
	if look.outside and FemaleCore.OUTSIDE_TOKEN then
		sendToken(FemaleCore.OUTSIDE_TOKEN)
	end
end

local function takeToken(class)
	local count = try("token", function() return player.inventory:GetCountOfClass(class) end) or 0
	if count > 0 then
		try("token", function() player.inventory:DeleteItemOfClass(class, count) end)
		return true
	end
	return false
end

-- Black screen

-- A black screen with a line of text, through the HUD, while the model changes. The player cannot move under it.
FemaleCore.SCREEN_TEXT = "@ml_ff_changing_look"
-- Whatever fails, the screen does not stay black longer than this.
FemaleCore.SCREEN_MAX_MS = 20000
local FADE_IN = 1
local FADE_OUT = 2
local TEXT_LAYOUT = 3
local TEXT_FADE_MS = 1000
local LOCK_MS = 100
local screen = { up = false, gen = 0 }

local function hud(name, ...)
	local args = { ... }
	try("hud " .. name, function() UIAction.CallFunction("hud", -1, name, unpack(args)) end)
end

-- The engine enables the map again, for example when the console closes, so it is locked in a loop.
local function lockInput()
	if screen.up then
		try("input lock", function() ActionMapManager.EnableActionMap("player", false) end)
		Script.SetTimer(LOCK_MS, lockInput)
	end
end

local function hideScreen()
	if not screen.up then
		return
	end
	screen.up = false
	hud("HideNarrativeSubtitles", TEXT_FADE_MS)
	hud("SetFaderState", FADE_OUT, "")
	try("input lock", function() ActionMapManager.EnableActionMap("player", true) end)
end

-- noScreen true leaves the screen as it is, for a mod that covers it on its own.
local function showScreen(noScreen)
	if noScreen then
		return
	end
	screen.gen = screen.gen + 1
	local gen = screen.gen
	if not screen.up then
		screen.up = true
		lockInput()
	end
	hud("SetFaderState", FADE_IN, "")
	hud("SetNarrativeSubtitles", FemaleCore.SCREEN_TEXT, TEXT_LAYOUT, TEXT_FADE_MS)
	Script.SetTimer(FemaleCore.SCREEN_MAX_MS, function()
		if screen.gen == gen then
			hideScreen()
		end
	end)
end

-- State

-- The id of the look she wears. 0 while Henry is a man. Skald keeps it in the save, and nothing shows in the inventory:
-- after a load, Lua asks and Skald answers with as many answer tokens as the id.
FemaleCore.current = 0

function FemaleCore.Current()
	return FemaleCore.current
end

function FemaleCore.IsWoman()
	return FemaleCore.current > 0
end

local function setCurrent(id)
	FemaleCore.current = id
end

-- After ml_ff_henry his head and body stay on as a look of the graph: a Commit with them in view did not give his head
-- back to his soul after hers. wasWoman says that Henry was a woman in this save.
local henryKept = false
local wasWoman = false
-- Her state woman, read on each load: it keeps her shift and her beard without a mesh on the soul.
local womanOn = false

local function count(class)
	return try("token", function() return player.inventory:GetCountOfClass(class) end) or 0
end

-- Skald answers with the id of the look, plus HENRY_KEPT_ANSWER and WAS_WOMAN_ANSWER when those are on.
local function askCurrent(after)
	sendToken(FemaleCore.ASK_TOKEN)
	Script.SetTimer(FemaleCore.TOKEN_MS + 200, function()
		local id = count(FemaleCore.ANSWER_ITEM)
		if id > 0 then
			try("token", function() player.inventory:DeleteItemOfClass(FemaleCore.ANSWER_ITEM, id) end)
		end
		womanOn = FemaleCore.WOMAN_ON_ANSWER ~= nil and id >= FemaleCore.WOMAN_ON_ANSWER
		if womanOn then
			id = id - FemaleCore.WOMAN_ON_ANSWER
		end
		wasWoman = id >= FemaleCore.WAS_WOMAN_ANSWER
		if wasWoman then
			id = id - FemaleCore.WAS_WOMAN_ANSWER
		end
		henryKept = id >= FemaleCore.HENRY_KEPT_ANSWER
		if henryKept then
			id = id - FemaleCore.HENRY_KEPT_ANSWER
		end
		-- A save where she became a woman with an older version does not have it on yet.
		wasWoman = wasWoman or id > 0
		setCurrent(id)
		after(id)
	end)
end

local function hairName(style, color)
	return string.format("ml_ff_hair_%03d_%s", style, FemaleCore.HAIR_COLORS[color])
end

FemaleCore.HairName = hairName

-- A hair of hers as a command or a mod gives it: a style from 1 to 7 and a color, by name or number, as
-- ml_ff_hair 5 blonde; the game's name of one of those, as LOOKS.md gives it, f_hair_005_blonde; or a hair of a woman
-- of the story, katherine or f_hair_katherine. Returns its name in the framework, and its style and color when it has
-- them, or nil.
local function resolveHair(style, color)
	local text = string.lower(tostring(style or ""))
	text = string.gsub(text, "^ml_ff_hair_", "")
	text = string.gsub(text, "^f_hair_", "")
	for _, named in ipairs(FemaleCore.NAMED_HAIRS) do
		if text == named then
			return "ml_ff_hair_" .. named
		end
	end
	local number, rest = string.match(text, "^(%d+)_(.+)$")
	if number then
		style, color = number, rest
	end
	style = tonumber(style)
	local colors = style and FemaleCore.HAIR_STYLES[style]
	local index = tonumber(color)
	for i, name in ipairs(FemaleCore.HAIR_COLORS) do
		if name == color then
			index = i
		end
	end
	if not (colors and index and index >= 1 and index <= colors) then
		return nil
	end
	return hairName(style, index), style, index
end

local function hairHelp(what)
	FemaleCore.Log("no hair " .. tostring(what) .. ": a style from 1 to " .. #FemaleCore.HAIR_STYLES .. " and a color from 1 to 9 or by name,",
		table.concat(FemaleCore.HAIR_COLORS, ", ") .. " (style 3 has no dark_grey, grey or white), as 5 blonde or f_hair_005_blonde;",
		"or one of", table.concat(FemaleCore.NAMED_HAIRS, ", "))
end

local function withBarber(label, fn)
	try(label, function()
		local barber = Barber:Create(player.soul)
		fn(barber)
		barber:Commit()
		Barber:Destroy(barber)
	end)
end

-- Two hair changes, in case one is the hair in use, and back: the model rebuilds and shows the overrides, with her hair.
-- With Henry back as a man, men's hair.
local function rebuild(after)
	local hairs = FemaleCore.WomanInUse() and FemaleCore.REBUILD_HAIRS or FemaleCore.HENRY_REBUILD_HAIRS
	local barber = try("rebuild", function()
		local object = Barber:Create(player.soul)
		object:TryHair(hairs[1])
		return object
	end)
	Script.SetTimer(FemaleCore.REBUILD_MS, function()
		try("rebuild", function() barber:TryHair(hairs[2]) end)
		Script.SetTimer(FemaleCore.REBUILD_MS, function()
			try("rebuild", function()
				barber:Revert()
				Barber:Destroy(barber)
			end)
			FemaleCore.Log("rebuilt")
			if after then
				after()
			end
		end)
	end)
end

-- The buff ml_ff_woman tells the game's scenes that the framework ships (FRAMEWORK_DEVELOPER_GUIDE.md) that
-- Henry is a woman, so they leave his head, body and breeches off her. Her graph keeps it on, but after a load a scene
-- can look before it is back, and the bandaged body came back at Bozhena's. So it goes off and on again here,
-- and each scene hears it arrive. Only on Henry: a scene of his story is never on the character of another mod.
FemaleCore.WOMAN_BUFF = "0571294f-90a1-599c-9d29-98d1e26c5ffc"

local function markWoman(on)
	local ok, other = pcall(FemaleCore.OtherCharacter)
	if ok and other then
		return
	end
	try("woman mark", function()
		player.soul:RemoveAllBuffsByGuid(FemaleCore.WOMAN_BUFF)
		if on then
			player.soul:AddBuff(FemaleCore.WOMAN_BUFF)
		end
	end)
end

-- Clothes

local notices = {}
local showing = false

-- Several kinds of clothes can come off at once, and each notice would cover the one before it.
local function showNotice()
	local text = table.remove(notices, 1)
	showing = text ~= nil
	if text then
		try("notice", function() Game.SendInfoText(text, false, nil, FemaleCore.NOTICE_SECONDS) end)
		Script.SetTimer(FemaleCore.NOTICE_SECONDS * 1000, showNotice)
	end
end

-- A copy is another item, so a piece that was on comes off when it changes. When the look chosen before the start goes
-- on, everything Henry has on him is what he wears: then each copy goes on as it is made, or she would be naked in the
-- first cutscene. Later the change cannot know what was on, since Lua does not read what is equipped: the item has
-- only health, amount, id, class and entity, and UnequipInventoryItem returns nothing, on or off.
FemaleCore.wearChanges = false

local function inventoryIds()
	local ids = {}
	for _, id in pairs(player.inventory:GetInventoryTable() or {}) do
		ids[tostring(id)] = id
	end
	return ids
end

-- Henry's soul is a man's, which cannot wear the F_* items of the game, so each one that reaches her inventory changes
-- for its copy, with the same health. Shops keep their items.
local function changeClothes()
	local wear = FemaleCore.wearChanges
	FemaleCore.wearChanges = false
	local seen, changed, quest = 0, 0, 0
	for _, id in pairs(player.inventory:GetInventoryTable() or {}) do
		local item = ItemManager.GetItem(id)
		local copy = item and FemaleCore.CLOTHES[item.class]
		seen = seen + 1
		if item and not copy and (FemaleCore.FITTED_ALIASES or {})[tostring(item.class)] then
			quest = quest + 1
		end
		if copy then
			changed = changed + 1
			local before = wear and inventoryIds()
			player.inventory:CreateItem(copy, item.health or 1, 1)
			if wear then
				for key, made in pairs(inventoryIds()) do
					if not before[key] then
						try("wear copy", function() player.actor:EquipInventoryItem(made) end)
						break
					end
				end
			end
			player.inventory:DeleteItem(id, -1)
			FemaleCore.Log("clothes changed", item.class, wear and "and put on" or "")
		end
	end
	-- At the start of a game as a woman, what Lua saw: in the prologue Henry's gear did not change.
	if wear then
		FemaleCore.Log("clothes at the start:", seen, "items in the inventory,", changed, "with a copy for her,", quest,
			"of the story")
	end
end

-- Henry's gear in the prologue is the quest's own: aliases of the game's pieces, weightless, which the quest looks for in
-- the inventory and takes away at the ambush. Swapped, the quest would lose them. She gets an alias of her own
-- for each one, weightless too, with her copy as its source (FITTED_ALIASES, fitted_gear.py), and it goes on over the
-- quest's, which stays in the bag. Only once she has full control: no cutscene, no dialogue and no horse for
-- STORY_GEAR_SETTLE ticks, as the cutscenes of the start would show her changing. When the quest takes its alias, hers
-- goes too; a man has no use for hers.
FemaleCore.QUEST_GEAR_TEXT = "@ml_ff_quest_gear"
FemaleCore.STORY_GEAR_SETTLE = 5
local controlTicks = 0
local ridingLogged = false

-- IsOnHorse is not a Lua call: on human and on actor it failed. player.human:GetHorse gives her horse, ridden or
-- not: it said riding all the game. She rides it when she is on it: within RIDING_REACH of its position, across.
-- Standing by its side she is further, past the half of its body and hers. The log says it, with how far across and how
-- much higher she is, each time it changes, to set the reach from the game.
FemaleCore.RIDING_REACH = 0.5

local function riding()
	local ok, horse = pcall(function()
		local id = player.human:GetHorse()
		return id and System.GetEntity(id)
	end)
	local on, across, up = false, nil, nil
	if ok and horse and horse.GetWorldPos then
		-- Read each one at once: the engine may give the same table to both calls.
		local a = horse:GetWorldPos()
		local hx, hy, hz = a.x, a.y, a.z
		local b = player:GetWorldPos()
		across = math.sqrt((hx - b.x) ^ 2 + (hy - b.y) ^ 2)
		up = b.z - hz
		on = across < FemaleCore.RIDING_REACH
	end
	if not ridingLogged or on ~= ridingLogged.on then
		ridingLogged = { on = on }
		FemaleCore.Log("horse check:", ok and (horse and "her horse" or "no horse") or tostring(horse), "- across",
			across and string.format("%.2f", across) or "-", "up", up and string.format("%.2f", up) or "-", "- riding:", on)
	end
	return on
end

-- The same cvar as inCutscene below, which the start of a game waits for (CUTSCENE_CVAR).
local function inCutsceneNow()
	local value = try("cutscene", System.GetCVar, FemaleCore.CUTSCENE_CVAR)
	return tonumber(value) == 1
end

local function fullControl()
	local talking = try("story gear dialog", function() return player.human:IsInDialog() end)
	return not inCutsceneNow() and not talking and not riding()
end

local function storyGear(woman)
	local aliases = FemaleCore.FITTED_ALIASES or {}
	local quest, mine = {}, {}
	local ours = {}
	for questAlias, herAlias in pairs(aliases) do
		ours[herAlias] = questAlias
	end
	for _, id in pairs(player.inventory:GetInventoryTable() or {}) do
		local item = ItemManager.GetItem(id)
		local class = item and tostring(item.class)
		if class and aliases[class] then
			quest[class] = item
		elseif class and ours[class] then
			mine[class] = id
		end
	end
	-- Hers go with the quest's, and off a man.
	for class, id in pairs(mine) do
		if not woman or not quest[ours[class]] then
			try("story gear", function() player.inventory:DeleteItem(id, -1) end)
			FemaleCore.Log("story gear taken back:", class)
			mine[class] = nil
		end
	end
	local missing = {}
	for class, item in pairs(quest) do
		if woman and not mine[aliases[class]] then
			missing[#missing + 1] = item
		end
	end
	if #missing == 0 or FemaleCore.storyGearFailed then
		controlTicks = 0
		return
	end
	controlTicks = fullControl() and controlTicks + 1 or 0
	if controlTicks < FemaleCore.STORY_GEAR_SETTLE then
		return
	end
	controlTicks = 0
	-- As the swap does: hers goes on, and the quest's comes off its slot; it stays in the bag.
	local made = 0
	for _, item in ipairs(missing) do
		local before = inventoryIds()
		try("story gear", function() player.inventory:CreateItem(aliases[tostring(item.class)], item.health or 1, 1) end)
		for key, id in pairs(inventoryIds()) do
			if not before[key] then
				made = made + 1
				try("wear story gear", function() player.actor:EquipInventoryItem(id) end)
				break
			end
		end
	end
	FemaleCore.Log("story gear: hers made and put on, over the quest's:", made, "of", #missing)
	if made == 0 then
		-- Nothing came: no use trying again every few seconds.
		FemaleCore.storyGearFailed = true
		return
	end
	if not FemaleCore.questGearTold then
		FemaleCore.questGearTold = true
		notices[#notices + 1] = FemaleCore.QUEST_GEAR_TEXT
	end
end

-- A man cannot keep what was refitted for her from a man's piece: the fitted gear (FITTED_GEAR.md) and the pieces other
-- mods register with back. Each one that reaches his inventory turns back into the game's piece, with the same
-- health. A copy of a woman's garment has no back: the rules of the graph take it off him.
FemaleCore.BACK = FemaleCore.BACK or {}

local function changeBack()
	for _, id in pairs(player.inventory:GetInventoryTable() or {}) do
		local item = ItemManager.GetItem(id)
		local original = item and FemaleCore.BACK[item.class]
		if original then
			player.inventory:CreateItem(original, item.health or 1, 1)
			player.inventory:DeleteItem(id, -1)
			FemaleCore.Log("clothes changed back", item.class)
		end
	end
end

-- Developer mode: ml_developer registers the test commands of the framework until the game closes, as it does for
-- KCD2 Life and KCD2 Male Framework, which register the same command. Each one turns on all three, so any works
-- alone or with the others.
FemaleCore.DEVELOPER = {
	{ "ml_ff_fitted_give", "FemaleCore.GiveFittedGear(%line)", "Test: gives the game's pieces of the fitted gear, which turn into her copies, or with copies the copies, for a man. A word gives only the pieces whose name has it, like ml_ff_fitted_give cuirass" },
	{ "ml_ff_npc_dress", "FemaleCore.NpcDressCommand(%line)", "Test: puts an item on the nearest woman NPC, by its name, like ml_ff_npc_dress Cuirass03_m03_A5, or its copy for her, Cuirass03_m03_A5_ff. It knows the fitted gear and the clothes other mods register with their names" },
	{ "ml_ff_fitted_test", "FemaleCore.GiveFittedTest()", "Test: gives the pieces to try the fitted gear with: tunics, hose, a short pourpoint, a hood, leg plates, a cuirass, Legate's robe, Bergov's coat and the jester's coat. A woman gets her copies, a man the game's pieces" },
	{ "ml_ff_start_character", "FemaleCore.StartCharacterCommand(%line)", "Test: a start character, as a mod registers it: her look, at every start of the game, new or loaded, like ml_ff_start_character woman_czech_2 5 blonde" },
	{ "ml_ff_inventory", "FemaleCore.LogInventory()", "Test: writes in kcd.log each item of the inventory that the framework sees, by its id, and whether it has a copy for her or is one" },
	{ "ml_ff_fitted_showcase", "FemaleCore.GiveFittedShowcase(%line)", "Test: gives each kind of garment of the fitted gear in a few colours, to show them: tunics, gambesons, coats, mail, plate, hose and hoods. A number gives that many colours of each, like ml_ff_fitted_showcase 5; 3 if not" },
}

function FemaleCore.Developer()
	if FemaleCore.developer then
		return
	end
	FemaleCore.developer = true
	for _, command in ipairs(FemaleCore.DEVELOPER) do
		try("command " .. command[1], function() System.AddCCommand(command[1], command[2], command[3]) end)
	end
	FemaleCore.Log("developer mode on:", #FemaleCore.DEVELOPER, "test commands until the game closes")
end

function FemaleCore.DeveloperCommand()
	FemaleCore.Developer()
	if MaleCore and MaleCore.Developer then
		try("KCD2 Male Framework developer mode", MaleCore.Developer)
	end
	if MedievalLife and MedievalLife.Commands and MedievalLife.Commands.Developer then
		try("KCD2 Life developer mode", MedievalLife.Commands.Developer)
	end
end

-- ml_ff_fitted_give [word] [copies]: the game's pieces of the fitted gear whose name has the word, or all, in the
-- inventory, where the swap turns them into her copies while she is a woman. With copies, the copies themselves: a man
-- gets the game's pieces back.
function FemaleCore.GiveFittedGear(line)
	local filter, copies = nil, false
	for word in string.gmatch(string.lower(tostring(line or "")), "%S+") do
		if word == "copies" then
			copies = true
		else
			filter = word
		end
	end
	local given = 0
	for original, copy in pairs(FemaleCore.FITTED_GEAR or {}) do
		local name = string.lower((FemaleCore.FITTED_GEAR_NAMES or {})[original] or "")
		if not filter or string.find(name, filter, 1, true) then
			try("give", function() player.inventory:CreateItem(copies and copy or original, 1, 1) end)
			given = given + 1
		end
	end
	FemaleCore.Log("fitted gear given:", given, copies and "copies" or "pieces of the game", filter and ("with " .. filter) or "")
end

-- The pieces to try the fitted gear with (02), by the names of the game's items.
FemaleCore.FITTED_TEST = {
	"TunicShort05_m01_D", "TunicLong02_m01_C", "HoseJoined02_m01_B", "GambesonShort03_m01_A4", "Hood05_m01_B",
	"LegsPlate03_m01_A5", "Cuirass03_m01_A5", "HabitLegate_m01", "CoatBergov_m01", "Coat06_m01_C",
}

-- A garment of each kind for the showcase, from the shirt to the plate, and how many of its colours by default.
FemaleCore.FITTED_SHOWCASE = {
	"TunicShort05", "TunicLong02", "GambesonShort04", "GambesonLong01", "Caftan02", "Coat11", "Waffenrock01", "Habit01",
	"MailShort02", "MailLong01", "Brigandine05", "Cuirass07", "ArmPlate02", "BrigandineArm06", "HoseJoined02",
	"HoseSeparate01", "LegsPadded01", "LegsBrigandine03", "LegsPlate03", "Hood05", "Hood12", "CoifLarge02", "CoifMail01",
	"CollarChain01",
}
FemaleCore.SHOWCASE_COLOURS = 3

-- Gives the game's items of the list, by their ids. A woman gets her copies, which need no swap: the swap waits while
-- the console or the inventory is open, since the game stops then, and a piece put on before it comes off.
local function giveFitted(originals, label)
	local woman = FemaleCore.WomanInUse and FemaleCore.WomanInUse()
	local given = 0
	for _, original in ipairs(originals) do
		local class = woman and (FemaleCore.FITTED_GEAR or {})[original] or original
		if try("give", function() player.inventory:CreateItem(class, 1, 1) return true end) then
			given = given + 1
		end
	end
	FemaleCore.Log(label, given, woman and "copies" or "pieces of the game")
end

local function fittedByName()
	local byName = {}
	for original, name in pairs(FemaleCore.FITTED_GEAR_NAMES or {}) do
		byName[string.lower(name)] = original
	end
	return byName
end

-- ml_ff_inventory: each item Lua sees in the inventory. In the prologue, Henry's gear did not change for her copies, and
-- this tells whether it is there for the swap to see.
function FemaleCore.LogInventory()
	local total, copies, ours = 0, 0, 0
	for _, id in pairs(player.inventory:GetInventoryTable() or {}) do
		local item = ItemManager.GetItem(id)
		if item then
			total = total + 1
			local class = tostring(item.class)
			local copy = FemaleCore.CLOTHES[item.class]
			local back = FemaleCore.BACK[item.class]
			copies = copies + (copy and 1 or 0)
			ours = ours + (back and 1 or 0)
			FemaleCore.Log("inventory:", class, (FemaleCore.FITTED_GEAR_NAMES or {})[class] or "",
				copy and "- has a copy for her" or (back and "- is a copy" or ""))
		end
	end
	FemaleCore.Log("inventory:", total, "items,", copies, "with a copy for her,", ours, "copies")
end

-- ml_ff_fitted_test: the pieces of FITTED_TEST.
function FemaleCore.GiveFittedTest()
	local byName, originals = fittedByName(), {}
	for _, name in ipairs(FemaleCore.FITTED_TEST) do
		local original = byName[string.lower(name)]
		if original then
			originals[#originals + 1] = original
		else
			FemaleCore.Log("fitted test: no piece named", name)
		end
	end
	giveFitted(originals, "fitted test given:")
end

-- ml_ff_fitted_showcase [colours]: each garment of FITTED_SHOWCASE in its first colours, by their number (_m01, _m02...),
-- and then its named variants (_mBergov...) if it has fewer.
function FemaleCore.GiveFittedShowcase(line)
	local colours = tonumber(string.match(tostring(line or ""), "(%d+)")) or FemaleCore.SHOWCASE_COLOURS
	local byName, originals = fittedByName(), {}
	for _, garment in ipairs(FemaleCore.FITTED_SHOWCASE) do
		local prefix = string.lower(garment) .. "_m"
		local found = {}
		for name, original in pairs(byName) do
			if string.sub(name, 1, #prefix) == prefix then
				local number = tonumber(string.match(string.sub(name, #prefix + 1), "^(%d+)"))
				found[#found + 1] = { number = number or 1000, name = name, original = original }
			end
		end
		table.sort(found, function(a, b)
			if a.number ~= b.number then
				return a.number < b.number
			end
			return a.name < b.name
		end)
		-- One item for each colour: a colour can have variants of its own, like _m01_C3 and _m01_C3_KHtournament_Henry.
		local picked, used = 0, {}
		for _, entry in ipairs(found) do
			if picked >= colours then
				break
			end
			if entry.number == 1000 or not used[entry.number] then
				used[entry.number] = true
				originals[#originals + 1] = entry.original
				picked = picked + 1
			end
		end
		if #found == 0 then
			FemaleCore.Log("fitted showcase: no piece of", garment)
		end
	end
	giveFitted(originals, "fitted showcase given:")
end

-- Dresses an NPC, a companion of another mod for one: each item class of the list goes into its inventory and on it. Returns how many went on. Not for the player: her clothes swap on their own.
function FemaleCore.DressNpc(entity, classes)
	local dressed = 0
	if not (entity and entity.inventory and entity.actor) then
		FemaleCore.Log("dress npc: not an NPC")
		return 0
	end
	for _, class in ipairs(type(classes) == "table" and classes or { classes }) do
		local ok = try("dress npc", function()
			local id = entity.inventory:CreateItem(class, 1, 1)
			entity.actor:EquipInventoryItem(id)
			return true
		end)
		dressed = dressed + (ok and 1 or 0)
	end
	FemaleCore.Log("dress npc", tostring(entity:GetName()), dressed, "of", #(type(classes) == "table" and classes or { classes }))
	return dressed
end

FemaleCore.NPC_DRESS_RANGE = 10

-- ml_ff_npc_dress <name>: the nearest woman NPC, within NPC_DRESS_RANGE metres, gets the item of that name, as the
-- item table and wh_cheat_addItem name it. Lua cannot find an item by its name, so only the names the framework knows
-- work (ITEM_NAMES): the pieces of the fitted gear and their copies, <name>_ff, and the clothes other mods register
-- with their names. Any other name says it cannot be put on.
function FemaleCore.NpcDressCommand(line)
	local name = string.match(tostring(line or ""), "^%s*(%S+)")
	if not name then
		FemaleCore.Log("ml_ff_npc_dress needs the name of an item, like ml_ff_npc_dress Cuirass03_m03_A5")
		return
	end
	local class = FemaleCore.ITEM_NAMES[string.lower(name)]
	if not class then
		FemaleCore.Log(name .. ": KCD2 Female Framework does not know an item of that name, so it cannot be put on. It knows "
			.. "the fitted gear and the clothes other mods register with their names (MAKING_CLOTHES.md)")
		return
	end
	local position, nearest, best = player:GetWorldPos(), nil, nil
	for _, entity in pairs(System.GetEntitiesInSphereByClass(position, FemaleCore.NPC_DRESS_RANGE, "NPC_Female") or {}) do
		local other = entity:GetWorldPos()
		local distance = (other.x - position.x) ^ 2 + (other.y - position.y) ^ 2
		if not best or distance < best then
			nearest, best = entity, distance
		end
	end
	if not nearest then
		FemaleCore.Log("no woman NPC within", FemaleCore.NPC_DRESS_RANGE, "m")
		return
	end
	FemaleCore.Log("dressing", tostring(nearest:GetName()), "with", name)
	if FemaleCore.DressNpc(nearest, { class }) == 0 then
		FemaleCore.Log(name .. ": it could not be put on " .. tostring(nearest:GetName()))
	end
end

-- The item names the framework knows, in lower case, and their class: Lua cannot find an item by its name.
FemaleCore.ITEM_NAMES = FemaleCore.ITEM_NAMES or {}

local function knowName(name, class)
	if type(name) == "string" and type(class) == "string" then
		FemaleCore.ITEM_NAMES[string.lower(name)] = class
	end
end

-- Clothes for her from other mods (MAKING_CLOTHES.md): each entry is the item of the game, or of the mod, and its copy
-- that she can wear, { original = id, copy = id }, and name and copy_name, their item names, to find them by name. With
-- back = true, the original is a man's piece, and a man gets it back. A garment that already has a copy keeps it.
-- source names the mod in the log. Returns how many were taken.
function FemaleCore.RegisterClothes(list, source)
	FemaleCore.CLOTHES = FemaleCore.CLOTHES or {}
	local count = 0
	for _, entry in ipairs(type(list) == "table" and list or {}) do
		local original, copy = entry.original, entry.copy
		if type(original) == "string" and type(copy) == "string" then
			-- name and copy_name, the item names of both, are optional: ml_ff_npc_dress finds them by those.
			knowName(entry.name, original)
			knowName(entry.copy_name, copy)
			FemaleCore.CLOTHES[original] = FemaleCore.CLOTHES[original] or copy
			if entry.back then
				FemaleCore.BACK[copy] = original
			end
			count = count + 1
		end
	end
	FemaleCore.Log("clothes of", tostring(source or "a mod") .. ":", count)
	return count
end

-- No event is known for an item that arrives, so the inventory is looked at once a second.
local tickGen = 0

-- The id of the look of the new character of KCD2 Life, when she is a woman, and 0 when not. KCD2 Life says it.
FemaleCore.newCharacter = 0

-- Whether the character in use is a woman: Henry, or the new character of a mod that plays its own.
local function womanInUse()
	local ok, other = pcall(FemaleCore.OtherCharacter)
	if ok and other then
		return FemaleCore.newCharacter > 0
	end
	return FemaleCore.current > 0
end

FemaleCore.WomanInUse = womanInUse

local function tick(gen)
	if gen ~= tickGen then
		return
	end
	if FemaleCore.Barber then
		try("barber", FemaleCore.Barber.Update)
	end
	if womanInUse() then
		try("clothes", changeClothes)
	elseif next(FemaleCore.BACK) then
		try("clothes back", changeBack)
	end
	if next(FemaleCore.FITTED_ALIASES or {}) then
		try("story gear", storyGear, womanInUse())
	end
	-- The rules also take a woman's clothes off a man of KCD2 Life.
	for class, text in pairs(FemaleCore.STRIPPED) do
		if takeToken(class) then
			notices[#notices + 1] = text
			FemaleCore.Log("clothes taken off", text)
		end
	end
	if not showing then
		showNotice()
	end
	if FemaleCore.CutsceneDoubles then
		try("cutscene doubles", FemaleCore.CutsceneDoubles)
	end
	-- A scene of the game that dresses her with a PlayerOutfitOverride gives this when the outfit goes on and when it comes
	-- off. The outfit goes on the model without her overrides, and a rebuild puts them back: a load in the middle of the
	-- pillory showed her right. KCD2 Male Framework ships the same scene and the same token, for a face of
	-- its own: this one takes it while a woman is in use, and always when KCD2 Male Framework is not there.
	local mine = womanInUse() or not (MaleCore and MaleCore.LOADED)
	if FemaleCore.REBUILD_TOKEN and mine and takeToken(FemaleCore.REBUILD_TOKEN) and womanInUse() then
		FemaleCore.Log("an outfit of a scene changed: rebuild")
		rebuild()
	end
	Script.SetTimer(FemaleCore.TICK_MS, function() tick(gen) end)
end

local function startTick()
	tickGen = tickGen + 1
	tick(tickGen)
end

-- Looks

-- FemaleCore.LOOKS is a list in menu order. Each look keeps its id, shared with KCD2 Male Framework, so the ids of the
-- women are not one after another. soul is the model with that look, for a mod that shows it before choosing, and style
-- and color are the hair it starts with. characters are the characters of the game with a name of their own who wear its
-- face, as in LOOKS.md.
local function copy(look)
	return look and { id = look.id, name = look.name, ethnicity = look.ethnicity, age = look.age, villager = look.villager,
		soul = look.soul, style = look.style, color = look.color, outside = look.outside, characters = { unpack(look.characters or {}) } }
end

local function find(key)
	for _, look in ipairs(FemaleCore.LOOKS) do
		if look.name == key or tostring(look.id) == tostring(key) then
			return look
		end
	end
	return nil
end

function FemaleCore.GetLook(id)
	return copy(find(id))
end

-- Only women: with FemaleCore.MAN the list is empty.
function FemaleCore.ListLooks(gender)
	local list = {}
	if gender ~= FemaleCore.MAN then
		for _, look in ipairs(FemaleCore.LOOKS) do
			list[#list + 1] = copy(look)
		end
	end
	return list
end

-- The faces of other mods (MAKING_FACES.md): a face pack, written by tools/make_face_pack.py, has its own tokens and
-- its own Skald project, and its Lua file in Scripts/FemaleCore/Looks registers them here. The save keeps a look by its id,
-- shared with KCD2 Male Framework, and the answer adds 500 and more to it, so the ids of a pack go from OUTSIDE_FIRST to
-- OUTSIDE_LAST, in blocks of ten that the tool chooses. A look that clashes, by id or by name, is left out, and the log
-- says it. Returns how many went in.
FemaleCore.OUTSIDE_FIRST, FemaleCore.OUTSIDE_LAST = 200, 499

local function idTaken(id)
	if find(id) then
		return "KCD2 Female Framework"
	end
	for _, look in ipairs(MaleCore and MaleCore.LOOKS or {}) do
		if look.id == id then
			return "KCD2 Male Framework"
		end
	end
	return nil
end

function FemaleCore.RegisterLooks(pack, looks)
	local added = 0
	for _, look in ipairs(type(looks) == "table" and looks or {}) do
		local id, name = tonumber(look.id), look.name
		local problem
		if type(name) ~= "string" or type(look.token) ~= "string" then
			problem = "it needs a name and a token"
		elseif not id or id ~= math.floor(id) or id < FemaleCore.OUTSIDE_FIRST or id > FemaleCore.OUTSIDE_LAST then
			problem = string.format("its id %s is not between %d and %d", tostring(look.id), FemaleCore.OUTSIDE_FIRST, FemaleCore.OUTSIDE_LAST)
		elseif find(name) then
			problem = "a look has that name already"
		elseif idTaken(id) then
			problem = "id " .. id .. " is taken in " .. idTaken(id)
		end
		if problem then
			FemaleCore.Log("look", tostring(name), "of", tostring(pack), "left out:", problem)
		else
			FemaleCore.LOOKS[#FemaleCore.LOOKS + 1] = {
				id = id, name = name, ethnicity = look.ethnicity, age = look.age or "young", villager = false,
				style = tonumber(look.style) or 1, color = tonumber(look.color) or 1, token = look.token,
				characters = type(look.characters) == "table" and look.characters or {}, outside = tostring(pack),
			}
			added = added + 1
		end
	end
	FemaleCore.Log("looks of", tostring(pack) .. ":", added)
	return added
end

function FemaleCore.FindLook(name)
	return copy(find(name))
end

-- Her hair while the framework knows it: what it put on, or what she chose at a barber. A load forgets it, and the soul
-- keeps the hair itself.
local hair = nil

-- A hair of a woman of the story has no style for the barber: then her hair is not known.
function FemaleCore.RememberHair(style, color)
	hair = style and { style = style, color = color } or nil
end

-- Her hair: a style, a color and whether it is known. When it is not, the hair her look starts with.
function FemaleCore.Hair()
	if hair then
		return hair.style, hair.color, true
	end
	local ok, other = pcall(FemaleCore.OtherCharacter)
	local look = find((ok and other) and FemaleCore.newCharacter or FemaleCore.current)
	if look then
		return look.style, look.color, false
	end
	return 2, 1, false
end

-- Henry becomes a woman, with that look: a name or an id. Without one, the first look. She stays one until Henry().
function FemaleCore.BecomeWoman(name, noScreen, hairStyle, hairColor)
	if notHenry() then
		return false
	end
	if FemaleCore.IsWoman() then
		if name then
			return FemaleCore.SetLook(name, noScreen, hairStyle, hairColor)
		end
		FemaleCore.Log("Henry is a woman already: ml_ff_look changes her look")
		return false
	end
	local look = name and find(name) or FemaleCore.LOOKS[1]
	if not look then
		FemaleCore.Log("no look called", name, "- ml_ff_looks lists them")
		return false
	end
	-- A hair given instead of the look's.
	local mesh, style, color = nil, look.style, look.color
	if hairStyle then
		mesh, style, color = resolveHair(hairStyle, hairColor)
		if not mesh then
			hairHelp(hairStyle)
			style, color = look.style, look.color
		end
	end
	mesh = mesh or hairName(look.style, look.color)
	FemaleCore.Log("Henry becomes a woman, look", look.name, "id", look.id, "hair", mesh)
	showScreen(noScreen)
	-- A face of KCD2 Male Framework would cover hers.
	if MaleCore and MaleCore.TakeOff then
		try("male look", MaleCore.TakeOff)
	end
	-- Barber:Commit keeps the head it sees in the soul, so her hair goes on while his head still shows.
	withBarber("woman parts", function(barber)
		barber:TryBeard(FemaleCore.SAFE_BEARD)
		barber:TryHair(mesh)
	end)
	FemaleCore.RememberHair(style, color)
	-- Her token also takes off his head and body, if they were kept on after ml_ff_henry.
	sendLookToken(look)
	setCurrent(look.id)
	markWoman(true)
	henryKept = false
	wasWoman = true
	Script.SetTimer(FemaleCore.TOKEN_MS + 200, function()
		rebuild(function()
			startTick()
			FemaleCore.Log("Henry is a woman")
			hideScreen()
		end)
	end)
	return true
end

-- The head and the body of a look on her. after runs once the model shows them, before the screen clears.
local function putLook(look, noScreen, after)
	FemaleCore.Log("look", look.name, "id", look.id)
	showScreen(noScreen)
	sendToken(FemaleCore.RESET_TOKEN)
	Script.SetTimer(FemaleCore.TOKEN_MS + 200, function()
		sendLookToken(look)
		setCurrent(look.id)
		Script.SetTimer(FemaleCore.TOKEN_MS + 200, function()
			rebuild(function()
				if after then
					after()
				end
				hideScreen()
			end)
		end)
	end)
end


-- She takes the head and the body of that look: a name or an id. Her hair stays, unless a hair is given, as SetHair
-- takes it.
-- From Henry, or from a face of KCD2 Male Framework, it makes him a woman with that look, as ml_mf_look gives him a
-- face straight away.
function FemaleCore.SetLook(name, noScreen, hairStyle, hairColor)
	if notHenry() then
		return false
	end
	local look = name and find(name)
	if not look then
		FemaleCore.Log("no look called", name, "- ml_ff_looks lists them")
		return false
	end
	if not FemaleCore.IsWoman() then
		return FemaleCore.BecomeWoman(look.name, noScreen, hairStyle, hairColor)
	end
	putLook(look, noScreen, hairStyle and function() FemaleCore.SetHair(hairStyle, hairColor) end or nil)
	return true
end

-- A look at random among all but hers, with the hair it starts with. Returns that look, or nil.
function FemaleCore.SetRandomLook(noScreen)
	if notHenry() then
		return nil
	end
	local choices = {}
	for _, look in ipairs(FemaleCore.LOOKS) do
		if look.id ~= FemaleCore.Current() then
			choices[#choices + 1] = look
		end
	end
	if #choices == 0 then
		return nil
	end
	local look = choices[math.random(#choices)]
	-- From Henry, she becomes a woman with it, and with its hair.
	if not FemaleCore.IsWoman() then
		return FemaleCore.BecomeWoman(look.name, noScreen) and copy(look) or nil
	end
	putLook(look, noScreen, function() FemaleCore.SetHair(look.style, look.color) end)
	return copy(look)
end

-- Her hair: a style from 1 to 7 and a color, by name or number, the game's name of one, or a hair of a woman of the
-- story (resolveHair). Hair only: no beard.
function FemaleCore.SetHair(style, color)
	if notHenry() then
		return false
	end
	if not FemaleCore.IsWoman() then
		FemaleCore.Log("Henry is not a woman yet: ml_ff_look first")
		return false
	end
	local mesh, number, index = resolveHair(style, color)
	if not mesh then
		hairHelp(style)
		return false
	end
	withBarber("hair", function(barber) barber:TryHair(mesh) end)
	FemaleCore.RememberHair(number, index)
	FemaleCore.Log("hair", mesh)
	return true
end

-- The new character of KCD2 Life, its playable soul ml_player. The commands do nothing with it,
-- and KCD2 Life calls these. Before SwitchPlayer, Henry gets the token of that character's look. KCD2 Life gives Henry
-- NEW_STARTED_TOKEN when the switch ends, and Skald turns the look on then.
function FemaleCore.ChooseNewCharacter(name)
	local look = find(name)
	if not look then
		FemaleCore.Log("no look called", name, "for the new character")
		return false
	end
	if not look.new_token then
		FemaleCore.Log(look.name, "is a look of", tostring(look.outside), "and has no token for the new character of KCD2 Life")
		return false
	end
	FemaleCore.Log("new character look", look.name, "id", look.id)
	sendToken(look.new_token)
	return true
end

-- Once the new character is in use: her hair, a style and a color, or the look's, and a rebuild that shows the look.
-- after runs at the end.
function FemaleCore.ShowNewCharacter(name, style, color, after)
	local look = find(name)
	if not look then
		FemaleCore.Log("no look called", name, "for the new character")
		return false
	end
	FemaleCore.newCharacter = look.id
	rebuild(function()
		withBarber("new character hair", function(barber)
			barber:TryBeard(FemaleCore.SAFE_BEARD)
			barber:TryHair(hairName(style or look.style, color or look.color))
		end)
		FemaleCore.RememberHair(style or look.style, color or look.color)
		if after then
			after()
		end
	end)
	return true
end

-- KCD2 Life says, after every load and every map, the look of its new character if she is a woman, and 0 if not: her
-- clothes change for the copies she can wear.
function FemaleCore.UseNewCharacter(id)
	FemaleCore.newCharacter = id or 0
end

-- The copy of a woman's item of the game that she can wear, or nil.
function FemaleCore.CopyOf(class)
	return FemaleCore.CLOTHES[class]
end

-- Her next haircut at a barber of the game is free, so a new character can choose her hair. Call it while Henry is the
-- player, before SwitchPlayer: the token goes to Henry's inventory, where the barber graph listens.
function FemaleCore.GiveFreeHaircut()
	sendToken(FemaleCore.FREE_HAIRCUT_TOKEN)
	FemaleCore.Log("next haircut free")
end

-- With Realish Economy, the game's barber asks 5 groschen instead of 50, in its price.xml, and so does hers. The
-- mod is known by one of its files, which System.IsFileExist also finds inside the paks of mods. A token for a moment
-- tells ml_ff_barber.xml, and the price stays in its state.
FemaleCore.LOW_PRICE_FILE = "Libs/Tables/item/item__realisheconomy.xml"

local function sendPrice()
	local found = try("barber price", function() return System.IsFileExist(FemaleCore.LOW_PRICE_FILE) end)
	local low = found == true or found == 1
	sendToken(low and FemaleCore.PRICE_LOW_TOKEN or FemaleCore.PRICE_GAME_TOKEN)
	FemaleCore.Log("barber price:", low and "5 groschen, with Realish Economy" or "50 groschen")
end

-- She becomes Henry again: his head, body and hair, with no beard. His head and body go on as one more look and stay
-- on, as long as he is a man. KCD2 Male Framework gives his face back with a Commit made with them in view, but after a
-- woman's head that left her face with his hair, so here they are not taken off. The
-- Commit is still made, for his hair and beard. Her clothes come off by the rules of the graph, with a notice.
-- after runs once he is back, before the screen clears: KCD2 Male Framework puts a face of its own on him then, straight
-- from a woman.
function FemaleCore.Henry(noScreen, after)
	if notHenry() then
		return false
	end
	if not FemaleCore.IsWoman() then
		FemaleCore.Log("Henry is not a woman: nothing to do")
		return false
	end
	FemaleCore.Log("back to Henry: his head and body go on as a look, and stay on")
	showScreen(noScreen)
	sendToken(FemaleCore.RESET_TOKEN)
	setCurrent(0)
	markWoman(false)
	hair = nil
	Script.SetTimer(FemaleCore.TOKEN_MS + 200, function()
		sendToken(FemaleCore.HENRY_TOKEN)
		henryKept = true
		wasWoman = true
		Script.SetTimer(FemaleCore.TOKEN_MS + 200, function()
			rebuild(function()
				withBarber("henry parts", function(barber)
					barber:TryBeard(FemaleCore.HENRY_BEARD)
					barber:TryHair(FemaleCore.HENRY_HAIR)
				end)
				FemaleCore.Log("Henry is back")
				if after then
					try("after Henry", after)
				end
				hideScreen()
			end)
		end)
	end)
	return true
end

-- For KCD2 Male Framework, before it puts on a look of its own: Henry's head and body, kept on after ml_ff_henry, come
-- off, so they do not cover it.
function FemaleCore.TakeOffHenry()
	if henryKept then
		FemaleCore.Log("his head and body come off, for a look of KCD2 Male Framework")
		sendToken(FemaleCore.RESET_TOKEN)
		henryKept = false
	end
end

-- For KCD2 Male Framework, when it gives Henry his own face back: if he was a woman in this save, his head and body go
-- on again, because hers may still be his soul's own. Its last rebuild changes the beard, and a beard on her head has
-- crashed the game.
function FemaleCore.KeepHenry()
	if wasWoman and not henryKept and not FemaleCore.IsWoman() then
		FemaleCore.Log("his head and body go on again")
		sendToken(FemaleCore.HENRY_TOKEN)
		henryKept = true
	end
end

-- Whether Henry's head and body are on as a look of the framework, after ml_ff_henry.
function FemaleCore.HenryKept()
	return henryKept
end

-- Rebuilds the model with what she has now, for when her look does not show.
function FemaleCore.Refresh()
	FemaleCore.Log("refresh, look", FemaleCore.Current())
	rebuild()
end

-- A look chosen before the game starts: from the console of the main menu before New Game, or by another mod.
-- The game tells no new game from a load (only OnGameplayStarted), so it goes on at the next start of the game, new
-- or loaded, once the framework knows her state. START_WAIT_MS more lets the start of a new game settle.
FemaleCore.START_WAIT_MS = 2000
FemaleCore.startLook = nil
-- A new game begins with Godwin, in Kuttenberg, on the first day of the world; Henry's part begins on the second, in
-- Trosecko, after a cutscene (kcd.log of 2026-11-09: world day 1, then 2). The soul of the player cannot be told from
-- Lua (soul:GetId is a runtime WUID), so the day tells it, and the look waits while it is the first.
FemaleCore.HENRY_FIRST_DAY = 2
-- Only Engine/Config/CVarOverrides/Cutscene.cfg sets this cvar, to 1, while a cutscene plays: the look waits for its
-- end, so it goes on once Henry is in the saddle.
FemaleCore.CUTSCENE_CVAR = "e_SkipInFrustumOptimizationWH"
FemaleCore.CUTSCENE_POLL_MS = 1000
local startGen = 0

-- name: a look, by name or id. nil, "" or "none" cancels it. Returns whether the look exists.
function FemaleCore.StartAs(name, hairStyle, hairColor)
	if name == nil or name == "" or name == "none" then
		FemaleCore.startLook, FemaleCore.startHair = nil, nil
		FemaleCore.Log("no look waits for the next start of the game")
		return true
	end
	local look = find(name)
	if not look then
		FemaleCore.Log("no look called", name, "- ml_ff_looks lists them")
		return false
	end
	-- With a hair of its own, checked now, so the log says at once if it is not one.
	if hairStyle and not resolveHair(hairStyle, hairColor) then
		hairHelp(hairStyle)
		hairStyle, hairColor = nil, nil
	end
	FemaleCore.startLook, FemaleCore.startHair = look.name, hairStyle and { hairStyle, hairColor } or nil
	FemaleCore.Log("the next game that starts or loads begins as a woman, look", look.name, "hair", hairStyle, hairColor)
	return true
end

-- The look that waits for the next start of the game, or nil.
function FemaleCore.StartLook()
	return FemaleCore.startLook
end

-- The character of a mod: a mod that plays a woman of its own tells it once, and the framework puts her look on at
-- every start of the game, new or loaded, as StartAs does, with no command. Only her look: her face, her hair and its
-- color. Several mods: the last one wins, and the log says it; KCD2 Male Framework drops its own.
--   FemaleCore.RegisterStartCharacter({
--       name = "Heidi",          -- optional, for the log
--       look = "woman_czech_2",  -- a look, by name or id (ml_ff_looks)
--       hair = 5,                -- optional: a style, or a name as SetHair takes it, like "katherine"
--       color = "blonde",        -- optional: the color of that style
--   })
-- Returns whether the look exists. nil drops the character.
FemaleCore.startCharacter = nil

function FemaleCore.RegisterStartCharacter(character)
	if character == nil then
		FemaleCore.startCharacter = nil
		FemaleCore.Log("no start character")
		return true
	end
	if type(character) ~= "table" or not find(character.look) then
		FemaleCore.Log("start character: no look called", type(character) == "table" and tostring(character.look) or tostring(character),
			"- ml_ff_looks lists them")
		return false
	end
	if FemaleCore.startCharacter and FemaleCore.startCharacter ~= character then
		FemaleCore.Log("start character", tostring(FemaleCore.startCharacter.name), "is replaced by", tostring(character.name))
	end
	FemaleCore.startCharacter = character
	if MaleCore and MaleCore.DropStartCharacter then
		try("male start character", MaleCore.DropStartCharacter, "KCD2 Female Framework")
	end
	FemaleCore.Log("start character:", tostring(character.name), "- look", character.look, "hair", tostring(character.hair),
		tostring(character.color))
	return true
end

-- KCD2 Male Framework calls it when a mod registers a man of its own: the last one wins.
function FemaleCore.DropStartCharacter(by)
	if FemaleCore.startCharacter then
		FemaleCore.Log("start character", tostring(FemaleCore.startCharacter.name), "dropped: a character of", tostring(by), "came after")
		FemaleCore.startCharacter = nil
	end
end

-- At every start of the game, before applyStartLook: her look, if she does not have it yet.
local function armStartCharacter(current)
	local character = FemaleCore.startCharacter
	if not character or FemaleCore.startLook then
		return
	end
	local look = find(character.look)
	if look and look.id ~= current then
		FemaleCore.StartAs(character.look, character.hair, character.color)
	end
end

-- ml_ff_start_character <look> [hair] [color]: a start character for a test, as a mod would register it.
function FemaleCore.StartCharacterCommand(line)
	local args = {}
	for word in string.gmatch(tostring(line or ""):gsub('"', ""), "%S+") do
		args[#args + 1] = word
	end
	if #args == 0 then
		FemaleCore.Log("ml_ff_start_character needs a look, like ml_ff_start_character woman_czech_2 5 blonde")
		return
	end
	FemaleCore.RegisterStartCharacter({ name = "test", look = args[1], hair = tonumber(args[2]) or args[2], color = args[3] })
end

local function inCutscene()
	local value = try("cutscene", System.GetCVar, FemaleCore.CUTSCENE_CVAR)
	return tonumber(value) == 1
end

local function applyStartLook()
	local name = FemaleCore.startLook
	if not name then
		return
	end
	local day = try("calendar", Calendar.GetWorldDay)
	if day and day < FemaleCore.HENRY_FIRST_DAY then
		FemaleCore.Log("world day", day, "- the prologue with Godwin: the look waits for Henry")
		return
	end
	local startHair = FemaleCore.startHair or {}
	FemaleCore.startLook, FemaleCore.startHair = nil, nil
	local gen, waited = startGen, false
	local function attempt()
		-- Another save loaded meanwhile: the look waits for that one.
		if gen ~= startGen then
			if not FemaleCore.startLook then
				FemaleCore.startLook, FemaleCore.startHair = name, startHair
			end
			return
		end
		if inCutscene() then
			if not waited then
				waited = true
				FemaleCore.Log("a cutscene plays: the look waits for its end")
			end
			Script.SetTimer(FemaleCore.CUTSCENE_POLL_MS, attempt)
			return
		end
		FemaleCore.Log("look chosen before the start:", name)
		FemaleCore.wearChanges = true
		local became = try("start look", function() return FemaleCore.BecomeWoman(name, nil, startHair[1], startHair[2]) end)
		if not became then
			FemaleCore.wearChanges = false
		end
	end
	Script.SetTimer(FemaleCore.START_WAIT_MS, attempt)
end

-- The overrides need a rebuild after every load, or the model shows Henry's head again. The inventory is read a moment
-- later: right at the start of the game it may not be there yet.
FemaleCore.LOAD_WAIT_MS = 3000

-- Ready once the look of the save is known and the model rebuilt with it. A command or a change of the other framework
-- in the seconds before met the look of the save before: a face of KCD2 Male Framework went on while this one did
-- not know yet that she was a woman, and her state and her beard without a mesh stayed on.
local ready = false

function FemaleCore.Ready()
	return ready
end

function FemaleCore:OnGameplayStarted()
	FemaleCore.Log("gameplay started")
	ready = false
	startGen = startGen + 1
	-- A load in the middle of a change.
	hideScreen()
	-- What memory has may belong to the save before.
	setCurrent(0)
	henryKept = false
	wasWoman = false
	hair = nil
	FemaleCore.questGearTold = false
	FemaleCore.storyGearFailed = false
	Script.SetTimer(FemaleCore.LOAD_WAIT_MS, function()
		local old = count(FemaleCore.OLD_STATE_ITEM)
		if old > 0 then
			try("token", function() player.inventory:DeleteItemOfClass(FemaleCore.OLD_STATE_ITEM, old) end)
		end
		sendPrice()
		askCurrent(function(current)
			FemaleCore.Log("look on load", current, "- his head kept on:", henryKept, "- was a woman:", wasWoman,
				"- her state on:", womanOn, "- world day", try("calendar", Calendar.GetWorldDay), "time", try("calendar", Calendar.GetWorldTime))
			-- Before the rebuild, so the model rebuilds without his parts. With Henry a man, it clears a mark left over.
			markWoman(current > 0)
			-- Her state left on with a man: her shift and her beard without a mesh stayed on him, and on his doubles. Henry's token turns it off and keeps his head, body and underwear on, as ml_ff_henry does. Without
			-- them on, a face of KCD2 Male Framework took their place, and the reset turns it off, as that framework
			-- sends before its face.
			local repaired = false
			if womanOn and current == 0 then
				repaired = true
				if henryKept then
					FemaleCore.Log("her state was still on, with Henry: his token turns it off")
					sendToken(FemaleCore.HENRY_TOKEN)
				else
					FemaleCore.Log("her state was still on, without Henry's head: the reset turns it off")
					sendToken(FemaleCore.RESET_TOKEN)
				end
			end
			local function done()
				ready = true
				FemaleCore.Log("ready")
			end
			if current > 0 or henryKept or repaired then
				Script.SetTimer(repaired and FemaleCore.TOKEN_MS + 200 or 0, function() rebuild(done) end)
			else
				done()
			end
			startTick()
			armStartCharacter(current)
			applyStartLook()
		end)
	end)
end

-- Console

local function words(line)
	local list = {}
	local text = tostring(line or ""):gsub('^%s*"?', ""):gsub('"?%s*$', "")
	for word in text:gmatch("%S+") do
		list[#list + 1] = word
	end
	return list
end

-- A last word true leaves out the black screen, like ml_ff_look woman_czech_2 true.
local function noScreenWord(list)
	if list[#list] == "true" then
		table.remove(list)
		return true
	end
	return false
end

-- A command of the console changes the model only in the game itself, with no inventory, map or menu open: a
-- change started under them breaks. Those screens pause the game, and a timer of the game waits while it is paused
--, so the change starts once the game runs again.
FemaleCore.IN_GAME_MS = 500
-- And once both frameworks know the look of the save and rebuilt with it. If that never comes, after this long
-- it starts anyway.
FemaleCore.READY_WAIT_MS = 30000

local function bothReady()
	local ok, other = pcall(function() return not (MaleCore and MaleCore.Ready) or MaleCore.Ready() end)
	return ready and (not ok or other == true)
end

local function inGame(label, fn)
	local asked = try("clock", System.GetCurrAsyncTime)
	FemaleCore.Log(label .. ": it starts in the game, once no inventory, map or menu is open, and the look of the save is on")
	local waited, told = 0, false
	local function attempt()
		if not bothReady() and waited < FemaleCore.READY_WAIT_MS then
			if not told then
				told = true
				FemaleCore.Log(label, "waits for the look of the save")
			end
			waited = waited + FemaleCore.IN_GAME_MS
			Script.SetTimer(FemaleCore.IN_GAME_MS, attempt)
			return
		end
		-- In real time: much more than IN_GAME_MS means the game was paused.
		local now = try("clock", System.GetCurrAsyncTime)
		if asked and now then
			FemaleCore.Log(label, "starts after", string.format("%.1f", now - asked), "s")
		end
		try(label, fn)
	end
	Script.SetTimer(FemaleCore.IN_GAME_MS, attempt)
end

-- Each look, and after it the characters of the game who wear its face.
function FemaleCore.PrintLooks()
	for _, look in ipairs(FemaleCore.ListLooks()) do
		local line = string.format("%s: woman, %s, %s, id %d", look.name, look.ethnicity or (look.outside and ("of " .. look.outside)) or "named character", look.age, look.id)
		if #look.characters > 0 then
			line = line .. " - " .. table.concat(look.characters, ", ")
		end
		System.LogAlways(line)
	end
end

function FemaleCore.FemaleCommand(line)
	local list = words(line)
	local noScreen = noScreenWord(list)
	inGame("ml_ff_female", function() FemaleCore.BecomeWoman(list[1], noScreen, list[2], list[3]) end)
end

function FemaleCore.LookCommand(line)
	local list = words(line)
	local noScreen = noScreenWord(list)
	if not list[1] then
		FemaleCore.Log("ml_ff_look needs a look, like ml_ff_look woman_czech_2: ml_ff_looks lists them")
		return
	end
	-- After the look, a hair as ml_ff_hair takes it: ml_ff_look woman_czech_2 5 blonde, or f_hair_005_blonde.
	inGame("ml_ff_look", function() FemaleCore.SetLook(list[1], noScreen, list[2], list[3]) end)
end

function FemaleCore.RandomCommand(line)
	local noScreen = noScreenWord(words(line))
	inGame("ml_ff_random", function() FemaleCore.SetRandomLook(noScreen) end)
end

function FemaleCore.HairCommand(line)
	local list = words(line)
	inGame("ml_ff_hair", function() FemaleCore.SetHair(list[1], list[2]) end)
end

function FemaleCore.HenryCommand(line)
	local noScreen = noScreenWord(words(line))
	inGame("ml_ff_henry", function() FemaleCore.Henry(noScreen) end)
end

function FemaleCore.RefreshCommand()
	inGame("ml_ff_refresh", FemaleCore.Refresh)
end

-- It only remembers the look, so it works in the main menu too. With no look, it says which one waits.
function FemaleCore.StartCommand(line)
	local list = words(line)
	if not list[1] then
		FemaleCore.Log("look for the next start of the game:", FemaleCore.startLook or "none")
		return
	end
	FemaleCore.StartAs(list[1], list[2], list[3])
end
