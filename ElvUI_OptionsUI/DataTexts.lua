local E, _, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local C, L = unpack(select(2, ...))
local DT = E:GetModule('DataTexts')
local Layout = E:GetModule('Layout')
local Chat = E:GetModule('Chat')
local Minimap = E:GetModule('Minimap')
local ACH = E.Libs.ACH

local _G = _G
local tonumber = tonumber
local tostring = tostring
local format = format
local pairs = pairs
local type = type

-- GLOBALS: AceGUIWidgetLSMlists

local DTPanelOptions = {
	numPoints = {
		order = 2,
		type = 'range',
		name = L["Number of DataTexts"],
		min = 1, max = 20, step = 1,
	},
	growth = {
		order = 3,
		type = 'select',
		name = L["Growth"],
		values = {
			HORIZONTAL = 'HORIZONTAL',
			VERTICAL = 'VERTICAL'
		},
	},
	width = {
		order = 4,
		type = 'range',
		name = L["Width"],
		min = 24, max = E.screenwidth, step = 1,
	},
	height = {
		order = 5,
		type = 'range',
		name = L["Height"],
		min = 12, max = E.screenheight, step = 1,
	},
	templateGroup = {
		order = 10,
		type = "multiselect",
		name = L['Template'],
		sortByValue = true,
		values = {
			backdrop = L["Backdrop"],
			panelTransparency = L["Backdrop Transparency"],
			mouseover = L["Mouse Over"],
			border = L["Show Border"],
		},
	},
	strataAndLevel = {
		order = 15,
		type = "group",
		name = L["Strata and Level"],
		guiInline = true,
		args = {
			frameStrata = {
				order = 2,
				type = "select",
				name = L["Frame Strata"],
				values = {
					["BACKGROUND"] = "BACKGROUND",
					["LOW"] = "LOW",
					["MEDIUM"] = "MEDIUM",
					["HIGH"] = "HIGH",
					["DIALOG"] = "DIALOG",
					["TOOLTIP"] = "TOOLTIP",
				},
			},
			frameLevel = {
				order = 5,
				type = "range",
				name = L["Frame Level"],
				min = 1, max = 128, step = 1,
			},
		},
	},
	tooltip = {
		order = 20,
		type = "group",
		name = L["Tooltip"],
		guiInline = true,
		args = {
			tooltipAnchor = {
				order = 2,
				type = "select",
				name = L["Anchor"],
				width = 'double',
				values = {
					ANCHOR_TOP = L["ANCHOR_TOP"],
					ANCHOR_RIGHT = L["ANCHOR_RIGHT"],
					ANCHOR_BOTTOM = L["ANCHOR_BOTTOM"],
					ANCHOR_LEFT = L["ANCHOR_LEFT"],
					ANCHOR_TOPRIGHT = L["ANCHOR_TOPRIGHT"],
					ANCHOR_BOTTOMRIGHT = L["ANCHOR_BOTTOMRIGHT"],
					ANCHOR_TOPLEFT = L["ANCHOR_TOPLEFT"],
					ANCHOR_BOTTOMLEFT = L["ANCHOR_BOTTOMLEFT"],
					ANCHOR_CURSOR = L["ANCHOR_CURSOR"],
					ANCHOR_CURSOR_LEFT = L["ANCHOR_CURSOR_LEFT"],
					ANCHOR_CURSOR_RIGHT = L["ANCHOR_CURSOR_RIGHT"],
				},
			},
			tooltipXOffset = {
				order = 2,
				type = 'range',
				name = L["X-Offset"],
				min = -30, max = 30, step = 1,
			},
			tooltipYOffset = {
				order = 3,
				type = 'range',
				name = L["Y-Offset"],
				min = -30, max = 30, step = 1,
			},
		},
	},
	visibility = {
		type = 'input',
		order = 25,
		name = L["Visibility State"],
		desc = L["This works like a macro, you can run different situations to get the actionbar to show/hide differently.\n Example: '[combat] show;hide'"],
		width = 'full',
	},
}

