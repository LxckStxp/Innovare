-- PluginManager.lua
-- Core plugin management system for Innovare
-- Author: LxckStxp
-- Version: 1.0.0

local PluginManager = {
    _initialized = false,
    _plugins = {},
    _activePlugins = {}
}

-- Services & References
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})
local TabSystem = _G.Innovare.Modules.TabSystem

-- Private Functions
local function validatePlugin(plugin)
    -- Check plugin structure
    if type(plugin) ~= "table" then
        return false, "Plugin must be a table"
    end
    
    -- Check required functions
    if type(plugin.Init) ~= "function" then
        return false, "Plugin must have Init function"
    end
    
    -- Check optional functions
    local optionalFunctions = {"Enable", "Disable", "Cleanup"}
    for _, funcName in ipairs(optionalFunctions) do
        if plugin[funcName] and type(plugin[funcName]) ~= "function" then
            return false, funcName .. " must be a function if provided"
        end
    end
    
    return true
end

-- Public Functions
function PluginManager.Init(window, tabSystem)
    if PluginManager._initialized then
        Ora:Warn("PluginManager already initialized")
        return false
    end
    
    Ora:Info("Initializing PluginManager...")
    
    if not tabSystem._initialized then
        Ora:Error("TabSystem must be initialized before PluginManager")
        return false
    end
    
    -- Store references
    mainWindow = window
    PluginManager.tabSystem = tabSystem
    PluginManager._initialized = true
    
    Ora:Info("PluginManager initialized successfully")
    return true
end

function PluginManager.LoadPlugin(pluginNameOrModule)
    if not PluginManager._initialized then
        Ora:Error("PluginManager not initialized")
        return false
    end
    
    -- Handle plugin input
    local pluginName, plugin
    if type(pluginNameOrModule) == "string" then
        pluginName = pluginNameOrModule
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
    
    -- Create plugin tab using TabSystem reference
    local pluginTab = PluginManager.tabSystem:AddTab(pluginName)
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
        PluginManager.tabSystem:RemoveTab(pluginName)
        return false
    end
    
    -- Store plugin
    PluginManager._plugins[pluginName] = plugin
    PluginManager._activePlugins[pluginName] = true
    _G.Innovare.Plugins[pluginName] = plugin
    
    Ora:Info("Successfully loaded plugin: " .. pluginName)
    return true
end

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
    
    -- Remove tab
    TabSystem.RemoveTab(pluginName)
    
    -- Remove references
    PluginManager._plugins[pluginName] = nil
    PluginManager._activePlugins[pluginName] = nil
    _G.Innovare.Plugins[pluginName] = nil
    
    Ora:Info("Successfully unloaded plugin: " .. pluginName)
    return true
end

function PluginManager.EnablePlugin(pluginName)
    local plugin = PluginManager._plugins[pluginName]
    if not plugin then 
        Ora:Error("Plugin not found: " .. pluginName)
        return false 
    end
    
    if plugin.Enable then
        local success, error = pcall(function()
            plugin:Enable()
        end)
        
        if success then
            PluginManager._activePlugins[pluginName] = true
            Ora:Info("Enabled plugin: " .. pluginName)
            return true
        else
            Ora:Error("Failed to enable plugin: " .. pluginName .. " - " .. error)
        end
    end
    return false
end

function PluginManager.DisablePlugin(pluginName)
    local plugin = PluginManager._plugins[pluginName]
    if not plugin then 
        Ora:Error("Plugin not found: " .. pluginName)
        return false 
    end
    
    if plugin.Disable then
        local success, error = pcall(function()
            plugin:Disable()
        end)
        
        if success then
            PluginManager._activePlugins[pluginName] = false
            Ora:Info("Disabled plugin: " .. pluginName)
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
    
    print("\nLoaded Plugins:")
    for name, plugin in pairs(PluginManager._plugins) do
        print(string.format("- %s:", name))
        print("  Enabled:", PluginManager._activePlugins[name])
        print("  Functions:")
        for funcName, func in pairs(plugin) do
            if type(func) == "function" then
                print("    -", funcName)
            end
        end
    end
    
    -- Debug TabSystem
    print("\nTabSystem Status:")
    TabSystem.Debug()
    
    print("=========================\n")
end

return PluginManager
