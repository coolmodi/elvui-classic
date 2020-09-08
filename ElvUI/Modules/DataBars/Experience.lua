local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DB = E:GetModule('DataBars')

local _G = _G
local min, format = min, format
local UnitXP, UnitXPMax = UnitXP, UnitXPMax
local GetXPExhaustion = GetXPExhaustion
local CreateFrame = CreateFrame
local CurrentXP, XPToLevel, RestedXP = 0, 0, 0

function DB:ExperienceBar_ShouldBeVisable()
	return E.mylevel ~= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
end

function DB:ExperienceBar_Update()
	local bar = DB.StatusBars.Experience
	if not DB.db.experience.enable or (bar.db.hideAtMaxLevel and not DB:ExperienceBar_ShouldBeVisable()) then
		bar:Hide()
		return
	else
		bar:Show()
	end

	CurrentXP, XPToLevel, RestedXP = UnitXP('player'), UnitXPMax('player'), GetXPExhaustion()
	if XPToLevel <= 0 then XPToLevel = 1 end

	bar:SetMinMaxValues(0, XPToLevel)
	bar:SetValue(CurrentXP)

	local expColor, restedColor = DB.db.colors.experience, DB.db.colors.rested
	bar:SetStatusBarColor(expColor.r, expColor.g, expColor.b, expColor.a)
	bar.Rested:SetStatusBarColor(restedColor.r, restedColor.g, restedColor.b, restedColor.a)

	local text, textFormat = '', DB.db.experience.textFormat

	if not DB:ExperienceBar_ShouldBeVisable() then
		text = L['Max Level']
	else
		if textFormat == 'PERCENT' then
			text = format('%d%%', CurrentXP / XPToLevel * 100)
		elseif textFormat == 'CURMAX' then
			text = format('%s - %s', E:ShortValue(CurrentXP), E:ShortValue(XPToLevel))
		elseif textFormat == 'CURPERC' then
			text = format('%s - %d%%', E:ShortValue(CurrentXP), CurrentXP / XPToLevel * 100)
		elseif textFormat == 'CUR' then
			text = format('%s', E:ShortValue(CurrentXP))
		elseif textFormat == 'REM' then
			text = format('%s', E:ShortValue(XPToLevel - CurrentXP))
		elseif textFormat == 'CURREM' then
			text = format('%s - %s', E:ShortValue(CurrentXP), E:ShortValue(XPToLevel - CurrentXP))
		elseif textFormat == 'CURPERCREM' then
			text = format('%s - %d%% (%s)', E:ShortValue(CurrentXP), CurrentXP / XPToLevel * 100, E:ShortValue(XPToLevel - CurrentXP))
		end

		if RestedXP and RestedXP > 0 then
			bar.Rested:SetMinMaxValues(0, XPToLevel)
			bar.Rested:SetValue(min(CurrentXP + RestedXP, XPToLevel))
			bar.Rested:Show()

			if textFormat == 'PERCENT' then
				text = text..format(' R:%d%%', RestedXP / XPToLevel * 100)
			elseif textFormat == 'CURPERC' then
				text = text..format(' R:%s [%d%%]', E:ShortValue(RestedXP), RestedXP / XPToLevel * 100)
			elseif textFormat ~= 'NONE' then
				text = text..format(' R:%s', E:ShortValue(RestedXP))
			end
		else
			bar.Rested:Hide()
		end
	end

	bar.text:SetText(text)
end

function DB:ExperienceBar_OnEnter()
	if self.db.mouseover then
		E:UIFrameFadeIn(self, 0.4, self:GetAlpha(), 1)
	end

	_G.GameTooltip:ClearLines()
	_G.GameTooltip:SetOwner(self, 'ANCHOR_CURSOR', 0, -4)

	_G.GameTooltip:AddLine(L["Experience"])
	_G.GameTooltip:AddLine(' ')

	_G.GameTooltip:AddDoubleLine(L["XP:"], format(' %d / %d (%.2f%%)', CurrentXP, XPToLevel, CurrentXP/XPToLevel * 100), 1, 1, 1)
	_G.GameTooltip:AddDoubleLine(L["Remaining:"], format(' %d (%.2f%% - %.2f '..L["Bars"]..')', XPToLevel - CurrentXP, (XPToLevel - CurrentXP) / XPToLevel * 100, 20 * (XPToLevel - CurrentXP) / XPToLevel), 1, 1, 1)

	if RestedXP then
		_G.GameTooltip:AddDoubleLine(L["Rested:"], format('+%d (%.2f%%)', RestedXP, RestedXP / XPToLevel * 100), 1, 1, 1)
	end

	_G.GameTooltip:Show()
end

function DB:ExperienceBar_OnClick() end

function DB:ExperienceBar_Toggle()
	local bar = DB.StatusBars.Experience
	bar.db = DB.db.experience

	if bar.db.enable and not (bar.db.hideAtMaxLevel and not DB:ExperienceBar_ShouldBeVisable()) then
		bar:Show()
		E:EnableMover(bar.mover:GetName())

		DB:RegisterEvent('PLAYER_XP_UPDATE', 'ExperienceBar_Update')
		DB:RegisterEvent('DISABLE_XP_GAIN', 'ExperienceBar_Update')
		DB:RegisterEvent('ENABLE_XP_GAIN', 'ExperienceBar_Update')
		DB:RegisterEvent('UPDATE_EXHAUSTION', 'ExperienceBar_Update')
		DB:UnregisterEvent('UPDATE_EXPANSION_LEVEL')

		DB:ExperienceBar_Update()
	else
		bar:Hide()
		E:DisableMover(bar.mover:GetName())

		DB:UnregisterEvent('PLAYER_XP_UPDATE')
		DB:UnregisterEvent('DISABLE_XP_GAIN')
		DB:UnregisterEvent('ENABLE_XP_GAIN')
		DB:UnregisterEvent('UPDATE_EXHAUSTION')
		DB:RegisterEvent('UPDATE_EXPANSION_LEVEL', 'ExperienceBar_Toggle')
	end
end

function DB:ExperienceBar()
	DB.StatusBars.Experience = DB:CreateBar('ElvUI_ExperienceBar', DB.ExperienceBar_OnEnter, DB.ExperienceBar_OnClick, 'BOTTOM', E.UIParent, 'BOTTOM', 0, 43)

	DB.StatusBars.Experience.Rested = CreateFrame('StatusBar', '$parent_Rested', DB.StatusBars.Experience)
	DB.StatusBars.Experience.Rested:SetStatusBarTexture(DB.db.customTexture and E.LSM:Fetch('statusbar', DB.db.statusbar) or E.media.normTex)
	DB.StatusBars.Experience.Rested:SetAllPoints()

	E:CreateMover(DB.StatusBars.Experience, 'ExperienceBarMover', L["Experience Bar"], nil, nil, nil, nil, nil, 'databars,experience')
	DB:ExperienceBar_Toggle()
end
