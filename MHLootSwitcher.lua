local inCombat = nil

--[[local MHLSVars = {
     ['defaultML'] = "Serpico",
     ['Black Temple'] = true,
     ['Mount Hyjal'] = true,
}]]--
local oldML = nil
local defaultML = nil
local isDebugging = nil
local isEnabled = true

local function checkTarget(id)
    if not isDebugging then return UnitExists(id) and UnitAffectingCombat(id) and UnitClassification(id) == "worldboss"
            -- If we're debugging then we don't care if the unit is in combat
    else return UnitExists(id) and UnitClassification(id) == "worldboss"
    end
end

local function checkZone()
    return GetZoneText() == "Hyjal Summit" or GetZoneText() == "Black Temple"
    --if MHLSVars["Hyjal Summit"] == true and GetZoneText() == "Hyjal Summit" then return true
    --elseif MHLSVars["Black Temple"] == true and GetZoneText() == "Black Temple" then return true end
    
end



local function scan()
    local isBoss = false
	if checkTarget("target") then isBoss =  true end
	if checkTarget("focus") then isBoss = true end
	if UnitInRaid("player") then
		for i = 1, 40 do if checkTarget("raid"..i.."target") then isBoss = true end
		end
	else
		for i = 1, 5 do if checkTarget("party"..i.."target") then isBoss = true end end
	end
    if isDebugging then
        if isBoss then DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: isBoss = true")
        else DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: isBoss = false") end
    end
    return isBoss
end

local frame = CreateFrame("Frame")
local function updateBossTarget()
	if not isDebugging and not checkZone() then return false end
    local target = scan()
    if isDebugging and target then DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: scan() returned true")
    elseif isDebugging and not target then DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: scan() returned nil")
    end
	if not target then return false end
	return true
end

local function lootSetter()
    if isDebugging then
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Target Changed")
    end
    if not IsRaidLeader() then 
        if isDebugging  then DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: You're not the raid leader") end
        return 
    end
    if updateBossTarget() then
        if isDebugging then DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Found a boss, trying to set to ML")
        end
        if lootmethod == "master" then return end
        if not oldML then SetLootMethod("master",defaultML)
        else SetLootMethod("master",oldML)  end
    else
        if isDebugging then
            DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Didn't find a boss, trying to set to group loot")
        end
        local lootmethod, _, masterlooterRaidID = GetLootMethod()
        if lootmethod == "group" then return end
        if lootmethod == "master" then oldML = GetRaidRosterInfo(masterlooterRaidID) end
        SetLootMethod("group")
    end
end

local function debug()
    if not isDebugging then
        isDebugging = true
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Entering Debug Mode")
    else
        isDebugging = false
        frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Exiting Debug Mode")
    end
end

local function enable()
    if isEnabled then
        isEnabled = false
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Is now disabled")
    else
        isEnabled = true
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Is now enabled")
    end
end

local function setML(type, name)
    if name == "" or name == nil then
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: You need to define a person to be master looter, /mhlsetml playername")
    else
        if type == "default" then
            MHLSVars["defaultML"] = name
            DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Default Master Looter set to " .. MHLSVars["defaultML"])
        else
            oldML = name
            DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Master Looter set to " .. oldML)
        end
        
    end
end

local function setZone(zone)
    if not MHLSVars[zone] then
        MHLSVars[zone] = true
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Lootswitching enabled for " .. zone)
    else 
        MHLSVars[zone] = false
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Lootswitching disabled for " .. zone)
    end
end
-- Shamlessly borrowed from http://lua-users.org/wiki/SplitJoin
local function strsplit(delimiter, text)
  local list = {}
  local pos = 1
  if strfind("", delimiter, 1) then -- this would result in endless loops
    error("MHLootSwitcher: delimiter matches empty string!")
  end
  while 1 do
    local first, last = strfind(text, delimiter, pos)
    if first then -- found?
      tinsert(list, strsub(text, pos, first-1))
      pos = last+1
    else
      tinsert(list, strsub(text, pos))
      break
    end
  end
  return list
end

local function slashCmdHandler(arg1)
    local args = {}
    args = strsplit(" ", arg1)
    if args[1] == "debug" then debug()
    elseif args[1] == "setML" then setML("session", args[2])
    elseif args[1] == "setdefaultML" then setML("default", args[2])
    elseif args[1] == "getdefaultML" then DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Default Master Looter is: " .. MHLSVars["defaultML"])
    elseif args[1] == "enable" then enable()
    elseif args[1] == "bt" then setZone("Black Temple")
    elseif args[1] == "mh" then setZone("Hyjal Summit")
    elseif args[1] == "splitjointest" then
        local list = {}
        list = strsplit(" ", "setML etrne")
        for x,y in pairs(list) do
            DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: List - " .. y)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Parameters for /mhl are: 'debug' to enter/exit debug mode, 'setML' to set the master looter, 'enable' to enable/disable the loot changing")
    end
    return
end

frame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if not MHLSVars then MHLSVars = { } end
        if(not MHLSVars['defaultML']) then MHLSVars['defaultML'] = 'Serpico' end;
        if(not MHLSVars['Black Temple']) then MHLSVars['Black Temple'] = true end;
        if(not MHLSVars['Hyjal Summit']) then MHLSVars['Hyjal Summit'] = true end;
	elseif event == "PLAYER_REGEN_DISABLED" then
        if not isDebugging and isEnabled then
            frame:RegisterEvent("PLAYER_TARGET_CHANGED")
            lootSetter()
        end
	elseif event == "PLAYER_TARGET_CHANGED" and isEnabled then
		lootSetter()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not isDebugging then
            frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end

    end
end)



-- Registering Events
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent('VARIABLES_LOADED')

-- Setting up Slash Commands
SlashCmdList["MHLOOTSWITCHER"] = slashCmdHandler;
SLASH_MHLOOTSWITCHER1 = "/mhl";
--[[SlashCmdList["MHLOOTSWITCHER"] = debug;
SlashCmdList["MHLOOTSWITCHER_MLCHANGE"] = setML;
SlashCmdList["MHLOOTSWITCHER_ENABLE"] = enable;
SLASH_MHLOOTSWITCHER1 = "/mhldebug";
SLASH_MHLOOTSWITCHER_MLCHANGE1 = "/mhlsetml";
SLASH_MHLOOTSWITCHER_ENABLE1 = "/mhlenable";]]--
