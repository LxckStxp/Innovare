-- Core/PluginManager.lua
local PluginManager = {
    ActivePlugins = {},    -- Stores currently active plugin instances
    PluginStates = {},     -- Tracks plugin states (enabled/disabled)
    LoadOrder = {},        -- Tracks plugin load order
    Connections = {}       -- Stores plugin-related connections
}

-- Get references to core systems
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})

-- Private variables
local mainWindow
local tabSystem
local Censura = _G.Innovare.System.Censura

-- Private functions
local function verifyPlugin(plugin)
    if type(plugin) ~= "table" then
        return false, "Plugin must be a table"
    end
    
    if type(plugin.Init) ~= "function" then
        return false, "Plugin must have Init function"
    end
    
    return true
end

local function setupPluginTab(pluginName)
    if not tabSystem then
        return nil, "TabSystem not initialized"
    end
    
    local success, tab = pcall(function()
        return tabSystem:AddTab(pluginName)
    end)
    
    if not success or not tab then
        return nil, "Failed to create tab for plugin: " .. pluginName
    end
    
    return tab
end

-- Public functions
function PluginManager.Init(window)
    Ora:Info("Initializing PluginManager...")
    
    -- Verify dependencies
    if not Censura then
        Ora:Error("Censura not found")
        return false
    end
    
    if not Censura.Elements then
        Ora:Error("Censura Elements not available")
        return false
    end
    
    -- Store window reference
    mainWindow = window
    
    -- Create tab system
    local success, result = pcall(function()
        local newTabSystem = Censura.Elements.TabSystem.new()
        newTabSystem.Parent = mainWindow.content
        return newTabSystem
    end)
    
    if not success or not result then
        Ora:Error("Failed to create TabSystem: " .. tostring(result))
        return false
    end
    
    tabSystem = result
    
    -- Create Settings tab
    local settingsTab = tabSystem:AddTab("Settings")
    
    -- Create settings section
    local settingsSection = Censura.Elements.Section.new({
        title = "Plugin Settings"
    })
    settingsSection.Parent = settingsTab
    
    -- Add plugin management controls
    Censura.Elements.Label.new({
        text = "Loaded Plugins:",
        height = 30
    }).Parent = settingsSection
    
    Ora:Info("PluginManager initialized successfully")
    return true
end

function PluginManager.LoadPlugin(pluginNameOrModule)
    local pluginName = type(pluginNameOrModule) == "string" and pluginNameOrModule or pluginNameOrModule.Name
    
    Ora:Info("Loading plugin: " .. pluginName)
    
    -- Load plugin module if name provided
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
    
    -- Verify plugin structure
    local isValid, error = verifyPlugin(plugin)
    if not isValid then
        Ora:Error("Invalid plugin structure: " .. error)
        return false
    end
    
    -- Create plugin tab
    local tab, error = setupPluginTab(pluginName)
    if not tab then
        Ora:Error(error)
        return false
    end
    
    -- Initialize plugin
    local success, result = pcall(function()
        plugin.Init(tab)
    end)
    
    if not success then
        Ora:Error("Failed to initialize plugin: " .. pluginName .. " - " .. tostring(result))
        return false
    end
    
    -- Store plugin reference
    PluginManager.ActivePlugins[pluginName] = plugin
    PluginManager.PluginStates[pluginName] = true
    table.insert(PluginManager.LoadOrder, pluginName)
    
    -- Store in global plugins table
    _G.Innovare.Plugins[pluginName] = plugin
    
    Ora:Info("Successfully loaded plugin: " .. pluginName)
    return true
end

function PluginManager.UnloadPlugin(pluginName)
    local plugin = PluginManager.ActivePlugins[pluginName]
    if not plugin then
        Ora:Warn("Plugin not found: " .. pluginName)
        return false
    end
    
    -- Call cleanup if available
    if plugin.Cleanup then
        local success, error = pcall(function()
            plugin:Cleanup()
        end)
        
        if not success then
            Ora:Error("Failed to cleanup plugin: " .. pluginName .. " - " .. tostring(error))
        end
    end
    
    -- Remove from tracking tables
    PluginManager.ActivePlugins[pluginName] = nil
    PluginManager.PluginStates[pluginName] = nil
    _G.Innovare.Plugins[pluginName] = nil
    
    -- Remove from load order
    for i, name in ipairs(PluginManager.LoadOrder) do
        if name == pluginName then
            table.remove(PluginManager.LoadOrder, i)
            break
        end
    end
    
    Ora:Info("Successfully unloaded plugin: " .. pluginName)
    return true
end

function PluginManager.GetLoadedPlugins()
    local plugins = {}
    for name, _ in pairs(PluginManager.ActivePlugins) do
        table.insert(plugins, name)
    end
    return plugins
end

function PluginManager.IsPluginLoaded(pluginName)
    return PluginManager.ActivePlugins[pluginName] ~= nil
end

function PluginManager.EnablePlugin(pluginName)
    local plugin = PluginManager.ActivePlugins[pluginName]
    if not plugin then return false end
    
    if plugin.Enable then
        local success, error = pcall(function()
            plugin:Enable()
        end)
        
        if success then
            PluginManager.PluginStates[pluginName] = true
            return true
        else
            Ora:Error("Failed to enable plugin: " .. pluginName .. " - " .. tostring(error))
        end
    end
    return false
end

function PluginManager.DisablePlugin(pluginName)
    local plugin = PluginManager.ActivePlugins[pluginName]
    if not plugin then return false end
    
    if plugin.Disable then
        local success, error = pcall(function()
            plugin:Disable()
        end)
        
        if success then
            PluginManager.PluginStates[pluginName] = false
            return true
        else
            Ora:Error("Failed to disable plugin: " .. pluginName .. " - " .. tostring(error))
        end
    end
    return false
end

-- Cleanup function
function PluginManager.Cleanup()
    -- Unload all plugins
    for pluginName, _ in pairs(PluginManager.ActivePlugins) do
        PluginManager.UnloadPlugin(pluginName)
    end
    
    -- Clear connections
    for _, connection in pairs(PluginManager.Connections) do
        connection:Disconnect()
    end
    
    -- Clear tables
    table.clear(PluginManager.ActivePlugins)
    table.clear(PluginManager.PluginStates)
    table.clear(PluginManager.LoadOrder)
    table.clear(PluginManager.Connections)
end

return PluginManager
