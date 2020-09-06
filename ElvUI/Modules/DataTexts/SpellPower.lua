 local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule('DataTexts')

--Lua functions
local strjoin = strjoin
local min = min
local GetSpellBonusDamage = GetSpellBonusDamage
local GetSpellBonusHealing = GetSpellBonusHealing
local STAT_CATEGORY_ENHANCEMENTS = STAT_CATEGORY_ENHANCEMENTS
local MAX_SPELL_SCHOOLS = MAX_SPELL_SCHOOLS

local displayString, lastPanel = ''

local function OnEvent(self)
	local minSpellPower = GetSpellBonusDamage(2)
	local HealingPower = GetSpellBonusHealing()

	for i = 3, MAX_SPELL_SCHOOLS do
		local spellPower = GetSpellBonusDamage(i);
		minSpellPower = min(minSpellPower, spellPower);
	end

	if HealingPower > minSpellPower then
		self.text:SetFormattedText(displayString, L["HP"], HealingPower)
	else
		self.text:SetFormattedText(displayString, L["SP"], minSpellPower)
	end

	lastPanel = self
end

local function ValueColorUpdate(hex)
	displayString = strjoin("", "%s: ", hex, "%d|r")

	if lastPanel ~= nil then
		OnEvent(lastPanel)
	end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext('Spell/Heal Power', STAT_CATEGORY_ENHANCEMENTS, {"UNIT_STATS", "UNIT_AURA"}, OnEvent, nil, nil, nil, nil, L["Spell/Heal Power"])
