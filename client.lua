-- ## To Do
-- Conditional Delay for Waypoint
-- Check for any other overhead usuage
-- It doubles routes, possible estimated 

-- Add this to qb-smallresources/config
--Config.MarkerColor = {0, 102, 204}  -- Fixed color: RGB (0, 102, 204)
--Config.MarkerAlpha = 150            -- Constant alpha value (transparency)
--Config.ScaleWithScreen = true       -- If false, uses a constant scale
--Config.Header = { TITLE = "Dokus World" }
--
---- Dynamqb scaling factors for the marker
--Config.WidthMultiplier  = 0.3       -- Multiplier for width based on distance
--Config.MinWidth         = 10.0      -- Minimum width so it remains visible when close
--Config.MaxWidth         = 25.0      -- Maximum width from far away
--
--Config.HeightMultiplier = 0.5       -- Multiplier for height based on distance
--Config.MinHeight        = 10.0      -- Minimum height when close
--Config.MaxHeight        = 10000.0   -- Maximum height from a distance
--
---- Pause Menu Colours
--Config.RGBA = {}
--Config.RGBA.LINE = { RED = 66, GREEN = 89, BLUE = 148, ALPHA = 255 }  -- Background
--Config.RGBA.STYLE = { RED = 66, GREEN = 89, BLUE = 148, ALPHA = 150 } -- Text 

local enableWaypoints = true
local lastWaypoint = nil

--------------------------------------------------------------------------------
-- Function to clear purple route if a waypoint is active
--------------------------------------------------------------------------------
local function ClearPurpleRouteIfActive()
    if IsWaypointActive() then
        ClearGpsMultiRoute()
    end
end

--------------------------------------------------------------------------------
-- Dynamic Marker / Route Thread
--------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        if not enableWaypoints then
            Citizen.Wait(500)
        else
            if not IsWaypointActive() then
                if lastWaypoint then
                    SetBlipRoute(lastWaypoint, false)
                    lastWaypoint = nil
                end
                Citizen.Wait(500)
            else
                Citizen.Wait(0)

                ClearPurpleRouteIfActive()

                local waypointBlip = GetFirstBlipInfoId(8)
                if DoesBlipExist(waypointBlip) then
                    local coords = GetBlipCoords(waypointBlip)
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local distance = #(playerCoords - coords)

                    local dynamicWidth = distance * Config.WidthMultiplier
                    if dynamicWidth < Config.MinWidth then dynamicWidth = Config.MinWidth end
                    if dynamicWidth > Config.MaxWidth then dynamicWidth = Config.MaxWidth end

                    local dynamicHeight = distance * Config.HeightMultiplier
                    if dynamicHeight < Config.MinHeight then dynamicHeight = Config.MinHeight end
                    if dynamicHeight > Config.MaxHeight then dynamicHeight = Config.MaxHeight end
                    dynamicHeight = math.floor(dynamicHeight * 100 + 0.5) / 100

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
                        0.0, 0.0, 0.0,  -- Offset
                        0.0, 0.0, 0.0,  -- Rotation
                        dynamicWidth, dynamicWidth, dynamicHeight,
                        Config.MarkerColor[1], Config.MarkerColor[2], Config.MarkerColor[3], Config.MarkerAlpha,
                        false, false, false, false, nil, nil, false
                    )
                else
                    if lastWaypoint then
                        SetBlipRoute(lastWaypoint, false)
                        lastWaypoint = nil
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- Simple wrapper for text entry
--------------------------------------------------------------------------------
local function AddTextEntry(key, value)
    Citizen.InvokeNative(0x32CA01C3, key, value)
end

--------------------------------------------------------------------------------
-- Handle Pause Menu Text Replacement
--------------------------------------------------------------------------------
local function ApplyTextReplacements()
    local replacer = {
        ["TITLE"] = "FE_THDR_GTAO"
    }
    for key, entry in pairs(replacer) do
        if Config.Header[key] then
            AddTextEntry(entry, Config.Header[key])
        end
    end
end

--------------------------------------------------------------------------------
-- Retrieve character information
--------------------------------------------------------------------------------
local function GetCharacterInfo()
    local playerData = exports['ic-core']:GetCoreObject().Functions.GetPlayerData()
    local name = (playerData.charinfo.firstname or "") .. " " .. (playerData.charinfo.lastname or "")
    local bankBalance = math.floor(playerData.money["bank"] or 0)
    local cashBalance = math.floor(playerData.money["cash"] or 0)
    local jobTitle = (playerData.job.label or playerData.job.name) or "N/A"
    local serverId = GetPlayerServerId(PlayerId())
    local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber() or "N/A"

    return name, serverId, bankBalance, cashBalance, phoneNumber, jobTitle
end

--------------------------------------------------------------------------------
-- Pause Menu Thread
--------------------------------------------------------------------------------
Citizen.CreateThread(function()
    ApplyTextReplacements()

    while true do
        if not IsPauseMenuActive() then
            Citizen.Wait(250)
        else
            Citizen.Wait(0)

            ReplaceHudColourWithRgba(116, Config.RGBA.LINE.RED, Config.RGBA.LINE.GREEN, Config.RGBA.LINE.BLUE, Config.RGBA.LINE.ALPHA)
            ReplaceHudColourWithRgba(117, Config.RGBA.STYLE.RED, Config.RGBA.STYLE.GREEN, Config.RGBA.STYLE.BLUE, Config.RGBA.STYLE.ALPHA)

            local characterName, characterId, bankBalance, cashBalance, phoneNumber, jobTitle = GetCharacterInfo()
            local characterBalance = ("Bank: $%d | Cash: $%d"):format(bankBalance, cashBalance)
            local idAndPhoneNumber = ("ID: %d | Phone: %s"):format(characterId, phoneNumber)
            local topRowText = ("%s - %s"):format(characterName, jobTitle)

            SetScriptGfxDrawBehindPausemenu(true)
            BeginScaleformMovieMethodOnFrontendHeader("SET_HEADING_DETAILS")
            PushScaleformMovieFunctionParameterString(topRowText)
            PushScaleformMovieFunctionParameterString(characterBalance)
            PushScaleformMovieFunctionParameterString(idAndPhoneNumber)
            EndScaleformMovieMethod()
        end
    end
end)