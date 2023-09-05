--[[
	RollTracker Lite Revived - last version by Jerry Chong. <zanglang@gmail.com>
	Originally written by Coth of Gilneas and Morodan of Khadgar.
]]--

local rollArray
local rollNames

-- hard-coded configs
local ClearWhenClosed = true

-- Basic localizations
local locales = {
	deDE = {
		["All rolls have been cleared."] = "Alle gewürfelten Zahlen gelöscht.",
		["%d Roll(s)"] = "%d Zahle(n) gewürfelt",
	},
	esES = {
		["All rolls have been cleared."] = "Todas las tiradas han sido borradas.",
		["%d Roll(s)"] = "%d Tiradas",
	},
	frFR = {
		["All rolls have been cleared."] = "Tous les jets ont été effacés.",
		["%d Roll(s)"] = "%d Jet(s)",
	},
	ruRU = {
		["All rolls have been cleared."] = "Все броски костей очищены.",
		["%d Roll(s)"] = "%d броска(ов)",
	},
	zhCN = {
		["All rolls have been cleared."] = "所有骰子已被清除。",
		["%d Roll(s)"] = "%d个骰子",
	},
	zhTW = {
		["All rolls have been cleared."] = "所有骰子已被清除。",
		["%d Roll(s)"] = "%d個骰子",
	},
}
local L = locales[GetLocale()] or {}
setmetatable(L, {
	-- looks a little messy, may be worth migrating to AceLocale when this list gets bigger
	__index = {
		["%d Roll(s)"] = "%d Roll(s)",
		["All rolls have been cleared."] = "All rolls have been cleared.",
	},
})

local AddonLoadedEventBus = CreateFrame('Frame')
AddonLoadedEventBus:RegisterEvent("ADDON_LOADED")
AddonLoadedEventBus:SetScript('OnEvent', function(self, event, addonName)
    if addonName == "RollTrackerLiteRevived" then
    	RollTracker_OnLoad()
        AddonLoadedEventBus:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Init
function RollTracker_OnLoad()
	rollArray = {}
	rollNames = {}
	
	-- GUI
	if not RollTrackerDB then RollTrackerDB = {} end -- fresh DB
	local x, y, w, h = RollTrackerDB.X, RollTrackerDB.Y, RollTrackerDB.Width, RollTrackerDB.Height
	if not x or not y or not w or not h then
		RollTracker_SaveAnchors()
	else
		RollTrackerFrame:ClearAllPoints()
		RollTrackerFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		RollTrackerFrame:SetWidth(w)
		RollTrackerFrame:SetHeight(h)
	end

	-- all but the korean lang string look like <rollresult> (<min>-<max>) - so we can have one common regex for all langs but korean
	rollPattern = ""
	if GetLocale() == 'koKR' then 
		rollPattern = "^(%w*)%s.*%s(%d+)|1.*%s%((%d+)-(%d+)%)%.?$"
	else
		rollPattern = "^(%w*)[%s|掷出].*[%s|掷出](%d+) %((%d+)-(%d+)%)%.?$"
	end
		
	-- slash command
	SLASH_ROLLTRACKER1 = "/rolltracker";
	SLASH_ROLLTRACKER2 = "/rt";
	SlashCmdList["ROLLTRACKER"] = function (msg)
		if msg == "clear" then
			RollTracker_ClearRolls()
		else
			RollTracker_ShowWindow()
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:SetScript("OnEvent", function(self, event, msg)
	local name, result, minRange, maxRange = string.match(msg, rollPattern)

	if name == nil or result == nil or minRange == nil or maxRange == nil then
		return
	end

	rollNames[name] = rollNames[name] and rollNames[name] + 1 or 1
	table.insert(rollArray, {
		Name = name,
		Roll = tonumber(result),
		Low = tonumber(minRange),
		High = tonumber(maxRange),
		Count = rollNames[name]
	})
	-- popup window
	RollTracker_ShowWindow()
end)

-- Sort and format the list
local function RollTracker_Sort(a, b)
	return a.Roll < b.Roll
end

function RollTracker_UpdateList()
	local rollText = ""
	
	table.sort(rollArray, RollTracker_Sort)
	
	-- format and print rolls, check for ties
	for i, roll in pairs(rollArray) do
		local tied = (rollArray[i + 1] and roll.Roll == rollArray[i + 1].Roll) or (rollArray[i - 1] and roll.Roll == rollArray[i - 1].Roll)
		rollText = string.format("|c%s%d|r: |c%s%s%s%s|r\n",
				tied and "ffffff00" or "ffffffff",
				roll.Roll,
				((roll.Low ~= 1 or roll.High ~= 100) or (roll.Count > 1)) and  "ffffcccc" or "ffffffff",
				roll.Name,
				(roll.Low ~= 1 or roll.High ~= 100) and format(" (%d-%d)", roll.Low, roll.High) or "",
				roll.Count > 1 and format(" [%d]", roll.Count) or "") .. rollText
	end
	RollTrackerRollText:SetText(rollText)
	RollTrackerFrameStatusText:SetText(string.format(L["%d Roll(s)"], table.getn(rollArray)))
end

function RollTracker_ClearRolls()
	rollArray = {}
	rollNames = {}
	DEFAULT_CHAT_FRAME:AddMessage(L["All rolls have been cleared."])
	RollTracker_UpdateList()
end

-- GUI
function RollTracker_SaveAnchors()
	RollTrackerDB.X = RollTrackerFrame:GetLeft()
	RollTrackerDB.Y = RollTrackerFrame:GetTop()
	RollTrackerDB.Width = RollTrackerFrame:GetWidth()
	RollTrackerDB.Height = RollTrackerFrame:GetHeight()
end

function RollTracker_ShowWindow()
	RollTrackerFrame:Show()
	RollTracker_UpdateList()
end

function RollTracker_HideWindow()
	if ClearWhenClosed then
		RollTracker_ClearRolls()
	end
end