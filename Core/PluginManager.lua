-- Core/PluginManager.lua
local PluginManager = {}

-- Get dependencies
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})

-- Private variables
local mainWindow
local tabSystem
local Censura = _G.Innovare.System.Censura

-- Verify UI system
local function verifyUISystem()
    if not Censura then
        Ora:Error("Censura not found")
        return false
    end
    
    if not Censura.Elements then
        Ora:Error("Censura Elements not available")
        return false
    end
    
    if not Censura.Elements.TabSystem then
        Ora:Error("TabSystem element not found")
        return false
    end
    
    return true
end

function PluginManager.Init(window)
    Ora:Info("Initializing PluginManager...")
    
    if not verifyUISystem() then
        return false
    end
    
    -- Store window reference
    mainWindow = window
    
    -- Create content frame for tabs if it doesn't exist
    if not window.content then
        Ora:Error("Window content frame not found")
        return false
    end
    
    -- Create tab system
    local success, result = pcall(function()
        -- Create new tab system instance
        local newTabSystem = Censura.Elements.TabSystem.new()
        
        -- Verify tab system was created
        if not newTabSystem then
            error("Failed to create TabSystem instance")
        end
        
        -- Set parent
        newTabSystem.Parent = window.content
        
        return newTabSystem
    end)
    
    if not success then
        Ora:Error("Failed to create TabSystem: " .. tostring(result))
        return false
    end
    
    -- Store tab system reference
    tabSystem = result
    
    -- Verify tab system methods
    if not tabSystem.AddTab then
        Ora:Error("TabSystem.AddTab method not found")
        return false
    end
    
    -- Create Settings tab as a test
    local settingsTab = tabSystem:AddTab("Settings")
    if not settingsTab then
        Ora:Error("Failed to create Settings tab")
        return false
    end
    
    Ora:Info("PluginManager initialized successfully")
    return true
end

function PluginManager.LoadPlugin(pluginNameOrModule)
    if not tabSystem then
        Ora:Error("TabSystem not initialized")
        return false
    end
    
    local pluginName = type(pluginNameOrModule) == "string" and pluginNameOrModule or pluginNameOrModule.Name
    Ora:Info("Loading plugin: " .. pluginName)
    
    -- Load plugin module
    local plugin
    if type(pluginNameOrModule) == "string" then
        local success, result = pcall(function()
            return _G.Innovare.System.LoadModule("Plugins/" .. pluginNameOrModule .. "/init")
        end)
        
        if not success or not result then
            Ora:Error("Failed to load plugin module: " .. pluginName)
            return false
        end
        
        plugin = result
    else
        plugin = pluginNameOrModule
    end
    
    -- Create plugin tab
    local pluginTab
    local success, result = pcall(function()
        return tabSystem:AddTab(pluginName)
    end)
    
    if not success or not result then
        Ora:Error("Failed to create tab for plugin: " .. pluginName)
        return false
    end
    
    pluginTab = result
    
    -- Initialize plugin
    success, result = pcall(function()
        if type(plugin.Init) ~= "function" then
            error("Plugin does not have an Init function")
        end
        plugin.Init(pluginTab)
    end)
    
    if not success then
        Ora:Error("Failed to initialize plugin: " .. pluginName .. " - " .. tostring(result))
        return false
    end
    
    -- Store plugin reference
    _G.Innovare.Plugins[pluginName] = plugin
    
    Ora:Info("Successfully loaded plugin: " .. pluginName)
    return true
end

-- Add utility functions
function PluginManager.GetLoadedPlugins()
    local plugins = {}
    for name, _ in pairs(_G.Innovare.Plugins) do
        table.insert(plugins, name)
    end
    return plugins
end

function PluginManager.IsPluginLoaded(pluginName)
    return _G.Innovare.Plugins[pluginName] ~= nil
end

-- Debug function
function PluginManager.DebugTabSystem()
    print("TabSystem Status:")
    print("TabSystem exists:", tabSystem ~= nil)
    if tabSystem then
        print("AddTab method exists:", typeof(tabSystem.AddTab) == "function")
        print("TabSystem parent:", tabSystem.Parent and tabSystem.Parent:GetFullName() or "No parent")
        print("TabSystem methods:", table.concat(
            table.create(
                table.getn(
                    getmetatable(tabSystem) or {}
                )
            ), ", "
        ))
    end
end

return PluginManager
