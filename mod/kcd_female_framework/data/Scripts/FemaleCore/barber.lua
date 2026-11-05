-- =============================================================================
-- A woman's haircut at the barbers of the game: Fiala, Adam, Betty and any NPC with the role BARBER. The screen of the
-- game has one list for everybody, with men's hair and beards, so she chooses in the talk (ml_ff_barber_dialog.xml): a
-- style and a color. Each one named tries the hair on her soul, so it shows at once, and only Accept keeps it.
-- =============================================================================
FemaleCore.Barber = {}
local Shop = FemaleCore.Barber

Shop.WOMAN_VARIABLE = "ml_ff_woman"
Shop.COLORS_VARIABLE = "ml_ff_hair_colors"
-- The menus hide what she has on now. 0 hides nothing: after a load, the framework does not know her hair.
Shop.STYLE_VARIABLE = "ml_ff_hair_style"
Shop.COLOR_VARIABLE = "ml_ff_hair_color"

local session
local style
local color
-- What she had on when the talk began, or nil when it is not known.
local known

local function publish()
	Variables.SetGlobal(Shop.COLORS_VARIABLE, FemaleCore.HAIR_STYLES[style])
	Variables.SetGlobal(Shop.STYLE_VARIABLE, known and style or 0)
	Variables.SetGlobal(Shop.COLOR_VARIABLE, known and color or 0)
end

local function show()
	FemaleCore.Try("barber try", function() session:TryHair(FemaleCore.HairName(style, color)) end)
end

local function close(finish)
	FemaleCore.Try("barber close", function()
		finish(session)
		Barber:Destroy(session)
	end)
	session = nil
end

function Shop.Open()
	session = FemaleCore.Try("barber", function() return Barber:Create(player.soul) end)
	local hairStyle, hairColor, isKnown = FemaleCore.Hair()
	style, color, known = hairStyle, hairColor, isKnown
	publish()
end

function Shop.Style(index)
	style = index
	color = math.min(color, FemaleCore.HAIR_STYLES[style])
	known = true
	publish()
	show()
end

function Shop.Color(index)
	color = index
	known = true
	publish()
	show()
end

function Shop.Accept()
	close(function(barber) barber:Commit() end)
	FemaleCore.RememberHair(style, color)
	FemaleCore.Log("barber", FemaleCore.HairName(style, color))
end

function Shop.Cancel()
	close(function(barber) barber:Revert() end)
end

-- Variables are lost on a region change, so the tick sets them every second. A talk cut short must not leave the hair on
-- trial.
function Shop.Update()
	Variables.SetGlobal(Shop.WOMAN_VARIABLE, FemaleCore.WomanInUse() and 1 or 0)
	if session and not FemaleCore.Try("barber dialog", function() return player.human:IsInDialog() end) then
		Shop.Cancel()
	end
end