local function ColorizeName(name, color)
	return format('|cFF%s%s|r', color or 'ffd100', name)
end

local function PanelGroup_Delete(panel)
	E.Options.args.datatexts.args.panels.args[panel] = nil
end

local function PanelGroup_Create(panel)
	local opts = {
		type = 'group',
		name = ColorizeName(panel),
		get = function(info) return E.db.datatexts.panels[panel][info[#info]] end,
		set = function(info, value)
			E.db.datatexts.panels[panel][info[#info]] = value
			DT:UpdatePanelAttributes(panel, E.global.datatexts.customPanels[panel])
		end,
		args = {
			enable = {
				order = 0,
				type = 'toggle',
				name = L['Enable'],
			},
			panelOptions = {
				order = -1,
				name = L["Panel Options"],
				type = 'group',
				guiInline = true,
				get = function(info) return E.global.datatexts.customPanels[panel][info[#info]] end,
				set = function(info, value)
					E.global.datatexts.customPanels[panel][info[#info]] = value
					DT:UpdatePanelAttributes(panel, E.global.datatexts.customPanels[panel])
					DT:PanelLayoutOptions()
				end,
				args = {
					delete = {
						order = -1,
						type = 'execute',
						name = L['Delete'],
						width = 'full',
						confirm = true,
						func = function(info)
							E.db.datatexts.panels[panel] = nil
							E.global.datatexts.customPanels[panel] = nil
							DT:ReleasePanel(panel)
							PanelGroup_Delete(panel)
							DT:PanelLayoutOptions()
							E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'datatexts', 'panels', 'newPanel')
						end,
					},
					fonts = {
						order = 10,
						type = "group",
						name = L["Fonts"],
						guiInline = true,
						get = function(info)
							local settings = E.global.datatexts.customPanels[panel]
							if not settings.fonts then settings.fonts = E:CopyTable({}, G.datatexts.newPanelInfo.fonts) end
							return settings.fonts[info[#info]]
						end,
						set = function(info, value)
							E.global.datatexts.customPanels[panel].fonts[info[#info]] = value
							DT:UpdatePanelAttributes(panel, E.global.datatexts.customPanels[panel])
						end,
						args = {
							enable = {
								type = "toggle",
								order = 1,
								name = L["Enable"],
								desc = L["This will override the global cooldown settings."],
								disabled = E.noop,
							},
							fontSize = {
								order = 3,
								type = 'range',
								name = L["Text Font Size"],
								min = 10, max = 50, step = 1,
							},
							font = {
								order = 4,
								type = 'select',
								name = L["Font"],
								dialogControl = 'LSM30_Font',
								values = AceGUIWidgetLSMlists.font,
							},
							fontOutline = {
								order = 5,
								type = "select",
								name = L["Font Outline"],
								values = C.Values.FontFlags,
							},
						}
					},
				},
			}
		},
	}

	local panelOpts = E:CopyTable(opts.args.panelOptions.args, DTPanelOptions)
	panelOpts.tooltip.args.tooltipYOffset.disabled = function() return E.global.datatexts.customPanels[panel].tooltipAnchor == 'ANCHOR_CURSOR' end
	panelOpts.tooltip.args.tooltipXOffset.disabled = function() return E.global.datatexts.customPanels[panel].tooltipAnchor == 'ANCHOR_CURSOR' end
	panelOpts.templateGroup.get = function(info, key) return E.global.datatexts.customPanels[panel][key] end
	panelOpts.templateGroup.set = function(info, key, value) E.global.datatexts.customPanels[panel][key] = value; DT:UpdatePanelAttributes(panel, E.global.datatexts.customPanels[panel]) end

	E.Options.args.datatexts.args.panels.args[panel] = opts
end

local dts = {[''] = L["NONE"]}
function DT:PanelLayoutOptions()
	for name, data in pairs(DT.RegisteredDataTexts) do
		dts[name] = data.localizedName or L[name]
	end

	local options = E.Options.args.datatexts.args.panels.args

	-- Custom Panels
	for panel in pairs(E.global.datatexts.customPanels) do
		PanelGroup_Create(panel)
	end

	-- This will mixin the options for the Custom Panels.
	for name, tab in pairs(DT.db.panels) do
		if type(tab) == 'table' then
			if not options[name] then
				options[name] = {
					type = 'group',
					name = ColorizeName(name, 'ffffff'),
					args = {},
					get = function(info) return E.db.datatexts.panels[name][info[#info]] end,
					set = function(info, value)
						E.db.datatexts.panels[name][info[#info]] = value
						DT:UpdatePanelInfo(name)
					end,
				}
			end

			-- temp to delete old data in WIP testing
			if not P.datatexts.panels[name] and not E.global.datatexts.customPanels[name] then
				options[name].args.delete = {
					order = -1,
					type = 'execute',
					name = L['Delete'],
					func = function()
						E.db.datatexts.panels[name] = nil
						options[name] = nil
						DT:PanelLayoutOptions()
					end,
				}
			end

			for option in pairs(tab) do
				if type(option) == 'number' then
					if E.global.datatexts.customPanels[name] and option > E.global.datatexts.customPanels[name].numPoints then
						-- Number of Datatexts has been lowered, remove datatext entry in profile
						tab[option] = nil
					else
						options[name].args[tostring(option)] = {
							type = 'select',
							order = option,
							name = format(L["Position %d"], option),
							values = dts,
							get = function(info) return E.db.datatexts.panels[name][tonumber(info[#info])] end,
							set = function(info, value)
								E.db.datatexts.panels[name][tonumber(info[#info])] = value
								DT:UpdatePanelInfo(name)
							end,
						}
					end
				end
			end
		end
	end
end

local function CreateDTOptions(name, data)
	local settings = E.global.datatexts.settings[name]
	if not settings then return end

	local optionTable = {
		order = 1,
		type = "group",
		name = data.localizedName or name,
		guiInline = false,
		get = function(info) return settings[info[#info]] end,
		set = function(info, value) settings[info[#info]] = value DT:ForceUpdate_DataText(name) end,
		args = {},
	}

	E.Options.args.datatexts.args.settings.args[name] = optionTable

	for key in pairs(settings) do
		if key == 'decimalLength' then
			optionTable.args.decimalLength = {
				type = 'range',
				name = L['Decimal Length'],
				min = 0, max = 5, step = 1,
			}
		elseif key == 'goldFormat' then
			optionTable.args.goldFormat = {
				type = 'select',
				name = L["Gold Format"],
				desc = L["The display format of the money text that is shown in the gold datatext and its tooltip."],
				values = { SMART = L["Smart"], FULL = L["Full"], SHORT = L["SHORT"], SHORTINT = L["Short (Whole Numbers)"], CONDENSED = L["Condensed"], BLIZZARD = L["Blizzard Style"], BLIZZARD2 = L["Blizzard Style"].." 2" },
			}
		elseif key == 'goldCoins' then
			optionTable.args.goldCoins = {
				type = 'toggle',
				name = L["Show Coins"],
				desc = L["Use coin icons instead of colored text."],
			}
		elseif key == 'Label' then
			optionTable.args.Label = {
				order = 0,
				type = 'input',
				name = L['Label'],
				get = function(info) return settings[info[#info]] and gsub(settings[info[#info]], '\124', '\124\124') end,
				set = function(info, value) settings[info[#info]] = gsub(value, '\124\124+', '\124') DT:ForceUpdate_DataText(name) end,
			}
		elseif key == 'NoLabel' then
			optionTable.args.NoLabel = {
				type = 'toggle',
				name = L['No Label'],
			}
		elseif key == 'textFormat' then
			optionTable.args.textFormat = {
				type = 'select',
				name = L["Text Format"],
				width = "double",
				get = function(info) return settings[info[#info]] end,
				set = function(info, value) settings[info[#info]] = value; DT:ForceUpdate_DataText(name) end,
				values = {},
			}
		end
	end

	if name == 'Time' then
		optionTable.args.time24 = {
			type = 'toggle',
			name = L["24-Hour Time"],
			desc = L["Toggle 24-hour mode for the time datatext."],
		}
		optionTable.args.localTime = {
			type = 'toggle',
			name = L["Local Time"],
			desc = L["If not set to true then the server time will be displayed instead."],
		}
	elseif name == 'Durability' then
		optionTable.args.percThreshold = {
			type = "range",
			name = L["Flash Threshold"],
			desc = L["The durability percent that the datatext will start flashing.  Set to -1 to disable"],
			min = -1, max = 99, step = 1,
			get = function(info) return settings[info[#info]] end,
			set = function(info, value) settings[info[#info]] = value; DT:ForceUpdate_DataText(name) end,
		}
	elseif name == 'Friends' then
		optionTable.args.description = {
			order = 1,
			type = "description",
			name = L["Hide specific sections in the datatext tooltip."],
		}
		optionTable.args.hideGroup1 = {
			order = 2,
			type = "multiselect",
			name = L["Hide by Status"],
			get = function(_, key) return settings[key] end,
			set = function(_, key, value) settings[key] = value; DT:ForceUpdate_DataText(name) end,
			values = {
				hideAFK = L["AFK"],
				hideDND = L["DND"],
			},
		}
		optionTable.args.hideGroup2 = {
			order = 2,
			type = "multiselect",
			name = L["Hide by Application"],
			get = function(_, key) return settings['hide'..key] end,
			set = function(_, key, value) settings['hide'..key] = value; DT:ForceUpdate_DataText(name) end,
			sortByValue = true,
			values = {
				WoW = "World of Warcraft",
				App = "App",
				BSAp = L["Mobile"],
				D3 = "Diablo 3",
				WTCG = "Hearthstone",
				Hero = "Heroes of the Storm",
				Pro = "Overwatch",
				S1 = "Starcraft",
				S2 = "Starcraft 2",
				VIPR = "COD: Black Ops 4",
				ODIN = "COD: Modern Warfare",
				LAZR = "COD: Modern Warfare 2",
			},
		}
	elseif name == 'Reputation' or name == 'Experience' then
		optionTable.args.textFormat.values = {
			PERCENT = L["Percent"],
			CUR = L["Current"],
			REM = L["Remaining"],
			CURMAX = L["Current - Max"],
			CURPERC = L["Current - Percent"],
			CURREM = L["Current - Remaining"],
			CURPERCREM = L["Current - Percent (Remaining)"],
		}
	elseif name == 'Bags' then
		optionTable.args.textFormat.values = {
			["FREE"] = L["Only Free Slots"],
			["USED"] = L["Only Used Slots"],
			["FREE_TOTAL"] = L["Free/Total"],
			["USED_TOTAL"] = L["Used/Total"],
		}
	end
end

local function SetupDTCustomization()
	local currencyTable = {}
	for name, data in pairs(DT.RegisteredDataTexts) do
		currencyTable[name] = data
	end

	for _, info in pairs(E.global.datatexts.customCurrencies) do
		local name = info.NAME
		if currencyTable[name] then
			currencyTable[name] = nil
		end
	end

	for name, data in pairs(currencyTable) do
		if not data.isLibDataBroker then
			CreateDTOptions(name, data)
		end
	end
end

E.Options.args.datatexts = {
	type = "group",
	name = L["DataTexts"],
	childGroups = "tab",
	order = 2,
	get = function(info) return E.db.datatexts[info[#info]] end,
	set = function(info, value) E.db.datatexts[info[#info]] = value; DT:LoadDataTexts() end,
	args = {
		intro = ACH:Description(L["DATATEXT_DESC"], 1),
		spacer = ACH:Spacer(2),
		general = {
			order = 3,
			type = "group",
			name = L["General"],
			args = {
				generalGroup = {
					order = 2,
					type = "group",
					guiInline = true,
					name = L["General"],
					args = {
						battleground = {
							order = 3,
							type = 'toggle',
							name = L["Battleground Texts"],
							desc = L["When inside a battleground display personal scoreboard information on the main datatext bars."],
						},
						noCombatClick = {
							order = 6,
							type = "toggle",
							name = L["Block Combat Click"],
							desc = L["Blocks all click events while in combat."],
						},
						noCombatHover = {
							order = 7,
							type = "toggle",
							name = L["Block Combat Hover"],
							desc = L["Blocks datatext tooltip from showing in combat."],
						},
					},
				},
				fontGroup = {
					order = 3,
					type = 'group',
					guiInline = true,
					name = L["Fonts"],
					args = {
						font = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 1,
							name = L["Font"],
							values = AceGUIWidgetLSMlists.font,
						},
						fontSize = {
							order = 2,
							name = L["FONT_SIZE"],
							type = "range",
							min = 4, max = 212, step = 1,
						},
						fontOutline = {
							order = 3,
							name = L["Font Outline"],
							desc = L["Set the font outline."],
							type = "select",
							values = C.Values.FontFlags,
						},
						wordWrap = {
							order = 4,
							type = "toggle",
							name = L["Word Wrap"],
						},
					},
				},
			},
		},
		panels = {
			type = 'group',
			name = L["Panels"],
			order = 4,
			args = {
				newPanel = {
					order = 0,
					type = 'group',
					name = ColorizeName(L['New Panel'], '33ff33'),
					get = function(info) return E.global.datatexts.newPanelInfo[info[#info]] end,
					set = function(info, value) E.global.datatexts.newPanelInfo[info[#info]] = value end,
					args = {
						name = {
							order = 0,
							type = 'input',
							width = 'full',
							name = L["Name"],
							validate = function(_, value)
								return E.global.datatexts.customPanels[value] and L["Name Taken"] or true
							end,
						},
						add = {
							order = 1,
							type = 'execute',
							name = L['Add'],
							width = 'full',
							hidden = function()
								return E.global.datatexts.newPanelInfo.name == ''
							end,
							func = function()
								local name = E.global.datatexts.newPanelInfo.name
								E.global.datatexts.customPanels[name] = E:CopyTable({}, E.global.datatexts.newPanelInfo)
								E.db.datatexts.panels[name] = { enable = true }

								for i = 1, E.global.datatexts.newPanelInfo.numPoints do
									E.db.datatexts.panels[name][i] = ''
								end

								PanelGroup_Create(name)
								DT:BuildPanelFrame(name, E.global.datatexts.customPanels[name])
								DT:PanelLayoutOptions()

								E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'datatexts', 'panels', name)
								E.global.datatexts.newPanelInfo = E:CopyTable({}, G.datatexts.newPanelInfo)
							end,
						},
					},
				},
				LeftChatDataPanel = {
					type = "group",
					name = ColorizeName(L["Datatext Panel (Left)"], 'cccccc'),
					desc = L["Display data panels below the chat, used for datatexts."],
					order = 2,
					get = function(info) return E.db.datatexts.panels.LeftChatDataPanel[info[#info]] end,
					set = function(info, value) E.db.datatexts.panels.LeftChatDataPanel[info[#info]] = value DT:UpdatePanelInfo('LeftChatDataPanel') Layout:SetDataPanelStyle() end,
					args = {
						enable = {
							order = 0,
							name = L['Enable'],
							type = 'toggle',
							set = function(info, value)
								E.db.datatexts.panels[info[#info - 1]][info[#info]] = value
								if E.db.LeftChatPanelFaded then
									E.db.LeftChatPanelFaded = true;
									_G.HideLeftChat()
								end

								Chat:UpdateEditboxAnchors()
								Layout:ToggleChatPanels()
								Layout:SetDataPanelStyle()
								DT:UpdatePanelInfo('LeftChatDataPanel')
							end,
						},
						backdrop = {
							order = 5,
							name = L["Backdrop"],
							type = "toggle",
						},
						border = {
							order = 6,
							name = L["Border"],
							type = "toggle",
						},
						panelTransparency = {
							order = 7,
							type = 'toggle',
							name = L["Panel Transparency"],
						},
					},
				},
				RightChatDataPanel = {
					type = "group",
					name = ColorizeName(L["Datatext Panel (Right)"], 'cccccc'),
					desc = L["Display data panels below the chat, used for datatexts."],
					order = 3,
					get = function(info) return E.db.datatexts.panels.RightChatDataPanel[info[#info]] end,
					set = function(info, value) E.db.datatexts.panels.RightChatDataPanel[info[#info]] = value DT:UpdatePanelInfo('RightChatDataPanel') Layout:SetDataPanelStyle() end,
					args = {
						enable = {
							order = 0,
							name = L['Enable'],
							type = 'toggle',
							set = function(info, value)
								E.db.datatexts.panels[info[#info - 1]][info[#info]] = value
								if E.db.RightChatPanelFaded then
									E.db.RightChatPanelFaded = true;
									_G.HideRightChat()
								end

								Chat:UpdateEditboxAnchors()
								Layout:ToggleChatPanels()
								Layout:SetDataPanelStyle()
								DT:UpdatePanelInfo('RightChatDataPanel')
							end,
						},
						backdrop = {
							order = 5,
							name = L["Backdrop"],
							type = "toggle",
						},
						border = {
							order = 6,
							name = L["Border"],
							type = "toggle",
						},
						panelTransparency = {
							order = 7,
							type = 'toggle',
							name = L["Panel Transparency"],
						},
					},
				},
				MinimapPanel = {
					type = "group",
					name = ColorizeName(L["Minimap Panels"], 'cccccc'),
					desc = L["Display minimap panels below the minimap, used for datatexts."],
					get = function(info) return E.db.datatexts.panels.MinimapPanel[info[#info]] end,
					set = function(info, value) E.db.datatexts.panels.MinimapPanel[info[#info]] = value DT:UpdatePanelInfo('MinimapPanel') end,
					order = 4,
					args = {
						enable = {
							order = 0,
							name = L['Enable'],
							type = 'toggle',
							set = function(info, value)
								E.db.datatexts.panels[info[#info - 1]][info[#info]] = value
								DT:UpdatePanelInfo('MinimapPanel')
								Minimap:UpdateSettings()
							end,
						},
						numPoints = {
							order = 5,
							type = 'range',
							name = L["Number of DataTexts"],
							min = 1, max = 2, step = 1,
						},
						backdrop = {
							order = 6,
							name = L["Backdrop"],
							type = "toggle",
						},
						border = {
							order = 7,
							name = L["Border"],
							type = "toggle",
						},
						panelTransparency = {
							order = 8,
							type = 'toggle',
							name = L["Panel Transparency"],
						},
					},
				},
			},
		},
		settings = {
			order = 7,
			type = "group",
			name = L["DataText Customization"],
			args = {},
		}
	},
}

E:CopyTable(E.Options.args.datatexts.args.panels.args.newPanel.args, DTPanelOptions)
E.Options.args.datatexts.args.panels.args.newPanel.args.templateGroup.get = function(info, key) return E.global.datatexts.newPanelInfo[key] end
E.Options.args.datatexts.args.panels.args.newPanel.args.templateGroup.set = function(info, key, value) E.global.datatexts.newPanelInfo[key] = value end

DT:PanelLayoutOptions()
SetupDTCustomization()
