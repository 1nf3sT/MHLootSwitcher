local inCombat = nil

local isDebugging = nil
local isEnabled = true

local function checkTarget(id)
    if not isDebugging then return UnitExists(id) and UnitAffectingCombat(id) and UnitClassification(id) == "worldboss"
            -- If we're debugging then we don't care if the unit is in combat
    else return UnitExists(id) and UnitClassification(id) == "worldboss"
    end
end

local function checkZone()
    return GetZoneText() == "Hyjal Summit" or GetZoneText() == "Black Temple" or GetZoneText() == "Sunwell Plateau" or GetZoneText() == "Tempest Keep" or GetZoneText() == "Serpentshrine Cavern" or GetZoneText() == "Gruul's Lair" or GetZoneText() == "Magtheridon's Lair" or GetZoneText() == "Karazhan"
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
        if lootmethod == "master" then return
        else SetLootMethod("master")  end
    else
        if isDebugging then
            DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Didn't find a boss, trying to set to group loot")
        end
        local lootmethod, _, masterlooterRaidID = GetLootMethod()
        if lootmethod == "group" then return end
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
    elseif args[1] == "enable" then enable()
	elseif args[1] == "swp" then setZone("Sunwell Plateau")
    elseif args[1] == "bt" then setZone("Black Temple")
    elseif args[1] == "mh" then setZone("Hyjal Summit")
	elseif args[1] == "tk" then setZone("Tempest Keep")
	elseif args[1] == "ssc" then setZone("Serpentshrine Cavern")
	elseif args[1] == "gruul" then setZone("Gruul's Lair")
	elseif args[1] == "mag" then setZone("Magtheridon's Lair")
	elseif args[1] == "kara" then setZone("Karazhan")
    elseif args[1] == "splitjointest" then
        local list = {}
        list = strsplit(" ", "setML etrne")
        for x,y in pairs(list) do
            DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: List - " .. y)
        end
    else
		DEFAULT_CHAT_FRAME:AddMessage("MHLootSwitcher: Parameters for /mhl are: \ndebug: enter/exit debug mode \nenable: enable/disable the loot changing \nkara: enable/disable Karazhan\nmag: enable/disable Magtheridon's Lair\ngruul: enable/disable Gruul's Lair\nssc: enable/disable Serpentshrine Cavern\ntk: enable/disable Tempest Keep\nmh: enable/disable Mount Hyjal \nbt: enable/disable Black Temple\nswp: enable/disable Sunwell Plateau")
    end
    return
end

frame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
		PlayerName = UnitName("player")
        if not MHLSVars then MHLSVars = { } end
        if(not MHLSVars['defaultML']) then MHLSVars['defaultML'] = PlayerName end;
		if(not MHLSVars['Sunwell Plateau']) then MHLSVars['Sunwell Plateau'] = true end;
        if(not MHLSVars['Black Temple']) then MHLSVars['Black Temple'] = true end;
        if(not MHLSVars['Hyjal Summit']) then MHLSVars['Hyjal Summit'] = true end;
		if(not MHLSVars['Tempest Keep']) then MHLSVars['Tempest Keep'] = true end;
		if(not MHLSVars['Serpentshrine Cavern']) then MHLSVars['Serpentshrine Cavern'] = true end;
		if(not MHLSVars['Gruul\'s Lair']) then MHLSVars['Gruul\'s Lair'] = true end;
		if(not MHLSVars['Magtheridon\'s Lair']) then MHLSVars['Magtheridon\'s Lair'] = true end;
		if(not MHLSVars['Karazhan']) then MHLSVars['Karazhan'] = true end;
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
