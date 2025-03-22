-- ## To Do
-- Conditional Delay for Waypoint
-- Check for any other overhead usuage

Config = {}
Config.MarkerColor = {0, 102, 204}  -- Fixed color: RGB (0, 102, 204)
Config.MarkerAlpha = 150            -- Constant alpha value (transparency)
Config.ScaleWithScreen = true       -- If false, uses a constant scale
Config.Header = { TITLE = "Dokus World" }

-- Dynamqb scaling factors for the marker
Config.WidthMultiplier  = 0.3       -- Multiplier for width based on distance
Config.MinWidth         = 10.0      -- Minimum width so it remains visible when close
Config.MaxWidth         = 25.0      -- Maximum width from far away

Config.HeightMultiplier = 0.5       -- Multiplier for height based on distance
Config.MinHeight        = 10.0      -- Minimum height when close
Config.MaxHeight        = 10000.0   -- Maximum height from a distance

-- Pause Menu Colours
Config.RGBA = {}
Config.RGBA.LINE = { RED = 66, GREEN = 89, BLUE = 148, ALPHA = 255 }  -- Background
Config.RGBA.STYLE = { RED = 66, GREEN = 89, BLUE = 148, ALPHA = 150 } -- Text 

local enableWaypoints = true
local lastWaypoint = nil

-- Clears purple waypoint
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsWaypointActive() then
            ClearGpsMultiRoute()
        end
    end
end)

-- Waypoint marker thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if enableWaypoints then
            local waypointBlip = GetFirstBlipInfoId(8)
            if DoesBlipExist(waypointBlip) then
                local coords = GetBlipCoords(waypointBlip)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - coords)
                
                local dynamqbWidth = distance * Config.WidthMultiplier
                if dynamqbWidth < Config.MinWidth then dynamqbWidth = Config.MinWidth end
                if dynamqbWidth > Config.MaxWidth then dynamqbWidth = Config.MaxWidth end
                
                local dynamqbHeight = distance * Config.HeightMultiplier
                if dynamqbHeight < Config.MinHeight then dynamqbHeight = Config.MinHeight end
                if dynamqbHeight > Config.MaxHeight then dynamqbHeight = Config.MaxHeight end
                dynamqbHeight = math.floor(dynamqbHeight * 100 + 0.5) / 100
                
                if waypointBlip ~= lastWaypoint then
                    if lastWaypoint then
                        SetBlipRoute(lastWaypoint, false)
                    end
                    SetBlipRoute(waypointBlip, true)
                    ReplaceHudColourWithRgba(142, 66, 89, 148, 255)
                    lastWaypoint = waypointBlip
                end
                
                DrawMarker(
                    1,  -- Marker type
                    coords.x, coords.y, coords.z,
                    0, 0, 0,            -- Offset
                    0, 0, 0,            -- Rotation
                    dynamqbWidth, dynamqbWidth, dynamqbHeight,
                    Config.MarkerColor[1], Config.MarkerColor[2], Config.MarkerColor[3], Config.MarkerAlpha,
                    false, false, false, 0, nil, nil, false
                )
            else
                if lastWaypoint then
                    SetBlipRoute(lastWaypoint, false)
                    lastWaypoint = nil
                end
            end
        end
    end
end)

-- Pause Menu Text Replacement
function ApplyTextReplacements()
    local replacer = {
        ["TITLE"] = "FE_THDR_GTAO"
    }
    for key, entry in pairs(replacer) do
        if Config.Header[key] then
            AddTextEntry(entry, Config.Header[key])
        end
    end
end

-- Wrapper for Text Entries
function AddTextEntry(key, value)
    Citizen.InvokeNative(0x32CA01C3, key, value)
end

-- Retrieve character information
function GetCharacterInfo()
    local playerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
    local name = playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname
    local bankBalance = math.floor(playerData.money["bank"])
    local cashBalance = math.floor(playerData.money["cash"])
    local jobTitle = playerData.job.label or playerData.job.name
    local serverId = GetPlayerServerId(PlayerId())
    local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber() or "N/A"
    
    return name, serverId, bankBalance, cashBalance, phoneNumber, jobTitle
end

-- Pause Menu thread
Citizen.CreateThread(function()
    ApplyTextReplacements()
    while true do
        Citizen.Wait(1)
        if IsPauseMenuActive() then
            ReplaceHudColourWithRgba(116, Config.RGBA.LINE.RED, Config.RGBA.LINE.GREEN, Config.RGBA.LINE.BLUE, Config.RGBA.LINE.ALPHA)
            ReplaceHudColourWithRgba(117, Config.RGBA.STYLE.RED, Config.RGBA.STYLE.GREEN, Config.RGBA.STYLE.BLUE, Config.RGBA.STYLE.ALPHA)
            
            local characterName, characterId, bankBalance, cashBalance, phoneNumber, jobTitle = GetCharacterInfo()
            local characterBalance = "Bank: $" .. bankBalance .. " | Cash: $" .. cashBalance
            local idAndPhoneNumber = "ID: " .. characterId .. " | Phone: " .. phoneNumber
            local topRowText = characterName .. " - " .. jobTitle
            
            SetScriptGfxDrawBehindPausemenu(true)
            BeginScaleformMovieMethodOnFrontendHeader("SET_HEADING_DETAILS")
            PushScaleformMovieFunctionParameterString(topRowText)
            PushScaleformMovieFunctionParameterString(characterBalance)
            PushScaleformMovieFunctionParameterString(idAndPhoneNumber)
            EndScaleformMovieMethod()
        end
    end
end)