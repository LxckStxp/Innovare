-- Core/PluginManager.lua
--[[
    PluginManager Module
    Handles plugin loading, initialization, and management for Innovare
    Author: LxckStxp
    
    Usage example:
    local PluginManager = require(path.to.PluginManager)
    local window, content = Censura.Elements.Window.new(...)
    PluginManager.Init(window, content)
    PluginManager.LoadPlugin("ESP")
--]]

local PluginManager = {
    _initialized = false,
    _plugins = {},
    _activePlugins = {}
}

-- Get logger instance
local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})

-- Private variables
local mainWindow
local mainContent
local tabSystem
local Censura = _G.Innovare.System.Censura

-- Private Functions
local function verifyDependencies()
    if not Censura then
        Ora:Error("Censura not available")
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

local function setupTabSystem()
    local success, result = pcall(function()
        -- Create new TabSystem
        local newTabSystem = Censura.Elements.TabSystem.new()
        if not newTabSystem then
            error("Failed to create TabSystem instance")
        end
        
        -- Parent to content frame
        newTabSystem.Parent = mainContent
        
        -- Create default tabs
        local settingsTab = newTabSystem:AddTab("Settings")
        if not settingsTab then
            error("Failed to create Settings tab")
        end
        
        -- Create settings section
        local settingsSection = Censura.Elements.Section.new({
            title = "Plugin Management"
        })
        settingsSection.Parent = settingsTab
        
        return newTabSystem
    end)
    
    if not success then
        Ora:Error("Failed to setup TabSystem: " .. tostring(result))
        return nil
    end
    
    return result
end

-- Public Functions
function PluginManager.Init(window, content)
    if PluginManager._initialized then
        Ora:Warn("PluginManager already initialized")
        return false
    end
    
    Ora:Info("Initializing PluginManager...")
    
    -- Verify parameters
    if not window or not content then
        Ora:Error("Window or content frame not provided")
        return false
    end
    
    -- Verify dependencies
    if not verifyDependencies() then
        return false
    end
    
    -- Store references
    mainWindow = window
    mainContent = content
    
    -- Setup tab system
    tabSystem = setupTabSystem()
    if not tabSystem then
        return false
    end
    
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
        -- Load plugin module
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
        pluginName = plugin.Name or "UnnamedPlugin"
    end
    
    -- Validate plugin structure
    if type(plugin) ~= "table" or type(plugin.Init) ~= "function" then
        Ora:Error("Invalid plugin structure for: " .. pluginName)
        return false
    end
    
    -- Create plugin tab
    local success, pluginTab = pcall(function()
        return tabSystem:AddTab(pluginName)
    end)
    
    if not success or not pluginTab then
        Ora:Error("Failed to create tab for plugin: " .. pluginName)
        return false
    end
    
    -- Initialize plugin
    success, result = pcall(function()
        plugin.Init(pluginTab)
    end)
    
    if not success then
        Ora:Error("Failed to initialize plugin: " .. pluginName .. " - " .. tostring(result))
        return false
    end
    
    -- Store plugin reference
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
    
    -- Call cleanup if available
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
    _G.Innovare.Plugins[pluginName] = nil
    
    Ora:Info("Successfully unloaded plugin: " .. pluginName)
    return true
end

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

-- Debug Functions
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

-- Example Usage:
--[[
    -- Initialize PluginManager
    local window, content = Censura.Elements.Window.new({
        title = "My Window",
        size = UDim2.new(0, 400, 0, 500)
    })
    PluginManager.Init(window, content)
    
    -- Load a plugin by name
    PluginManager.LoadPlugin("ESP")
    
    -- Load a plugin module directly
    local MyPlugin = {
        Name = "CustomPlugin",
        Init = function(tab)
            -- Plugin initialization code
        end,
        Cleanup = function()
            -- Plugin cleanup code
        end
    }
    PluginManager.LoadPlugin(MyPlugin)
    
    -- Enable/Disable plugins
    PluginManager.DisablePlugin("ESP")
    PluginManager.EnablePlugin("ESP")
    
    -- Debug information
    PluginManager.Debug()
--]]

return PluginManager
