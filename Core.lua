
-- Global vars
local UpdateInterval = 60.0 -- How often the OnUpdate code will run (in seconds)
local VERSION_NUM = GetAddOnMetadata("ItemLevelHistory", "Version")
local ILH_ICON = "Interface\\Addons\\ItemLevelHistory\\Media\\icon.tga"
local LINE_ICON = "Interface\\Addons\\ItemLevelHistory\\Media\\line.tga"
local DOTTED_ICON = "Interface\\Addons\\ItemLevelHistory\\Media\\dline.tga"
local START_YEAR = 2022
local SIDE_BUFFER = 10
local LOWER_BUFFER = 50
local UPPER_BUFFER = 20
local GRAPH_WIDTH = 720
local GRAPH_HEIGHT = 480
local SUP_ACHIEVE = 346 --Will need to be edited once I know what the superior/epic achievements are
local EPIC_ACHIEVE = 372 --Do these achievements even exist this time around?

local XPAC_DAY = 332 -- Global launch is day 333 UTC but it'll be 332 in the Western Hemisphere
local MAJOR_PATCH_DAY = 332
local SEASON_RESETS = { 332, 347 }

local WindowOpen = false
local ClassColors = {
	["DEATHKNIGHT"] = {0.769, 0.118, 0.227}, -- Death Knight
	["DEMONHUNTER"] = {0.639, 0.188, 0.788}, -- Demon Hunter
	["DRUID"] = {1.000, 0.486, 0.039}, -- Druid
	["EVOKER"] = {0.200, 0.576, 0.498}, -- Evoker
	["HUNTER"] = {0.667, 0.827, 0.447}, -- Hunter
	["MAGE"] = {0.231, 0.729, 0.859}, -- Mage
	["MONK"] = {0.000, 1.000, 0.596}, -- Monk
	["PALADIN"] = {0.957, 0.549, 0.729}, -- Paladin
	["PRIEST"] = {1.000, 1.000, 1.000}, -- Priest
	["ROGUE"] = {1.000, 0.957, 0.408}, -- Rogue
	["SHAMAN"] = {0.000, 0.439, 0.867}, -- Shaman
	["WARLOCK"] = {0.529, 0.533, 0.933}, -- Warlock
	["WARRIOR"] = {0.776, 0.608, 0.427},  -- Warrior
	["SUPERIOR"] = {0.000, 0.439, 0.867}, -- Superior Achievement
	["EPIC"] = {0.639, 0.208, 0.933} -- Epic Achievement
}

-- Library Setup
ILH = LibStub("AceAddon-3.0"):NewAddon("ItemLevelHistory", "AceEvent-3.0", "AceConsole-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0")
local UI = LibStub("AceGUI-3.0")
-- Minimap icon setup
local ILHDB = LibStub("LibDataBroker-1.1"):NewDataObject("ILHDB", {
	type = "data source",
	text = "ILHDB",
	icon = ILH_ICON,
	OnClick = function(_, button)
			if button == "LeftButton" then ILH:OpenGraph()
			elseif button == "RightButton" then ILH:ToggleOptions()
			end
	end,
	OnTooltipShow = function(tooltip)
		local cs = "|cff31d6bb"
		local ce = "|r"
		tooltip:AddDoubleLine("Item Level History ", VERSION_NUM)
		tooltip:AddLine(" ")
		tooltip:AddLine(format("%sLeft-Click%s to open the main window", cs, ce))
		tooltip:AddLine(format("%sRight-Click%s to open the options window", cs, ce))
		tooltip:AddLine(format("%sDrag%s to move this button", cs, ce))
	end,
})
local LibDBIcon = LibStub("LibDBIcon-1.0")
local LibGraph = LibStub("HFSLibGraph-2.0")

-- Functions
function ILH:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ILHDB", self.defaults, true)
	self:GetCharacterInfo()
	AC:RegisterOptionsTable("ILH_Options", self.options)
	self.optionsFrame = ACD:AddToBlizOptions("ILH_Options", "Item Level History (ILH)")

	self:RegisterChatCommand("ilh", "SlashCommand")
	
	LibDBIcon:Register("ILH", ILHDB, self.db.profile.minimap)
end

function ILH:GetCharacterInfo()
	self.db.char.level = UnitLevel("player")
end

