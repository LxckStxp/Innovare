-- PluginManager.lua
-- Core plugin management system for Innovare
-- Author: LxckStxp
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

-- Private Functions
local function createTabSystem()
    Ora:Info("Creating TabSystem...")
    
    -- Debug the TabSystem object
    Ora:Info("TabSystem object type: " .. type(Censura.Elements.TabSystem))
    
    -- Create the TabSystem first
    local newTabSystem = Censura.Elements.TabSystem.new()
    
    -- Debug the created object
    Ora:Info("Created TabSystem object: " .. tostring(newTabSystem))
    
    -- Parent after creation
    newTabSystem.Parent = mainContent
    
    -- Debug parenting
    Ora:Info("TabSystem parented to: " .. tostring(newTabSystem.Parent))
    
    -- Verify the AddTab method exists
    if not newTabSystem.AddTab then
        Ora:Error("AddTab method not found on TabSystem")
        return nil
    end
    
    -- Create Settings tab with error handling
    local success, settingsTab = pcall(function()
        return newTabSystem:AddTab("Settings")
    end)
    
    if not success then
        Ora:Error("Failed to create Settings tab: " .. tostring(settingsTab))
        return nil
    end
    
    -- Create settings section with error handling
    success, _ = pcall(function()
        local settingsSection = Censura.Elements.Section.new({
            title = "Plugin Management"
        })
        settingsSection.Parent = settingsTab
    end)
    
    if not success then
        Ora:Error("Failed to create settings section")
        return nil
    end
    
    return newTabSystem
end

-- Let's also add a verification function
local function verifyTabSystem(tabSystem)
    if not tabSystem then
        return false, "TabSystem is nil"
    end
    
    if not tabSystem.AddTab then
        return false, "TabSystem missing AddTab method"
    end
    
    if not tabSystem.Parent then
        return false, "TabSystem not parented"
    end
    
    return true
end

-- Modify the Init function to use these
function PluginManager.Init(window, content)
    if PluginManager._initialized then
        Ora:Warn("PluginManager already initialized")
        return false
    end
    
    Ora:Info("Initializing PluginManager...")
    
    -- Verify parameters
    if not window or not content then
        Ora:Error("Window and content parameters required")
        return false
    end
    
    -- Debug available Censura elements
    Ora:Info("Available Censura elements:")
    for name, element in pairs(Censura.Elements) do
        Ora:Info("- " .. name)
    end
    
    -- Store references
    mainWindow = window
    mainContent = content
    
    -- Create tab system
    local success, result = pcall(function()
        local ts = createTabSystem()
        local valid, err = verifyTabSystem(ts)
        if not valid then
            error(err)
        end
        return ts
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

-- Add a test function
function PluginManager.TestTabSystem()
    print("\n=== TabSystem Test ===")
    
    -- Test TabSystem creation
    local ts = Censura.Elements.TabSystem.new()
    print("TabSystem created:", ts ~= nil)
    
    if ts then
        -- Check methods
        print("\nMethods:")
        for k, v in pairs(ts) do
            print("-", k, type(v))
        end
        
        -- Check metatable
        local mt = getmetatable(ts)
        if mt then
            print("\nMetatable methods:")
            for k, v in pairs(mt) do
                print("-", k, type(v))
            end
        end
    end
    
    print("=====================\n")
end

return PluginManager
