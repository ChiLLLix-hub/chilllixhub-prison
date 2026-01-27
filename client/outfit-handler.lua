-- Outfit Handler for Prison Script
-- Handles saving and restoring player appearances when jailing/releasing
-- Requires: illenium-appearance resource with server:getAppearance callback support

local savedAppearance = nil
-- Time in milliseconds to wait after applying outfit to ensure it's fully rendered
local OUTFIT_APPLY_DELAY = 100

-- Component ID mapping: t-shirt=8, torso2=11, arms=3, pants=4, shoes=6
local COMPONENT_MAP = {
    ['t-shirt'] = 8,
    ['torso2'] = 11,
    ['arms'] = 3,
    ['pants'] = 4,
    ['shoes'] = 6
}

-- Prop IDs to clear: 0=hat, 1=glasses, 2=ear, 6=watch, 7=bracelet
local PROPS_TO_CLEAR = {0, 1, 2, 6, 7}

--- Saves the current player appearance to memory
--- Uses illenium-appearance:server:getAppearance callback which returns the player's current appearance data
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
    
    -- Convert uniform data to components using shared component map
    if uniformData and uniformData.outfitData then
        for key, data in pairs(uniformData.outfitData) do
            local componentId = COMPONENT_MAP[key]
            if componentId then
                appearance.components[componentId] = {
                    component_id = componentId,
                    drawable = data.item,
                    texture = data.texture
                }
            end
        end
    end
    
    -- Clear all accessories using shared prop list
    for _, propId in ipairs(PROPS_TO_CLEAR) do
        appearance.props[propId] = {
            prop_id = propId,
            drawable = -1,
            texture = -1
        }
    end
    
    return appearance
end

--- Applies outfit using native GTA functions
--- @param playerPed number The player ped ID
--- @param uniformData table The uniform data from config
local function ApplyOutfitNative(playerPed, uniformData)
    if not uniformData or not uniformData.outfitData then
        print('[Prison] Error: No outfit data found in config')
        return false
    end
    
    print('[Prison] Applying outfit components:')
    -- Apply outfit components using shared component map
    for key, data in pairs(uniformData.outfitData) do
        local componentId = COMPONENT_MAP[key]
        if componentId then
            print('[Prison]   - ' .. key .. ' (ID: ' .. componentId .. ') = drawable: ' .. data.item .. ', texture: ' .. data.texture)
            SetPedComponentVariation(playerPed, componentId, data.item, data.texture, 0)
        else
            print('[Prison]   - ' .. key .. ' (unknown component, skipping)')
        end
    end
    
    print('[Prison] Clearing accessories:')
    -- Clear accessories using shared prop list
    for _, propId in ipairs(PROPS_TO_CLEAR) do
        print('[Prison]   - Clearing prop ' .. propId)
        ClearPedProp(playerPed, propId)
    end
    
    print('[Prison] Native outfit application complete')
    return true
end

--- Applies the jail outfit to the player
--- @param playerPed number The player ped ID
--- @param gender number The player gender (0 = male, 1 = female)
local function ApplyJailOutfit(playerPed, gender)
    print('[Prison] ApplyJailOutfit called with gender: ' .. tostring(gender))
    local uniformData = gender == 0 and Config.Uniforms.male or Config.Uniforms.female
    
    if not DoesEntityExist(playerPed) then
        print('[Prison] Error: Player ped does not exist')
        return
    end
    
    print('[Prison] Player ped exists, checking uniform data...')
    if not uniformData then
        print('[Prison] Error: No uniform data for gender ' .. tostring(gender))
        return
    end
    
    if not uniformData.outfitData then
        print('[Prison] Error: uniformData.outfitData is nil')
        return
    end
    
    print('[Prison] Uniform data found, checking illenium-appearance...')
    
    -- Method 1: Try using illenium-appearance setPedAppearance export
    local resourceState = GetResourceState('illenium-appearance')
    print('[Prison] illenium-appearance resource state: ' .. tostring(resourceState))
    
    if resourceState == 'started' then
        print('[Prison] Trying illenium-appearance method...')
        local appearance = ConvertUniformToAppearance(uniformData)
        local success, err = pcall(function()
            exports['illenium-appearance']:setPedAppearance(playerPed, appearance)
        end)
        if success then
            print('[Prison] Applied jail outfit using setPedAppearance')
            Wait(OUTFIT_APPLY_DELAY)
            return
        else
            print('[Prison] setPedAppearance failed: ' .. tostring(err))
        end
    else
        print('[Prison] illenium-appearance resource not started (state: ' .. tostring(resourceState) .. '), using native fallback')
    end
    
    -- Method 2: Fallback to native GTA functions
    print('[Prison] Applying outfit using native functions')
    if ApplyOutfitNative(playerPed, uniformData) then
        print('[Prison] Applied jail outfit using native functions')
        Wait(OUTFIT_APPLY_DELAY)
    else
        print('[Prison] Failed to apply outfit using native functions')
    end
end

--- Restores the saved appearance to the player
--- @param playerPed number The player ped ID
local function RestoreSavedAppearance(playerPed)
    if not DoesEntityExist(playerPed) then
        print('[Prison] Error: Player ped does not exist')
        return
    end
    
    -- Try using illenium-appearance setPedAppearance if available
    if savedAppearance and GetResourceState('illenium-appearance') == 'started' then
        local success, err = pcall(function()
            exports['illenium-appearance']:setPedAppearance(playerPed, savedAppearance)
        end)
        if success then
            print('[Prison] Restored saved appearance using setPedAppearance')
            savedAppearance = nil
            return
        else
            print('[Prison] Error restoring appearance: ' .. tostring(err))
        end
    end
    
    -- Fallback: Use illenium-appearance reloadSkin event to load from database
    print('[Prison] Using reloadSkin fallback to restore appearance from database')
    TriggerEvent('illenium-appearance:client:reloadSkin')
    savedAppearance = nil
end

--- Main function to save appearance and apply jail outfit
--- Called when player is jailed
function SaveAndApplyJailOutfit()
    local playerPed = PlayerPedId()
    print('[Prison] Starting jail outfit application...')
    
    -- Reset player state
    SetPedArmour(playerPed, 0)
    ClearPedBloodDamage(playerPed)
    ResetPedVisibleDamage(playerPed)
    ClearPedLastWeaponDamage(playerPed)
    ResetPedMovementClipset(playerPed, 0)
    
    -- Get player data first
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.charinfo or playerData.charinfo.gender == nil then
        print('[Prison] Error: Unable to get player gender, defaulting to male outfit')
        ApplyJailOutfit(playerPed, 0) -- Default to male
        return
    end
    
    local gender = playerData.charinfo.gender
    print('[Prison] Player gender: ' .. tostring(gender))
    
    -- Apply outfit immediately first (to ensure it happens)
    print('[Prison] Applying outfit immediately...')
    ApplyJailOutfit(playerPed, gender)
    
    -- Wait a bit and apply again to ensure it sticks
    Wait(500)
    print('[Prison] Re-applying outfit to ensure it sticks...')
    ApplyJailOutfit(playerPed, gender)
    
    -- Then try to save current appearance for restoration later (best effort, async)
    SaveCurrentAppearance(function(success)
        if success then
            print('[Prison] Successfully saved current appearance for restoration')
        else
            print('[Prison] Warning: Failed to save current appearance, will reload from database on release')
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