function ILH:SlashCommand(input, editbox)	
	if input == "enable" then
		self:Enable()
		self:Print("ILH Enabled.")
	elseif input == "disable" then
		-- unregisters all events and calls ILH:OnDisable() if defined
		self:Disable()
		self:Print("ILH Disabled.")
	elseif input == "minimap" then
		ILH:ToggleMinimap()
	elseif input == "options" then
		ILH:ToggleOptions()
	else
		self:Print("Version " .. VERSION_NUM)
		print("|cff31d6bb/ilh minimap|r Toggle minimap icon")
		print("|cff31d6bb/ilh options|r Open options window")
	end
end

function ILH:ToggleOptions()
	if ACD.OpenFrames["ILH_Options"] then
		ACD:Close("ILH_Options")
	else
		if (ILH.GraphFrame) then
			ILH.GraphFrame:Hide()
		end
		
		local characters = ILH:GetCharacterList()
		self.db.profile.delChar = nil
		ILH.options.args.delChar.values = characters
		ACD:Open("ILH_Options")
	end
end

function ILH:DeleteRecord()
	local chars = ILH:GetCharacterList()
	if (self.db.profile.delChar) then
		local result = mysplit(chars[self.db.profile.delChar], "-")
		local server = result[1]:match'^%s*(.*%S)' or ''
		local charname = result[2]:match'^%s*(.*%S)' or ''
		local playerGUID = ILH:FindGUID(charname, server)
		self.db.global.PlayerData[playerGUID] = nil
	else
		self:Print("No character selected to delete.")
	end
end

function ILH:FindGUID(charname, server)
	for k, v in pairs(self.db.global.PlayerData) do
		if (v.Name == charname and v.Server == server) then
			return k
		end
	end
	return nil
end

function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

-- Record character information to database
function ILH:CharInfo()

	local rioscore = 0
	if (RaiderIO ~= nil and RaiderIO.GetProfile("player") ~= nil and RaiderIO.GetProfile("player").mythicKeystoneProfile ~= nil) then
		rioscore = RaiderIO.GetProfile("player").mythicKeystoneProfile.currentScore
	end
    local overall = GetAverageItemLevel()
	local playerGUID = UnitGUID("player")
	local playerClass = select(2, GetPlayerInfoByGUID(playerGUID))
	local playerName = select(6, GetPlayerInfoByGUID(playerGUID))
	local playerServer = GetRealmName()
	local tdate = GetTDate()
	
	self.db.global.PlayerData = self.db.global.PlayerData or {}
	pData = self.db.global.PlayerData
	
	if (pData[playerGUID] == nil) then
		pData[playerGUID] = {}
		pData[playerGUID].Data = {}
	end
	pData[playerGUID].Name = playerName -- These are updated each time in case of player name/server changes
	pData[playerGUID].Server = playerServer
	pData[playerGUID].Class = playerClass
	pData[playerGUID].Data[tdate] = { ["iLv"] = overall, ["rio"] = rioscore }

    return overall
end

function ILH:GetCharacterList()
	local chars = {}
	if (self.db) then
		for gid, chr in pairs(self.db.global.PlayerData) do
			tinsert(chars, chr.Server .. " - " .. chr.Name)
		end
	end
	table.sort(chars)
	return chars
end

