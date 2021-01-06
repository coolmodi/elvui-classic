local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule('ActionBars')

--Lua functions
local _G = _G
local pairs = pairs
local assert = assert
local unpack = unpack
--WoW API / Variables
local CreateFrame = CreateFrame
local RegisterStateDriver = RegisterStateDriver
local InCombatLockdown = InCombatLockdown
local MICRO_BUTTONS = MICRO_BUTTONS

local microBar = CreateFrame('Frame', 'ElvUI_MicroBar', E.UIParent)
microBar:SetSize(100, 100)

local function onLeaveBar()
	if AB.db.microbar.mouseover then
		E:UIFrameFadeOut(microBar, 0.2, microBar:GetAlpha(), 0)
	end
end

local watcher = 0
local function onUpdate(self, elapsed)
	if watcher > 0.1 then
		if not self:IsMouseOver() then
			self.IsMouseOvered = nil
			self:SetScript("OnUpdate", nil)
			onLeaveBar()
		end
		watcher = 0
	else
		watcher = watcher + elapsed
	end
end

local function onEnter(button)
	if AB.db.microbar.mouseover and not microBar.IsMouseOvered then
		microBar.IsMouseOvered = true
		microBar:SetScript('OnUpdate', onUpdate)
		E:UIFrameFadeIn(microBar, 0.2, microBar:GetAlpha(), AB.db.microbar.alpha)
	end

	if button.backdrop and button:IsEnabled() then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	end

	-- bag keybind support from actionbar module
	if E.private.actionbar.enable then
		AB:BindUpdate(button, 'MICRO')
	end
end

local function onLeave(button)
	if button.backdrop and button:IsEnabled() then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

function AB:HandleMicroButton(button)
	assert(button, 'Invalid micro button name.')

	local pushed = button:GetPushedTexture()
	local normal = button:GetNormalTexture()
	local disabled = button:GetDisabledTexture()

	button:CreateBackdrop(nil, nil, nil, nil, nil, nil, true)

	button:SetParent(microBar)
	button:GetHighlightTexture():Kill()
	button:HookScript('OnEnter', onEnter)
	button:HookScript('OnLeave', onLeave)
	button:SetHitRectInsets(0, 0, 0, 0)

	if button.Flash then
		button.Flash:SetInside()
		button.Flash:SetTexture()
	end

	pushed:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	pushed:SetInside()

	normal:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	normal:SetInside()

	if disabled then
		disabled:SetTexCoord(0.17, 0.87, 0.5, 0.908)
		disabled:SetInside()
	end
end

function AB:MainMenuMicroButton_SetNormal()
	_G.MainMenuBarPerformanceBar:Point('TOPLEFT', _G.MainMenuMicroButton, 'TOPLEFT', 9, -36)
end

function AB:MainMenuMicroButton_SetPushed()
	_G.MainMenuBarPerformanceBar:Point('TOPLEFT', _G.MainMenuMicroButton, 'TOPLEFT', 8, -37)
end

function AB:UpdateMicroButtonsParent()
	for _, x in pairs(_G.MICRO_BUTTONS) do
		_G[x]:SetParent(microBar)
	end
end

function AB:UpdateMicroBarVisibility()
	if InCombatLockdown() then
		AB.NeedsUpdateMicroBarVisibility = true
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	local visibility = self.db.microbar.visibility
	if visibility and visibility:match('[\n\r]') then
		visibility = visibility:gsub('[\n\r]','')
	end

	RegisterStateDriver(microBar.visibility, 'visibility', (self.db.microbar.enabled and visibility) or 'hide')
end

local VisibleMicroButtons = {}

function AB:UpdateMicroPositionDimensions()
	local db = AB.db.microbar
	microBar.db = db

	microBar.backdrop:SetShown(db.backdrop)
	microBar.backdrop:ClearAllPoints()

	db.buttons = #MICRO_BUTTONS

	AB:MoverMagic(microBar)

	local backdropSpacing = db.backdropSpacing
	local _, horizontal, anchorUp, anchorLeft = AB:GetGrowth(db.point)
	local lastButton, anchorRowButton = microBar

	wipe(VisibleMicroButtons)

	for i = 1, #MICRO_BUTTONS do
		local button = _G[MICRO_BUTTONS[i]]
		if button:IsShown() then
			tinsert(VisibleMicroButtons, button:GetName())
		end
	end

	for i = 1, #VisibleMicroButtons do
		local button = _G[VisibleMicroButtons[i]]
		local lastColumnButton = _G[VisibleMicroButtons[i - db.buttonsPerRow]]

		if i == 1 or i == db.buttonsPerRow then
			anchorRowButton = button
		end

		AB:HandleButton(microBar, button, i, lastButton, lastColumnButton)

		lastButton = button
	end

	microBar:SetAlpha((db.mouseover and not microBar.IsMouseOvered and 0) or db.alpha)

	AB:HandleBackdropMultiplier(microBar, backdropSpacing, db.buttonSpacing, db.widthMult, db.heightMult, anchorUp, anchorLeft, horizontal, lastButton, anchorRowButton)
	AB:HandleBackdropMover(microBar, backdropSpacing)

	if microBar.mover then
		if AB.db.microbar.enabled then
			E:EnableMover(microBar.mover:GetName())
		else
			E:DisableMover(microBar.mover:GetName())
		end
	end

	AB:UpdateMicroBarVisibility()
end

function AB:SetupMicroBar()
	microBar:CreateBackdrop(AB.db.transparent and 'Transparent', nil, nil, nil, nil, nil, nil, 0)
	microBar:Point('TOPLEFT', E.UIParent, 'TOPLEFT', 4, -48)
	microBar:EnableMouse(false)

	microBar.visibility = CreateFrame('Frame', nil, E.UIParent, 'SecureHandlerStateTemplate')
	microBar.visibility:SetScript('OnShow', function() microBar:Show() end)
	microBar.visibility:SetScript('OnHide', function() microBar:Hide() end)

	for _, x in pairs(_G.MICRO_BUTTONS) do
		AB:HandleMicroButton(_G[x])
	end

	_G.MicroButtonPortrait:SetInside(_G.CharacterMicroButton.backdrop)

	AB:SecureHook('MainMenuMicroButton_SetPushed')
	AB:SecureHook('MainMenuMicroButton_SetNormal')
	AB:SecureHook('UpdateMicroButtonsParent')
	AB:SecureHook('UpdateMicroButtons', 'UpdateMicroPositionDimensions')
	_G.UpdateMicroButtonsParent(microBar)
	AB:MainMenuMicroButton_SetNormal()
	AB:UpdateMicroPositionDimensions()

	-- With this method we might don't taint anything. Instead of using :Kill()
	_G.MainMenuBarPerformanceBar:SetAlpha(0)
	_G.MainMenuBarPerformanceBar:SetScale(0.00001)

	E:CreateMover(microBar, 'MicrobarMover', L["Micro Bar"], nil, nil, nil, 'ALL,ACTIONBARS', nil, 'actionbar,microbar')
end
