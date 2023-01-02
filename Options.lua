local LibDBIcon = LibStub("LibDBIcon-1.0")

ILH.defaults = {
	profile = {
		minimapToggle = true,
		minimap = {
			minimapPos = 220,
			hide = false,
		},
		showAchievement = true,
		showChars = 3,
		labelRange = 13,
		dateRange = 1,
		dataType = 1,
		hideNoProgress = true,
		delChar = nil,
	},
}

-- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
ILH.options = {
	type = "group",
	name = "Item Level History (ILH)",
	handler = ILH,
	args = {
		optionsTitle = {
			type = "description",
			order = 1,
			name = "|cff31d6bbItem Level History|r",
			fontSize = "large",
		},
		optionsDetails = {
			type = "description",
			order = 2,
			name = "\nCharacters must have at least 2 data points (logins on different days within the selected span) to appear on the graph.\nRaider.io required to track mythic+ score progress.",
		},
		ddgroup = {
			type = "group",
			name = "Graph Options",
			order = 3,
			inline = true,
			args = {
				showChars = {
					type = "select",
					order = 1,
					name = "Shown Characters",
					desc = "Which characters are displayed on the graph",
					values = {"Current Character", "Characters on Server", "All Characters"},
					get = "GetValue",
					set = "SetValue",
				},
				dateRange = {
					type = "select",
					order = 2,
					name = "Date Range",
					desc = "Range of dates",
					values = {"All data", "Current Expansion (DF)", "Current Season (10.0)", "Last Week (7 days)", "Last Month (30 days)"},
					get = "GetValue",
					set = "SetValue",
				},
				dataType = {
					type = "select",
					order = 3,
					name = "Data Type",
					desc = "What data to display on the graph",
					values = {"Item Level", "Mythic+ Score"},
					get = "GetValue",
					set = "SetValue",
				},
			},
		},
		minimapToggle = {
			type = "toggle",
			order = 4,
			name = "Minimap Icon",
			desc = "Show the minimap icon",
			-- inline getter/setter example
			get = "GetShowMinimap",
			set = "SetShowMinimap",
		},
		showAchievement = {
			type = "toggle",
			order = 5,
			name = "Show achievements",
			desc = "Show 'Superior' and 'Epic' thresholds",
			-- inline getter/setter example
			get = "GetValue",
			set = "SetValue",
		},
		hideNoProgress = {
			type = "toggle",
			order = 6,
			name = "Hide no progress",
			desc = "Do not show characters with no progress during the selected timespan",
			-- inline getter/setter example
			get = "GetValue",
			set = "SetValue",
		},
		labelRange = {
			type = "range",
			order = 7,
			name = "Label iLvl Axis Steps",
			desc = "Gridline interval for item level graph",
			-- this will look for a getter/setter on our handler object
			get = "GetValue",
			set = "SetValue",
			min = 13, max = 52, step = 13,
		},
		delChar = {
			type = "select",
			order = 8,
			name = "Delete Character",
			desc = "Select a character to delete their data",
			values = ILH:GetCharacterList(),
			get = "GetValue",
			set = "SetValue",
		},
		delButton = {
			type = "execute",
			order = 9,
			name = "Delete",
			func = function ()
				ILH:DeleteRecord()
			end,
		},
	},
}

function ILH:GetShowMinimap(info)
	return self.db.profile.minimapToggle
end

function ILH:ToggleMinimap()
	self.db.profile.minimapToggle = not self.db.profile.minimapToggle
	ILH:SetShowMinimap(_, self.db.profile.minimapToggle)
end

function ILH:SetShowMinimap(info, value)
	self.db.profile.minimapToggle = value
	self.db.profile.minimap.hide = not value
	if (self.db.profile.minimapToggle) then
		LibDBIcon:Show("ILH")
	else
		LibDBIcon:Hide("ILH")
	end
end

-- for documentation on the info table
-- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables#title-4-1
function ILH:GetValue(info)
	return self.db.profile[info[#info]]
end

function ILH:SetValue(info, value)
	self.db.profile[info[#info]] = value
end