function ILH:OpenGraph()
	-- Close options menu if it's open
	if ACD.OpenFrames["ILH_Options"] then
		ACD:Close("ILH_Options")
	end
	
	if (ILH.GraphFrame and ILH.GraphFrame:IsShown()) then
		ILH.GraphFrame:Hide()
		return
	end
	
	ILH:CharInfo() -- Trigger data update in case upgrade occurs before update
	local playerGUID = UnitGUID("player")
	local data = {}
	local tdate = GetTDate()
	local precision = 0
	
	-- Build Graph Frame
	if (not ILH.GraphFrame) then
		local graphFrame = UI:Create("Frame")
		
		-- Frame setup
		graphFrame:SetTitle("Item Level History (ILH)")
		ILH.GraphFrame = graphFrame
		
		-- Set locked size of graph window
		ph = GRAPH_HEIGHT
		pw = GRAPH_WIDTH
		graphFrame:SetHeight(ph)
		graphFrame:SetWidth(pw)
		graphFrame.frame:SetResizeBounds(pw, ph, pw, ph)
		graphFrame.frame.Name = "ILHGraphFrame"
	end
		
	-- Load relevant characters
	local charsfordata = {}
	local graphtype = "iLv"
	if (self.db.profile.dataType == 2) then
		graphtype = "mythic+"
	end
	if (self.db.profile.showChars == 1) then -- Current character only
		ILH.GraphFrame:SetStatusText("Current character [" .. select(6, GetPlayerInfoByGUID(playerGUID)) .. "] " .. graphtype .. " history through " .. date("%m/%d/%Y"))
		tinsert(charsfordata, playerGUID)
	elseif (self.db.profile.showChars == 2) then -- Server characters only
		ILH.GraphFrame:SetStatusText("Server [" .. GetRealmName() .. "] character " .. graphtype .. " history through " .. date("%m/%d/%Y"))
		for gid, chr in pairs(self.db.global.PlayerData) do
			if(chr.Server == self.db.global.PlayerData[playerGUID].Server) then
				tinsert(charsfordata, gid)
			end
		end
	else -- All characters
		ILH.GraphFrame:SetStatusText("Account character " .. graphtype .. " history through " .. date("%m/%d/%Y"))
		for gid, chr in pairs(self.db.global.PlayerData) do
			tinsert(charsfordata, gid)
		end
	end

	local g = nil
	if (ILH.GraphFrame.Graph == nil) then
		g = LibGraph:CreateGraphLine("ILHGraph", ILH.GraphFrame.frame, "BOTTOMLEFT", "BOTTOMLEFT", 10, LOWER_BUFFER, pw - SIDE_BUFFER - 10, ph - LOWER_BUFFER - UPPER_BUFFER)
	else
		g = ILH.GraphFrame.Graph
	end
	g:ResetData()
	
	-- Get data for each character
	local firstday = 0
	local lastday = 0
	local dataseries = {}
	for _, gid in ipairs(charsfordata) do
		local resetdays = table.shallow_copy(SEASON_RESETS)
		data = {}
		for day, pdata in pairs(self.db.global.PlayerData[gid].Data) do
			if (self.db.profile.dataType == 1) then
				tinsert(data, {day, pdata.iLv})
			else
				tinsert(data, {day, pdata.rio})
			end
		end

		local xdates = {}
		local sorteddata = {}
		local startingdata = nil
		-- populate the table that holds the keys
		for k, v in pairs(data) do
			table.insert(xdates, v[1])
		end
		-- sort the keys
		table.sort(xdates)
				
		-- Remove season resets from before this character had data to prevent false lines at 0 for the history of the character
		while (table.getn(resetdays) > 0 and (firstday == 0 or resetdays[1] <= firstday) and resetdays[1] <= xdates[1]) do
			table.remove(resetdays, 1)
		end		
		
		-- use the keys to retrieve the values in the sorted order
		local previlv = 0
		local hasToday = false
		for k, v in ipairs(xdates) do 
			local day = indexOf(data, v)
			-- Limit data to certain cutoff if settings say to
			if (self.db.profile.dateRange == 3 and data[day][1] < MAJOR_PATCH_DAY) then
				startingdata = {MAJOR_PATCH_DAY, data[day][2]}
			elseif (self.db.profile.dateRange == 2 and data[day][1] < XPAC_DAY) then
				startingdata = {XPAC_DAY, data[day][2]}
			elseif (self.db.profile.dateRange == 4 and data[day][1] < tdate - 7) then
				startingdata = {tdate - 7, data[day][2]} -- Last Week
			elseif (self.db.profile.dateRange == 5 and data[day][1] < tdate - 30) then
				startingdata = {tdate - 30, data[day][2]} -- Last Month
			else
				-- Set a start point for data existing prior to the cutoff, null afterwards so it doesn't repeat
				if (startingdata ~= nil and startingdata[1] < data[day][1]) then
					tinsert(sorteddata, startingdata)
					startingdata = nil
				else
					startingdata = nil
				end
				
				-- If a character goes a time without being improved, this bit prevents an upgrade from looking like
				-- long steady progress. The graph will show the advancement specifically when it occurred.
				local prevday = data[day][1] - 1
				if (not HasDay(data, prevday) and table.getn(sorteddata) > 0) then
					tinsert(sorteddata, {prevday, sorteddata[table.getn(sorteddata)][2]})
				end
				
				-- On the day of a season reset, place a point at the last point score of the previous season and a 0 on today's
				-- date to create the sharp reset. FOR R.IO SCORES ONLY
				if (self.db.profile.dataType == 2 and table.getn(resetdays) > 0 and resetdays[1] <= data[day][1] and table.getn(sorteddata) > 0) then
					tinsert(sorteddata, {resetdays[1], sorteddata[table.getn(sorteddata)][2]})
					tinsert(sorteddata, {resetdays[1], 0})
					table.remove(resetdays, 1)
				end
				
				-- Add this record to the data set
				tinsert(sorteddata, data[day])
			
				-- These are used to determine the bounds of the SUPERIOR and EPIC lines
				previlv = data[day][1]
				if (v < firstday or firstday == 0) then
					firstday = v
				end
				if (v > lastday or lastday == 0) then
					lastday = v
				end
				
				-- Used to check if the character has data for today
				if (data[day][1] == tdate) then
					hasToday = true
				end
			end
		end
		
		-- If a character hasn't logged in today, continue its line horizontally to the end
		if (not hasToday and table.getn(sorteddata) > 0) then
			tinsert(sorteddata, {tdate, sorteddata[table.getn(sorteddata)][2]})
		end
		
		if (self.db.profile.dataType == 1) then
			precision = 2
		end
				
		-- Add the character's graph line to the set of all lines
		if (table.getn(sorteddata) > 0 and (sorteddata[table.getn(sorteddata)][2] ~= sorteddata[1][2] or not self.db.profile.hideNoProgress)) then
			tinsert(dataseries, {sorteddata, ClassColors[self.db.global.PlayerData[gid].Class], self.db.global.PlayerData[gid].Name})
		end
	end
	
	-- Add Superior/Epic achievement lines if desired
	local superior = { {firstday, SUP_ACHIEVE}, {lastday, SUP_ACHIEVE + 0.001} }
	local epic = { {firstday, EPIC_ACHIEVE}, {lastday, EPIC_ACHIEVE + 0.001} }
	
	if (table.getn(dataseries) == 0) then
		self:Print("No data to graph with the selected options.")
	end
	if (self.db.profile.showAchievement and self.db.profile.dataType == 1) then
		g:AddDataSeries(superior, ClassColors["SUPERIOR"], nil, DOTTED_ICON, "Superior")
		g:AddDataSeries(epic, ClassColors["EPIC"], nil, DOTTED_ICON, "Epic")
	end
	
	-- Add data series to the graph
	for _, ds in ipairs(dataseries) do
		if (not HasDay(ds[1], lastday)) then
			tinsert(ds[1], LastValue(ds[1]))
		end
		
		g:AddDataSeries(ds[1], ds[2], nil, LINE_ICON, ds[3], precision)
	end
	
	-- Set graph parameters
	if (self.db.profile.dataType == 1) then
		g:SetGridSpacing(1, self.db.profile.labelRange) -- this should be based on data
	else
		g:SetGridSpacing(1, 500) -- Good for IO Scores
	end
	g:SetGridColor({0.5, 0.5, 0.5, 0.5})
	g:SetAxisDrawing(true, true)
	g:SetAxisColor({1.0, 1.0, 1.0, 1.0})
	g:SetAutoScale(true) -- Have to use full auto scale because the graph will draw lines outside of the boundaries
	g:SetYLabels(true, false)
	
	ILH.GraphFrame.Graph = g;
	ILH.GraphFrame:Show()
