-- Core/PluginManager.lua
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

-- Debug function to verify Censura state
local function debugCensura()
    print("\n=== Censura Debug ===")
    print("Censura exists:", Censura ~= nil)
    if Censura then
        print("Elements exists:", Censura.Elements ~= nil)
        if Censura.Elements then
            print("Available Elements:")
            for name, element in pairs(Censura.Elements) do
                print("- " .. name)
            end
            print("\nTabSystem exists:", Censura.Elements.TabSystem ~= nil)
        end
    end
    print("=====================\n")
end

-- Initialize the tab system
local function createTabSystem()
    -- Debug output
    debugCensura()
    
    -- Create the tab system
    local success, newTabSystem = pcall(function()
        local ts = Censura.Elements.TabSystem.new()
        ts.Parent = mainContent
        return ts
    end)
    
    if not success or not newTabSystem then
        Ora:Error("Failed to create TabSystem: " .. tostring(newTabSystem))
        return nil
    end
    
    -- Create initial tab
    success, result = pcall(function()
        return newTabSystem:AddTab("Settings")
    end)
    
    if not success then
        Ora:Error("Failed to create Settings tab: " .. tostring(result))
        return nil
    end
    
    return newTabSystem
end

-- Public Functions
function PluginManager.Init(window, content)
    Ora:Info("Initializing PluginManager...")
    
    -- Store window references
    mainWindow = window
    mainContent = content
    
    -- Create tab system
    tabSystem = createTabSystem()
    if not tabSystem then
        return false
    end
    
    PluginManager._initialized = true
    return true
end

-- Simple plugin loading
function PluginManager.LoadPlugin(pluginName)
    if not PluginManager._initialized then
        Ora:Error("PluginManager not initialized")
        return false
    end
    
    -- Load plugin module
    local success, plugin = pcall(function()
        return _G.Innovare.System.LoadModule("Plugins/" .. pluginName .. "/init")
    end)
    
    if not success then
        Ora:Error("Failed to load plugin: " .. pluginName)
        return false
    end
    
    -- Create tab for plugin
    local pluginTab = tabSystem:AddTab(pluginName)
    if not pluginTab then
        Ora:Error("Failed to create tab for plugin: " .. pluginName)
        return false
    end
    
    -- Initialize plugin
    success = pcall(function()
        plugin.Init(pluginTab)
    end)
    
    if not success then
        Ora:Error("Failed to initialize plugin: " .. pluginName)
        return false
    end
    
    -- Store plugin
    PluginManager._plugins[pluginName] = plugin
    PluginManager._activePlugins[pluginName] = true
    _G.Innovare.Plugins[pluginName] = plugin
    
    return true
end

-- Debug function
function PluginManager.Debug()
    print("\n=== PluginManager Debug ===")
    print("Initialized:", PluginManager._initialized)
    print("Window exists:", mainWindow ~= nil)
    print("Content exists:", mainContent ~= nil)
    print("TabSystem exists:", tabSystem ~= nil)
    
    if tabSystem then
        print("\nTabSystem methods:")
        for name, func in pairs(getmetatable(tabSystem) or {}) do
            print("- " .. name .. " (" .. type(func) .. ")")
        end
    end
    
    if mainContent then
        print("\nContent Children:")
        for _, child in ipairs(mainContent:GetChildren()) do
            print("- " .. child.Name .. " (" .. child.ClassName .. ")")
        end
    end
    
    print("=========================\n")
end

return PluginManager
