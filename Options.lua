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
			name = "\nCharacters must have at least 2 data points (logins on different days within the selected span) to appear on the graph.\n",
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
					values = {"All data", "Current Expansion", "Current Major Patch"},
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
			name = "Show Achievements",
			desc = "Show 'Superior' and 'Epic' thresholds",
			-- inline getter/setter example
			get = "GetValue",
			set = "SetValue",
		},
		labelRange = {
			type = "range",
			order = 6,
			name = "Label iLvl Axis Steps",
			-- this will look for a getter/setter on our handler object
			get = "GetValue",
			set = "SetValue",
			min = 13, max = 52, step = 13,
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
