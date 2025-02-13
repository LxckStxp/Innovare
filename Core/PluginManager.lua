-- PluginManager.lua
-- Core plugin management system for Innovare
-- Version: 1.0.0

local PluginManager = {
    _initialized = false,
    _plugins = {},
    _activePlugins = {},
    _tabs = {}
}

-- Services & References
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})
local Censura = _G.Innovare.System.Censura

-- Private Variables
local mainWindow
local mainContent
local tabSystem

-- Initialize the plugin manager
function PluginManager.Init(window, content)
    if PluginManager._initialized then
        Ora:Warn("PluginManager already initialized")
        return false
    end
    
    Ora:Info("Initializing PluginManager...")
    
    -- Store references
    mainWindow = window
    mainContent = content
    
    -- Create TabSystem
    local success, result = pcall(function()
        -- Create TabSystem using Censura
        local newTabSystem = Censura.Elements.TabSystem.new()
        if not newTabSystem then
            error("Failed to create TabSystem")
        end
        
        -- Parent to content
        newTabSystem.Parent = mainContent
        
        -- Create Settings tab
        local settingsTab = newTabSystem:AddTab("Settings")
        if not settingsTab then
            error("Failed to create Settings tab")
        end
        
        -- Add settings section
        local settingsSection = Censura.Elements.Section.new({
            title = "Plugin Management"
        })
        settingsSection.Parent = settingsTab
        
        return newTabSystem
    end)
    
    if not success then
        Ora:Error("Failed to setup TabSystem: " .. tostring(result))
        return false
    end
    
    tabSystem = result
    PluginManager._initialized = true
    
    Ora:Info("PluginManager initialized successfully")
    return true
end

-- Load a plugin
function PluginManager.LoadPlugin(pluginNameOrModule)
    if not PluginManager._initialized then
        Ora:Error("PluginManager not initialized")
        return false
    end
    
    -- Handle plugin input
    local pluginName, plugin
    if type(pluginNameOrModule) == "string" then
        pluginName = pluginNameOrModule
        -- Load plugin module
        local success, result = pcall(function()
            return _G.Innovare.System.LoadModule("Plugins/" .. pluginNameOrModule .. "/init")
        end)
        
        if not success then
            Ora:Error("Failed to load plugin module: " .. pluginName)
            return false
        end
        
        plugin = result
    else
        plugin = pluginNameOrModule
        pluginName = plugin.Name or "UnnamedPlugin"
    end
    
    -- Validate plugin
    if type(plugin) ~= "table" or type(plugin.Init) ~= "function" then
        Ora:Error("Invalid plugin structure: " .. pluginName)
        return false
    end
    
    -- Create plugin tab
    local pluginTab = tabSystem:AddTab(pluginName)
    if not pluginTab then
        Ora:Error("Failed to create tab for: " .. pluginName)
        return false
    end
    
    -- Initialize plugin
    local success, error = pcall(function()
        plugin.Init(pluginTab)
    end)
    
    if not success then
        Ora:Error("Plugin initialization failed: " .. tostring(error))
        return false
    end
    
    -- Store plugin references
    PluginManager._plugins[pluginName] = plugin
    PluginManager._activePlugins[pluginName] = true
    PluginManager._tabs[pluginName] = pluginTab
    _G.Innovare.Plugins[pluginName] = plugin
    
    Ora:Info("Successfully loaded plugin: " .. pluginName)
    return true
end

-- Unload a plugin
function PluginManager.UnloadPlugin(pluginName)
    local plugin = PluginManager._plugins[pluginName]
    if not plugin then
        Ora:Warn("Plugin not found: " .. pluginName)
        return false
    end
    
    -- Cleanup plugin
    if plugin.Cleanup then
        local success, error = pcall(function()
            plugin:Cleanup()
        end)
        
        if not success then
            Ora:Error("Failed to cleanup plugin: " .. pluginName .. " - " .. error)
        end
    end
    
    -- Remove references
    PluginManager._plugins[pluginName] = nil
    PluginManager._activePlugins[pluginName] = nil
    PluginManager._tabs[pluginName] = nil
    _G.Innovare.Plugins[pluginName] = nil
    
    Ora:Info("Successfully unloaded plugin: " .. pluginName)
    return true
end

-- Enable a plugin
function PluginManager.EnablePlugin(pluginName)
    local plugin = PluginManager._plugins[pluginName]
    if not plugin then return false end
    
    if plugin.Enable then
        local success, error = pcall(function()
            plugin:Enable()
        end)
        
        if success then
            PluginManager._activePlugins[pluginName] = true
            return true
        else
            Ora:Error("Failed to enable plugin: " .. pluginName .. " - " .. error)
        end
    end
    return false
end

-- Disable a plugin
function PluginManager.DisablePlugin(pluginName)
    local plugin = PluginManager._plugins[pluginName]
    if not plugin then return false end
    
    if plugin.Disable then
        local success, error = pcall(function()
            plugin:Disable()
        end)
        
        if success then
            PluginManager._activePlugins[pluginName] = false
            return true
        else
            Ora:Error("Failed to disable plugin: " .. pluginName .. " - " .. error)
        end
    end
    return false
end

-- Utility Functions
function PluginManager.GetLoadedPlugins()
    local plugins = {}
    for name, _ in pairs(PluginManager._plugins) do
        table.insert(plugins, name)
    end
    return plugins
end

function PluginManager.IsPluginLoaded(pluginName)
    return PluginManager._plugins[pluginName] ~= nil
end

function PluginManager.IsPluginEnabled(pluginName)
    return PluginManager._activePlugins[pluginName] == true
end

-- Debug Function
function PluginManager.Debug()
    print("\n=== PluginManager Debug ===")
    print("Initialized:", PluginManager._initialized)
    print("Window exists:", mainWindow ~= nil)
    print("Content exists:", mainContent ~= nil)
    print("TabSystem exists:", tabSystem ~= nil)
    
    if mainContent then
        print("\nContent Children:")
        for _, child in ipairs(mainContent:GetChildren()) do
            print("- " .. child.Name .. " (" .. child.ClassName .. ")")
        end
    end
    
    print("\nLoaded Plugins:")
    for name, plugin in pairs(PluginManager._plugins) do
        print("- " .. name .. " (Enabled: " .. tostring(PluginManager._activePlugins[name]) .. ")")
    end
    print("=========================\n")
end

return PluginManager
