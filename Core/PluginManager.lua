-- Core/PluginManager.lua
local PluginManager = {}

local Ora = _G.Innovare.System.Oratio.Logger.new({
    moduleName = "PluginManager"
})

local mainWindow
local tabSystem

function PluginManager.Init(window)
    mainWindow = window
    
    -- Create tab system
    tabSystem = _G.Innovare.System.Censura.Elements.TabSystem.new()
    tabSystem.Parent = mainWindow.content
end

function PluginManager.LoadPlugin(pluginName)
    Ora:Info("Loading plugin: " .. pluginName)
    
    local success, plugin = pcall(function()
        return _G.Innovare.System.LoadModule("Plugins/" .. pluginName .. "/init")
    end)
    
    if success and plugin then
        -- Create tab for plugin
        local pluginTab = tabSystem:AddTab(pluginName)
        
        -- Initialize plugin with its tab
        plugin.Init(pluginTab)
        
        -- Store plugin reference
        _G.Innovare.Plugins[pluginName] = plugin
        
        Ora:Info("Successfully loaded plugin: " .. pluginName)
    else
        Ora:Error("Failed to load plugin: " .. pluginName)
    end
end

return PluginManager