end

function ILH:UpdateCharacterDatabase()
	-- This is for updating the db data from v1.0 to v1.1
	for k,v in pairs(self.db.global.PlayerData) do
		for dk, dv in pairs(v.Data) do
			if (type(dv) ~= "table") then
				self.db.global.PlayerData[k].Data[dk] = { ["iLv"] = dv, ["rio"] = 0 }
			end
		end
	end
end

-- Helper functions
function GetTDate()
	local dayofyear = date("*t").yday
	local years = START_YEAR - date("*t").year
	return dayofyear + years
end

function HasDay(data, day)
	for _, d in pairs(data) do
		if (d[1] == day) then
			return true
		end
	end
	return false
end

function LastValue(ds)
	local i = table.getn(ds)
	return {ds[i][1] + 1, ds[i][2]}
end

function indexOf(array, value)
    for i, v in ipairs(array) do
        if v[1] == value then
            return i
        end
    end
    return nil
end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- Update Loop and Event Triggers
local ilhFrame = CreateFrame("Button", "ilhFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)

do
    local throttle = UpdateInterval;
    function UpdateCharData(self, elapsed)
        throttle = throttle + elapsed
        if (throttle > UpdateInterval) then
            ILH:CharInfo()
            throttle = 0
			
			local doonce = true
			if (doonce) then
				ILH:UpdateCharacterDatabase()
				doonce = false
			end
        end
    end
end

ilhFrame:SetScript("OnUpdate", UpdateCharData)

local function CloseWindow(self, key)
	if (key == "ESCAPE" and ILH.GraphFrame and ILH.GraphFrame:IsShown()) then
		ILH.GraphFrame:Hide()
	end
end

ilhFrame:SetScript("OnKeyDown", CloseWindow)
ilhFrame:SetPropagateKeyboardInput(true)
 