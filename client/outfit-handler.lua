-- Outfit Handler for Prison Script
-- Handles saving and restoring player appearances when jailing/releasing
-- Requires: illenium-appearance resource with server:getAppearance callback support

local savedAppearance = nil

--- Saves the current player appearance to memory
--- @param callback function Callback function to execute after saving
local function SaveCurrentAppearance(callback)
    QBCore.Functions.TriggerCallback('illenium-appearance:server:getAppearance', function(appearance)
        if appearance then
            savedAppearance = appearance
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    end)
end

--- Converts Config.Uniforms format to illenium-appearance component format
--- @param uniformData table The uniform data from config (with 't-shirt', 'torso2', etc.)
--- @return table appearance The converted appearance data
local function ConvertUniformToAppearance(uniformData)
    local appearance = {
        components = {},
        props = {}
    }
    
    -- Component ID mapping: t-shirt=8, torso2=11, arms=3, pants=4, shoes=6
    local componentMap = {
        ['t-shirt'] = 8,
        ['torso2'] = 11,
        ['arms'] = 3,
        ['pants'] = 4,
        ['shoes'] = 6
    }
    
    -- Convert uniform data to components
    if uniformData and uniformData.outfitData then
        for key, data in pairs(uniformData.outfitData) do
            local componentId = componentMap[key]
            if componentId then
                appearance.components[componentId] = {
                    component_id = componentId,
                    drawable = data.item,
                    texture = data.texture
                }
            end
        end
    end
    
    -- Clear all accessories (hats, glasses, watches, etc.)
    -- Prop IDs: 0=hat, 1=glasses, 2=ear, 6=watch, 7=bracelet
    local propsToRemove = {0, 1, 2, 6, 7}
    for _, propId in ipairs(propsToRemove) do
        appearance.props[propId] = {
            prop_id = propId,
            drawable = -1,
            texture = -1
        }
    end
    
    return appearance
end

--- Applies the jail outfit to the player
--- @param playerPed number The player ped ID
--- @param gender number The player gender (0 = male, 1 = female)
local function ApplyJailOutfit(playerPed, gender)
    local uniformData = gender == 0 and Config.Uniforms.male or Config.Uniforms.female
    local appearance = ConvertUniformToAppearance(uniformData)
    
    if DoesEntityExist(playerPed) then
        local success, err = pcall(function()
            exports['illenium-appearance']:setPedAppearance(playerPed, appearance)
        end)
        if not success then
            print('[Prison] Error applying jail outfit: ' .. tostring(err))
        end
    end
end

--- Restores the saved appearance to the player
--- @param playerPed number The player ped ID
local function RestoreSavedAppearance(playerPed)
    if savedAppearance and DoesEntityExist(playerPed) then
        local success, err = pcall(function()
            exports['illenium-appearance']:setPedAppearance(playerPed, savedAppearance)
        end)
        if success then
            savedAppearance = nil -- Clear after restoring
        else
            print('[Prison] Error restoring appearance: ' .. tostring(err))
            -- Fallback to reloadSkin if setPedAppearance fails
            TriggerEvent('illenium-appearance:client:reloadSkin')
            savedAppearance = nil
        end
    else
        -- Fallback to reloadSkin if no saved appearance
        TriggerEvent('illenium-appearance:client:reloadSkin')
    end
end

--- Main function to save appearance and apply jail outfit
--- Called when player is jailed
function SaveAndApplyJailOutfit()
    local playerPed = PlayerPedId()
    
    -- Reset player state
    SetPedArmour(playerPed, 0)
    ClearPedBloodDamage(playerPed)
    ResetPedVisibleDamage(playerPed)
    ClearPedLastWeaponDamage(playerPed)
    ResetPedMovementClipset(playerPed, 0)
    
    -- Save current appearance, then apply jail outfit
    SaveCurrentAppearance(function(success)
        local gender = QBCore.Functions.GetPlayerData().charinfo.gender
        if success then
            ApplyJailOutfit(playerPed, gender)
        else
            -- Even if save fails, still apply jail outfit
            -- Player will get DB appearance on release instead
            print('[Prison] Warning: Failed to save current appearance, will reload from database on release')
            ApplyJailOutfit(playerPed, gender)
        end
    end)
end

--- Main function to restore appearance
--- Called when player is released
function RestorePlayerAppearance()
    local playerPed = PlayerPedId()
    RestoreSavedAppearance(playerPed)
end

-- Export functions for use in main.lua
exports('SaveAndApplyJailOutfit', SaveAndApplyJailOutfit)
exports('RestorePlayerAppearance', RestorePlayerAppearance)
