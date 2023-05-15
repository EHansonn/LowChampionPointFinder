
-- Libraries -- 
local LAM = LibAddonMenu2


-- Local Vars -- 
LowChampionPointFinder = {}
local ADDON_NAME = "LowChampionPointFinder"
local ADDON_VERSION = "1.0"
local DATABASE_VERSION = "1.0"
local LOADED = false

local DB
local DEFAULTS = {
    fontSize = 32,
    CpOffset = {x = 0, y = 60},
    isPvpOnly = true, -- Controls if CP shows in non pvp zones (IE Duels)
    isAttackableOnly = true, -- Controls if you see friendly players CP
    ChampionPointGroups = {
        [1] = {lowCp=0, highCp=160, text="Low Cp", color={r=0.0, g=1.0, b=1.0, a=1.0}},
        [2] = {lowCp=160, highCp=600, text="Low Cp", color={r=0.0, g=1.0, b=0.8, a=1.0}},
        [3] = {lowCp=600, highCp=810, text="Low Cp", color={r=0.0, g=1.0, b=0.5, a=1.0}},
        [4] = {lowCp=810, highCp=1200, text="", color={r=.8, g=1.0, b=0.0, a=0.8}},
        [5] = {lowCp=1200, highCp=1500, text="", color={r=1.0, g=0.2, b=0.0, a=0.5}},
        [6] = {lowCp=1500, highCp=3600, text="", color={r=1.0, g=0.0, b=0.0, a=0.5}},
    }
}
-- Local Functions --
local function FindChampionPointGroup(Cp,groups)
    for i, group in ipairs(groups) do
        if Cp >= group.lowCp and Cp <= group.highCp then
          return group
        end
      end 
    return groups[1]
end


local function GetTargetChampionPoints()
    if IsUnitPlayer("reticleover") then
        local championPoints = GetUnitChampionPoints("reticleover") 
        return championPoints
    else
        return 160
    end
end

local function SetColor(color,view)
    local red = color.r
    local green = color.g
    local blue = color.b 
    local alpha = color.a
    view:SetColor(red, green, blue, alpha)
end


local function UpdateUi()
    if LOADED == true then
        local targetName = GetUnitName("reticleover")
        local canAttack = IsUnitAttackable("reticleover")
        local isPlayer = IsUnitPlayer("reticleover")
        local isTargetDead = IsUnitDead("reticleover")

        if (IsPlayerInAvAWorld() == false and DB.isPvpOnly== true)  or (targetName == "") or (canAttack == false and DB.isAttackableOnly == true) or (isPlayer == false) or (isTargetDead == true) then
            LowChampionPointFinderView:SetAlpha(0)
            LowChampionPointFinderViewCp:SetText("")
        else
            LowChampionPointFinderView:SetAlpha(1)
            local targetChampionPoints = GetTargetChampionPoints()
            local matchingGroup = FindChampionPointGroup(targetChampionPoints,DB.ChampionPointGroups)

            LowChampionPointFinderViewCp:SetText(matchingGroup.text)
            SetColor(matchingGroup.color,LowChampionPointFinderViewCp)
        end
    end
end
    
local function TargetChanged()
    UpdateUi()
end
    
local function CombatEvent()
    UpdateUi()
end
    

local function CreateAnchors()
    LowChampionPointFinderViewCp:ClearAnchors()
    LowChampionPointFinderViewCp:SetAnchor(TOP,LowChampionPointFinderView,TOP,DB.CpOffset.x,DB.CpOffset.y)
end

local function UpdateFont() --Same font as squishyfinder <3 -- 
    LowChampionPointFinderViewCp:SetFont("$(BOLD_FONT)|" .. DB.fontSize .. "|soft-shadow-thick")
end


local function createControlsForGroup(i, group, default)
    local options = { }

    
    table.insert(options, {
        type = "editbox",
        name = "Group " .. i .. " CP (lower bound)",
        tooltip = "Color group defined by CP above this value",
        textType = TEXT_TYPE_NUMERIC_UNSIGNED_INT,
        default = default.lowCp,
        getFunc = function() return group.lowCp end,
        setFunc = function(text)
        group.lowCp = tonumber(text)
        if (group.lowCp < 0 or group.lowCp > 3600) then
            group.lowCp = 0
            end
        end,
    })
      
    table.insert(options, {
        type = "editbox",
        name = "Group " .. i .. " CP (upper bound)",
        tooltip = "Color group defined by CP under this value",
        textType = TEXT_TYPE_NUMERIC_UNSIGNED_INT,
        default = default.highCp,
        getFunc = function() return group.highCp end,
        setFunc = function(text)
            group.highCp = tonumber(text)
            if (group.highCp < 0 or group.highCp > 3600) then
                group.highCp = 3600
              end
          end,
      })
    
    table.insert(options, {
        type = "editbox",
        name = "Group " .. i .. " text",
        tooltip = "The text that is displayed when the target's CP is within this value. Leave empty to show nothing",
        default = default.text,
        getFunc = function() return group.text end,
        setFunc = function(text) 
            group.text = text
        end,
      })
     
    table.insert(options, {
        type = "colorpicker",
        name = "Group " .. i .. " color",
        default = default.color,
            getFunc = function() 
                return group.color.r, group.color.g, group.color.b, group.color.a
            end,
            setFunc = function(r,g,b,a) 
                group.color = { r=r, g=g, b=b, a=a }
            end,
      })

    table.insert(options, {
        type = "description",
        text = "",
    })
    return options
  end
 
-- Creating LAM2 MENU --
local function CreateSettingsMenu()
    local panelName = "LowChampionPointFinderPanel"
    local panelData = {
		type = "panel",
		name = ADDON_NAME,
		displayName = "Low Champion Point Finder",
		author = "EHansonn",
		version = ADDON_VERSION,
		registerForRefresh = true,
		registerForDefaults = true,
	}

    local controlPanel = LAM:RegisterAddonPanel(panelName,panelData)

    local options = {
        {
			type = "header",
			name = "Visiblity Settings",
		},
       
        {
			type = "checkbox",
			name = "PvP Zone Only",
			textType = TEXT_TYPE_NUMERIC_UNSIGNED_INT,
			tooltip = "Turn OFF to see CP in non pvp zones",
			default = DEFAULTS.isPvpOnly,
			getFunc = function() return DB.isPvpOnly end,
			setFunc = function(value)
				DB.isPvpOnly = value
			end,
		},
        {
			type = "checkbox",
			name = "Attackable (enemy) targets only",
			textType = TEXT_TYPE_NUMERIC_UNSIGNED_INT,
			tooltip = "Turn OFF to see non attackable targets (friendly players)",
			default = DEFAULTS.isAttackableOnly,
			getFunc = function() return DB.isAttackableOnly end,
			setFunc = function(value)
				DB.isAttackableOnly = value
			end,
		},
        {
			type = "button",
			name = "Reset to defaults",
			tooltip = "Resets to default values",
			func = function() 
                DB.isAttackableOnly = DEFAULTS.isAttackableOnly
                DB.isPvpOnly = DEFAULTS.isPvpOnly
			end,
		},

        {
			type = "header",
			name = "Alignment Settings",
		},

        {
			type = "editbox",
			name = "Font size",
			textType = TEXT_TYPE_NUMERIC_UNSIGNED_INT,
			tooltip = "Change how big the text is",
			default = DEFAULTS.fontSize,
			getFunc = function() return DB.fontSize end,
			setFunc = function(text)
				DB.fontSize = tonumber(text)
				UpdateFont()
			end,
		},
        {
			type = "editbox",
			name = "Alert horizontal offset",
			tooltip = "Positive ->, Negative <-",
			textType = TEXT_TYPE_NUMERIC_INT,
			default = DEFAULTS.CpOffset.x,
			getFunc = function() return DB.CpOffset.x end,
			setFunc = function(text)
				DB.CpOffset.x = tonumber(text)
				CreateAnchors()
			end,
		},
		{
			type = "editbox",
			name = "Alert vertical offset",
			tooltip = "Positive down, negative up",
			textType = TEXT_TYPE_NUMERIC_INT,
			default = DEFAULTS.CpOffset.y,
			getFunc = function() return DB.CpOffset.y end,
			setFunc = function(text)
				DB.CpOffset.y = tonumber(text)
				CreateAnchors()
			end,
		},
        {
			type = "button",
			name = "Reset positions",
			tooltip = "Resets positions",
			func = function() 
                DB.CpOffset.x = DEFAULTS.CpOffset.x
                DB.CpOffset.y = DEFAULTS.CpOffset.y
                DB.fontSize = DEFAULTS.fontSize
                CreateAnchors()
                UpdateFont()
			end,
		},
        {
			type = "header",
			name = "Group settings",
		},
        {
			type = "button",
			name = "Reset values",
			tooltip = "Resets all values back to their defaults",
			func = function() 
               for i, group in ipairs(DB.ChampionPointGroups) do
                group.lowCp = DEFAULTS.ChampionPointGroups[i].lowCp
                group.highCp = DEFAULTS.ChampionPointGroups[i].highCp
                group.color = DEFAULTS.ChampionPointGroups[i].color
                group.text = DEFAULTS.ChampionPointGroups[i].text
               end
			end,
		},
    }

    local optionsIndex = #options +1
  
    for i=1,#DEFAULTS.ChampionPointGroups do
      local result = createControlsForGroup(i, DB.ChampionPointGroups[i], DEFAULTS.ChampionPointGroups[i])
      for resulti=1,#result do
        options[optionsIndex] = result[resulti]
        optionsIndex = optionsIndex + 1
      end
    end



    LAM:RegisterOptionControls(panelName,options)
end


local function OnLoad(eventCode,addonName)
    if addonName == ADDON_NAME then
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    DB = ZO_SavedVars:NewAccountWide("LowChampionPointFinderVars", DATABASE_VERSION, nil, DEFAULTS)
    CreateSettingsMenu()
    CreateAnchors()
    UpdateFont()
    LOADED = true
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_RETICLE_TARGET_CHANGED, TargetChanged)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, CombatEvent)
    end
end


EVENT_MANAGER:RegisterForEvent(ADDON_NAME,EVENT_ADD_ON_LOADED,OnLoad)